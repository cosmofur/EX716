"""Native EXGC instruction-clock timing and page-flip regression."""
import os
import numpy

import cpuCfunc


EXGC_BASE = 0xfc0000
VIDEO_TIMING = 0xf800
VIDEO_PAGE = 0xf802
VIDEO_FRAME = 0xf814
SCANLINE_INSTRUCTIONS = 256
VISIBLE_LINES = 192
RC_DEVICE_GENERAL_FAIL = -10

PUSH = 1
POPI = 8


def instruction(opcode, operand):
    return bytes((opcode, operand & 0xff, (operand >> 8) & 0xff))


def run(memory, stack, steps):
    return cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0xfc, 0, 1,
                               -1, steps, 0)


def read_word(memory, offset):
    return int(memory[EXGC_BASE + offset]) | (int(memory[EXGC_BASE + offset + 1]) << 8)


def run_test():
    memory = numpy.zeros(0x1000000, dtype=numpy.uint8)
    stack = numpy.zeros(0xff - 2, dtype=numpy.uint16)
    cpuCfunc.EXGCReset(memory)

    # Bounded calls share the same event clock and complete exactly one line.
    run(memory, stack, 128)
    assert read_word(memory, VIDEO_TIMING) == 0
    run(memory, stack, 128)
    assert read_word(memory, VIDEO_TIMING) == 1

    # Immediate select retains the Phase 2 ABI: displayed=requested, no pending.
    memory[:6] = numpy.frombuffer(instruction(PUSH, 2) + instruction(POPI, VIDEO_PAGE),
                                  dtype=numpy.uint8)
    result = run(memory, stack, 2)
    assert result[3] == 0
    assert read_word(memory, VIDEO_PAGE) == 3

    # A deferred request leaves page B displayed until VBlank starts.
    memory[:6] = numpy.frombuffer(instruction(PUSH, 4) + instruction(POPI, VIDEO_PAGE),
                                  dtype=numpy.uint8)
    result = run(memory, stack, 2)
    assert result[3] == 0
    assert read_word(memory, VIDEO_PAGE) == 9  # display B, request A, pending

    # We are two instructions into scanline 1. Advance to the 191->VBlank
    # boundary; the pending request must become visible exactly there.
    run(memory, stack, (VISIBLE_LINES - 1) * SCANLINE_INSTRUCTIONS - 260)
    assert read_word(memory, VIDEO_TIMING) == 191
    assert read_word(memory, VIDEO_PAGE) == 9
    run(memory, stack, SCANLINE_INSTRUCTIONS)
    assert read_word(memory, VIDEO_TIMING) == 0x80bf
    assert read_word(memory, VIDEO_PAGE) == 0  # display/request A, no pending

    # Completing VBlank wraps scanline and increments frame, independently of
    # rendering or the return-code path.
    run(memory, stack, (262 - VISIBLE_LINES) * SCANLINE_INSTRUCTIONS)
    assert read_word(memory, VIDEO_TIMING) == 0
    assert read_word(memory, VIDEO_FRAME) == 1

    # Host rendering is presentation only: it neither retires guest work nor
    # changes selected/current page state.  Suppress the binary SIXEL stream.
    before_timing = read_word(memory, VIDEO_TIMING)
    before_frame = read_word(memory, VIDEO_FRAME)
    before_page = read_word(memory, VIDEO_PAGE)
    saved_stdout = os.dup(1)
    null_stdout = os.open(os.devnull, os.O_WRONLY)
    try:
        os.dup2(null_stdout, 1)
        assert cpuCfunc.EXGCRender(memory, 1, 1) > 0
    finally:
        os.dup2(saved_stdout, 1)
        os.close(saved_stdout)
        os.close(null_stdout)
    assert read_word(memory, VIDEO_TIMING) == before_timing
    assert read_word(memory, VIDEO_FRAME) == before_frame
    assert read_word(memory, VIDEO_PAGE) == before_page

    # Explicit reset is the only reset of timing/page state.
    cpuCfunc.EXGCReset(memory)
    assert read_word(memory, VIDEO_TIMING) == 0
    assert read_word(memory, VIDEO_FRAME) == 0
    assert read_word(memory, VIDEO_PAGE) == 0

    # Odd MMIO remains a normal native execution failure, not an event return.
    memory[:6] = numpy.frombuffer(instruction(PUSH, 0) + instruction(POPI, VIDEO_TIMING + 1),
                                  dtype=numpy.uint8)
    result = run(memory, stack, 2)
    assert result[3] == RC_DEVICE_GENERAL_FAIL, result


if __name__ == "__main__":
    run_test()
