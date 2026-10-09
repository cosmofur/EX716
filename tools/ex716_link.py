#!/usr/bin/env python3
"""Validate and combine EX716 C assembly units for one assembler pass."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


GLOBAL_RE = re.compile(r"(?m)^G\s+(\S+)(?:\s+.*)?$")
FUNCTION_RE = re.compile(r"(?m)^@FUNCTION\s+(\S+)")
CODE_LABEL_RE = re.compile(r"(?m)^:(?!:)(\S+)")
DATA_LABEL_RE = re.compile(r"(?m)^::(\S+)")


def unit_symbols(source: str) -> tuple[set[str], set[str]]:
    """Return globally declared names and actual symbol definitions."""
    declared = set(GLOBAL_RE.findall(source))
    functions = set(FUNCTION_RE.findall(source))
    labels = {name for name in CODE_LABEL_RE.findall(source)
              if name != "__" and name not in functions}
    data = {name for name in DATA_LABEL_RE.findall(source) if name != "__"}
    return declared, functions | labels | data


def combine(sources: list[tuple[str, str]]) -> tuple[str, str]:
    """Validate public and private definitions, then combine unit text."""
    definitions: dict[str, tuple[bool, str]] = {}
    exports: set[str] = set()
    declarations: set[str] = set()

    for filename, source in sources:
        declared, defined = unit_symbols(source)
        declarations.update(declared)
        for name in defined:
            public = name in declared
            previous = definitions.get(name)
            if previous:
                previous_public, previous_file = previous
                if public or previous_public:
                    raise ValueError(
                        f"duplicate external definition {name!r} "
                        f"(in {previous_file} and {filename})"
                    )
                raise ValueError(
                    f"duplicate private assembly label {name!r} "
                    f"(in {previous_file} and {filename}); unit identities collide"
                )
            definitions[name] = (public, filename)
            if public:
                exports.add(name)

    # G declarations are set-like. Emit them before references so every
    # assembler pass sees external names before it resolves local labels.
    body = []
    for _, source in sources:
        body.extend(line for line in source.splitlines()
                    if not GLOBAL_RE.match(line))
    combined = "".join(f"G {name}\n" for name in sorted(declarations))
    combined += "\n".join(body).rstrip() + "\n"

    report = "# EX716 defined C-unit exports; G lines declare names only\n"
    report += "".join(f"G {name}\n" for name in sorted(exports))
    return combined, report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-o", "--output", type=Path, required=True,
                        help="combined assembly output")
    parser.add_argument("--symbols-output", type=Path,
                        help="optional G-declaration report of defined exports")
    parser.add_argument("units", nargs="+", type=Path,
                        help="compiler-generated EX716 assembly units")
    args = parser.parse_args()

    try:
        inputs = [(str(path), path.read_text(encoding="utf-8"))
                  for path in args.units]
        combined, report = combine(inputs)
        args.output.write_text(combined, encoding="utf-8")
        if args.symbols_output:
            args.symbols_output.write_text(report, encoding="utf-8")
    except (OSError, ValueError) as exc:
        print(f"ex716-link: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
