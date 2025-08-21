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
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('tit_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('tit_request_duration_seconds', 'Request latency')

# Database configuration
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'user': os.environ.get('DB_USER', 'admin'),
    'password': os.environ.get('DB_PASSWORD', 'defaultpass'),
    'database': os.environ.get('DB_NAME', 'titdb'),
    'port': int(os.environ.get('DB_PORT', '3306'))
}

@app.before_request
def before_request():
    from flask import request
    REQUEST_COUNT.labels(method=request.method, endpoint=request.endpoint, status='processing').inc()

@app.after_request
def after_request(response):
    from flask import request
    REQUEST_COUNT.labels(method=request.method, endpoint=request.endpoint, status=response.status_code).inc()
    return response

@app.route('/health')
def health_check():
    with REQUEST_LATENCY.time():
        health_status = {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'hostname': socket.gethostname(),
            'version': '2.0.0',
            'environment': os.environ.get('ENVIRONMENT', 'production')
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
            logger.info("Database health check passed")
        except Exception as e:
            health_status['database'] = f'error: {str(e)[:100]}'
            health_status['status'] = 'degraded'
            logger.error(f"Database health check failed: {str(e)}")
        
        return jsonify(health_status)

@app.route('/')
def index():
    with REQUEST_LATENCY.time():
        html_template = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>TIT Infrastructure Demo</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: rgba(255, 255, 255, 0.95);
                    border-radius: 20px;
                    padding: 30px;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                    backdrop-filter: blur(10px);
                }
                .header {
                    text-align: center;
                    margin-bottom: 40px;
                }
                .header h1 {
                    font-size: 3em;
                    color: #2c3e50;
                    margin-bottom: 10px;
                }
                .header p {
                    font-size: 1.2em;
                    color: #7f8c8d;
                }
                .status-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                    gap: 20px;
                    margin-bottom: 40px;
                }
                .status-card {
                    background: white;
                    padding: 20px;
                    border-radius: 15px;
                    box-shadow: 0 5px 15px rgba(0,0,0,0.08);
                    border-left: 5px solid #27ae60;
                }
                .status-card.info {
                    border-left-color: #3498db;
                }
                .features {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 15px;
                    margin: 30px 0;
                }
                .feature {
                    background: white;
                    padding: 20px;
                    border-radius: 12px;
                    text-align: center;
                    box-shadow: 0 5px 15px rgba(0,0,0,0.08);
                    transition: transform 0.3s ease;
                }
                .feature:hover {
                    transform: translateY(-5px);
                }
                .feature.active {
                    background: linear-gradient(135deg, #27ae60, #2ecc71);
                    color: white;
                }
                .controls {
                    text-align: center;
                    margin: 30px 0;
                }
                .btn {
                    background: #3498db;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 8px;
                    font-size: 16px;
                    cursor: pointer;
                    margin: 0 10px;
                    transition: all 0.3s ease;
                }
                .btn:hover {
                    background: #2980b9;
                    transform: translateY(-2px);
                }
                .btn.success { background: #27ae60; }
                .btn.success:hover { background: #229954; }
                #output {
                    margin-top: 20px;
                    padding: 20px;
                    background: #2c3e50;
                    color: #ecf0f1;
                    border-radius: 10px;
                    font-family: 'Courier New', monospace;
                    white-space: pre-wrap;
                    max-height: 400px;
                    overflow-y: auto;
                }
                .metrics {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 15px;
                    margin-top: 20px;
                }
                .metric {
                    background: #34495e;
                    color: white;
                    padding: 15px;
                    border-radius: 10px;
                    text-align: center;
                }
                .loading {
                    opacity: 0.7;
                    pointer-events: none;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🚀 TIT Infrastructure Demo</h1>
                    <p>Technical Infrastructure Test - Auto-Scaling Web Application with Monitoring</p>
                </div>
                
                <div class="status-grid">
                    <div class="status-card">
                        <h3>🟢 System Status</h3>
                        <p>Application is running successfully</p>
                        <small>All services operational</small>
                    </div>
                    <div class="status-card info">
                        <h3>🖥️ Server Info</h3>
                        <p><strong>Hostname:</strong> {{ hostname }}</p>
                        <p><strong>Environment:</strong> {{ environment }}</p>
                    </div>
                    <div class="status-card info">
                        <h3>🕒 Runtime Info</h3>
                        <p><strong>Started:</strong> {{ timestamp }}</p>
                        <p><strong>Version:</strong> 2.0.0</p>
                    </div>
                    <div class="status-card info">
                        <h3>🗄️ Database</h3>
                        <p><strong>Host:</strong> {{ db_host }}</p>
                        <p><strong>Port:</strong> {{ db_port }}</p>
                    </div>
                </div>

                <h2>Infrastructure Components</h2>
                <div class="features">
                    <div class="feature active">
                        <h3>⚖️ Load Balancer</h3>
                        <p>AWS ALB with health checks</p>
                    </div>
                    <div class="feature active">
                        <h3>📈 Auto Scaling</h3>
                        <p>EC2 Auto Scaling Group</p>
                    </div>
                    <div class="feature active">
                        <h3>🗃️ Database</h3>
                        <p>RDS MySQL with backups</p>
                    </div>
                    <div class="feature active">
                        <h3>📊 Monitoring</h3>
                        <p>CloudWatch & Prometheus</p>
                    </div>
                    <div class="feature active">
                        <h3>🔄 Failover</h3>
                        <p>Automated health recovery</p>
                    </div>
                    <div class="feature active">
                        <h3>🏗️ IaC</h3>
                        <p>Terraform provisioning</p>
                    </div>
                </div>

                <div class="controls">
                    <button class="btn" onclick="refreshStatus()">🔄 Refresh Status</button>
                    <button class="btn" onclick="loadTest()">⚡ Load Test</button>
                    <button class="btn success" onclick="healthCheck()">💚 Health Check</button>
                    <button class="btn" onclick="viewMetrics()">📊 View Metrics</button>
                </div>

                <div id="output"></div>
            </div>

            <script>
                let isLoading = false;

                function setLoading(loading) {
                    isLoading = loading;
                    document.body.classList.toggle('loading', loading);
                }

                function updateOutput(content, type = 'info') {
                    const output = document.getElementById('output');
                    const timestamp = new Date().toLocaleTimeString();
                    const prefix = type === 'error' ? '❌' : type === 'success' ? '✅' : 'ℹ️';
                    output.textContent = `[${timestamp}] ${prefix} ${content}`;
                    output.scrollTop = output.scrollHeight;
                }

                async function refreshStatus() {
                    if (isLoading) return;
                    setLoading(true);
                    
                    try {
                        const response = await fetch('/health');
                        const data = await response.json();
                        updateOutput(JSON.stringify(data, null, 2), 'success');
                    } catch (error) {
                        updateOutput(`Error fetching status: ${error.message}`, 'error');
                    } finally {
                        setLoading(false);
                    }
                }

                async function loadTest() {
                    if (isLoading) return;
                    setLoading(true);
                    
                    updateOutput('Starting load test with 100 concurrent requests...');
                    const startTime = Date.now();
                    
                    try {
                        const promises = Array(100).fill().map(() => fetch('/health'));
                        await Promise.all(promises);
                        
                        const duration = Date.now() - startTime;
                        updateOutput(`Load test completed successfully!
📊 100 requests processed in ${duration}ms
⚡ Average: ${(duration/100).toFixed(2)}ms per request
🎯 All requests successful`, 'success');
                    } catch (error) {
                        updateOutput(`Load test failed: ${error.message}`, 'error');
                    } finally {
                        setLoading(false);
                    }
                }

                async function healthCheck() {
                    if (isLoading) return;
                    setLoading(true);
                    
                    try {
                        const response = await fetch('/health');
                        if (response.ok) {
                            const data = await response.json();
                            updateOutput(`Health Check: ${data.status.toUpperCase()}
🖥️  Server: ${data.hostname}
🗄️  Database: ${data.database}
🕒 Timestamp: ${data.timestamp}`, 'success');
                        } else {
                            updateOutput(`Health check failed with status: ${response.status}`, 'error');
                        }
                    } catch (error) {
                        updateOutput(`Health check error: ${error.message}`, 'error');
                    } finally {
                        setLoading(false);
                    }
                }

                async function viewMetrics() {
                    if (isLoading) return;
                    setLoading(true);
                    
                    try {
                        const response = await fetch('/metrics');
                        if (response.ok) {
                            const metrics = await response.text();
                            const lines = metrics.split('\\n').filter(line => 
                                line.startsWith('tit_') && !line.startsWith('#')
                            ).slice(0, 10);
                            
                            updateOutput(`Prometheus Metrics (sample):
${lines.join('\\n')}

Full metrics available at /metrics endpoint`, 'info');
                        } else {
                            updateOutput('Metrics endpoint not available', 'error');
                        }
                    } catch (error) {
                        updateOutput(`Metrics error: ${error.message}`, 'error');
                    } finally {
                        setLoading(false);
                    }
                }

                // Auto-refresh every 30 seconds
                setInterval(refreshStatus, 30000);
                
                // Initial load
                window.addEventListener('load', refreshStatus);
            </script>
        </body>
        </html>
        """
        
        return render_template_string(html_template,
            hostname=socket.gethostname(),
            environment=os.environ.get('ENVIRONMENT', 'production'),
            timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC'),
            db_host=DB_CONFIG['host'],
            db_port=DB_CONFIG['port']
        )

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/info')
def api_info():
    return jsonify({
        'hostname': socket.gethostname(),
        'timestamp': datetime.now().isoformat(),
        'version': '2.0.0',
        'environment': os.environ.get('ENVIRONMENT', 'production'),
        'database_config': {
            'host': DB_CONFIG['host'],
            'port': DB_CONFIG['port'],
            'database': DB_CONFIG['database']
        }
    })

if __name__ == '__main__':
    logger.info("Starting TIT application...")
    app.run(host='0.0.0.0', port=8080, debug=False)