#!/usr/bin/env python3
"""Compile and execute the EX716 C regression suite with the CPU24 loader."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_COMPILER = ROOT.parent / "lcc" / "build" / "rcc"
RESULT_RE = re.compile(r"(?m)^EX716_TEST_RESULT=(-?\d+)\s*$")


def run_case(source: Path, compiler: Path, timeout: float) -> tuple[bool, str]:
    compile_result = subprocess.run(
        [str(compiler), "-target=ex716", str(source)],
        cwd=compiler.parent.parent,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )
    if compile_result.returncode != 0:
        return False, "compiler failed:\n" + compile_result.stderr[-4000:]

    harness = "\n".join(
        [
            "I common.mc",
            "@JMP Main",
            "L clocals.ld",
            "L lmath.ld",
            compile_result.stdout,
            ":Main",
            '@PRT "EX716_TEST_RESULT="',
            "@CALL main",
            "@PRTTOP",
            "@POPNULL",
            "@PRTNL",
            "@END",
            "",
        ]
    )

    with tempfile.TemporaryDirectory(prefix="ex716-csuite-") as temp_dir:
        asm_path = Path(temp_dir) / f"{source.stem}.asm"
        asm_path.write_text(harness, encoding="utf-8")
        cpu_result = subprocess.run(
            [sys.executable, str(ROOT / "cpu24.py"), str(asm_path)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )

    if cpu_result.returncode != 0:
        return False, "CPU24 failed:\n" + cpu_result.stdout[-3000:] + cpu_result.stderr[-3000:]
    if "Unresolved symbols: 0" not in cpu_result.stdout:
        return False, "assembler reported unresolved symbols:\n" + cpu_result.stdout[-3000:]

    matches = RESULT_RE.findall(cpu_result.stdout)
    if len(matches) != 1:
        return False, "could not find one test result marker:\n" + cpu_result.stdout[-3000:]
    result = int(matches[0])
    if result != 0:
        return False, f"C main returned {result} (expected 0)"
    return True, ""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--compiler", type=Path, default=DEFAULT_COMPILER,
        help=f"lcc executable (default: {DEFAULT_COMPILER})",
    )
    parser.add_argument("--filter", help="run only paths containing this text")
    parser.add_argument("--timeout", type=float, default=30.0)
    args = parser.parse_args()

    compiler = args.compiler.resolve()
    if not compiler.is_file():
        parser.error(f"compiler not found: {compiler}")

    cases = sorted((ROOT / "tests" / "csuite" / "cases").rglob("*.c"))
    if args.filter:
        cases = [case for case in cases if args.filter in str(case.relative_to(ROOT))]
    if not cases:
        parser.error("no C test cases selected")

    failures = 0
    for case in cases:
        ok, detail = run_case(case, compiler, args.timeout)
        label = "PASS" if ok else "FAIL"
        print(f"{label} {case.relative_to(ROOT)}")
        if not ok:
            failures += 1
            print(detail)

    print(f"\n{len(cases) - failures}/{len(cases)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
