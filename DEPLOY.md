# 🚀 Деплой AI Quiz на Ubuntu сервер

## 📋 Требования

- Ubuntu 24.04 сервер
- Доступ по SSH (root)
- Минимум 2GB RAM
- 10GB свободного места

## 🎯 Быстрый деплой

### 1. Автоматический деплой (рекомендуется)

```bash
# Сделайте скрипты исполняемыми
chmod +x scripts/*.sh

# Запустите полный деплой
./scripts/full-deploy.sh
```

Этот скрипт автоматически:
- Загрузит файлы на сервер
- Установит Docker и зависимости
- Соберет и запустит приложение
- Настроит автозапуск
- Проверит доступность

### 2. Пошаговый деплой

#### Шаг 1: Загрузка файлов
```bash
./scripts/upload.sh
```

#### Шаг 2: Установка на сервере
```bash
ssh root@212.34.134.169 'cd /opt/ai-quiz && chmod +x scripts/deploy.sh && ./scripts/deploy.sh'
```

## 🔧 Управление приложением

После деплоя используйте скрипт управления:

```bash
# Подключитесь к серверу
ssh root@212.34.134.169

# Перейдите в директорию приложения
cd /opt/ai-quiz

# Доступные команды
./scripts/manage.sh start    # Запустить
./scripts/manage.sh stop     # Остановить
./scripts/manage.sh restart  # Перезапустить
./scripts/manage.sh logs     # Показать логи
./scripts/manage.sh status   # Статус и ресурсы
./scripts/manage.sh update   # Обновить приложение
./scripts/manage.sh backup   # Создать резервную копию
./scripts/manage.sh clean    # Очистить Docker ресурсы
./scripts/manage.sh health   # Проверить здоровье
```

## 🌐 Доступ к приложению

После успешного деплоя приложение будет доступно:

- **Веб-интерфейс**: http://212.34.134.169
- **QR код для регистрации**: http://212.34.134.169/api/room/qr
- **API**: http://212.34.134.169/api/room

## 📁 Структура на сервере

```
/opt/ai-quiz/
├── backend/           # Backend код
├── frontend/          # Frontend код
├── scripts/           # Скрипты управления
├── logs/              # Логи приложения
├── docker-compose.yml # Конфигурация Docker
├── Dockerfile         # Образ приложения
└── manage.sh          # Скрипт управления
```

## 🔒 Безопасность

- Приложение запускается от непривилегированного пользователя
- Firewall настроен (порт 80 открыт)
- Автозапуск через systemd
- Логи сохраняются в отдельной директории

## 📊 Мониторинг

### Просмотр логов
```bash
# Логи в реальном времени
./scripts/manage.sh logs

# Логи Docker
docker-compose logs -f

# Системные логи
journalctl -u ai-quiz.service -f
```

### Статус приложения
```bash
# Статус контейнеров
./scripts/manage.sh status

# Использование ресурсов
docker stats

# Проверка здоровья
./scripts/manage.sh health
```

## 🔄 Обновление

### Автоматическое обновление
```bash
./scripts/manage.sh update
```

### Ручное обновление
```bash
# Остановить приложение
./scripts/manage.sh stop

# Обновить код (если используете git)
git pull origin main

# Пересобрать и запустить
docker-compose build --no-cache
./scripts/manage.sh start
```

## 🛠️ Устранение неполадок

### Приложение не запускается
```bash
# Проверить логи
./scripts/manage.sh logs

# Проверить статус Docker
docker ps -a

# Проверить системные ресурсы
df -h
free -h
```

### Проблемы с сетью
```bash
# Проверить firewall
ufw status

# Проверить порты
netstat -tlnp | grep :80

# Проверить доступность
curl -I http://localhost/api/room
```

### Очистка и перезапуск
```bash
# Полная очистка
./scripts/manage.sh stop
./scripts/manage.sh clean
./scripts/manage.sh start
```

## 📞 Поддержка

При возникновении проблем:

1. Проверьте логи: `./scripts/manage.sh logs`
2. Проверьте статус: `./scripts/manage.sh status`
3. Проверьте здоровье: `./scripts/manage.sh health`
4. Создайте резервную копию: `./scripts/manage.sh backup`

## 🎯 Особенности деплоя

- **Порт**: 80 (HTTP)
- **Автозапуск**: Да (systemd)
- **Логи**: /opt/ai-quiz/logs/
- **Резервные копии**: /tmp/ai-quiz-backup-*.tar.gz
- **QR код**: Автоматически настроен на IP сервера 