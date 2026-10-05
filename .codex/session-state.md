# Session State

Last updated: 2026-10-04

## Latest milestone: lcc C readiness review and implementation handoff

- User requested a deep C readiness review, critical-path missing features,
  standard C I/O roadmap, repeatable test plan, and economical-model handoff.
  The initial review made no compiler fixes; R01 is now implemented below.
- Added `docs/c-readiness.md` and `docs/c-implementation-handoff.md`; linked
  from `docs/README.md` and `tests/csuite/README.md`.
- Added `tests/csuite/readiness.py`, `features.json` (now 120 stable IDs), and
  the original 116-entry `readiness-baseline.json`. Preserved unrelated edits.
- Built sibling lcc rcc/cpp. Original suite: 4/4 PASS. Audit per mode:
  22 PASS, 23 FAIL, 43 MISSING headers, 28 NOT_TESTED fixtures. All-mode run:
  66 PASS, 69 FAIL, 129 MISSING, 84 NOT_TESTED. Repeated segmented baseline
  reports no status changes. Script syntax and diff whitespace checks pass.
- Demonstrated aggregate stack leak, local shadow alias collision, negative
  ptrdiff miscompile, signed 16-bit remainder/high-bit unsigned divide bugs,
  missing static/global/literal emission, small-block copy failures, variadic
  corruption, dense-switch/indirect-call gaps and unsafe float paths.
- Artifacts: `/tmp/ex716-readiness-baseline-final/`; all-mode artifacts and
  JSON: `/tmp/ex716-readiness-all-modes/` and matching `.json`. Temporary;
  rerun documented commands to recreate. Baseline JSON includes input hashes.
- Historical at initial review: R02 aliases, R03 division, R04 ptrdiff,
  R05 aggregates, R06 data; then unit/startup/header foundations, variadic
  ABI and console/file stdio. Read the handoff before implementing.

## R01 milestone: backend errors fail the compiler (2026-10-04)

- Routed unsupported EX716 code-generation, assignment, comparison and jump
  diagnostics through lcc `error()`, so `errcnt` makes rcc exit nonzero. Added
  an explicit unsupported-code-operator diagnostic and avoided duplicate
  generic errors for failed call emission.
- Added four stable `SAFE-unsupported-*` entries and `backend-reject` audit
  handling, requiring both the specific backend diagnostic and nonzero exit.
  Made `--filter` repeatable after the first multi-filter run showed argparse
  silently retained only its final value; reran the intended selection.
- Built rcc. Four existing smoke tests pass. Eleven supported controls, four
  backend rejection tests and invalid-source diagnostics pass in classic,
  CPU24 shared and CPU24 segmented modes: 48/48 checks. A focused earlier run
  also passed 12/12 backend-rejection checks.
- Review checkpoint remains immutable. The post-R01 full segmented report is
  `/tmp/ex716-r01-full.json`, with evidence in `/tmp/ex716-r01-full/`.
  Selected-control report: `/tmp/ex716-r01-checkpoint.json`; rejection-only
  rerun: `/tmp/ex716-r01-final-check.json`.
- R02 local aliasing and R03 16-bit division correctness are complete. R04
  signed pointer difference is next in the current proposed sequence, pending
  the user's direction on project goals and priority. Other unsupported feature
  tests remain failures until their corresponding lowering is implemented.

## R02 milestone: unique local aliases (2026-10-04)

- `lcc/src/ex716.c` now names each local Symbol with a function-qualified
  per-function ID alias (`__ex716_<function>_local_<id>`), avoiding collisions
  between shadowed same-spelling locals and generated temporaries.
- Caller and callee Symbol views of parameters share the same frame alias.
  Derived `__ex716_offN` aliases from `I(address)` continue to refer to their
  existing frame byte offsets and do not allocate duplicate slots.
- Added stderr assignment traces identifying frame/function, source local,
  unique alias, byte offset and width; pointer-indirect targets are marked as
  runtime offsets.
- Expanded `LANG-016` to test nested and sibling shadowed locals. `LANG-015`,
  `LANG-016`, `LANG-017` pass in classic, CPU24 shared and segmented modes
  (9/9); the four original C smoke tests pass (4/4).
- First regression run found derived-address Symbols being allocated as locals;
  the fix preserved their aliases. The next run found caller parameter views
  retaining stale names; mapping both lcc Symbols to the same alias fixed it.
