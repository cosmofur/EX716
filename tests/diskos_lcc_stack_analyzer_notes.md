# DiskOS/lcc stack analyzer findings

## Verified runtime conventions

- `@StackDump` reports `hwstacksp` and reads values from the hardware stack.
  It does not report the DS software stack pointer `__DSS_SP`.
- Near `@CALL`/`@RET` paths use a one-word return PC. In the DS soft-stack
  configuration, `@PUSHRETURN` calls `__DSS_MOVE_HW_SS` to move that word
  off the hardware stack; `@POPRETURN` restores it before `@RET` consumes it.
- `@FCALL` supplies a two-word CS:PC return pair. `@FENTER` saves the pair in
  the root record's far-return area; `@FRET` restores it and `@FJMPS` consumes
  it. The auto-bank veneer also turns some near calls into a far gateway,
  which can emit its own `FENTER`/`FRET` snapshots.
- In `cpu24.py`, `FindWhatLineInfo` maps the physical address selected by
  current CS to source metadata. A veneer instruction can therefore execute
  at one CS:PC while carrying source metadata inherited from the first macro
  callsite. Source line alone is not a function identity.

## Finding in the current raw trace

`/tmp/ex716-all-function-current-run.log` contains repeated snapshots at
`CS:PC 00:e0bd`, `00:e10c`, `00:e156`, and `00:e1a5`, all attributed to
`diskos.ld:528` or `diskos.ld:530`. Those are the auto-bank/helper paths used
by the software-stack move routines; they are not repeated executions of
`SetDiskHeap`. The actual SetDiskHeap body is at `CS:05`, with one observed
entry/exit pair (`05:109a`/`05:10c4`). Its one argument is removed and its
normal/error contract is zero return words. The previous 2,255 count and
return value 7 were false source-line attributions.

The repaired `build_diskos_call_csv.py` uses runtime CS:PC in addition to
source metadata and requires strict LIFO name matching. It no longer assigns
shared veneer snapshots to `SetDiskHeap`. The summary output count is the
hardware-stack delta from the baseline computed using the declared argument
count and return-address size; nested callees' leaks are therefore visible
in their callers' deltas. The current log does not record a snapshot
immediately before each caller pushes arguments, so an independent runtime
count of supplied arguments cannot be recovered from stack depth alone. The
`actual_input_arguments_seen` and per-invocation `actual_arguments_observed`
fields are left empty instead of repeating the declared arity.

Some far-gateway and tail-jump paths do not have a matching ordinary
`@POPRETURN` event. These must remain diagnostics/unsupported cases rather
than being paired to an older same-named invocation. A complete invocation
table requires symbol-address ranges from the exact assembled image; the raw
text trace does not serialize that symbol map.

## Duplicate `memcpy` symbols and corrected contracts

- The linker-visible C wrapper is `c_runtime_stubs.ld::memcpy`. It calls the
  internal alias `__ex716_memcpy` and then pushes `Dst`, so it returns one
  word as required by C. It ran 39 times and returned one word each time.
- The implementation is `string.ld::memcpy`. It performs the byte copy and
  returns no stack value. It ran 39 times and returned zero words each time.
  The 39 apparent memcpy mismatches were caused by collapsing these separate
  functions under the same name; both implementations match their contracts.
- The wrapper's 39 returned destination pointers are called from three
  assembly functions documented/implemented as void: `DirEntryToArgTable`
  (34 calls), `DirArgTableToEntry` (4), and `DiskSetFileName` (1). Those
  callsites do not discard the wrapper result. The parent invocations
  consequently show one extra word each. This accounts for the 39 repeated
  copy-related caller deltas; it is a caller cleanup issue, not a defect in
  the internal copy loop.
- Corrected other stale contracts from source: `HeapDSDefineMemoryFar` takes
  two arguments (the caller pushes two words) and returns one; `FSFindFile`
  returns one `FileNum|0` value. Its first run matches; two later runs have a
  one-word excess. `DirNewArgTable` and `DiskNewBuffer` take no arguments and
  each return one pointer. `DirReadEntry` returns one status word.
- `DiskFindFreeBlock` pushes `Result` once but its exit snapshot has two words
  above the entry baseline. The extra word is `0x908a`, the allocated map
  pointer. Its child `DirReadEntry`/`DirEntryToArgTable` path has the
  copy-wrapper residue described above, which is the leading explanation for
  that excess. No DiskOS or runtime source was changed during this audit.
