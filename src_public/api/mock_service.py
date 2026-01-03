"""
Mock service that returns deterministic responses from sample data.

This service simulates the multi-agent system behavior without requiring
real LLM or database connections.
"""

import json
from pathlib import Path
from typing import Dict, Any
from api.models import AgentResponse, RAGUsedContext


class MockService:
    """Mock service that returns sample responses."""
    
    def __init__(self, samples_dir: Path):
        """
        Initialize mock service with samples directory.
        
        Args:
            samples_dir: Path to samples directory containing sample responses
        """
        self.samples_dir = samples_dir
        self._load_sample_responses()
    
    def _load_sample_responses(self):
        """Load sample responses from JSON files."""
        self.responses: Dict[str, Dict[str, Any]] = {}
        
        responses_dir = self.samples_dir / "sample_responses"
        if responses_dir.exists():
            for file in responses_dir.glob("*.json"):
                with open(file, 'r') as f:
                    data = json.load(f)
                    # Use filename as key (without extension)
                    key = file.stem
                    self.responses[key] = data
    
    def get_mock_response(self, query: str, request_id: str) -> Dict[str, Any]:
        """
        Get mock response based on query.
        
        In production, this would:
        - Route through coordinator agent
        - Delegate to specialized agents
        - Perform hybrid search in Qdrant
        - Call LLM via LiteLLM
        - Return structured response
        
        In mock mode, returns sample responses based on query patterns.
        """
        query_lower = query.lower()
        
        # Simple pattern matching to select appropriate sample response
        if "cart" in query_lower or "add" in query_lower or "shopping" in query_lower:
            # Cart operation
            if "warehouse" in query_lower or "reservation" in query_lower or "reserve" in query_lower:
                # Multi-step query with warehouse
                response_key = "multi_step_query"
            else:
                # Simple cart operation
                response_key = "cart_operation"
        else:
            # Product query
            response_key = "product_query"
        
        # Get sample response
        sample_response = self.responses.get(response_key, self.responses.get("product_query", {}))
        
        # Update request_id
        response = sample_response.copy()
        response["request_id"] = request_id
        
        return response
    
    def format_response(self, data: Dict[str, Any]) -> AgentResponse:
        """
        Format response data as AgentResponse model.
        
        This is a helper method for type validation.
        """
        used_context = [
            RAGUsedContext(**ctx) for ctx in data.get("used_context", [])
        ]
        
        return AgentResponse(
            request_id=data["request_id"],
            answer=data["answer"],
            used_context=used_context
        )

