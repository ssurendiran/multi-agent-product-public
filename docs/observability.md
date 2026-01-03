# Observability

This document describes what is traced and monitored in the system (high-level only). Implementation details are maintained in the private repository.

## Overview

The platform uses **LangSmith** for end-to-end observability, providing comprehensive tracing, monitoring, and evaluation capabilities.

## What is Traced

### 1. Agent Executions

**Coordinator Agent**:
- Intent analysis calls
- Routing decisions (`next_agent` selections)
- Plan creation and revision
- Final answer generation

**Product QA Agent**:
- Product query processing
- Tool invocation decisions
- Answer generation with references
- Context formatting

**Shopping Cart Agent**:
- Cart operation processing
- Tool invocation decisions
- Cart state updates
- Response generation

**Warehouse Manager Agent**:
- Inventory check operations
- Reservation creation
- Availability queries
- Response generation

**Trace Data Captured**:
- Input queries and conversation history
- LLM prompts and responses
- Structured outputs (Pydantic validated)
- Execution time (latency)
- Token usage (input/output tokens)
- Model used (OpenAI GPT-4.1 or Groq Llama 3.3 70B)

### 2. Tool Calls

**Retrieval Tools**:
- `get_formatted_item_context`: Product retrieval
- `get_formatted_reviews_context`: Review retrieval
- Embedding generation calls
- Qdrant query execution
- Results formatting

**Cart Tools**:
- `add_to_shopping_cart`: Cart write operations
- `remove_from_cart`: Cart deletion operations
- `get_shopping_cart`: Cart read operations
- PostgreSQL query execution

**Warehouse Tools**:
- `check_warehouse_availability`: Inventory queries
- `reserve_warehouse_items`: Reservation creation
- PostgreSQL query execution

**Trace Data Captured**:
- Tool name and arguments
- Execution time
- Results returned
- Database query performance
- Vector search performance

### 3. LLM API Calls

**All LLM Interactions**:
- API provider (OpenAI, Groq)
- Model used (GPT-4.1, GPT-4.1-mini, Llama 3.3 70B)
- Input prompts
- Output responses
- Token counts (input/output)
- Latency (API response time)
- Cost per call
- Error status (success/failure)

**Fallback Tracking**:
- Primary provider attempts
- Fallback triggers (rate limits, errors)
- Fallback provider usage
- Cost comparison (primary vs fallback)

### 4. Embedding Generation

**Embedding Calls**:
- Query embedding generation
- Model used (`text-embedding-3-small`)
- Vector dimensions (1536)
- Latency
- Token usage

### 5. Vector Database Queries

**Qdrant Operations**:
- Hybrid search queries
- Dense vector search (semantic)
- Sparse vector search (BM25)
- Fusion query (RRF)
- Results count (top-k)
- Query latency
- Collection names queried

### 6. User Feedback

**Feedback Integration**:
- Feedback score (positive/negative)
- Feedback text (user comments)
- Trace ID linkage
- Thread ID linkage
- Feedback source (Human/API)
- Timestamp

**Feedback Analysis**:
- Feedback linked to specific traces
- Agent performance correlation
- Response quality metrics
- User satisfaction trends

## Metrics Tracked

### Performance Metrics

**Latency**:
- P50 (median) latency: ~1.2-1.3s
- P99 (99th percentile) latency: ~1.5-1.6s
- Per-agent latency breakdown
- Per-tool latency breakdown
- LLM API latency

**Throughput**:
- Requests per second
- Traces per day
- Agent invocations per trace

### Cost Metrics

**LLM Costs**:
- Cost per trace (P50: ~$0.01-0.05)
- Cost per agent call
- Token usage (input/output)
- Model cost breakdown (OpenAI vs Groq)
- Total daily/weekly costs

**Optimization Tracking**:
- Fallback usage (cost savings)
- Token reduction opportunities
- Model routing efficiency

### Quality Metrics

**Routing Accuracy**:
- Coordinator routing correctness (60%+ threshold)
- Agent selection accuracy
- Plan quality

