#!/bin/bash
# bootstrap-workspace.sh — Party Panic Herdr Workspace Bootstrap
# Run once to set up all worktrees, agents, and Herdr workspace

set -euo pipefail

REPO_ROOT="/home/vsad/Dev/Party Panic"
cd "$REPO_ROOT"

echo "🚀 Bootstrapping Party Panic Herdr Workspace..."

# 1. Ensure main is clean and up to date
echo "📦 Syncing main..."
git fetch origin
git checkout main
git pull --rebase origin main

# 2. Create long-lived branches if missing
for branch in backend/main client/main map/main ui/main test/main; do
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "🌿 Creating branch: $branch"
    git branch "$branch" main
  fi
done

# Push long-lived branches
for branch in backend/main client/main map/main ui/main test/main; do
  git push -u origin "$branch" 2>/dev/null || true
done

# 3. Create worktrees
echo "🌳 Creating worktrees..."
declare -A WORKTREES=(
  ["../PartyPanic-backend"]="backend/main"
  ["../PartyPanic-client"]="client/main"
  ["../PartyPanic-map"]="map/main"
  ["../PartyPanic-ui"]="ui/main"
  ["../PartyPanic-test"]="test/main"
)

for path in "${!WORKTREES[@]}"; do
  branch="${WORKTREES[$path]}"
  if [ ! -d "$path" ]; then
    echo "  Creating worktree: $path ($branch)"
    git worktree add "$path" "$branch"
  else
    echo "  Worktree exists: $path"
  fi
done

# 4. Verify worktrees
echo "✅ Verifying worktrees..."
git worktree list

# 5. Install Herdr plugins (core only)
echo "🔌 Installing Herdr plugins (core)..."
herdr plugin install herdr/github 2>/dev/null || true
herdr plugin install herdr/git-worktree 2>/dev/null || true
herdr plugin install herdr/agent-router 2>/dev/null || true
herdr plugin install herdr/agent-status 2>/dev/null || true
herdr plugin install herdr/project-status 2>/dev/null || true
herdr plugin install herdr/logs 2>/dev/null || true
herdr plugin install herdr/workspace-bootstrap 2>/dev/null || true
herdr plugin install herdr/task-creation 2>/dev/null || true
herdr plugin install herdr/agent-spawning 2>/dev/null || true

# 6. Load Herdr workspace
echo "🏗️  Loading Herdr workspace..."
herdr workspace load .herdr-workspace.yaml

# 7. Spawn agents
echo "🤖 Spawning agents..."
herdr agent start leader --kind opencode --pane w1:p1 -- -m nemotron-3-ultra-free 2>/dev/null || true
herdr agent start orchestrator --kind opencode --pane w1:p2 2>/dev/null || true
herdr agent start backend --kind kilo --pane w1:p3 -- -m kilo/poolside/laguna-s-2.1:free 2>/dev/null || true
herdr agent start client --kind kilo --pane w1:p4 -- -m kilo/poolside/laguna-s-2.1:free 2>/dev/null || true
herdr agent start map --kind opencode --pane w1:p5 2>/dev/null || true
herdr agent start ui --kind opencode --pane w1:p6 2>/dev/null || true
herdr agent start tester --kind kilo --pane w1:p7 -- -m kilo/poolside/laguna-s-2.1:free 2>/dev/null || true
herdr agent start researcher --kind opencode --pane w1:p7 2>/dev/null || true
herdr agent start docs --kind opencode --pane w1:p8 2>/dev/null || true

# 8. Verify
echo "✅ Verifying agents..."
herdr agent list

echo ""
echo "✨ Workspace bootstrap complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Leader: Read .ai/AGENT_ROLES.md and .ai/WORKFLOW.md"
echo "  2. Leader: Dispatch first task via Orchestrator"
echo "  3. Operator: Monitor via 'herdr agent list'"
echo ""
echo "🎯 Ready for Party Panic development!"