- Final evidence: `/tmp/ex716-r02-local-regression-final2/` and JSON
  `/tmp/ex716-r02-local-regression-final2.json`.

## R03 milestone: 16-bit division correctness (2026-10-04)

- In `EX716/lib/div.ld`, DIV now tracks dividend sign separately from quotient
  sign XOR, negating the remainder according to the dividend as required for
  truncation-toward-zero C arithmetic. `[remainder, quotient]` order is intact.
- DIVU uses `IF_ULT_S` to skip subtraction when the unsigned remainder is less
  than the divisor. Follow-up inspection found `IF_UGE_S` itself violated its
  unsigned contract; both `structure.asm` and `structureDS.ld` now skip on
  unsigned `JULT`, with boundary regressions in classic and CPU24 tests.
- Expanded stable vectors cover all operand sign combinations, exact and
  inexact quotient/remainder cases, and unsigned high-bit operands in both
  orders. The three 16-bit tests pass across classic, CPU24 and segmented modes
  (9/9). `LANG-009` and signed 32-bit div/mod controls pass (9/9); C smoke suite
  passes 4/4.
- Evidence: `/tmp/ex716-r03-div16-vectors/` and
  `/tmp/ex716-r03-math-regression/`. Full readiness audit not rerun; immutable
  initial checkpoint remains unchanged.
- `cpu.py tests/if_test_16.asm` passes the complete classic comparison suite;
  `cpu24.py tests/if_uge_cpu24-test.asm` passes high-bit/equality checks.
  `MATH-div16-high` passes again in all three readiness modes after fixing the
  shared macro. Evidence: `/tmp/ex716-uge-divu-regression/`.
- R04 signed pointer difference is now implemented in sibling `lcc/src/ex716.c`.
  It recognizes lcc's 16-bit subtraction/widening form, compares near offsets
  unsigned, computes a 16-bit magnitude, applies element scaling with native
  shifts or DIVU16, and forms the signed 32-bit result. Byte stride 1 is
  handled when lcc optimizes away division. No pointer operation calls the
  32-bit math library.
- This is near-pointer behavior only: offsets never carry into another segment;
  structures/objects must remain inside one 64-KiB data segment. It does not
  implement far-pointer difference or cross-segment arithmetic.
- Expanded stable `LANG-018` coverage for positive/negative byte, int and long
  pointer differences, pointer ordering, and storing a negative result. The
  three pointer vectors (`LANG-018`, `MEM-pointer-negative`, and
  `MEM-pointer-positive`) pass in classic, CPU24 shared and segmented modes
  (9/9). Original C smoke suite passes 4/4; `git diff --check` passes.
- Evidence: `/tmp/ex716-r04-final/` and `/tmp/ex716-r04-final.json`.
- R04 acceptance completed for valid same-array near-pointer cases; far-pointer
  and cross-segment differences remain explicitly unsupported.

## R05 milestone: aggregate ABI and exact block copies (2026-10-04)

- `lcc/src/ex716.c` now routes block-valued `ASGN` through exact-address
  copying, including 1-, 2-, and 4-byte structures; existing larger blocks use
  the overlap-safe internal `EX716_MEMMOVE` helper. This preserves the IR's
  block/address distinction instead of treating width as scalar integer size.
- The `LANG-005` trace showed two `0x0006` words left by two internal copy
  calls. Each call leaked one condition/length word; the helper now balances
  both before its local-frame epilogue.
- Expanded `LANG-029` to exact struct block sizes 1, 2 and 3 bytes. `LANG-030`
  covers 4 bytes; `LANG-005` covers a 6-byte aggregate argument, hidden result
  pointer/return, and stack cleanup. All three pass in classic, CPU24 shared
  and segmented modes (9/9). Existing C smoke suite passes 4/4.
- Evidence: `/tmp/ex716-r05-expanded/` and `/tmp/ex716-r05-expanded.json`.
- Public C `memcpy` and broader aggregate ABI cases remain separate work.

## R06 milestone: C data and initializer emission (2026-10-04)

- `lcc/src/ex716.c` now emits scalar/array/struct initializers, named data
  labels, byte strings, address relocations, and repeated zero-fill using the
  assembler's `::label value` and `::__ value` forms. Private statics and
  generated constants receive unique internal labels. Global stores and
  subobject offsets retain their data symbol rather than becoming frame offsets.
