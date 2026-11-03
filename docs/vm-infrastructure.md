# CPU24 event and console infrastructure

This document describes emulator infrastructure shared by future devices. It
does not specify EXGC registers, graphics, SIXEL, or CPU interrupt entry.

## Audit (2026-11-03)

`speedCPU.c` has two native execution entry points: `c_EvalOne` for the
legacy 64 KiB model and `c_EvalOne24` for CPU24's 16 MiB memory. Both borrow
NumPy arrays, install `handle_ctrl_c`, and run `step_once` until its signed
return code is nonzero or a bounded instruction count is exhausted. CPU state
is returned as a tuple; CPU24 additionally returns CS, DS, ES, segmented-mode,
and segment-override state. `steps == -1` is unlimited; positive `steps` is a
bounded run. Ctrl-C sets `sig_atomic_t` state and uses `write(2, "^C\\n", 3)`,
which stays async-signal-safe and bypasses the console abstraction.

There was no timing or event dispatcher. `step_once` directly returned signed
`RC_*` stop/error values. Fast-mode CAST wrote guest text to stdout with
`printf`/`putchar`; CAST error text, stack dumps, unknown-opcode reports, and
TTY state diagnostics used stderr. Disk/tape `fwrite` calls are device file I/O
and intentionally remain outside the console layer.

In `cpu24.py`, `optCAST` uses `sys.stdout.write` for guest text and
`safeprint(..., file=DebugOut)` for guest error text. `print`, `safeprint`, and
direct stdout writes also cover assembler diagnostics, debugger prompts/traces,
cross-check reports, and general command-line status. File-object `.write()`
calls include disk/tape, generated assembly, and EXC01 output. Those Python
paths are audited but deliberately unchanged in this phase: only native
fast-mode CAST guest text is centralized.

## Events

`vm_events` keeps `pending_events` and `pending_interrupts` separate from
executor return codes. Events are coalescible flags; a future device that must
count every occurrence must own a counter or queue. `vm_events_schedule_after`
uses an instruction-count deadline and has no host-clock call in the normal
path. The retired-instruction counter advances after every successfully retired
instruction, even with no deadline armed. Its initial fixed eight-slot
scheduler supports distinct deadlines without allocating; when full it makes a
new event pending immediately rather than dropping it. A zero-delay event is
made pending immediately and serviced at the next instruction boundary.

The C loops invoke the service point after each executed instruction in both
bounded and unlimited runs. A service failure maps to `RC_EVENT_SERVICE_FAIL`
only when the instruction returned zero. An instruction's existing `RC_*`
value always has priority. Pending interrupts are stored but deliberately not
delivered: CPU24 interrupt vectors, stack frames, and opcodes remain undefined.

The extension exposes `EventsReset`, `EventsScheduleAfter`, and `EventsStatus`
for focused tests and future native-device wiring. These configure only
coalescible event flags; they do not deliver interrupts.

## Console

`vm_console` provides `GUEST_TEXT`, `HOST_DIAGNOSTIC`, `VIDEO`, and
`DEBUGGER` channels. In direct mode guest text still goes to stdout and host
diagnostics to stderr. Buffered guest mode uses an 8 KiB ring buffer; oldest
bytes are discarded on overflow and counted. The extension exposes
`ConsoleSetGuestBuffered`, `ConsoleDrainGuest`, `ConsoleStatus`, and
`ConsoleReset` for an eventual display frontend. Video suspension is a policy
hook only; no renderer exists here.

The console accepts byte spans, so guest control characters and escapes are
not transformed. It does not own disk, tape, generated-file, or signal-handler
I/O.
