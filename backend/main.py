from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from .api import router
from .ws import ws_router
from .timer import start_registration, start_new_cycle
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Сначала монтируем статические файлы
FRONTEND_DIST = os.path.join(os.path.dirname(__file__), '../frontend_dist')
if os.path.exists(FRONTEND_DIST):
    app.mount("/assets", StaticFiles(directory=os.path.join(FRONTEND_DIST, "assets")), name="assets")

# Затем API роутеры
app.include_router(router, prefix="/api")
app.include_router(ws_router)

@app.get("/")
async def root():
    """Главная страница"""
    if os.path.exists(FRONTEND_DIST):
        return FileResponse(os.path.join(FRONTEND_DIST, "index.html"))
    return {"status": "ok"}

@app.get("/{full_path:path}")
async def catch_all(full_path: str, request: Request):
    """Fallback для SPA - все остальные пути возвращают index.html"""
    if full_path.startswith("api/") or full_path.startswith("ws/"):
        # API и WebSocket пути обрабатываются отдельно
        return {"error": "Not found"}
    
    if os.path.exists(FRONTEND_DIST):
        return FileResponse(os.path.join(FRONTEND_DIST, "index.html"))
    return {"error": "Frontend not found"}

@app.on_event("startup")
async def startup_event():
    """Автоматический запуск викторины при старте приложения"""
    print("🎯 Запуск AI Quiz Platform...")
    start_registration()
    print("✅ Викторина запущена в режиме регистрации") 