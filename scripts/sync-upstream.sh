#!/usr/bin/env bash
# sync-upstream.sh — Rebase local changes atop upstream/main and summarize diff.
# 🤓 tribal: run from repo root; assumes upstream remote points to DeusData/codebase-memory-mcp
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== codebase-memory-mcp upstream sync ==="
echo ""

# Ensure upstream remote exists
if ! git remote | grep -q "^upstream$"; then
    echo "Adding upstream remote..."
    git remote add upstream https://github.com/DeusData/codebase-memory-mcp.git
fi

echo "Fetching upstream/main..."
git fetch upstream main

UPSTREAM="upstream/main"
LOCAL="main"

# Check if local is behind/ahead/diverged
BEHIND=$(git rev-list --count "$LOCAL..$UPSTREAM" 2>/dev/null || echo "0")
AHEAD=$(git rev-list --count "$UPSTREAM..$LOCAL" 2>/dev/null || echo "0")
MERGE_BASE=$(git merge-base "$LOCAL" "$UPSTREAM")

echo ""
echo "Local:  $(git rev-parse --short "$LOCAL") $(git log -1 --format=%s "$LOCAL")"
echo "Upstream: $(git rev-parse --short "$UPSTREAM") $(git log -1 --format=%s "$UPSTREAM")"
echo "Merge-base: $(git rev-parse --short "$MERGE_BASE")"
echo ""
echo "Commits behind upstream: $BEHIND"
echo "Commits ahead of upstream: $AHEAD"
echo ""

if [ "$BEHIND" -eq 0 ] && [ "$AHEAD" -eq 0 ]; then
    echo "✅ Already in sync with upstream. Nothing to do."
    exit 0
fi

# Summary of upstream changes
echo "--- Upstream changes since merge-base ---"
git log --oneline --reverse "$MERGE_BASE..$UPSTREAM"
echo ""

# If we have local changes, show them
if [ "$AHEAD" -gt 0 ]; then
    echo "--- Our local changes ---"
    git log --oneline --reverse "$MERGE_BASE..$LOCAL"
    echo ""
    echo "--- Diff stat (upstream vs local) ---"
    git diff --stat "$UPSTREAM..$LOCAL"
    echo ""
fi

# Generate a structured diff summary for b00t grok / SDD consumption
SUMMARY_FILE="_b00t_/upstream-sync-$(date +%Y%m%d)-$(git rev-parse --short "$UPSTREAM").md"
mkdir -p "$(dirname "$SUMMARY_FILE")"

cat > "$SUMMARY_FILE" <<EOF
# Upstream Sync Summary — $(date -u +%Y-%m-%dT%H:%M:%SZ)

| Metric | Value |
|--------|-------|
| upstream | $(git rev-parse --short "$UPSTREAM") |
| local | $(git rev-parse --short "$LOCAL") |
| merge-base | $(git rev-parse --short "$MERGE_BASE") |
| commits behind | $BEHIND |
| commits ahead | $AHEAD |

## Upstream commits

\`\`\`
$(git log --oneline --reverse "$MERGE_BASE..$UPSTREAM")
\`\`\`

## Local commits (if any)

\`\`\`
$(git log --oneline --reverse "$MERGE_BASE..$LOCAL" 2>/dev/null || echo "none")
\`\`\`

## Diff stat

\`\`\`
$(git diff --stat "$UPSTREAM..$LOCAL" 2>/dev/null || echo "no diff")
\`\`\`

<!-- b00t:map v1
summary: upstream sync diff summary for $(git rev-parse --short "$UPSTREAM")
tags: l3dg3rr, upstream, sync
tier: sm0l
cmds: scripts/sync-upstream.sh
complexity: 3
-->
EOF

echo "Summary written to: $SUMMARY_FILE"
echo ""

# Rebase workflow
if [ "$AHEAD" -gt 0 ]; then
    echo "⚠️  Local commits detected. Proposing rebase onto upstream/main..."
    echo "    Run: git rebase upstream/main"
    echo "    Or:  git rebase -i upstream/main"
    echo ""
    echo "After rebase, force-push to origin:"
    echo "    git push origin main --force-with-lease"
else
    echo "🔄 Fast-forward possible. Run:"
    echo "    git merge --ff-only upstream/main"
    echo "    git push origin main"
fi
