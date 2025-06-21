#!/bin/bash

# Тестирование подключения к серверу
# Загружает секретные данные из переменных окружения

set -e

# Загружаем секретные данные
if [ -f "scripts/export-secrets.sh" ]; then
    source scripts/export-secrets.sh
else
    echo "❌ Файл scripts/export-secrets.sh не найден!"
    echo "   Создайте его с секретными данными или установите переменные вручную"
    exit 1
fi

echo "🔍 Тестирование подключения к серверу..."

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Проверяем наличие переменных окружения
if [ -z "$SERVER_IP" ] || [ -z "$SERVER_USER" ] || [ -z "$SERVER_PASSWORD" ]; then
    error "Не все переменные окружения установлены. Проверьте scripts/export-secrets.sh"
fi

# Проверяем наличие sshpass
if ! command -v sshpass &> /dev/null; then
    error "sshpass не установлен. Установите: brew install sshpass (macOS) или sudo apt-get install sshpass (Linux)"
fi

log "Тестируем подключение по SSH..."
if sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "echo 'SSH подключение успешно'" 2>/dev/null; then
    log "✅ SSH подключение работает"
else
    error "❌ Не удалось подключиться по SSH"
fi

log "Проверяем версию Ubuntu..."
OS_VERSION=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "lsb_release -d | cut -f2")
log "📋 Операционная система: $OS_VERSION"

log "Проверяем свободное место..."
DISK_SPACE=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "df -h / | tail -1 | awk '{print \$4}'")
log "💾 Свободное место: $DISK_SPACE"

log "Проверяем RAM..."
RAM=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "free -h | grep Mem | awk '{print \$2}'")
log "🧠 Общий RAM: $RAM"

log "Проверяем доступность порта 80..."
if sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "netstat -tlnp | grep :80" 2>/dev/null; then
    warning "⚠️ Порт 80 уже занят"
else
    log "✅ Порт 80 свободен"
fi

log "Проверяем наличие Docker..."
if sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "docker --version" 2>/dev/null; then
    DOCKER_VERSION=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "docker --version")
    log "🐳 Docker уже установлен: $DOCKER_VERSION"
else
    log "📦 Docker не установлен (будет установлен автоматически)"
fi

log "Проверяем firewall..."
UFW_STATUS=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "ufw status | head -1")
log "🔥 Firewall: $UFW_STATUS"

log "🎉 Тестирование подключения завершено успешно!"
log "✅ Сервер готов к деплою"
log ""
log "🚀 Для запуска деплоя выполните:"
log "   ./scripts/full-deploy.sh" 