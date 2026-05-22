from fastapi import FastAPI
from pydantic import BaseModel
import requests

app = FastAPI()

OLLAMA_URL = "http://localhost:11434/api/generate"

class PromptRequest(BaseModel):
    prompt: str

@app.post("/chat")
def chat(req: PromptRequest):

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": "gemma:2b",
            "prompt": req.prompt,
            "stream": False
        }
    )

    data = response.json()

    return {
        "response": data["response"]
    }