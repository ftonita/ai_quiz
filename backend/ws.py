from fastapi import WebSocket, WebSocketDisconnect, APIRouter
from .state import room, get_users
import asyncio
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

ws_router = APIRouter()
connections = set()

@ws_router.get("/ws/status")
async def ws_status():
    """Проверка статуса WebSocket подключений"""
    return {
        "active_connections": len(connections),
        "connections": [str(conn.client.host) for conn in connections]
    }

@ws_router.websocket("/ws/room")
async def ws_room(websocket: WebSocket):
    logger.info(f"🔌 WebSocket connection attempt from {websocket.client.host}")
    await websocket.accept()
    connections.add(websocket)
    logger.info(f"✅ WebSocket connected. Total connections: {len(connections)}")
    
    try:
        while True:
            await asyncio.sleep(1)
            data = {
                "stage": room.stage,
                "timer": room.timer,
                "users": [u.name for u in get_users()],
                "current_question": getattr(room, 'current_question', 0),
                "question_count": len(getattr(room, 'questions', [])),
            }
            await websocket.send_json(data)
            logger.debug(f"📨 Sent WebSocket data: {data}")
    except WebSocketDisconnect:
        connections.remove(websocket)
        logger.info(f"🔌 WebSocket disconnected. Total connections: {len(connections)}")
    except Exception as e:
        logger.error(f"❌ WebSocket error: {e}")
        connections.discard(websocket) 