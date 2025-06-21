#!/bin/bash

# Скрипт для быстрого обновления фронтенда в Nginx
# Использование: ./update-frontend-nginx.sh [DOMAIN]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ОШИБКА]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[УСПЕХ]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[ПРЕДУПРЕЖДЕНИЕ]${NC} $1"
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    error "Необходимо указать домен!"
    echo "Использование: $0 <domain>"
    echo "Пример: $0 example.com"
    exit 1
fi

DOMAIN=$1
log "🔄 Начинаем обновление фронтенда для домена: $DOMAIN"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Проверка, что приложение запущено
if ! docker-compose ps | grep -q "Up"; then
    error "Приложение не запущено. Запустите сначала: systemctl start ai-quiz"
    exit 1
fi

# Создание временного контейнера для сборки фронтенда
log "🔨 Создаем временный контейнер для сборки фронтенда..."
docker create --name temp-frontend-build \
    -v "$(pwd)/frontend:/app/frontend" \
    node:18 \
    bash -c "cd /app/frontend && rm -rf node_modules dist .npm .cache .vite .parcel-cache && npm cache clean --force && npm install --no-cache --prefer-offline=false && npm run build"

# Запуск сборки
log "📦 Собираем фронтенд..."
docker start temp-frontend-build
docker wait temp-frontend-build

# Проверка успешности сборки
if [ "$(docker inspect temp-frontend-build --format='{{.State.ExitCode}}')" != "0" ]; then
    error "Ошибка сборки фронтенда"
    docker logs temp-frontend-build
    docker rm temp-frontend-build
    exit 1
fi

# Копирование собранных файлов
log "📋 Копируем собранные файлы..."
docker cp temp-frontend-build:/app/frontend/dist/. /var/www/html/

# Очистка временного контейнера
docker rm temp-frontend-build

# Настройка прав доступа
log "🔐 Настраиваем права доступа..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Очистка кэша Nginx
log "🧹 Очищаем кэш Nginx..."
rm -rf /var/cache/nginx/* 2>/dev/null || true

# Перезапуск Nginx
log "🔄 Перезапускаем Nginx..."
systemctl reload nginx

# Проверка доступности
log "🔍 Проверяем доступность обновленного фронтенда..."
sleep 3

if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "Фронтенд успешно обновлен и доступен!"
else
    warning "Фронтенд может быть недоступен, проверьте вручную"
fi

success "✅ Обновление фронтенда завершено!"
log "🌐 Проверьте обновления по адресу: https://$DOMAIN"
log "💡 Для полного обновления (включая бэкенд) используйте: ./scripts/deploy-with-nginx.sh $DOMAIN" 