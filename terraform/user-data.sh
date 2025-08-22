#!/bin/bash

# Update system
yum update -y

# Install Docker
yum install -y docker git
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone repository and setup application
mkdir -p /opt/tit-app
cd /opt/tit-app

# Download the docker compose configuration
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/TIT/main/docker/docker-compose.yml

# Create environment file
cat << EOF > .env
DB_HOST=${db_endpoint}
DB_PASSWORD=${db_password}
DB_USER=admin
DB_NAME=titdb
DB_PORT=3306
EOF

# Start the application stack
docker-compose up -d

# Create health monitoring script
cat << 'EOF' > /opt/health-monitor.sh
#!/bin/bash
cd /opt/tit-app

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "$(date): Containers down, restarting..."
    docker-compose restart
fi

# Check application health
if ! curl -f http://localhost/nginx-health > /dev/null 2>&1; then
    echo "$(date): Health check failed, restarting services..."
    docker-compose restart nginx
fi
EOF

chmod +x /opt/health-monitor.sh

# Setup monitoring cron job
echo "*/2 * * * * root /opt/health-monitor.sh >> /var/log/health-monitor.log" >> /etc/crontab

echo "$(date): TIT Free Tier application deployed successfully" >> /var/log/user-data.log