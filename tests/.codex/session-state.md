# Session state

- Standing roadmap: read `FuncCalc-Design-Plan.md` before planning major FuncCalc language or runtime changes. Its priority order is Value model, real LIST collections, first-class functions, execution contexts, cofunctions, coherent library growth, and then additional syntax sugar; string concatenation is the early exception.

- Objective: develop FuncCalc's core control flow, scoping, shared CPU implementation, and basic console I/O.
- Completed: fixed BLOCK classification, assignment parsing, and DEFUN body collection; added global-by-default assignment, explicit `LOCAL`, implicit-local parameters, `WHILE`, inline `FOR({init},test,{body})`, first-match lazy `SWITCH(value,case,statement,...,default)`, TRUE/FALSE constants, numeric/string equality and inequality, braces, `BREAK`, nested `BREAK(depth)`, and `CONTINUE`. Added `INPUT([prompt])`, `INPUTINT([prompt])`, blocking/polling `GETKEY([wait])`, plus persistent `TTYRAW()`/`TTYCOOKED()` controls. Extracted the shared implementation to `FuncCalcCore.asm`; `FuncCalc.asm` and `FuncCalc24.asm` are small target wrappers using `I FuncCalcCore.asm`.
- Modified files: `FuncCalcCore.asm` (new shared implementation), `FuncCalc24.asm`, `FuncCalc.asm`, `FuncCalc.md`, and this handoff note.
- Verification: CPU24 loop-control and FOR tests passed. SWITCH passed numeric/string selection, TRUE predicate cases, string `=`, lazy unselected branches, default blocks, first-match behavior, BREAK and RETURN propagation, malformed-pair errors, and default-only form. INPUT prompt/string and INPUTINT signed conversion passed scripted CPU24 tests. Final smoke tests passed through both `cpu24.py`/`FuncCalc24.asm` and `cpu.py`/`FuncCalc.asm`, with zero unresolved symbols.
- Findings: CPU24 still warns that the source has no `.ENTRY` directive and uses legacy `.ORG`. Explicit `LOCAL` outside a function correctly errors.
- Repository: local `Dev_072426` is now current with `origin/Dev_072426`; the pulled commit changed `cpu.py`, `cpu24.py`, and `speedCPU.c`, not the FuncCalc files.
- Decisions: `GETKEY()` and `GETKEY(TRUE)` block; `GETKEY(FALSE)` polls and returns an empty string when no key is ready. Polling does not toggle terminal state; callers use `TTYRAW()` once before a polling loop and `TTYCOOKED()` afterward. Character-mask/formatted input remains deferred.
- Known issue: piped-input testing of blocking GETKEY is affected by stream/line timing and is not a substitute for an interactive raw-terminal test.
- Next step: consider formatted input masks and broader interactive GETKEY tests.
