from typing import List, Dict, Optional
import numpy as np
from scipy import stats
from datetime import datetime, timedelta
from uuid import uuid4
import asyncio
from sentence_transformers import SentenceTransformer

from app.schemas.evaluation import (
    EvaluationMetrics, ABTestConfig, ABTestResult, 
    HumanFeedback, ExperimentCreate
)

class EvaluationService:
    def __init__(self):
        # Initialize embedding model for semantic evaluation
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        
    async def create_ab_experiment(
        self, 
        experiment_data: ExperimentCreate
    ) -> str:
        """Create A/B test experiment"""
        experiment_id = str(uuid4())
        
        experiment = {
            "experiment_id": experiment_id,
            "name": experiment_data.name,
            "description": experiment_data.description,
            "flow_a_id": experiment_data.flow_a_id,
            "flow_b_id": experiment_data.flow_b_id,
            "config": experiment_data.config.dict(),
            "status": "running",
            "created_at": datetime.utcnow(),
            "results": [],
            "variant_assignments": {}  # user_id -> variant mapping
        }
        
        # Store in MongoDB (placeholder - implement with actual DB)
        # await self.mongodb.experiments.insert_one(experiment)
        return experiment_id
    
    async def evaluate_prompt_quality(
        self, 
        prompt: str, 
        response: str,
        expected_output: Optional[str] = None,
        execution_time_ms: float = 0,
        token_counts: Dict[str, int] = None
    ) -> EvaluationMetrics:
        """Evaluate prompt response quality using multiple metrics"""
        
        # Performance metrics
        if token_counts is None:
            token_counts = {"prompt_tokens": 0, "completion_tokens": 0}
        
        # Calculate semantic metrics
        coherence = await self._calculate_coherence(prompt, response)
        relevance = await self._calculate_relevance(prompt, response)
        
        # Factual accuracy (if ground truth provided)
        accuracy = None
        if expected_output:
            accuracy = await self._calculate_accuracy(response, expected_output)
        
        # Cost estimation (rough approximation)
        cost_usd = self._estimate_cost(token_counts)
        
        return EvaluationMetrics(
            latency_ms=execution_time_ms,
            token_usage=token_counts,
            cost_usd=cost_usd,
            coherence_score=coherence,
            relevance_score=relevance,
            factual_accuracy=accuracy
        )
    
    async def compare_variants(
        self, 
        experiment_id: str
    ) -> ABTestResult:
        """Statistical comparison of A/B test variants"""
        
        # Get experiment results (placeholder - implement with actual DB)
        # results = await self.mongodb.experiments.find_one({"experiment_id": experiment_id})
        
        # Mock data for demonstration
        variant_a_scores = [0.8, 0.75, 0.9, 0.85, 0.78] * 20  # Mock scores
        variant_b_scores = [0.85, 0.88, 0.92, 0.87, 0.84] * 20  # Mock scores
        
        # Statistical significance testing
        significance = self._calculate_statistical_significance(
            variant_a_scores, variant_b_scores
        )
        
        # Calculate aggregate metrics
        variant_a_metrics = self._create_mock_metrics(np.mean(variant_a_scores))
        variant_b_metrics = self._create_mock_metrics(np.mean(variant_b_scores))
        
        # Determine winner and improvement
        winner, improvement = self._determine_winner_and_improvement(
            variant_a_scores, variant_b_scores
        )
        
        return ABTestResult(
            experiment_id=experiment_id,
            variant_a_metrics=variant_a_metrics,
            variant_b_metrics=variant_b_metrics,
            sample_size=len(variant_a_scores) + len(variant_b_scores),
            statistical_significance=significance,
            winner=winner,
            improvement_percentage=improvement
        )
    
    async def record_human_feedback(
        self,
        experiment_id: str,
        response_id: str,
        feedback: HumanFeedback
    ):
        """Record human evaluation feedback"""
        feedback_record = {
            "experiment_id": experiment_id,
            "response_id": response_id,
            "feedback": feedback.dict(),
            "timestamp": datetime.utcnow()
        }
        
        # Store in MongoDB (placeholder)
        # await self.mongodb.human_feedback.insert_one(feedback_record)
        pass
    
    # Private helper methods
    async def _calculate_coherence(self, prompt: str, response: str) -> float:
        """Calculate semantic coherence between prompt and response"""
        try:
            prompt_embedding = self.embedding_model.encode([prompt])
            response_embedding = self.embedding_model.encode([response])
            
            # Cosine similarity
            similarity = np.dot(prompt_embedding[0], response_embedding[0]) / (
                np.linalg.norm(prompt_embedding[0]) * np.linalg.norm(response_embedding[0])
            )
            
            # Convert to 0-1 scale
            return float((similarity + 1) / 2)
        except Exception:
            return 0.5  # Default fallback
    
    async def _calculate_relevance(self, prompt: str, response: str) -> float:
        """Calculate topic relevance score"""
        # Simplified relevance calculation based on keyword overlap
        prompt_words = set(prompt.lower().split())
        response_words = set(response.lower().split())
        
        if not prompt_words:
            return 0.0
        
        overlap = len(prompt_words.intersection(response_words))
        relevance = overlap / len(prompt_words)
        
        return min(relevance, 1.0)
    
    async def _calculate_accuracy(self, response: str, expected: str) -> float:
        """Calculate factual accuracy against expected output"""
        try:
            response_embedding = self.embedding_model.encode([response])
            expected_embedding = self.embedding_model.encode([expected])
            
            similarity = np.dot(response_embedding[0], expected_embedding[0]) / (
                np.linalg.norm(response_embedding[0]) * np.linalg.norm(expected_embedding[0])
            )
            
            return float((similarity + 1) / 2)
        except Exception:
            return 0.5
    
    def _estimate_cost(self, token_counts: Dict[str, int]) -> float:
        """Estimate cost based on token usage (GPT-4 pricing)"""
        prompt_tokens = token_counts.get("prompt_tokens", 0)
        completion_tokens = token_counts.get("completion_tokens", 0)
        
        # GPT-4 pricing (approximate)
        prompt_cost = prompt_tokens * 0.00003  # $0.03 per 1K tokens
        completion_cost = completion_tokens * 0.00006  # $0.06 per 1K tokens
        
        return prompt_cost + completion_cost
    
    def _calculate_statistical_significance(
        self, 
        variant_a: List[float], 
        variant_b: List[float]
    ) -> float:
        """Calculate p-value for statistical significance"""
        try:
            # Perform t-test
            t_stat, p_value = stats.ttest_ind(variant_a, variant_b)
            return float(p_value)
        except Exception:
            return 1.0  # No significance if calculation fails
    
    def _determine_winner_and_improvement(
        self, 
        variant_a: List[float], 
        variant_b: List[float]
    ) -> tuple[Optional[str], Optional[float]]:
        """Determine winning variant and improvement percentage"""
        try:
            mean_a = np.mean(variant_a)
            mean_b = np.mean(variant_b)
            
            if abs(mean_a - mean_b) < 0.01:  # Threshold for tie
                return "tie", 0.0
            
            if mean_b > mean_a:
                improvement = ((mean_b - mean_a) / mean_a) * 100
                return "B", improvement
            else:
                improvement = ((mean_a - mean_b) / mean_b) * 100
                return "A", improvement
        except Exception:
            return None, None
    
    def _create_mock_metrics(self, score: float) -> EvaluationMetrics:
        """Create mock metrics for demonstration"""
        return EvaluationMetrics(
            latency_ms=150.0 + np.random.normal(0, 20),
            token_usage={"prompt_tokens": 50, "completion_tokens": 100},
            cost_usd=0.01,
            coherence_score=score,
            relevance_score=score + np.random.normal(0, 0.05),
            user_satisfaction=score * 5  # Convert to 1-5 scale
        )
