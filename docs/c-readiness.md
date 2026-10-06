# lcc / EX716 C readiness review

Review date: 2026-10-04. Implementation handoff and permanent test plan.

## Verdict and intended scope

The EX716 backend is useful for small, deliberately restricted integer C
experiments. It is **not yet ready for ordinary C application development**.
The main obstacles are correctness and missing application infrastructure,
not optimization. Global objects, literals, some ordinary C expressions,
argument cleanup, target headers, and a C-compatible I/O layer need work.

The existing four regressions pass, but that result substantially overstates
readiness: their runner only checks `main`'s return value and unresolved
symbols. It uses `common.mc`, so CPU24 executes in shared-memory mode. The new
audit actually enters segmented mode with CS=0 and DS=1, and checks both
software-frame restoration and hardware-stack balance. The aggregate-return
regression returns zero while leaving **two words** on the hardware stack.

For the first practical release, use this explicit profile:

- Eight-bit bytes and signed plain `char`; 16-bit `short` and `int`;
  32-bit `long`; little-endian; two-byte pointer and scalar alignment.
- Near data pointers refer to the current 64 KiB DS. Function addresses belong
  to CS. Larger physical CPU24 memory does not make these pointers far pointers.
- C90-derived declarations/statements and integer/aggregate operations,
  plus selected C99 library conveniences such as `snprintf`.
- Document arithmetic signed right shift and choose integer division that
  truncates toward zero. Tests avoid signed overflow, invalid shifts, unrelated
  pointer subtraction, division by zero, and signed-minimum divided by -1.
- Floating point, eight-byte integers, modern language extensions, and far
  pointers may be deferred, but unsupported executable operations must be
  rejected cleanly. Merely declaring metrics for a type does not implement it.

This profile is a development milestone, **not ISO C conformance**. C's hosted
and freestanding environments have different obligations; freestanding does
not by itself excuse incorrect supported expressions. C11's distinctions and
library organization are described in [WG14 N1570, clauses 4, 5.1.2 and 7.21](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf).

## Evidence, baseline, and limits

Sources inspected: sibling `lcc/src/ex716.c`, frontend/build/driver files,
EX716 `cpu.py`/`cpu24.py`, `clocals.ld`, `softstack.ld`, integer libraries,
`string.ld`, `heapmgr.ld`, `diskos.ld`, and the current guides and C tests.
Compiler commit: `a30c745`; EX716 commit: `be12427`. Both worktrees contain
additional material, so commit hashes alone do not identify this baseline.
Existing changes were preserved; no compiler or runtime fixes were made.

The initial readiness baseline contains **116 entries**:

| Status in segmented mode | Count | Meaning |
| --- | ---: | --- |
| PASS | 22 | This executable probe passed, including stack checks; not full feature certification. |
| FAIL | 23 | Compiler, assembler, semantic, symbol-isolation, or ABI failure demonstrated. |
| MISSING | 43 | Public include absent; execution cannot yet assess that entry. |
| NOT_TESTED | 28 | Persistent acceptance requirements exist, but executable fixtures are not yet implemented. |

The 43 header-blocked entries are not 43 independent implementation defects.
Most depend on the same missing `stdio.h`, `string.h`, or `stdlib.h`.
Likewise, a compound probe may fail because of one shared root cause.

[The saved JSON baseline](../tests/csuite/readiness-baseline.json) records every
ID and failure stage. [The manifest](../tests/csuite/features.json) is the
authoritative ongoing checklist; this prose is a dated interpretation.
Detailed generated sources, assembly and logs from the review are in
`/tmp/ex716-readiness-baseline/`; these temporary artifacts are not permanent
project dependencies. Rerun with `--artifacts` to recreate evidence.

Passing areas include direct mixed-width calls, the existing arithmetic and
local-array fixtures, boundary integer comparisons, basic conversions,
short-circuit side effects, loops/goto, sparse switch, shallow recursive
addressable frames, adjacent byte stores, the sampled union/bit-field case,
computed legal boundary shifts, and unsigned addition wrapping. Each is
sampled rather than exhaustive. No physical EX716 hardware was tested.

## Core missing or broken features

P0 means correctness or basic application blocker; P1 means the next useful
application tier; P2 means deferred breadth. A P1 implementation may depend on
a P0 fix. Fixing a dependency does not automatically certify its consumers.

