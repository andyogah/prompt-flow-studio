from fastapi import APIRouter
from app.api.v1.endpoints import flows, health, evaluation

api_router = APIRouter()

@api_router.get("/health")
async def health_check():
    return {"status": "healthy", "message": "API is running"}

@api_router.get("/")
async def root():
    return {"message": "Prompt Flow API v1", "version": "0.1.0"}

api_router.include_router(flows.router, prefix="/flows", tags=["flows"])
api_router.include_router(evaluation.router, prefix="/evaluation", tags=["evaluation"])
api_router.include_router(health.router, prefix="/health", tags=["health"])