**Retrieval Quality**:
- Top-k retrieval relevance
- Hybrid search effectiveness
- Context precision/recall

**Response Quality**:
- User feedback scores
- Answer relevance
- Reference accuracy

### Reliability Metrics

**Error Rates**:
- Overall error rate (target: 0%)
- Per-agent error rates
- Per-tool error rates
- LLM API error rates
- Database error rates

**Availability**:
- Uptime percentage
- Service health status
- Fallback activation frequency

## Dashboards

### Tracing Dashboard

**7-Day Overview**:
- Trace count (successful vs errors)
- Latency trends (P50, P99)
- Error rate trends
- Cost trends

**Individual Traces**:
- Waterfall visualization
- Agent execution timeline
- Tool call timeline
- LLM call timeline
- Full trace details

### LLM Calls Dashboard

**Usage Analytics**:
- LLM calls per day
- Latency per model
- Cost per model
- Token usage
- Error rates

**Cost Analysis**:
- Total cost trends
- Cost per trace
- Model cost comparison
- Optimization opportunities

### Evaluation Dashboard

**Quality Metrics**:
- Routing accuracy (coordinator)
- Retrieval quality (RAGAS metrics)
- Response quality (user feedback)
- Experiment comparisons

**A/B Testing**:
- Prompt version comparisons
- Model configuration comparisons
- Performance regression detection

## Integration Points

### LangSmith Integration

**Automatic Tracing**:
- All LangChain/LangGraph components auto-instrumented
- LiteLLM calls automatically traced
- Tool executions automatically traced
- Embedding calls automatically traced

**Manual Instrumentation**:
- Custom trace metadata
- User feedback submission
- Custom metrics

### CI/CD Integration

**Quality Gates**:
- Automated evaluation on PRs
- Routing accuracy threshold (60%)
- Performance regression detection
- Cost threshold checks

**Experiment Tracking**:
- Git commit hash linkage
- Version comparison
- Historical performance tracking

## High-Level Architecture

```
User Request
    │
    ▼
FastAPI (starts trace)
    │
    ▼
LangGraph Workflow
    │
    ├──► Coordinator Agent (traced)
    │       │
    │       ├──► LLM Call (traced)
    │       └──► Routing Decision (logged)
    │
    ├──► Product QA Agent (traced)
    │       │
    │       ├──► LLM Call (traced)
    │       ├──► Tool Call (traced)
    │       │       │
    │       │       ├──► Embedding (traced)
    │       │       └──► Qdrant Query (traced)
    │       └──► Response (logged)
    │
    └──► Shopping Cart Agent (traced)
            │
            ├──► LLM Call (traced)
            ├──► Tool Call (traced)
            │       │
            │       └──► PostgreSQL Query (traced)
            └──► Response (logged)
    │
    ▼
FastAPI (ends trace, logs metrics)
    │
    ▼
LangSmith Dashboard
```

## Production Metrics (7-Day Period)

**Reliability**:
- Error Rate: 0%
- Uptime: 100%

**Performance**:
- P50 Latency: ~1.2-1.3s
- P99 Latency: ~1.5-1.6s

**Cost Efficiency**:
- P50 Cost per Trace: ~$0.01-0.05
- P99 Cost per Trace: Up to $0.25 (complex multi-agent workflows)

**Quality**:
- Routing Accuracy: 60%+ (maintained via CI/CD gates)
- User Feedback: Tracked and analyzed

## What is NOT Traced (Privacy)

**Excluded for Privacy**:
- Full user conversation content (only query/response pairs)
- Personal identifiable information (PII)
- Cart contents (only cart state metadata)
- Warehouse inventory details (only availability status)

**Data Retention**:
- Traces retained for analysis and debugging
- User feedback retained for quality improvement
- Metrics aggregated for trend analysis

## Future Enhancements

**Planned Observability Improvements**:
- Prometheus + Grafana for system metrics
- OpenTelemetry integration for distributed tracing
- Custom dashboards for business metrics
- Automated alerting (PagerDuty, Slack)
- Performance regression detection
- Cost anomaly detection

