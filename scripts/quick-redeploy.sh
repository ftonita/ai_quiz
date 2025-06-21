#!/bin/bash

# Быстрый передеплой AI Quiz
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

echo "🔄 Быстрый передеплой AI Quiz..."

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

# Проверяем наличие sshpass
if ! command -v sshpass &> /dev/null; then
    error "sshpass не установлен. Установите: brew install sshpass"
fi

# Проверяем наличие переменных окружения
if [ -z "$SERVER_IP" ] || [ -z "$SERVER_USER" ] || [ -z "$SERVER_PASSWORD" ]; then
    error "Не все переменные окружения установлены. Проверьте scripts/export-secrets.sh"
fi

log "Останавливаем приложение на сервере..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "
    cd $APP_PATH
    docker-compose down
"

log "Загружаем обновленные файлы..."
# Загружаем только измененные файлы
sshpass -p "$SERVER_PASSWORD" scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
    backend/api.py \
    "$SERVER_USER@$SERVER_IP:$APP_PATH/backend/"

log "Пересобираем и запускаем приложение..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "
    cd $APP_PATH
    docker-compose build --no-cache
    docker-compose up -d
"

log "Ждем запуска приложения..."
sleep 10

log "Проверяем статус приложения..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "
    cd $APP_PATH
    docker-compose ps
"

log "Тестируем доступность..."
if curl -f -s "http://$SERVER_IP/" > /dev/null; then
    log "✅ Приложение успешно запущено и доступно!"
    log "🌐 URL: http://$SERVER_IP/"
    log "📱 QR код теперь ведет на главную страницу"
else
    warning "⚠️ Приложение может быть еще не готово. Проверьте логи:"
    sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "
        cd $APP_PATH
        docker-compose logs --tail=20
    "
fi

echo ""
log "🎉 Быстрый передеплой завершен!"

# Запускаем скрипт с вашим реальным email
./scripts/upload-and-deploy-vdsina-auto.sh $NGINX_EMAIL