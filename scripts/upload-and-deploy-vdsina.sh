#!/bin/bash

# Скрипт для загрузки файлов на удаленный сервер и запуска деплоя
# Использование: ./upload-and-deploy-vdsina.sh [SERVER_IP] [EMAIL]

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
if [ $# -lt 2 ]; then
    error "Необходимо указать IP сервера и email!"
    echo "Использование: $0 <SERVER_IP> <EMAIL>"
    echo "Пример: $0 192.168.1.100 admin@example.com"
    exit 1
fi

SERVER_IP=$1
EMAIL=$2
DOMAIN="v386879.hosted-by-vdsina.com"

log "Начинаем загрузку и деплой на сервер: $SERVER_IP"
log "Email для SSL: $EMAIL"
log "Домен: $DOMAIN"

# Проверка доступности сервера
log "Проверяем доступность сервера..."
if ! ping -c 1 $SERVER_IP > /dev/null 2>&1; then
    error "Сервер $SERVER_IP недоступен"
    exit 1
fi

success "Сервер доступен"

# Создание временной директории на сервере
log "Создаем временную директорию на сервере..."
ssh root@$SERVER_IP "mkdir -p /tmp/ai-quiz-deploy"

# Загрузка основных файлов проекта
log "Загружаем основные файлы проекта..."
scp -r backend/ root@$SERVER_IP:/tmp/ai-quiz-deploy/
scp -r frontend/ root@$SERVER_IP:/tmp/ai-quiz-deploy/
scp -r scripts/ root@$SERVER_IP:/tmp/ai-quiz-deploy/
scp Dockerfile root@$SERVER_IP:/tmp/ai-quiz-deploy/ 2>/dev/null || true
scp docker-compose.yml root@$SERVER_IP:/tmp/ai-quiz-deploy/ 2>/dev/null || true

# Загрузка документации
log "Загружаем документацию..."
scp NGINX_DEPLOY_VDSINA.md root@$SERVER_IP:/tmp/ai-quiz-deploy/

# Создание рабочей директории на сервере
log "Создаем рабочую директорию на сервере..."
ssh root@$SERVER_IP "mkdir -p /opt/ai-quiz"

# Перемещение файлов в рабочую директорию
log "Перемещаем файлы в рабочую директорию..."
ssh root@$SERVER_IP "cp -r /tmp/ai-quiz-deploy/* /opt/ai-quiz/ && chmod +x /opt/ai-quiz/scripts/*.sh"

# Переход в рабочую директорию и запуск деплоя
log "Запускаем полный деплой на сервере..."
ssh root@$SERVER_IP "cd /opt/ai-quiz && ./scripts/full-nginx-deploy-vdsina.sh $EMAIL"

# Очистка временных файлов
log "Очищаем временные файлы..."
ssh root@$SERVER_IP "rm -rf /tmp/ai-quiz-deploy"

# Проверка результата
log "Проверяем результат деплоя..."
sleep 10

# Проверка доступности приложения
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "Приложение успешно развернуто и доступно!"
    log "Ваше приложение доступно по адресу: https://$DOMAIN"
else
    warning "Приложение может быть недоступно, проверьте вручную"
    log "Проверьте логи на сервере: ssh root@$SERVER_IP 'quiz-manage logs'"
fi

# Создание локального скрипта для управления удаленным сервером
log "Создаем локальный скрипт управления..."
cat > manage-remote.sh << EOF
#!/bin/bash

# Скрипт для управления удаленным сервером
# Использование: ./manage-remote.sh [команда]

SERVER_IP="$SERVER_IP"

case "\$1" in
    status)
        ssh root@\$SERVER_IP "quiz-manage status"
        ;;
    logs)
        ssh root@\$SERVER_IP "quiz-manage logs"
        ;;
    nginx-logs)
        ssh root@\$SERVER_IP "quiz-manage nginx-logs"
        ;;
    restart)
        ssh root@\$SERVER_IP "quiz-manage restart"
        ;;
    update-frontend)
        ssh root@\$SERVER_IP "cd /opt/ai-quiz && ./scripts/update-frontend-nginx-vdsina.sh"
        ;;
    ssl-renew)
        ssh root@\$SERVER_IP "quiz-manage ssl-renew"
        ;;
    connect)
        ssh root@\$SERVER_IP
        ;;
    *)
        echo "Использование: \$0 {status|logs|nginx-logs|restart|update-frontend|ssl-renew|connect}"
        echo ""
        echo "Команды:"
        echo "  status         - статус приложения"
        echo "  logs           - логи приложения"
        echo "  nginx-logs     - логи Nginx"
        echo "  restart        - перезапустить приложение"
        echo "  update-frontend - обновить фронтенд"
        echo "  ssl-renew      - обновить SSL сертификаты"
        echo "  connect        - подключиться к серверу"
        exit 1
        ;;
esac
EOF

chmod +x manage-remote.sh

success "Загрузка и деплой завершены!"
echo ""
log "Управление удаленным сервером:"
log "  ./manage-remote.sh status         - статус приложения"
log "  ./manage-remote.sh logs           - логи приложения"
log "  ./manage-remote.sh nginx-logs     - логи Nginx"
log "  ./manage-remote.sh restart        - перезапустить"
log "  ./manage-remote.sh update-frontend - обновить фронтенд"
log "  ./manage-remote.sh ssl-renew      - обновить SSL"
log "  ./manage-remote.sh connect        - подключиться к серверу"
echo ""
log "Прямое подключение к серверу:"
log "  ssh root@$SERVER_IP"
echo ""
log "Ваше приложение доступно по адресу: https://$DOMAIN" 