| Work item | Priority | Demonstrated evidence / source anchor | Exit criteria and permanent IDs |
| --- | --- | --- | --- |
| R01: Fail closed on unsupported code | P0; safety work complete | At review time, unsupported expression/assignment/jump/call paths used `fprintf` and could return exit 0. R01 now routes these through `error()` and diagnoses unknown code nodes. | The remaining negative float safety check requires a matching backend error and nonzero exit. Dense-switch, small-aggregate, and indirect-call safety IDs are now positive regressions because those paths are implemented. Feature support remains tracked by the corresponding `LANG-*` rows. |
| R02: Correct local symbol identity | P0; implementation complete | `ex716_register_local` now assigns function-qualified per-Symbol aliases; caller/callee parameter views share one alias, while `__ex716_offN` derived aliases do not allocate new slots. | Nested/sibling shadowing passes `LANG-016`; recursion, arrays, byte stores and ABI smoke tests remain passing. Assignment diagnostics show frame, source name, alias, offset and size. |
| R03: Signed remainder and unsigned division | P0; implementation complete | In `EX716/lib/div.ld`, `DIV` tracks dividend sign separately from quotient XOR sign. `DIVU` uses unsigned-less-than branching for remainder subtraction, including high-bit values. | Expanded sign/exactness and high-bit vectors pass independently; `[remainder, quotient]` result order preserved. `MATH-div16-signed`, `MATH-mod16-signed`, `MATH-div16-high`. |
| R04: Negative pointer difference | P0; implementation complete for near pointers | Backend now recognizes divide-scaled and stride-one pointer-difference IR, compares offsets unsigned, and forms signed differences without 32-bit math. Cross-segment/far-pointer arithmetic is not supported. | Byte/int/long stride, both signs, expression/assignment and pointer ordering pass in all modes. `LANG-018`, both `MEM-pointer-*`. |
| R05: Aggregate ABI and copy sizes | P0/P1; implementation complete for tested local aggregate ABI | `LANG-005` exposed one copy-length word leaked per internal memmove call; small block `INDIR` was incorrectly treated as scalar. Backend now copies block values by address and helper cleanup is balanced. | Aggregate arguments/results and exact 1-, 2-, 3-, 4-, and 6-byte copies pass with stack/frame checks in all modes. `LANG-005`, `029`, `030`. Public C `memcpy` and broader ABI certification remain separate. |
| R06: Real data emission | P0; implemented for current data acceptance vectors | Backend emits named DS data through native `::label value` and `::__ value` initializer streams, explicit zero-fill, byte strings, static identities, and near-address relocations. Global stores/subobject offsets now retain their data symbol. Classic assembler gained its missing code high-water field for unified code/data labels. | Automatic/global initialization, scalar/array/struct/string objects, zeroed BSS, separate same-name statics, object/function/offset addresses pass with CS != DS. `LANG-019` through `024`, all modes. Floating initializers remain explicitly unsupported; cross-unit linkage remains R08. |
| R07: Variadic calling convention | P0; implemented for current acceptance subset | Caller builds a frame-owned packet with a 16-bit payload-byte count and promoted scalar/pointer items in source order; a hidden packet pointer follows named arguments. Fixed calls retain their existing ABI. Target `stdarg.h` provides `va_start`, typed `va_arg`, and no-op `va_end`. | `LANG-026/027` pass in classic, CPU24 and segmented modes, including zero extras, mixed widths, default char promotion, nested call, pointer/string. Aggregates and floating items are explicitly rejected; frames above the current 256-byte backend limit and multi-unit static helper linkage are not certified. Formatting (`IO-v*`) must preserve packet semantics. |
| R08: Translation units and linkage | P1; implemented for the current assembly-combiner profile | Each compilation automatically derives a deterministic unit namespace from the original filename and preprocessed content, excluding path-bearing line directives. Private functions, data, constants, branch labels, and local aliases use that namespace; external names remain unchanged. No user-supplied ID is required. | Cross-unit external calls and same-named private functions/data/constants/control flow pass all three modes (`LANG-032/033`). The optional `-unit-id=` override is for build tooling. A production combiner/build fixture remains `SYS-002`; import/export callbacks remain intentionally empty because assembler resolution supplies the current link step. |
| R09: Dense switch and indirect calls | P1; implemented for near code pointers | Sparse and dense switches execute. Computed jump targets use `JMPS`; switch relocations use emitted case labels. `CALLS` implements the call equivalent for a 16-bit target already on the stack while preserving the direct-call ABI. | Dense tables with holes and signed bounds, runtime-selected function pointers, callbacks, mixed-width arguments/results, and indirect variadic calls pass all three modes. Far code pointers remain outside the near-pointer profile. `LANG-013`, `014`, `025`, both corresponding positive `SAFE-*` regressions. |
| R10: Frames and startup memory contract | Accepted for the current software-managed profile; hardware boundary/lifecycle gates deferred | Generated `main` initializes a heap after static storage, allocates a 4-KiB stack object by default, and calls `SetSSStack` before opening its C frame. `-Wf-stack-size=N` (or direct `rcc -stack-size=N`) adjusts it; `@CLocals` checks the stack bottom. `EX716_MAX_FRAME_BYTES` defaults to 256 and can be overridden when building the backend. | `LANG-028`, `SYS-004` (default-stack exhaustion), and `SYS-005` (8-KiB override) pass in all three modes. `SYS-001` production entry/exit and `SYS-003` full segment-end/overlap verification remain planned, explicitly deferred until CPU memory management and hard interrupts. The public C `malloc` adapter is R11. |
| R11: Target headers and C runtime adapters | P0/P1; integer limits header and expanded integer formatter present, broader adapters open | Target `stddef.h`, `limits.h`, `stdlib.h`, and `string.h` now exist. `stdio_format.c` follows a parser/field-renderer/sink structure; EX716 conversion uses nibble/bit groups for hex/octal and power-of-ten subtraction for 32-bit decimal, avoiding repeated 32-bit division. It supports integer flags, width/precision, `%d/%i/%u/%o/%x/%X/%p/%c/%s/%%`, 32-bit `long`, and bounded `snprintf`; unsupported long-long and floating conversions reject explicitly. | `HEADER-limits` asserts the target values. Expand runtime evidence for flags, precision, `%lu`, and extrema before calling integer formatting complete. `fprintf`, `sprintf`, `v*` wrappers, `calloc`, `realloc`, and file streams remain open. Continue under `IO-printf` and `IO-snprintf`. |
| R12: Floating/64-bit type policy | P0 safety; execution support is a later major project | Float/double/long-long metrics exist without complete code generation. Float expressions, assignments, comparisons, and initializers now have explicit EX716 rejection diagnostics instead of falling through integer paths. | Keep unsupported operations rejected and clearly identified. The next numeric-model project should choose IEEE floating point or a documented fixed-point alternative before adding arithmetic; fixed point is not C `float` compatibility. `LANG-034`, `035`, `038`. |

