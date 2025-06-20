#!/usr/bin/env python3
"""
Универсальный скрипт запуска AI Quiz Platform
Автоматически определяет окружение и запускает соответствующий режим
"""
import os
import sys
import subprocess
from pathlib import Path

def check_docker_available():
    """Проверяет доступность Docker"""
    try:
        subprocess.run(["docker", "--version"], capture_output=True, check=True)
        return True
    except:
        return False

def main():
    print("🎯 AI Quiz Platform - Universal Launcher")
    print("=" * 50)
    
    # Проверяем наличие Docker
    if check_docker_available():
        print("🐳 Docker обнаружен - запуск в продакшн режиме")
        print("💡 Для разработки используйте: python scripts/dev.py")
        
        # Запускаем продакшн скрипт
        script_path = Path(__file__).parent / "prod.py"
        subprocess.run([sys.executable, str(script_path)])
    else:
        print("🔧 Docker не найден - запуск в режиме разработки")
        print("💡 Для продакшн используйте: python scripts/prod.py")
        
        # Запускаем dev скрипт
        script_path = Path(__file__).parent / "dev.py"
        subprocess.run([sys.executable, str(script_path)])

if __name__ == "__main__":
    main() 