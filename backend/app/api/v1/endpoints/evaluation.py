from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.services.evaluation_service import EvaluationService
from app.schemas.evaluation import (
    ExperimentCreate, ExperimentResponse, ABTestResult,
    HumanFeedback, EvaluationMetrics
)

router = APIRouter()
evaluation_service = EvaluationService()

@router.get("/")
async def evaluation_status():
    return {"status": "ready", "message": "Evaluation endpoint"}

@router.post("/experiments/", response_model=str)
async def create_experiment(experiment_data: ExperimentCreate):
    """Create a new A/B test experiment"""
    experiment_id = await evaluation_service.create_ab_experiment(experiment_data)
    return experiment_id

@router.get("/experiments/{experiment_id}/results", response_model=ABTestResult)
async def get_experiment_results(experiment_id: str):
    """Get A/B test results with statistical analysis"""
    try:
        results = await evaluation_service.compare_variants(experiment_id)
        return results
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Experiment not found: {str(e)}")

@router.post("/experiments/{experiment_id}/feedback")
async def submit_human_feedback(
    experiment_id: str,
    feedback: HumanFeedback
):
    """Submit human evaluation feedback"""
    await evaluation_service.record_human_feedback(
        experiment_id=experiment_id,
        response_id=feedback.response_id,
        feedback=feedback
    )
    return {"message": "Feedback recorded successfully"}

@router.post("/evaluate", response_model=EvaluationMetrics)
async def evaluate_prompt_response(
    prompt: str,
    response: str,
    expected_output: str = None,
    execution_time_ms: float = 0
):
    """Evaluate the quality of a prompt-response pair"""
    metrics = await evaluation_service.evaluate_prompt_quality(
        prompt=prompt,
        response=response,
        expected_output=expected_output,
        execution_time_ms=execution_time_ms
    )
    return metrics

@router.get("/experiments/{experiment_id}/dashboard")
async def get_experiment_dashboard(experiment_id: str):
    """Get dashboard data for experiment monitoring"""
    results = await evaluation_service.compare_variants(experiment_id)
    
    return {
        "experiment_id": experiment_id,
        "status": "running",  # This would come from DB
        "metrics_comparison": [
            {
                "metric_name": "Coherence Score",
                "variant_a": results.variant_a_metrics.coherence_score,
                "variant_b": results.variant_b_metrics.coherence_score,
                "improvement": results.improvement_percentage,
                "significance": results.statistical_significance
            },
            {
                "metric_name": "User Satisfaction",
                "variant_a": results.variant_a_metrics.user_satisfaction,
                "variant_b": results.variant_b_metrics.user_satisfaction,
                "improvement": results.improvement_percentage,
                "significance": results.statistical_significance
            },
            {
                "metric_name": "Latency (ms)",
                "variant_a": results.variant_a_metrics.latency_ms,
                "variant_b": results.variant_b_metrics.latency_ms,
                "improvement": results.improvement_percentage,
                "significance": results.statistical_significance
            }
        ]
    }
