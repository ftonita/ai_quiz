from typing import List, Dict, Optional
from pydantic import BaseModel

class User(BaseModel):
    name: str
    score: int = 0
    answered: bool = False
    last_answer_correct: Optional[bool] = None
    last_score: int = 0

class Question(BaseModel):
    text: str
    options: List[str]
    correct_index: int
    theme: str

class Room(BaseModel):
    stage: str  # registration, preparation, quiz, results
    timer: int
    users: Dict[str, User]
    questions: List[Question]
    current_question: int = 0
    answers: Dict[str, int] = {} 