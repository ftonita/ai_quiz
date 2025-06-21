#!/bin/bash

# Скрипт для загрузки файлов на удаленный сервер и запуска деплоя с автоматической аутентификацией
# Использование: ./upload-and-deploy-vdsina-auto.sh [EMAIL]

set -e

# Загружаем секретные данные
if [ -f "scripts/export-secrets.sh" ]; then
    source scripts/export-secrets.sh
else
    echo "❌ Файл scripts/export-secrets.sh не найден!"
    echo "   Создайте его с секретными данными или установите переменные вручную"
    exit 1
fi

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
    EMAIL=$NGINX_EMAIL
    log "Email не указан, используем значение из переменных окружения: $EMAIL"
else
    EMAIL=$1
fi

# Проверяем наличие переменных окружения
if [ -z "$SERVER_IP" ] || [ -z "$SERVER_USER" ] || [ -z "$SERVER_PASSWORD" ] || [ -z "$SERVER_DOMAIN" ]; then
    error "Не все переменные окружения установлены. Проверьте scripts/export-secrets.sh"
    exit 1
fi

log "Начинаем загрузку и деплой на сервер: $SERVER_IP"
log "Email для SSL: $EMAIL"
log "Домен: $SERVER_DOMAIN"

# Проверка sshpass
if ! command -v sshpass &> /dev/null; then
    error "sshpass не установлен. Установите: brew install sshpass"
    exit 1
fi

# Проверка доступности сервера
log "Проверяем доступность сервера..."
if ! ping -c 1 $SERVER_IP > /dev/null 2>&1; then
    error "Сервер $SERVER_IP недоступен"
    exit 1
fi

success "Сервер доступен"

# Создание временной директории на сервере
log "Создаем временную директорию на сервере..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "mkdir -p /tmp/ai-quiz-deploy"

# Загрузка основных файлов проекта
log "Загружаем основные файлы проекта..."
sshpass -p "$SERVER_PASSWORD" scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -r backend/ "$SERVER_USER@$SERVER_IP:/tmp/ai-quiz-deploy/"
sshpass -p "$SERVER_PASSWORD" scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -r frontend/ "$SERVER_USER@$SERVER_IP:/tmp/ai-quiz-deploy/"
sshpass -p "$SERVER_PASSWORD" scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -r scripts/ "$SERVER_USER@$SERVER_IP:/tmp/ai-quiz-deploy/"
sshpass -p "$SERVER_PASSWORD" scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no Dockerfile "$SERVER_USER@$SERVER_IP:/tmp/ai-quiz-deploy/" 2>/dev/null || true
sshpass -p "$SERVER_PASSWORD" scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no docker-compose.yml "$SERVER_USER@$SERVER_IP:/tmp/ai-quiz-deploy/" 2>/dev/null || true

# Загрузка документации
log "Загружаем документацию..."
sshpass -p "$SERVER_PASSWORD" scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no NGINX_DEPLOY_VDSINA.md "$SERVER_USER@$SERVER_IP:/tmp/ai-quiz-deploy/"

# Создание рабочей директории на сервере
log "Создаем рабочую директорию на сервере..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "mkdir -p $APP_PATH"

# Перемещение файлов в рабочую директорию
log "Перемещаем файлы в рабочую директорию..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "cp -r /tmp/ai-quiz-deploy/* $APP_PATH/ && chmod +x $APP_PATH/scripts/*.sh"

# Переход в рабочую директорию и запуск деплоя
log "Запускаем полный деплой на сервере..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "cd $APP_PATH && ./scripts/full-nginx-deploy-vdsina.sh $EMAIL"

# Очистка временных файлов
log "Очищаем временные файлы..."
sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "rm -rf /tmp/ai-quiz-deploy"

# Проверка результата
log "Проверяем результат деплоя..."
sleep 10

# Проверка доступности приложения
if curl -s -o /dev/null -w "%{http_code}" "https://$SERVER_DOMAIN" | grep -q "200"; then
    success "Приложение успешно развернуто и доступно!"
    log "Ваше приложение доступно по адресу: https://$SERVER_DOMAIN"
else
    warning "Приложение может быть недоступно, проверьте вручную"
    log "Проверьте логи на сервере: sshpass -p '$SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP 'quiz-manage logs'"
fi

# Создание локального скрипта для управления удаленным сервером
log "Создаем локальный скрипт управления..."
cat > manage-remote-auto.sh << EOF
#!/bin/bash

# Скрипт для управления удаленным сервером с автоматической аутентификацией
# Использование: ./manage-remote-auto.sh [команда]

# Загружаем секретные данные
if [ -f "scripts/export-secrets.sh" ]; then
    source scripts/export-secrets.sh
else
    echo "❌ Файл scripts/export-secrets.sh не найден!"
    exit 1
fi

case "\$1" in
    status)
        sshpass -p "\$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "\$SERVER_USER@\$SERVER_IP" "quiz-manage status"
        ;;
    logs)
        sshpass -p "\$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "\$SERVER_USER@\$SERVER_IP" "quiz-manage logs"
        ;;
    nginx-logs)
        sshpass -p "\$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "\$SERVER_USER@\$SERVER_IP" "quiz-manage nginx-logs"
        ;;
    restart)
        sshpass -p "\$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "\$SERVER_USER@\$SERVER_IP" "quiz-manage restart"
        ;;
    update-frontend)
        sshpass -p "\$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "\$SERVER_USER@\$SERVER_IP" "cd \$APP_PATH && ./scripts/update-frontend-nginx-vdsina.sh"
        ;;
    ssl-renew)
        sshpass -p "\$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "\$SERVER_USER@\$SERVER_IP" "quiz-manage ssl-renew"
        ;;
    connect)
        sshpass -p "\$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "\$SERVER_USER@\$SERVER_IP"
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

chmod +x manage-remote-auto.sh

success "Загрузка и деплой завершены!"
echo ""
log "Управление удаленным сервером:"
log "  ./manage-remote-auto.sh status         - статус приложения"
log "  ./manage-remote-auto.sh logs           - логи приложения"
log "  ./manage-remote-auto.sh nginx-logs     - логи Nginx"
log "  ./manage-remote-auto.sh restart        - перезапустить"
log "  ./manage-remote-auto.sh update-frontend - обновить фронтенд"
log "  ./manage-remote-auto.sh ssl-renew      - обновить SSL"
log "  ./manage-remote-auto.sh connect        - подключиться к серверу"
echo ""
log "Прямое подключение к серверу:"
log "  sshpass -p '$SERVER_PASSWORD' ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP"
echo ""
log "Ваше приложение доступно по адресу: https://$SERVER_DOMAIN" 