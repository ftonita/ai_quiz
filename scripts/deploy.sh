#!/bin/bash

# Скрипт деплоя AI Quiz на Ubuntu сервер
# IP: 212.34.134.169
# Порт: 80

set -e

echo "🚀 Начинаем деплой AI Quiz на сервер..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для логирования
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

# Проверяем, что мы root
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен выполняться от имени root"
fi

log "Обновляем систему..."
export DEBIAN_FRONTEND=noninteractive
apt update -y && apt upgrade -y

log "Устанавливаем необходимые пакеты..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

log "Устанавливаем Docker..."
# Удаляем старые версии Docker
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Добавляем официальный GPG ключ Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg --batch --yes

# Добавляем репозиторий Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновляем индекс пакетов
export DEBIAN_FRONTEND=noninteractive
apt update -y

# Устанавливаем Docker
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Запускаем Docker
systemctl start docker
systemctl enable docker

log "Устанавливаем Docker Compose..."
# Устанавливаем Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Создаем символическую ссылку
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

log "Создаем директорию для приложения..."
mkdir -p /opt/ai-quiz
cd /opt/ai-quiz

log "Клонируем репозиторий..."
# Если репозиторий уже существует, обновляем его
if [ -d ".git" ]; then
    git pull origin main
else
    # Здесь нужно будет заменить на реальный URL репозитория
    # git clone https://github.com/your-repo/ai-quiz.git .
    warning "Репозиторий не найден. Создаем структуру вручную..."
fi

log "Создаем docker-compose.yml для продакшена..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  quiz:
    build: .
    ports:
      - "80:8000"
    restart: unless-stopped
    environment:
      - PYTHONUNBUFFERED=1
    volumes:
      - ./logs:/app/logs
EOF

log "Создаем Dockerfile для продакшена..."
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

log "Создаем директорию для логов..."
mkdir -p logs

log "Обновляем конфигурацию для продакшена..."
# Обновляем URL в API для QR кода
sed -i 's|http://localhost:8000|http://212.34.134.169|g' backend/api.py

log "Пересобираем и запускаем приложение..."
# Останавливаем и удаляем все контейнеры и образы
docker-compose down --rmi all --volumes --remove-orphans 2>/dev/null || true
docker rmi ai-quiz-quiz 2>/dev/null || true

# Очищаем все Docker кэши
docker system prune -f
docker builder prune -f

# Принудительная пересборка без кэша
docker build --no-cache --pull -t ai-quiz-quiz .
docker-compose up -d

log "Проверяем статус приложения..."
sleep 10
if docker-compose ps | grep -q "Up"; then
    log "✅ Приложение успешно запущено!"
    log "🌐 Доступно по адресу: http://212.34.134.169"
    log "📱 QR код ведет на: http://212.34.134.169/api/room/register"
else
    error "❌ Ошибка запуска приложения"
fi

log "Настраиваем автозапуск..."
# Создаем systemd сервис
cat > /etc/systemd/system/ai-quiz.service << EOF
[Unit]
Description=AI Quiz Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/ai-quiz
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Включаем автозапуск
systemctl daemon-reload
systemctl enable ai-quiz.service

log "Настраиваем firewall..."
# Открываем порт 80
ufw allow 80/tcp
ufw allow 22/tcp
ufw --force enable

log "Проверяем доступность приложения..."
if curl -f http://localhost/api/room > /dev/null 2>&1; then
    log "✅ Приложение доступно локально"
else
    warning "⚠️ Приложение недоступно локально"
fi

log "🎉 Деплой завершен успешно!"
log "📋 Полезные команды:"
log "   - Просмотр логов: docker-compose logs -f"
log "   - Перезапуск: docker-compose restart"
log "   - Остановка: docker-compose down"
log "   - Обновление: git pull && docker-compose up -d --build" 