- Emission intentionally follows the active assembler data cursor instead of
  hardcoding a bank: classic/shared modes use unified memory; the segmented
  harness selects `.DATA 1` before generated C units, so globals and strings
  land in DS with CS != DS. The existing CPU24 data test independently confirms
  quoted strings follow `.DATA 1`.
- Initial classic-mode runs exposed a pre-existing assembler crash: `::label`
  accessed `context.codehighaddress`, absent from classic `AssemblerContext`.
  Added the missing field to `cpu.py`; data labels now advance the unified code
  cursor correctly.
- Expanded `LANG-020` to scalar widths, writable globals, initialized arrays,
  padded structs and string data; `LANG-021` covers zeroed arrays/pointers/
  structs and writes; `LANG-022` tests initialized same-named statics; `LANG-023`
  tests escapes and distinct literals; `LANG-024` tests object/function and
  object-plus-offset relocations. `LANG-019` checks automatic initialized
  arrays. All six pass in classic, CPU24 shared and segmented modes (18/18).
- The static-function-address edge in `LANG-024` exposed an `rcc` SIGSEGV:
  the frontend calls `defsymbol` before the static function type is complete.
  `ex716_defsymbol` now guards the temporarily-null type; the static function
  pointer initializer passes all modes. The readiness runner now prints
  `(no diagnostic detail)` rather than crashing if a failure has empty stderr.
- Cross-milestone regression set (`LANG-005`, `015`–`024`, `029`–`030`, and
  both pointer probes) passes 45/45 across all three modes; C smoke suite 4/4.
  Latest evidence: `/tmp/ex716-r06-complete/` (18/18),
  `/tmp/ex716-r06-regression-latest/` (45/45), and
  `/tmp/ex716-r06-static-fnptr-fixed/` (3/3), with matching JSON reports.
  `python3 tests/csuite/run.py` passes 4/4.
- Floating initializers are explicitly rejected (R12 policy); translation-unit
  imports/exports and static identity across separate compilations remain R08.
- Next handoff priority: R08/R10/R11 foundations (unit isolation, target build/
  startup and bounded memory layout), followed by the written variadic ABI R07.

## R07 milestone: variadic argument packet (2026-10-04)

- Implemented the R07 packet ABI in `lcc/src/ex716.c`: a caller-owned frame
  packet has a 16-bit payload byte count followed by optional promoted scalar
  and pointer values in source order. A hidden packet pointer follows named
  parameters. Fixed/non-variadic calls retain the existing convention; zero
  extra arguments use a valid empty packet.
- Added `lcc/include/ex716/stdarg.h` with `va_list`, `va_start`, typed
  `va_arg`, `va_end`, and two static support routines for cursor setup/advance.
  The caller preserves packet lifetime for the call and owns cleanup.
- Coverage checks default `char` promotion, 16-/32-bit traversal, pointer and
  string arguments, nested variadic calls, empty packets, and fixed calls.
  `LANG-026/027` pass all three modes. Regression set `LANG-005`, `015`–`024`,
  `026/027`, `029/030`, and pointer probes passes 51/51; C smoke passes 4/4.
  Evidence: `/tmp/ex716-r07-final-candidate/` and
  `/tmp/ex716-r07-regression-final/` (matching JSON reports).
- Variadic packet tests exposed a general backend omission: scalar assignment
  through a computed `ADD` address was not emitted. The backend now handles
  this alongside indirect/global stores; this is not C-specific ABI behavior.
  An initially bad nested-call test passed the wrong count for the arguments it
  consumed; correcting the fixture removed that undefined read and verified
  the intended `long` traversal.
- Floating items and aggregates through `...` are rejected; item widths are
  limited to 2/4 bytes; the pre-existing 40-byte frame limit still applies.
  Header helper linkage across translation units is unverified and belongs to
  R08. Variadic formatting is not yet implemented. Floats are explicitly
  excluded in backend planning until a floating ABI is added.

The objectives below are historical; this review/handoff is the newest work.

## Latest milestone: addressable C local frames

- Added opt-in `lib/clocals.ld`; it includes `softstack.ld` as a dependency.
  `softstack.ld` does not include or depend on `clocals.ld`, and its existing
  `@Locals`/`@Local` behavior for assembly programs is unchanged.
- Added `@CLocals`, `@CLocal`, `@CLocal32`, `@EndCLocals`, `@CPUSHADDR`,
  `@CPUSHI`, `@CPOPI`, `@CPUSH32I`, and `@CPOP32I`.
