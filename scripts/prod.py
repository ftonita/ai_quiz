#!/usr/bin/env python3
import os
import sys
import subprocess
import time
from pathlib import Path

def check_docker():
    """Проверяет наличие Docker"""
    print("🐳 Проверка Docker...")
    try:
        result = subprocess.run(["docker", "--version"], capture_output=True, text=True)
        print(f"✅ Docker: {result.stdout.strip()}")
        return True
    except Exception as e:
        print("❌ Docker не найден")
        return False

def check_docker_compose():
    """Проверяет наличие docker-compose"""
    print("🐳 Проверка Docker Compose...")
    try:
        result = subprocess.run(["docker-compose", "--version"], capture_output=True, text=True)
        print(f"✅ Docker Compose: {result.stdout.strip()}")
        return True
    except Exception as e:
        print("❌ Docker Compose не найден")
        return False

def build_and_run():
    """Собирает и запускает приложение через Docker"""
    print("\n🔨 Сборка и запуск приложения...")
    
    try:
        # Остановка существующих контейнеров
        print("🛑 Остановка существующих контейнеров...")
        subprocess.run(["docker-compose", "down"], check=False)
        
        # Сборка и запуск
        print("🚀 Сборка и запуск...")
        subprocess.run(["docker-compose", "up", "--build", "-d"], check=True)
        
        print("\n🎉 Приложение запущено!")
        print("📱 Доступно по адресу: http://localhost:8000")
        print("🔧 API документация: http://localhost:8000/docs")
        print("\n📊 Логи контейнера:")
        print("   docker-compose logs -f")
        print("\n⏹️  Остановка:")
        print("   docker-compose down")
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Ошибка сборки/запуска: {e}")
        return False
    
    return True

def show_logs():
    """Показывает логи контейнера"""
    print("\n📊 Логи приложения:")
    try:
        subprocess.run(["docker-compose", "logs", "-f"])
    except KeyboardInterrupt:
        print("\n✅ Просмотр логов завершен")

def main():
    print("🎯 AI Quiz Platform - Production")
    print("=" * 50)
    
    if not check_docker():
        print("\n❌ Установите Docker")
        sys.exit(1)
    
    if not check_docker_compose():
        print("\n❌ Установите Docker Compose")
        sys.exit(1)
    
    if build_and_run():
        print("\n" + "=" * 50)
        print("🎯 Приложение готово к использованию!")
        print("=" * 50)

if __name__ == "__main__":
    main() 