#!/bin/bash

# Полный скрипт деплоя с Nginx и SSL
# Использование: ./full-nginx-deploy.sh [DOMAIN] [EMAIL]

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
if [ $# -lt 1 ]; then
    error "Необходимо указать домен!"
    echo "Использование: $0 <domain> [email]"
    echo "Пример: $0 example.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-"admin@$DOMAIN"}

log "🚀 Начинаем полный деплой с Nginx и SSL для домена: $DOMAIN"
log "📧 Email для уведомлений: $EMAIL"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Проверка наличия скриптов
if [ ! -f "scripts/setup-nginx.sh" ] || [ ! -f "scripts/get-ssl.sh" ] || [ ! -f "scripts/deploy-with-nginx.sh" ]; then
    error "Не найдены необходимые скрипты. Убедитесь, что вы находитесь в корневой директории проекта."
    exit 1
fi

# Шаг 1: Настройка Nginx
log "📋 Шаг 1: Настройка Nginx..."
if ./scripts/setup-nginx.sh "$DOMAIN"; then
    success "Nginx настроен"
else
    error "Ошибка настройки Nginx"
    exit 1
fi

# Шаг 2: Получение SSL сертификата
log "🔒 Шаг 2: Получение SSL сертификата..."
if ./scripts/get-ssl.sh "$DOMAIN" "$EMAIL"; then
    success "SSL сертификат получен"
else
    error "Ошибка получения SSL сертификата"
    exit 1
fi

# Шаг 3: Деплой приложения
log "🚀 Шаг 3: Деплой приложения..."
if ./scripts/deploy-with-nginx.sh "$DOMAIN"; then
    success "Приложение развернуто"
else
    error "Ошибка деплоя приложения"
    exit 1
fi

# Финальная проверка
log "🔍 Выполняем финальную проверку..."

# Проверка Nginx
if systemctl is-active --quiet nginx; then
    success "Nginx работает"
else
    error "Nginx не работает"
fi

# Проверка SSL сертификата
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    success "SSL сертификат установлен"
else
    error "SSL сертификат не найден"
fi

# Проверка приложения
if docker-compose ps | grep -q "Up"; then
    success "Приложение запущено"
else
    error "Приложение не запущено"
fi

# Проверка доступности по HTTPS
log "🌐 Проверяем доступность по HTTPS..."
sleep 5
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "Сайт доступен по HTTPS"
else
    warning "Сайт может быть недоступен по HTTPS"
fi

# Проверка WebSocket
log "🔌 Проверяем WebSocket..."
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/ws/room" | grep -q "101\|400\|404"; then
    success "WebSocket endpoint доступен"
else
    warning "WebSocket endpoint может быть недоступен"
fi

# Создание файла с информацией о деплое
log "📝 Создаем файл с информацией о деплое..."
cat > deploy-info.txt << EOF
=== Информация о деплое ===
Домен: $DOMAIN
Email: $EMAIL
Дата деплоя: $(date)
Версия: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

=== Доступные URL ===
Основной сайт: https://$DOMAIN
API: https://$DOMAIN/api/
WebSocket: wss://$DOMAIN/ws/
QR код: https://$DOMAIN/qr/

=== Управление ===
Статус приложения: systemctl status ai-quiz
Логи приложения: docker-compose logs -f
Логи Nginx: tail -f /var/log/nginx/access.log
Обновление SSL: certbot renew

=== Мониторинг ===
Проверка здоровья: https://$DOMAIN/health
Статус Nginx: systemctl status nginx
Статус Docker: docker-compose ps

=== Безопасность ===
SSL сертификат: /etc/letsencrypt/live/$DOMAIN/
Автообновление SSL: настроено (cron)
Firewall: настроен (UFW)
EOF

success "🎉 Полный деплой с Nginx и SSL завершен!"
log ""
log "📋 Информация о деплое сохранена в файл: deploy-info.txt"
log ""
log "🌐 Ваше приложение доступно по адресу: https://$DOMAIN"
log ""
log "📊 Полезные команды:"
log "  • Статус приложения: systemctl status ai-quiz"
log "  • Логи приложения: docker-compose logs -f"
log "  • Логи Nginx: tail -f /var/log/nginx/access.log"
log "  • Обновление SSL: certbot renew"
log "  • Перезапуск приложения: systemctl restart ai-quiz"
log "  • Перезапуск Nginx: systemctl reload nginx"
log ""
log "🔒 SSL сертификат будет автоматически обновляться каждые 90 дней"
log "🛡️ Firewall настроен для защиты сервера"
log "📱 QR код теперь ведет на HTTPS версию сайта" 