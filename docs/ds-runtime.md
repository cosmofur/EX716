# DS-local runtime libraries

`softstackDS.ld` and `heapmgrDS.ld` are the new near-memory runtime for a
segmented CPU24 program.  They are intentionally separate from the legacy
`softstack.ld` and `heapmgr.ld`; do not load both stack/heap families into the
same program.

`softstackDS.ld` is selected in place of `softstack.ld`, not alongside it. It
owns the familiar `@PUSHRETURN`, `@POPRETURN`, `@PUSHHW`, `@POPHW`,
`@Locals`, `@Local`, `@Local32`, `@EndLocals`, `@LocalVar`, and `@RestoreVar`
spellings, as well as the `SetSSStack` routine. Existing function bodies can
therefore retain their normal headers; only the selected library and startup
initialization change. `DSS*` names remain available for code that wants to
make the choice explicit.

The stack itself is fixed in a configured segment (normally DS 1 for the
simple form). The DS0 root record occupies offsets `0000..0006`, declared
before the normal `Var01` convention; every stack helper saves the caller's DS/ES,
selects that fixed segment, and restores the caller's state. Application DS
may therefore change between calls, but must not change in the middle of an
open stack frame.

Heap identifiers, object identifiers, locals, and object links are near
offsets in the active application DS. Select DS before a heap operation and
do not change it while that function has a live frame. A different DS needs
its own heap initialization, while the fixed stack initialization is shared.

## Setup

`HeapDSInit` is a macro, so it needs no previously initialized stack.  It
reserves a software stack at the top of the supplied DS range and creates a
heap below it.

```assembly
M UseSoftStackDS 1
.CODE 0
.ORG 0x0100          # reserve low CS0 offsets for the DS0 root
.DATA 1
I commonDS.mc       # auto-loads softstackDS.ld when opted in
L heapmgrDS.ld

::MainHeap 0

:Main
    @PUSH 1 @SSET SegDS
    @PUSH 1 @ADM

    # heap: [__DEND, 0xe000); fixed stack (DS 1): [0xe000, 0xf000)
    @HeapDSInit MainHeap __DEND 0xf000 0x1000
```

For a dedicated stack bank, use `@HeapDSInitS heap bottom top stack_bytes
stack_segment` once during startup. After changing application DS, initialize
only that bank's heap with `HeapDSDefineMemory`; do not reinitialize the fixed
stack. Every range must stay in one 64 KiB bank and must not overlap static
data, MMIO, or another reserved region.

## Soft stack API

```text
@DSSInitAB top_exclusive bottom
@DSSInitAS bottom size
@DSSPushReturn / @DSSPopReturn
@DSSPushHW / @DSSPopHW
@DSSLocals / @DSSLocal name / @DSSEndLocals
DSSRemaining() -> bytes to bottom
```

The equivalent historical names are selected automatically.  Each push/return
or locals scope must still be paired normally.

## Heap API

```text
HeapDSDefineMemory(base, size) -> heap ID or 0
HeapDSNewObject(heap ID, bytes) -> object ID or 0
HeapDSDeleteObject(heap ID, object ID) -> 0 or error
HeapDSObjectSize(heap ID, object ID) -> bytes
HeapDSAvailable(heap ID) -> free bytes
```

The allocator is first-fit and splits sufficiently large free blocks.  Delete
marks a block free; the next allocation may reuse it.  This first version
does not expose resize or compaction.

## Extended memory boundary

This is **not** the far heap planned for large shared data.  HeapDS objects
are near pointers and become invalid when DS changes.  Keep DS pinned for an
ordinary module/program and use the established ES/far-pointer helpers for
cross-bank data.  A later `farheap.ld` will return explicit `{offset,
segment}` handles and must never be passed to HeapDS.
