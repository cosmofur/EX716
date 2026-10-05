# EX716 Documentation Map

This page identifies the purpose and authority of the active documentation.
For implementation details, current Python and assembly sources remain the
final authority; documentation should be corrected when it differs from code.

## Current project and programming guides

| Document | Purpose and role |
| --- | --- |
| [`../README.md`](../README.md) | Project entry point: capabilities, layout, basic invocation, and links into the detailed guides. It should remain concise and current. |
| [`programming-guide.md`](programming-guide.md) | Primary programmer guide for the `cpu.py` and `cpu24.py` machine models, native instruction families, segmented mode, calling conventions, style, and debugging. |
| [`library-appendix.md`](library-appendix.md) | Quick-reference tables for common/structured macros and the main lmath, random, string, heap, and software-stack services. |
| [`diskos-guide.md`](diskos-guide.md) | Primary runtime DiskOS guide: heap ownership, physical layout, metadata tables, open modes, line I/O, close discipline, and host-tool compatibility. |
| [`c-readiness.md`](c-readiness.md) | lcc/EX716 readiness review, demonstrated compiler/ABI gaps, standard C I/O priorities, release gates, and permanent test plan. |
| [`c-implementation-handoff.md`](c-implementation-handoff.md) | Implementation starting point: economical-model instructions, exact audit commands, critical-path task order, and reasoning traps. |
| [`../Macro.md`](../Macro.md) | Tutorial for the assembler's macro language itself, including parameters, unique tokens, macro state, and conditional expansion. |
| [`../CPU2CPU24.txt`](../CPU2CPU24.txt) | Detailed migration checklist for converting a classic `cpu.py`/Ring 0 program to CPU24 segmented Ring 1 storage and execution. |

## Subsystem and language documentation

| Document | Purpose and role |
| --- | --- |
| [`../filesys/README.md`](../filesys/README.md) | Command reference for the host-side `ex716disk.py` image utility. Its magic/extent warning defines how to create images compatible with runtime DiskOS. |
| [`../filesys/README.txt`](../filesys/README.txt) | Version and regression-verification record for the current `ex716disk.py` 0.5.0 artifact, including its checksum. It is release metadata, not a filesystem design guide. |
| [`../tests/FuncCalc.md`](../tests/FuncCalc.md) | User-facing FuncCalc language syntax, operators, functions, and interactive behavior. |
| [`../tests/FuncCalc-Design-Plan.md`](../tests/FuncCalc-Design-Plan.md) | Implementation plan and development status for FuncCalc. Treat incomplete milestones as design intent rather than shipped behavior. |

## Lessons and background references

| Document | Purpose and role |
| --- | --- |
| [`lesson01.md`](lesson01.md) through [`lesson05.md`](lesson05.md) | Introductory sequence covering early EX716 assembly concepts and basic programming exercises. |
| [`lesson06.md`](lesson06.md) through [`lesson10.md`](lesson10.md) | Intermediate lessons that build larger routines and introduce more assembler/macro techniques. |
| [`lesson11.md`](lesson11.md) through [`lesson16.md`](lesson16.md) | Later lessons and worked examples. These are teaching material; use the programming guide when a historical lesson conflicts with current syntax. |
| [`8086.txt`](8086.txt) | Background notes on the Intel 8086. This is comparative/reference material, not an EX716 specification. |
| [`m68000.txt`](m68000.txt) | Background notes on the Motorola 68000. This is comparative/reference material, not an EX716 specification. |
| [`cheetsheet1.mc`](cheetsheet1.mc) | Assembly/macro cheat-sheet source used alongside the lessons. Despite living in `docs/`, it is code-like reference material rather than prose. |

## Generated and source-adjacent references

| Document family | Purpose and role |
| --- | --- |
| `lib/*.ref` | Function/link dependency indexes consumed alongside dynamic libraries. They are source metadata and concise API clues, not substitutes for the guides or `.ld` implementation comments. |
| `lib/fat16lib.txt` | Notes/reference material for the separate FAT16 experiment. FAT16 is not DiskOS. |
| `cpu.info` | Source-description input associated with generated CPU indexes. It is maintenance data, not the public CPU programming guide. |
| `emacs_debug.txt` | Editor/debugging notes for a specific development workflow; optional and not part of the architecture contract. |

## Archive

Files under [`archive/`](archive/) are retained for historical context only.
They describe old implementations, future concepts, or stale generated indexes
and must not be used as current API or architecture references.
