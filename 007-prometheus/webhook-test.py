#!/usr/bin/env python3
"""
Simple webhook server to receive and display Alertmanager notifications.
This is useful for testing alerting configuration in development.

Usage:
    python3 webhook-test.py

The server will listen on http://localhost:5001 by default.
"""

import json
import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse

class AlertWebhookHandler(BaseHTTPRequestHandler):
    
    def do_POST(self):
        """
        Handle incoming POST requests containing Alertmanager alert notifications.
        
        Parses the JSON payload from the request, extracts and displays alert metadata and details to the terminal with formatted output, and responds with a JSON acknowledgment including the timestamp, alert count, and request path. If parsing or processing fails, responds with a 500 error and a JSON error message.
        """
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode('utf-8'))
            timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            print(f"\n{'='*80}")
            print(f"🚨 ALERT RECEIVED - {timestamp}")
            print(f"📍 Path: {self.path}")
            print(f"{'='*80}")
            
            # Parse path to determine alert type
            path_parts = self.path.strip('/').split('/')
            alert_type = path_parts[0] if path_parts[0] else 'default'
            
            # Display alert type icon
            icons = {
                'critical': '🔴',
                'system': '🖥️',
                'docker': '🐳',
                'monitoring': '📊',
                'default': '⚠️'
            }
            icon = icons.get(alert_type, '⚠️')
            
            print(f"{icon} Alert Type: {alert_type.upper()}")
            print(f"📊 Status: {data.get('status', 'unknown')}")
            print(f"🏷️  Group Labels: {data.get('groupLabels', {})}")
            print(f"📝 Common Labels: {data.get('commonLabels', {})}")
            
            if 'alerts' in data:
                print(f"\n📋 ALERTS ({len(data['alerts'])} total):")
                print("-" * 50)
                
                for i, alert in enumerate(data['alerts'], 1):
                    status = alert.get('status', 'unknown')
                    status_icon = '🔴' if status == 'firing' else '🟢' if status == 'resolved' else '⚪'
                    
                    print(f"\n{status_icon} Alert #{i} - {status.upper()}")
                    print(f"   Name: {alert.get('labels', {}).get('alertname', 'Unknown')}")
                    print(f"   Severity: {alert.get('labels', {}).get('severity', 'Unknown')}")
                    print(f"   Instance: {alert.get('labels', {}).get('instance', 'Unknown')}")
                    
                    annotations = alert.get('annotations', {})
                    if 'summary' in annotations:
                        print(f"   Summary: {annotations['summary']}")
                    if 'description' in annotations:
                        print(f"   Description: {annotations['description']}")
                    
                    # Show starts/ends at times
                    if 'startsAt' in alert:
                        starts_at = alert['startsAt'].replace('T', ' ').replace('Z', ' UTC')
                        print(f"   Started: {starts_at}")
                    
                    if alert.get('status') == 'resolved' and 'endsAt' in alert:
                        ends_at = alert['endsAt'].replace('T', ' ').replace('Z', ' UTC')
                        print(f"   Resolved: {ends_at}")
                        
                    # Show all labels for debugging
                    labels = alert.get('labels', {})
                    if labels:
                        print(f"   Labels: {', '.join([f'{k}={v}' for k, v in labels.items()])}")
            
            print(f"\n{'='*80}")
            
            # Send response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {
                'status': 'received',
                'timestamp': timestamp,
                'alert_count': len(data.get('alerts', [])),
                'path': self.path
            }
            
            self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))
            
        except Exception as e:
            print(f"❌ Error processing alert: {e}")
            print(f"Raw data: {post_data.decode('utf-8', errors='replace')}")
            
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            error_response = {
                'error': str(e),
                'timestamp': datetime.datetime.now().isoformat()
            }
            
            self.wfile.write(json.dumps(error_response).encode('utf-8'))
    
    def do_GET(self):
        """
        Responds to GET requests with an HTML page displaying server status, usage instructions, example Alertmanager configuration, and available test routes.
        """
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Alertmanager Webhook Test Server</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .status { background: #e8f5e8; padding: 20px; border-radius: 5px; }
                .code { background: #f4f4f4; padding: 10px; border-radius: 3px; margin: 10px 0; }
            </style>
        </head>
        <body>
            <h1>🚨 Alertmanager Webhook Test Server</h1>
            <div class="status">
                <h2>✅ Server is running!</h2>
                <p>This webhook server is ready to receive alerts from Alertmanager.</p>
                <p><strong>Listening on:</strong> http://localhost:5001</p>
            </div>
            
            <h2>📝 Configuration</h2>
            <p>Add this to your Alertmanager configuration:</p>
            <div class="code">
webhook_configs:<br>
- url: 'http://127.0.0.1:5001/'<br>
&nbsp;&nbsp;send_resolved: true
            </div>
            
            <h2>🧪 Test Routes</h2>
            <ul>
                <li><code>/</code> - Default alerts</li>
                <li><code>/critical</code> - Critical alerts</li>
                <li><code>/system</code> - System alerts</li>
                <li><code>/docker</code> - Docker alerts</li>
                <li><code>/monitoring</code> - Monitoring alerts</li>
            </ul>
            
            <h2>📊 Usage</h2>
            <p>Watch the terminal where you started this script to see incoming alerts in real-time.</p>
        </body>
        </html>
        """
        
        self.wfile.write(html.encode('utf-8'))

def run_server(port=5001):
    """
    Start the Alertmanager webhook test server on the specified port.
    
    The server listens for incoming HTTP requests, handling Alertmanager alert POSTs and serving an informational HTML page on GET requests. Runs indefinitely until interrupted by the user.
    
    Parameters:
        port (int, optional): The port number to bind the server to. Defaults to 5001.
    """
    server_address = ('', port)
    httpd = HTTPServer(server_address, AlertWebhookHandler)
    
    print(f"🚀 Starting Alertmanager webhook test server...")
    print(f"📡 Listening on http://localhost:{port}")
    print(f"🌐 Visit http://localhost:{port} in your browser for info")
    print(f"📋 Watch this terminal for incoming alerts")
    print(f"🛑 Press Ctrl+C to stop")
    print(f"{'='*60}")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print(f"\n👋 Shutting down webhook server...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()
