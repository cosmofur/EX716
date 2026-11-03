"""Native CPU24 event-clock throughput benchmark.

Run after `make -B DEBUG=0`.  It uses a zero-filled instruction stream (NOP)
and compares no scheduled events with a coalescible periodic native test event.
"""
import statistics
import time

import numpy

import cpuCfunc

COUNT = 50_000_000
REPEATS = 3
VM_EVENT_TIMER = 1


def run(period):
    memory = numpy.zeros(0x1000000, dtype=numpy.uint8)
    stack = numpy.zeros(0xff - 2, dtype=numpy.uint16)
    rates = []
    for _ in range(REPEATS):
        cpuCfunc.EventsReset()
        if period is not None:
            cpuCfunc.EventsSetPeriodicTest(period, VM_EVENT_TIMER)
        start = time.monotonic()
        result = cpuCfunc.EvalOne24(memory, stack, 0, 0, 0, 0, 0, 0, 0,
                                    -1, COUNT, 0)
        elapsed = time.monotonic() - start
        assert result[3] == 0
        assert cpuCfunc.EventsStatus()[2] == COUNT
        if period is not None:
            assert cpuCfunc.EventsPeriodicTestCount() == COUNT // period
        rates.append(COUNT / elapsed)
    return statistics.median(rates)


if __name__ == "__main__":
    print("Build condition: make -B DEBUG=0 (-O2 -DNDEBUG)")
    print(f"NOP count per sample: {COUNT}; samples: {REPEATS}")
    no_event = run(None)
    periodic = run(1024)
    print(f"No event: {no_event:.1f} instructions/s")
    print(f"Periodic event (every 1024 retired instructions): {periodic:.1f} instructions/s")
    print(f"Periodic delta: {(periodic / no_event - 1.0) * 100.0:.2f}%")
