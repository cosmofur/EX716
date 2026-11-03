# CPU24 event and console architectural verification

Verification date: 2026-11-03. This is an implementation audit, not an EXGC
hardware specification.

## 1. Event clock and dispatcher cost

The only implemented deadline clock is `VMEventState.instruction_count`.
`vm_events_after_instruction()` is called after every `step_once()` in both
native evaluators. There is no host-monotonic-clock call, allocation, Python
callback, or interrupt delivery in its normal path.

The retired-instruction counter advances after every successfully retired
instruction, including when no deadline is armed. It is not incremented for an
instruction that returns an execution error. `CAST End` and debug-toggle are
successfully executed terminating instructions and are counted before their
existing return code is preserved. Ctrl-C is observed between instructions, so
it retires no additional instruction.

With no deadline and no pending event, the per-instruction dispatcher work is
one out-of-line C call, a 64-bit increment, and a no-deadline branch. With
pending event flags, the service callback is invoked after every instruction
until it clears or consumes the flags. The default callback is absent and
therefore inexpensive, but a future device callback must clear/acknowledge
coalescible flags to avoid that repeated service cost.

## 2. Event-state lifetime

`speedCPU.c` owns process-global static `g_events` and `g_console` objects.
`g_events` is initialized when `cpuCfunc` is imported and persists across both
`EvalOne` and `EvalOne24` calls, including bounded calls. It is not part of the
Python CPU object or the tuples returned to Python.

Entering fast-mode debugger stepping continues to call `EvalOne24`, so it sees
the same global event state. Python-backend execution has no event dispatcher.
There is no emulator-reset integration: only the extension testing hook
`EventsReset()` clears event state. Therefore a future CPU reset must explicitly
reset device/event state, and an eventual multi-VM design cannot retain this
process-global ownership model.

Pending interrupt flags are separate from event flags and executor `RC_*`
values. They persist until a future owner clears them; no interrupt is delivered
in this change.

## 3. Console-buffer semantics

`g_console` is also process-global and persists across native calls until
`ConsoleReset()` or drain operations change it.

- `GUEST_TEXT` defaults to direct `stdout` output. Buffered mode instead uses
  an 8,192-byte byte ring; it emits nothing to the terminal.
- On a full ring, each new byte discards the oldest byte and increments the
  cumulative `guest_overflow` count. Draining does not reset that count;
  `ConsoleReset()` does.
- `ConsoleDrainGuest()` returns buffered bytes in oldest-to-newest order and
  removes them. `vm_console_flush_guest()` similarly drains to a caller-supplied
  stream.
- `vm_console_write()` accepts a pointer and explicit length, so it preserves
  NULs, escape sequences, and other binary data. CAST string commands remain
  NUL-terminated by their pre-existing guest semantics and retain their existing
  control-byte-to-hex rendering. `vm_console_printf()` is formatting-only and
  currently truncates a single formatted result to 127 bytes; current CAST
  numeric uses are safely smaller.
- `HOST_DIAGNOSTIC` and `DEBUGGER` write to `stderr` even when guest text is
  buffered. `VIDEO` writes to `stdout` unless suspended. The Ctrl-C signal
  handler bypasses this subsystem and uses async-signal-safe `write(2, ...)`.

## 4. Throughput result

`tests/benchmark_event_clock.py` runs the reproducible NOP benchmark after
`make -B DEBUG=0`, comparing no events with a coalescible native test event
every 1,024 retired instructions. Its measured results are recorded below after
the final optimized run. This compares operating modes of the corrected build;
it is not a historical pre-dispatch A/B regression measurement.

Final run on this host: three 50,000,000-NOP samples per mode, built with
`make -B DEBUG=0` (`-O2 -DNDEBUG`). No-event median throughput was
173.9 million instructions/second. Periodic-event median throughput was
164.9 million instructions/second, a 5.15% reduction under this deliberately
active 1,024-instruction cadence.
