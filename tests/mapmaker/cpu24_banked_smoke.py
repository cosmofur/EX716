#!/usr/bin/env python3
"""Run banked C smoke tests; --mapsmooth reproduces the known failing path."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
EX716 = HERE.parents[1]
LCC = EX716.parent / "lcc"
RESULT = re.compile(r"(?m)^BANKED_RESULT=(-?\d+)\s*$")


def compile_c(source, work, defines=()):
    result = subprocess.run(
        [str(LCC / "build/cpp"), "-N", "-D__EX716__=1",
         *defines,
         "-I" + str(HERE), "-I" + str(LCC / "include/ex716"), str(source)],
        cwd=work, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    intermediate = work / (source.stem + ".i")
    intermediate.write_text(result.stdout, encoding="utf-8")
    result = subprocess.run(
        [str(LCC / "build/rcc"), "-target=ex716", str(intermediate)],
        cwd=LCC, text=True, capture_output=True)
    if result.returncode or "EX716: unhandled" in result.stderr:
        raise RuntimeError(result.stderr)
    return result.stdout


def extract_function(unit, name):
    match = re.search(
        r"(?ms)^G " + re.escape(name) +
        r"\s+@FUNCTION " + re.escape(name) + r"\n.*?^@ENDFUNCTION\n", unit)
    if not match:
        raise RuntimeError("could not locate compiler-generated " + name)
    return match.group(0), unit[:match.start()] + unit[match.end():]


def rewrite_bank2(unit):
    replacements = (
        ("@PUSHRETURN", "@B2_PUSHRETURN"),
        ("@POPRETURN", "@B2_POPRETURN"),
        ("@EndCLocals", "@B2_EndCLocals"),
        ("@CALL shared_global_value", "@B2_CALL_B0 FarBankGlobalValue"),
        ("@CALL MUL", "@CALL B2_MUL"),
        ("@CALL MULU", "@CALL B2_MULU"),
        ("@CALL SHL16_BY_N", "@CALL B2_SHL16_BY_N"),
        ("@CALL SHR16_BY_N", "@CALL B2_SHR16_BY_N"),
        ("@CALL ex716_far_put16v", "@CALL B2_ex716_far_put16v"),
        ("@CALL ex716_far_get16v", "@CALL B2_ex716_far_get16v"),
    )
    for old, new in replacements:
        unit = unit.replace(old, new)
    unit = re.sub(r"@CLocals ([0-9]+)", r"@B2_CLocals \1", unit)
    remaining = [name for name in re.findall(r"(?m)^\s*@CALL\s+(\S+)", unit)
                 if name not in {"MapSetCell", "MapSmooth", "B2_MUL", "B2_MULU",
                                 "B2_SHL16_BY_N", "B2_SHR16_BY_N",
                                 "B2_ex716_far_put16v", "B2_ex716_far_get16v"}]
    if remaining:
        raise RuntimeError("bank-1 unit has unmapped near calls: " +
                           ", ".join(sorted(set(remaining))))
    return unit


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mapsmooth", action="store_true",
        help=("include MapSmooth in bank 3; this intentionally reproduces the "
              "current soft-stack/far-pointer failure and exits nonzero"))
    args = parser.parse_args(argv)
    with tempfile.TemporaryDirectory(prefix="mapmaker-banked-") as directory:
        work = Path(directory)
        defines = ["-DBANKED_SMOKE_MAP_SMOOTH=1"] if args.mapsmooth else []
        unit = compile_c(HERE / "banked_smoke.c", work, defines)
        driver, bank0 = extract_function(unit, "banked_driver")
        map_set_cell, bank0 = extract_function(bank0, "MapSetCell")
        map_smooth = ""
        if args.mapsmooth:
            map_smooth, bank0 = extract_function(bank0, "MapSmooth")
        service, bank0 = extract_function(bank0, "shared_global_value")
        implementation = rewrite_bank2(driver + map_set_cell + map_smooth)
        service = re.sub(r"\bshared_global_value\b", "FarBankGlobalValueImpl",
                         service)
        bank_math = work / "bank2_math.asm"
        generated = subprocess.run(
            [sys.executable, str(EX716 / "tools/bank_runtime.py"), "-o",
             str(bank_math), str(EX716 / "lib/mul.ld"),
             str(EX716 / "lib/div.ld"), str(EX716 / "lib/shift16.ld"),
             str(EX716 / "lib/farptr.ld")],
            text=True, capture_output=True)
        if generated.returncode:
            raise RuntimeError(generated.stderr)
        assembly = "\n".join((
            # Reserve MapSmooth's far scratch bank before selecting the next
            # executable bank.  HIGH_BANK is maintained by cpu24.py.
            ".DATA 2", ".DATA 1", "I commonDS.mc", "@JMP __banked_entry",
            "L clocals.ld", "L lmath.ld", "L farptr.ld", bank0, service,
            "@FUNCTION(F) FarBankGlobalValue", "@CALL FarBankGlobalValueImpl",
            "@SWP @RET", "@ENDFUNCTION",
            # MapSmooth reserves bank 2 for its far row buffer, so executable
            # banked C starts in bank 3.
            ".CODE HIGH_BANK+1", "L banked_runtime.ld",
            bank_math.read_text(encoding="utf-8"),
            implementation,
            "@FUNCTION(F) FarTarget", "@CALL banked_driver", "@SWP @RET",
            "@ENDFUNCTION", ".CODE 0", ":__banked_entry",
            ".ENTRY __banked_entry", "@PUSH 1", "@SSET SegDS", "@PUSH 1",
            "@ADM", "@PUSH 0xfff0", "@PUSH 0xf000", "@CALL SetSSStack",
            '@PRT "BANKED_RESULT="', "@FCALL HIGH_BANK FarTarget", "@PRTTOP",
            "@POPNULL", "@PRTNL", "@PUSH 0", "@ADM", "@END", ""))
        source = work / "banked.asm"
        source.write_text(assembly, encoding="utf-8")
        environment = dict(os.environ)
        environment["CPUPATH"] = str(EX716 / "lib")
        executed = subprocess.run(
            [sys.executable, str(EX716 / "cpu24.py"), str(source)], cwd=EX716,
            env=environment, text=True, capture_output=True)
        if executed.returncode or RESULT.findall(executed.stdout) != ["42"]:
            Path("/tmp/mapmaker-banked-failed.asm").write_text(
                assembly, encoding="utf-8")
    sys.stdout.write(executed.stdout)
    sys.stderr.write(executed.stderr)
    if executed.returncode or RESULT.findall(executed.stdout) != ["42"]:
        return executed.returncode or 1
    return 0 if "Unresolved symbols: 0" in executed.stdout else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print("FAIL: " + str(error), file=sys.stderr)
        raise SystemExit(1)
