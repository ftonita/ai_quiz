# Деплой с Nginx и SSL сертификатами

Этот документ описывает процесс настройки и деплоя приложения AI Quiz с использованием Nginx в качестве обратного прокси и SSL сертификатов Let's Encrypt.

## 🚀 Быстрый старт

Для полного деплоя с Nginx и SSL выполните одну команду:

```bash
sudo ./scripts/full-nginx-deploy.sh your-domain.com your-email@example.com
```

Этот скрипт автоматически выполнит все необходимые шаги:
1. Настройку Nginx
2. Получение SSL сертификата
3. Деплой приложения

## 📋 Пошаговый деплой

### 1. Подготовка сервера

Убедитесь, что у вас есть:
- Ubuntu/Debian сервер с root доступом
- Домен, указывающий на IP адрес сервера
- Docker и Docker Compose установлены

### 2. Настройка Nginx

```bash
sudo ./scripts/setup-nginx.sh your-domain.com
```

Этот скрипт:
- Устанавливает Nginx
- Устанавливает Certbot для Let's Encrypt
- Настраивает базовую конфигурацию
- Настраивает firewall (UFW)
- Создает cron задачу для автоматического обновления SSL

### 3. Получение SSL сертификата

```bash
sudo ./scripts/get-ssl.sh your-domain.com your-email@example.com
```

Этот скрипт:
- Проверяет доступность домена
- Получает SSL сертификат от Let's Encrypt
- Настраивает HTTPS конфигурацию Nginx
- Тестирует SSL сертификат

### 4. Деплой приложения

```bash
sudo ./scripts/deploy-with-nginx.sh your-domain.com
```

Этот скрипт:
- Собирает Docker образ
- Запускает приложение
- Копирует статические файлы фронтенда в Nginx директорию
- Настраивает systemd сервис для автозапуска
- Проверяет доступность приложения

## 🔧 Управление приложением

### Основные команды

```bash
# Статус приложения
systemctl status ai-quiz

# Запуск приложения
systemctl start ai-quiz

# Остановка приложения
systemctl stop ai-quiz

# Перезапуск приложения
systemctl restart ai-quiz

# Логи приложения
docker-compose logs -f

# Логи Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Обновление приложения

#### Полное обновление (фронтенд + бэкенд)
```bash
sudo ./scripts/deploy-with-nginx.sh your-domain.com
```

#### Только фронтенд
```bash
sudo ./scripts/update-frontend-nginx.sh your-domain.com
```

### Управление SSL сертификатами

```bash
# Проверка статуса сертификатов
certbot certificates

# Обновление сертификатов
certbot renew

# Тестовое обновление
certbot renew --dry-run

# Удаление сертификата
certbot delete --cert-name your-domain.com
```

## 🌐 Структура URL

После деплоя ваше приложение будет доступно по следующим адресам:

- **Основной сайт**: `https://your-domain.com`
- **API**: `https://your-domain.com/api/`
- **WebSocket**: `wss://your-domain.com/ws/`
- **QR код**: `https://your-domain.com/qr/`
- **Здоровье**: `https://your-domain.com/health`

## 🔒 Безопасность

### Настроенные меры безопасности:

1. **SSL/TLS**: Современные протоколы TLS 1.2 и 1.3
2. **HSTS**: HTTP Strict Transport Security
3. **Firewall**: UFW настроен для защиты сервера
4. **Автообновление SSL**: Сертификаты обновляются автоматически
5. **Проксирование**: Приложение работает только на localhost

### Дополнительные рекомендации:

```bash
# Настройка fail2ban для защиты от атак
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Регулярные обновления системы
sudo apt update && sudo apt upgrade -y

# Мониторинг логов
sudo tail -f /var/log/nginx/access.log | grep -v "health"
```

## 📊 Мониторинг

### Проверка состояния системы

```bash
# Статус всех сервисов
systemctl status nginx ai-quiz

# Использование ресурсов
docker stats

# Проверка SSL сертификата
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Проверка доступности
curl -I https://your-domain.com
```

### Логи и отладка

```bash
# Логи Nginx
sudo tail -f /var/log/nginx/error.log

# Логи приложения
docker-compose logs -f quiz

# Логи systemd
journalctl -u ai-quiz -f
journalctl -u nginx -f
```

## 🛠️ Устранение неполадок

### Проблемы с SSL

```bash
# Проверка конфигурации Nginx
sudo nginx -t

# Проверка SSL сертификата
sudo certbot certificates

# Принудительное обновление SSL
sudo certbot renew --force-renewal
```

### Проблемы с приложением

```bash
# Проверка статуса контейнеров
docker-compose ps

# Перезапуск приложения
docker-compose restart

# Просмотр логов
docker-compose logs quiz
```

### Проблемы с Nginx

```bash
# Проверка конфигурации
sudo nginx -t

# Перезапуск Nginx
sudo systemctl reload nginx

# Проверка портов
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

## 📁 Структура файлов

```
/opt/ai-quiz/
├── scripts/
│   ├── setup-nginx.sh          # Настройка Nginx
│   ├── get-ssl.sh              # Получение SSL
│   ├── deploy-with-nginx.sh    # Деплой с Nginx
│   ├── full-nginx-deploy.sh    # Полный деплой
│   └── update-frontend-nginx.sh # Обновление фронтенда
├── nginx/
│   ├── nginx.conf              # Основная конфигурация Nginx
│   └── nginx-http.conf         # HTTP конфигурация
├── frontend/                   # Исходный код фронтенда
├── backend/                    # Исходный код бэкенда
├── docker-compose.yml          # Конфигурация Docker Compose
└── Dockerfile                  # Docker образ
```

## 🔄 Автоматизация

### Cron задачи

Система автоматически создает следующие cron задачи:

```bash
# Обновление SSL сертификатов (ежедневно в 12:00)
0 12 * * * /usr/local/bin/renew-ssl.sh
```

### Systemd сервисы

```bash
# Автозапуск приложения
systemctl enable ai-quiz

# Автозапуск Nginx
systemctl enable nginx
```

## 📞 Поддержка

При возникновении проблем:

1. Проверьте логи: `docker-compose logs -f`
2. Проверьте статус сервисов: `systemctl status ai-quiz nginx`
3. Проверьте конфигурацию: `nginx -t`
4. Проверьте SSL: `certbot certificates`

Для полной переустановки используйте:
```bash
sudo ./scripts/full-nginx-deploy.sh your-domain.com your-email@example.com
``` 