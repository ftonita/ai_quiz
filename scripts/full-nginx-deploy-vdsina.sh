#!/bin/bash

# Полный скрипт деплоя с Nginx для домена v386879.hosted-by-vdsina.com
# Использование: ./full-nginx-deploy-vdsina.sh [EMAIL]

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

log "Начинаем полный деплой с Nginx для домена: $DOMAIN"
log "Email для SSL: $EMAIL"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Шаг 1: Настройка Nginx
log "=== ШАГ 1: Настройка Nginx ==="
if [ -f "./scripts/setup-nginx-vdsina.sh" ]; then
    ./scripts/setup-nginx-vdsina.sh
else
    error "Скрипт setup-nginx-vdsina.sh не найден"
    exit 1
fi

# Проверка успешности настройки Nginx
if ! systemctl is-active --quiet nginx; then
    error "Nginx не запущен после настройки"
    exit 1
fi

success "Nginx настроен и запущен"

# Шаг 2: Получение SSL сертификата
log "=== ШАГ 2: Получение SSL сертификата ==="
if [ -f "./scripts/get-ssl-vdsina.sh" ]; then
    ./scripts/get-ssl-vdsina.sh "$EMAIL"
else
    error "Скрипт get-ssl-vdsina.sh не найден"
    exit 1
fi

# Проверка SSL сертификата
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    error "SSL сертификат не был получен"
    exit 1
fi

success "SSL сертификат получен"

# Шаг 3: Деплой приложения
log "=== ШАГ 3: Деплой приложения ==="
if [ -f "./scripts/deploy-with-nginx-vdsina.sh" ]; then
    ./scripts/deploy-with-nginx-vdsina.sh
else
    error "Скрипт deploy-with-nginx-vdsina.sh не найден"
    exit 1
fi

# Проверка статуса приложения
if ! docker-compose ps | grep -q "Up"; then
    error "Приложение не запущено после деплоя"
    exit 1
fi

success "Приложение запущено"

# Финальные проверки
log "=== ФИНАЛЬНЫЕ ПРОВЕРКИ ==="

# Проверка доступности по HTTPS
log "Проверяем доступность по HTTPS..."
sleep 10
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "HTTPS работает корректно"
else
    warning "HTTPS может быть недоступен"
fi

# Проверка WebSocket
log "Проверяем WebSocket..."
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/ws/room" | grep -q "101\|400\|404"; then
    success "WebSocket endpoint доступен"
else
    warning "WebSocket endpoint может быть недоступен"
fi

# Проверка API
log "Проверяем API..."
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/api/health" | grep -q "200"; then
    success "API работает корректно"
else
    warning "API может быть недоступен"
fi

# Проверка автоматического обновления SSL
log "Проверяем автоматическое обновление SSL..."
if certbot renew --dry-run > /dev/null 2>&1; then
    success "Автоматическое обновление SSL настроено"
else
    warning "Проблема с автоматическим обновлением SSL"
fi

# Создание скрипта управления
log "Создаем скрипт управления..."
cat > /usr/local/bin/quiz-manage << 'EOF'
#!/bin/bash

DOMAIN="v386879.hosted-by-vdsina.com"

case "$1" in
    start)
        systemctl start ai-quiz
        echo "Приложение запущено"
        ;;
    stop)
        systemctl stop ai-quiz
        echo "Приложение остановлено"
        ;;
    restart)
        systemctl restart ai-quiz
        echo "Приложение перезапущено"
        ;;
    status)
        systemctl status ai-quiz
        ;;
    logs)
        docker-compose logs -f
        ;;
    nginx-logs)
        tail -f /var/log/nginx/access.log
        ;;
    nginx-error-logs)
        tail -f /var/log/nginx/error.log
        ;;
    ssl-renew)
        certbot renew --quiet
        systemctl reload nginx
        echo "SSL сертификаты обновлены"
        ;;
    update-frontend)
        cd /opt/ai-quiz
        ./scripts/update-frontend-nginx-vdsina.sh
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|logs|nginx-logs|nginx-error-logs|ssl-renew|update-frontend}"
        echo ""
        echo "Команды:"
        echo "  start           - запустить приложение"
        echo "  stop            - остановить приложение"
        echo "  restart         - перезапустить приложение"
        echo "  status          - показать статус приложения"
        echo "  logs            - показать логи приложения"
        echo "  nginx-logs      - показать логи Nginx"
        echo "  nginx-error-logs - показать ошибки Nginx"
        echo "  ssl-renew       - обновить SSL сертификаты"
        echo "  update-frontend - обновить только фронтенд"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/quiz-manage

# Создание директории для логов
mkdir -p /opt/ai-quiz/logs
chown -R www-data:www-data /opt/ai-quiz/logs

# Финальное сообщение
echo ""
success "=== ПОЛНЫЙ ДЕПЛОЙ ЗАВЕРШЕН ==="
echo ""
log "Ваше приложение доступно по адресу: https://$DOMAIN"
echo ""
log "Управление приложением:"
log "  quiz-manage start           - запустить приложение"
log "  quiz-manage stop            - остановить приложение"
log "  quiz-manage restart         - перезапустить приложение"
log "  quiz-manage status          - показать статус"
log "  quiz-manage logs            - логи приложения"
log "  quiz-manage nginx-logs      - логи Nginx"
log "  quiz-manage ssl-renew       - обновить SSL"
log "  quiz-manage update-frontend - обновить фронтенд"
echo ""
log "Мониторинг:"
log "  systemctl status ai-quiz    - статус сервиса"
log "  docker-compose ps           - статус контейнеров"
log "  nginx -t                    - проверить конфигурацию Nginx"
echo ""
log "Логи:"
log "  /var/log/nginx/access.log   - логи доступа Nginx"
log "  /var/log/nginx/error.log    - ошибки Nginx"
log "  /opt/ai-quiz/logs/          - логи приложения"
echo ""
success "Деплой завершен успешно!" 