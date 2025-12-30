#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl
import os
import sys

def log(_msg, _isError=False):
  print(f"HOST-META || {_msg}", file=sys.stderr if _isError else sys.stdout)

DOMAIN = os.environ.get('PROSODY_DOMAIN')
if not DOMAIN:
  log("PROSODY_DOMAIN is not set!", True)
  sys.exit(1)

SSL_CERT = "/app/certs/" + DOMAIN + "/fullchain.pem"
SSL_KEY = "/app/certs/" + DOMAIN + "/privkey.pem"
HOST_META = (
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  "<XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'>"
  "<Link href='https://" + DOMAIN + ":5281/http-bind' rel='urn:xmpp:alt-connections:xbosh'/>"
  "<Link href='wss://" + DOMAIN + ":5281/xmpp-websocket' rel='urn:xmpp:alt-connections:websocket'/>"
  "</XRD>").encode('utf-8')

reqCounter = 0

class HostMetaHandler(BaseHTTPRequestHandler):
  server_version = "Nginx"
  sys_version = ""
  
  def log_message(self, format, *args):
    pass
        
  def do_GET(self):
    global reqCounter
    reqCounter += 1
    reqIndex = reqCounter
    statusCode = 0
    log(f"[{reqIndex}] {self.client_address[0]} => {self.command} {self.path}")
    
    if self.path == '/.well-known/host-meta':
      try:                
        self.send_response(200)
        self.send_header('Content-Type', 'application/xrd+xml')
        self.send_header('Content-Length', str(len(HOST_META)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        self.wfile.write(HOST_META)
        statusCode = 200
      except Exception as e:
        self.send_error(500, f"Internal Server Error: {str(e)}")
        statusCode = 500
    else:
      self.send_error(404, "Not Found")
      statusCode = 404

    log(f"[{reqIndex}] {self.client_address[0]} <= {self.command} {self.path} {statusCode}")

def run_server():    
  server_address = ('0.0.0.0', 443)
  httpd = HTTPServer(server_address, HostMetaHandler)
  
  try:
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(SSL_CERT, SSL_KEY)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    
    log(f"Server launched on https://0.0.0.0:443")
    log(f"Domain: {DOMAIN}")
    log(f"SSL certificate: {SSL_CERT}")
    
    httpd.serve_forever()
  except FileNotFoundError as e:
    log(f"Error: SSL certificate not found - {e}", True)
    sys.exit(1)
  except PermissionError:
    log(f"Error: Permission denied for port 443. Root privileges are required.", True)
    sys.exit(1)
  except Exception as e:
    log(f"Error running server: {e}", True)
    sys.exit(1)
  finally:
    httpd.server_close()
        
if __name__ == '__main__':
  try:
    run_server()
  except KeyboardInterrupt:
    log("\nServer stopped")
    sys.exit(0)
