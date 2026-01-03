# System Flows

This document describes the step-by-step flows for the four core agents: **Coordinator Agent**, **Product QA Agent**, **Shopping Cart Agent**, and **Warehouse Manager Agent**.

## Flow 1: Product Q&A

**User Query**: "What kind of earphones can I get?"

### Step-by-Step Flow

1. **User submits query**
   - User types query in Streamlit UI
   - Streamlit sends `POST /rag` to FastAPI with `{query, thread_id}`

2. **FastAPI receives request**
   - FastAPI creates request ID
   - Starts LangSmith trace
   - Builds initial state for LangGraph workflow
   - Compiles LangGraph workflow with PostgreSQL checkpointer

3. **LangGraph workflow starts**
   - Workflow begins at `_start_` node
   - Routes to `coordinator_agent` node

4. **Coordinator Agent analyzes intent**
   - Coordinator receives: `{query, conversation_history, thread_id}`
   - Calls LLM (via LiteLLM) with intent analysis prompt
   - LLM returns structured output: `{next_agent: "product_qa_agent", plan: "...", final_answer: null}`

5. **Coordinator routes to Product QA Agent**
   - Workflow routes to `product_qa_agent` node
   - Passes query and conversation history

6. **Product QA Agent processes query**
   - Agent receives query and context
   - Calls LLM (via LiteLLM) with product query prompt
   - LLM returns: `{tool_calls: [{name: "get_formatted_item_context", arguments: {...}}], final_answer: null}`

7. **Product QA Agent invokes tool**
   - Workflow routes to `product_qa_agent_tool_node`
   - Tool node executes `get_formatted_item_context`

8. **Tool performs hybrid search**
   - Tool embeds query using OpenAI `text-embedding-3-small`
   - Generates 1536-dimensional vector
   - Queries Qdrant with hybrid search:
     - **Dense search**: Semantic similarity (COSINE) with query vector
     - **Sparse search**: BM25 keyword matching
     - **Fusion**: Reciprocal Rank Fusion (RRF) combines results
   - Retrieves top-k products (e.g., top 5)
   - Formats product context (description, price, image, rating)

9. **Tool returns formatted context**
   - Tool returns formatted product information to agent
   - Workflow routes back to `product_qa_agent`

10. **Product QA Agent generates answer**
    - Agent receives formatted context
    - Calls LLM (via LiteLLM) with context + query
    - LLM returns structured output: `{final_answer: "...", answer: "...", references: [...]}`

11. **Product QA Agent returns to Coordinator**
    - Agent returns: `{answer, used_context, references}`
    - Workflow routes back to `coordinator_agent`

12. **Coordinator reviews and finalizes**
    - Coordinator receives answer from Product QA Agent
    - Reviews plan completion
    - Calls LLM to finalize response
    - LLM returns: `{final_answer: true, answer: "...", next_agent: "end"}`

13. **Workflow ends**
    - Coordinator routes to `_end_` node
    - FastAPI streams response via Server-Sent Events (SSE)
    - Response format: `{request_id, answer, used_context}`

14. **Streamlit displays response**
    - Streamlit receives SSE stream
    - Displays answer with product references
    - Shows product images and prices in sidebar

15. **Observability**
    - All steps traced in LangSmith
    - Metrics recorded: latency, tokens, costs
    - Trace available for debugging

## Flow 2: Shopping Cart Operations

**User Query**: "Add the most durable iPhone charger to my cart"

### Step-by-Step Flow

1. **User submits query**
   - User types query in Streamlit UI
   - Streamlit sends `POST /rag` to FastAPI with `{query, thread_id}`

2. **FastAPI receives request**
   - FastAPI creates request ID
   - Starts LangSmith trace
   - Builds initial state (loads conversation history from PostgreSQL checkpoint)
   - Compiles LangGraph workflow

3. **LangGraph workflow starts**
   - Workflow begins at `_start_` node
   - Routes to `coordinator_agent` node

4. **Coordinator Agent analyzes intent**
   - Coordinator receives: `{query, conversation_history, thread_id}`
   - Analyzes: Query requires product search + cart operation
   - Creates plan: "1. Find most durable iPhone charger, 2. Add to cart"
   - Routes to Product QA Agent first

5. **Product QA Agent finds product**
   - Agent receives query: "most durable iPhone charger"
   - Invokes `get_formatted_item_context` tool
   - Tool performs hybrid search in Qdrant
   - Retrieves iPhone charger products
   - Invokes `get_formatted_reviews_context` tool
   - Tool searches reviews collection (filtered by product IDs)
   - Analyzes reviews for durability mentions
   - Agent selects most durable product (e.g., product ID: `B0BYYLJRHT`)
   - Returns to coordinator with product recommendation

