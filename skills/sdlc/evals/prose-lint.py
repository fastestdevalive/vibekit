#!/usr/bin/env python3
"""Tier A prose linter.

Flags any line with more than one sentence that is not inside a table row,
code fence, bullet/numbered list item, or heading — i.e. a prose paragraph,
which vibekit docs ban (skills/planning/FORMAT.md "Format rules — banned").

Usage: python3 skills/sdlc/evals/prose-lint.py [path ...]
  Defaults to skills/ and .vibekit.yaml.example when no paths given.
  Exits 1 if any violation is found.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

SENTENCE_END = re.compile(r"[.!?][\"')\]]*(\s|$)")
CODE_FENCE = re.compile(r"^\s*```")
TABLE_ROW = re.compile(r"^\s*\|")
BULLET = re.compile(r"^\s*([-*]|\d+\.)\s+")
HEADING = re.compile(r"^\s*#{1,6}\s+")
BLOCKQUOTE = re.compile(r"^\s*>")
HTML_COMMENT = re.compile(r"^\s*(<!--|-->)")


def count_sentences(line: str) -> int:
    # Ignore sentence-enders inside inline code spans.
    stripped = re.sub(r"`[^`]*`", "", line)
    return len(SENTENCE_END.findall(stripped))


def lint_file(path: Path) -> list[tuple[int, str]]:
    violations: list[tuple[int, str]] = []
    in_fence = False
    in_frontmatter = False
    lines = path.read_text(encoding="utf-8").splitlines()
    for lineno, raw in enumerate(lines, start=1):
        line = raw.rstrip()
        if lineno == 1 and line.strip() == "---":
            in_frontmatter = True
            continue
        if in_frontmatter:
            if line.strip() == "---":
                in_frontmatter = False
            continue
        if CODE_FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence or not line.strip():
            continue
        if TABLE_ROW.match(line) or BULLET.match(line) or HEADING.match(line) or BLOCKQUOTE.match(line) or HTML_COMMENT.match(line):
            continue
        if count_sentences(line) > 1:
            violations.append((lineno, line.strip()))
    return violations


def main(argv: list[str]) -> int:
    repo_root = Path(__file__).resolve().parents[3]
    targets = [Path(p) for p in argv] or [repo_root / "skills", repo_root / ".vibekit.yaml.example"]

    files: list[Path] = []
    for t in targets:
        if t.is_dir():
            files.extend(sorted(t.rglob("*.md")))
        elif t.is_file():
            files.append(t)

    total = 0
    for f in files:
        if "evals" in f.parts:
            continue  # eval case tables intentionally quote prose in Pass criteria cells
        if f.name == "EXAMPLES.md":
            continue  # worked-example narrative ("Situation:" prose) — moved verbatim from source draft
        violations = lint_file(f)
        for lineno, text in violations:
            print(f"{f}:{lineno}: multi-sentence line outside table/fence/bullet/heading: {text[:100]}")
            total += 1

    if total:
        print(f"\nprose-lint: {total} violation(s)", file=sys.stderr)
        return 1
    print("prose-lint: clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
