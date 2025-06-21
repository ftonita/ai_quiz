#!/bin/bash

# Скрипт для загрузки файлов на сервер
# IP: 212.34.134.169
# User: root

set -e

echo "📤 Загружаем файлы на сервер..."

# Параметры сервера
SERVER_IP="212.34.134.169"
SERVER_USER="root"
SERVER_PASS="581J44sT6RhSCap7"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Проверяем наличие sshpass
if ! command -v sshpass &> /dev/null; then
    log "Устанавливаем sshpass..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install sshpass
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt-get update && sudo apt-get install -y sshpass
    else
        error "Не удалось установить sshpass. Установите вручную."
    fi
fi

# Создаем временную директорию для архива
TEMP_DIR=$(mktemp -d)
ARCHIVE_NAME="ai-quiz-$(date +%Y%m%d-%H%M%S).tar.gz"

log "Создаем архив с файлами приложения..."
tar -czf "$TEMP_DIR/$ARCHIVE_NAME" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.DS_Store' \
    --exclude='logs' \
    --exclude='*.log' \
    .

log "Загружаем архив на сервер..."
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$TEMP_DIR/$ARCHIVE_NAME" "$SERVER_USER@$SERVER_IP:/tmp/"

log "Распаковываем файлы на сервере..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" << 'EOF'
    # Создаем директорию для приложения
    mkdir -p /opt/ai-quiz
    
    # Распаковываем архив
    tar -xzf "/tmp/$(basename /tmp/ai-quiz-*.tar.gz)" -C /opt/ai-quiz --strip-components=1
    
    # Удаляем архив
    rm /tmp/ai-quiz-*.tar.gz
    
    # Обновляем URL в API для QR кода
    sed -i 's|http://localhost:8000|http://212.34.134.169|g' /opt/ai-quiz/backend/api.py
    
    echo "Файлы успешно распакованы в /opt/ai-quiz"
EOF

# Очищаем временную директорию
rm -rf "$TEMP_DIR"

log "✅ Файлы успешно загружены на сервер!"
log "🚀 Теперь можно запустить деплой: ssh root@212.34.134.169 'cd /opt/ai-quiz && ./scripts/deploy.sh'" 