#!/usr/bin/env python3
"""Small deterministic secret guard for committed repository text."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {".git", ".dart_tool", "build", "coverage"}
TEXT_SUFFIXES = {
    ".dart",
    ".md",
    ".yaml",
    ".yml",
    ".json",
    ".xml",
    ".gradle",
    ".kts",
    ".py",
    ".txt",
    ".example",
    ".gitignore",
    ".gitattributes",
    ".editorconfig",
}
PATTERNS = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "GitHub token": re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{30,}\b"),
    "GitHub fine-grained token": re.compile(r"\bgithub_pat_[A-Za-z0-9_]{40,}\b"),
    "AWS access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "Google API key": re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b"),
}


def candidate_files() -> list[Path]:
    files: list[Path] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.suffix.lower() in TEXT_SUFFIXES or path.name.startswith("."):
            files.append(path)
    return sorted(files)


def main() -> int:
    findings: list[str] = []
    for path in candidate_files():
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for label, pattern in PATTERNS.items():
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                findings.append(f"{path.relative_to(ROOT)}:{line}: possible {label}")

    if findings:
        print("Potential committed secrets detected:")
        for finding in findings:
            print(f"- {finding}")
        return 1

    print(f"Checked {len(candidate_files())} text files: no known secret pattern found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
