# Current segmented-memory contract probe.
#
# This is intentionally not a far heap implementation.  It proves that the
# existing near heap/soft-stack libraries can operate in two banks only when
# each bank has separately initialized runtime metadata, and that a near
# pointer is meaningful only while its DS is selected.
.DATA 1
I commonDS.mc
L softstack.ld
L heapmgr.ld
L farptr.ld

::HeapOne 0
::ObjectOne 0
::HeapTwo 0
::ObjectTwo 0
::ProbeFar 0x0400 2

.ORG 0x2000
:Main
@PUSH 1
@SSET SegDS
@PUSH 1
@ADM

# DS 1 uses the initialized library defaults and owns its first heap.
@PUSH 0x0100
@PUSH 0x2000
@CALL HeapDefineMemory
@POPI HeapOne
@PUSHI HeapOne
@PUSH 16
@CALL HeapNewObject
@POPI ObjectOne
@PUSH 0x1111
@PUSHI ObjectOne
@POPS

# A DS switch does not carry software-stack state.  Initialize a separate
# context at the same logical offsets in DS 2 before calling library code.
@PUSH 2
@SSET SegDS
@PUSH 0xdffe
@POPI __SS_TOP
@PUSH 0xe000
@POPI __SS_SP
@PUSH 0xd000
@POPI __SS_BOTTOM
@PUSH 0x0100
@PUSH 0x2000
@CALL HeapDefineMemory
@POPI HeapTwo
@PUSHI HeapTwo
@PUSH 16
@CALL HeapNewObject
@POPI ObjectTwo
@PUSH 0x2222
@PUSHI ObjectTwo
@POPS

# Switching back recovers the first bank's independent heap and stack state.
@PUSH 1
@SSET SegDS
@PRT "DS1="
@PUSHI ObjectOne
@PUSHS
@PRTHEXTOP
@POPNULL
@PRTNL

@PUSH 2
@SSET SegDS
@PRT "DS2="
@PUSHI ObjectTwo
@PUSHS
@PRTHEXTOP
@POPNULL
@PRTNL

# Far data uses ES and preserves it, leaving DS 1 and its near heap intact.
@PUSH 1
@SSET SegDS
@PUSH 3
@SSET SegES
@PUSH ProbeFar
@PUSH 0xbead
@CALL ex716_far_put16
@PUSH ProbeFar
@CALL ex716_far_get16
@PRT "FAR="
@PRTHEXTOP
@POPNULL
@PRT " ES="
@SGET SegES
@PRTHEXTOP
@POPNULL
@PRTNL

@PUSH 0
@ADM
@END
