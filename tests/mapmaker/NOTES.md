# CPU24 disk-build handoff

## Current state

- `python3 cpu24_smoke.py` passes (`MAPMAKER_CPU24_RESULT=0`).
- `make test` passes for the host pipeline.
- `python3 cpu24_string_boundary.py` passes.  Its string begins at `0xffc0`,
  and its NUL terminator is at `DS:0xffff`; it intentionally does not test an
  ordinary address range.
- `python3 cpu24_disk.py --smoke` assembles and starts successfully, but still
  stops later with `Memory Error, while creating split string list.`

## Fixed boundary fault

`splitstr` used `PUSHS` followed by `AND 0xff` for character reads. `PUSHS` is
a 16-bit access, so it cannot read a byte at `0xffff`: it also attempts to
read `0x10000`. CPU24 now provides `PUSHB` (opcode 63), which replaces the
stack address with one byte and is valid at `DS:0xffff`. The string routines
that scan delimiters and `strlen` use it.

## Remaining disk-smoke investigation

The original error at `string.ld:1122` was resolved. The next failure happens
after the boundary scan, when `splitstr` calls `HeapNewObject` for its token
pointer array. Likely next checks:

1. Trace `SSCount`, `SplitLen`, and `HeapIn` immediately before that call. An
   unexpectedly large `SSCount` would mean delimiter scanning or the caller's
   data is still wrong; a sane count with a failed allocation points at DiskOS
   heap setup.
2. Trace `SetDiskHeap` / `HeapDefineMemory` and compare available heap space
   before the `splitstr` call with the requested `((SSCount + 1) * 2)` bytes.
3. Run `python3 cpu24_disk.py --smoke --cpu-debug`; CPU24 also has
   `--trace-tail 64`, which prints the final instruction history after a fatal
   emulator error.

Keep boundary regressions at `0xfff*` / `0xffff`; ordinary-index tests cannot
exercise this failure mode.
