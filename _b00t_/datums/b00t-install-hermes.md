# b00t install hermes — Hermes Agent Bootstrap

> ⚠️ Status and metadata are derived by git lint. Do NOT inline mutable state.

## Problem

Hermes Agent is the CLI runtime for b00t-aligned agents. Currently:
- Hermes installs separately (`pip install hermes-agent` or standalone binary)
- b00t-mcp is registered in `~/.hermes/config.yaml` manually
- No unified "install hermes + wire b00t" command

## Proposal

Extend `b00t-cli install` to accept `hermes` as a virtual datum:

```bash
b00t install hermes              # Install Hermes + register b00t-mcp
b00t install hermes --help       # Show Hermes-specific install options
```

## Stage Gates

| Gate | Criteria |
|------|----------|
| G1 | `b00t install hermes` detects existing Hermes or installs it |
| G2 | Auto-registers `b00t-mcp` in `~/.hermes/config.yaml` |
| G3 | Auto-registers `codebase-memory` MCP if l3dg3rr is built |
| G4 | Validates config with `hermes config check` |

## Implementation Sketch

### b00t-cli datum config (`~/.dotfiles/_b00t_/hermes.toml`)

```toml
name = "hermes"
desires = "latest"

detect = "hermes --version"
detect_regex = "hermes ([0-9]+\\.[0-9]+\\.[0-9]+)"

install = "pip install --upgrade hermes-agent"
# OR for standalone:
# install = "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"

hint = "Hermes Agent CLI — AI agent runtime with native MCP support"

[mcp]
auto_register = ["b00t-mcp", "codebase-memory", "just-mcp"]
```

### Post-install hook

```bash
# After hermes binary is present:
hermes config set mcp_servers.b00t-mcp.command $(which b00t-mcp)
hermes config set mcp_servers.b00t-mcp.args '["stdio", "-d", "'${B00T_ROOT}'"]'
hermes config check
```

## Current State ✅

Hermes ALREADY sees b00t-mcp:

```yaml
# ~/.hermes/config.yaml
mcp_servers:
  b00t-mcp:
    command: /home/brianh/.cargo/bin/b00t-mcp
    args: [stdio, -d, /home/brianh/.b00t]
  codebase-memory:
    command: /home/brianh/.b00t/vendor/.../build/c/codebase-memory-mcp
    args: []
```

Hermes config check: PASS (config version 23).

## Gap

No automated idempotent bootstrap. User must manually:
1. Install Hermes
2. Edit `config.yaml` to add MCP servers
3. Run `hermes config check`

`b00t install hermes` would collapse this to one command.

<!-- b00t:map v1
summary: b00t install hermes — unified bootstrap for Hermes Agent + b00t MCP wiring
tags: hermes, b00t-cli, install, mcp, bootstrap
tier: frontier
cmds: b00t install hermes, hermes config check
complexity: 5
-->
