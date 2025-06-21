# Деплой с Nginx для домена v386879.hosted-by-vdsina.com

Этот документ описывает процесс деплоя веб-приложения с использованием Nginx в качестве обратного прокси и Let's Encrypt для SSL сертификатов на домене `v386879.hosted-by-vdsina.com`.

## Предварительные требования

1. **Сервер с Ubuntu/Debian** с root доступом
2. **Домен** `v386879.hosted-by-vdsina.com` должен указывать на IP адрес сервера
3. **Docker и Docker Compose** установлены на сервере
4. **Email адрес** для получения SSL сертификатов Let's Encrypt

## Быстрый старт

### Полный автоматический деплой

Для полного деплоя с автоматической настройкой Nginx, SSL и приложения:

```bash
sudo ./scripts/full-nginx-deploy-vdsina.sh your-email@example.com
```

Этот скрипт выполнит все необходимые шаги:
1. Настройка Nginx
2. Получение SSL сертификата
3. Деплой приложения
4. Финальные проверки

## Пошаговый деплой

### Шаг 1: Настройка Nginx

```bash
sudo ./scripts/setup-nginx-vdsina.sh
```

Этот скрипт:
- Устанавливает Nginx и Certbot
- Настраивает firewall
- Создает базовую конфигурацию для домена
- Настраивает автоматическое обновление SSL сертификатов

### Шаг 2: Получение SSL сертификата

```bash
sudo ./scripts/get-ssl-vdsina.sh your-email@example.com
```

Этот скрипт:
- Проверяет доступность домена
- Получает SSL сертификат от Let's Encrypt
- Настраивает HTTPS конфигурацию Nginx
- Проверяет корректность работы SSL

### Шаг 3: Деплой приложения

```bash
sudo ./scripts/deploy-with-nginx-vdsina.sh
```

Этот скрипт:
- Собирает Docker образ приложения
- Запускает приложение в контейнере
- Копирует статические файлы фронтенда в Nginx директорию
- Настраивает systemd сервис для автозапуска

## Управление приложением

После деплоя доступны следующие команды управления:

```bash
# Основные команды
quiz-manage start           # запустить приложение
quiz-manage stop            # остановить приложение
quiz-manage restart         # перезапустить приложение
quiz-manage status          # показать статус приложения

# Логи
quiz-manage logs            # логи приложения
quiz-manage nginx-logs      # логи Nginx
quiz-manage nginx-error-logs # ошибки Nginx

# Обновления
quiz-manage ssl-renew       # обновить SSL сертификаты
quiz-manage update-frontend # обновить только фронтенд
```

## Обновление фронтенда

Для быстрого обновления только фронтенда без перезапуска бэкенда:

```bash
sudo ./scripts/update-frontend-nginx-vdsina.sh
```

## Мониторинг и логи

### Статус сервисов

```bash
# Статус приложения
systemctl status ai-quiz

# Статус контейнеров
docker-compose ps

# Статус Nginx
systemctl status nginx
```

### Логи

```bash
# Логи приложения
tail -f /opt/ai-quiz/logs/app.log

# Логи Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Логи Docker контейнеров
docker-compose logs -f
```

### Проверка конфигурации

```bash
# Проверка конфигурации Nginx
nginx -t

# Проверка SSL сертификата
certbot certificates

# Проверка автоматического обновления SSL
certbot renew --dry-run
```

## Структура файлов

```
/var/www/html/              # Статические файлы фронтенда
/etc/nginx/sites-available/ # Конфигурации Nginx
/etc/letsencrypt/live/      # SSL сертификаты
/opt/ai-quiz/              # Директория приложения
/opt/ai-quiz/logs/         # Логи приложения
```

## Безопасность

### Firewall

Скрипт автоматически настраивает UFW firewall:
- Порт 80 (HTTP) - открыт для Let's Encrypt
- Порт 443 (HTTPS) - открыт для веб-трафика
- Порт 22 (SSH) - открыт для управления

### SSL/TLS

- Используются современные протоколы TLS 1.2 и 1.3
- Настроены безопасные шифры
- Включен HSTS (HTTP Strict Transport Security)
- Автоматическое обновление сертификатов

### Nginx

- Настроены заголовки безопасности
- Кэширование статических файлов
- Правильные таймауты для API и WebSocket
- Логирование доступа и ошибок

## Устранение неполадок

### Проблемы с SSL

```bash
# Проверка SSL сертификата
openssl s_client -connect v386879.hosted-by-vdsina.com:443 -servername v386879.hosted-by-vdsina.com

# Обновление SSL сертификата вручную
certbot renew --force-renewal
systemctl reload nginx
```

### Проблемы с Nginx

```bash
# Проверка конфигурации
nginx -t

# Перезапуск Nginx
systemctl restart nginx

# Просмотр ошибок
tail -f /var/log/nginx/error.log
```

### Проблемы с приложением

```bash
# Проверка статуса контейнеров
docker-compose ps

# Просмотр логов
docker-compose logs

# Перезапуск приложения
docker-compose restart
```

### Проблемы с доменом

```bash
# Проверка DNS
nslookup v386879.hosted-by-vdsina.com

# Проверка доступности
curl -I https://v386879.hosted-by-vdsina.com
```

## Резервное копирование

### Важные файлы для резервного копирования

```bash
# SSL сертификаты
/etc/letsencrypt/live/v386879.hosted-by-vdsina.com/

# Конфигурация Nginx
/etc/nginx/sites-available/v386879.hosted-by-vdsina.com

# Логи приложения
/opt/ai-quiz/logs/

# Docker образы
docker save ai-quiz-quiz > ai-quiz-backup.tar
```

### Восстановление

```bash
# Восстановление Docker образа
docker load < ai-quiz-backup.tar

# Восстановление конфигурации Nginx
cp backup/nginx-config /etc/nginx/sites-available/v386879.hosted-by-vdsina.com
nginx -t && systemctl reload nginx
```

## Производительность

### Оптимизация Nginx

- Включено кэширование статических файлов
- Настроены правильные таймауты
- Используется HTTP/2
- Оптимизированы SSL настройки

### Мониторинг ресурсов

```bash
# Использование CPU и памяти
htop

# Использование диска
df -h

# Сетевые соединения
netstat -tlnp
```

## Контакты и поддержка

При возникновении проблем:

1. Проверьте логи: `quiz-manage logs`
2. Проверьте статус сервисов: `quiz-manage status`
3. Убедитесь, что домен правильно настроен
4. Проверьте firewall настройки

## Обновления

Для обновления всей системы:

```bash
# Обновление системы
apt update && apt upgrade -y

# Обновление приложения
sudo ./scripts/full-nginx-deploy-vdsina.sh your-email@example.com
```

---

**Важно**: Все скрипты должны выполняться с правами root (sudo) и требуют предварительной настройки DNS для домена `v386879.hosted-by-vdsina.com`. 