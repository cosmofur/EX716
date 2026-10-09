# EX716 C implementation handoff for an economical AI model

Read this document first. It tells you how to reproduce the review, choose a
bounded task, and prove a repair. Read the larger
[readiness report](c-readiness.md) only for the item you are implementing.
Do not repeat the whole architecture review at the start of every task.

## Objective and boundaries

Make the existing sibling lcc backend reliable for practical integer C on
EX716, then add console and file I/O. Preserve existing assembly applications
and unrelated worktree changes. Improve the existing tests and stable checklist;
do not replace them with a new testing strategy each session.

The working layout is:

```text
personal/
  lcc/                 compiler frontend, EX716 backend, cpp and build tools
  EX716/               emulators, assembly runtimes, docs, C audit
    tests/csuite/
      run.py           historical four-case smoke suite
      readiness.py     repeatable capability audit
      features.json    permanent feature IDs and acceptance requirements
      readiness-baseline.json  immutable review checkpoint
```

Both directories are separate Git repositories. Start by reading
`EX716/AGENTS.md` and `EX716/.codex/session-state.md`, checking each worktree,
and confirming the baseline against current code. The session notes can be
stale. This environment is WSL1: sandbox commands may require escalation solely
because the sandbox launcher cannot create user namespaces. That is an
environment issue, not a compiler failure.

Current target: eight-bit bytes, signed plain char, 16-bit int/short/pointers,
32-bit long, little-endian, near DS pointers. CPU24 has more physical memory,
but the C backend still has a 64 KiB near-data address space. Initial scope is
an explicit integer C subset, not complete ISO C, C99/C11, or a hosted platform.
Floating-point/64-bit execution can wait; unsupported operations must reject.

## Reproduce the actual tests

Run from `personal/EX716`:

```sh
make -C ../lcc BUILDDIR=build rcc cpp
python3 tests/csuite/run.py
python3 tests/csuite/readiness.py --json /tmp/c-readiness-current.json \
  --artifacts /tmp/c-readiness-evidence
```

The readiness command defaults to CPU24 with **CS=0, DS=1, segmented mode
enabled**. The old suite's CPU24 execution uses shared memory. They are not
equivalent tests.

The initial review's segmented checkpoint has 116 entries: 22 PASS, 23 FAIL,
43 MISSING, 28 NOT_TESTED. Four R01 safety probes have since been added; the
current manifest has 120 entries. The post-R01 segmented audit reports 26 PASS,
23 FAIL, 43 MISSING, 28 NOT_TESTED: all original rows retain their baseline
status and the four new safe-rejection checks pass. The pre-R01 all-mode run
gave 66 PASS, 69 FAIL, 129 MISSING, 84 NOT_TESTED across three modes. Full
post-R01 report and evidence are in `/tmp/ex716-r01-full.json` and
`/tmp/ex716-r01-full/`. The original four-case smoke suite passes despite the
remaining compiler feature failures.

Those counts are the post-R01 checkpoint. The active manifest now has 135
entries, including dense-switch acceptance, `SYS-004`/`SYS-005` stack
coverage, initial C adapters, and focused integer-formatting vectors. The
immutable baseline remains 116 entries. At the 2026-10-06 checkpoint, the
post-R09 segmented audit reports 75 PASS, 23 FAIL, 9 MISSING, and 28 NOT_TESTED; the
historical smoke suite passes 4/4.

Audit exit 1 is expected while backlog remains. It means at least one selected
entry is not PASS; it does not mean the runner itself crashed. Missing tools
produce argument error exit 2. Use a specific feature filter while repairing it:

```sh
python3 tests/csuite/readiness.py --filter LANG-016 \
  --modes classic,cpu24,segmented --jobs 1 \
  --json /tmp/c-shadowing.json --artifacts /tmp/c-shadowing-evidence

python3 tests/csuite/readiness.py \
  --compare tests/csuite/readiness-baseline.json \
  --json /tmp/c-readiness-after.json
```

`--filter` selects ID substrings; repeat it to select several IDs. It does not
select source filename substrings. For example:

```sh
python3 tests/csuite/readiness.py --filter LANG-001 --filter LANG-002 \
  --modes classic,cpu24,segmented
```
`--jobs 1` gives serial execution. Each stage has its own timeout, default 60
seconds. A timeout affects one row and the runner continues. For final
compatibility, use `--modes classic,cpu24,segmented` on the whole audit.

