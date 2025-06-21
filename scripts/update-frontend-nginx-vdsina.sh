#!/bin/bash

# Скрипт для быстрого обновления фронтенда с Nginx для домена v386879.hosted-by-vdsina.com
# Использование: ./update-frontend-nginx-vdsina.sh

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

DOMAIN="v386879.hosted-by-vdsina.com"
log "Начинаем обновление фронтенда для домена: $DOMAIN"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Проверка, что приложение запущено
if ! docker-compose ps | grep -q "Up"; then
    error "Приложение не запущено. Запустите сначала полный деплой."
    exit 1
fi

# Остановка приложения
log "Останавливаем приложение для обновления..."
docker-compose down

# Создание временного Dockerfile только для фронтенда
log "Создаем временный Dockerfile для сборки фронтенда..."
cat > Dockerfile.frontend << 'EOF'
FROM node:18 AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./

# Агрессивная очистка всех возможных кэшей
RUN rm -rf node_modules dist .npm .cache .vite .parcel-cache
RUN npm cache clean --force
RUN npm install --no-cache --prefer-offline=false
COPY frontend/ ./
RUN npm run build

FROM alpine:latest
WORKDIR /app
COPY --from=frontend-build /app/frontend/dist ./frontend_dist
CMD ["sh", "-c", "cp -r /app/frontend_dist/* /var/www/html/ && chown -R www-data:www-data /var/www/html"]
EOF

# Сборка образа фронтенда
log "Собираем образ фронтенда..."
docker build -f Dockerfile.frontend -t ai-quiz-frontend-temp .

# Создание временного контейнера для копирования файлов
log "Копируем обновленные файлы фронтенда..."
docker run --rm -v /var/www/html:/var/www/html ai-quiz-frontend-temp

# Настройка прав доступа
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Очистка временных файлов
log "Очищаем временные файлы..."
rm -f Dockerfile.frontend
docker rmi ai-quiz-frontend-temp 2>/dev/null || true

# Перезапуск приложения
log "Перезапускаем приложение..."
docker-compose up -d

# Ожидание запуска
log "Ждем запуска приложения..."
sleep 5

# Проверка статуса
if docker-compose ps | grep -q "Up"; then
    success "Приложение перезапущено"
else
    error "Ошибка перезапуска приложения"
    docker-compose logs
    exit 1
fi

# Перезагрузка Nginx для применения изменений
log "Перезагружаем Nginx..."
systemctl reload nginx

# Проверка доступности
log "Проверяем доступность обновленного фронтенда..."
sleep 3

if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "Фронтенд обновлен и доступен!"
else
    warning "Фронтенд может быть недоступен, проверьте вручную"
fi

success "Обновление фронтенда завершено для домена $DOMAIN!"
log "Обновленный фронтенд доступен по адресу: https://$DOMAIN" 