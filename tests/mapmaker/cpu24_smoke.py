#!/usr/bin/env python3
"""Compile and execute the MapMaker core with the CPU24 C toolchain."""
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
EX716 = HERE.parents[1]
LCC = EX716.parent / "lcc"

def main():
    compiler = LCC / "build" / "rcc"
    preprocessor = LCC / "build" / "cpp"
    if not compiler.is_file() or not preprocessor.is_file():
        print("missing CPU24 compiler tools under " + str(LCC / "build"), file=sys.stderr)
        return 2
    preprocessed = subprocess.run([str(preprocessor), "-N", "-D__EX716__=1",
                                  "-I" + str(HERE), "cpu24_smoke.c"],
                                 cwd=HERE, text=True, capture_output=True)
    if preprocessed.returncode:
        sys.stderr.write(preprocessed.stderr)
        return preprocessed.returncode
    with tempfile.TemporaryDirectory(prefix="mapmaker-cpu24-") as temporary:
        source = pathlib.Path(temporary) / "cpu24_smoke.i"
        source.write_text(preprocessed.stdout, encoding="utf-8")
        compiled = subprocess.run([str(compiler), "-target=ex716", str(source)],
                                   cwd=LCC, text=True, capture_output=True)
    if compiled.returncode:
        sys.stderr.write(compiled.stderr)
        return compiled.returncode
    harness = "\n".join((".DATA 1", "I commonDS.mc", "@JMP __mapmaker_entry",
                         "L clocals.ld", "L lmath.ld", compiled.stdout,
                         ":__mapmaker_entry", ".ENTRY __mapmaker_entry",
                         "@PUSH 1", "@SSET SegDS", "@PUSH 1", "@ADM",
                         "@PRT \"MAPMAKER_CPU24_RESULT=\"", "@CALL main",
                         "@PRTTOP", "@POPNULL", "@PRTNL", "@PUSH 0", "@ADM",
                         "@END", ""))
    with tempfile.TemporaryDirectory(prefix="mapmaker-cpu24-") as temporary:
        asm = pathlib.Path(temporary) / "mapmaker.asm"
        asm.write_text(harness, encoding="utf-8")
        run = subprocess.run([sys.executable, str(EX716 / "cpu24.py"), str(asm)],
                             cwd=EX716, text=True, capture_output=True)
    sys.stdout.write(run.stdout)
    sys.stderr.write(run.stderr)
    if run.returncode or "Unresolved symbols: 0" not in run.stdout:
        return run.returncode or 1
    return 0 if "MAPMAKER_CPU24_RESULT=0" in run.stdout else 1

if __name__ == "__main__":
    raise SystemExit(main())