- C frames occupy unique software-stack storage and preserve a shared
  `__C_FP`, making local addresses stable across nested calls and recursion.
- `tests/clocals-test.asm` passes under `cpu.py`; the separate-CS/DS
  `tests/clocals-cpu24-test.asm` passes under `cpu24.py`. Both print `1234`,
  `12345678`, and recursive sum `15`, with zero unresolved symbols.
- Integrated these frames into the sibling lcc EX716 backend and added 16-bit
  DS pointers: local address-of, 16/32-bit indirect loads and stores, scaled
  indexing/arithmetic, signed pointer differences, comparisons, nested calls
  through local addresses, and recursive C frames.
- Pointer integration passed on both `cpu.py` and separate-CS/DS `cpu24.py`.
  Existing calls, comparisons/control flow, and multiply/divide tests also pass
  under the new frame convention.
- Fixed CPU24 `PUSH32(A)` to read inline constants through CS overrides, and
  fixed `IF32_ULE`/`IF32_UGT` to push flag-mask constants rather than reading
  memory at those numeric addresses.
- Added C-frame byte helpers and sibling lcc signed/unsigned character pointer
  loads, byte-preserving stores, local character address-of, and byte-scaled
  indexing. Tests pass identically on `cpu.py` and CPU24: `ff80`, `0080`,
  preserved-neighbor word `aa34`, local signed result `fffe`, and indexed
  unsigned result `00fe`.

## Latest milestone: lcc direct C-to-C calls

- Added direct function-call emission to the sibling `lcc/src/ex716.c` backend.
- Arguments are evaluated/pushed in source order; existing callee prologues pop
  them in reverse order. Calls support 16/32-bit arguments and return values,
  nested calls, void calls, zero-argument calls, and discarded return values.
- Added sibling regression fixtures `tst/ex716-calls.c` and
  `tst/ex716-calls.asm`.
- Runtime-tested outputs: `9`, `00051ae7` (334567), `12`, `000186a6`
  (100006), `7`, `42`, and `19`; all symbols resolved.
- Function-pointer/indirect calls remain explicitly unsupported.

## Latest milestone: lcc integer shifts

- Added and exported `SAR32` in `lib/lmath.ld` for signed arithmetic right
  shifts, including sign saturation for counts of 32 or greater.
- Updated the sibling `lcc/src/ex716.c` backend to emit constant or computed
  16/32-bit left, logical-right, and arithmetic-right shifts.
- Shift-count expressions are reduced to their low word and masked with
  `0x7fff`, so helpers always receive a nonnegative short integer.
- Verified the lcc output matrix selects `SHL16_BY_N`, `SHR16_BY_N`,
  `SAR16_BY_N`, `SHL32`, `SHR32`, and `SAR32` and emits the required `#USE`.
- Runtime-tested `SAR32`: `80000000 >> 1 = c0000000`,
  `87654321 >> 4 = f8765432`, `7fffffff >> 31 = 00000000`, and a negative
  value shifted by 32 sign-saturates to `ffffffff`. All symbols resolved.
- `git diff --check` passes in both repositories.

## Latest milestone: lcc multiply and divide

- Added signed and unsigned 16/32-bit `MUL` and `DIV` expression emission in
  the sibling `lcc/src/ex716.c` backend.
- Generic operations select `MUL`/`MULU`, `MUL32S`/`MUL32U`, `DIV`/`DIVU`, or
  the appropriate signed/unsigned 32-bit quotient wrapper.
- Constant multipliers 2, 4, 8, 10, and 12 are lowered to shifts and adds;
  optimized expressions do not request a multiply library routine.
- Added `DIV32U_Q` and `DIV32S_Q` in `lib/lmath.ld` to discard the base divide
  routines' remainder and return one expression result.
- Repaired `lib/mul.ld` signed `MUL`, which previously lost an operand during
  sign checks, and corrected its result-negation condition.
- Repaired `lib/shift16.ld` runtime loops, which previously shifted counts 1,
  2, and 3 all by three positions. Constant 16-bit logical shifts now compile
  directly to `SHLN`/`SHRN`.
- End-to-end generated-code tests passed for signed/unsigned 16/32-bit generic
  multiply and divide and every optimized multiplier; all symbols resolved.

## Current objective

