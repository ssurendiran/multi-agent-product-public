# System Architecture

## Overview

The Multi-Agent Product Intelligence Platform is a production-grade system that processes complex user queries through intelligent orchestration, delivering accurate, context-aware responses while managing multi-step workflows.

## Component Responsibilities

### 1. Public Entry Layer

**Caddy Reverse Proxy**
- **Responsibility**: TLS termination, rate limiting, request routing
- **Boundaries**: 
  - Receives HTTPS requests from users
  - Routes to Streamlit UI (port 8501) or FastAPI (port 8000)
  - Enforces rate limits per IP
  - Handles TLS certificates (Let's Encrypt)

**Streamlit UI**
- **Responsibility**: Interactive chat interface for users
- **Boundaries**:
  - Renders chat interface with product suggestions sidebar
  - Sends POST requests to FastAPI `/rag` endpoint
  - Displays streaming responses (Server-Sent Events)
  - Captures user feedback (thumbs up/down, comments)

### 2. Application Layer

**FastAPI Backend**
- **Responsibility**: REST API layer, request processing, response streaming
- **Boundaries**:
  - Exposes `/rag` endpoint (POST, streaming response)
  - Exposes `/submit_feedback` endpoint (POST)
  - Builds initial state for LangGraph workflow
  - Compiles LangGraph workflow with PostgreSQL checkpointer
  - Streams Server-Sent Events (SSE) back to client
  - Integrates with LangSmith for tracing

**Key Endpoints**:
- `POST /rag`: Main agent query endpoint (streaming)
- `POST /submit_feedback`: User feedback submission

### 3. Orchestration Runtime

**LangGraph Workflow**
- **Responsibility**: Multi-agent workflow orchestration and state management
- **Boundaries**:
  - Manages workflow state (conversation history, agent decisions)
  - Routes between coordinator and specialized agents
  - Handles tool execution cycles
  - Maintains conversation context across turns

**Coordinator Agent**
- **Responsibility**: Intent analysis and agent routing
- **Boundaries**:
  - Analyzes user query and conversation history
  - Creates execution plan
  - Routes to appropriate specialist agent (Product QA, Shopping Cart, Warehouse Manager)
  - Reviews results and decides next steps
  - Can terminate workflow when final answer is ready

**PostgreSQL Checkpointer**
- **Responsibility**: Persistent state management
- **Boundaries**:
  - Stores conversation state per `thread_id`
  - Enables conversation continuity across sessions
  - Maintains cart state and warehouse reservations
  - Supports checkpointing for LangGraph workflow

### 4. Specialized Agents

**Product QA Agent**
- **Responsibility**: Product queries, recommendations, review analysis
- **Boundaries**:
  - Receives product-related queries from coordinator
  - Invokes retrieval tools (hybrid search in Qdrant)
  - Formats context for LLM
  - Generates structured responses with product references
  - Returns to coordinator with answer and citations

**Shopping Cart Agent**
- **Responsibility**: Cart operations (add, remove, retrieve)
- **Boundaries**:
  - Receives cart-related queries from coordinator
  - Invokes cart tools (PostgreSQL operations)
  - Manages cart state (add items, update quantities, remove items)
  - Generates cart-focused responses
  - Returns to coordinator with cart summary

**Warehouse Manager Agent**
- **Responsibility**: Inventory checks and warehouse reservations
- **Boundaries**:
  - Receives warehouse-related queries from coordinator
  - Invokes warehouse tools (PostgreSQL inventory operations)
  - Checks item availability across warehouses
  - Creates reservations for items
  - Returns to coordinator with reservation details

### 5. Tool Layer

**Product QA Tools**
- `get_formatted_item_context`: Retrieves and formats product information
- `get_formatted_reviews_context`: Retrieves and formats review data
- **Boundaries**: Interface between Product QA Agent and Qdrant vector database

**Shopping Cart Tools**
- `add_to_shopping_cart`: Adds items to cart (PostgreSQL write)
- `remove_from_cart`: Removes items from cart (PostgreSQL write)
- `get_shopping_cart`: Retrieves current cart state (PostgreSQL read)
- **Boundaries**: Interface between Shopping Cart Agent and PostgreSQL

**Warehouse Tools**
- `check_warehouse_availability`: Checks item availability (PostgreSQL read)
- `reserve_warehouse_items`: Creates warehouse reservations (PostgreSQL write)
- **Boundaries**: Interface between Warehouse Manager Agent and PostgreSQL

### 6. Retrieval Stack

**Embedding Generation**
- **Responsibility**: Convert queries to semantic vectors
- **Boundaries**:
  - Uses OpenAI `text-embedding-3-small` (1536 dimensions)
  - Generates embeddings for user queries
  - Same model used for indexing (ensures compatibility)

**Qdrant Hybrid Search**
- **Responsibility**: Semantic + keyword search with fusion
- **Boundaries**:
  - **Dense Vectors**: Semantic similarity (COSINE)
  - **Sparse Vectors**: BM25 keyword matching
  - **Fusion**: Reciprocal Rank Fusion (RRF) combines results
  - Returns top-k products based on hybrid similarity

**Collections**:
- `Amazon-items-collection-01-hybrid-search`: 500 products with hybrid search
- `Amazon-items-collection-01-reviews`: 45,948 reviews with semantic search

### 7. Data Stores

**Qdrant Vector Database**
- **Responsibility**: Vector storage and hybrid search
- **Boundaries**:
  - Stores product embeddings (dense vectors)
  - Stores review embeddings (dense vectors)
  - Indexes BM25 sparse vectors for keyword search
  - Supports filtering by `parent_asin` (product ID)

**PostgreSQL**
- **Responsibility**: Relational data storage
- **Boundaries**:
  - **Checkpointing**: LangGraph state persistence
  - **Shopping Cart**: Cart items, quantities, user sessions
  - **Warehouse Inventory**: Item availability, reservations
  - **Schemas**: `shopping_carts`, `warehouse_management`

### 8. LLM & Guardrails

**LiteLLM Router**
- **Responsibility**: Unified LLM API with automatic fallbacks
- **Boundaries**:
  - **Primary**: OpenAI GPT-4.1 (all agents)
  - **Fallback**: Groq Llama 3.3 70B (when OpenAI rate limits)
  - Handles API errors and automatic retries
  - Routes to appropriate model based on availability

**Instructor + Pydantic**
- **Responsibility**: Structured output validation
- **Boundaries**:
  - Ensures LLM responses match expected schemas
  - Validates agent outputs (next_agent, tool_calls, final_answer)
  - Type-safe response parsing
  - Prevents malformed responses from reaching downstream

### 9. Observability

**LangSmith Integration**
- **Responsibility**: End-to-end tracing and monitoring
- **Boundaries**:
  - Traces all agent executions
  - Traces all tool calls
  - Traces all LLM API calls
  - Traces embedding generation
  - Traces vector database queries
  - Captures user feedback
  - Tracks performance metrics (latency, tokens, costs)

## Component Boundaries

### Data Flow Boundaries

1. **User → Application**: HTTPS requests through Caddy
2. **Application → Orchestration**: FastAPI builds state, compiles LangGraph
3. **Orchestration → Agents**: Coordinator routes to specialized agents
4. **Agents → Tools**: Agents invoke tools when needed
5. **Tools → Data Stores**: Tools read/write to Qdrant or PostgreSQL
6. **Agents → LLM**: Agents call LLM via LiteLLM router
7. **All Components → Observability**: All components trace to LangSmith

### State Management Boundaries

- **Conversation State**: Stored in PostgreSQL checkpointer (per `thread_id`)
- **Cart State**: Stored in PostgreSQL `shopping_carts` schema
- **Warehouse State**: Stored in PostgreSQL `warehouse_management` schema
- **Vector Data**: Stored in Qdrant collections (immutable, indexed)

### Security Boundaries

- **TLS Termination**: Caddy handles HTTPS
- **Rate Limiting**: Caddy enforces per-IP limits
- **API Keys**: Stored in environment variables (GCP Secret Manager in production)
- **Database Access**: Credentials in environment variables, not in code

## Scalability Considerations

**Current Scale**:
- 500 products indexed in Qdrant
- 45,948 reviews indexed in Qdrant
- Single VM deployment
- 0% error rate, <2s P50 latency

**Architecture Supports**:
- Full Amazon dataset (571M reviews, 48M items)
- Horizontal scaling (multiple FastAPI instances)
- Qdrant clustering for larger vector datasets
- PostgreSQL read replicas for cart/warehouse queries

**Scaling Path**:
- 2-10x: Qdrant clustering, Cloud SQL migration
- 10x-100x: Multi-region deployment, microservices architecture

## Technology Choices

**Why LangGraph?**
- Native support for multi-agent workflows
- Built-in state management and checkpointing
- Tool execution cycles
- Production-ready patterns

**Why LiteLLM?**
- Unified API across LLM providers
- Automatic fallback handling
- Cost optimization through routing
- Simplified error handling

**Why Qdrant?**
- Native hybrid search support (dense + sparse vectors)
- High-performance vector operations
- Filtering capabilities (parent_asin)
- Production-ready clustering

**Why PostgreSQL?**
- Reliable state persistence
- ACID guarantees for cart/warehouse operations
- LangGraph checkpointing support
- Proven scalability path

