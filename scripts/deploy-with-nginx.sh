#!/bin/bash

# Скрипт для деплоя приложения с Nginx
# Использование: ./deploy-with-nginx.sh [DOMAIN]

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
log "Начинаем деплой приложения с Nginx для домена: $DOMAIN"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Проверка, что Nginx настроен
if [ ! -f "/etc/nginx/sites-available/$DOMAIN" ]; then
    error "Nginx не настроен для домена $DOMAIN"
    log "Сначала запустите: ./scripts/setup-nginx.sh $DOMAIN"
    exit 1
fi

# Проверка SSL сертификата
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    error "SSL сертификат не найден для домена $DOMAIN"
    log "Сначала запустите: ./scripts/get-ssl.sh $DOMAIN"
    exit 1
fi

# Остановка текущего приложения
log "Останавливаем текущее приложение..."
systemctl stop ai-quiz 2>/dev/null || true
docker-compose down 2>/dev/null || true

# Создание нового Dockerfile для работы с Nginx
log "Создаем Dockerfile для работы с Nginx..."
cat > Dockerfile << 'EOF'
# Многоэтапная сборка
FROM node:18 AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./

# Агрессивная очистка всех возможных кэшей
RUN rm -rf node_modules dist .npm .cache .vite .parcel-cache
RUN npm cache clean --force
RUN npm install --no-cache --prefer-offline=false
COPY frontend/ ./
RUN npm run build

FROM python:3.11-slim AS backend-build
WORKDIR /app
COPY backend/requirements.txt ./backend/
RUN pip install --upgrade pip && pip install -r backend/requirements.txt
COPY backend/ ./backend/
COPY --from=frontend-build /app/frontend/dist ./frontend_dist
COPY scripts/ ./scripts/

# Финальный образ
FROM python:3.11-slim
WORKDIR /app

# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Копируем Python зависимости
COPY --from=backend-build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=backend-build /usr/local/bin /usr/local/bin
COPY --from=backend-build /app/backend ./backend
COPY --from=backend-build /app/frontend_dist ./frontend_dist
COPY --from=backend-build /app/scripts ./scripts

RUN useradd -m -u 1000 quiz && chown -R quiz:quiz /app

USER quiz

CMD ["python", "-m", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Сборка Docker образа
log "Собираем Docker образ..."
docker build --no-cache --pull -t ai-quiz-quiz .

# Создание docker-compose.yml для работы с Nginx
log "Создаем docker-compose.yml для работы с Nginx..."
cat > docker-compose.yml << EOF
version: '3.8'
services:
  quiz:
    image: ai-quiz-quiz
    container_name: ai-quiz-app
    restart: unless-stopped
    ports:
      - "127.0.0.1:8000:8000"
    volumes:
      - ./logs:/app/logs
    environment:
      - ENVIRONMENT=production
    networks:
      - ai-quiz-network

networks:
  ai-quiz-network:
    driver: bridge
EOF

# Запуск приложения
log "Запускаем приложение..."
docker-compose up -d

# Ожидание запуска приложения
log "Ждем запуска приложения..."
sleep 10

# Проверка статуса приложения
if docker-compose ps | grep -q "Up"; then
    success "Приложение запущено"
else
    error "Ошибка запуска приложения"
    docker-compose logs
    exit 1
fi

# Копирование статических файлов фронтенда в Nginx директорию
log "Копируем статические файлы фронтенда..."
docker create --name temp-container ai-quiz-quiz
docker cp temp-container:/app/frontend_dist/. /var/www/html/
docker rm temp-container

# Настройка прав доступа
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Обновление конфигурации Nginx для работы с приложением
log "Обновляем конфигурацию Nginx..."
cat > /etc/nginx/sites-available/$DOMAIN << EOF
# HTTP -> HTTPS редирект
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL конфигурация
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL настройки безопасности
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Статические файлы фронтенда
    location / {
        root /var/www/html;
        try_files \$uri \$uri/ /index.html;
        
        # Кэширование статических файлов
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API проксирование
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Таймауты для API
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket проксирование
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket таймауты
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # QR код проксирование
    location /qr/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Здоровье приложения
    location /health {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Проверка конфигурации Nginx
log "Проверяем конфигурацию Nginx..."
if nginx -t; then
    success "Конфигурация Nginx корректна"
else
    error "Ошибка в конфигурации Nginx"
    exit 1
fi

# Перезапуск Nginx
log "Перезапускаем Nginx..."
systemctl reload nginx

# Создание systemd сервиса для автозапуска
log "Создаем systemd сервис для автозапуска..."
cat > /etc/systemd/system/ai-quiz.service << EOF
[Unit]
Description=AI Quiz Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/ai-quiz
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd и включение автозапуска
systemctl daemon-reload
systemctl enable ai-quiz

# Проверка доступности приложения
log "Проверяем доступность приложения..."
sleep 5

if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "Приложение доступно по HTTPS!"
else
    warning "Приложение может быть недоступно, проверьте вручную"
fi

# Проверка WebSocket
log "Проверяем WebSocket соединение..."
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/ws/room" | grep -q "101\|400\|404"; then
    success "WebSocket endpoint доступен"
else
    warning "WebSocket endpoint может быть недоступен"
fi

success "Деплой с Nginx завершен!"
log "Ваше приложение доступно по адресу: https://$DOMAIN"
log "Статус приложения: systemctl status ai-quiz"
log "Логи приложения: docker-compose logs -f"
log "Логи Nginx: tail -f /var/log/nginx/access.log" 