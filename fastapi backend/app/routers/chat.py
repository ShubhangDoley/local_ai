from fastapi import APIRouter, HTTPException
import requests
import logging
from app.schemas import PromptRequest, ChatResponse
from app import config

router = APIRouter()
logger = logging.getLogger("uvicorn.error")

@router.post("/chat", response_model=ChatResponse)
def chat(req: PromptRequest):
    # 1. Check if NVIDIA NIM is configured via environment variable
    if config.NVIDIA_API_KEY:
        logger.info(f"Routing chat query to NVIDIA NIM (Model: {config.NVIDIA_MODEL})")
        url = "https://integrate.api.nvidia.com/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {config.NVIDIA_API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": config.NVIDIA_MODEL,
            "messages": [
                {"role": "user", "content": req.prompt}
            ],
            "temperature": 0.5,
            "max_tokens": 1024
        }
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            if response.status_code != 200:
                logger.error(f"NVIDIA NIM API returned error {response.status_code}: {response.text}")
                raise HTTPException(status_code=502, detail=f"NVIDIA NIM API Error: {response.text}")
            
            data = response.json()
            reply = data['choices'][0]['message']['content']
            return ChatResponse(response=reply)
        except Exception as e:
            logger.error(f"Failed to reach NVIDIA NIM: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Failed to reach NVIDIA NIM: {str(e)}")
            
    # 2. Fallback to Local Ollama
    logger.info(f"Routing chat query to Local Ollama (Url: {config.OLLAMA_URL})")
    try:
        response = requests.post(
            config.OLLAMA_URL,
            json={
                "model": "gemma:2b",
                "prompt": req.prompt,
                "stream": False
            },
            timeout=30
        )
        if response.status_code != 200:
            logger.error(f"Ollama returned error {response.status_code}: {response.text}")
            raise HTTPException(status_code=502, detail=f"Ollama Error: {response.text}")
        
        data = response.json()
        return ChatResponse(response=data["response"])
    except Exception as e:
        logger.error(f"Failed to reach Local Ollama: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to reach Local Ollama: {str(e)}. "
                   f"Please run Ollama locally or configure NVIDIA_API_KEY environment variable."
        )
