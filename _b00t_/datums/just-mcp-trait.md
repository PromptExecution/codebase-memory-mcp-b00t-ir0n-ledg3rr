# just-mcp as First-Class Executable Interface Trait

> ⚠️ Status and metadata are derived by git lint. Do NOT inline mutable state.

## Problem

`just-mcp` exists in `b00t mcp list` but:
- Directory `/home/brianh/.b00t/just-mcp/` is EMPTY (stub)
- No Rust trait defines what a "just-mcp executable interface" IS
- b00t-cli references `just-mcp` as a string datum name, not a typed interface

## Proposal

Define a Rust trait `JustMcpInterface` in `b00t-cli` (or a new `b00t-traits` crate) that:
1. Introspects a justfile
2. Exposes recipes as MCP tools
3. Enforces ACL at recipe level
4. Streams recipe output as MCP progress

## Trait Definition (Pseudocode)

```rust
/// Generic type invariant: every just-mcp implementation MUST:
/// - Be discoverable via `just --list --unsorted`
/// - Return JSON on `just --dump`
/// - Accept `--justfile <path>` override
/// - Exit 0 on success, non-zero on failure
pub trait JustMcpInterface: Send + Sync {
    /// Invariant: returns absolute path to justfile
    fn justfile_path(&self) -> &std::path::Path;

    /// Invariant: recipes are sorted by declaration order
    fn list_recipes(&self) -> Vec<Recipe>;

    /// Invariant: recipe exists and passes ACL check
    fn execute(&self, recipe: &str, args: &[String]) -> Result<RecipeOutput, McpError>;

    /// Invariant: ACL applies BEFORE execution
    fn acl_check(&self, recipe: &str) -> Result<(), AclError>;

    /// Invariant: progress events stream every 100ms or on newline
    fn stream_progress(&self) -> tokio::sync::mpsc::Receiver<ProgressEvent>;
}

/// Invariant: Recipe metadata is read-only after construction
#[derive(Clone, Debug)]
pub struct Recipe {
    pub name: String,
    pub doc: Option<String>,
    pub parameters: Vec<Parameter>,
    pub is_private: bool,
}

/// Invariant: Output includes exit code, stdout, stderr, timing
pub struct RecipeOutput {
    pub exit_code: i32,
    pub stdout: String,
    pub stderr: String,
    pub elapsed_ms: u64,
}
```

## Implementation Plan

### Phase 1: Fill the stub
```bash
cd /home/brianh/.b00t/just-mcp
# Scaffold Rust crate or Node.js wrapper that:
#   - Spawns `just --dump --dump-format=json`
#   - Maps recipes to MCP tools
#   - Enforces ACL from ~/.dotfiles/b00t-mcp-acl.toml
```

### Phase 2: Trait in b00t-cli
Add to `b00t-cli/src/lib.rs`:
```rust
pub mod just_mcp;
```

### Phase 3: Integration test
```bash
just test-mcp  # existing test in b00t-cli justfile
```

## Current Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| b00t-cli reference | `b00t-cli/src/lib.rs:just-mcp` | string literal |
| Empty stub | `~/.b00t/just-mcp/` | empty dir |
| ACL config | `~/.dotfiles/b00t-mcp-acl.toml` | exists |
| Main justfile | `~/.b00t/justfile` | 20+ modules |

## Next Step

Implement `just-mcp` as a Rust binary in `vendor/just-mcp/` using the trait above, then register it in b00t MCP registry.

<!-- b00t:map v1
summary: just-mcp first-class trait — typed interface for exposing just recipes as MCP tools
tags: just-mcp, trait, rust, mcp, b00t-cli, executable-interface
tier: frontier
cmds: just test-mcp, b00t mcp list | grep just-mcp
complexity: 7
-->
