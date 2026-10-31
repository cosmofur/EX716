#!/usr/bin/env python3
"""Build MapMaker for CPU24 and write MAPMAKER.MAP to an existing DISK00 image.

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
RESULT = re.compile(r"(?m)^EX716_MAIN_STATUS=(-?\d+)\s*$")


def run(command, cwd, environment=None):
    return subprocess.run(command, cwd=str(cwd), env=environment, text=True,
                          capture_output=True)


def compile_unit(source, name, defines, work, rcc_options=()):
    cpp = [str(LCC / "build/cpp"), "-N", "-D__EX716__=1",
           "-I" + str(HERE), "-I" + str(LCC / "include/ex716")]
    cpp.extend(defines)
    cpp.append(str(source))
    result = run(cpp, work)
    if result.returncode:
        raise RuntimeError(result.stderr)
    intermediate = work / (name + ".i")
    intermediate.write_text(result.stdout, encoding="utf-8")
    result = run([str(LCC / "build/rcc"), "-target=ex716", *rcc_options,
                  str(intermediate)], LCC)
    if result.returncode or "EX716: unhandled" in result.stderr:
        raise RuntimeError(result.stderr)
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--smoke", action="store_true",
                        help="run a fast 7x7 disk-write smoke test")
    parser.add_argument("--output-dir", type=Path, default=HERE,
        help="where the extracted map and failure assembly are retained")
    parser.add_argument("--disk", type=Path, default=HERE / "DISK00.disk",
                        help="existing DiskOS image used by the target (default: %(default)s)")
    parser.add_argument("--cpu-debug", action="store_true",
                        help="run CPU24 with three assembler/debug trace levels")
    args = parser.parse_args()
    if not (LCC / "build/rcc").is_file() or not (LCC / "build/cpp").is_file():
        parser.error("missing lcc compiler tools")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    args.disk = args.disk.resolve()
    if args.disk.name != "DISK00.disk":
        parser.error("--disk must be named DISK00.disk; target stdio opens that name")
    if not args.disk.is_file():
        parser.error("missing existing disk image: " + str(args.disk))
    checked_disk = run([sys.executable, str(EX716 / "filesys/ex716disk.py"),
                        "check", str(args.disk)], args.disk.parent)
    if checked_disk.returncode:
        parser.error("invalid disk image: " + checked_disk.stderr.strip())
    defines = []
    if args.smoke:
        defines = ["-DMAP_WIDTH=7", "-DMAP_HEIGHT=7",
                   "-DMAPMAKER_CPU24_SMOKE=1"]
    with tempfile.TemporaryDirectory(prefix="mapmaker-disk-") as directory:
        work = Path(directory)
        runtime = compile_unit(EX716 / "lib/stdio_format.c", "stdio", [], work)
        core = compile_unit(HERE / "mapmaker.c", "mapmaker", defines, work)
        program = compile_unit(HERE / "mapmaker_cpu24.c", "program", defines, work,
                               rcc_options=("-main-header=direct",))
        assembly = "\n".join((
            ".DATA 1", "I commonDS.mc", "@JMP __mapmaker_entry",
            ":__mapmaker_entry", ".ENTRY __mapmaker_entry", "@PUSH 1",
            "@SSET SegDS", "@PUSH 1", "@ADM", "@PUSH 0xfff0",
            "@PUSH 0xf000", "@CALL SetSSStack",
            # The direct header creates main's only synthetic near return;
            # entering it through @CALL would add a second return frame.
            "@FJMP 2 __ex716_main_direct", "@END", ""))
        assembly = "\n".join((assembly, "L clocals.ld", "L lmath.ld", "L farptr.ld",
                               runtime, core, program, ""))
        source = work / "mapmaker.asm"
        source.write_text(assembly, encoding="utf-8")
        environment = dict(os.environ)
        environment["CPUPATH"] = os.pathsep.join((str(EX716 / "lib"), str(work)))
        cpu_command = [sys.executable, str(EX716 / "cpu24.py"), "--trace-tail", "64"]
        if args.smoke:
            cpu_command.append("-f")
        if args.cpu_debug:
            cpu_command.extend(("-d", "-d", "-d"))
        cpu_command.append(str(source))
        executed = run(cpu_command, args.disk.parent,
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
        output_map = args.output_dir / "MAPMAKER.MAP"
        exported = run([sys.executable, str(EX716 / "filesys/ex716disk.py"), "export",
                        str(args.disk), "MAPMAKER.MAP", "-o", str(output_map)],
                       args.disk.parent)
        if exported.returncode:
            sys.stderr.write(exported.stderr)
            return 1
    print("used " + str(args.disk))
    print("exported " + str(output_map))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print("FAIL: " + str(error), file=sys.stderr)
        raise SystemExit(1)
