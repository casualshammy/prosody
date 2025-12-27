#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl
import os
import sys

DOMAIN = os.environ.get('PROSODY_DOMAIN')
if not DOMAIN:
    print("Error: PROSODY_DOMAIN is not set", file=sys.stderr)
    sys.exit(1)

SSL_CERT = "/app/certs/" + DOMAIN + "/fullchain.pem"
SSL_KEY = "/app/certs/" + DOMAIN + "/privkey.pem"
HOST_META = ("<?xml version=\"1.0\" encoding=\"UTF-8\"?><XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'><Link href='https://" + DOMAIN + ":5281/http-bind' rel='urn:xmpp:alt-connections:xbosh'/></XRD>").encode('utf-8')

class HostMetaHandler(BaseHTTPRequestHandler):    
    def do_GET(self):
        if self.path == '/.well-known/host-meta':
            try:                
                self.send_response(200)
                self.send_header('Content-Type', 'application/xrd+xml')
                self.send_header('Content-Length', str(len(HOST_META)))
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                
                self.wfile.write(HOST_META)
            except Exception as e:
                self.send_error(500, f"Internal Server Error: {str(e)}")
        else:
            self.send_error(404, "Not Found")

def run_server():    
    server_address = ('0.0.0.0', 443)
    httpd = HTTPServer(server_address, HostMetaHandler)
    
    try:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(SSL_CERT, SSL_KEY)
        httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
        
        print(f"Server launched on https://0.0.0.0:443")
        print(f"Domain: {DOMAIN}")
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
    finally:
        httpd.server_close()
        
if __name__ == '__main__':
    try:
        run_server()
    except KeyboardInterrupt:
        print("\nServer stopped")
        sys.exit(0)