If a C ABI runtime adapter has been added, supply
`--runtime /absolute/path/to/c_runtime.ld`; repeat for additional adapters.
The default target include directory is `personal/lcc/include/ex716`, which is
currently absent. Do not redirect it to host system headers to hide failures.

### What a probe actually proves

The runner performs these checks in order:

1. Bundled `lcc/build/cpp -N` preprocesses the C source using only the explicit
   target include path and defines `__EX716__`. This prevents host-header leaks.
2. `rcc -target=ex716` emits assembly. Compiler exit and known unsupported
   backend diagnostics are checked independently; R01 makes the audited
   unsupported backend paths exit nonzero. A new unsupported path discovered
   later must be added to the explicit rejection checks rather than accepted
   because assembly was emitted.
3. A small assembly harness includes runtime helpers, sets the test entry,
   optionally enables separate DS, and calls int `main(void)`.
4. The selected CPU loads/executes it. Unresolved symbols, emulator failure or
   timeout fail the row, even if execution continues.
5. Exactly one result marker must report zero; requested program output must
   match; software SP must be restored to 0xfff2, C FP to zero, and the hardware
   stack must be empty after removing the result. Stack diagnostics are on
   stderr, not necessarily stdout.

Tests run in separate temporary directories with CPUPATH pointed at this
checkout's libraries. The harness is for small probes and reserves its entry
at 0x7000; it is not production crt0 or a large-program memory layout.

Read failure stages before touching code:

| Stage/status | First useful evidence | Typical repair area |
| --- | --- | --- |
| preprocess/MISSING | `unit*.cpp.stderr` | Target header/include setup; function has not been runtime-tested. |
| compile/FAIL | `unit*.compiler.stderr` | Frontend constraint or backend frame limit. |
| codegen/FAIL | Diagnostic and `unit*.asm` | Unsupported IR, silent omission, unsafe unit symbol collision. |
| assemble/FAIL | Missing symbol list and harness | Global allocation, imports/dependencies, label identity. |
| execute/FAIL or TIMEOUT | CPU stdout/stderr | Bad branch/call, fatal memory/stack state, wrong entry, loop. |
| result/output/FAIL | C return number and output | Value semantics; use assertion code to isolate the subcase. |
| abi/FAIL | Stack/frame markers and stack dump | Argument/result cleanup or frame restoration. |
| coverage/NOT_TESTED | Manifest acceptance list | Implement the planned fixture; this is not a passed feature. |

Artifacts are organized as `<artifacts>/<feature-ID>/<mode>/`. Inspect only the
failing case's source, preprocessed source, generated assembly and logs. The
JSON records statuses, tool identities and input hashes. A PASS certifies the
probe, not every acceptance vector listed for the whole feature.

## Critical-path order

Use the R identifiers below to find the matching evidence and implementation
packet in `c-readiness.md`. Complete one bounded change before taking the next.

