#!/usr/bin/env python3
import os
import json
import mysql.connector
from flask import Flask, jsonify, render_template_string
from datetime import datetime
import socket
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('tit_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('tit_request_duration_seconds', 'Request latency')

# Database configuration
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'user': os.environ.get('DB_USER', 'admin'),
    'password': os.environ.get('DB_PASSWORD', 'defaultpass'),
    'database': os.environ.get('DB_NAME', 'titdb'),
    'port': int(os.environ.get('DB_PORT', '3306'))
}

# Get instance identifier
INSTANCE_ID = os.environ.get('INSTANCE_ID', 'unknown')

@app.before_request
def before_request():
    from flask import request
    REQUEST_COUNT.labels(method=request.method, endpoint=request.endpoint or 'unknown').inc()

@app.route('/health')
def health_check():
    with REQUEST_LATENCY.time():
        health_status = {
            'status': 'healthy',
            'instance_id': INSTANCE_ID,
            'hostname': socket.gethostname(),
            'timestamp': datetime.now().isoformat(),
            'version': '2.0.0-freetier'
        }
        
        # Check database connection
        try:
            conn = mysql.connector.connect(
                host=DB_CONFIG['host'],
                user=DB_CONFIG['user'],
                password=DB_CONFIG['password'],
                database=DB_CONFIG['database'],
                port=DB_CONFIG['port'],
                connection_timeout=5
            )
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            conn.close()
            health_status['database'] = 'connected'
            logger.info(f"Health check passed for {INSTANCE_ID}")
        except Exception as e:
            health_status['database'] = f'error: {str(e)[:100]}'
            health_status['status'] = 'degraded'
            logger.error(f"Database health check failed for {INSTANCE_ID}: {str(e)}")
        
        return jsonify(health_status)

