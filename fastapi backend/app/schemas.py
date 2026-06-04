from pydantic import BaseModel

class PromptRequest(BaseModel):
    prompt: str

class ChatResponse(BaseModel):
    response: str
