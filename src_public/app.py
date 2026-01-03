"""
Mock-mode FastAPI application for public demonstration.

This is a simplified mock implementation that demonstrates the API structure
without requiring real LLM or database connections. It returns deterministic
responses from sample data.

NOTE: This is NOT the production implementation. The full production code
is maintained in a private repository.
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import json
import os
from pathlib import Path

from api.models import AgentRequest, FeedbackRequest, FeedbackResponse
from api.mock_service import MockService

# Initialize FastAPI app
app = FastAPI(
    title="Multi-Agent Product Intelligence Platform API (Mock Mode)",
    description="Mock-mode demonstration of the API structure. Full implementation in private repository.",
    version="1.0.0-mock"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize mock service
_samples_dir = Path(__file__).parent.parent / "samples"
mock_service = MockService(_samples_dir)


@app.get("/")
async def root():
    """Root endpoint that returns a welcome message."""
    return {
        "message": "Multi-Agent Product Intelligence Platform API (Mock Mode)",
        "version": "1.0.0-mock",
        "note": "This is a mock implementation. Full production code is in private repository."
    }


@app.post("/rag")
async def rag(
    request: Request,
    payload: AgentRequest
) -> StreamingResponse:
    """
    Mock RAG endpoint that returns deterministic responses.
    
    In production, this endpoint:
    - Processes queries through multi-agent system
    - Streams responses via Server-Sent Events
    - Integrates with LangGraph, Qdrant, PostgreSQL, LLM providers
    
    In mock mode, returns sample responses based on query patterns.
    """
    # Generate request ID
    request_id = f"req-mock-{hash(payload.query) % 10000}"
    
    # Get mock response based on query
    response_data = mock_service.get_mock_response(payload.query, request_id)
    
    # Convert to SSE format
    def generate_sse():
        # Format as Server-Sent Event
        yield f"data: {json.dumps(response_data)}\n\n"
    
    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream"
    )


@app.post("/submit_feedback")
async def submit_feedback(
    request: Request,
    payload: FeedbackRequest
) -> FeedbackResponse:
    """
    Mock feedback endpoint that simulates feedback submission.
    
    In production, this endpoint:
    - Submits feedback to LangSmith for trace linkage
    - Stores feedback for quality analysis
    - Links feedback to agent execution traces
    
    In mock mode, returns success response.
    """
    request_id = f"req-feedback-{hash(payload.trace_id) % 10000}"
    
    # In mock mode, just return success
    # In production, this would submit to LangSmith and store feedback
    return FeedbackResponse(
        request_id=request_id,
        status="success"
    )


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy", "mode": "mock"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

