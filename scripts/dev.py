#!/usr/bin/env python3
import os
import sys
import subprocess
import platform
import time
from pathlib import Path

def check_dependencies():
    """Проверяет наличие Python и Node.js"""
    print("🔍 Проверка зависимостей...")
    
    # Проверка Python
    try:
        result = subprocess.run([sys.executable, "--version"], capture_output=True, text=True)
        print(f"✅ Python: {result.stdout.strip()}")
    except Exception as e:
        print("❌ Python не найден")
        return False
    
    # Проверка Node.js
    try:
        result = subprocess.run(["node", "--version"], capture_output=True, text=True)
        print(f"✅ Node.js: {result.stdout.strip()}")
    except Exception as e:
        print("❌ Node.js не найден")
        return False
    
    return True

def install_backend():
    """Устанавливает зависимости backend"""
    print("\n🐍 Установка зависимостей backend...")
    backend_dir = Path("backend")
    if not backend_dir.exists():
        print("❌ Папка backend не найдена")
        return False
    
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "pip"], 
                      cwd=backend_dir, check=True)
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], 
                      cwd=backend_dir, check=True)
        print("✅ Backend зависимости установлены")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Ошибка установки backend: {e}")
        return False

def install_frontend():
    """Устанавливает зависимости frontend"""
    print("\n📦 Установка зависимостей frontend...")
    frontend_dir = Path("frontend")
    if not frontend_dir.exists():
        print("❌ Папка frontend не найдена")
        return False
    
    try:
        # Сначала проверяем наличие package.json
        package_json = frontend_dir / "package.json"
        if not package_json.exists():
            print("❌ package.json не найден")
            return False
        
        # Устанавливаем зависимости (это создаст package-lock.json)
        subprocess.run(["npm", "install"], cwd=frontend_dir, check=True)
        print("✅ Frontend зависимости установлены")
        
        # Проверяем, что package-lock.json создался
        lock_file = frontend_dir / "package-lock.json"
        if lock_file.exists():
            print("✅ package-lock.json создан")
        else:
            print("⚠️  package-lock.json не создан")
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Ошибка установки frontend: {e}")
        return False

def start_services():
    """Запускает backend и frontend параллельно"""
    print("\n🚀 Запуск сервисов...")
    
    backend_cmd = [sys.executable, "-m", "uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
    frontend_cmd = ["npm", "run", "dev"]
    
    processes = []
    
    try:
        # Запуск backend
        print("🔧 Запуск backend (http://localhost:8000)...")
        backend_proc = subprocess.Popen(backend_cmd, cwd="backend")
        processes.append(backend_proc)
        
        # Ждем немного для запуска backend
        time.sleep(3)
        
        # Запуск frontend
        print("🎨 Запуск frontend (http://localhost:5173)...")
        frontend_proc = subprocess.Popen(frontend_cmd, cwd="frontend")
        processes.append(frontend_proc)
        
        print("\n🎉 Все сервисы запущены!")
        print("📱 Главная страница: http://localhost:5173")
        print("🔧 API документация: http://localhost:8000/docs")
        print("\n⏹️  Для остановки нажмите Ctrl+C")
        
        # Ожидание завершения
        for proc in processes:
            proc.wait()
            
    except KeyboardInterrupt:
        print("\n🛑 Остановка сервисов...")
        for proc in processes:
            proc.terminate()
        print("✅ Сервисы остановлены")

def main():
    print("🎯 AI Quiz Platform - Dev Environment")
    print("=" * 50)
    
    if not check_dependencies():
        print("\n❌ Установите Python 3.11+ и Node.js 18+")
        sys.exit(1)
    
    if not install_backend():
        sys.exit(1)
    
    if not install_frontend():
        sys.exit(1)
    
    start_services()

if __name__ == "__main__":
    main() 