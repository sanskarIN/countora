#!/usr/bin/env python3
"""Fail when a repository-local Markdown link points to a missing path."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SKIPPED_SCHEMES = ("http://", "https://", "mailto:", "tel:", "data:")


def markdown_files() -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob("*.md")
        if ".git" not in path.parts and "build" not in path.parts
    )


def normalized_target(raw: str) -> str:
    target = raw.strip().split(maxsplit=1)[0].strip("<>")
    return unquote(target.split("#", maxsplit=1)[0])


def main() -> int:
    failures: list[str] = []
    for document in markdown_files():
        text = document.read_text(encoding="utf-8")
        for match in LINK.finditer(text):
            raw = match.group(1)
            target = normalized_target(raw)
            if not target or target.startswith("#") or target.startswith(SKIPPED_SCHEMES):
                continue
            if target.startswith("/"):
                candidate = ROOT / target.lstrip("/")
            else:
                candidate = document.parent / target
            if not candidate.exists():
                line = text.count("\n", 0, match.start()) + 1
                failures.append(
                    f"{document.relative_to(ROOT)}:{line}: missing local link {raw!r}"
                )

    if failures:
        print("Markdown link check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"Checked {len(markdown_files())} Markdown files: local links are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
