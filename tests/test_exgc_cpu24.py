"""CPU24 native/Python EXGC shared-memory and MMIO smoke test."""
import numpy

import cpu24
import cpuCfunc

PUSH = 1
POPI = 8
EXGC_SEGMENT = 0xfc
EXGC_BASE = EXGC_SEGMENT << 16
VIDEO_PAGE = 0xf802
PALETTE0 = 0xf840
RC_DEVICE_GENERAL_FAIL = -10


def instruction(opcode, operand):
    return bytes((opcode, operand & 0xff, (operand >> 8) & 0xff))


def run():
    memory = numpy.zeros(0x1000000, dtype=numpy.uint8)
    stack = numpy.zeros(0xff - 2, dtype=numpy.uint16)
    cpuCfunc.EXGCReset(memory)
    assert int(memory[EXGC_BASE]) == 0
    # CPU24 writes VIDEO_PAGE through a normal aligned word store in DS=FC.
    program = instruction(PUSH, 2) + instruction(POPI, VIDEO_PAGE)
    memory[:len(program)] = numpy.frombuffer(program, dtype=numpy.uint8)
    result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, EXGC_SEGMENT, 0,
                                1, -1, 2, 0)
    assert result[3] == 0
    assert int(memory[EXGC_BASE + VIDEO_PAGE]) == 3
    # The Python device observes the same memory-backed state and writes palette
    # words in the same little-endian representation.
    device = cpu24.EXGCDevice(memory)
    assert device.read_word(EXGC_BASE + VIDEO_PAGE) == 3
    assert device.write_word(EXGC_BASE + PALETTE0, 0x801f)
    assert int(memory[EXGC_BASE + PALETTE0]) == 0x1f
    assert int(memory[EXGC_BASE + PALETTE0 + 1]) == 0x80
    try:
        device.byte_access(EXGC_BASE + VIDEO_PAGE)
    except ValueError:
        pass
    else:
        raise AssertionError("EXGC byte MMIO access was accepted")

    # Native odd-word MMIO writes are rejected rather than silently touching
    # the register bytes.
    memory.fill(0)
    cpuCfunc.EXGCReset(memory)
    program = instruction(PUSH, 0x1234) + instruction(POPI, VIDEO_PAGE + 1)
    memory[:len(program)] = numpy.frombuffer(program, dtype=numpy.uint8)
    result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, EXGC_SEGMENT, 0,
                                1, -1, 2, 0)
    assert result[3] == RC_DEVICE_GENERAL_FAIL, result


if __name__ == "__main__":
    run()
