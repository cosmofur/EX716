"""Smoke test for the new DS-local software stack and heap manager."""
from pathlib import Path
import os
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests" / "cpu24-ds-runtime.asm"


def run():
    environment = os.environ.copy()
    environment["CPUPATH"] = "lib"
    completed = subprocess.run(
        [sys.executable, "cpu24.py", "-q", str(FIXTURE)],
        cwd=ROOT, env=environment, text=True, capture_output=True, check=False
    )
    if completed.returncode:
        raise AssertionError(completed.stdout + completed.stderr)
    assert "DSS free=4096" in completed.stdout
    assert "COMMON=6" in completed.stdout
    assert "HDS first=0207 second=022a reused=0207 value=5678" in completed.stdout
    assert "DS2=2222" in completed.stdout
    assert "COMMON2=8" in completed.stdout
    assert "AFTER DS=2" in completed.stdout
    assert "DS1=5678" in completed.stdout
    assert "unresolved= 0" in completed.stdout


if __name__ == "__main__":
    run()