@app.route('/')
def index():
    with REQUEST_LATENCY.time():
        # Determine background color based on instance
        bg_color = '#e3f2fd' if INSTANCE_ID == 'web-app-1' else '#fff3e0'
        instance_color = '#1976d2' if INSTANCE_ID == 'web-app-1' else '#f57c00'
        
        html_template = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>TIT Free Tier Demo - {{ instance_id }}</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: 'Segoe UI', system-ui, sans-serif;
                    background: linear-gradient(135deg, {{ bg_color }}, #f5f5f5);
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    max-width: 1000px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 15px;
                    padding: 30px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                }
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                    padding: 20px;
                    background: {{ instance_color }};
                    color: white;
                    border-radius: 10px;
                }
                .instance-badge {
                    display: inline-block;
                    background: rgba(255,255,255,0.2);
                    padding: 5px 15px;
                    border-radius: 20px;
                    margin-top: 10px;
                    font-size: 14px;
                }
                .status-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                    gap: 20px;
                    margin: 20px 0;
                }
                .status-card {
                    background: #f8f9fa;
                    padding: 20px;
                    border-radius: 10px;
                    border-left: 4px solid {{ instance_color }};
                }
                .features {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 15px;
                    margin: 20px 0;
                }
                .feature {
                    background: #e8f5e8;
                    padding: 15px;
                    border-radius: 8px;
                    text-align: center;
                    border: 2px solid #4caf50;
                }
                .controls {
                    text-align: center;
                    margin: 30px 0;
                }
                .btn {
                    background: {{ instance_color }};
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 6px;
                    margin: 5px;
                    cursor: pointer;
                    font-size: 16px;
                    transition: opacity 0.3s;
                }
                .btn:hover { opacity: 0.8; }
                #output {
                    background: #2c3e50;
                    color: #ecf0f1;
                    padding: 20px;
                    border-radius: 8px;
                    font-family: 'Courier New', monospace;
                    white-space: pre-wrap;
                    max-height: 400px;
                    overflow-y: auto;
                    margin-top: 20px;
                }
                .cost-breakdown {
                    background: #d4edda;
                    border: 1px solid #c3e6cb;
                    padding: 20px;
                    border-radius: 8px;
                    margin: 20px 0;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🚀 TIT Free Tier Architecture Demo</h1>
                    <p>Nginx Load Balancer + Docker Containers + RDS MySQL</p>
                    <div class="instance-badge">Served by: {{ instance_id }}</div>
                </div>
                
                <div class="status-grid">
                    <div class="status-card">
                        <h3>🟢 Instance Status</h3>
                        <p><strong>ID:</strong> {{ instance_id }}</p>
                        <p><strong>Container:</strong> {{ hostname }}</p>
                        <p><strong>Status:</strong> Healthy</p>
                    </div>
                    <div class="status-card">
                        <h3>🕒 Runtime Info</h3>
                        <p><strong>Started:</strong> {{ timestamp }}</p>
                        <p><strong>Version:</strong> 2.0.0-freetier</p>
                        <p><strong>Platform:</strong> Docker</p>
                    </div>
                    <div class="status-card">
                        <h3>🗄️ Database</h3>
                        <p><strong>Host:</strong> {{ db_host }}</p>
                        <p><strong>Type:</strong> RDS MySQL</p>
                        <p><strong>Tier:</strong> db.t3.micro (Free)</p>
                    </div>
                    <div class="status-card">
                        <h3>⚖️ Load Balancer</h3>
                        <p><strong>Type:</strong> Nginx</p>
                        <p><strong>Algorithm:</strong> Least Connections</p>
                        <p><strong>Instances:</strong> 2</p>
                    </div>
                </div>

                <div class="cost-breakdown">
                    <h3>💰 AWS Free Tier Breakdown</h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px;">
                        <div>✅ <strong>EC2 t2.micro:</strong> $0.00/month</div>
                        <div>✅ <strong>RDS db.t3.micro:</strong> $0.00/month</div>
                        <div>✅ <strong>EBS 20GB:</strong> $0.00/month</div>
                        <div>✅ <strong>Nginx Load Balancer:</strong> $0.00/month</div>
                    </div>
                    <p style="margin-top: 10px;"><strong>Total Monthly Cost: $0.00</strong> (within free tier limits)</p>
                </div>

                <h3>🏗️ Architecture Components</h3>
                <div class="features">
                    <div class="feature">
                        <strong>🐳 Docker Containers</strong><br>
                        Multi-container orchestration
                    </div>
                    <div class="feature">
                        <strong>⚖️ Nginx Load Balancer</strong><br>
                        Free alternative to AWS ALB
                    </div>
                    <div class="feature">
                        <strong>🗃️ RDS MySQL</strong><br>
                        Managed database service
                    </div>
                    <div class="feature">
                        <strong>🔄 Health Checks</strong><br>
                        Automated monitoring
                    </div>
                    <div class="feature">
                        <strong>📊 Metrics</strong><br>
                        Prometheus monitoring
                    </div>
                    <div class="feature">
                        <strong>🏗️ Terraform IaC</strong><br>
                        Infrastructure as Code
                    </div>
                </div>

                <div class="controls">
                    <button class="btn" onclick="testLoadBalancing()">🔄 Test Load Balancing</button>
                    <button class="btn" onclick="healthCheck()">💚 Health Check</button>
                    <button class="btn" onclick="loadTest()">⚡ Load Test</button>
                    <button class="btn" onclick="viewMetrics()">📊 View Metrics</button>
                </div>

                <div id="output"></div>
            </div>

            <script>
                function updateOutput(content, type = 'info') {
                    const output = document.getElementById('output');
                    const timestamp = new Date().toLocaleTimeString();
                    const icon = type === 'error' ? '❌' : type === 'success' ? '✅' : 'ℹ️';
                    output.textContent = `[${timestamp}] ${icon} ${content}`;
                }

                async function testLoadBalancing() {
                    updateOutput('Testing load balancing across containers...');
                    
                    try {
                        const results = [];
                        for (let i = 0; i < 10; i++) {
                            const response = await fetch('/health');
                            const data = await response.json();
                            results.push(data.instance_id);
                        }
                        
                        const instances = [...new Set(results)];
                        const distribution = {};
                        results.forEach(id => distribution[id] = (distribution[id] || 0) + 1);
                        
                        let summary = `Load Balancing Test Results:\\n`;
                        summary += `Total Requests: 10\\n`;
                        summary += `Instances Hit: ${instances.join(', ')}\\n`;
                        Object.entries(distribution).forEach(([id, count]) => {
                            summary += `${id}: ${count} requests (${(count/10*100).toFixed(1)}%)\\n`;
                        });
                        
                        updateOutput(summary, 'success');
                    } catch (error) {
                        updateOutput(`Load balancing test failed: ${error.message}`, 'error');
                    }
                }

                async function healthCheck() {
                    try {
                        const response = await fetch('/health');
                        const data = await response.json();
                        updateOutput(`Health Check Results:\\nInstance: ${data.instance_id}\\nStatus: ${data.status}\\nDatabase: ${data.database}\\nTimestamp: ${data.timestamp}`, 'success');
                    } catch (error) {
                        updateOutput(`Health check failed: ${error.message}`, 'error');
                    }
                }

                async function loadTest() {
                    updateOutput('Running load test with 50 concurrent requests...');
                    const startTime = Date.now();
                    
                    try {
                        const promises = Array(50).fill().map(() => fetch('/health'));
                        await Promise.all(promises);
                        
                        const duration = Date.now() - startTime;
                        updateOutput(`Load Test Complete:\\n50 requests in ${duration}ms\\nAverage: ${(duration/50).toFixed(2)}ms per request\\nAll requests successful`, 'success');
                    } catch (error) {
                        updateOutput(`Load test failed: ${error.message}`, 'error');
                    }
                }

                async function viewMetrics() {
                    try {
                        const response = await fetch('/metrics');
                        const metrics = await response.text();
                        const lines = metrics.split('\\n').filter(line => 
                            line.startsWith('tit_') && !line.startsWith('#')
                        ).slice(0, 8);
                        
                        updateOutput(`Prometheus Metrics Sample:\\n${lines.join('\\n')}\\n\\nFull metrics available at /metrics`, 'info');
                    } catch (error) {
                        updateOutput(`Metrics unavailable: ${error.message}`, 'error');
                    }
                }

                // Auto-refresh instance info every 30 seconds
                setInterval(() => {
                    document.querySelector('.instance-badge').style.opacity = '0.5';
                    setTimeout(() => {
                        document.querySelector('.instance-badge').style.opacity = '1';
                    }, 500);
                }, 30000);
            </script>
        </body>
        </html>
        """
        
        return render_template_string(html_template,
            instance_id=INSTANCE_ID,
            hostname=socket.gethostname(),
            timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC'),
            db_host=DB_CONFIG['host'],
            bg_color=bg_color,
            instance_color=instance_color
        )

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/info')
def api_info():
    return jsonify({
        'instance_id': INSTANCE_ID,
        'hostname': socket.gethostname(),
        'timestamp': datetime.now().isoformat(),
        'version': '2.0.0-freetier'
    })

if __name__ == '__main__':
    logger.info(f"Starting TIT application - Instance: {INSTANCE_ID}")
    app.run(host='0.0.0.0', port=8080, debug=False)