# Mock Mode Implementation

This directory contains a **mock-mode implementation** of the API that demonstrates the structure without requiring real LLM or database connections.

## What's Included

- **FastAPI route skeletons**: Endpoint definitions matching production API
- **Pydantic models**: Request/response schemas (exact match to production)
- **Mock service**: Returns deterministic responses from sample data
- **No external dependencies**: No LLM, no database, no vector search

## What's NOT Included

- Full agent implementations
- LangGraph workflow orchestration
- Real LLM calls
- Database connections
- Vector search
- Tool implementations
- Prompt templates

## Running Mock Mode

### Prerequisites

- Python 3.12+
- UV package manager (or pip)

### Setup

```bash
cd src_public
uv sync
# or
pip install fastapi uvicorn pydantic
```

### Run

```bash
uvicorn app:app --reload --port 8000
# or
python -m uvicorn app:app --reload --port 8000
```

### Test

```bash
# Test RAG endpoint
curl -X POST "http://localhost:8000/rag" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What kind of earphones can I get?",
    "thread_id": "user-123-session-456"
  }'

# Test feedback endpoint
curl -X POST "http://localhost:8000/submit_feedback" \
  -H "Content-Type: application/json" \
  -d '{
    "feedback_score": 1,
    "feedback_text": "Great!",
    "trace_id": "trace-123",
    "thread_id": "user-123-session-456",
    "feedback_source_type": "Human"
  }'
```

## API Documentation

Once running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Sample Responses

The mock service uses sample responses from `../samples/sample_responses/`. It selects responses based on simple query pattern matching:

- Queries with "cart", "add", "shopping" → `cart_operation.json`
- Queries with "warehouse", "reservation" → `multi_step_query.json`
- Other queries → `product_query.json`

## Differences from Production

**Mock Mode**:
- Returns deterministic responses from sample data
- No real agent orchestration
- No LLM calls
- No database queries
- Simple pattern matching for response selection

**Production** (private repository):
- Full multi-agent orchestration via LangGraph
- Real LLM calls via LiteLLM (OpenAI/Groq)
- Hybrid search in Qdrant
- PostgreSQL for state/cart management
- Complex routing and tool execution

## Purpose

This mock implementation serves to:
1. Demonstrate API structure and contracts
2. Enable testing without external dependencies
3. Provide examples for API consumers
4. Showcase engineering approach without exposing proprietary code

