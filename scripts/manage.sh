#!/bin/bash

# Скрипт управления AI Quiz на сервере
# Использование: ./manage.sh [start|stop|restart|logs|status|update]

set -e

# Параметры
APP_DIR="/opt/ai-quiz"
SERVICE_NAME="ai-quiz"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Проверяем, что мы в правильной директории
if [ ! -f "$APP_DIR/docker-compose.yml" ]; then
    error "Приложение не найдено в $APP_DIR"
fi

cd "$APP_DIR"

case "$1" in
    start)
        log "Запускаем приложение..."
        docker-compose up -d
        log "✅ Приложение запущено"
        ;;
    stop)
        log "Останавливаем приложение..."
        docker-compose down
        log "✅ Приложение остановлено"
        ;;
    restart)
        log "Перезапускаем приложение..."
        docker-compose down
        docker-compose up -d
        log "✅ Приложение перезапущено"
        ;;
    logs)
        log "Показываем логи..."
        docker-compose logs -f
        ;;
    status)
        log "Статус приложения:"
        docker-compose ps
        echo ""
        log "Использование ресурсов:"
        docker stats --no-stream
        ;;
    update)
        log "Обновляем приложение..."
        # Останавливаем приложение
        docker-compose down
        
        # Обновляем код (если есть git репозиторий)
        if [ -d ".git" ]; then
            git pull origin main
        fi
        
        # Обновляем URL в API
        sed -i 's|http://localhost:8000|http://212.34.134.169|g' backend/api.py
        
        # Пересобираем и запускаем
        docker-compose build --no-cache
        docker-compose up -d
        
        log "✅ Приложение обновлено"
        ;;
    backup)
        log "Создаем резервную копию..."
        BACKUP_FILE="/tmp/ai-quiz-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        tar -czf "$BACKUP_FILE" --exclude='logs' .
        log "✅ Резервная копия создана: $BACKUP_FILE"
        ;;
    clean)
        log "Очищаем неиспользуемые Docker ресурсы..."
        docker system prune -f
        docker volume prune -f
        log "✅ Очистка завершена"
        ;;
    health)
        log "Проверяем здоровье приложения..."
        if curl -f http://localhost/api/room > /dev/null 2>&1; then
            log "✅ Приложение работает корректно"
        else
            error "❌ Приложение недоступно"
        fi
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|logs|status|update|backup|clean|health}"
        echo ""
        echo "Команды:"
        echo "  start   - Запустить приложение"
        echo "  stop    - Остановить приложение"
        echo "  restart - Перезапустить приложение"
        echo "  logs    - Показать логи"
        echo "  status  - Показать статус и ресурсы"
        echo "  update  - Обновить приложение"
        echo "  backup  - Создать резервную копию"
        echo "  clean   - Очистить Docker ресурсы"
        echo "  health  - Проверить здоровье приложения"
        exit 1
        ;;
esac 