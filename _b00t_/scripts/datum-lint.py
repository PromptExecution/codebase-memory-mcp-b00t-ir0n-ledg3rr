#!/usr/bin/env python3
"""
datum-lint.py — Enforce "no mutable metadata in datum files."

Rules:
  FAIL: any datum .md containing inline mutable metadata tables
        (source_commit, research_date, datum_version, status, tier, complexity)
  PASS: metadata derived from git (author, commit date, tags)

Usage:
  python3 datum-lint.py <datum_dir>
  python3 datum-lint.py --git-survey <datum_dir>  # derive metadata from git

🤓 tribal: datum files contain ONLY conceptual content. Metadata is lint.
"""

import argparse
import os
import re
import subprocess
import sys

FORBIDDEN_KEYS = {
    "source_commit", "research_date", "datum_version", "status",
    "tier", "complexity", "researcher", "source_date",
}


def lint_file(path: str) -> list:
    issues = []
    with open(path) as f:
        text = f.read()
    # Find table rows with forbidden keys
    for line in text.splitlines():
        m = re.match(r"^\|\s*(\w+)\s*\|", line)
        if m and m.group(1) in FORBIDDEN_KEYS:
            issues.append(f"{path}: forbidden inline key '{m.group(1)}'")
    return issues


def git_survey_file(path: str) -> dict:
    """Derive metadata from git for a single file."""
    repo = os.path.dirname(os.path.dirname(path))
    rel = os.path.relpath(path, repo)
    meta = {}
    # last commit touching this file
    out = subprocess.run(
        ["git", "log", "-1", "--format=%H|%aN|%aE|%ai|%s", "--", rel],
        cwd=repo, capture_output=True, text=True,
    )
    if out.returncode == 0 and out.stdout.strip():
        parts = out.stdout.strip().split("|", 4)
        meta["commit"] = parts[0]
        meta["author"] = parts[1]
        meta["email"] = parts[2]
        meta["date"] = parts[3]
        meta["subject"] = parts[4]
    # count commits
    out = subprocess.run(
        ["git", "rev-list", "--count", "HEAD", "--", rel],
        cwd=repo, capture_output=True, text=True,
    )
    if out.returncode == 0:
        meta["version"] = f"0.0.{out.stdout.strip()}"
    # tags pointing at HEAD
    out = subprocess.run(
        ["git", "tag", "--points-at", "HEAD"],
        cwd=repo, capture_output=True, text=True,
    )
    if out.returncode == 0 and out.stdout.strip():
        meta["tags"] = out.stdout.strip().splitlines()
    return meta


def main():
    parser = argparse.ArgumentParser(description="datum linter")
    parser.add_argument("dir", help="Directory containing datum .md files")
    parser.add_argument("--git-survey", action="store_true", help="Derive metadata from git")
    args = parser.parse_args()

    all_issues = []
    for root, _, files in os.walk(args.dir):
        for f in files:
            if not f.endswith(".md"):
                continue
            path = os.path.join(root, f)
            issues = lint_file(path)
            all_issues.extend(issues)
            if args.git_survey:
                meta = git_survey_file(path)
                print(f"--- {os.path.relpath(path, args.dir)} ---")
                for k, v in meta.items():
                    print(f"  {k}: {v}")

    if all_issues:
        print(f"\n❌ {len(all_issues)} issue(s) found:", file=sys.stderr)
        for i in all_issues:
            print(f"  {i}", file=sys.stderr)
        sys.exit(1)
    else:
        print("✅ No inline mutable metadata found.")
        sys.exit(0)


if __name__ == "__main__":
    main()
