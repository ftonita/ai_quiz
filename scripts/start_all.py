import subprocess
import sys
import os
import platform

BACKEND_CMD = [sys.executable, '-m', 'uvicorn', 'main:app', '--reload', '--host', '0.0.0.0', '--port', '8000']
FRONTEND_CMD = ['npm', 'run', 'dev']

backend = subprocess.Popen(BACKEND_CMD, cwd='backend')
frontend = subprocess.Popen(FRONTEND_CMD, cwd='frontend')

try:
    backend.wait()
    frontend.wait()
except KeyboardInterrupt:
    backend.terminate()
    frontend.terminate() 