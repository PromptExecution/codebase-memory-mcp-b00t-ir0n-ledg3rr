#!/usr/bin/env bash
# datum-meta.sh — Git hooks for datum metadata tracking
# 
# 🤓 tribal: research_date and datum_version are GIT METADATA, not file content.
# Do NOT edit datum .md files for trivial bumps. Use git notes instead.
#
# Install:
#   cp _b00t_/hooks/datum-meta.sh .git/hooks/pre-commit
#   cp _b00t_/hooks/datum-meta.sh .git/hooks/post-commit
#   chmod +x .git/hooks/pre-commit .git/hooks/post-commit

set -euo pipefail

HOOK_NAME="$(basename "$0")"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DATUM_DIR="${REPO_ROOT}/_b00t_/datums"
META_REF="refs/notes/datum-meta"

# ── pre-commit: block trivial bumps ────────────────────────────
if [ "$HOOK_NAME" = "pre-commit" ]; then
    # Check if any datum files are staged
    staged_datums=$(git diff --cached --name-only --diff-filter=M | grep "^_b00t_/datums/.*\.md$" || true)
    
    if [ -n "$staged_datums" ]; then
        # Check for forbidden inline metadata edits
        bad_lines=$(git diff --cached -- "$DATUM_DIR"/*.md | grep -E "^[+-]\| (research_date|datum_version) \|" || true)
        if [ -n "$bad_lines" ]; then
            echo "❌ BLOCKED: Inline datum metadata edits detected." >&2
            echo "   research_date and datum_version are GIT PROPERTIES, not file content." >&2
            echo "   Remove these lines from your diff and retry." >&2
            echo "" >&2
            echo "Offending lines:" >&2
            echo "$bad_lines" >&2
            exit 1
        fi
        
        # TODO: significance survey (b00t survey WIP)
        # echo "⚠️  Datum changes staged. Run 'b00t survey' before commit (WIP)."
    fi
    exit 0
fi

# ── post-commit: record metadata via git notes ─────────────────
if [ "$HOOK_NAME" = "post-commit" ]; then
    commit_hash=$(git rev-parse HEAD)
    commit_msg=$(git log -1 --pretty=%s)
    
    # Only track if commit touched datums
    changed_datums=$(git diff-tree --no-commit-id --name-only -r "$commit_hash" | grep "^_b00t_/datums/.*\.md$" || true)
    
    if [ -n "$changed_datums" ]; then
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        researcher="${B00T_RESEARCHER:-$(git config user.name || echo 'unknown')}"
        
        meta=$(jq -n \
            --arg ts "$ts" \
            --arg researcher "$researcher" \
            --arg commit "$commit_hash" \
            --arg msg "$commit_msg" \
            --argjson files "$(echo "$changed_datums" | jq -R . | jq -s .)" \
            '{
                research_date: $ts,
                researcher: $researcher,
                commit: $commit,
                message: $msg,
                files: $files
            }')
        
        git notes --ref="$META_REF" add -m "$meta" "$commit_hash" 2>/dev/null || \
            git notes --ref="$META_REF" append -m "$meta" "$commit_hash"
        
        echo "📝 Datum metadata recorded in git notes ($META_REF)"
    fi
    exit 0
fi

echo "Unknown hook: $HOOK_NAME" >&2
exit 1
