from .models import Room, User, Question
import random

room = Room(
    stage='registration',
    timer=60,
    users={},
    questions=[],
    current_question=0,
    answers={}
)

def set_stage(stage: str, timer: int):
    room.stage = stage
    room.timer = timer

def add_user(name: str):
    if name not in room.users and len(room.users) < 100:
        room.users[name] = User(name=name)
        return True
    return False

def get_users():
    return list(room.users.values()) 