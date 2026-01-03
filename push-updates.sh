#!/bin/bash
# Script to push public-release to GitHub

set -e

echo "🚀 Pushing public-release to GitHub..."
echo ""

# Navigate to public-release directory
cd "$(dirname "$0")"

# Check if already a git repo
if [ -d ".git" ]; then
    echo "⚠️  .git folder exists. Removing to start fresh..."
    rm -rf .git
fi

# Initialize git
echo "📦 Initializing git repository..."
git init

# Add remote
echo "🔗 Adding remote repository..."
git remote add origin https://github.com/ssurendiran/multi-agent-product-public.git 2>/dev/null || \
git remote set-url origin https://github.com/ssurendiran/multi-agent-product-public.git

# Add all files
echo "➕ Adding all files..."
git add .

# Show what will be committed
echo ""
echo "📋 Files to be committed:"
git status --short

# Commit
echo ""
echo "💾 Creating commit..."
git commit -m "Initial public release: Architecture, contracts, and mock implementation

- Complete architecture documentation
- OpenAPI specification
- Sample requests/responses
- Mock-mode implementation
- Security and legal files
- Comprehensive documentation for hiring managers
- Updated placeholders for professional presentation"

# Set main branch
echo "🌿 Setting main branch..."
git branch -M main

# Push
echo ""
echo "⬆️  Pushing to GitHub..."
echo "   (You may be prompted for GitHub credentials)"
git push -u origin main

echo ""
echo "✅ Done! Check your repository at:"
echo "   https://github.com/ssurendiran/multi-agent-product-public"
echo ""

