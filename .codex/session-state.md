# Session State

Last updated: 2026-09-25

## Current objective

Continue FuncCalc language development on the now-tested CPU24 segmented-code
foundation. The next language milestone is complete Boolean behavior followed by
statement-level IF and WHILE control flow.

## Checkpoint completed

- CPU24 initialized data declarations use `::name initializer [* count]`, with
  `::__` as a repeatable throw-away field.
- CPU24 supports `.CODE`, `.ENTRY`, physical banked placement, `FJMPS`, and the
  `FJMP`/`FCALL`/`FENTER`/`FRET` far-call convention.
- `tests/cpu24-far-code.asm` covers three code banks, explicit entry, nested far
  calls, local calls, returned values, WHILE/IF macros, and reused local-symbol
  lookup across code banks.
- The CPU24 debugger is segment-aware for CS:PC display, disassembly, source and
  label ranges, label navigation, reset, breakpoints, named data inspection,
  and watches.
- FuncCalc supports signed `<`, `<=`, `>`, `>=`, logical `&&`, and logical `||`.
  Results are canonical 32-bit integer 0 or 1. Precedence is arithmetic,
  comparison, `&&`, then `||`; parentheses and function arguments accept the
  full grammar.
- `lib/lmath.ld` signed `IF32_LT/LE/GT/GE` helpers normalize the emulated
  overflow flag before comparing it with the emulated negative flag, fixing
  signed-overflow boundary cases.
- FuncCalc documentation and interactive help describe the new operators.

## Verification

- CPU24 and legacy FuncCalc comparison suites passed for ordinary and negative
  values, precedence, parentheses, `IF(...)`, and
  `2147483647 > -2147483648`.
- `python3 cpu24.py tests/cpu24-far-code.asm` prints
  `CPU24 far-code PASS`.
- Scripted debugger execution stopped at `FarLoop` in `01:0200` and `FarValue`
  in `02:0300`; `p ReusedLocal` selected `01:0030 = 1111` in the first function
  and `01:0032 = 2222` in the second.
- CPU24 and legacy FuncCalc both evaluate `PRINT 1+2` as `3`.
- `python3 -m py_compile cpu.py cpu24.py` and `git diff --check` pass.
- `tests/lmath_test.o.asm` runs to completion but has a pre-existing unresolved
  string-like symbol and questionable archival division expectations.

## Decisions

- Code labels remain 16-bit offsets plus assembler/debugger bank metadata.
- Cross-bank control flow uses explicit bank+offset far operations.
- `&&` and `||` currently evaluate both operands; short-circuit semantics have
  not yet been implemented.
- `CPU24_SEGMENTED` selects segmented library storage without changing ordinary
  CPU24 Ring 0 layouts.
- WSL1 requires command escalation only to bypass the unavailable bubblewrap
  user-namespace launcher.

## Next steps

1. Add `==` and `!=` to complete the comparison set.
2. Implement short-circuit behavior for `&&` and `||`.
3. Implement FuncCalc statement-level IF using normalized Boolean results.
4. Replace `FCWhileBlock` with working WHILE execution, then test nested IF and
   WHILE, RETURN from blocks, and eventual BREAK behavior.
5. Diagnose ordinary near JMP/CALL references that cross code banks.
6. Add explicit numeric `bank:offset` debugger syntax.
7. Add `.ENTRY Main` to FuncCalc24 and split expression evaluation into another
   code bank using the tested far-call convention.
8. Decide separately whether to modernize or retire `lib/common-reloc.mc`.
