"""Regression probe for the current DS-local heap/soft-stack contract."""
from pathlib import Path
import os
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests" / "cpu24-segment-memory.asm"


def run():
    environment = os.environ.copy()
    environment["CPUPATH"] = "lib"
    completed = subprocess.run(
        [sys.executable, "cpu24.py", "-q", str(FIXTURE)],
        cwd=ROOT, env=environment, text=True, capture_output=True, check=False
    )
    if completed.returncode:
        raise AssertionError(completed.stdout + completed.stderr)
    assert "DS1=1111" in completed.stdout, completed.stdout
    assert "DS2=2222" in completed.stdout, completed.stdout
    assert "FAR=bead ES=0003" in completed.stdout, completed.stdout
    assert "unresolved= 0" in completed.stdout, completed.stdout


if __name__ == "__main__":
    run()
