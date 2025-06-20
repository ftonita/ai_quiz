from fastapi import WebSocket, WebSocketDisconnect, APIRouter
from .state import room, get_users
import asyncio

ws_router = APIRouter()
connections = set()

@ws_router.websocket("/ws/room")
async def ws_room(websocket: WebSocket):
    await websocket.accept()
    connections.add(websocket)
    try:
        while True:
            await asyncio.sleep(1)
            await websocket.send_json({
                "stage": room.stage,
                "timer": room.timer,
                "users": [u.name for u in get_users()],
                "current_question": getattr(room, 'current_question', 0),
                "question_count": len(getattr(room, 'questions', [])),
            })
    except WebSocketDisconnect:
        connections.remove(websocket)
    except Exception as e:
        print(f"WebSocket error: {e}")
        connections.discard(websocket) 