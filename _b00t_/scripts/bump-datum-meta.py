#!/usr/bin/env python3
"""
bump-datum-meta.py — Auto-research git metadata bumper for b00t datums.

Usage:
    python3 bump-datum-meta.py <datum.md> [source_artifact_url]

Behavior:
1. Reads frontmatter from datum.md
2. Bumps datum_version (semver patch+)
3. Updates research_date to now (UTC)
4. Appends source artifact to embedded artifacts log
5. Git-adds the datum with experiment: prefix

🤓 tribal: run after extending any datum with autoresearch.
"""

import argparse
import datetime
import json
import os
import re
import subprocess
import sys


def parse_frontmatter(text: str) -> tuple:
    """Extract frontmatter table from markdown. Returns (dict, body)."""
    lines = text.splitlines()
    fm = {}
    body_start = 0
    in_table = False
    for i, line in enumerate(lines):
        if line.startswith("| ") and "|" in line[2:]:
            in_table = True
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 3 and parts[1] and parts[1] != "Field":
                key = parts[1].lower().replace(" ", "_")
                val = parts[2]
                fm[key] = val
        elif in_table and not line.startswith("|"):
            body_start = i
            break
    if body_start == 0:
        body_start = len(lines)
    return fm, "\n".join(lines[body_start:])


def bump_version(v: str) -> str:
    """Bump patch version."""
    parts = v.split(".")
    if len(parts) == 3 and all(p.isdigit() for p in parts):
        parts[2] = str(int(parts[2]) + 1)
        return ".".join(parts)
    return v + "+bumped"


def update_frontmatter(text: str, new_fm: dict) -> str:
    """Replace frontmatter values in text."""
    for key, val in new_fm.items():
        pattern = rf"^(\| \s*{re.escape(key)}\s*\| )([^|]+)(\|)"
        text = re.sub(pattern, rf"\g<1>{val}\g<3>", text, flags=re.IGNORECASE | re.MULTILINE)
    return text


def append_artifact(text: str, url: str, artifact_type: str = "url") -> str:
    """Append source artifact to embedded JSONL block if present, else create one."""
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    entry = json.dumps({"ts": ts, "artifact": url, "type": artifact_type}, separators=(",", ":"))

    # Look for existing ```jsonl block
    pattern = r"(```jsonl\n)(.*?)(```)"
    match = re.search(pattern, text, re.DOTALL)
    if match:
        existing = match.group(2)
        new_block = existing.rstrip() + "\n" + entry + "\n"
        text = text[:match.start()] + "```jsonl\n" + new_block + "```" + text[match.end():]
    else:
        # Append before tail-map
        tail_pattern = r"(<!-- b00t:map v1)"
        tail_match = re.search(tail_pattern, text)
        if tail_match:
            insert_pos = tail_match.start()
            block = f"\n## Source Artifacts Log\n\n```jsonl\n{entry}\n```\n\n"
            text = text[:insert_pos] + block + text[insert_pos:]
        else:
            text += f"\n## Source Artifacts Log\n\n```jsonl\n{entry}\n```\n"
    return text


def git_commit(path: str, msg: str):
    """Git-add and commit with experiment: prefix."""
    repo = os.path.dirname(os.path.dirname(path))  # assume _b00t_/datums/file.md
    subprocess.run(["git", "add", path], cwd=repo, check=True)
    subprocess.run(["git", "commit", "-m", f"experiment: {msg}"], cwd=repo, check=True)


def main():
    parser = argparse.ArgumentParser(description="Bump datum metadata after auto-research")
    parser.add_argument("datum", help="Path to datum .md file")
    parser.add_argument("artifact", nargs="?", help="Source artifact URL or path")
    parser.add_argument("--no-commit", action="store_true", help="Skip git commit")
    args = parser.parse_args()

    with open(args.datum, "r") as f:
        text = f.read()

    fm, body = parse_frontmatter(text)
    old_version = fm.get("datum_version", "0.0.0")
    new_version = bump_version(old_version)
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    updates = {
        "datum_version": new_version,
        "research_date": now,
    }
    text = update_frontmatter(text, updates)

    if args.artifact:
        text = append_artifact(text, args.artifact)

    with open(args.datum, "w") as f:
        f.write(text)

    print(f"Bumped {args.datum}: {old_version} -> {new_version} @ {now}")

    if not args.no_commit:
        try:
            git_commit(args.datum, f"auto-research bump {os.path.basename(args.datum)} v{new_version}")
            print("Git committed with experiment: prefix.")
        except subprocess.CalledProcessError as e:
            print(f"Git commit failed: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