| Order | Task | Tests and concrete starting point |
| ---: | --- | --- |
| 1 | R01: reliable rejection of unsupported code — complete | `lcc/src/ex716.c`: `ex716_emit_expr`, assignment/call/jump emitters and `I(emit)`. `SAFE-unsupported-*` verify nonzero diagnostic in all modes. Compile failures now report relevant EX716 backend diagnostics first. Existing LANG-014/025/029/030/034/035 remain feature failures until implemented. |
| 2 | R02: unique local aliases — complete | `LANG-015/016/017` across all modes. Aliases use function plus per-function Symbol ID; parameter views share identity; derived offset aliases do not allocate storage. |
| 3 | R03: 16-bit division correctness — complete | `EX716/lib/div.ld`; expanded `MATH-div16-signed`, `MATH-mod16-signed`, `MATH-div16-high` pass all modes. Dividend and quotient signs are tracked independently; DIVU uses unsigned less-than for subtract/skip. Preserve `[remainder, quotient]`. `IF_UGE_S` is corrected in both structure macro libraries to skip on unsigned `JULT`; boundary cases pass classic and CPU24 tests. |
| 4 | R04: signed ptrdiff — complete for near pointers | `LANG-018`, `MEM-pointer-negative/positive` pass all modes. Backend compares 16-bit offsets unsigned, applies byte/int/long stride and signs the result without 32-bit math. Cross-segment/far-pointer arithmetic remains unsupported. |
| 5 | R05: aggregates — implementation complete for tested local ABI | `LANG-005/029/030` pass all modes with stack/frame checks. Block ASGN copies exact addresses for 1–4-byte values; 6-byte hidden-result return and aggregate argument use overlap-safe internal copy. Public C `memcpy` and broader ABI certification remain separate. |
| 6 | R06: data emission — implemented for current acceptance vectors | `LANG-019` through `024` cover initialized locals/globals, zero-fill, initialized statics, strings/escapes, arrays/structs, and object/function/offset addresses. `::` output follows the active assembler data cursor; segmented harness selects `.DATA 1`; all cases pass with CS != DS. Floating initializers are explicitly rejected; R08 still owns cross-unit linkage. |
| 7 | R08 current combiner profile implemented; R11 foundations; R10 accepted | `LANG-032/033` pass with automatically namespaced private symbols and unchanged external names. `SYS-002` remains the production build/combiner fixture. Continue `HEADER-limits/errno`. R10 uses a default 4-KiB adjustable software stack with checked frame reservations (`LANG-028`, `SYS-004/005`). |
| 8 | R07: variadic ABI — implemented for current acceptance subset | `LANG-026/027` and `HEADER-stdarg` pass all three modes. Caller-owned packet: 16-bit payload-byte count followed by promoted scalar/pointer items in argument order; a hidden descriptor pointer follows named parameters. Fixed calls keep their existing ABI. `stdarg.h` traverses with `va_start`/`va_arg`/`va_end`. Aggregates, floats, frames above the current 256-byte backend limit and multi-unit helper linkage remain unsupported/unverified; continue with IO-v* only after checking these boundaries. |
| 9 | Console and formatting | HEADER-stdio, IO-putchar/getchar/puts/fputc/fgetc/fputs/fgets/fflush/feof/ferror/clearerr, then IO-printf/snprintf and v forms. Use a shared stream core and formatting engine. |
| 10 | String/heap adapters and file I/O | Initial `fopen`/`fclose`/`fread`/`fwrite` adapters now map to DiskOS. Add isolated disk fixtures for semantic certification, then implement positioning. |
| 11 | R09 complete for near code pointers; optional breadth remains | `LANG-014/025` pass: dense switches and indirect calls, including callbacks and variadic function pointers. Far calls remain outside the profile. Continue hosted I/O and optional R12 float/64-bit support. |

The order is a dependency guide, not permission to combine everything in one
patch. For example, scalar global+BSS emission can be one task, while literals
and relocations are subsequent tasks under the same R06 umbrella.

Initial R01 success means unsupported operations reject safely. Their feature
rows will still FAIL at compile stage until actual support is implemented.
That is progress in safety, not a reason to mark them PASS or suppress them.

Useful controls already pass: signed 16-bit quotient for -17/5, signed 32-bit
quotient/remainder for -123456/100, positive ptrdiff, direct calls, shallow
recursion, sparse switch and sampled integer comparisons. Keep these controls
while fixing failures; do not rewrite a passing neighboring subsystem without
evidence that it is responsible.

## Bad paths and reasoning to avoid

- **"It compiles, therefore it works."** Current unsupported emitters can exit
  zero and omit code. Read diagnostics and execute the target code.
- **"main returns zero, therefore the ABI is right."** LANG-005 disproves this:
  two 0x0006 words remain after the result is popped. Assert stack and frames.
- **"The old suite says 4/4, so start libc."** Fix demonstrated core miscompiles
  first. Library code will exercise shadowing, aggregate, pointer and ABI bugs.
- **"All 43 missing rows require unrelated fixes."** Most share absent headers.
  Identify dependencies, but do not mark consumers correct just because a header
  now exists. Re-run them to expose the next stage's failure.
- **"Host gcc or headers are an EX716 oracle."** Host int/long/pointer widths,
  alignments and variadic layout differ. Use explicit target expectations and
  target-only preprocessing. Host checks can validate syntax, not target ABI.
- **"A type is implemented because Interface has its size."** Floating metrics
  exist but operations and constants do not. A weak float equality test initially
  passed by comparing incorrectly loaded values; the strengthened distinct-value
  control fails. Add negative controls when a pass could be accidental.
- **"Pointer subtraction is unsigned because pointers are unsigned."** ptrdiff
  must retain the sign for differences within one array. Conversely, do not
  sign-extend all unsigned-to-long conversions to repair this one expression.
- **"Copy byte count determines IR type."** A two-/four-byte struct remains a
  block value. Use the IR block suffix and address/value contract.
- **"Local source spelling is a storage identity."** Shadowed objects can share
  spelling. Across units, static functions can also share spelling. Allocate
  identities appropriate to their scopes and linkage.
