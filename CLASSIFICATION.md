# File Classification: Safe/Public vs Private

This document classifies all files in the repository as either **SAFE FOR PUBLIC RELEASE** or **PRIVATE (MUST NOT PUBLISH)**.

## ✅ SAFE FOR PUBLIC RELEASE

### Documentation & Architecture
- `README.md` (rewritten for public consumption)
- `documentation/High_level.drawio.png` (architecture diagram)
- `documentation/screenshots/*.png` (screenshots of UI and dashboards)
- `LICENSE` (Apache 2.0)
- `pyproject.toml` (dependency list only, no secrets)

### Contracts & Schemas
- API endpoint signatures (`POST /rag`, `POST /submit_feedback`)
- Pydantic models (request/response schemas)
- OpenAPI specification (endpoints, models, no internals)
- SQL schemas (sanitized, no data)

### Sample Data
- Sample request/response JSON files (sanitized, realistic examples)
- Mock data for demonstrations

### Mock Implementation
- FastAPI route skeletons (endpoint definitions only)
- Pydantic models (schemas)
- Mock service implementations (deterministic responses, no real LLM/DB calls)

## ❌ PRIVATE (MUST NOT PUBLISH)

### Source Code - Implementation Details
- `src/api/agent/agents.py` - Full agent implementations with routing logic
- `src/api/agent/graph.py` - LangGraph workflow orchestration details
- `src/api/agent/tools.py` - Tool implementations (retrieval, cart, warehouse)
- `src/api/agent/retrieval_generation.py` - RAG pipeline implementation
- `src/api/agent/prompts/*.yaml` - **PROPRIETARY PROMPTS** (routing logic, agent instructions)
- `src/api/agent/utils/*.py` - Prompt management and utilities
- `src/api/api/processors/*.py` - Request processing logic
- `src/api/core/config.py` - Configuration with API keys structure
- `src/chatbot_ui/app.py` - Streamlit UI implementation
- `src/items_mcp_server/*.py` - MCP server implementations
- `src/reviews_mcp_server/*.py` - MCP server implementations

### Infrastructure & Configuration
- `docker-compose.yaml` - Service configuration with internal URLs
- `Dockerfile.*` - Container definitions
- `Caddyfile` - Reverse proxy configuration with domains/IPs
- `.env` / `env.example` - Environment variable templates (may contain structure)
- `Makefile` - Build commands

### Data & Secrets
- `data/*.jsonl` - **PROPRIETARY DATASETS** (Amazon product data)
- `qdrant_storage*/` - Vector database storage (contains indexed data)
- `postgres_data*/` - Database storage (contains user data, cart state)
- All API keys, secrets, credentials
- Internal URLs, IP addresses, service accounts

### Evaluation & Testing
- `evals/eval_retriever.py` - Retrieval evaluation logic
- `evals/eval_coordinator_agent.py` - Coordinator evaluation logic
- `notebooks/**/*.ipynb` - **PROPRIETARY NOTEBOOKS** (full implementation, prompts, data processing)
- `.github/workflows/ci.yaml` - CI/CD pipeline with secrets

### Proprietary Logic
- Agent routing heuristics
- Retrieval ranking algorithms
- Prompt templates and instructions
- Tool implementation details
- State management logic
- Error handling strategies
- Performance optimizations

## 📋 Summary

**PUBLISH:**
- Architecture diagrams and documentation
- API contracts (OpenAPI)
- Pydantic schemas (models only)
- Sample requests/responses
- Mock-mode code (skeletons + deterministic responses)
- High-level flow descriptions
- Observability setup (what is traced, not how)
- Security posture (high-level only)

**DO NOT PUBLISH:**
- Full source code implementations
- Prompt templates
- Agent routing logic
- Tool internals
- Real datasets
- Database contents
- API keys or secrets
- Internal infrastructure details
- Evaluation scripts
- Notebooks with implementation

