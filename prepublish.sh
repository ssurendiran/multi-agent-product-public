#!/bin/bash
#
# Pre-publish security scan script
# Scans for secrets, API keys, and sensitive data before publishing
#

set -e

echo "🔍 Running pre-publish security scan..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to check for secrets
check_secrets() {
    echo "Checking for API keys and secrets..."
    
    # Patterns to check for
    PATTERNS=(
        "sk-[a-zA-Z0-9]{32,}"           # OpenAI API key
        "gsk_[a-zA-Z0-9]{32,}"          # Groq API key
        "lsv2_[a-zA-Z0-9]{32,}"         # LangSmith API key
        "AIza[0-9A-Za-z_-]{35}"         # Google API key
        "AKIA[0-9A-Z]{16}"               # AWS Access Key
        "-----BEGIN.*PRIVATE KEY-----"   # Private keys
        "password\s*=\s*['\"][^'\"]+['\"]"  # Password assignments
        "secret\s*=\s*['\"][^'\"]+['\"]"   # Secret assignments
    )
    
    for pattern in "${PATTERNS[@]}"; do
        if grep -r -E "$pattern" . --exclude-dir=.git --exclude-dir=__pycache__ --exclude="prepublish.sh" --exclude="*.md" 2>/dev/null; then
            echo -e "${RED}❌ ERROR: Potential secret found matching pattern: $pattern${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

# Function to check for internal URLs/IPs
check_internal_urls() {
    echo "Checking for internal URLs and IP addresses..."
    
    # Patterns to check for
    PATTERNS=(
        "192\.168\.[0-9]+\.[0-9]+"       # Private IP ranges
        "10\.[0-9]+\.[0-9]+\.[0-9]+"
        "172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+"
        "localhost:[0-9]+"               # Localhost with port (might be OK, but check)
        "127\.0\.0\.1:[0-9]+"
        "surendiran\.ai"                  # Replace with your actual domain if needed
        "api\.surendiran\.ai"
        "demo\.surendiran\.ai"
    )
    
    for pattern in "${PATTERNS[@]}"; do
        if grep -r -E "$pattern" . --exclude-dir=.git --exclude-dir=__pycache__ --exclude="prepublish.sh" --exclude="*.md" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  WARNING: Internal URL/IP found: $pattern${NC}"
            echo "   Review if this should be public or use placeholder"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
}

# Function to check for database credentials
check_db_credentials() {
    echo "Checking for database credentials..."
    
    # Check for hardcoded database passwords
    if grep -r -i "postgres.*password" . --exclude-dir=.git --exclude-dir=__pycache__ --exclude="prepublish.sh" --exclude="*.md" 2>/dev/null | grep -v "POSTGRES_PASSWORD" | grep -v "example"; then
        echo -e "${RED}❌ ERROR: Potential hardcoded database password found${NC}"
        ERRORS=$((ERRORS + 1))
    fi
}

# Function to check file structure
check_structure() {
    echo "Checking required files..."
    
    REQUIRED_FILES=(
        "README.md"
        "LICENSE"
        "SECURITY.md"
        "NOTICE"
        ".gitignore"
        "docs/architecture.md"
        "docs/flow.md"
        "docs/observability.md"
        "docs/security.md"
        "contracts/openapi.yaml"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}❌ ERROR: Required file missing: $file${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✓${NC} Found: $file"
        fi
    done
}

# Function to check for proprietary code
check_proprietary() {
    echo "Checking for proprietary code that shouldn't be public..."
    
    # Check for prompt files (should not be in public repo)
    if find . -name "*.yaml" -path "*/prompts/*" 2>/dev/null | grep -v ".git"; then
        echo -e "${RED}❌ ERROR: Prompt files found in public repo!${NC}"
        echo "   Prompt templates should remain in private repository"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check for full agent implementations
    if find . -name "agents.py" -o -name "graph.py" -o -name "tools.py" 2>/dev/null | grep -v ".git" | grep -v "src_public"; then
        echo -e "${YELLOW}⚠️  WARNING: Agent implementation files found${NC}"
        echo "   Ensure these are mock implementations only"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# Run all checks
echo ""
check_structure
echo ""
check_secrets
echo ""
check_internal_urls
echo ""
check_db_credentials
echo ""
check_proprietary
echo ""

# Summary
echo "=========================================="
echo "Scan Summary:"
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Safe to publish.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found. Review before publishing.${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(s) and $WARNINGS warning(s) found.${NC}"
    echo "   Please fix errors before publishing."
    exit 1
fi

