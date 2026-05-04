#!/usr/bin/env python3
"""
l3dg3rr-doc-proxy.py — Query l3dg3rr via MCP and emit .tomllm / rustdoc / json.

Usage:
    python3 l3dg3rr-doc-proxy.py --format=tomllm --project=home-brianh-... > docs.toml
    python3 l3dg3rr-doc-proxy.py --format=rustdoc --project=home-brianh-... > docs.md

🤓 tribal: this is a PROTOTYPE. Production version should be an MCP tool
registered in b00t-mcp, not a standalone script.
"""

import argparse
import json
import subprocess
import sys


def mcp_call(tool: str, params: dict) -> dict:
    """Call codebase-memory-mcp CLI tool and parse JSON."""
    cmd = ["/home/brianh/.b00t/vendor/codebase-memory-mcp-b00t-ir0n-ledg3rr/build/c/codebase-memory-mcp", "cli", tool, json.dumps(params)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    # Strip log lines before JSON
    lines = result.stdout.strip().splitlines()
    for line in reversed(lines):
        line = line.strip()
        if line.startswith("{") or line.startswith("["):
            return json.loads(line)
    return {}


def emit_tomllm(functions: list) -> str:
    out = []
    out.append("# l3dg3rr docgen export — .tomllm format")
    out.append("")
    for f in functions:
        out.append(f"[[{f['qualified_name']}]]")
        out.append(f"name = {json.dumps(f['name'])}")
        out.append(f"file_path = {json.dumps(f['file_path'])}")
        out.append(f"signature = {json.dumps(f.get('signature', ''))}")
        out.append(f"return_type = {json.dumps(f.get('return_type', ''))}")
        out.append(f"complexity = {f.get('complexity', 0)}")
        out.append(f"lines = {f.get('lines', 0)}")
        doc = f.get('docstring', '') or ''
        if doc:
            out.append(f"# @tribal: {doc.replace(chr(10), ' ')}")
        out.append("")
    out.append("# b00t:map v1")
    out.append("# summary: l3dg3rr function documentation export")
    out.append("# tags: l3dg3rr, docgen, auto-export")
    out.append("# tier: sm0l")
    out.append("# cmds: python3 l3dg3rr-doc-proxy.py --format=tomllm")
    out.append("# complexity: 3")
    return "\n".join(out)


def emit_rustdoc(functions: list) -> str:
    out = []
    out.append("// l3dg3rr docgen export — rustdoc style")
    out.append("")
    for f in functions:
        out.append(f"/// `{f.get('signature', f['name'] + '()')}`")
        doc = f.get('docstring', '') or 'No documentation available.'
        for line in doc.splitlines():
            out.append(f"/// {line}")
        out.append(f"///")
        out.append(f"/// # Examples")
        out.append(f"/// ```no_run")
        out.append(f"/// // TODO: add usage example for {f['name']}")
        out.append(f"/// ```")
        out.append(f"/// # Safety")
        out.append(f"/// Review source at {f['file_path']}:{f.get('start_line', 0)}")
        out.append(f"fn {f['name']}(...); // stub")
        out.append("")
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description="l3dg3rr doc proxy")
    parser.add_argument("--project", default="home-brianh-.b00t-vendor-codebase-memory-mcp-b00t-ir0n-ledg3rr")
    parser.add_argument("--format", choices=["tomllm", "rustdoc", "json"], default="tomllm")
    parser.add_argument("--limit", type=int, default=10)
    args = parser.parse_args()

    # Query graph for exported functions
    result = mcp_call("search_graph", {
        "project": args.project,
        "query": "http server UI documentation",
        "limit": args.limit
    })

    functions = result.get("results", [])
    if args.format == "json":
        print(json.dumps(functions, indent=2))
    elif args.format == "tomllm":
        print(emit_tomllm(functions))
    elif args.format == "rustdoc":
        print(emit_rustdoc(functions))


if __name__ == "__main__":
    main()
