#!/usr/bin/env python3
"""Compile and execute the explicit CPU24 far-data ABI regression."""
from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
LCC = ROOT.parent / "lcc"
SOURCE = ROOT / "tests/csuite/cases/memory/farptr_manual.c"
RESULT = re.compile(r"(?m)^EX716_FARPTR_RESULT=(-?\d+)\s*$")


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="ex716-farptr-") as temporary:
        work = Path(temporary)
        preprocessed = subprocess.run(
            [str(LCC / "build/cpp"), "-N", "-D__EX716__=1",
             "-I" + str(LCC / "include/ex716"), str(SOURCE)],
            text=True, capture_output=True, check=False)
        if preprocessed.returncode:
            sys.stderr.write(preprocessed.stderr)
            return 1
        unit = work / "farptr_manual.i"
        unit.write_text(preprocessed.stdout, encoding="utf-8")
        compiled = subprocess.run(
            [str(LCC / "build/rcc"), "-target=ex716", str(unit)],
            cwd=LCC, text=True, capture_output=True, check=False)
        if compiled.returncode:
            sys.stderr.write(compiled.stderr)
            return 1
        harness = "\n".join((
            ".DATA 1", "I commonDS.mc", "@JMP __farptr_entry",
            "L clocals.ld", "L lmath.ld", "L farptr.ld", compiled.stdout,
            ":__farptr_entry", ".ENTRY __farptr_entry", "@PUSH 1",
            "@SSET SegDS", "@PUSH 1", "@ADM",
            '@PRT "EX716_FARPTR_RESULT="', "@CALL main", "@PRTTOP",
            "@POPNULL", "@PRTNL", "@PUSH 0", "@ADM", "@END", ""))
        asm = work / "farptr_manual.asm"
        asm.write_text(harness, encoding="utf-8")
        environment = dict(os.environ)
        environment["CPUPATH"] = str(ROOT / "lib") + os.pathsep + str(work)
        executed = subprocess.run(
            [sys.executable, str(ROOT / "cpu24.py"), str(asm)], cwd=ROOT,
            env=environment, text=True, capture_output=True, check=False)
    sys.stdout.write(executed.stdout)
    sys.stderr.write(executed.stderr)
    return 0 if executed.returncode == 0 and RESULT.findall(executed.stdout) == ["0"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
