from fastapi import APIRouter, HTTPException, Depends
from .state import room, add_user, get_users
from .timer import start_registration, start_new_cycle
from .auth import create_access_token, get_current_user
from pydantic import BaseModel
import qrcode
from fastapi.responses import StreamingResponse
from io import BytesIO

router = APIRouter()

class RegisterRequest(BaseModel):
    name: str

class AnswerRequest(BaseModel):
    answer: int

@router.get("/room")
async def get_room():
    return {
        "stage": room.stage,
        "timer": room.timer,
        "users": [u.name for u in get_users()],
        "current_question": getattr(room, 'current_question', 0),
        "question_count": len(getattr(room, 'questions', []))
    }

@router.post("/room/register")
async def register_user(req: RegisterRequest):
    if room.stage != 'registration' or room.timer <= 0:
        raise HTTPException(status_code=403, detail="Регистрация закрыта")
    if not validate_name(req.name):
        raise HTTPException(status_code=400, detail="Невалидное имя")
    if not add_user(req.name.strip()):
        raise HTTPException(status_code=409, detail="Имя занято или лимит")
    
    # Создаем JWT токен для пользователя
    access_token = create_access_token(data={"sub": req.name.strip()})
    return {"ok": True, "token": access_token, "user": req.name.strip()}

def validate_name(name: str) -> bool:
    import re
    name = name.strip()
    if not name:
        return False
    # Поддерживаем латиницу, кириллицу, цифры, пробелы и точки
    return bool(re.match(r'^[a-zA-Zа-яА-Я0-9 .]+$', name))

@router.post("/room/start")
async def start_room():
    start_registration()
    return {"ok": True}

@router.post("/room/restart")
async def restart_room():
    """Запуск нового цикла викторины"""
    start_new_cycle()
    return {"ok": True}

@router.get("/room/question")
async def get_question():
    if room.stage != 'quiz':
        return {"question": None}
    
    try:
        q = room.questions[room.current_question]
        return {
            "question": {
                "text": q.text,
                "options": q.options,
                "theme": q.theme,
                "timer": room.timer
            }
        }
    except (IndexError, AttributeError):
        return {"question": None}

@router.post("/room/answer")
async def answer_question(req: AnswerRequest, current_user: str = Depends(get_current_user)):
    if room.stage != 'quiz' or room.timer <= 0:
        raise HTTPException(status_code=403, detail="Вопрос не активен")
    if current_user not in room.users:
        raise HTTPException(status_code=403, detail="Пользователь не зарегистрирован")
    if current_user in room.answers:
        raise HTTPException(status_code=409, detail="Уже отвечал")
    
    # Сохраняем ответ и время ответа
    room.answers[current_user] = {
        'answer': req.answer,
        'time': room.timer  # время, когда пользователь ответил
    }
    return {"ok": True}

@router.get("/room/leaderboard")
async def leaderboard():
    users = sorted(get_users(), key=lambda u: u.score, reverse=True)
    return [{"name": u.name, "score": u.score} for u in users]

@router.get("/room/qr")
async def get_qr():
    url = "https://v386879.hosted-by-vdsina.com/"  # Главная страница приложения
    img = qrcode.make(url)
    buf = BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return StreamingResponse(buf, media_type="image/png")

@router.get("/room/me")
async def get_current_user_info(current_user: str = Depends(get_current_user)):
    """Получение информации о текущем пользователе"""
    if current_user not in room.users:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    user = room.users[current_user]
    return {
        "name": user.name,
        "score": user.score,
        "last_answer_correct": getattr(user, 'last_answer_correct', None),
        "last_score": getattr(user, 'last_score', 0)
    } 