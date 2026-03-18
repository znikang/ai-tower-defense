import http.server
import ssl
import os

os.chdir('C:\\Users\\hisashi\\Documents\\godot-tower-defense\\export')

handler = http.server.SimpleHTTPRequestHandler
httpd = http.server.HTTPServer(('0.0.0.0', 8000), handler)

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain('cert.pem', 'key.pem')
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print('HTTPS Server running at https://localhost:8000')
print('Access from other device: https://YOUR_IP:8000')
httpd.serve_forever()
