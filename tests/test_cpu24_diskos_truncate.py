"""Shrink a writable DDS handle and commit its new size on close."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ENV = dict(os.environ, CPUPATH=str(ROOT / 'lib'))
source = (ROOT / 'tests/cpu24-diskos-open-probe.asm').read_text()
source = source.replace('L diskosDS.ld', (ROOT / 'lib/diskosDS.ld').read_text(), 1)
source = source.replace('DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen',
                        '3 @FCALL {DiskDDS} DiskOSOpen', 1)
source = source.replace('@IF_NEQ_AV 0 UserHandle\n', '''@IF_NEQ_AV 0 UserHandle
   @PUSHI UserHandle @PUSH 3 @PUSH 0 @FCALL {DiskDDS} DiskOSTruncate
   @PRT "truncate=" @PRTTOP @POPNULL @PRTNL
''', 1)

with tempfile.TemporaryDirectory(prefix='diskos-truncate-') as directory:
    work = Path(directory)
    image = work / 'DISK00.disk'
    clean = work / 'clean.disk'
    original = work / 'input.bin'
    original.write_bytes(b'abcdef')
    tool = ROOT / 'filesys/ex716disk.py'
    subprocess.run([sys.executable, str(tool), 'format', str(clean), '--disk-id',
                    '0', '--magic', '0x3044'], check=True, capture_output=True)
    subprocess.run([sys.executable, str(tool), 'import', str(clean), str(original),
                    '--name', 'EXISTS.TXT'], check=True, capture_output=True)
    fixture = work / 'truncate.asm'
    fixture.write_text(source)
    for fast in (False, True):
        shutil.copyfile(clean, image)
        cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
        if fast:
            cmd.append('-f')
        result = subprocess.run(cmd + [str(fixture)], cwd=work, env=ENV,
                                capture_output=True, text=True, timeout=60)
        expected = ('truncate=1', 'close=1', 'reclose=1',
                    'after DS=0001 ES=0004 user=7777')
        if result.returncode or any(value not in result.stdout for value in expected):
            raise AssertionError((cmd, result.returncode, result.stdout, result.stderr))
        exported = work / ('fast.bin' if fast else 'python.bin')
        subprocess.run([sys.executable, str(tool), 'export', str(image),
                        'EXISTS.TXT', '-o', str(exported)],
                       check=True, capture_output=True)
        if exported.read_bytes() != b'abc':
            raise AssertionError((fast, exported.read_bytes()))
        print('DiskOSDS truncate passed', '(fast)' if fast else '(Python)')
