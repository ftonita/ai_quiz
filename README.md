# AI Quiz Platform

## Структура

- backend/ — FastAPI backend
- frontend/ — React frontend
- scripts/ — DevOps-скрипты для сборки и запуска

## Быстрый старт

### 🚀 Один клик (рекомендуется)

```bash
python scripts/start.py
```

Скрипт автоматически определит окружение и запустит соответствующий режим.

### 🔧 Режим разработки

```bash
python scripts/dev.py
```

- Проверяет зависимости (Python 3.10+, Node.js 18+)
- Устанавливает зависимости backend и frontend
- Запускает backend (http://localhost:8000) и frontend (http://localhost:5173) параллельно
- Hot reload для разработки

### 🐳 Продакшн режим (Docker)

```bash
python scripts/prod.py
```

- Проверяет Docker и Docker Compose
- Собирает и запускает приложение в контейнере
- Доступно по адресу: http://localhost:8000

### 🧹 Очистка

```bash
python scripts/clean.py
```

- Останавливает Docker контейнеры
- Удаляет образы и volumes
- Очищает node_modules, __pycache__, build папки

## Доступные скрипты

| Скрипт | Описание |
|--------|----------|
| `scripts/start.py` | Универсальный запуск (автоопределение режима) |
| `scripts/dev.py` | Режим разработки |
| `scripts/prod.py` | Продакшн через Docker |
| `scripts/clean.py` | Очистка всех артефактов |

## Требования

### Для разработки
- Python 3.11+
- Node.js 18+

### Для продакшн
- Docker
- Docker Compose

## Docker команды

```bash
# Сборка и запуск
docker-compose up --build

# Только запуск
docker-compose up

# Остановка
docker-compose down

# Просмотр логов
docker-compose logs -f

# Полная очистка
docker-compose down --rmi all -v
```

## Для Windows и MacOS

- Все команды выполняются одинаково через Python-скрипты.
- Для продакшн-сборки фронта используйте:
   ```
   python scripts/build_frontend.py
   ```

## Docker

1. Собрать и запустить через docker-compose:
   ```
   docker-compose up --build
   ```
2. Приложение будет доступно на http://localhost:8000

- Фронтенд доступен по тому же адресу (отдается через backend)
- Для локальной разработки используйте скрипты из scripts/ 