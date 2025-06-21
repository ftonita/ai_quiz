# 🔐 Быстрый старт: Безопасность

## Что сделано

✅ **Создана система безопасности** для хранения секретных данных
✅ **Все пароли и IP вынесены** из скриптов в переменные окружения  
✅ **Файлы с секретами исключены** из Git через `.gitignore`
✅ **Обновлены все скрипты** для использования переменных окружения

## Файлы безопасности

- `scripts/export-secrets.sh` - **ВАШИ СЕКРЕТЫ** (не коммитьте в Git!)
- `scripts/export-secrets.sh.example` - пример для новых пользователей
- `.gitignore` - исключает секретные файлы
- `SECURITY.md` - подробная документация

## Как использовать

### 1. Загрузить секреты в текущую сессию
```bash
source scripts/export-secrets.sh
```

### 2. Запустить любой скрипт (автоматически загружает секреты)
```bash
./scripts/test-connection.sh
./scripts/quick-redeploy.sh
./scripts/upload-and-deploy-vdsina-auto.sh
```

### 3. Проверить переменные
```bash
echo "Server: $SERVER_IP"
echo "Domain: $SERVER_DOMAIN"
echo "Email: $NGINX_EMAIL"
```

## Для новых пользователей

1. Скопируйте пример:
```bash
cp scripts/export-secrets.sh.example scripts/export-secrets.sh
```

2. Отредактируйте файл своими данными:
```bash
nano scripts/export-secrets.sh
```

3. Заполните ваши данные:
```bash
export SERVER_IP="YOUR_IP"
export SERVER_PASSWORD="YOUR_PASSWORD"
export SERVER_DOMAIN="YOUR_DOMAIN"
export NGINX_EMAIL="YOUR_EMAIL"
```

## Безопасность

- ✅ Пароли не в коде
- ✅ IP адреса в переменных  
- ✅ Файлы с секретами в `.gitignore`
- ⚠️ **НЕ КОММИТЬТЕ** `scripts/export-secrets.sh` в Git!

## Подробная документация

См. `SECURITY.md` для полной документации по безопасности. 