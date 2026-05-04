# karpathy/autoimprove — Self-Improving Datum Pattern

## Concept

Andrej Karpathy's autoimprove idea: a system that reads its own source,
identifies weaknesses, generates patches, and validates them.

In b00t, this maps to:
1. **Index** the datum repo with l3dg3rr
2. **Query** for gaps (missing examples, stale commands, low complexity scores)
3. **Generate** patches via adversarial A/B loop
4. **Validate** with `b00t grok ask` — if answer quality < threshold, retry

## Implementation Sketch

```bash
# 1) Index datums
b00t("index_repository", {repo_path: "_b00t_/datums", mode: "fast"})

# 2) Find datums without examples
b00t("query_graph", {
  project: "datums",
  query: 'MATCH (f:File) WHERE f.content CONTAINS "@example:" RETURN f.name'
})

# 3) Generate missing examples via frontier agent
/k0mmand3r dispatch <agent> --role=researcher --task="add @example: to datum X"

# 4) Bouncer verifies
/k0mmand3r dispatch <agent> --role=bouncer --verify-from="datum X"

# 5) Assimilate if accepted
b00t grok digest --topic=datum "<patched content>"
```

## b00t-mcp Integration

Expose as tools:
- `autoimprove_scan` — find gaps in datum corpus
- `autoimprove_patch` — generate patch for a datum
- `autoimprove_vote` — bouncer/reviewer vote on patch quality

## Output Contract

- `PASS: N datums scanned, M patches generated, K accepted`
- `FAIL: <datum> <reason> | confidence: CC## | retry: Y/N`

<!-- b00t:map v1
summary: karpathy/autoimprove pattern for self-improving b00t datums
tags: autoimprove, karpathy, datums, self-healing, a-b-loop
tier: frontier
cmds: b00t grok assimilate -t autoimprove, b00t task next
complexity: 8
-->
