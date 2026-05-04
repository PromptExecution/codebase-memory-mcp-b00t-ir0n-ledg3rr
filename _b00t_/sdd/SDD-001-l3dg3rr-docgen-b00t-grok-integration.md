# SDD-001 — l3dg3rr Docgen → b00t grok Integration

| Field | Value |
|-------|-------|
| Status | draft |
| Tier | frontier |
| Complexity | 7 |

## Problem

l3dg3rr (`codebase-memory-mcp`) embeds an interactive documentation generator:
- HTTP server (`src/ui/http_server.c`) on port 9749
- React/Three.js graph UI (`graph-ui/`)
- Endpoints: `/browse`, `/layout`, `/adr`, `/logs`, `/processes`, `/rpc`

This docgen is **not yet connected** to b00t grok. We need:
1. Extract structured docs from the knowledge graph in `.tomllm` format
2. Emit rustdoc-style markup for Rust-relevant subgraphs
3. Proxy the UI through b00t-mcp so Hermes agents can render it
4. Feed outputs into future unsloth fine-tuning corpora

## Interface Specification

### Input
- `project` (string) — indexed project name from l3dg3rr
- `format` (enum: `tomllm`, `rustdoc`, `json`) — output dialect
- `scope` (enum: `architecture`, `module`, `function`, `adr`) — graph slice

### Output
- `.tomllm`: valid TOML + `# @tribal:` / `# b00t:map v1` tail block
- `rustdoc`: Markdown with `///` headers + `# Examples` sections
- `json`: raw graph nodes/edges for pipeline consumption

## Stage Gates

| Gate | Criteria | Test |
|------|----------|------|
| G1 | Index l3dg3rr itself via MCP | `index_repository` returns nodes>0 |
| G2 | Query architecture and emit .tomllm | Parser validates output, tail-map present |
| G3 | Query function docs and emit rustdoc | Contains `///` + `# Examples` + `# Safety` |
| G4 | b00t-mcp proxy exposes doc endpoint | `b00t grok ask "show l3dg3rr docs"` returns summary |
| G5 | unsloth corpus export | JSONL with `instruction` / `input` / `output` keys |

## Integration Points

### l3dg3rr → b00t-mcp proxy
```
l3dg3rr MCP server (stdio)
  ├── get_architecture → b00t-mcp assimilate → RAG index
  ├── search_graph → b00t grok ask → natural-language answer
  └── manage_adr → b00t task add → SDD backlog
```

### docgen → .tomllm converter
```python
# Pseudocode — actual impl in Rust or Python
for node in query_graph("MATCH (f:Function) RETURN f"):
    print(f"[[{node.qname}]]")
    print(f"# @tribal: complexity={node.complexity}")
    print(f"signature = {json.dumps(node.signature)}")
    print(f"docstring = {json.dumps(node.docstring)}")
    print("")
# emit tail-map
```

## Tauri/WSL Display Layer

- **Feasibility**: YES with caveats
- Node has X11 forwarding active (`DISPLAY=localhost:10.0`)
- Missing dependency: `libwebkit2gtk-4.1-dev` (required for Tauri v2)
- Install: `sudo apt install libwebkit2gtk-4.1-dev libgtk-3-dev`
- Tauri app can wrap the existing `graph-ui` build output
- WSL host receives UI via SSH X11 forwarding

## unsloth Fine-Tuning Hook

Export corpus from ADR + docstring + signature triples:
```jsonl
{"instruction":"Explain cbm_http_server_new","input":"port: int","output":"Creates a new HTTP server on localhost:port..."}
```

## Fallback Chain

1. If Tauri deps missing → serve via existing embedded HTTP server
2. If b00t-mcp proxy fails → query MCP directly via `codebase-memory-mcp cli`
3. If .tomllm parser rejects output → fall back to plain TOML

## Termination

- DONE: all 5 gates pass
- FAIL: G1 or G2 fail after 3 retries
- ESCALATE: Tauri build fails due to missing system libs on WSL

<!-- b00t:map v1
summary: SDD for connecting l3dg3rr docgen to b00t grok (.tomllm, rustdoc, unsloth)
tags: l3dg3rr, docgen, b00t-grok, tomllm, rustdoc, tauri, unsloth, mcp-proxy
tier: frontier
cmds: b00t grok assimilate -t docgen, b00t task next
complexity: 7
-->
