#!/bin/bash

# Скрипт для экспорта секретных данных в переменные окружения
# Запускать: source scripts/export-secrets.sh

echo "🔐 Экспорт секретных данных в переменные окружения..."

# Основные настройки сервера
export SERVER_IP="212.34.134.169"
export SERVER_USER="root"
export SERVER_PASSWORD="581J44sT6RhSCap7"
export SERVER_DOMAIN="v386879.hosted-by-vdsina.com"

# Настройки SSH
export SSH_HOST="$SERVER_IP"
export SSH_USER="$SERVER_USER"
export SSH_PASSWORD="$SERVER_PASSWORD"
export SSH_OPTS="-o StrictHostKeyChecking=no"

# Настройки приложения
export APP_NAME="ai-quiz"
export APP_PATH="/opt/$APP_NAME"

# Настройки Nginx
export NGINX_DOMAIN="$SERVER_DOMAIN"
export NGINX_EMAIL="farmtonita@gmail.com"

# Настройки SSL
export SSL_EMAIL="$NGINX_EMAIL"
export SSL_DOMAIN="$NGINX_DOMAIN"

# Настройки Docker
export DOCKER_IMAGE="ai-quiz-quiz"
export DOCKER_CONTAINER="ai-quiz-app"

# Настройки базы данных (если понадобится в будущем)
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="quiz_db"
export DB_USER="quiz_user"
export DB_PASSWORD=""

# Настройки JWT (если понадобится в будущем)
export JWT_SECRET=""
export JWT_ALGORITHM="HS256"
export JWT_EXPIRES_IN="24h"

echo "✅ Переменные окружения экспортированы:"
echo "   SERVER_IP: $SERVER_IP"
echo "   SERVER_USER: $SERVER_USER"
echo "   SERVER_DOMAIN: $SERVER_DOMAIN"
echo "   NGINX_EMAIL: $NGINX_EMAIL"
echo ""
echo "💡 Для использования в других скриптах:"
echo "   source scripts/export-secrets.sh"
echo ""
echo "⚠️  ВАЖНО: Файл .env добавлен в .gitignore для безопасности" 