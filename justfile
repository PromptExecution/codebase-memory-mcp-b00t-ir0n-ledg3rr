# justfile — codebase-memory-mcp (l3dg3rr)
# 🤓 tribal: replaces Makefile.cbm + shell scripts with just recipes
# Usage: just -l

set shell := ["bash", "-cu"]
set dotenv-load

repo := justfile_directory()
cbmbin := repo + "/build/c/codebase-memory-mcp"

# ┌── Default ────────────────────────────────────────────────────────────────────┐
default:
    @echo "l3dg3rr justfile — run 'just -l' for recipes"

# ┌── Build ────────────────────────────────────────────────────────────────────┐

# Production binary (no UI)
cbm:
    make -f Makefile.cbm cbm

# Production binary with embedded graph UI
cbm-with-ui:
    make -f Makefile.cbm cbm-with-ui

# Clean build artifacts
clean:
    make -f Makefile.cbm clean-c
    rm -rf build/c/embedded

# ┌── Test ────────────────────────────────────────────────────────────────────┐

# Foundation tests only (fast)
test-foundation:
    make -f Makefile.cbm test-foundation

# Full test suite (ASan + UBSan)
test:
    make -f Makefile.cbm test

# Thread sanitizer build
test-tsan:
    make -f Makefile.cbm test-tsan

# ┌── Lint ────────────────────────────────────────────────────────────────────┐

lint-tidy:
    make -f Makefile.cbm lint-tidy

lint-cppcheck:
    make -f Makefile.cbm lint-cppcheck

lint-format:
    make -f Makefile.cbm lint-format

lint: lint-tidy lint-cppcheck lint-format

# CI-friendly lint (no suppressions)
lint-ci:
    make -f Makefile.cbm lint-ci

# ┌── Security ───────────────────────────────────────────────────────────────────┐

# Audit vendored grammar scanner.c files
audit-grammar:
    scripts/audit-grammar-security.sh

# Full security suite
security: cbm
    make -f Makefile.cbm security

# ┌── Upstream Sync ──────────────────────────────────────────────────────────┐

# Fetch upstream and show diff summary
sync-upstream:
    scripts/sync-upstream.sh

# ┌── MCP / Docgen ──────────────────────────────────────────────────────────┐

# Index this repo into the knowledge graph
index-self mode="fast":
    {{cbmbin}} cli index_repository '{"repo_path":"{{repo}}","mode":"{{mode}}"}'

# Export docs in .tomllm format
doc-tomllm project="home-brianh-.b00t-vendor-codebase-memory-mcp-b00t-ir0n-ledg3rr":
    python3 _b00t_/scripts/l3dg3rr-doc-proxy.py --format=tomllm --project={{project}}

# Export docs in rustdoc format
doc-rustdoc project="home-brianh-.b00t-vendor-codebase-memory-mcp-b00t-ir0n-ledg3rr":
    python3 _b00t_/scripts/l3dg3rr-doc-proxy.py --format=rustdoc --project={{project}}

# Start HTTP UI server on port 9749
serve-ui port="9749": cbm-with-ui
    {{cbmbin}} --ui=true --port={{port}}

# ┌── Graph UI Frontend ─────────────────────────────────────────────────────┐

# Install frontend deps
ui-deps:
    cd graph-ui && npm ci

# Dev server for graph UI
ui-dev: ui-deps
    cd graph-ui && npm run dev

# Build graph UI
ui-build: ui-deps
    cd graph-ui && npm run build

# ┌── Bench / Misc ───────────────────────────────────────────────────────────────────┐

# Run benchmark indexer on a repo
bench-index repo_path:
    scripts/benchmark-index.sh {{repo_path}}

# ┌── b00t Integration ─────────────────────────────────────────────────────────┐

# Install l3dg3rr MCP into Hermes
install-hermes:
    #!/bin/bash
    set -euo pipefail
    echo "Installing codebase-memory MCP into Hermes..."
    b00t-cli mcp add '{
      "name": "codebase-memory",
      "command": "{{repo}}/build/c/codebase-memory-mcp",
      "args": []
    }' dotmcpjson
    echo "Done. Restart Hermes or run 'hermes config check' to validate."

# Install l3dg3rr MCP into b00t-native registry
install-b00t:
    #!/bin/bash
    set -euo pipefail
    echo "Registering codebase-memory in b00t MCP registry..."
    b00t mcp add '{
      "name": "codebase-memory",
      "command": "{{repo}}/build/c/codebase-memory-mcp",
      "args": []
    }'

# b00t:map v1
# summary: justfile for l3dg3rr — build, test, lint, sync, docgen, UI, b00t integration
# tags: l3dg3rr, just, build, mcp, docgen
# tier: sm0l
# cmds: just cbm, just test, just sync-upstream, just serve-ui, just doc-tomllm
# complexity: 4
