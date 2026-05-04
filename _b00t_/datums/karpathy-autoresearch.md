# karpathy/autoresearch — Autonomous Goal-Directed Iteration

> ⚠️ Metadata (source_repo, commit, date, researcher) is derived by git lint.
> Do NOT inline mutable state in datum files — it rots immediately.

## Concept

Autonomous goal-directed iteration loop. One metric, constrained scope, fast verification, automatic rollback, git as memory. Works on ANY domain with a measurable scalar.

**Core loop:** Modify → Verify → Keep/Discard → Repeat.

### The Karpathy Loop Formula

```
AGENT + CONSTRAINED_SCOPE + SCALAR_METRIC + FAST_VERIFICATION = AUTONOMOUS_IMPROVEMENT
```

## Seven Universal Principles

1. **Constraint = Enabler** — limit scope to make progress tractable
2. **Strategy ≠ Tactics** — human defines what, agent figures out how
3. **Mechanical Metrics** — vocabulary-independent numbers (val_bpb, coverage %, LOC)
4. **Fast Verification** — seconds to minutes per iteration (faster = bolder exploration)
5. **Iteration Cost → Behavior** — cheap iterations enable aggressive experimentation
6. **Git as Memory** — every experiment committed; history is the dataset
7. **Honest Limitations** — explicit constraints; stop when wall is hit

## Claude Autoresearch Commands

| Command | Purpose |
|---------|---------|
| `autoresearch` | Main iteration loop |
| `autoresearch:plan` | Interactive wizard (goal → scope → metric → verify) |
| `autoresearch:debug` | Scientific bug-hunting |
| `autoresearch:fix` | Auto-detect and repair errors one at a time |
| `autoresearch:security` | STRIDE + OWASP + red-team audit |
| `autoresearch:ship` | Universal shipping workflow (8 phases, 9 types) |
| `autoresearch:scenario` | 12-dimension scenario exploration |
| `autoresearch:predict` | Multi-persona swarm (5 experts) |
| `autoresearch:learn` | Auto-documentation engine |
| `autoresearch:reason` | Adversarial refinement (blind judge panel) |
| `autoresearch:probe` | Requirement/assumption interrogation (8 personas) |

## b00t Integration

### Phase 1: Datum Auto-Research Hook
When `b00t grok digest` or `b00t learn` extends a datum:
1. Run `autoresearch:probe` on the datum's claims
2. Log source artifacts to `_b00t_/datums/<name>.artifacts.jsonl`
3. Git-commit the extended datum with `experiment:` prefix

### Phase 2: Self-Improving Corpus
```bash
b00t autoresearch --goal="Improve datum accuracy" \
  --scope="_b00t_/datums/*.md" \
  --metric="b00t grok ask <datum_topic> | relevance_score" \
  --verify="python3 _b00t_/scripts/verify_datum.py"
```

### Phase 3: Adversarial Loop (A/B/R)
- AgentA (researcher): extends datum with new sources
- AgentB (bouncer): verifies claims against source artifacts
- AgentR (reviewer): votes confidence <|VOTE:CC##|>

## Source Artifacts Log

```jsonl
{"ts":"2026-05-03T07:45:00Z","artifact":"AGENTS.md","url":"https://raw.githubusercontent.com/uditgoenka/autoresearch/master/AGENTS.md","lines":120}
{"ts":"2026-05-03T07:46:00Z","artifact":"COMPARISON.md","url":"https://raw.githubusercontent.com/uditgoenka/autoresearch/master/COMPARISON.md","lines":200}
{"ts":"2026-05-03T07:47:00Z","artifact":"claude-plugin/skills/","url":"https://github.com/uditgoenka/autoresearch/tree/master/claude-plugin","type":"directory"}
{"ts":"2026-05-03T08:00:38Z","artifact":"https://raw.githubusercontent.com/uditgoenka/autoresearch/master/AGENTS.md","type":"url"}
```

<!-- b00t:map v1
summary: karpathy/autoresearch — autonomous goal-directed iteration for any measurable domain
tags: autoresearch, karpathy, claude-code, iteration, self-improvement, datum
tier: frontier
cmds: b00t autoresearch --goal=... --scope=... --metric=..., b00t grok digest --topic=autoresearch
complexity: 8
-->
