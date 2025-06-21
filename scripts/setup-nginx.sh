#!/bin/bash

# Скрипт для настройки Nginx на сервере
# Использование: ./setup-nginx.sh [DOMAIN]

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
log "Начинаем настройку Nginx для домена: $DOMAIN"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Обновление системы
log "Обновляем систему..."
apt-get update
apt-get upgrade -y

# Установка Nginx
log "Устанавливаем Nginx..."
apt-get install -y nginx

# Установка certbot для Let's Encrypt
log "Устанавливаем Certbot..."
apt-get install -y certbot python3-certbot-nginx

# Создание директорий
log "Создаем необходимые директории..."
mkdir -p /var/www/html
mkdir -p /var/www/certbot
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Настройка прав доступа
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/www/certbot

# Создание временной HTTP конфигурации
log "Создаем временную HTTP конфигурацию..."
cat > /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Статические файлы фронтенда
    location / {
        root /var/www/html;
        try_files \$uri \$uri/ /index.html;
    }

    # API проксирование
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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

# Активация сайта
log "Активируем конфигурацию сайта..."
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Удаление дефолтного сайта
if [ -f /etc/nginx/sites-enabled/default ]; then
    log "Удаляем дефолтный сайт Nginx..."
    rm /etc/nginx/sites-enabled/default
fi

# Проверка конфигурации Nginx
log "Проверяем конфигурацию Nginx..."
if nginx -t; then
    success "Конфигурация Nginx корректна"
else
    error "Ошибка в конфигурации Nginx"
    exit 1
fi

# Запуск Nginx
log "Запускаем Nginx..."
systemctl enable nginx
systemctl start nginx

# Настройка firewall
log "Настраиваем firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    ufw allow ssh
    ufw --force enable
    success "Firewall настроен"
else
    warning "UFW не найден, настройте firewall вручную"
fi

# Создание скрипта для обновления SSL
log "Создаем скрипт для обновления SSL сертификатов..."
cat > /usr/local/bin/renew-ssl.sh << 'EOF'
#!/bin/bash
certbot renew --quiet
systemctl reload nginx
EOF

chmod +x /usr/local/bin/renew-ssl.sh

# Добавление cron задачи для автоматического обновления сертификатов
log "Добавляем автоматическое обновление SSL сертификатов..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/local/bin/renew-ssl.sh") | crontab -

success "Nginx успешно настроен!"
log "Следующие шаги:"
log "1. Убедитесь, что DNS записи для домена $DOMAIN указывают на этот сервер"
log "2. Запустите скрипт получения SSL сертификата: ./scripts/get-ssl.sh $DOMAIN"
log "3. После получения сертификата запустите: ./scripts/deploy-with-nginx.sh"

# Проверка доступности
log "Проверяем доступность Nginx..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
    success "Nginx доступен на localhost"
else
    error "Nginx недоступен на localhost"
fi 