"""Exercise an isolated, one-shot DDS DiskOS open on disposable images."""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ENV = dict(os.environ, CPUPATH=str(ROOT / 'lib'))
source = (ROOT / 'tests/cpu24-diskos-open-probe.asm').read_text()
source = source.replace('L diskosDS.ld', (ROOT / 'lib/diskosDS.ld').read_text(), 1)
with tempfile.TemporaryDirectory(prefix='diskos-open-') as directory:
    work = Path(directory)
    image = work / 'DISK00.disk'
    hostfile = work / 'input.txt'
    hostfile.write_text('DiskOS open probe\n')
    tool = ROOT / 'filesys/ex716disk.py'
    subprocess.run([sys.executable, str(tool), 'format', str(image), '--disk-id',
                    '0', '--magic', '0x3044'], check=True, capture_output=True)
    subprocess.run([sys.executable, str(tool), 'import', str(image), str(hostfile),
                    '--name', 'EXISTS.TXT'], check=True, capture_output=True)
    for name, should_open in [('EXISTS.TXT', True), ('MISSING.TXT', False),
                              ('X' * 32, False)]:
        fixture = work / 'probe.asm'
        fixture.write_text(source.replace('EXISTS.TXT', name, 1))
        for fast in (False, True):
            cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
            if fast:
                cmd.append('-f')
            result = subprocess.run(cmd + [str(fixture)], cwd=work, env=ENV,
                                    capture_output=True, text=True, timeout=60)
            match = re.search(r'result=(\d+) DS=0001 ES=0004', result.stdout)
            reopened = re.search(r'reopen=(\d+)', result.stdout)
            if (result.returncode or not match
                    or (int(match.group(1)) > 0) != should_open
                    or 'init=1' not in result.stdout
                    or 'initrepeat=1' not in result.stdout
                    or 'initmismatch=0' not in result.stdout
                    or 'initerror=10' not in result.stdout
                    or ('find=1' in result.stdout) != should_open
                    or 'findmissing=0' not in result.stdout
                    or ('info=1' in result.stdout) != should_open
                    or ('info-len=10' in result.stdout) != should_open
                    or ('info-strcmp=0' in result.stdout) != should_open
                    or ('close=1' in result.stdout) != should_open
                    or ('reclose=1' in result.stdout) != should_open
                    or 'stack=effe/abcd' not in result.stdout
                    or 'stackbank=0003' not in result.stdout
                    or 'after DS=0001 ES=0004 user=7777' not in result.stdout
                    or (bool(reopened) and (int(reopened.group(1)) > 0) != should_open)
                    or (should_open and reopened and reopened.group(1) == match.group(1))):
                raise AssertionError((name, cmd, result.returncode, result.stdout, result.stderr))
            print(f'DDS open {name} passed', '(fast)' if fast else '(Python)')