6. **Coordinator routes to Shopping Cart Agent**
   - Coordinator receives product recommendation
   - Updates plan: "Product found, now add to cart"
   - Routes to `shopping_cart_agent` node

7. **Shopping Cart Agent processes cart operation**
   - Agent receives: `{query: "add to cart", product_id: "B0BYYLJRHT", ...}`
   - Calls LLM to understand cart operation
   - LLM returns: `{tool_calls: [{name: "add_to_shopping_cart", arguments: {product_id: "B0BYYLJRHT", quantity: 1}}]}`

8. **Shopping Cart Agent invokes tool**
   - Workflow routes to `shopping_cart_agent_tool_node`
   - Tool node executes `add_to_shopping_cart`

9. **Tool writes to PostgreSQL**
   - Tool connects to PostgreSQL
   - Inserts/updates row in `shopping_carts.shopping_cart_items` table:
     - `user_id`: From thread_id
     - `product_id`: "B0BYYLJRHT"
     - `price`: From product metadata
     - `quantity`: 1
     - `product_image_url`: From product metadata
   - Returns success confirmation

10. **Tool returns to Shopping Cart Agent**
    - Tool returns cart update confirmation
    - Workflow routes back to `shopping_cart_agent`

11. **Shopping Cart Agent generates response**
    - Agent receives cart update confirmation
    - Calls LLM to generate user-friendly response
    - LLM returns: `{final_answer: true, answer: "I've added the iPhone charger to your cart..."}`

12. **Shopping Cart Agent returns to Coordinator**
    - Agent returns: `{answer, cart_state: {...}}`
    - Workflow routes back to `coordinator_agent`

13. **Coordinator reviews and finalizes**
    - Coordinator receives answer from Shopping Cart Agent
    - Reviews plan completion (both steps done)
    - Calls LLM to finalize response
    - LLM returns: `{final_answer: true, answer: "...", next_agent: "end"}`

14. **Workflow ends**
    - Coordinator routes to `_end_` node
    - FastAPI saves checkpoint to PostgreSQL (conversation state)
    - FastAPI streams response via SSE
    - Response format: `{request_id, answer, used_context, cart_state}`

15. **Streamlit displays response**
    - Streamlit receives SSE stream
    - Displays answer: "I've added the iPhone charger to your cart..."
    - Updates shopping cart sidebar with new item
    - Shows product image, price, quantity

16. **Observability**
    - All steps traced in LangSmith
    - Multi-agent workflow visible in trace waterfall
    - Metrics recorded: latency, tokens, costs
    - User feedback can be linked to trace

## Flow 3: Warehouse Manager Operations

**User Query**: "Check availability and reserve the iPhone charger in your warehouse"

### Step-by-Step Flow

1. **User submits query**
   - User types query in Streamlit UI
   - Streamlit sends `POST /rag` to FastAPI with `{query, thread_id}`

2. **FastAPI receives request**
   - FastAPI creates request ID
   - Starts LangSmith trace
   - Builds initial state (loads conversation history from PostgreSQL checkpoint)
   - Compiles LangGraph workflow

3. **LangGraph workflow starts**
   - Workflow begins at `_start_` node
   - Routes to `coordinator_agent` node

4. **Coordinator Agent analyzes intent**
   - Coordinator receives: `{query, conversation_history, thread_id}`
   - Analyzes: Query requires warehouse operations (availability check + reservation)
   - Creates plan: "1. Check warehouse availability, 2. Reserve items"
   - Routes to Warehouse Manager Agent

5. **Warehouse Manager Agent processes request**
   - Agent receives: `{query: "check availability and reserve", product_id: "B0BYYLJRHT", ...}`
   - Calls LLM to understand warehouse operation
   - LLM returns: `{tool_calls: [{name: "check_warehouse_availability", arguments: {product_id: "B0BYYLJRHT"}}]}`

6. **Warehouse Manager Agent invokes availability tool**
   - Workflow routes to `warehouse_manager_agent_tool_node`
   - Tool node executes `check_warehouse_availability`

7. **Tool queries PostgreSQL**
   - Tool connects to PostgreSQL
   - Queries `warehouse_management.warehouse_inventory` table:
     - Checks `product_id`: "B0BYYLJRHT"
     - Returns availability across warehouses:
       - `DE-BER-01`: 50 units available
       - `US-NY-01`: 30 units available
   - Returns availability data

