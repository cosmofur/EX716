"""Verify the non-reentrant probe retains two independent open handles."""
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
source = source.replace('::UserHandle 0',
                        '::UserHandle 0\n::SecondHandle 0\n::SecondName "SECOND.TXT\\0"', 1)
source = source.replace('@IF_NEQ_AV 0 UserHandle\n', '''@PUSH SecondName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen @POPI SecondHandle
@PRT "second=" @PUSHI SecondHandle @PRTTOP @POPNULL @PRTNL
@IF_NEQ_AV 0 UserHandle
''', 1)
source = source.replace('@PRT "close=" @PRTTOP @POPNULL @PRTNL', '''@PRT "close=" @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @FCALL {DiskDDS} DiskOSClose
   @PRT "staleclose=" @PRTTOP @POPNULL @PRTNL
   @FCALL {DiskDDS} DiskOSLastError
   @PRT "staleerror=" @PRTTOP @POPNULL @PRTNL
   @PUSHI SecondHandle @FCALL {DiskDDS} DiskOSClose
   @PRT "secondclose=" @PRTTOP @POPNULL @PRTNL''', 1)
with tempfile.TemporaryDirectory(prefix='diskos-two-handles-') as directory:
    work = Path(directory)
    image, hostfile = work / 'DISK00.disk', work / 'input.txt'
    hostfile.write_text('test\n')
    tool = ROOT / 'filesys/ex716disk.py'
    subprocess.run([sys.executable, str(tool), 'format', str(image), '--disk-id',
                    '0', '--magic', '0x3044'], check=True, capture_output=True)
    for name in ('EXISTS.TXT', 'SECOND.TXT'):
        subprocess.run([sys.executable, str(tool), 'import', str(image), str(hostfile),
                        '--name', name], check=True, capture_output=True)
    fixture = work / 'probe.asm'
    fixture.write_text(source)
    for fast in (False, True):
        cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
        if fast:
            cmd.append('-f')
        result = subprocess.run(cmd + [str(fixture)], cwd=work, env=ENV,
                                capture_output=True, text=True, timeout=60)
        first = re.search(r'result=(\d+)', result.stdout)
        second = re.search(r'second=(\d+)', result.stdout)
        expected = ('close=1', 'staleclose=0', 'staleerror=7',
                    'secondclose=1', 'reclose=1',
                    'after DS=0001 ES=0004 user=7777', 'stack=effe/abcd')
        if (result.returncode or not first or not second or int(first.group(1)) == 0
                or int(second.group(1)) == 0 or first.group(1) == second.group(1)
                or any(x not in result.stdout for x in expected)):
            raise AssertionError((cmd, result.returncode, result.stdout, result.stderr))
        print('DiskOSDS simultaneous handles passed', '(fast)' if fast else '(Python)')
