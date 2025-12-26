#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl
import os
import sys

DOMAIN = os.environ.get('PROSODY_DOMAIN')
if not DOMAIN:
    print("Error: PROSODY_DOMAIN is not set", file=sys.stderr)
    sys.exit(1)

HOST_META_FILE = './host-meta'
SSL_CERT = "/app/certs/" + DOMAIN + "/fullchain.pem"
SSL_KEY = "/app/certs/" + DOMAIN + "/privkey.pem"

class HostMetaHandler(BaseHTTPRequestHandler):    
    def do_GET(self):
        if self.path == '/.well-known/host-meta':
            self.send_host_meta()
        else:
            self.send_error(404, "Not Found")
    
    def send_host_meta(self):
        try:
            with open(HOST_META_FILE, 'rb') as f:
              content = f.read()
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/xrd+xml')
            self.send_header('Content-Length', str(len(content)))
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404, f"File not found: {HOST_META_FILE}")
        except Exception as e:
            self.send_error(500, f"Internal Server Error: {str(e)}")

def run_server():
    if not os.path.exists(HOST_META_FILE):
        print(f"Предупреждение: Файл {HOST_META_FILE} не найден", file=sys.stderr)
    
    server_address = ('0.0.0.0', 443)
    httpd = HTTPServer(server_address, HostMetaHandler)
    
    try:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(SSL_CERT, SSL_KEY)
        httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
        
        print(f"Server launched on https://0.0.0.0:443")
        print(f"Serving file: {HOST_META_FILE}")
        print(f"SSL certificate: {SSL_CERT}")
        
        httpd.serve_forever()
    except FileNotFoundError as e:
        print(f"Error: SSL certificate not found - {e}", file=sys.stderr)
        sys.exit(1)
    except PermissionError:
        print(f"Error: Permission denied for port 443. Root privileges are required.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error running server: {e}", file=sys.stderr)
        sys.exit(1)
        
if __name__ == '__main__':
    try:
        run_server()
    except KeyboardInterrupt:
        print("\nServer stopped")
        sys.exit(0)
