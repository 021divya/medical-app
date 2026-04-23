from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import List
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.chat import Message, ChatSession

router = APIRouter()

# --- Connection Manager ---
class ConnectionManager:
    def __init__(self):
        # Dictionary to store active connections: {user_id: WebSocket}
        self.active_connections: dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        self.active_connections[user_id] = websocket

    def disconnect(self, user_id: int):
        if user_id in self.active_connections:
            del self.active_connections[user_id]

    async def send_personal_message(self, message: str, user_id: int):
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_text(message)

manager = ConnectionManager()

# --- WebSocket Endpoint ---
@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int, db: Session = Depends(get_db)):
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_text()
            
            # 1. Save User Message to DB
            # (In a real app, find the active session_id for this user first)
            # For simplicity, we assume a session exists or create a dummy one
            
            # 2. Logic: "The Switch"
            # Here is where you will add AI later.
            # IF AI_MODE:
            #    response = call_ai_model(data)
            # ELSE:
            #    notify_doctor(data)
            
            # For now, echo the message back to prove it works
            await manager.send_personal_message(f"You wrote: {data}", user_id)
            
    except WebSocketDisconnect:
        manager.disconnect(user_id)