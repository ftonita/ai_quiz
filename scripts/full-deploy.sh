#!/bin/bash

# Полный деплой AI Quiz на Ubuntu сервер
# IP: 212.34.134.169
# User: root

set -e

echo "🚀 Полный деплой AI Quiz на сервер Ubuntu..."

# Параметры сервера
SERVER_IP="212.34.134.169"
SERVER_USER="root"
SERVER_PASS="581J44sT6RhSCap7"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Проверяем наличие необходимых файлов
if [ ! -f "backend/main.py" ]; then
    error "Файл backend/main.py не найден. Запустите скрипт из корневой директории проекта."
fi

if [ ! -f "frontend/package.json" ]; then
    error "Файл frontend/package.json не найден. Запустите скрипт из корневой директории проекта."
fi

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

log "Шаг 1: Загружаем файлы на сервер..."
./scripts/upload.sh

log "Шаг 2: Запускаем деплой на сервере..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" << 'EOF'
    cd /opt/ai-quiz
    chmod +x scripts/deploy.sh
    ./scripts/deploy.sh
EOF

log "Шаг 3: Проверяем доступность приложения..."
sleep 30

if curl -f "http://$SERVER_IP/api/room" > /dev/null 2>&1; then
    log "✅ Приложение успешно развернуто и доступно!"
    log ""
    log "🌐 Доступ к приложению:"
    log "   - Веб-интерфейс: http://$SERVER_IP"
    log "   - QR код: http://$SERVER_IP/api/room/qr"
    log "   - API: http://$SERVER_IP/api/room"
    log ""
    log "📋 Управление приложением:"
    log "   - Подключение к серверу: ssh root@$SERVER_IP"
    log "   - Просмотр логов: cd /opt/ai-quiz && ./scripts/manage.sh logs"
    log "   - Статус: cd /opt/ai-quiz && ./scripts/manage.sh status"
    log "   - Перезапуск: cd /opt/ai-quiz && ./scripts/manage.sh restart"
    log ""
    log "🎉 Деплой завершен успешно!"
else
    warning "⚠️ Приложение может быть недоступно. Проверьте логи на сервере:"
    warning "   ssh root@$SERVER_IP 'cd /opt/ai-quiz && ./scripts/manage.sh logs'"
fi 