### Initial C Adapter Inventory

Compatibility levels describe current evidence, not just implementation names:
**C wrapper tested** means the listed C-level vectors pass in all three
modes, not that every standard edge case is certified; **service exists** means
a related EX716 routine exists but its C ABI or semantics remain unverified;
**primitive only** means an instruction or macro is available but no library
service exists; **missing** means no suitable service was found.

| EX716 Version Name | C Library Name | Compatibility Level | Priority |
| --- | --- | --- | --- |
| `string.ld:strlen` (direct global; no stub) | `strlen` | Direct C call tested (`LIB-strlen`). | P1 |
| `string.ld:strcmp` (direct global; no stub) | `strcmp` | Direct C call tested for equality and ordering (`LIB-strcmp`). | P1 |
| `string.ld:strncmp` (direct global; no stub) | `strncmp` | Direct C call tested for count, ordering, equality and zero count (`LIB-strncmp`). | P1 |
| `string.ld:strstr` (direct global; no stub) | `strstr` | Direct C call tested for first match and no match (`LIB-strstr`). | P1 |
| `string.ld:strcpy` via `c_runtime_stubs.ld` | `strcpy` | C wrapper tested: terminator and returned destination (`LIB-strcpy`). | P1 |
| `string.ld:strncpy` via `c_runtime_stubs.ld` | `strncpy` | C wrapper tested: bounded copy and returned destination (`LIB-strncpy`). | P1 |
| `string.ld:strcat` / `strncat` via `c_runtime_stubs.ld` | `strcat` / `strncat` | C wrappers tested: terminator and returned destination (`LIB-strcat`, `LIB-strncat`); adapter removes the legacy `strncat` stack leak. | P1 |
| `string.ld:memcpy` via `c_runtime_stubs.ld` | `memcpy` | C wrapper tested: byte copy and returned destination (`LIB-memcpy`). Existing implementation also tolerates overlap. | P1 |
| `EX716_MEMMOVE` via `c_runtime_stubs.ld` | `memmove` | C wrapper tested: overlap-safe byte copy and returned destination (`LIB-memmove`). | P1 |
| C byte-fill routine in `c_runtime_stubs.ld` | `memset` | Implemented and tested for byte value and returned destination (`LIB-memset`). | P1 |
| `HeapNewObject` / `HeapDeleteObject` via `c_runtime_stubs.ld` | `malloc` / `free` | C wrapper tested for two-byte alignment, allocation/use, `free`, `free(NULL)`, and oversized-allocation null (`LIB-malloc`, `LIB-malloc.oom`). | P1 |
| `HeapNewObject` plus zero-fill | `calloc` | Buildable from existing allocation; multiplication overflow and C result contract need a wrapper. | P2 |
| `HeapResizeObject` | `realloc` | Moving resize service exists; adapt null/failure/zero-size rules and test failure preservation. | P2 |
| `CAST` adapter in `c_runtime_stubs.ld` / `POLL` instruction | `putchar` / `getchar` | `putchar` C wrapper tested in all modes (`IO-putchar`); output failure/EOF is not yet representable. `getchar` remains missing. | P0 |
| `stdio_format.c` | `printf` / `snprintf` | Shared parser, field renderer and output sink. Integer conversions are specialized for the 16-bit `int`/32-bit `long` profile; float and long-long formats fail explicitly. Existing focused `%d`/`%ld` evidence predates the expanded formatter; expanded acceptance is still required. | P1 |

