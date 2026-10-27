#!/usr/bin/env python3
"""Prototype a C-callable stub into one compiler-generated far-bank function."""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
EX716 = HERE.parents[1]
LCC = EX716.parent / "lcc"
RESULT = re.compile(r"(?m)^FARBANK_RESULT=(-?\d+)\s*$")


def compile_c(source, work):
    preprocessed = subprocess.run(
        [str(LCC / "build/cpp"), "-N", "-D__EX716__=1",
         "-I" + str(HERE), "-I" + str(LCC / "include/ex716"), str(source)],
        cwd=work, text=True, capture_output=True)
    if preprocessed.returncode:
        raise RuntimeError(preprocessed.stderr)
    unit = work / (source.stem + ".i")
    unit.write_text(preprocessed.stdout, encoding="utf-8")
    compiled = subprocess.run(
        [str(LCC / "build/rcc"), "-target=ex716", str(unit)],
        cwd=LCC, text=True, capture_output=True)
    if compiled.returncode or "EX716: unhandled" in compiled.stderr:
        raise RuntimeError(compiled.stderr)
    return compiled.stdout


def main():
    with tempfile.TemporaryDirectory(prefix="mapmaker-farbank-") as directory:
        work = Path(directory)
        unit = compile_c(HERE / "farbank_smoke.c", work)
        match = re.search(
            r"(?ms)^G far_target_impl\s+@FUNCTION far_target_impl\n.*?^@ENDFUNCTION\n",
            unit)
        if not match:
            raise RuntimeError("could not locate compiler-generated far_target_impl")
        implementation = match.group(0)
        caller = unit[:match.start()] + unit[match.end():]
        assembly = "\n".join((
            ".DATA 1", "I commonDS.mc", "@JMP __farbank_entry",
            "L clocals.ld", "L lmath.ld", "L farptr.ld", ".CODE 0", caller,
            "@FUNCTION far_target", ":far_target", "@PUSHRETURN",
            "@FCALL 1 FarTarget", "@POPRETURN", "@RET", "@ENDFUNCTION",
            ".CODE 1", implementation, "@FUNCTION(F) FarTarget",
            "@CALL far_target_impl", "@SWP @RET", "@ENDFUNCTION",
            ".CODE 0", ":__farbank_entry", ".ENTRY __farbank_entry",
            "@PUSH 1", "@SSET SegDS", "@PUSH 1", "@ADM",
            '@PRT "FARBANK_RESULT="', "@CALL main", "@PRTTOP", "@POPNULL",
            "@PRTNL", "@PUSH 0", "@ADM", "@END", ""))
        source = work / "farbank.asm"
        source.write_text(assembly, encoding="utf-8")
        environment = dict(os.environ)
        environment["CPUPATH"] = str(EX716 / "lib")
        executed = subprocess.run(
            [sys.executable, str(EX716 / "cpu24.py"), str(source)],
            cwd=EX716, env=environment, text=True, capture_output=True)
        sys.stdout.write(executed.stdout)
        sys.stderr.write(executed.stderr)
        if executed.returncode or RESULT.findall(executed.stdout) != ["0"]:
            Path("/tmp/mapmaker-farbank-failed.asm").write_text(
                assembly, encoding="utf-8")
            print("saved /tmp/mapmaker-farbank-failed.asm", file=sys.stderr)
        if executed.returncode or "Unresolved symbols: 0" not in executed.stdout:
            return executed.returncode or 1
        return 0 if RESULT.findall(executed.stdout) == ["0"] else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print("FAIL: " + str(error), file=sys.stderr)
        raise SystemExit(1)
