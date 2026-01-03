#!/usr/bin/env python3
import json
import sys
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

LOG_DIR = Path('/opt/keybuzz/logs/sre/alertmanager')
PORT = 9099

class AlertHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_POST(self):
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')
            timestamp = datetime.utcnow().isoformat() + 'Z'
            date_str = datetime.utcnow().strftime('%Y%m%d')
            log_file = LOG_DIR / f'alerts_{date_str}.jsonl'
            try:
                payload = json.loads(body) if body else {}
            except json.JSONDecodeError:
                payload = {'raw': body}
            log_entry = {'received_at': timestamp, 'path': self.path, 'payload': payload}
            with open(log_file, 'a') as f:
                f.write(json.dumps(log_entry) + '\n')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
            alert_count = len(payload.get('alerts', [])) if isinstance(payload, dict) else 0
            print(f'[{timestamp}] Received {alert_count} alert(s) -> {log_file}', flush=True)
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            print(f'[ERROR] {e}', file=sys.stderr, flush=True)

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status":"healthy","service":"keybuzz-alert-receiver"}')

if __name__ == '__main__':
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    print(f'Starting KeyBuzz Alert Receiver on port {PORT}...', flush=True)
    server = HTTPServer(('0.0.0.0', PORT), AlertHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('Shutting down...')
        server.shutdown()