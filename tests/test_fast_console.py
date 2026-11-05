"""Fast-mode CAST console routing smoke test.

The instruction sequence pushes CastPrintChar, executes CAST on byte 0x0100,
then executes CastEnd.  The test asserts that guest output is capturable and
that normal return handling remains unchanged.
"""
import os
import pty
import select
import subprocess
import fcntl
import struct
import termios
import sys

import numpy

import cpuCfunc

OPT_PUSH = 1
OPT_CAST = 42
CAST_PRINT_CHAR = 6
CAST_END = 99
RC_END_PROGRAM = -1
RC_DEVICE_GENERAL_FAIL = -10
VM_EVENT_TIMER = 1
VM_EVENT_DEVICE = 2


def instruction(opcode, operand):
    return bytes((opcode, operand & 0xff, (operand >> 8) & 0xff))


def execute(buffered):
    memory = numpy.zeros(0x1000000, dtype=numpy.uint8)
    stack = numpy.zeros(0xff - 2, dtype=numpy.uint16)
    program = instruction(OPT_PUSH, CAST_PRINT_CHAR)
    program += instruction(OPT_CAST, 0x0100)
    program += instruction(OPT_PUSH, CAST_END)
    program += instruction(OPT_CAST, 0)
    memory[:len(program)] = numpy.frombuffer(program, dtype=numpy.uint8)
    memory[0x0100] = ord("Z")

    cpuCfunc.ConsoleReset()
    cpuCfunc.ConsoleSetGuestBuffered(buffered)
    cpuCfunc.EventsReset()
    cpuCfunc.EventsScheduleAfter(1, VM_EVENT_TIMER)
    result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0)
    assert result[3] == RC_END_PROGRAM, result
    assert cpuCfunc.EventsStatus()[0] == VM_EVENT_TIMER
    assert cpuCfunc.EventsStatus()[2] == 4  # CAST End itself retired.
    if buffered:
        assert cpuCfunc.ConsoleDrainGuest() == b"Z"
        assert cpuCfunc.ConsoleStatus() == (0, 0)
        cpuCfunc.ConsoleSetGuestBuffered(False)
    return memory, stack


def execute_guest_char_without_console_reset():
    """Emit one CAST byte using whichever console policy is already active."""
    memory = numpy.zeros(0x1000000, dtype=numpy.uint8)
    stack = numpy.zeros(0xff - 2, dtype=numpy.uint16)
    program = instruction(OPT_PUSH, CAST_PRINT_CHAR) + instruction(OPT_CAST, 0x0100)
    memory[:len(program)] = numpy.frombuffer(program, dtype=numpy.uint8)
    memory[0x0100] = ord("Z")
    result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0, -1, 2, 0)
    assert result[3] == 0, result


def read_pty(master):
    chunks = []
    while select.select([master], [], [], 0.05)[0]:
        try:
            chunk = os.read(master, 65536)
        except BlockingIOError:
            break
        if not chunk:
            break
        chunks.append(chunk)
    return b"".join(chunks)


def test_in_place_video_console():
    """Exercise save/home/re-home/restore without requiring a real terminal."""
    master, slave = pty.openpty()
    saved_stdout = os.dup(1)
    memory = numpy.zeros(0x1000000, dtype=numpy.uint8)
    try:
        os.dup2(slave, 1)
        os.close(slave)
        cpuCfunc.ConsoleReset()
        cpuCfunc.EXGCReset(memory)
        cpuCfunc.ConsoleVideoDisplayStart()
        execute_guest_char_without_console_reset()
        cpuCfunc.EXGCRender(memory, 1, 1)
        cpuCfunc.EXGCRender(memory, 1, 1)
        # A resize with reported pixel dimensions too small rejects a later
        # frame before it can scroll normal-screen history.
        fcntl.ioctl(1, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 100, 100))
        try:
            cpuCfunc.EXGCRender(memory, 1, 1)
        except RuntimeError as error:
            assert "viewport" in str(error)
        else:
            raise AssertionError("too-small terminal viewport accepted an EXGC frame")
        cpuCfunc.ConsoleVideoDisplayStop()
        stream = read_pty(master)
    finally:
        os.dup2(saved_stdout, 1)
        os.close(saved_stdout)
        os.close(master)
        cpuCfunc.ConsoleReset()
    assert stream.startswith(b"\x1b[s\x1b[H"), stream[:16]
    assert stream.count(b"\x1bPq") == 2
    assert stream.count(b"\x1b[H") == 2  # start plus second frame only
    assert b"\x1b[uZ" in stream  # restored cursor, then deferred CAST


def run():
    memory, stack = execute(True)

    # Bounded runs reach the same service point, and an instruction error wins
    # over independently pending hardware work.
    memory.fill(0)
    memory[0] = 255
    cpuCfunc.EventsReset()
    cpuCfunc.EventsScheduleAfter(1, VM_EVENT_TIMER)
    result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0)
    assert result[3] == RC_DEVICE_GENERAL_FAIL, result
    assert cpuCfunc.EventsStatus() == (0, 0, 0)

    # No-event instructions always advance the persistent retired clock.
    memory.fill(0)
    cpuCfunc.EventsReset()
    result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0, -1, 1000, 0)
    assert result[3] == 0 and cpuCfunc.EventsStatus() == (0, 0, 1000)
    cpuCfunc.EventsScheduleAfter(3, VM_EVENT_TIMER)
    cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0, -1, 2, 0)
    assert cpuCfunc.EventsStatus() == (0, 0, 1002)
    cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0)
    assert cpuCfunc.EventsStatus() == (VM_EVENT_TIMER, 0, 1003)

    # Same-deadline flags coexist, and zero-delay scheduling is immediately
    # pending for the next instruction-boundary service point.
    cpuCfunc.EventsReset()
    cpuCfunc.EventsScheduleAfter(2, VM_EVENT_TIMER)
    cpuCfunc.EventsScheduleAfter(2, VM_EVENT_DEVICE)
    cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0, -1, 2, 0)
    assert cpuCfunc.EventsStatus() == (VM_EVENT_TIMER | VM_EVENT_DEVICE, 0, 2)
    cpuCfunc.EventsReset()
    cpuCfunc.EventsScheduleAfter(0, VM_EVENT_TIMER)
    assert cpuCfunc.EventsStatus() == (VM_EVENT_TIMER, 0, 0)

    direct = subprocess.run([sys.executable, __file__, "--direct-child"],
                            check=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    assert direct.stdout == b"Z", direct.stdout
    test_in_place_video_console()


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--direct-child":
        execute(False)
    else:
        run()
