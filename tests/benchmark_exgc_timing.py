"""Measure native NOP throughput with Phase 3 EXGC scanline events on/off."""
import statistics
import time

import numpy
import cpuCfunc


COUNT = 50_000_000
SAMPLES = 3


def measure(enabled):
    values = []
    for _ in range(SAMPLES):
        memory = numpy.zeros(0x1000000, dtype=numpy.uint8)
        stack = numpy.zeros(0xff - 2, dtype=numpy.uint16)
        cpuCfunc.EventsReset()
        cpuCfunc.EXGCReset(memory)
        cpuCfunc.EXGCTimingTestEnabled(enabled)
        started = time.perf_counter()
        result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 1,
                                    -1, COUNT, 0)
        elapsed = time.perf_counter() - started
        assert result[3] == 0
        values.append(COUNT / elapsed)
    return statistics.median(values)


def main():
    disabled = measure(False)
    enabled = measure(True)
    cpuCfunc.EXGCTimingTestEnabled(True)
    print("EXGC timing benchmark: make -B DEBUG=0 (-O2 -DNDEBUG)")
    print("NOP count per sample: %d; samples: %d" % (COUNT, SAMPLES))
    print("Timing disabled: %.1f instructions/s" % disabled)
    print("Timing enabled (one scanline event/256 instructions): %.1f instructions/s" % enabled)
    print("Timing delta: %.2f%%" % ((enabled / disabled - 1.0) * 100.0))


if __name__ == "__main__":
    main()
