from pydantic import BaseModel
from typing import Dict, List, Optional
from datetime import datetime

class EvaluationMetrics(BaseModel):
    # Performance Metrics
    latency_ms: float
    token_usage: Dict[str, int]  # prompt_tokens, completion_tokens
    cost_usd: Optional[float] = None
    
    # Quality Metrics  
    coherence_score: Optional[float] = None  # 0-1
    relevance_score: Optional[float] = None  # 0-1
    factual_accuracy: Optional[float] = None  # 0-1
    
    # Business Metrics
    user_satisfaction: Optional[float] = None  # 1-5 rating
    task_completion_rate: Optional[float] = None  # 0-1
    conversion_rate: Optional[float] = None  # 0-1
    
    # Custom Metrics
    custom_metrics: Dict[str, float] = {}

class ABTestConfig(BaseModel):
    name: str
    description: str
    traffic_split: float = 0.5  # 0.0-1.0
    success_metric: str = "user_satisfaction"
    minimum_sample_size: int = 100
    max_duration_days: int = 30

class ABTestResult(BaseModel):
    experiment_id: str
    variant_a_metrics: EvaluationMetrics
    variant_b_metrics: EvaluationMetrics
    sample_size: int
    statistical_significance: float
    winner: Optional[str] = None  # "A", "B", or "tie"
    improvement_percentage: Optional[float] = None

class HumanFeedback(BaseModel):
    response_id: str
    helpfulness: float  # 1-5
    accuracy: float  # 1-5
    clarity: float  # 1-5
    overall_rating: float  # 1-5
    comments: Optional[str] = None

class ExperimentCreate(BaseModel):
    name: str
    description: str
    flow_a_id: str
    flow_b_id: str
    config: ABTestConfig

class ExperimentResponse(BaseModel):
    experiment_id: str
    name: str
    description: str
    flow_a_id: str
    flow_b_id: str
    status: str  # "running", "completed", "paused"
    created_at: datetime
    results: Optional[ABTestResult] = None
    
    class Config:
        from_attributes = True