8. **Tool returns to Warehouse Manager Agent**
   - Tool returns warehouse availability
   - Workflow routes back to `warehouse_manager_agent`

9. **Warehouse Manager Agent creates reservation**
   - Agent receives availability data
   - Calls LLM to decide reservation
   - LLM returns: `{tool_calls: [{name: "reserve_warehouse_items", arguments: {product_id: "B0BYYLJRHT", warehouse_id: "DE-BER-01", quantity: 1}}]}`

10. **Warehouse Manager Agent invokes reservation tool**
    - Workflow routes to `warehouse_manager_agent_tool_node`
    - Tool node executes `reserve_warehouse_items`

11. **Tool writes reservation to PostgreSQL**
    - Tool connects to PostgreSQL
    - Inserts row in `warehouse_management.warehouse_reservations` table:
      - `product_id`: "B0BYYLJRHT"
      - `warehouse_id`: "DE-BER-01"
      - `quantity`: 1
      - `reservation_id`: Generated unique ID
      - `ready_by`: Timestamp (e.g., 24 hours from now)
    - Updates inventory count
    - Returns reservation confirmation

12. **Tool returns to Warehouse Manager Agent**
    - Tool returns reservation details
    - Workflow routes back to `warehouse_manager_agent`

13. **Warehouse Manager Agent generates response**
    - Agent receives reservation confirmation
    - Calls LLM to generate user-friendly response
    - LLM returns: `{final_answer: true, answer: "I've reserved the iPhone charger at Berlin Distribution Center..."}`

14. **Warehouse Manager Agent returns to Coordinator**
    - Agent returns: `{answer, reservation_details: {...}}`
    - Workflow routes back to `coordinator_agent`

15. **Coordinator reviews and finalizes**
    - Coordinator receives answer from Warehouse Manager Agent
    - Reviews plan completion
    - Calls LLM to finalize response
    - LLM returns: `{final_answer: true, answer: "...", next_agent: "end"}`

16. **Workflow ends**
    - Coordinator routes to `_end_` node
    - FastAPI saves checkpoint to PostgreSQL (conversation state)
    - FastAPI streams response via SSE
    - Response format: `{request_id, answer, reservation_details}`

17. **Streamlit displays response**
    - Streamlit receives SSE stream
    - Displays answer: "I've reserved the iPhone charger at Berlin Distribution Center (DE-BER-01). Ready for pickup within 24 hours."
    - Shows reservation details

18. **Observability**
    - All steps traced in LangSmith
    - Warehouse operations visible in trace
    - Metrics recorded: latency, tokens, costs

## Flow 4: Multi-Agent Coordination (Complex Query)

**User Query**: "Can I get a charger for my iPhone and a waterproof speaker? Could you get user reviews about durability of each item and add the most durable ones to my shopping cart? Could you then also make a reservation for these items in your warehouses?"

This demonstrates all four agents working together.

### Step-by-Step Flow

1. **User submits complex query**
   - User types multi-step query in Streamlit UI
   - Streamlit sends `POST /rag` to FastAPI

2. **FastAPI receives request**
   - FastAPI creates request ID
   - Starts LangSmith trace
   - Builds initial state
   - Compiles LangGraph workflow

3. **Coordinator Agent creates multi-step plan**
   - Coordinator analyzes complex query
   - Creates plan:
     1. Find products (Product QA Agent)
     2. Analyze reviews for durability (Product QA Agent)
     3. Add to cart (Shopping Cart Agent)
     4. Reserve in warehouse (Warehouse Manager Agent)
   - Routes to Product QA Agent first

4. **Product QA Agent - Step 1: Find Products**
   - Agent receives query about iPhone charger and waterproof speaker
   - Invokes `get_formatted_item_context` tool
   - Performs hybrid search in Qdrant
   - Retrieves iPhone charger and speaker products
   - Returns product recommendations to coordinator

5. **Product QA Agent - Step 2: Analyze Reviews**
   - Coordinator routes back to Product QA Agent
   - Agent invokes `get_formatted_reviews_context` tool
   - Searches reviews collection filtered by product IDs
   - Analyzes reviews for durability mentions
   - Selects most durable products:
     - iPhone Charger: B0BYYLJRHT (89% positive durability reviews)
     - Waterproof Speaker: B0C69MM2TP (92% positive durability reviews)
   - Returns durability analysis to coordinator

6. **Coordinator routes to Shopping Cart Agent**
   - Coordinator receives product recommendations
   - Updates plan: "Products found, now add to cart"
   - Routes to Shopping Cart Agent

