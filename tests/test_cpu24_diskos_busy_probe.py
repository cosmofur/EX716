"""Verify rejected nested DDS operations preserve an active call's state."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ENV = dict(os.environ, CPUPATH=str(ROOT / 'lib'))
source = (ROOT / 'tests/cpu24-diskos-open-probe.asm').read_text()
source = source.replace('L diskosDS.ld', (ROOT / 'lib/diskosDS.ld').read_text(), 1)
source = source.replace('@PUSH UserName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen', '''@PUSH {DiskDDS} @SSET SegES
@PUSH 1 @PUSH DiskBusy @ESO @POPS
@PUSH 0x1357 @PUSH SavedPC @ESO @POPS
@PUSH 4 @SSET SegES
@PUSH UserName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen
@PRT "busyopen=" @PRTTOP @POPNULL @PRTNL
@PUSH 123 @FCALL {DiskDDS} DiskOSClose
@PRT "busyclose=" @PRTTOP @POPNULL @PRTNL
@PUSH 123 @PUSH UserName @PUSH 1 @FCALL {DiskDDS} DiskOSRead
@PRT "busyread=" @PRTTOP @POPNULL @PRTNL
@PUSH 123 @PUSH UserName @PUSH 1 @FCALL {DiskDDS} DiskOSWrite
@PRT "busywrite=" @PRTTOP @POPNULL @PRTNL
@PRT "busy DS=" @SGET SegDS @PRTHEXTOP @POPNULL
@PRT " ES=" @SGET SegES @PRTHEXTOP @POPNULL @PRTNL
@PUSH {DiskDDS} @SSET SegES
@PRT "active=" @PUSH DiskBusy @ESO @PUSHS @PRTHEXTOP @POPNULL
@PRT " error=" @PUSH DiskLastError @ESO @PUSHS @PRTHEXTOP @POPNULL
@PRT " saved=" @PUSH SavedPC @ESO @PUSHS @PRTHEXTOP @POPNULL @PRTNL
@PUSH 0 @PUSH DiskBusy @ESO @POPS
@PUSH 4 @SSET SegES
@FCALL {DiskDDS} DiskOSLastError
@PRT "query=" @PRTTOP @POPNULL @PRTNL
@FCALL {DiskDDS} DiskOSLastError
@PRT "queryagain=" @PRTTOP @POPNULL @PRTNL
@PUSH UserName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen''', 1)
source = source.replace('@PRT "after DS="', '''@FCALL {DiskDDS} DiskOSLastError
@PRT "queryclear=" @PRTTOP @POPNULL @PRTNL
@PRT "after DS="''', 1)
with tempfile.TemporaryDirectory(prefix='diskos-busy-') as directory:
    work = Path(directory)
    image = work / 'DISK00.disk'
    hostfile = work / 'input.txt'
    hostfile.write_text('test\n')
    tool = ROOT / 'filesys/ex716disk.py'
    subprocess.run([sys.executable, str(tool), 'format', str(image), '--disk-id',
                    '0', '--magic', '0x3044'], check=True, capture_output=True)
    subprocess.run([sys.executable, str(tool), 'import', str(image), str(hostfile),
                    '--name', 'EXISTS.TXT'], check=True, capture_output=True)
    fixture = work / 'probe.asm'
    fixture.write_text(source)
    for fast in (False, True):
        cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
        if fast:
            cmd.append('-f')
        result = subprocess.run(cmd + [str(fixture)], cwd=work, env=ENV,
                                capture_output=True, text=True, timeout=60)
        expected = ('busyopen=0', 'busyclose=0', 'busyread=0', 'busywrite=0',
                    'busy DS=0001 ES=0004', 'active=0001 error=0001 saved=1357',
                    'query=1', 'queryagain=1', 'queryclear=0',
                    'close=1', 'reclose=1', 'stack=effe/abcd', 'stackbank=0003')
        if result.returncode or any(x not in result.stdout for x in expected):
            raise AssertionError((cmd, result.returncode, result.stdout, result.stderr))
        print('DiskOSDS re-entry rejection passed', '(fast)' if fast else '(Python)')
