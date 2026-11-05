# Segmented heap and software-stack plan

## Decision

Keep the existing `softstack.ld` and `heapmgr.ld` as the **near, DS-pinned**
runtime.  They remain the default for legacy/Ring 0 programs and for CPU24
programs that choose a DS at startup and retain it.  Their 16-bit heap and
object identifiers intentionally never name another bank.

Do not attempt to make an existing `HeapID` or `ObjectID` cross a 64 KiB
boundary.  Doing so would silently reinterpret every existing object link and
ordinary pointer.  Large-memory programs instead use two explicit mechanisms:

1. ES/far handles for data outside the active DS.
2. DS contexts only at explicit execution boundaries, where all ordinary
   calls/frames in the old context have been unwound.

## Immediate compatibility work

Add an assembly convenience macro for the safe startup case:

```assembly
# DS is selected; `DataEnd` and `HeapTop` are offsets in that same bank.
@InitDSHeap DataEnd HeapTop MainHeap
@InitDSSoftStack MainHeap 0x0800
```

It must calculate the heap size from a data-segment end symbol (normally
`__DEND`), not `ENDOFCode`.  It returns/stores ordinary near values and is a
documented wrapper around `HeapDefineMemory`, `HeapNewObject`, and
`SetSSStack`.  The historical `ENDOFCode..0xff00` pattern remains valid only
for unsegmented programs.

Correct the existing public-name mismatch before exposing new APIs:
`SaveSSStack`/`RestoreSSStack` are exported and used by convenience macros,
but the implementations are labelled `SaveStack`/`RestoreStack`.

## DS-local stack API: `softstackds.ld`

This is a context-aware successor, not a replacement for old source.

```text
DSSInit(top, bottom) -> status
DSSSave(record_near) -> status
DSSRestore(record_near) -> status
DSSRemaining() -> bytes
DSSContextEnter(context_far) -> status
DSSContextLeave(context_far) -> status
```

Each active DS owns one record at known offsets in that DS:

```text
DSStackRecord (all offsets are in its owning DS)
    magic/version
    bottom
    top
    sp
    guard/checksum
```

The `@DSPUSHRETURN`, `@DSPOPRETURN`, `@DSLocals`, and `@DSEndLocals` macros
operate only on the active DS record.  They retain the familiar near-pointer
calling convention, so a function cannot switch DS while it owns one of these
frames.  `DSSContextEnter` is therefore legal only at a documented context
gateway with an empty hardware stack except for its gateway return state.

The initial DS stack remains within one bank.  A stack larger than 64 KiB is
not a first-version goal: frame pointers and local addresses are 16-bit, and
making one stack span banks would require a different far-frame ABI.

## Far-heap API: `farheap.ld`

One heap resides wholly inside one data bank.  Its descriptor is a normal
near object owned by the active DS; its allocations return explicit far
objects.

```text
FarHeapDescriptor
    version/flags
    segment
    base
    limit_exclusive
    first_object

FarObject
    offset
    segment
```

Proposed operations:

```text
FHeapDefine(descriptor_near, segment, base, size) -> status
FHeapAlloc(descriptor_near, size, far_object_out_near) -> status
FHeapFree(descriptor_near, far_object_near) -> status
FHeapResize(descriptor_near, far_object_near, size, far_object_out_near)
FHeapAvailable(descriptor_near) -> bytes
```

Implement the internal header walk with ES overrides, saving/restoring ES on
every public operation.  The underlying allocator can reuse the current
single-bank free-list layout after all accesses are abstracted behind
ES-relative load/store helpers.  No allocation may wrap or spill into the
next segment; callers choose another far-heap descriptor when a bank is full.

An object is accessed through `FarObject`/ES helpers, never by treating its
offset as an ordinary `T *` or `ObjectID`.  This matches the established
`farptr.ld` rule and lets a DS-pinned application use many heap banks without
switching DS.

## Context switching

`DataContext` owns a DS bank, an initialized DS stack record, and its
near-heap roots.  It is a scheduling/module boundary, not a general pointer
conversion facility.  A root/loader context must hold the far location of
each context descriptor so it can select a new DS without relying on old
near globals after the switch.

Context entering/leaving must preserve ES, verify the stack magic/guard, set
DS only after saving the outgoing stack state, and restore the incoming state
before ordinary code is allowed to run.  Sharing data between contexts still
uses far objects/ES, never a retained near pointer.

## Test sequence

1. Keep `tests/cpu24-segment-memory.asm` as the current-contract regression:
   two independently initialized DS-local heaps return separate values, and
   `farptr.ld` preserves ES.
2. Add `DSSInit` overflow/underflow/guard tests and reject a context switch
   with active DS frames.
3. Add two `FarHeapDescriptor` instances in separate banks; allocate, read,
   resize, free, and validate both while DS remains pinned.
4. Assert ES restoration on success and all allocation failures.
5. Assert base/size rejection for offset wrap, MMIO-reserved ranges, and any
   request that could cross a bank boundary.
6. Add only then a two-context gateway test: switch DS 1 -> DS 2 -> DS 1,
   with no live near frame crossing the gateway and with far data shared
   correctly through ES.
