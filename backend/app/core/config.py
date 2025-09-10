from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    APP_NAME: str = "Prompt Flow API"
    VERSION: str = "0.1.0"
    DEBUG: bool = True
    
    # CORS
    ALLOWED_HOSTS: List[str] = ["*"]
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]
    
    # Database URLs
    DATABASE_URL: str = "postgresql://user:password@localhost/dbname"
    MONGODB_URL: str = "mongodb://admin:password123@mongodb:27017/prompt_flow?authSource=admin"
    REDIS_URL: str = "redis://redis:6379"
    QDRANT_URL: str = "http://qdrant:6333"
    
    # API Keys (optional)
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
