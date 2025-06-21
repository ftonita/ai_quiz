#!/bin/bash

# Скрипт для быстрого обновления приложения на удаленном сервере
# Использование: ./quick-update-remote-vdsina.sh [SERVER_IP]

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
    error "Необходимо указать IP сервера!"
    echo "Использование: $0 <SERVER_IP>"
    echo "Пример: $0 192.168.1.100"
    exit 1
fi

SERVER_IP=$1
DOMAIN="v386879.hosted-by-vdsina.com"

log "Начинаем быстрое обновление на сервере: $SERVER_IP"

# Проверка доступности сервера
log "Проверяем доступность сервера..."
if ! ping -c 1 $SERVER_IP > /dev/null 2>&1; then
    error "Сервер $SERVER_IP недоступен"
    exit 1
fi

success "Сервер доступен"

# Создание временной директории на сервере
log "Создаем временную директорию на сервере..."
ssh root@$SERVER_IP "mkdir -p /tmp/ai-quiz-update"

# Загрузка обновленных файлов
log "Загружаем обновленные файлы..."
scp -r backend/ root@$SERVER_IP:/tmp/ai-quiz-update/
scp -r frontend/ root@$SERVER_IP:/tmp/ai-quiz-update/
scp -r scripts/ root@$SERVER_IP:/tmp/ai-quiz-update/
scp Dockerfile root@$SERVER_IP:/tmp/ai-quiz-update/ 2>/dev/null || true
scp docker-compose.yml root@$SERVER_IP:/tmp/ai-quiz-update/ 2>/dev/null || true

# Остановка приложения
log "Останавливаем приложение..."
ssh root@$SERVER_IP "cd /opt/ai-quiz && docker-compose down" 2>/dev/null || true

# Обновление файлов
log "Обновляем файлы приложения..."
ssh root@$SERVER_IP "cp -r /tmp/ai-quiz-update/* /opt/ai-quiz/ && chmod +x /opt/ai-quiz/scripts/*.sh"

# Пересборка и запуск приложения
log "Пересобираем и запускаем приложение..."
ssh root@$SERVER_IP "cd /opt/ai-quiz && docker-compose up -d --build"

# Очистка временных файлов
log "Очищаем временные файлы..."
ssh root@$SERVER_IP "rm -rf /tmp/ai-quiz-update"

# Проверка результата
log "Проверяем результат обновления..."
sleep 10

# Проверка статуса приложения
if ssh root@$SERVER_IP "cd /opt/ai-quiz && docker-compose ps | grep -q 'Up'"; then
    success "Приложение успешно обновлено и запущено!"
else
    error "Ошибка при обновлении приложения"
    log "Проверьте логи: ssh root@$SERVER_IP 'cd /opt/ai-quiz && docker-compose logs'"
    exit 1
fi

# Проверка доступности
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"; then
    success "Приложение доступно после обновления!"
    log "Обновленное приложение доступно по адресу: https://$DOMAIN"
else
    warning "Приложение может быть недоступно, проверьте вручную"
fi

success "Быстрое обновление завершено!" 