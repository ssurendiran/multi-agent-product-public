# Push Updates to GitHub

## Quick Push Commands

Run these commands in your terminal to push all updates:

```bash
cd /Users/suren/BOOTCAMP/ai-assistant-ecosystem/public-release

# Check current status
git status

# Add all changes (including our updates)
git add -A

# Check what will be committed
git status

# Commit the updates
git commit -m "Update: Add four core agent flows and live demo URLs

- Updated README with four core agent flows (Coordinator, Product QA, Shopping Cart, Warehouse Manager)
- Added Warehouse Manager flow documentation
- Added Multi-Agent Coordination flow
- Updated live demo URLs: demo.surendiran.ai and api.surendiran.ai
- Updated OpenAPI spec with production URLs
- Enhanced flow.md with complete agent flow documentation"

# Push to GitHub
git push origin main
```

## What Was Updated

### Files Modified:
1. **README.md**
   - Changed "Two Core Flows" → "Four Core Agent Flows"
   - Added Coordinator Agent flow
   - Added Warehouse Manager Agent flow
   - Added Multi-Agent Coordination example
   - Updated demo URLs to `demo.surendiran.ai` and `api.surendiran.ai`

2. **docs/flow.md**
   - Added Flow 3: Warehouse Manager Operations (18 steps)
   - Added Flow 4: Multi-Agent Coordination (14 steps)
   - Added performance metrics for new flows

3. **contracts/openapi.yaml**
   - Updated server URL: `https://api.surendiran.ai`
   - Updated curl examples with production URL

## Verify After Pushing

After pushing, check:
1. https://github.com/ssurendiran/multi-agent-product-public
2. README.md should show "Four Core Agent Flows"
3. Demo section should show `demo.surendiran.ai` and `api.surendiran.ai`
4. OpenAPI spec should have `api.surendiran.ai` as production server

## Troubleshooting

If you get authentication errors:
- Use GitHub Personal Access Token
- Or use SSH: `git remote set-url origin git@github.com:ssurendiran/multi-agent-product-public.git`

If files are already committed:
- The changes might already be in the repo
- Check GitHub to see if updates are there
- If not, force add: `git add -f .` then commit and push

