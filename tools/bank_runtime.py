#!/usr/bin/env python3
"""Create bank-qualified copies of legacy CPU24 arithmetic helpers."""
from __future__ import annotations

import argparse
from pathlib import Path
import re


FUNCTION = re.compile(r"(?ms)^@FUNCTION\s+\w+\n.*?^@ENDFUNCTION\n")
LABEL = re.compile(r"(?m)^:(\w+)")


def qualify_block(block: str, prefix: str) -> str:
    names = {name for name in LABEL.findall(block)}
    function = re.search(r"(?m)^@FUNCTION\s+(\w+)", block)
    if function:
        names.add(function.group(1))
    names = {name: prefix + name for name in names}
    for old, new in sorted(names.items(), key=lambda item: -len(item[0])):
        block = re.sub(r"\b" + re.escape(old) + r"\b", new, block)
    block = re.sub(r"(?<!B2_)@PUSHRETURN\b", "@B2_PUSHRETURN", block)
    block = re.sub(r"(?<!B2_)@POPRETURN\b", "@B2_POPRETURN", block)
    block = re.sub(r"@LocalVar\b", "@B2_LocalVar", block)
    block = re.sub(r"@EndLocals\b", "@B2_EndLocals", block)
    block = re.sub(r"@Locals\b", "@B2_Locals", block)
    block = re.sub(r"@Local\b", "@B2_Local", block)
    block = re.sub(r"@RestoreVar\b", "@B2_RestoreVar", block)
    return block


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("sources", nargs="+", type=Path)
    args = parser.parse_args()
    blocks = []
    for source in args.sources:
        text = source.read_text(encoding="utf-8")
        blocks.extend(qualify_block(match.group(0), "B2_")
                      for match in FUNCTION.finditer(text))
    args.output.write_text("\n".join(blocks), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
