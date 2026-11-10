"""Exercise prototype UDS-to-DDS filename copying with isolated fixtures."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ENV = dict(os.environ, CPUPATH=os.pathsep.join((str(ROOT / 'tests'), str(ROOT / 'lib'))))
source = (ROOT / 'tests/cpu24-diskos-filename-probe.asm').read_text()
cases = [('TEST.TXT', 'TEST.TXT', 1), ('X' * 31, 'X' * 31, 1),
         ('X' * 32, '<invalid>', 0)]
with tempfile.TemporaryDirectory(prefix='diskos-filename-') as directory:
    for name, displayed, status in cases:
        fixture = Path(directory) / 'probe.asm'
        fixture.write_text(source.replace('TEST.TXT', name, 1))
        for fast in (False, True):
            cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
            if fast:
                cmd.append('-f')
            result = subprocess.run(cmd + [str(fixture)], cwd=directory, env=ENV,
                                    capture_output=True, text=True, timeout=30)
            expected = f'filename={displayed} status={status} DS=0001 ES=0004'
            if result.returncode or expected not in result.stdout:
                raise AssertionError((cmd, result.returncode, result.stdout, result.stderr))
            print(f'UDS filename length {len(name)} passed', '(fast)' if fast else '(Python)')
