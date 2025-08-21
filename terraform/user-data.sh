#!/bin/bash

# Update system and install packages
yum update -y
yum install -y nginx mysql python3 pip curl

# Install CloudWatch agent
wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create directories
mkdir -p /opt/${project_name}-app
mkdir -p /opt/scripts

# Create Python web application
cat << 'EOF' > /opt/${project_name}-app/app.py
#!/usr/bin/env python3
import os
import json
import mysql.connector
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime
import socket
import threading
import time

class TITHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            health_status = {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'hostname': socket.gethostname(),
                'version': '1.0.0'
            }
            
            # Check database connection
            try:
                db_config = {
                    'host': '${db_endpoint}'.split(':')[0] if '${db_endpoint}' else 'localhost',
                    'user': 'admin',
                    'password': '${db_password}',
                    'database': '${project_name}db'
                }
                conn = mysql.connector.connect(**db_config)
                conn.close()
                health_status['database'] = 'connected'
            except Exception as e:
                health_status['database'] = f'error: {str(e)[:50]}'
                health_status['status'] = 'degraded'
            
            self.wfile.write(json.dumps(health_status).encode())
            
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <title>${project_name.upper()} Infrastructure Demo</title>
                <style>
                    body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
                    .container {{ background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
                    .status {{ padding: 10px; margin: 10px 0; border-radius: 4px; }}
                    .healthy {{ background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }}
                    .info {{ background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }}
                    .feature {{ display: inline-block; margin: 5px; padding: 10px; background: #e9ecef; border-radius: 4px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🚀 ${project_name.upper()} Infrastructure Demo</h1>
                    <div class="status healthy">
                        <strong>Status:</strong> Application is running successfully
                    </div>
                    <div class="status info">
                        <strong>Server:</strong> {socket.gethostname()}
                    </div>
                    <div class="status info">
                        <strong>Timestamp:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
                    </div>
                    <div class="status info">
                        <strong>Database:</strong> ${db_endpoint}
                    </div>
                    <h3>Infrastructure Components:</h3>
                    <div class="feature">✅ Load Balancer</div>
                    <div class="feature">✅ Auto Scaling</div>
                    <div class="feature">✅ RDS Database</div>
                    <div class="feature">✅ CloudWatch Monitoring</div>
                    <div class="feature">✅ Automated Failover</div>
                    <div class="feature">✅ Terraform IaC</div>
                </div>
            </body>
            </html>
            """
            self.wfile.write(html_content.encode())
        else:
            self.send_response(404)
            self.end_headers()

def run_server():
    server_address = ('', 8080)
    httpd = HTTPServer(server_address, TITHandler)
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
EOF

# Install Python dependencies
pip3 install mysql-connector-python

# Create nginx configuration
cat << 'EOF' > /etc/nginx/conf.d/${project_name}-app.conf
upstream ${project_name}_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://${project_name}_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
    }
    
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Remove default nginx config
rm -f /etc/nginx/conf.d/default.conf

# Create health check script
cat << 'EOF' > /opt/scripts/health-check.sh
#!/bin/bash
LOG_FILE="/var/log/health-check.log"
ENDPOINT="http://localhost/health"
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s $ENDPOINT > /dev/null; then
        echo "$(date): Health check passed" >> $LOG_FILE
        exit 0
    else
        echo "$(date): Health check failed, attempt $((RETRY_COUNT + 1))" >> $LOG_FILE
        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep 5
    fi
done

echo "$(date): Health check failed after $MAX_RETRIES attempts" >> $LOG_FILE
exit 1
EOF

# Create failover script
cat << 'EOF' > /opt/scripts/failover.sh
#!/bin/bash
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
LOG_FILE="/var/log/failover.log"

restart_services() {
    echo "$(date): Restarting services on instance $INSTANCE_ID" | tee -a $LOG_FILE
    systemctl restart nginx
    systemctl restart ${project_name}-app
    
    sleep 10
    if systemctl is-active --quiet nginx && systemctl is-active --quiet ${project_name}-app; then
        echo "$(date): Services restarted successfully" | tee -a $LOG_FILE
        return 0
    else
        echo "$(date): Service restart failed" | tee -a $LOG_FILE
        return 1
    fi
}

trigger_instance_replacement() {
    echo "$(date): Triggering instance replacement" | tee -a $LOG_FILE
    aws autoscaling set-instance-health \
        --instance-id $INSTANCE_ID \
        --health-status Unhealthy \
        --region $REGION
}

if ! /opt/scripts/health-check.sh; then
    echo "$(date): Health check failed, attempting service restart" | tee -a $LOG_FILE
    
    if restart_services; then
        echo "$(date): Failover successful - services restarted" | tee -a $LOG_FILE
    else
        echo "$(date): Service restart failed, triggering instance replacement" | tee -a $LOG_FILE
        trigger_instance_replacement
    fi
fi
EOF

# Make scripts executable
chmod +x /opt/scripts/*.sh

# Create systemd service
cat << 'EOF' > /etc/systemd/system/${project_name}-app.service
[Unit]
Description=${project_name.upper()} Demo Application
After=network.target

[Service]
Type=simple
User=nginx
WorkingDirectory=/opt/${project_name}-app
ExecStart=/usr/bin/python3 /opt/${project_name}-app/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configure CloudWatch agent
cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "metrics": {
    "namespace": "${project_name.upper()}/Application",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/health-check.log",
            "log_group_name": "${project_name}-health-checks"
          },
          {
            "file_path": "/var/log/failover.log",
            "log_group_name": "${project_name}-failover"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "${project_name}-nginx-access"
          }
        ]
      }
    }
  }
}
EOF

# Start services
systemctl daemon-reload
systemctl enable ${project_name}-app
systemctl start ${project_name}-app
systemctl enable nginx
systemctl start nginx

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Setup cron job for failover monitoring
echo "*/2 * * * * root /opt/scripts/failover.sh" >> /etc/crontab

# Final status
echo "$(date): ${project_name.upper()} application setup completed" >> /var/log/user-data.log
sleep 30
curl -f http://localhost/health || echo "$(date): Initial health check failed" >> /var/log/user-data.log