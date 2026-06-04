import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# NVIDIA NIM Configurations
NVIDIA_API_KEY = os.getenv("NVIDIA_API_KEY")
NVIDIA_MODEL = os.getenv("NVIDIA_MODEL", "meta/llama-3.1-8b-instruct")

# Local Ollama Fallback URL
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
