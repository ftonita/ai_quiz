#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
from pathlib import Path

def clean_docker():
    """Очищает Docker контейнеры и образы"""
    print("🐳 Очистка Docker...")
    try:
        subprocess.run(["docker-compose", "down", "--rmi", "all", "-v"], check=False)
        print("✅ Docker контейнеры и образы очищены")
    except Exception as e:
        print(f"⚠️  Ошибка очистки Docker: {e}")

def clean_frontend():
    """Очищает node_modules и build папки frontend"""
    print("📦 Очистка frontend...")
    frontend_dir = Path("frontend")
    
    dirs_to_remove = ["node_modules", "dist", ".vite"]
    for dir_name in dirs_to_remove:
        dir_path = frontend_dir / dir_name
        if dir_path.exists():
            shutil.rmtree(dir_path)
            print(f"✅ Удалена папка: {dir_name}")

def clean_backend():
    """Очищает __pycache__ папки backend"""
    print("🐍 Очистка backend...")
    backend_dir = Path("backend")
    
    for pycache in backend_dir.rglob("__pycache__"):
        shutil.rmtree(pycache)
        print(f"✅ Удалена папка: {pycache}")
    
    for pyc_file in backend_dir.rglob("*.pyc"):
        pyc_file.unlink()
        print(f"✅ Удален файл: {pyc_file}")

def clean_scripts():
    """Очищает __pycache__ папки scripts"""
    print("🔧 Очистка scripts...")
    scripts_dir = Path("scripts")
    
    for pycache in scripts_dir.rglob("__pycache__"):
        shutil.rmtree(pycache)
        print(f"✅ Удалена папка: {pycache}")

def main():
    print("🧹 AI Quiz Platform - Cleanup")
    print("=" * 50)
    
    clean_docker()
    clean_frontend()
    clean_backend()
    clean_scripts()
    
    print("\n✅ Очистка завершена!")

if __name__ == "__main__":
    main() 