#!/bin/bash

# Скрипт для получения SSL сертификатов Let's Encrypt для домена v386879.hosted-by-vdsina.com
# Использование: ./get-ssl-vdsina.sh [EMAIL]

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
    error "Необходимо указать email!"
    echo "Использование: $0 <email>"
    echo "Пример: $0 admin@example.com"
    exit 1
fi

DOMAIN="v386879.hosted-by-vdsina.com"
EMAIL=$1

log "Начинаем получение SSL сертификата для домена: $DOMAIN"
log "Email для уведомлений: $EMAIL"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Проверка доступности домена
log "Проверяем доступность домена..."
if ! nslookup $DOMAIN > /dev/null 2>&1; then
    error "Домен $DOMAIN недоступен. Проверьте DNS настройки."
    exit 1
fi

# Проверка, что Nginx запущен
if ! systemctl is-active --quiet nginx; then
    error "Nginx не запущен. Запустите сначала setup-nginx-vdsina.sh"
    exit 1
fi

# Проверка, что порт 80 доступен
if ! netstat -tlnp | grep -q ":80 "; then
    error "Порт 80 не слушается. Проверьте настройки Nginx."
    exit 1
fi

# Остановка приложения на порту 8000 если запущено
if systemctl is-active --quiet ai-quiz; then
    log "Останавливаем приложение для получения сертификата..."
    systemctl stop ai-quiz
fi

# Создание временного файла для проверки доступности
log "Создаем временный файл для проверки доступности домена..."
mkdir -p /var/www/html
echo "Domain verification in progress..." > /var/www/html/index.html
chown -R www-data:www-data /var/www/html

# Перезапуск Nginx
log "Перезапускаем Nginx..."
systemctl reload nginx

# Проверка доступности домена извне
log "Проверяем доступность домена извне..."
sleep 5

if ! curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" | grep -q "200"; then
    error "Домен $DOMAIN недоступен извне. Проверьте:"
    error "1. DNS записи указывают на этот сервер"
    error "2. Firewall разрешает входящие соединения на порт 80"
    error "3. Провайдер не блокирует порт 80"
    exit 1
fi

success "Домен доступен извне"

# Получение SSL сертификата
log "Получаем SSL сертификат от Let's Encrypt..."
if certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive; then
    success "SSL сертификат успешно получен!"
else
    error "Ошибка при получении SSL сертификата"
    log "Попробуйте запустить вручную:"
    log "certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos"
    exit 1
fi

# Проверка конфигурации Nginx
log "Проверяем конфигурацию Nginx..."
if nginx -t; then
    success "Конфигурация Nginx корректна"
else
    error "Ошибка в конфигурации Nginx после получения сертификата"
    exit 1
fi

# Перезапуск Nginx
log "Перезапускаем Nginx с SSL конфигурацией..."
systemctl reload nginx

# Проверка SSL сертификата
log "Проверяем SSL сертификат..."
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "HTTPS работает корректно!"
else
    warning "HTTPS может быть недоступен, проверьте вручную"
fi

# Проверка автоматического обновления
log "Проверяем настройки автоматического обновления..."
if certbot renew --dry-run; then
    success "Автоматическое обновление сертификатов настроено"
else
    warning "Проблема с автоматическим обновлением сертификатов"
fi

# Создание финальной конфигурации
log "Создаем финальную конфигурацию Nginx..."
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

# Перезапуск Nginx с финальной конфигурацией
log "Применяем финальную конфигурацию..."
systemctl reload nginx

success "SSL сертификат успешно настроен для домена $DOMAIN!"
log "Ваш сайт теперь доступен по адресу: https://$DOMAIN"
log "Следующий шаг: запустите ./scripts/deploy-with-nginx-vdsina.sh для деплоя приложения" 