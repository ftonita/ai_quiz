import asyncio
from .state import room, set_stage
from .models import Question
import random

# Глобальный task для управления стадиями
TIMER_TASK = None

STAGES = [
    ("registration", 60),
    ("preparation", 15),
    ("quiz", 15),  # для каждого вопроса
    ("pause", 3),  # пауза между вопросами
    ("results", 0)
]

QUESTIONS_POOL = [
    {"text": "Что такое Вайбкодинг?", "options": ["Метод обучения", "Язык программирования", "Стиль код-ревью", "Техника командной работы"], "correct": 0, "theme": "Вайбкодинг"},
    {"text": "Что такое AI?", "options": ["Искусственный интеллект", "Автоматизация интерфейса", "Анализ изображений", "Архитектурный индекс"], "correct": 0, "theme": "AI"},
    {"text": "Что делает ИИ-агент?", "options": ["Выполняет задачи самостоятельно", "Только обучается", "Только хранит данные", "Только рисует"], "correct": 0, "theme": "ИИ-агенты"},
    {"text": "Какой язык программирования используется в Вайбкодинге?", "options": ["Python", "JavaScript", "Java", "C++"], "correct": 0, "theme": "Вайбкодинг"},
    {"text": "Что такое машинное обучение?", "options": ["Подмножество AI", "База данных", "Операционная система", "Сеть"], "correct": 0, "theme": "AI"},
    {"text": "Как ИИ-агент принимает решения?", "options": ["На основе алгоритмов", "Случайно", "По расписанию", "Только по команде"], "correct": 0, "theme": "ИИ-агенты"},
    {"text": "В чем преимущество Вайбкодинга?", "options": ["Быстрая разработка", "Низкая стоимость", "Простота обучения", "Все вышеперечисленное"], "correct": 3, "theme": "Вайбкодинг"},
    {"text": "Что такое нейронная сеть?", "options": ["Модель AI", "Интернет-сеть", "База данных", "Программа"], "correct": 0, "theme": "AI"},
    {"text": "Может ли ИИ-агент обучаться?", "options": ["Да, на основе данных", "Нет, никогда", "Только при перезапуске", "Только в лаборатории"], "correct": 0, "theme": "ИИ-агенты"},
    {"text": "Какой принцип лежит в основе Вайбкодинга?", "options": ["Простота и скорость", "Сложность и точность", "Дороговизна", "Медленная разработка"], "correct": 0, "theme": "Вайбкодинг"},
]

def start_registration():
    global TIMER_TASK
    if TIMER_TASK and not TIMER_TASK.done():
        TIMER_TASK.cancel()
    TIMER_TASK = asyncio.create_task(registration_loop())

def start_new_cycle():
    """Запуск нового цикла викторины с 2-минутной регистрацией"""
    global TIMER_TASK
    if TIMER_TASK and not TIMER_TASK.done():
        TIMER_TASK.cancel()
    TIMER_TASK = asyncio.create_task(new_cycle_loop())

async def new_cycle_loop():
    """Новый цикл с 2-минутной регистрацией"""
    # Инициализация стадии регистрации (2 минуты = 120 секунд)
    set_stage("registration", 120)
    
    # Таймер без блокировок
    for i in range(120, 0, -1):
        await asyncio.sleep(1)
        room.timer = i - 1
    
    # Переход к подготовке
    await start_preparation()

async def registration_loop():
    # Инициализация стадии регистрации
    set_stage("registration", 60)
    
    # Таймер без блокировок
    for i in range(60, 0, -1):
        await asyncio.sleep(1)
        room.timer = i - 1
    
    # Переход к подготовке
    await start_preparation()

async def start_preparation():
    # Инициализация стадии подготовки
    set_stage("preparation", 15)
    
    # Генерация вопросов
    qs = random.sample(QUESTIONS_POOL, min(5, len(QUESTIONS_POOL)))
    room.questions = []
    for q in qs:
        room.questions.append(Question(
            text=q["text"],
            options=q["options"],
            correct_index=q["correct"],
            theme=q["theme"]
        ))
    
    # Таймер без блокировок
    for i in range(15, 0, -1):
        await asyncio.sleep(1)
        room.timer = i - 1
    
    # Переход к викторине
    await start_quiz(0)

async def start_quiz(q_idx):
    # Инициализация вопроса
    set_stage("quiz", 15)
    room.current_question = q_idx
    # Сбрасываем ответы для нового вопроса
    room.answers = {}
    
    # Таймер без блокировок
    for i in range(15, 0, -1):
        await asyncio.sleep(1)
        room.timer = i - 1
    
    # Начисление баллов (используем время, когда пользователь ответил)
    for uname, user in room.users.items():
        if uname in room.answers:
            answer_data = room.answers[uname]
            user_answer = answer_data['answer']
            answer_time = answer_data['time']
            
            if user_answer == room.questions[q_idx].correct_index:
                # Начисляем баллы за правильный ответ
                # Баллы = время ответа (чем быстрее, тем больше)
                user.last_answer_correct = True
                user.last_score = answer_time
                user.score += answer_time
            else:
                user.last_answer_correct = False
                user.last_score = 0
        else:
            user.last_answer_correct = False
            user.last_score = 0
    
    # Переход к паузе
    await start_pause(q_idx)

async def start_pause(q_idx):
    # Инициализация паузы
    set_stage("pause", 3)
    
    # Таймер без блокировок
    for i in range(3, 0, -1):
        await asyncio.sleep(1)
        room.timer = i - 1
    
    # Определение следующего этапа
    if q_idx + 1 < len(room.questions):
        await start_quiz(q_idx + 1)
    else:
        await start_results()

async def start_results():
    set_stage("results", 0)
    
    # Ждем 10 секунд на странице результатов, затем сбрасываем данные и запускаем новый цикл
    await asyncio.sleep(10)
    await start_new_cycle_auto()

async def start_new_cycle_auto():
    """Автоматический запуск нового цикла"""
    # Сбрасываем данные пользователей
    room.users = {}
    room.answers = {}
    room.questions = []
    room.current_question = 0
    
    # Устанавливаем стадию ожидания
    set_stage("waiting", 15)
    
    # Ждем 15 секунд перед началом новой регистрации
    for i in range(15, 0, -1):
        await asyncio.sleep(1)
        room.timer = i - 1
    
    await new_cycle_loop() 