# 🔐 Безопасность и управление секретами

## Обзор

Проект использует систему переменных окружения для безопасного хранения секретных данных (пароли, IP адреса, домены). Все секретные данные вынесены из скриптов в отдельные файлы, которые исключены из Git.

## Структура безопасности

### Файлы
- `scripts/export-secrets.sh` - скрипт для экспорта переменных окружения
- `.env` - файл с переменными окружения (исключен из Git)
- `.gitignore` - исключает секретные файлы из Git

### Переменные окружения

#### Основные настройки сервера
- `SERVER_IP` - IP адрес сервера
- `SERVER_USER` - пользователь для SSH
- `SERVER_PASSWORD` - пароль для SSH
- `SERVER_DOMAIN` - доменное имя

#### Настройки SSH
- `SSH_HOST` - хост для SSH подключения
- `SSH_USER` - пользователь SSH
- `SSH_PASSWORD` - пароль SSH
- `SSH_OPTS` - опции SSH

#### Настройки приложения
- `APP_NAME` - название приложения
- `APP_PATH` - путь к приложению на сервере

#### Настройки Nginx и SSL
- `NGINX_DOMAIN` - домен для Nginx
- `NGINX_EMAIL` - email для SSL сертификатов
- `SSL_EMAIL` - email для SSL
- `SSL_DOMAIN` - домен для SSL

#### Настройки Docker
- `DOCKER_IMAGE` - имя Docker образа
- `DOCKER_CONTAINER` - имя Docker контейнера

## Использование

### 1. Первоначальная настройка

```bash
# Создайте файл .env с вашими секретными данными
cp scripts/export-secrets.sh.example scripts/export-secrets.sh

# Отредактируйте файл с вашими данными
nano scripts/export-secrets.sh
```

### 2. Загрузка переменных окружения

```bash
# Загрузить переменные в текущую сессию
source scripts/export-secrets.sh

# Или использовать в скриптах
source scripts/export-secrets.sh
```

### 3. Использование в скриптах

Все скрипты автоматически загружают переменные окружения:

```bash
# Скрипты автоматически загружают секреты
./scripts/quick-redeploy.sh
./scripts/upload-and-deploy-vdsina-auto.sh
./scripts/test-connection.sh
```

### 4. Проверка переменных

```bash
# Проверить загруженные переменные
echo "Server IP: $SERVER_IP"
echo "Domain: $SERVER_DOMAIN"
echo "Email: $NGINX_EMAIL"
```

## Безопасность

### ✅ Что защищено
- Пароли не хранятся в коде
- IP адреса вынесены в переменные
- Домены настраиваются централизованно
- Файлы с секретами исключены из Git

### ⚠️ Важные моменты
- Файл `scripts/export-secrets.sh` содержит реальные секреты
- Не коммитьте этот файл в Git
- Храните резервную копию секретов в безопасном месте
- Регулярно меняйте пароли

### 🔒 Рекомендации
1. Используйте SSH ключи вместо паролей
2. Настройте firewall на сервере
3. Регулярно обновляйте SSL сертификаты
4. Мониторьте логи на предмет подозрительной активности

## Устранение неполадок

### Ошибка "Файл scripts/export-secrets.sh не найден"
```bash
# Создайте файл с секретами
cp scripts/export-secrets.sh.example scripts/export-secrets.sh
# Отредактируйте файл
nano scripts/export-secrets.sh
```

### Ошибка "Не все переменные окружения установлены"
```bash
# Проверьте файл export-secrets.sh
cat scripts/export-secrets.sh

# Убедитесь, что все переменные экспортированы
source scripts/export-secrets.sh
env | grep SERVER
```

### Переменные не загружаются
```bash
# Проверьте синтаксис файла
bash -n scripts/export-secrets.sh

# Загрузите вручную
source scripts/export-secrets.sh
```

## Миграция с хардкода

Если у вас есть старые скрипты с хардкодом секретов:

1. Замените хардкод на переменные окружения
2. Добавьте загрузку `source scripts/export-secrets.sh`
3. Добавьте проверку переменных
4. Протестируйте скрипт

### Пример миграции

**Было:**
```bash
SERVER_IP="212.34.134.169"
SERVER_PASS="password123"
sshpass -p "$SERVER_PASS" ssh root@$SERVER_IP
```

**Стало:**
```bash
source scripts/export-secrets.sh
sshpass -p "$SERVER_PASSWORD" ssh $SERVER_USER@$SERVER_IP
```

## Поддержка

При возникновении проблем с безопасностью:
1. Проверьте логи на сервере
2. Убедитесь, что файлы с секретами не попали в Git
3. При необходимости смените пароли
4. Проверьте права доступа к файлам 