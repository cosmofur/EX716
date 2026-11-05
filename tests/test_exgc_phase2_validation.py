"""Post-integration EXGC Phase 2 validation and optional SIXEL visual smoke.

The normal invocation is noninteractive: it runs the existing CPU24 assembly
fixture, tests native/Python MMIO agreement, and captures renderer output to a
temporary file.  ``--emit`` deliberately writes frames to the current terminal
for a human Windows Terminal check; it never changes terminal modes or starts
an automatic refresh loop.
"""
import argparse
import contextlib
import ctypes
import hashlib
import io
import os
from pathlib import Path
import sys
import tempfile
import time

import numpy

import cpu24
import cpuCfunc


ROOT = Path(__file__).resolve().parents[1]
ASSEMBLY = ROOT / "tests" / "exgc-phase2.asm"
EXGC_BASE = 0xfc0000
FRAME_A = EXGC_BASE
FRAME_B = EXGC_BASE + 0x5a00
VIDEO_PAGE = 0xf802
PALETTE = 0xf840
RC_DEVICE_GENERAL_FAIL = -10
PUSH, PUSHS, POPI = 1, 5, 8


def instruction(opcode, operand):
    return bytes((opcode, operand & 0xff, (operand >> 8) & 0xff))


def native_run(memory, program, ds=0xfc, es=0, override=-1, steps=None):
    """Run raw CPU24 instructions through the native path only."""
    stack = numpy.zeros(0xff - 2, dtype=numpy.uint16)
    memory[:len(program)] = numpy.frombuffer(program, dtype=numpy.uint8)
    if steps is None:
        steps = sum(1 for _ in range(1))  # caller normally supplies fixed code
    return cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, ds, es, 1,
                               override, steps, 0), stack


def run_assembly_fixture():
    """Use the actual assembler/fast executor and retain its populated CPU."""
    saved_argv = sys.argv[:]
    saved_cwd = os.getcwd()
    try:
        os.chdir(ROOT)
        sys.argv = ["cpu24.py", "-q", "-f", str(ASSEMBLY)]
        # @END terminates main by SystemExit after a normal native execution.
        with contextlib.redirect_stdout(io.StringIO()):
            try:
                cpu24.main()
            except SystemExit as exc:
                assert exc.code in (None, 0), exc.code
    finally:
        sys.argv = saved_argv
        os.chdir(saved_cwd)
    cpu = cpu24.CPU
    # These are real CPU24 DS=FC POPI stores in the assembly fixture.
    assert bytes(cpu.memspace[FRAME_A:FRAME_A + 2]) == b"\x34\x12"
    assert bytes(cpu.memspace[FRAME_B:FRAME_B + 2]) == b"\xcd\xab"
    assert cpu.exgc.read_word(EXGC_BASE + PALETTE) == 0x0000
    assert cpu.exgc.read_word(EXGC_BASE + PALETTE + 2) == 0x7c00
    assert cpu.exgc.read_word(EXGC_BASE + PALETTE + 30) == 0x7fff
    return cpu


def pixel_set(memory, base, x, y, color):
    address = base + y * 120 + x // 2
    original = int(memory[address])
    if x & 1:
        memory[address] = (original & 0xf0) | color
    else:
        memory[address] = (original & 0x0f) | (color << 4)


