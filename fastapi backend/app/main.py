
from fastapi import FastAPI
from app.routers import chat

app = FastAPI(title="Local AI Chat Backend", version="1.0.0")

# Register Routers
app.include_router(chat.router)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "FastAPI Backend is running."}
