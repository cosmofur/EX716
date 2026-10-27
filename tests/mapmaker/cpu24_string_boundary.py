#!/usr/bin/env python3
"""Regression: string byte reads may legally address data offset 0xffff."""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


HERE = Path(__file__).resolve().parent
EX716 = HERE.parents[1]
RESULT = re.compile(r"(?m)^STRING_BOUNDARY_RESULT=(-?\d+)\s*$")


def main():
    # 0xffc0 + 63 is 0xffff: the test deliberately puts the terminating byte
    # at the final address of DS.  Do not replace this with an ordinary string.
    # `strlen` uses PUSHB for these reads; this small harness isolates the
    # final read without loading the soft-stack metadata at 0xfff0.
    delimiter = "x" * 63
    assembly = "\n".join((
        ".DATA 1", "I commonDS.mc", "@JMP __boundary_entry",
        ":__boundary_entry", ".ENTRY __boundary_entry",
        "@PUSH 1", "@SSET SegDS", "@PUSH 0xffff", "@PUSHB",
        '@PRT "STRING_BOUNDARY_RESULT="', "@PRTTOP", "@POPNULL", "@PRTNL",
        "@PUSH 0", "@ADM", "@END",
        ".ORG 0xffc0", ':BoundaryDelimiter "' + delimiter + '\\0"', "",
    ))
    with tempfile.TemporaryDirectory(prefix="cpu24-string-boundary-") as directory:
        source = Path(directory) / "boundary.asm"
        source.write_text(assembly, encoding="utf-8")
        environment = dict(os.environ)
        environment["CPUPATH"] = str(EX716 / "lib")
        run = subprocess.run([sys.executable, str(EX716 / "cpu24.py"), str(source)],
                             cwd=EX716, env=environment, text=True,
                             capture_output=True)
    sys.stdout.write(run.stdout)
    sys.stderr.write(run.stderr)
    return 0 if run.returncode == 0 and RESULT.findall(run.stdout) == ["0"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
