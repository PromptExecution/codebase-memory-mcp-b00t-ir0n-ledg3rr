# k0mmand3r Loop Extension Syntax

> ⚠️ Metadata derived by git lint. Do NOT inline mutable state.

## Concept

Generic loop runner for b00t: wrap ANY command in an autoresearch-style iteration loop.
Inspired by `git@github.com:PromptExecution/autoresearch-b00t-ledgrrr.git`.

**Core idea:** `b00t --loop=<spec> <command>` runs `<command>` repeatedly, measuring a scalar metric, keeping improvements, reverting regressions.

## Syntax

### CLI Form

```bash
# Inline spec (compact)
b00t --loop="metric:coverage|verify:pytest|max:50" test

# TOML spec file
b00t --loop=loop.toml test

# k0mmand3r REPL form
/loop goal="reduce compile time" metric="ms" verify="just cbm" max=100
```

### Spec Grammar

```ebnf
loop-spec    = keyval *( "|" keyval )
keyval       = key ":" value
key          = "goal" | "metric" | "verify" | "guard" | "max" | "scope" | "direction"
value        = *VCHAR
```

### Keys

| Key | Required | Description |
|-----|----------|-------------|
| `goal` | Yes | Plain-language objective |
| `metric` | Yes | Scalar to optimize (parseable number) |
| `verify` | Yes | Shell command that prints the metric |
| `guard` | No | Safety command; must pass every iteration |
| `max` | No | Max iterations (default: unlimited) |
| `scope` | No | File glob limiting what the loop may change |
| `direction` | No | `higher` or `lower` (default: inferred from first 2 runs) |

## k0mmand3r Integration

### New Verbs

```
/loop start <spec>        # Begin loop with spec
/loop pause               # Halt iteration, preserve state
/loop resume              # Continue from halt
/loop status              # Show current iteration, best metric, last result
/loop abort               # Stop and revert all uncommitted changes
```

### Loop State Machine

```
IDLE → BASELINE → ITER → VERIFY → [KEEP|REVERT] → ITER...
                → PAUSED → RESUME
                → DONE (max reached or converged)
                → ABORTED
```

## Implementation Sketch

### b00t-cli extension

```rust
// src/commands/loop.rs
pub struct LoopRunner {
    spec: LoopSpec,
    baseline: f64,
    best: f64,
    iteration: u32,
}

impl LoopRunner {
    pub async fn run(&mut self, cmd: &[String]) -> Result<LoopResult> {
        // 1. Establish baseline
        self.baseline = self.measure().await?;
        self.best = self.baseline;

        loop {
            // 2. Run user command
            let status = Command::new("sh").arg("-c").args(cmd).status()?;
            if !status.success() {
                self.revert().await?;
                continue;
            }

            // 3. Measure metric
            let current = self.measure().await?;

            // 4. Compare
            let improved = match self.spec.direction {
                Direction::Higher => current > self.best,
                Direction::Lower => current < self.best,
            };

            if improved {
                self.commit_iteration().await?;
                self.best = current;
            } else {
                self.revert().await?;
            }

            // 5. Check termination
            if self.spec.max.map(|m| self.iteration >= m).unwrap_or(false) {
                break;
            }
            self.iteration += 1;
        }

        Ok(LoopResult { best: self.best, iterations: self.iteration })
    }
}
```

### MCP Tool Surface

```json
{
  "name": "b00t_loop",
  "description": "Run a b00t command in an iterative improvement loop",
  "inputSchema": {
    "type": "object",
    "properties": {
      "goal": {"type": "string"},
      "metric": {"type": "string"},
      "verify": {"type": "string"},
      "guard": {"type": "string"},
      "max_iterations": {"type": "integer"},
      "command": {"type": "array", "items": {"type": "string"}}
    },
    "required": ["goal", "metric", "verify", "command"]
  }
}
```

## Example: Optimize Compile Time

```bash
b00t --loop="goal:reduce compile time|metric:ms|verify:time just cbm|max:20|direction:lower" \
     "just lint && just cbm"
```

## Example: Improve Test Coverage

```bash
b00t --loop="goal:90% coverage|metric:%|verify:pytest --cov|max:50|direction:higher" \
     "autoresearch:fix"
```

## Relationship to autoresearch-b00t-ledgrrr

The `autoresearch-b00t-ledgrrr` repo provides the AGENTS.md skill definitions for Claude Code/Codex. This spec provides the RUNTIME ENGINE that executes those skills generically across ANY b00t command, not just AI-agent tasks.

<!-- b00t:map v1
summary: k0mmand3r loop syntax — generic autoresearch loop runner for any b00t command
tags: k0mmand3r, loop, autoresearch, b00t-cli, mcp
tier: frontier
cmds: b00t --loop="..." <cmd>, /loop start <spec>
complexity: 8
-->
