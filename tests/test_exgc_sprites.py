"""Exercise the EXGC sprite guest registers in both CPU24 executors."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def test_guest_sprite_setup():
    source = Path(__file__).with_name('exgc-sprites.asm').read_text()
    source = source.replace('@ForIA2B Frame 0 30', '@ForIA2B Frame 0 2')
    source = source.replace('@Call(A) Sleep 1', '@Call(A) Sleep 0')
    source = source.replace('@END', '''@PRT " sprite="
@PUSH 0xf804 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@PUSH 0xf808 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@PUSH 0xe000 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@PUSH 0xe008 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@PUSH 0xb400 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@PUSH 0xe006 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@PUSH 0 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRTNL
@END''')
    env = os.environ.copy()
    env['CPUPATH'] = str(ROOT / 'lib')
    with tempfile.TemporaryDirectory() as directory:
        program = Path(directory) / 'sprites.asm'
        program.write_text(source)
        for args in ([], ['-f']):
            result = subprocess.run([sys.executable, str(ROOT / 'cpu24.py'), '-q',
                                     *args, str(program)], cwd=ROOT, env=env,
                                    text=True, capture_output=True, timeout=30)
            assert result.returncode == 0, result.stdout + result.stderr
            assert ' sprite=0010,0205,0006,00c2,0100,0011,6666' in result.stdout, result.stdout


if __name__ == '__main__':
    test_guest_sprite_setup()
