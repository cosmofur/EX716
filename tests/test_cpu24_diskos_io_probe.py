"""Round-trip binary data through the experimental UDS/DDS DiskOS gateways."""
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
source = source.replace('::UserSentinel 0x7777', '''::UserSentinel 0x7777
::WriteData $$0 $$1 $$0xff $$0x80 $$0x41 $$0
::ReadData 0 0 0 0 0 0 0 0
::Stats 0 0''')
source = source.replace('@PUSH UserName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen',
                        '@PUSH UserName @PUSH 3 @FCALL {DiskDDS} DiskOSOpen', 1)
source = source.replace('@IF_NEQ_AV 0 UserHandle\n', '''@IF_NEQ_AV 0 UserHandle
   @PUSH 0x0100 @POPI WriteData
   @PUSH 0x80ff @POPI WriteData+2
   @PUSH 0x0041 @POPI WriteData+4
   @PUSHI UserHandle @PUSH WriteData @PUSH 6 @FCALL {DiskDDS} WriteGateway
   @PRT "write=" @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH Stats @FCALL {DiskDDS} DiskOSTell
   @PRT "tellok=" @PRTTOP @POPNULL
   @PRT " tell=" @PUSHI Stats @PRTTOP @POPNULL
   @PRT "/" @PUSHI Stats+2 @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH Stats @FCALL {DiskDDS} DiskOSSize
   @PRT "sizeok=" @PRTTOP @POPNULL
   @PRT " size=" @PUSHI Stats @PRTTOP @POPNULL
   @PRT "/" @PUSHI Stats+2 @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH 0xffff @PUSH 1 @FCALL {DiskDDS} WriteGateway
   @PRT "badwrite=" @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH 0xfffe @PUSH 2 @FCALL {DiskDDS} WriteGateway
   @PRT "wrapwrite=" @PRTTOP @POPNULL @PRTNL
''', 1)
source = source.replace('@PRT "reopen=" @PUSHI UserHandle @PRTTOP @POPNULL @PRTNL', '''@PRT "reopen=" @PUSHI UserHandle @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH 0xfffe @PUSH 2 @FCALL {DiskDDS} ReadGateway
   @PRT "badread=" @PRTTOP @POPNULL @PRTNL
   @PUSH 0xbeef @POPI ReadData+6
   @PUSHI UserHandle @PUSH ReadData @PUSH 16 @FCALL {DiskDDS} ReadGateway
   @PRT "read=" @PRTTOP @POPNULL @PRTNL
   @PRT "bytes=" @PUSHI ReadData @PRTHEXTOP @POPNULL
   @PRT "/" @PUSHI ReadData+2 @PRTHEXTOP @POPNULL
   @PRT "/" @PUSHI ReadData+4 @PRTHEXTOP @POPNULL
   @PRT "/" @PUSHI ReadData+6 @PRTHEXTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH ReadData @PUSH 1 @FCALL {DiskDDS} ReadGateway
   @PRT "eof=" @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @PUSH ReadData @PUSH 0 @FCALL {DiskDDS} ReadGateway
   @PRT "zero=" @PRTTOP @POPNULL @PRTNL''', 1)

with tempfile.TemporaryDirectory(prefix='diskos-io-') as directory:
    work = Path(directory)
    image = work / 'DISK00.disk'
    clean = work / 'clean.disk'
    hostfile = work / 'input.bin'
    hostfile.write_bytes(b'abcdef')
    tool = ROOT / 'filesys/ex716disk.py'
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
        expected = ('write=6', 'tellok=1 tell=6/0', 'sizeok=1 size=6/0',
                    'badwrite=0', 'wrapwrite=0', 'badread=0',
                    'read=6', 'bytes=0100/80ff/0041/beef',
                    'eof=0', 'zero=0', 'after DS=0001 ES=0004 user=7777',
                    'stack=effe/abcd', 'stackbank=0003', 'reclose=1')
        if result.returncode or any(x not in result.stdout for x in expected):
            raise AssertionError((cmd, result.returncode, result.stdout, result.stderr))
        export = work / ('fast-export.bin' if fast else 'python-export.bin')
        subprocess.run([sys.executable, str(tool), 'export', str(image), 'EXISTS.TXT',
                        '-o', str(export)], check=True, capture_output=True)
        assert export.read_bytes() == b'\x00\x01\xff\x80A\x00'
        print('DDS binary write/read/EOF passed', '(fast)' if fast else '(Python)')