- **"CPU24 implies separated segments or far pointers."** It can run shared
  memory. Actually enter segmented mode and assert DS placement. Current C
  pointers remain 16-bit offsets.
- **"Assembly memcpy/heap/DiskOS functions are standard C functions."** Names
  do not establish return values, argument cleanup, size types, stream state or
  failure behavior. Check each assembly contract and write an adapter.
- **"DiskOS modes are standard C modes."** C stdio has its own mode
  translation and explicitly truncates for `w`; DiskOS close's success value
  also needs translation. Some open-error paths can print diagnostics, so
  failure behavior needs fixture coverage.
- **"Format or mount the project disk to test a fix."** Use only temporary
  DISK00.disk fixtures, explicit magic 0x3044, no extents and disjoint memory
  ranges. The runtime does not follow host extent chains.
- **"Raise the 40-byte frame limit and buffers are solved."** Default software
  stack is roughly 240 bytes, shared with saved frames/return state; frame
  reservation currently lacks a bottom check. Fix bounds and startup layout.
- **"A failing compound arithmetic probe means all division is broken."** The
  independent quotient/remainder tests narrow the fault. Split assertions under
  permanent IDs instead of guessing or replacing all math routines.
- **"A test uses undefined behavior, so any answer is meaningful."** Avoid
  invalid shifts, signed overflow and unrelated pointer subtraction. Choose and
  document implementation-defined target behaviors. Probe nonconstant operands
  when measuring runtime helpers, so frontend folding cannot bypass them.
- **"Known missing features should be skipped/xfail."** That hides the backlog.
  Keep FAIL/MISSING/NOT_TESTED visible. Never loosen assertions or reset the
  review checkpoint simply to obtain green output.
- **"Optimization or full modern C support is the next blocker."** Correctness,
  data, startup, ABI and I/O are the practical critical path. Defer optimizer
  projects and broad floating-point support until those are reliable.

Also keep the audit harness trustworthy. It already loads lmath, which loads
string and the aggregate helper; do not redundantly include that helper. During
the review a redundant guarded include caused the remaining harness to be
skipped. Explicit entry directives now avoid reliance on incidental startup
data/instructions. If a previously green minimal control times out after a
harness change, inspect the harness before attributing it to the compiler.

## Extend coverage without replacing the plan

`features.json` is the durable list. Keep IDs and requirements. A planned entry
stays NOT_TESTED until it has an actual semantic fixture. Convert it to a C
source/file/multi-unit case under the same ID when implementing it. Add
independent vector IDs such as `IO-fread.partial` or `IO-fread.error` when
different contracts need independent results. Header-only compilation is not
runtime certification of an I/O function.

File fixtures must create/import temporary runtime-compatible images, initialize
heap and DiskOS, test byte/sector/file boundaries, close/reopen, and independently
export/check persisted data. Inject deterministic allocation/device errors.
No file operation may rely on repository disks. The detailed fixed fixture
requirements already exist in `c-readiness.md`; implement them incrementally.

For each new feature, add assertions for the manifest's acceptance vectors
before declaring it ready. Smoke PASS and full-contract readiness are separate.
The current 28 NOT_TESTED rows explicitly expose coverage debt; neither their
prose nor absence of execution is evidence that the feature works.

## Finish one repair with a small evidence record

1. State the selected R item and test IDs; reproduce failures before editing.
2. Inspect relevant source and generated assembly; record a specific mechanism.
3. Implement the smallest complete repair, preserving unrelated dirty changes.
4. Rebuild rcc if backend code changed. Run the relevant IDs in all three modes,
   their nearby passing controls, and the historical smoke suite.
5. Run the full audit and compare statuses. It can remain exit 1 due to unrelated
   backlog; require your assertions green and no new regressions.
6. Save a new JSON checkpoint, update session-state notes, and leave a concise
   handoff: files changed, decision, commands, before/after IDs and remaining
   acceptance vectors. Do not overwrite the review checkpoint to hide failures.

If a fix requires changing the calling convention, segment model or stack
layout, document that decision first and include all affected callers/callees
and runtime adapters in the repair. Do not patch one emitted sequence while
leaving its counterpart inconsistent.

Suggested next-work prompt:

> Read docs/c-implementation-handoff.md. Implement the next unfinished critical
> task, starting with R02 local aliases. Reproduce its evidence, keep
> permanent IDs, verify targeted three-mode execution and the full status diff,
> and report only the changes, results and next dependency. Do not re-run a
> broad architecture review or implement unrelated deferred features.
