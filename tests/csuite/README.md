# EX716 C regression suite

This suite tests C programs compiled for EX716 and executed by `cpu24.py`.
It deliberately targets the current machine model: 16-bit `int`, 32-bit
`long`, 16-bit near pointers, separate 64 KiB code and data segments, and no
floating-point support. Cases are small and self-contained; each defines
`int main(void)` and returns zero on success or a nonzero failure number.

Run from the EX716 repository root:

```sh
python3 tests/csuite/run.py
```

The runner invokes the sibling `lcc/build/rcc`, emits an assembly harness that
loads the EX716 runtime and compiler output, then gives that assembly to the
CPU24 loader. Use `--compiler /path/to/rcc` for another build, or `--filter`
to run paths containing a substring. No native executable is produced.

The initial cases are adapted from the kinds of focused tests in
`writing-a-c-compiler-tests`: arithmetic width and signedness, function calls,
local arrays/pointers, and aggregate parameter/return ABI behavior. Tests that
depend on hosted I/O, 64-bit `long`, floating point, or memory beyond the
current segment model are intentionally excluded until EX716 supports them.

## Persistent readiness audit

`run.py` remains the four-case historical smoke suite. It checks results in
CPU24 shared-memory mode; it does not establish complete C readiness or stack
balance. The separate audit reports unsupported features and coverage debt:

```sh
make -C ../lcc BUILDDIR=build rcc cpp
python3 tests/csuite/readiness.py --json /tmp/c-readiness.json \
  --artifacts /tmp/c-readiness-evidence
python3 tests/csuite/readiness.py --modes classic,cpu24,segmented \
  --compare tests/csuite/readiness-baseline.json
```

The default is genuinely segmented CPU24 execution. `features.json` contains
120 stable feature IDs and acceptance vectors. The original review baseline has
116 entries: 22 passing probes, 23 failures, 43 header-blocked entries and 28
planned fixtures. Four R01 rejection-safety probes were added afterward.
The audit returns 1 until every selected entry is PASS; use `--filter ID` for
a focused task. PASS describes the executed probe, not every unimplemented
acceptance vector. Missing and planned cases are never silently skipped.

Read [the implementation handoff](../../docs/c-implementation-handoff.md) for
exact methods, task order and pitfalls, or [the full review and permanent
plan](../../docs/c-readiness.md) for evidence, I/O contracts and fixture design.
