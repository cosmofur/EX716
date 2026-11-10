"""Smoke test for a private-CS/DS service gateway on both CPU24 engines."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ENV = dict(os.environ, CPUPATH=os.pathsep.join((str(ROOT / 'tests'), str(ROOT / 'lib'))))
source = (ROOT / 'tests/cpu24-diskos-gateway-probe.asm').read_text()
with tempfile.TemporaryDirectory(prefix='diskos-gateway-') as directory:
    for previous_bank, expected_dds in ((0, 2), (7, 8)):
        # Select another code bank before reserving DDS; return to CS0 for Main.
        variant = source.replace('MF DiskDDS',
                                 f'.CODE {previous_bank}\n.CODE 0\nMF DiskDDS', 1)
        fixture = Path(directory) / 'probe.asm'
        fixture.write_text(variant)
        for fast in (False, True):
            cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
            if fast:
                cmd.append('-f')
            result = subprocess.run(cmd + [str(fixture)], cwd=directory, env=ENV,
                                    capture_output=True, text=True, timeout=30)
            expected = f'result=5678 DS=0001 ES=0004 DDS={expected_dds:04x} app=beef'
            if result.returncode or expected not in result.stdout:
                raise AssertionError((cmd, result.returncode, result.stdout, result.stderr))
            print(f'CPU24 DiskOS gateway DDS {expected_dds} passed',
                  '(fast)' if fast else '(Python)')
