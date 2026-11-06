"""Interactive CPU24 FuncCalc regression; run with python3 tests/test_funccalc24.py."""
import os
from pathlib import Path
import pty
import select
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent.parent


def run(fast=False):
    master, slave = pty.openpty()
    env = dict(os.environ, CPUPATH=os.pathsep.join((str(ROOT / "tests"), str(ROOT / "lib"))))
    args = [sys.executable, "-u", str(ROOT / "cpu24.py"), "-q"]
    if fast:
        args.append("-f")
    proc = subprocess.Popen(
        args + ["FuncCalc.asm"],
        cwd=ROOT / "tests", env=env, stdin=slave, stdout=slave, stderr=slave,
    )
    os.close(slave)
    transcript = bytearray()

    def expect(marker, timeout=30):
        output = bytearray()
        end = time.monotonic() + timeout
        while marker not in output:
            remaining = end - time.monotonic()
            if remaining <= 0 or not select.select([master], [], [], remaining)[0]:
                raise AssertionError(f"timeout waiting for {marker!r}; output: {bytes(output)!r}")
            try:
                chunk = os.read(master, 65536)
            except OSError:
                chunk = b""
            if not chunk:
                raise AssertionError(f"process exited waiting for {marker!r}; output: {bytes(output)!r}")
            output.extend(chunk)
            transcript.extend(chunk)
        return bytes(output).replace(b"\r", b"")

    def command(line, expected):
        os.write(master, line.encode() + b"\n")
        output = expect(b"FC> ")
        if expected not in output:
            raise AssertionError(f"{line!r}: expected {expected!r}, got {output!r}")

    try:
        expect(b"FC> ")
        command("PRINT 2+3*4", b"\n14\n")
        command('PRINT "a"+"b"', b"\nab\n")
        command("PRINT -17%5", b"\n-2\n")
        command('WRITE("hello")', b"helloFC> ")
        os.write(master, b'A=INPUT("Name: ")\n')
        expect(b"Name: ")
        os.write(master, b"Ada\n")
        expect(b"FC> ")
        command("PRINT A", b"\nAda\n")
        os.write(master, b'N=INPUTINT("Number: ")\n')
        expect(b"Number: ")
        os.write(master, b"42\n")
        expect(b"FC> ")
        command("PRINT N+1", b"\n43\n")
        os.write(master, b"QUIT\n")
        expect(b"Bye.")
        proc.wait(timeout=10)
        if proc.returncode:
            raise AssertionError(f"cpu24 exited {proc.returncode}")
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        os.close(master)
    print(f"FuncCalc24 arithmetic, strings and console I/O passed ({'fast' if fast else 'Python'})")


if __name__ == "__main__":
    if sys.argv[1:] not in ([], ["--fast"]):
        raise SystemExit("usage: test_funccalc24.py [--fast]")
    run(fast=bool(sys.argv[1:]))