7. **Shopping Cart Agent adds items**
   - Agent receives products to add
   - Invokes `add_to_shopping_cart` tool for each item
   - Writes to PostgreSQL `shopping_carts` table
   - Returns cart summary to coordinator

8. **Coordinator routes to Warehouse Manager Agent**
   - Coordinator receives cart confirmation
   - Updates plan: "Items in cart, now reserve in warehouse"
   - Routes to Warehouse Manager Agent

9. **Warehouse Manager Agent checks availability**
   - Agent receives products to reserve
   - Invokes `check_warehouse_availability` tool
   - Queries PostgreSQL for inventory
   - Finds availability:
     - B0BYYLJRHT: Available at DE-BER-01
     - B0C69MM2TP: Available at DE-BER-01
   - Returns availability to agent

10. **Warehouse Manager Agent creates reservations**
    - Agent invokes `reserve_warehouse_items` tool
    - Creates reservations in PostgreSQL
    - Both items reserved at DE-BER-01
    - Returns reservation confirmation to coordinator

11. **Coordinator finalizes response**
    - Coordinator receives all results:
      - Product recommendations (Product QA)
      - Cart update (Shopping Cart)
      - Warehouse reservations (Warehouse Manager)
    - Reviews complete plan execution
    - Calls LLM to synthesize final response
    - LLM returns comprehensive answer covering all steps

12. **Workflow ends**
    - Coordinator routes to `_end_` node
    - FastAPI saves checkpoint (full conversation state)
    - FastAPI streams comprehensive response via SSE
    - Response includes: answer, used_context, cart_state, warehouse_reservation

13. **Streamlit displays complete response**
    - Streamlit receives SSE stream
    - Displays comprehensive answer
    - Shows product recommendations
    - Updates cart sidebar
    - Shows warehouse reservation details

14. **Observability**
    - Complete multi-agent workflow traced in LangSmith
    - All four agents visible in trace waterfall
    - Full metrics: latency, tokens, costs across all agents
    - Demonstrates coordinator orchestration capabilities

## Multi-Agent Coordination

**Key Pattern**: Coordinator orchestrates multiple agents sequentially

1. **Coordinator creates plan**: Breaks down complex query into steps
2. **Routes to first agent**: Delegates to appropriate specialist
3. **Agent completes task**: Executes tools, generates response
4. **Returns to coordinator**: Agent reports completion
5. **Coordinator reviews**: Checks plan progress
6. **Routes to next agent** (if needed): Continues with next step
7. **Finalizes response**: Combines results, returns to user

**State Persistence**:
- Conversation history stored in PostgreSQL checkpoint (per `thread_id`)
- Cart state stored in PostgreSQL `shopping_carts` schema
- Enables conversation continuity across sessions

## Error Handling

**LLM API Errors**:
- LiteLLM automatically retries on transient errors
- Falls back to Groq if OpenAI rate limits
- Returns structured error to coordinator

**Tool Errors**:
- Tool failures return error to agent
- Agent can retry or return error to coordinator
- Coordinator can route to different agent or return error to user

**Database Errors**:
- PostgreSQL connection errors retried
- Transaction rollback on failures
- Error logged to LangSmith trace

## Performance Characteristics

**Product Q&A Flow**:
- P50 latency: ~1.2-1.3s
- P99 latency: ~1.5-1.6s
- Components: Coordinator (200ms) + Product QA (400ms) + Retrieval (300ms) + LLM (300ms)

**Shopping Cart Flow**:
- P50 latency: ~1.5-2.0s
- P99 latency: ~2.5-3.0s
- Components: Coordinator (200ms) + Product QA (400ms) + Shopping Cart (300ms) + Database (100ms) + LLM (500ms)

**Warehouse Manager Flow**:
- P50 latency: ~1.3-1.8s
- P99 latency: ~2.0-2.5s
- Components: Coordinator (200ms) + Warehouse Manager (300ms) + Database (200ms) + LLM (400ms)

**Multi-Agent Coordination Flow**:
- P50 latency: ~2.5-3.5s
- P99 latency: ~4.0-5.0s
- Components: Coordinator (400ms) + Product QA (600ms) + Shopping Cart (300ms) + Warehouse Manager (400ms) + Multiple DB queries (300ms) + Multiple LLM calls (1.5s)

**Optimization Opportunities**:
- Parallel agent execution (when independent)
- Caching retrieval results
- Batch LLM calls
- Connection pooling for databases

