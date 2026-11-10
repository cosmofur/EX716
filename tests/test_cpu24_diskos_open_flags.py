"""Check DiskOSDS open-flag validation and create/truncate behavior."""
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
disk_tool = ROOT / 'filesys/ex716disk.py'

with tempfile.TemporaryDirectory(prefix='diskos-flags-') as directory:
    work = Path(directory)
    clean = work / 'clean.disk'
    image = work / 'DISK00.disk'
    original = work / 'original.txt'
    original.write_bytes(b'keep me')
    subprocess.run([sys.executable, str(disk_tool), 'format', str(clean),
                    '--disk-id', '0', '--magic', '0x3044'],
                   check=True, capture_output=True)
    subprocess.run([sys.executable, str(disk_tool), 'import', str(clean),
                    str(original), '--name', 'EXISTS.TXT'],
                   check=True, capture_output=True)

    for flags in ('0x0000', '0x0020', '0x000a'):
        shutil.copyfile(clean, image)
        fixture = work / 'invalid.asm'
        invalid = source.replace('DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen',
                                 f'{flags} @FCALL {{DiskDDS}} DiskOSOpen', 1)
        invalid = invalid.replace('@PRT " DS="', '''@FCALL {DiskDDS} DiskOSLastError
@PRT "error=" @PRTTOP @POPNULL @PRT " DS="''', 1)
        fixture.write_text(invalid)
        for fast in (False, True):
            cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
            if fast:
                cmd.append('-f')
            result = subprocess.run(cmd + [str(fixture)], cwd=work, env=ENV,
                                    capture_output=True, text=True, timeout=60)
            if result.returncode or 'result=0error=3 DS=0001 ES=0004' not in result.stdout:
                raise AssertionError((flags, cmd, result.returncode,
                                      result.stdout, result.stderr))
        print(f'DiskOSDS invalid open flags {flags} passed')

    shutil.copyfile(clean, image)
    truncate = source.replace('DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen',
                              '0x000e @FCALL {DiskDDS} DiskOSOpen', 1)
    fixture = work / 'truncate.asm'
    fixture.write_text(truncate)
    for fast in (False, True):
        cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
        if fast:
            cmd.append('-f')
        result = subprocess.run(cmd + [str(fixture)], cwd=work, env=ENV,
                                capture_output=True, text=True, timeout=60)
        if result.returncode or 'close=1' not in result.stdout \
                or 'reclose=1' not in result.stdout:
            raise AssertionError((cmd, result.returncode,
                                  result.stdout, result.stderr))
        exported = work / ('fast.bin' if fast else 'python.bin')
        subprocess.run([sys.executable, str(disk_tool), 'export', str(image),
                        'EXISTS.TXT', '-o', str(exported)],
                       check=True, capture_output=True)
        if exported.read_bytes():
            raise AssertionError((fast, exported.read_bytes()))
        print('DiskOSDS truncate-on-open passed', '(fast)' if fast else '(Python)')
