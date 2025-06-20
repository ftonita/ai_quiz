import os
import sys
import subprocess

def run(cmd, cwd=None):
    print(f"$ {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd)
    if result.returncode != 0:
        sys.exit(result.returncode)

print("=== Установка зависимостей backend ===")
run("python -m pip install --upgrade pip", cwd="backend")
run("pip install -r requirements.txt", cwd="backend")

print("=== Установка зависимостей frontend ===")
run("npm install", cwd="frontend") 