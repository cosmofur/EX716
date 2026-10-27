#!/usr/bin/env python3
"""Build MapMaker for CPU24, write MAPMAKER.MAP to a temporary DISK00 image.

Use --smoke for a 7x7 execution check.  Without it, this builds the normal
127x127 fixed-configuration target program; extraction is left in the chosen
directory so the map can be viewed with mapmaker-target-convert and mapmaker-ansi.
"""
from __future__ import print_function

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
RESULT = re.compile(r"(?m)^MAPMAKER_CPU24_RESULT=(-?\d+)\s*$")


def run(command, cwd, environment=None):
    return subprocess.run(command, cwd=str(cwd), env=environment, text=True,
                          capture_output=True)


def compile_unit(source, name, defines, work):
    cpp = [str(LCC / "build/cpp"), "-N", "-D__EX716__=1",
           "-I" + str(HERE), "-I" + str(LCC / "include/ex716")]
    cpp.extend(defines)
    cpp.append(str(source))
    result = run(cpp, work)
    if result.returncode:
        raise RuntimeError(result.stderr)
    intermediate = work / (name + ".i")
    intermediate.write_text(result.stdout, encoding="utf-8")
    result = run([str(LCC / "build/rcc"), "-target=ex716", str(intermediate)], LCC)
    if result.returncode or "EX716: unhandled" in result.stderr:
        raise RuntimeError(result.stderr)
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--smoke", action="store_true",
                        help="run a fast 7x7 disk-write smoke test")
    parser.add_argument("--output-dir", type=Path, default=HERE,
                        help="where DISK00.disk and the extracted map are retained")
    parser.add_argument("--cpu-debug", action="store_true",
                        help="run CPU24 with three assembler/debug trace levels")
    args = parser.parse_args()
    if not (LCC / "build/rcc").is_file() or not (LCC / "build/cpp").is_file():
        parser.error("missing lcc compiler tools")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    defines = []
    if args.smoke:
        defines = ["-DMAP_WIDTH=7", "-DMAP_HEIGHT=7"]
    with tempfile.TemporaryDirectory(prefix="mapmaker-disk-") as directory:
        work = Path(directory)
        disk = work / "DISK00.disk"
        format_disk = run([sys.executable, str(EX716 / "filesys/ex716disk.py"),
                           "format", str(disk), "--disk-id", "0x0716",
                           "--magic", "0x3044", "--create-time", "0"], work)
        if format_disk.returncode:
            raise RuntimeError(format_disk.stderr)
        runtime = compile_unit(EX716 / "lib/stdio_format.c", "stdio", [], work)
        core = compile_unit(HERE / "mapmaker.c", "mapmaker", defines, work)
        program = compile_unit(HERE / "mapmaker_cpu24.c", "program", defines, work)
        assembly = "\n".join((
            ".DATA 1", "I commonDS.mc", "@JMP __mapmaker_entry",
            ":__mapmaker_entry", ".ENTRY __mapmaker_entry", "@PUSH 1",
            "@SSET SegDS", "@PUSH 1", "@ADM",
            '@PRT "MAPMAKER_CPU24_RESULT="', "@CALL main", "@PRTTOP",
            "@POPNULL", "@PRTNL", "@PUSH 0", "@ADM", "@END", ""))
        assembly = "\n".join((assembly, "L clocals.ld", "L lmath.ld", "L farptr.ld",
                               runtime, core, program, ""))
        source = work / "mapmaker.asm"
        source.write_text(assembly, encoding="utf-8")
        environment = dict(os.environ)
        environment["CPUPATH"] = os.pathsep.join((str(EX716 / "lib"), str(work)))
        cpu_command = [sys.executable, str(EX716 / "cpu24.py"), "--trace-tail", "64"]
        if args.cpu_debug:
            cpu_command.extend(("-d", "-d", "-d"))
        cpu_command.append(str(source))
        executed = run(cpu_command, work,
                       environment)
        sys.stdout.write(executed.stdout)
        sys.stderr.write(executed.stderr)
        if executed.returncode or RESULT.findall(executed.stdout) != ["0"]:
            debug_source = args.output_dir / "mapmaker-failed.asm"
            debug_source.write_text(assembly, encoding="utf-8")
            print("retained " + str(debug_source), file=sys.stderr)
            lines = assembly.splitlines()
            for line in (executed.stdout + "\n" + executed.stderr).splitlines():
                if "Filename:" in line and ":" in line:
                    try:
                        line_number = int(line.rsplit(":", 1)[1])
                        if line_number > 0 and line_number <= len(lines):
                            print("assembly failure line " + str(line_number) +
                                  ": " + lines[line_number - 1], file=sys.stderr)
                    except ValueError:
                        pass
            return 1
        output_disk = args.output_dir / "DISK00.disk"
        output_map = args.output_dir / "MAPMAKER.MAP"
        output_disk.write_bytes(disk.read_bytes())
        exported = run([sys.executable, str(EX716 / "filesys/ex716disk.py"), "export",
                        str(disk), "MAPMAKER.MAP", "-o", str(output_map)], work)
        if exported.returncode:
            sys.stderr.write(exported.stderr)
            return 1
    print("wrote " + str(output_disk))
    print("exported " + str(output_map))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print("FAIL: " + str(error), file=sys.stderr)
        raise SystemExit(1)