def write_pattern(memory, base, pattern):
    memory[base:base + 0x5a00] = 0
    for y in range(192):
        for x in range(240):
            if pattern == "bars":
                color = x * 16 // 240
            elif pattern == "checker":
                color = 15 if ((x // 8) ^ (y // 8)) & 1 else 1
            elif pattern == "diagonal":
                color = ((x + y) // 12) & 15
            else:
                raise ValueError(pattern)
            pixel_set(memory, base, x, y, color)


_libc = ctypes.CDLL(None)
_libc.fflush.argtypes = [ctypes.c_void_p]
_libc.fflush.restype = ctypes.c_int


def flush_c_stdio():
    """Flush C stdout; Python's sys.stdout.flush cannot flush vm_console."""
    assert _libc.fflush(None) == 0


@contextlib.contextmanager
def capture_c_stdout():
    """Capture C fwrite output, including a final C stdio flush."""
    flush_c_stdio()
    saved = os.dup(1)
    fd, name = tempfile.mkstemp(prefix="exgc-phase2-", suffix=".six")
    try:
        os.dup2(fd, 1)
        os.close(fd)
        yield name
        flush_c_stdio()
    finally:
        os.dup2(saved, 1)
        os.close(saved)


def capture_render(cpu, scale_x, scale_y):
    started = time.perf_counter()
    with capture_c_stdout() as name:
        reported = cpu.render_exgc(scale_x, scale_y)
    elapsed = time.perf_counter() - started
    stream = Path(name).read_bytes()
    os.unlink(name)
    assert reported == len(stream), (reported, len(stream))
    assert stream.startswith(b"\x1bPq") and stream.endswith(b"\x1b\\")
    raster = ('"1;1;%d;%d' % (240 * scale_x, 192 * scale_y)).encode()
    assert raster in stream
    return elapsed, stream


def validate_mmio(cpu):
    memory = cpu.memspace
    # Python segment override uses the same physical EXGC device/registers.
    cpu.SegmentMode, cpu.DS, cpu.segment_override = 1, 0x12, 0xfc
    cpu.putwordat(VIDEO_PAGE, 2)
    assert cpu.getwordat(VIDEO_PAGE) == 3
    assert bytes(memory[EXGC_BASE + VIDEO_PAGE:EXGC_BASE + VIDEO_PAGE + 2]) == b"\x03\x00"
    cpu.putwordat(PALETTE + 4, 0x801f)
    assert cpu.getwordat(PALETTE + 4) == 0x801f
    assert bytes(memory[EXGC_BASE + PALETTE + 4:EXGC_BASE + PALETTE + 6]) == b"\x1f\x80"
    assert cpu.exgc.read_word(EXGC_BASE + 0xf800) == 0
    assert cpu.exgc.write_word(EXGC_BASE + 0xf800, 0xbeef)
    assert cpu.exgc.read_word(EXGC_BASE + 0xf800) == 0
    for address in (EXGC_BASE + VIDEO_PAGE, EXGC_BASE + VIDEO_PAGE + 1):
        try:
            if address & 1:
                cpu.exgc.read_word(address)
            else:
                cpu.exgc.byte_access(address)
        except ValueError:
            pass
        else:
            raise AssertionError("Python EXGC device accepted invalid MMIO access")

    # Native ES override must hit EXGC; an ordinary DS must not.  ESO is an
    # actual CPU24 one-instruction segment prefix, not a host-side shortcut.
    memory.fill(0)
    cpuCfunc.EXGCReset(memory)
    result, _ = native_run(memory, instruction(PUSH, 2) + bytes((58,)) +
                           instruction(POPI, VIDEO_PAGE),
                           ds=0x12, es=0xfc, steps=3)
    assert result[3] == 0 and int(memory[EXGC_BASE + VIDEO_PAGE]) == 3
    result, _ = native_run(memory, instruction(PUSH, 0xbeef) + instruction(POPI, 0xf800),
                           ds=0x12, override=-1, steps=2)
    assert result[3] == 0
    assert bytes(memory[0x12 << 16 | 0xf800:0x12 << 16 | 0xf802]) == b"\xef\xbe"
    assert cpu24.EXGCDevice(memory).read_word(EXGC_BASE + 0xf800) == 0

    # Palette readback is native MMIO, not merely NumPy backing-memory access.
    program = (instruction(PUSH, 0x801f) + instruction(POPI, PALETTE) +
               instruction(PUSH, PALETTE) + bytes((PUSHS,)))
    result, stack = native_run(memory, program, override=0xfc, steps=4)
    assert result[3] == 0 and int(stack[0]) == 0x801f
    assert bytes(memory[EXGC_BASE + PALETTE:EXGC_BASE + PALETTE + 2]) == b"\x1f\x80"
    result, stack = native_run(memory, instruction(PUSH, 0xf800) + bytes((PUSHS,)),
                               override=0xfc, steps=2)
    assert result[3] == 0 and int(stack[0]) == 0
    result, _ = native_run(memory, instruction(PUSH, VIDEO_PAGE + 1) + bytes((PUSHS,)),
                           override=0xfc, steps=2)
    assert result[3] == RC_DEVICE_GENERAL_FAIL


def run_automated(cpu):
    validate_mmio(cpu)
    outputs = {}
    for scale in ((3, 2), (6, 3)):
        for page, base in (("A", FRAME_A), ("B", FRAME_B)):
            cpu.putwordat(EXGC_BASE + VIDEO_PAGE, 2 if page == "B" else 0)
            for pattern in ("bars", "checker", "diagonal"):
                write_pattern(cpu.memspace, base, pattern)
                elapsed, stream = capture_render(cpu, *scale)
                outputs[(scale, page, pattern)] = (elapsed, len(stream),
                                                    hashlib.sha256(stream).hexdigest())
    # A and B are rendered through the selected-page register, and the three
    # patterns differ structurally at both requested scales.
    for scale in ((3, 2), (6, 3)):
        hashes = {outputs[(scale, "A", pattern)][2]
                  for pattern in ("bars", "checker", "diagonal")}
        assert len(hashes) == 3
        for pattern in ("bars", "checker", "diagonal"):
            assert outputs[(scale, "A", pattern)][2] == outputs[(scale, "B", pattern)][2]
    return outputs


def emit_visual(cpu, scale, frames, cursor_home, in_place):
    """Explicit manual terminal test; no alternate screen or terminal mode changes."""
    patterns = ("bars", "checker", "diagonal")
    if in_place:
        cpu.start_exgc_display()
    try:
        for frame in range(frames):
            pattern = patterns[frame % len(patterns)]
            page, base = (("A", FRAME_A), ("B", FRAME_B))[frame & 1]
            write_pattern(cpu.memspace, base, pattern)
            cpu.putwordat(EXGC_BASE + VIDEO_PAGE, 2 if page == "B" else 0)
            if cursor_home and not in_place:
                sys.stdout.write("\x1b[H")
                sys.stdout.flush()
            started = time.perf_counter()
            size = cpu.render_exgc(*scale)
            flush_c_stdio()
            print("EXGC visual frame %d: page %s, %s, %dx%d, %d bytes, %.2f ms" %
                  (frame + 1, page, pattern, scale[0], scale[1], size,
                   (time.perf_counter() - started) * 1000), file=sys.stderr)
    finally:
        if in_place:
            cpu.stop_exgc_display()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--emit", action="store_true", help="write visual frames to stdout")
    parser.add_argument("--scale", default="3x2", choices=("3x2", "6x3"))
    parser.add_argument("--frames", type=int, default=3)
    parser.add_argument("--cursor-home", action="store_true",
                        help="emit CSI H before each explicit frame")
    parser.add_argument("--in-place", action="store_true",
                        help="use the host in-place EXGC display session")
    args = parser.parse_args()
    assert args.frames > 0
    cpu = run_assembly_fixture()
    results = run_automated(cpu)
    print("EXGC Phase 2 validation passed: %d selected-page render cases" % len(results))
    for scale in ((3, 2), (6, 3)):
        cases = [results[(scale, page, pattern)] for page in ("A", "B")
                 for pattern in ("bars", "checker", "diagonal")]
        print("  %dx%d: %.2f..%.2f ms, %d..%d bytes" %
              (scale[0], scale[1], min(c[0] for c in cases) * 1000,
               max(c[0] for c in cases) * 1000,
               min(c[1] for c in cases), max(c[1] for c in cases)))
    if args.emit:
        # Preserve host-text/video ordering when stdout is redirected or pipe
        # buffered: vm_console VIDEO uses C stdio, not Python's TextIO buffer.
        sys.stdout.flush()
        x, y = (int(value) for value in args.scale.split("x"))
        emit_visual(cpu, (x, y), args.frames, args.cursor_home, args.in_place)


if __name__ == "__main__":
    main()
