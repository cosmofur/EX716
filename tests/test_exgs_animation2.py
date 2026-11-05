"""Exercise animation calls and packed framebuffer pixels in CPU24."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(__file__).with_name('exgs-animation2.asm')


def run_program(source, fast):
    environment = os.environ.copy()
    environment['CPUPATH'] = str(ROOT / 'lib')
    with tempfile.TemporaryDirectory() as directory:
        program = Path(directory) / 'animation.asm'
        program.write_text(source)
        command = [sys.executable, str(ROOT / 'cpu24.py'), '-q']
        if fast:
            command.append('-f')
        command.append(str(program))
        result = subprocess.run(command, cwd=ROOT, env=environment,
                                capture_output=True, text=True, timeout=30)
    assert result.returncode == 0, result.stdout + result.stderr
    assert 'unresolved= 0' in result.stdout, result.stdout
    assert 'Error.' not in result.stdout, result.stdout
    return result.stdout


def test_curve_and_palette_cycle():
    source = SOURCE.read_text().split(':Main .ENTRY Main')[0] + """
:Main .ENTRY Main
@PUSH 1 @SSET SegDS @PUSH RingOne @ADM
@CALL InitMemory
@PUSH GraphDS @SSET SegES
@Call(A) ClearWindow BackgroundColor
@Call(A) CyclePalette 0
@CALL DrawCurve
@PRT " pixels="
# (1,55), (120,165), (128,165), (239,55)
@PUSH 6600 @ESO @PUSHS @AND 0xff @PRTHEXTOP @POPNULL @PRT ","
@PUSH 19860 @ESO @PUSHS @AND 0xff @PRTHEXTOP @POPNULL @PRT ","
@PUSH 19864 @ESO @PUSHS @AND 0xff @PRTHEXTOP @POPNULL @PRT ","
@PUSH 6718 @ESO @PUSHS @SHR8 @PRTHEXTOP @POPNULL @PRTNL
@PRT " palette="
@PUSH 0xf842 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@Call(A) CyclePalette 1
@PUSH 0xf842 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@Call(A) CyclePalette 14
@PUSH 0xf842 @ESO @PUSHS @PRTHEXTOP @POPNULL @PRT ","
@PUSH 0xf85e @ESO @PUSHS @PRTHEXTOP @POPNULL @PRTNL
@END
"""
    for fast in (False, True):
        output = run_program(source, fast)
        assert ' pixels=000f,0011,0022,000f' in output, output
        assert ' palette=7c00,7d40,781f,3c1f' in output, output


def test_pixel_rows_and_neighbors():
    source = SOURCE.read_text().split(':Main .ENTRY Main')[0] + '''
:Main .ENTRY Main
@PUSH 1 @SSET SegDS @PUSH RingOne @ADM
@CALL InitMemory
@PUSH GraphDS @SSET SegES
@Call(AAA) SetPixel 0 0 1
@Call(AAA) SetPixel 1 0 2
@Call(AAA) SetPixel 2 1 3
@Call(AAA) SetPixel 3 1 4
@Call(AAA) SetPixel 5 50 5
@Call(AAA) SetPixel 239 191 6
@PRT " pixels="
@PUSH 0 @ESO @PUSHS @AND 0xff @PRTHEXTOP @POPNULL @PRT ","
@PUSH 121 @ESO @PUSHS @AND 0xff @PRTHEXTOP @POPNULL @PRT ","
@PUSH 6002 @ESO @PUSHS @AND 0xff @PRTHEXTOP @POPNULL @PRT ","
@PUSH 23038 @ESO @PUSHS @SHR8 @PRTHEXTOP @POPNULL @PRTNL
@END
'''
    for fast in (False, True):
        output = run_program(source, fast)
        assert ' pixels=0012,0034,0005,0006' in output, output


if __name__ == '__main__':
    test_curve_and_palette_cycle()
    test_pixel_rows_and_neighbors()