Keep documentation aligned with the current Python CPU implementations, macro
libraries, runtime libraries, and DiskOS. The requested refresh is complete.

## Completed work

- Added `docs/programming-guide.md` for the CPU model, native instructions,
  classic and segmented examples, calls/locals, style, and debugger workflow.
- Added `docs/library-appendix.md` with table summaries of important common and
  structured macros plus lmath, random, string, heapmgr, and softstack services.
- Added `docs/diskos-guide.md` covering heap ownership, physical layout and
  tables, open modes, line I/O examples, closing, and host-tool compatibility.
- Linked the guides from `README.md` and corrected stale claims about the memory
  model, library paths, documentation directory, and command-line options.
- Corrected `Macro.md` and `CPU2CPU24.txt` stale references/terminology, and
  added a prominent runtime-magic/extent warning to `filesys/README.md`.

## Validation and decisions

- Used `cpu.py`, `cpu24.py`, `lib/CPU.json`, library implementations, and
  `filesys/ex716disk.py` as authoritative instead of older prose.
- Confirmed all base and CPU24 opcodes, Ring 1 segment behavior, assembler bank
  directives, DiskOS field offsets, and runtime magic `0x3044`.
- Documented that `ex716disk.py` defaults to incompatible magic `0x0716`; use
  `--magic 0x3044` for runtime images.
- Documented that host-tool extent chains are not followed by current runtime
  DiskOS, which is limited to one 64 KiB block per file.
- Made DiskOS's heap dependence explicit, including persistent file-pointer and
  ArgTable allocations, transient 512-byte buffers, ownership, and lifetime.
- Removed the erroneous legacy `I lmath.md` include from `lib/timetool.ld`;
  current `lmath.ld` already supplies every 32-bit macro timetool uses.
- Moved four unreferenced historical/stale documents into `docs/archive/` with
  explicit archive banners and added `docs/README.md` as the active-doc map.

## Verification

- A temporary CPU24 guide example assembled with zero unresolved symbols and
  ran successfully; the temporary source was removed.
- A temporary DiskOS call-pattern source including `string.ld` assembled with
  zero unresolved symbols; the temporary source was removed. It was a syntax
  and link check, not a heap/disk functional test.
- `tests/event-time.asm` assembled after removing `I lmath.md` from timetool
  with 254 used symbols, 2732 resolved symbols, and zero unresolved symbols;
  it then entered its expected interactive terminal wait.
- `git diff --check` passes.

## Modified files

- `README.md`
- `docs/programming-guide.md` (new)
- `docs/library-appendix.md` (new)
- `docs/diskos-guide.md` (new)
- `docs/README.md` (new)
- `docs/archive/README-legacy.md` (moved from `README.md.old`)
- `docs/archive/EX816-future-concept.md` (moved from `README2.md`)
- `docs/archive/cpu-generated-index-stale.md` (moved from `cpu.md`)
- `docs/archive/cpu12-function-index.md` (moved from `cpu_function_index.md`)
- `Macro.md`
- `CPU2CPU24.txt`
- `filesys/README.md`
- `lib/timetool.ld`
- `.codex/session-state.md`

## Known unrelated worktree items

- `.cpu_history` and `tests/.codex/` are untracked and were not touched.

## Next steps

1. Consider changing `ex716disk.py`'s default magic to `0x3044` and updating
   its older README; this milestone documents rather than changes that behavior.
2. Decide whether host extent support should be implemented in runtime DiskOS
   or disabled for runtime-bound images.
3. Resume the earlier FuncCalc equality, short-circuit, and IF/WHILE milestones
   as a separate task.

## Latest milestone: EX716 C regression suite starter

- Added `tests/csuite/run.py`, which compiles each small C `main` using the
  sibling `lcc/build/rcc`, creates an assembly harness, and runs it through
  `cpu24.py`; tests return zero on success and nonzero on failure.
- Added suite guidance and initial cases for mixed-width calls, 16/32-bit
  signed and unsigned arithmetic/shifts, arrays/pointer arrays, and struct
  parameter/return ABI.
- Verified all four cases pass through CPU24 and report zero unresolved
  symbols; `git diff --check` passes.
- Modified files for this milestone: `tests/csuite/` and
  `.codex/session-state.md`.
- Next: grow coverage from the book's focused tests while filtering out
  floating point, host-width assumptions, hosted I/O, and over-segment memory
  until those target features are implemented.
