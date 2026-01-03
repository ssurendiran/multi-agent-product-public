# Public Release Assembly Guide

This document provides step-by-step instructions to assemble and publish the public portfolio repository.

## Folder Structure

```
public-release/
├── README.md                    # Main README (hiring-manager friendly)
├── LICENSE                      # Apache 2.0 License
├── SECURITY.md                  # Security policy
├── NOTICE                       # Third-party attributions
├── .gitignore                   # Git ignore rules
├── prepublish.sh                # Pre-publish security scan script
├── CLASSIFICATION.md            # File classification (Safe vs Private)
├── ASSEMBLY.md                  # This file
│
├── docs/                        # Documentation
│   ├── architecture.md          # System architecture
│   ├── flow.md                  # Step-by-step flows
│   ├── observability.md        # Observability setup
│   └── security.md              # Security posture
│
├── contracts/                   # API Contracts
│   └── openapi.yaml            # OpenAPI 3.0 specification
│
├── samples/                     # Sample Data
│   ├── sample_requests/        # Example API requests
│   │   ├── product_query.json
│   │   ├── cart_operation.json
│   │   ├── multi_step_query.json
│   │   ├── feedback_positive.json
│   │   └── feedback_negative.json
│   │
│   └── sample_responses/       # Example API responses
│       ├── product_query.json
│       ├── cart_operation.json
│       ├── multi_step_query.json
│       └── feedback_response.json
│
└── src_public/                  # Mock Implementation
    ├── README.md                # Mock mode documentation
    ├── pyproject.toml          # Python dependencies
    ├── app.py                  # FastAPI application (mock)
    └── api/
        ├── __init__.py
        ├── models.py           # Pydantic models
        └── mock_service.py     # Mock service implementation
```

## Assembly Commands

### Step 1: Verify Structure

```bash
cd public-release

# Verify all required files exist
./prepublish.sh
```

### Step 2: Run Security Scan

```bash
# Run pre-publish security scan
./prepublish.sh

# Fix any errors or warnings before proceeding
```

### Step 3: Review and Customize

**Required Customizations:**

1. **README.md**:
   - Update contact information
   - Update demo URLs (if available)
   - Update copyright year and name

2. **LICENSE**:
   - Update copyright year and name in APPENDIX section

3. **NOTICE**:
   - Update copyright year and name
   - Review third-party components list

4. **SECURITY.md**:
   - Update security contact email

5. **contracts/openapi.yaml**:
   - Update server URLs (replace `api.example.com`)
   - Update contact information

6. **docs/architecture.md**, **docs/flow.md**, etc.:
   - Review for any internal references
   - Ensure no proprietary details exposed

### Step 4: Test Mock Implementation (Optional)

```bash
cd src_public
uv sync  # or: pip install -r requirements.txt
uvicorn app:app --reload --port 8000

# Test endpoints
curl -X POST "http://localhost:8000/rag" \
  -H "Content-Type: application/json" \
  -d '{"query": "What kind of earphones can I get?", "thread_id": "test-123"}'
```

### Step 5: Final Security Check

```bash
cd public-release

# Run final security scan
./prepublish.sh

# Manual checks:
# - No API keys or secrets
# - No internal URLs/IPs
# - No proprietary prompts
# - No real database credentials
# - No full implementation code
```

### Step 6: Create Git Repository (if new)

```bash
cd public-release

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial public release: Architecture, contracts, and mock implementation"

# Add remote (if publishing to GitHub)
git remote add origin https://github.com/[your-org]/ai-assistant-ecosystem-public.git

# Push to remote
git push -u origin main
```

### Step 7: Publish

**Option A: New Repository**
```bash
# Create new GitHub repository
# Push public-release/ contents to new repo
git push -u origin main
```

**Option B: Existing Repository**
```bash
# Copy public-release/ contents to repository root
cp -r public-release/* /path/to/public-repo/
cd /path/to/public-repo
git add .
git commit -m "Public release: Architecture, contracts, and mock implementation"
git push
```

## Pre-Publish Checklist

### Documentation
- [ ] README.md updated with contact info and demo URLs
- [ ] All docs/ files reviewed for proprietary information
- [ ] Architecture diagrams accurate and complete
- [ ] Flow documentation matches actual implementation
- [ ] Observability docs describe what is traced (not how)
- [ ] Security docs describe posture (not implementation)

### Contracts
- [ ] OpenAPI spec complete and accurate
- [ ] All endpoints documented
- [ ] Request/response schemas match production
- [ ] Examples provided

### Samples
- [ ] Sample requests cover all use cases
- [ ] Sample responses realistic and sanitized
- [ ] No real data or PII in samples
- [ ] All samples valid JSON

### Mock Implementation
- [ ] Mock service returns deterministic responses
- [ ] No real LLM or database calls
- [ ] Pydantic models match production exactly
- [ ] FastAPI routes match production structure
- [ ] README explains mock vs production differences

### Security & Legal
- [ ] LICENSE file present (Apache 2.0)
- [ ] SECURITY.md present with contact info
- [ ] NOTICE file includes all third-party components
- [ ] .gitignore excludes secrets and sensitive files
- [ ] prepublish.sh script executable and tested

### Security Scan
- [ ] No API keys or secrets found
- [ ] No internal URLs/IPs found
- [ ] No proprietary prompts found
- [ ] No database credentials found
- [ ] No full implementation code exposed

### Content Review
- [ ] "Private Implementation Access" section in README
- [ ] Clear distinction between public and private
- [ ] No proprietary routing logic exposed
- [ ] No proprietary retrieval heuristics exposed
- [ ] No proprietary prompt templates exposed

## Post-Publish Tasks

1. **Update Private Repository**:
   - Add reference to public repository
   - Document what is public vs private

2. **Monitor**:
   - Watch for security issues
   - Respond to questions/feedback
   - Update documentation as needed

3. **Maintain**:
   - Keep public repo in sync with architecture changes
   - Update contracts when API changes
   - Refresh samples periodically

## Troubleshooting

### Security Scan Fails

**Issue**: Script finds potential secrets
**Solution**: 
- Review flagged patterns
- Ensure they are false positives or placeholders
- Update prepublish.sh if needed

### Mock Implementation Doesn't Run

**Issue**: Import errors or missing dependencies
**Solution**:
- Check Python version (3.12+)
- Install dependencies: `uv sync` or `pip install -r requirements.txt`
- Verify sample files exist in `../samples/`

### Missing Files

**Issue**: Required files not found
**Solution**:
- Run `./prepublish.sh` to see what's missing
- Check CLASSIFICATION.md for what should be included
- Verify all files from assembly guide are present

## Support

For questions or issues:
- Open an issue in the repository
- Contact: Open an issue in the repository or contact via GitHub profile