The backend advertises long long=8, float=4, double=8, long double=16 with
`outofline` metrics. That flag is not evidence that operations work. There is
also a 64-symbol local table with an assertion; replacing hard limits should
include a proper diagnostic. Debug-tree output currently floods compiler
stderr and contains host addresses; gate it behind an option after diagnostics
are reliable.

`address()` currently derives every subobject alias from frame offset. When
implementing R06, distinguish static/global base-plus-offset expressions from
frame-relative subobjects. Global fields must not accidentally become locals.
For aggregate copying, branch on the IR block suffix, not only byte count.

The [lcc 4.x code-generation interface](https://drh.github.io/lcc/documents/interface4.pdf)
describes backend callbacks, target metrics and IR conventions. Read the
relevant callback contract before filling the data hooks; frontend support and
backend implementation are separate responsibilities.

### R08 translation-unit milestone (2026-10-06)

The current assembly-combiner linkage profile is implemented. The backend
automatically derives a deterministic unit namespace from the original source
filename and preprocessed contents, excluding path-bearing line directives.
End users do not provide an identifier. An optional `-unit-id=` override exists
only for build tooling that already owns a stronger compilation-unit identity.

Static functions and data, generated constants, branch labels, and local
aliases use the namespace. External definitions and references retain their C
linkage names, so separately generated assembly units resolve normally when
combined. Expanded `LANG-033` coverage gives both units the same private
function and data names, distinct string contents, and independent branches;
`LANG-032/033` pass in classic, CPU24 shared, and segmented modes (6/6).
The neighboring data/control-flow/variadic regression set passes 36/36 and the
historical smoke suite passes 4/4.

The full segmented audit now reports 74 PASS, 24 FAIL, 9 MISSING, and 28
NOT_TESTED. The namespace repair also removed apparent stack-allocation failures
from focused `snprintf` probes: those failures were caused by colliding private
control/helper symbols, not inadequate heap space. Evidence is in
`/tmp/ex716-r08-full/` with report `/tmp/ex716-r08-full.json`.

This does not claim a general object format or production linker. `SYS-002`
still owns the production build/combiner fixture and explicit diagnostics for
duplicate public definitions and unresolved externals.

### R09 computed-control-flow milestone (2026-10-06)

Dense switch tables and indirect function calls are implemented for 16-bit
near code addresses. `common.mc` and `commonDS.mc` provide `CALLS` for a target
already on the stack. It pushes an assembler-computed return label, swaps that
address beneath the target, and executes `JMPS`; the callee therefore receives
the same argument/return-address layout as an ordinary `CALL`. The existing
`CALLI` remains available for calls through a named memory cell.

The backend accepts lcc's pointer-valued `INDIR` call target, evaluates it, and
emits `CALLS`. Variadic packet planning now derives the function type from both
direct and indirect targets, so indirect variadic calls retain the R07 ABI.
Expanded `LANG-025` coverage includes runtime target selection, callbacks,
16-/32-bit arguments and results, and a variadic function pointer. R09 and its
nearby R07/R08 controls pass 27/27 across all modes; smoke passes 4/4.

The full segmented audit now reports 75 PASS, 23 FAIL, 9 MISSING, and 28
NOT_TESTED. Evidence is in `/tmp/ex716-r09-full/` with report
`/tmp/ex716-r09-full.json`. Far function pointers and cross-segment calls remain
outside the current near-pointer target profile.

### R01 diagnostic-safety milestone (2026-10-04)

The first implementation milestone is complete. Unsupported backend expression,
assignment, aggregate-copy, comparison, jump, shift-count and code-node paths
now report through lcc `error()`, which increments the compiler error count;
`rcc` returns nonzero when that count is positive. Unhandled code operators
also fail explicitly. An unsupported indirect call emits one backend diagnostic
and does not fall through into a second generic-node error.

At that checkpoint four `SAFE-unsupported-*` probes confirmed rejection of
indirect calls, float expressions, two-byte struct copies, and malformed dense
switch lowering. Dense switches and small aggregate copies have since become
positive regressions. Indirect calls remain the open R09 rejection;
floating-point rejection/implementation remains R12.

The checked-in 116-entry baseline remains immutable; the active manifest has
120 entries after adding the four R01 acceptance checks. The post-R01 full
segmented audit reports 26 PASS, 23 FAIL, 43 MISSING and 28 NOT_TESTED. All
original 116 rows retain their prior status; the four new safety rows pass.
The active manifest has since grown to 135 entries with dense-switch,
stack-exhaustion/configuration, initial C-adapter coverage, and focused
formatting vectors; the historical baseline remains unchanged. The
post-R08 checkpoint reports 74 PASS, 24 FAIL, 9 MISSING, and 28 NOT_TESTED
in segmented mode, with the historical smoke suite passing 4/4.
The remaining FAIL rows are compiler/runtime feature work, not test-runner
failures. Full report: `/tmp/ex716-r01-full.json`, with per-case evidence in
`/tmp/ex716-r01-full/`. The selected-control report is
`/tmp/ex716-r01-checkpoint.json`; the final rejection-only report is
`/tmp/ex716-r01-final-check.json`. Compiler failures now surface the first
relevant `EX716: unsupported`, `unhandled` or `malformed` diagnostic instead
of letting verbose debug output hide it.

## Required standard C I/O roadmap

Start with a small, consistent `FILE` abstraction for console and DiskOS streams.
Provide target `EOF`, `BUFSIZ`, `SEEK_*`, `size_t`, `fpos_t`, and standard stream
objects. Character input must represent every unsigned byte separately from
EOF. Keep end-of-file and error state separate. Prefer one byte-I/O core used
by strings, block I/O and formatting rather than independent implementations.

The priority below is an EX716 engineering recommendation, not the standard's
priority. The C99 reference for these API groups is
[WG14 N1256, clause 7.19](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1256.pdf).

| Tier | Functions | Practical requirement |
| --- | --- | --- |
| First console | `putchar`, `getchar`, `puts`, `fputc`, `fgetc`, `fputs`, `fgets`; `getc`, `putc` aliases next | Byte results, bounded lines, terminators, predictable newline policy, deterministic piped input. |
| State/visibility | `fflush`, `feof`, `ferror`, `clearerr`; `ungetc` next | Distinct EOF/error flags, flush failure, one-character pushback. |
| First formatting | `printf`, `snprintf`; then `fprintf`, `sprintf`, `vprintf`, `vfprintf`, `vsprintf`, `vsnprintf` | Shared integer/string formatting engine and target variadic ABI; return counts and bounded destination behavior. |
| First files | `fopen`, `fclose`, `fread`, `fwrite` | Standard mode meanings, binary byte preservation, complete-element counts, close/flush metadata and ownership. |
| Useful positioning | `fseek`, `ftell`, `rewind`; `fgetpos`, `fsetpos` later | Long cursor and explicit offset limits; EOF reset and update-stream transitions. |
| Text parsing/reporting | `sscanf`, `perror`; `scanf`, `fscanf`, `vscanf`, `vfscanf`, `vsscanf` later | Assignment counts, bounded strings, recovery and stderr diagnostics. |
| Later hosted breadth | `freopen`, `setbuf`, `setvbuf`, `remove`, `rename`, `tmpfile`, `tmpnam` | Rebinding, buffering ownership, filesystem metadata and temporary lifetime. |

Every listed function has its own permanent `IO-<name>` entry. Their acceptance
vectors live in the manifest. `gets` is intentionally excluded from the
recommended application profile; wide-character I/O, locale-dependent
formatting and floating conversions belong to a later profile. This is not a
complete hosted-library checklist. `snprintf` and corresponding `v` forms are
selected C99 additions, not C90 claims.

For initial formatting, explicitly document support for `%d`, `%i`, `%u`,
`%o`, `%x`, `%X`, `%c`, `%s`, `%p`, `%%`, integer length modifiers and selected
flags/width/precision. Track unimplemented conversion semantics visibly.
Unsupported float formats must not consume arguments using an integer layout.
Do not mistake an integer-only formatter for complete standard `printf`.

### Why existing assembly I/O is insufficient

Console `CAST`/`POLL` macros are useful primitives, but they do not provide
standard stream objects, EOF/error policy, variadic argument decoding or return
counts. Assembly `memcpy`/`EX716_MEMMOVE` copies bytes but does not provide the
C API's destination-pointer result; an adapter is needed. Heap routines
require a heap ID and custom success conventions; `malloc`/`free` also need
startup ownership and exhaustion behavior.

DiskOS offers byte reads/writes and persistent file pointers. It should be a
backend for stdio, not be renamed to stdio:

- Its `ro`, `wo`, `rw`, `w+`, `a+` modes differ from C modes. In particular,
  current `wo` does not establish truncation, and DiskOS `w+` starts at EOF.
  Implement a separate mode translator and the missing operations.
- Line reads remove LF and pack status/length; a stdio adapter must reconstruct
  its own line and state contract. Reusing raw byte reads may be simpler.
- DiskOS close returns 1 for success; the C wrapper must translate results.
  Some file-open error paths print and end execution; stdio failures must return
  normally with stream/error information.
- Heap-backed FilePtr, ArgTable and sector buffers have distinct lifetimes.
  Initialization needs a disk heap and loaded filesystem header.
- The current runtime only supports a single 64 KiB block per file and does
  not follow host-tool extent chains. Do not represent larger files as working.
  Split large requests and check multiplication before computing size*count;
  a 16-bit `size_t` cannot represent an entire 65536-byte transfer.
- Runtime disk magic is `0x3044`; the host formatter defaults to `0x0716`.
  Use the explicit runtime magic in all isolated fixtures.

See [DiskOS guide](diskos-guide.md) and implementation comments for exact
contracts. DiskOS behavior was reviewed from source here; end-to-end C file
I/O was not tested because the C layer does not exist.

## Permanent test plan and operation

Keep the existing `run.py` as the quick historical smoke suite. Use
[`readiness.py`](../tests/csuite/readiness.py) for the development backlog:

```sh
# From EX716; refresh executables before trusting results.
make -C ../lcc BUILDDIR=build rcc cpp
python3 tests/csuite/run.py
python3 tests/csuite/readiness.py --json /tmp/c-readiness.json \
  --artifacts /tmp/c-readiness-evidence

# One task while implementing it, then the full audit.
python3 tests/csuite/readiness.py --filter LANG-016 \
  --modes classic,cpu24,segmented --artifacts /tmp/c-shadowing

# Compare statuses against the checked-in review baseline.
python3 tests/csuite/readiness.py --compare tests/csuite/readiness-baseline.json \
  --json /tmp/c-readiness-next.json

# Compatibility and actual segmented execution.
python3 tests/csuite/readiness.py --modes classic,cpu24,segmented \
  --json /tmp/c-readiness-all.json
```

Default mode is segmented CPU24. `classic` invokes `cpu.py`; `cpu24` uses
`common.mc` without entering segmented mode. The runner uses bundled `cpp -N`
and an explicit EX716 include directory, avoiding accidental host headers.
An absent target include directory deliberately produces missing-feature rows.
Once a runtime adapter exists, supply `--runtime /absolute/path/to/c_runtime.ld`
(repeatable); that file is included before generated C code. Change
`--include`, `--compiler`, `--cpp` only for a deliberate alternate build.

Tests run in independent temporary working directories, with the library
search path pointing to this checkout. They never use project disk images.
Sources may be embedded in the manifest, stored in a `file` relative to csuite,
or given as separate `units`. stdin and expected stdout can be specified;
stderr patterns are also supported. Test `main` must return int zero on success.
Use different nonzero returns for different failing assertions.

Every stage has a timeout (default 60 seconds), including preprocessing,
compilation and emulation; a timeout does not abort remaining entries.
`--jobs 1` makes diagnosis serial. Artifacts include preprocessed C, compiler
stderr, generated assembly, harness and emulator output. Reports hash tools,
manifest, backend, runtime libraries and existing C fixtures; hashes describe
the run's inputs, not a clean-repository guarantee.

The harness uses a fixed entry area at 0x7000, the current default software
stack, and test-specific marker output. It is for small probes, not a production
loader. Larger stress tests need their own explicit memory layout. A compiler
exit of zero is insufficient: known unsupported diagnostics are rejected,
unresolved symbols fail, result markers must be unique, result zero is required,
and SP/FP/empty-hardware-stack checks must pass.

Exit code is **1 whenever any selected entry is not PASS**, including
NOT_TESTED. That is intentional for a readiness gate. Filter an implemented
area when a green targeted result is needed. A missing executable/tool instead
produces argument error exit 2; unexpected runner exceptions appear as ERROR.

### How the checklist evolves without replacement

IDs are permanent. Never delete, skip, xfail, or loosen a requirement just
because it is currently unsupported. A future repair automatically changes
the same ID's result from failure to success. Status comparison highlights
that change; a previously passing probe that fails again is a regression.

The 28 `planned` entries deliberately stay NOT_TESTED. They include DiskOS
stream fixtures, `v` argument forwarding, 64-bit execution and production
startup/bounds. When implementing one, keep its ID and acceptance requirements,
replace `kind: planned` with an executable `source`/`file`/`units`, and add the
required fixture capability to this runner. This is incremental implementation
of the present plan, not invention of a new plan. Do not turn a header-only
compile into PASS for an I/O function.

Retain the small smoke case and add independent vector entries named, for
example, `IO-fread.zero`, `IO-fread.partial`, `IO-fread.error`. This makes each
semantic gap independently reportable; the parent's PASS is only a smoke
result. A release gate must select all required vectors, not just parent IDs.
Header entries intentionally certify compilation only. Declaration checks,
linking and semantic runtime checks are different obligations.

### Fixed fixture requirements for file/error tests

Implement these fixtures before certifying `IO-fopen` through `IO-fwrite`:

1. Inside each test's temporary directory create only `DISK00.disk` using
   `filesys/ex716disk.py format ... --disk-id 0x0716 --magic 0x3044
   --create-time 0`. Import files with explicit names and no extent chains.
2. Initialize a disjoint heap/stack/data layout and DiskOS in the C test
   startup adapter. Heap and filesystem initialization is part of the fixture,
   not a hidden assumption in a C function.
3. Seed empty, LF-terminated, unterminated-last-line, long-line and binary
   files. Binary payload must include 0x00,0x7f,0x80,0xff and span a 512-byte
   sector boundary. Seed an existing longer destination for truncation checks.
4. Cover all open modes, create/missing/truncate, repeated append after seek,
   complete/partial element counts, zero requests, failed permissions, seek
   directions, EOF-versus-error, pushback and read/write direction changes.
5. Close/reopen and export the image with the host tool to verify bytes and
   persisted size independently of the same C read routine. Check failed and
   successful open/close loops against heap availability/validation.
6. Inject deterministic allocation exhaustion and failed device operations;
   assert normal failure returns and errno/stream state. Add 65535/65536
   boundary tests without requiring a size_t value larger than its range.
7. Test process termination flush/cleanup separately. No existing repository
   disk image may be mounted, changed or formatted by these tests.

For formatting, retain the exact output/count fixture (`-7 100000 65535 ff Z ok`
has 23 characters) and add bounded-buffer canaries, size 0/1, truncation,
width/precision, sign/alternate-base, promotions and nested `v` forwarding.
For scanning, add mismatch, no-assignment EOF, suppression, whitespace,
bounded strings and destination canaries. For streams, test errors separately
from EOF and require failure returns without emulator termination.

These are project-specific verification vectors. API descriptions and
complete formatted-I/O contracts should be checked against the referenced
standard draft, rather than inferred from the names of existing routines.

## Implementation packets for a smaller-model handoff

The efficient unit of work is **one R item and its named IDs**, not this entire
report. Read this section, the item's row, its manifest entries and the relevant
source functions. Fetch generated artifacts only for those IDs. Do not begin
by re-reviewing the whole repository.

Recommended dependency order:

1. R01 diagnostic safety through R05 aggregate ABI/copy correctness are implemented for their current acceptance vectors.
2. R06 static data and literals; R08/R11 build, unit and header foundations.
3. R08 unit isolation and a reproducible target build; minimal
  `stddef.h`/`limits.h`/`errno.h` from R11. R10 is accepted for the current
  profile; revisit `SYS-001`/`SYS-003` with CPU memory management and hard
  interrupts.
4. R07 written variadic ABI and `stdarg.h`; first console stream layer.
5. String/heap C adapters, integer formatting and bounded formatting.
6. Isolated disk fixtures and byte/block file streams; then positioning.
7. R09 indirect calls/dense switches and later hosted/library breadth.
8. R12 numeric-model project (IEEE float or explicitly scoped fixed-point) only
   after rejection is reliable. Diagnostic safety is early even though numeric
   execution support is a later major project.

### Concrete starting points and bounded tasks

**R01 (complete):** Unsupported emit paths now report through lcc `error()`;
`I(emit)` also diagnoses code operators it does not recognize. The persistent
`SAFE-unsupported-*` probes require a matching diagnostic plus nonzero exit.
The compiler may have written partial assembly to stdout, so callers must honor
the nonzero exit and discard the output. When adding a new backend lowering
path, keep that contract. R01 does not implement the rejected feature, so its
corresponding `LANG-*` row stays FAIL.

**R02 (complete):** `ex716_add_local` assigns each parameter/local/temporary a
function-qualified ID alias. The caller and callee Symbols for each parameter
share the same alias because they describe one frame slot. `address()`-derived
`__ex716_offN` names remain aliases for existing byte offsets and are not
registered as additional locals. Assignment debug lines report function/frame,
source name, alias, byte offset and size; indirect destinations are explicitly
reported as runtime-offset. The first pass exposed two traps: derived address
symbols must not consume slots, and caller/callee parameter symbols must not
retain different aliases. `LANG-015/016/017` pass in classic, CPU24 shared and
segmented modes (9/9); the four-case C smoke suite passes (4/4). Evidence is in
`/tmp/ex716-r02-local-regression-final2/`.

**R03 (complete):** In `lib/div.ld`, `DIVU` now selects subtraction using
`IF_ULT_S` (unsigned carry logic), not the misleading `IF_UGE_S`, whose current
definition branches on signed `JLT`. `DIV` records dividend sign independently
from the quotient sign XOR, then negates the remainder only when the dividend
was negative. The helper still returns `[remainder, quotient]`. Expanded
`MATH-div16-signed`, `MATH-mod16-signed` and `MATH-div16-high` pass in all three
modes (9/9), covering all sign combinations, exact/inexact quotients, and high
unsigned values in both operand orders. `LANG-009`, signed 32-bit quotient and
remainder controls also pass in all modes (9/9); C smoke suite: 4/4. Evidence:
`/tmp/ex716-r03-div16-vectors/` and `/tmp/ex716-r03-math-regression/`. The
related `IF_UGE_S` contract is also fixed in `structure.asm` and
`structureDS.ld`: its skip branch now uses unsigned `JULT`. Classic and CPU24
boundary tests cover high-bit greater/equal/less cases; the high-bit DIVU probe
passes again. Full readiness audit has not been rerun.

**R04 (complete for near pointers):** `ex716_pointer_difference` handles the
frontend's divide-scaled and stride-one CVU/SUB forms. It compares 16-bit
offsets unsigned and emits signed magnitude without 32-bit math. `LANG-018`
now covers byte/int/long strides, both signs, assigned results and ordering;
both `MEM-pointer-*` controls pass in classic, CPU24 and segmented modes. The
high word of a future far pointer remains a segment ID, not an offset carry;
cross-segment subtraction is unsupported.

**R05 (complete for tested local aggregate ABI):** Block-typed ASGN uses exact
source/destination addresses even at widths 1, 2 and 4; larger blocks keep the
overlap-safe internal helper. The `LANG-005` hidden-result/aggregate-argument
path passes stack/frame checks after balancing the helper's condition words.
`LANG-029/030` now exercise exact sizes 1 through 4, and `LANG-005` exercises
6-byte copies and aggregate return/argument behavior. Public C `memcpy`, global
aggregate data, and broader ABI cases remain separate work.

**R06 (implemented for current acceptance vectors):** Data callbacks now use
the baseline assembler's `::label value`, `::__ value`, and repeated zero-fill
forms. Emission follows the active assembler data cursor rather than hardcoding
a bank: the segmented harness selects `.DATA 1`, while classic/shared tests use
their unified address space. `LANG-019` through `024` pass with CS != DS,
including initialized locals/globals, arrays, struct padding, strings/escapes,
zeroed globals, distinct initialized statics, and object/function/offset
pointer initializers. Floating data remains rejected; multi-unit identity and
imports/exports remain R08, not data-value emission.

**R07 (implemented for current acceptance subset):** Variadic calls use a caller-owned packet, not a sentinel and not a
callee-sized pop from the hardware stack. Its first 16-bit field is the number
of payload bytes (excluding the header); the payload contains only default-
promoted scalar values and pointers in `va_arg` traversal order. Each value's
word layout must match the EX716 argument push/consume convention, including
32-bit values. Aggregate values passed through `...` are initially diagnosed
as unsupported; pointers to aggregates/strings are ordinary pointer items.
The caller owns the packet through the call and reclaims it afterward while
preserving the return value. A zero-optional-argument call has a valid empty
packet. Only calls whose function type is variadic use this path; fixed calls
retain their present argument layout and cleanup. `va_start` initializes the
cursor from the hidden packet pointer; typed `va_arg` fetches one item and
advances it; `va_end` has no packet ownership to release. The target
implementation must not copy host x86 `stdarg.h` assumptions. Make
`LANG-026`/`027` pass in classic, CPU24 and segmented modes before implementing
variadic formatting. The implementation is intentionally limited to 2- and
4-byte non-floating scalar/pointer items; float-typed items and aggregates are
diagnosed as unsupported. `stdarg.h` uses two static helper routines, so
multi-translation-unit linkage now passes the current R08 assembly-combiner
tests. Frame capacity defaults to 256 bytes; frames above that limit are not
certified.

**R08 current profile:** Separate compilations retain external names and use
automatic deterministic namespaces for every private/generated symbol. The
two-unit execution probes pass in all modes. The audit's assembly concatenation
is the current link model; `SYS-002` still needs a production build/combiner
fixture with explicit duplicate-public and unresolved-external diagnostics.

**R10 accepted profile:** The generated entry initializes a heap-backed,
adjustable 4-KiB software stack and checks each frame reservation. Keep
`SYS-001` and `SYS-003` planned, not PASS: production lifecycle and full
segment/heap/stack isolation are deferred until CPU memory management and hard
interrupts.

**R11/stdio:** Add the target include directory and C adapters. Start
unbuffered console streams so state/return values are correct before
buffering. Map each I/O function's existing ID to an executable public-header
test. Implement allocation and disk fixtures before claiming file-stream
support. Do not use host libc as a proxy for the EX716 runtime.

For each task, the handoff record should contain only: requirement/IDs, files
changed, design decision, before/after status, verification command and any
remaining acceptance vectors. Rebuild `rcc` for backend changes; runtime-only
changes still need the actual CPU tests. Run targeted three-mode checks and
the original four-case smoke suite, then the full readiness audit. Compare to
the review baseline and explain any regression before moving to the next item.

Do not overwrite the review baseline merely to make failures disappear; save a
new JSON checkpoint. Update this report only for a material change in scope or
architecture. The manifest and checkpoints carry day-to-day progress.

## Release gates

**Restricted integer applications:** R01–R08 core correctness, usable checked
frames, target headers, deterministic build/startup, and all selected integer,
pointer, aggregate and unit tests green. Any deferred extension rejects.

**Console applications:** Above, plus stdarg, standard console streams, bounded
line input, EOF/error state and required integer formatting vectors green.

**File applications:** Above, plus isolated DiskOS read/write/mode/seek/error,
persisted-data and cleanup vectors green, with file-size limits documented.

**Broader standard-library compatibility:** Incremental later gate; complete
library/language conformance requires additional requirements beyond this
practical profile. No percentage of smoke-test passes establishes it.

The source distribution's `lcc/CPYRIGHT` includes use/distribution conditions.
Keep that notice intact and review those conditions before packaging a derived
toolchain. This review does not evaluate commercial licensing.
