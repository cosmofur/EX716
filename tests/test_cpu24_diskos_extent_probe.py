"""Append across the 64 KiB extent boundary via the DDS write gateway."""
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
source = source.replace('::UserSentinel 0x7777',
                        '::UserSentinel 0x7777\n::WriteData 0 0')
source = source.replace('@PUSH UserName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen',
                        '@PUSH UserName @PUSH 0x0016 @FCALL {DiskDDS} DiskOSOpen', 1)
source = source.replace('@IF_NEQ_AV 0 UserHandle\n', '''@IF_NEQ_AV 0 UserHandle
   @PUSH 0x0100 @POPI WriteData
   @PUSH 0xfe80 @POPI WriteData+2
   @PUSHI UserHandle @PUSH WriteData @PUSH 4 @FCALL {DiskDDS} WriteGateway
   @PRT "write1=" @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH WriteData @PUSH 4 @FCALL {DiskDDS} WriteGateway
   @PRT "write2=" @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH WriteData @PUSH 4 @FCALL {DiskDDS} WriteGateway
   @PRT "write3=" @PRTTOP @POPNULL @PRTNL
''', 1)

with tempfile.TemporaryDirectory(prefix='diskos-extent-') as directory:
    work = Path(directory)
    tool = ROOT / 'filesys/ex716disk.py'
    clean, image = work / 'clean.disk', work / 'DISK00.disk'
    hostfile = work / 'input.bin'
    initial = bytes(range(256)) * 255 + bytes(range(250))  # 65,530 bytes
    assert len(initial) == 65530
    hostfile.write_bytes(initial)
    subprocess.run([sys.executable, str(tool), 'format', str(clean), '--disk-id',
                    '0', '--magic', '0x3044'], check=True, capture_output=True)
    subprocess.run([sys.executable, str(tool), 'import', str(clean), str(hostfile),
                    '--name', 'EXISTS.TXT'], check=True, capture_output=True)
    fixture = work / 'probe.asm'
    fixture.write_text(source)
    for fast in (False, True):
        shutil.copyfile(clean, image)
        cmd = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
        if fast:
            cmd.append('-f')
        result = subprocess.run(cmd + [str(fixture)], cwd=work, env=ENV,
                                capture_output=True, text=True, timeout=120)
        expected = ('write1=4', 'write2=4', 'write3=4', 'close=1',
                    'reclose=1', 'after DS=0001 ES=0004 user=7777',
                    'stack=effe/abcd', 'stackbank=0003')
        if result.returncode or any(x not in result.stdout for x in expected):
            raise AssertionError((cmd, result.returncode, result.stdout, result.stderr))
        export = work / ('fast-export.bin' if fast else 'python-export.bin')
        subprocess.run([sys.executable, str(tool), 'export', str(image), 'EXISTS.TXT',
                        '-o', str(export)], check=True, capture_output=True)
        actual = export.read_bytes()
        assert actual == initial + b'\x00\x01\x80\xfe' * 3, (len(actual), actual[-16:])
        check = subprocess.run([sys.executable, str(tool), 'check', str(image)],
                               capture_output=True, text=True)
        if check.returncode:
            raise AssertionError((check.returncode, check.stdout, check.stderr))
        print('DDS repeated writes across 64 KiB passed', '(fast)' if fast else '(Python)')
