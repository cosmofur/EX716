! __LIB_SOFTSTACK_DS_LOADED
M __LIB_SOFTSTACK_DS_LOADED 1
P Loading softstackDS.ld
I softstackDS.ref

# DS-local software stack for CPU24 segmented programs.
#
# Stack control and storage live in one fixed data segment.  Every push/pop
# helper saves the caller's DS, briefly selects that segment, then restores
# DS before returning.  DSSInitAB is a macro, so it can establish the stack
# before any stack-backed routine runs.

G __DSS_TOP G __DSS_BOTTOM G __DSS_SP G __DSS_MAGIC
G __DSS_MOVE_HW_SS G __DSS_MOVE_SS_HW G DSSRemaining
G __SS_TOP G __SS_BOTTOM G __SS_SP
G __MOVE_HW_SS G __MOVE_SS_HW G SetSSStack
G __DSS_StackError

=DSS_MAGIC_VALUE 0x4453

@JMP __DSS_SKIP
? CPU24_SEGMENTED
::__DSS_TOP 0xfff0
::__DSS_BOTTOM 0xff00
::__DSS_SP 0xfff2
::__DSS_MAGIC DSS_MAGIC_VALUE
::DSSInitDS 0
::DSSInitES 0
ENDBLOCK
! CPU24_SEGMENTED
:__DSS_TOP 0xfff0
:__DSS_BOTTOM 0xff00
:__DSS_SP 0xfff2
:__DSS_MAGIC DSS_MAGIC_VALUE
ENDBLOCK
:__DSS_DATA_END

# The root record is addressed through ES=0 while application DS remains
# untouched.  On entry these macros preserve both caller DS and ES; between
# them DS is the configured stack bank and ES remains 0 for root access.
M DSSSaveCallerToRoot `\
  @SGET SegES ; @PUSH 0 ; @SSET SegES ; \
  @PUSH __SS_ROOT_SAVED_ES ; @ESO @POPS ; \
  @SGET SegDS ; @PUSH __SS_ROOT_SAVED_DS ; @ESO @POPS \
`
M DSSEnterStackSegment `\
  @DSSSaveCallerToRoot ; \
  @PUSH __SS_ROOT_STACK_DS ; @ESO @PUSHS ; @SSET SegDS \
`
M DSSLeaveStackSegment `\
  @PUSH __SS_ROOT_SAVED_DS ; @ESO @PUSHS ; @SSET SegDS ; \
  @PUSH __SS_ROOT_SAVED_ES ; @ESO @PUSHS ; @SSET SegES \
`

# Initialize [bottom, top) in the current DS.  The top word is reserved as
# the empty-stack sentinel, matching the original softstack convention.
M DSSInitABS `\
  @DSSSaveCallerToRoot ; \
  @PUSH %1 ; @PUSH __SS_ROOT_STACK_DS ; @ESO @POPS ; \
  @PUSH DSS_MAGIC_VALUE ; @PUSH __SS_ROOT_MAGIC ; @ESO @POPS ; \
  @PUSH %1 ; @SSET SegDS ; \
  @PUSH %2 ; @SUB 2 ; @POPI __DSS_TOP ; \
  @PUSH %2 ; @POPI __DSS_SP ; \
  @PUSH %3 ; @POPI __DSS_BOTTOM ; \
  @PUSH DSS_MAGIC_VALUE ; @POPI __DSS_MAGIC ; \
  @DSSLeaveStackSegment \
`
M DSSInitAB `\
  @DSSInitABS 1 %1 %2 \
`
M DSSInitAS @DSSInitAB %1+%2 %1
# Quick programs: reserve CS0:0000..00ff with .ORG 0x0100 and use .DATA 1.
# Call once at entry; bank 1 offsets ff00..ffef are reserved for the stack.
M DSSInitQuick @PUSH 1 @SSET SegDS @PUSH 1 @ADM @DSSInitAB 0xfff0 0xff00
M DSSInitASS @DSSInitABS %1 %2+%3 %2

M DSSInitLegacy `\
  @PUSH %1 ; @SUB 2 ; @POPI __DSS_TOP ; \
  @PUSH %1 ; @POPI __DSS_SP ; \
  @PUSH %2 ; @POPI __DSS_BOTTOM ; \
  @PUSH DSS_MAGIC_VALUE ; @POPI __DSS_MAGIC \
`

M DSSPushReturn @CALL __DSS_MOVE_HW_SS
M DSSPopReturn @CALL __DSS_MOVE_SS_HW
M DSSPushHW @CALL __DSS_MOVE_HW_SS
M DSSPopHW @CALL __DSS_MOVE_SS_HW
M DSSPushLocalI @PUSHI %1 @CALL __DSS_MOVE_HW_SS
M DSSPopLocal @CALL __DSS_MOVE_SS_HW @POPI %1

# Scoped aliases reuse Var01..Var20, but preserve them in the DS-local stack.
M DSSLocalVar = %1 Var%2 @PUSHI Var%2 @CALL __DSS_MOVE_HW_SS
M DSSRestoreVar `@CALL __DSS_MOVE_SS_HW @POPI Var%1`
M DSSLocals `MF DSSVarCount 1 ; MF DSSVarLimit 0`
M DSSLocal `\
  MF DSSLocalNum {DSSVarCount} ; \
  @DSSLocalVar %1 {DSSLocalNum} ; \
  MF DSSVarCount %EVAL {DSSLocalNum}+1 ; \
  MF DSSVarLimit {DSSLocalNum} \
`
M DSSEndLocals `\
  %REPEAT {DSSVarLimit} \
    MF DSSVarCount %EVAL {DSSVarCount}-1 ; \
    MF DSSLocalNum {DSSVarCount} ; \
    @DSSRestoreVar {DSSLocalNum} ; \
  %ENDR \
`

# Drop-in public macro set.  Select this file *instead of* softstack.ld, so
# normal assembly and generated code retain their established spellings.
M PUSHRETURN @DSSPushReturn
M POPRETURN @DSSPopReturn
M PUSHHW @DSSPushHW
M POPHW @DSSPopHW
M POPLOCAL @DSSPopLocal %1
M POPLOCALII @DSSPopHW @POPII %1
M TOPLOCAL @CALL __DSS_PEEK_SS_HW
M PUSHLOCALI @DSSPushLocalI %1
M PUSHLOCALII @PUSHII %1 @DSSPushHW
M PUSHLOCAL @PUSH %1 @DSSPushHW
M LocalVar = %1 Var%2 @PUSHI Var%2 @DSSPushHW
M RestoreVar `@DSSPopHW @POPI Var%1`
M Locals @DSSLocals
M Local @DSSLocal %1
M Local32 @DSSLocal %1 @DSSLocal %1.high
M EndLocals @DSSEndLocals

@FUNCTION __DSS_MOVE_HW_SS
:__DSS_MOVE_HW_SS
@DSSEnterStackSegment
@PUSHI __DSS_SP
@SUB 2
@IF_ULT_V __DSS_BOTTOM
   @POPNULL
   @JMP __DSS_StackError
@ENDIF
@POPNULL
@SWP
@DEC2I __DSS_SP
@POPII __DSS_SP
@DSSLeaveStackSegment
@RET
@ENDFUNCTION

@FUNCTION __DSS_MOVE_SS_HW
:__DSS_MOVE_SS_HW
@DSSEnterStackSegment
@PUSHI __DSS_SP
@IF_UGT_V __DSS_TOP
   @POPNULL
   @JMP __DSS_StackError
@ENDIF
@POPNULL
@PUSHII __DSS_SP
@INC2I __DSS_SP
@SWP
@DSSLeaveStackSegment
@RET
@ENDFUNCTION

@FUNCTION __DSS_PEEK_SS_HW
:__DSS_PEEK_SS_HW
@DSSEnterStackSegment
@PUSHI __DSS_SP
@IF_UGT_V __DSS_TOP
   @POPNULL
   @JMP __DSS_StackError
@ENDIF
@POPNULL
@PUSHII __DSS_SP
@SWP
@DSSLeaveStackSegment
@RET
@ENDFUNCTION

@FUNCTION DSSRemaining
:DSSRemaining
@DSSPushReturn
@DSSEnterStackSegment
@PUSHI __DSS_SP
@SUBI __DSS_BOTTOM
@ADD 2
@DSSLeaveStackSegment
@DSSPopReturn
@RET
@ENDFUNCTION

# Legacy initialization entry used by existing callers. On its first call it
# binds the software stack root to the current DS; later calls can update the
# range without depending on an already initialized DS stack.
@FUNCTION SetSSStack
:SetSSStack
@SGET SegES @POPI DSSInitES
@SGET SegDS @POPI DSSInitDS
@PUSH 0 @SSET SegES
@PUSHI DSSInitDS @PUSH __SS_ROOT_STACK_DS @ESO @POPS
@PUSHI DSSInitDS @PUSH __SS_ROOT_SAVED_DS @ESO @POPS
@PUSHI DSSInitES @PUSH __SS_ROOT_SAVED_ES @ESO @POPS
@PUSH DSS_MAGIC_VALUE @PUSH __SS_ROOT_MAGIC @ESO @POPS
@PUSHI DSSInitDS @SSET SegDS
@SWP
@POPI __DSS_BOTTOM
@SWP
@SUB 2
@POPI __DSS_TOP
@MV2V __DSS_TOP __DSS_SP
@INC2I __DSS_SP
@PUSH DSS_MAGIC_VALUE
@POPI __DSS_MAGIC
@PUSHI DSSInitES @SSET SegES
@RET
@ENDFUNCTION

:__DSS_StackError
@PRTLN "Error. DS Software Stack Out of Bounds"
@END

# Compatibility aliases: only one soft-stack library may be selected.  These
# preserve code that reads the historical control variables directly.
=__SS_TOP __DSS_TOP
=__SS_BOTTOM __DSS_BOTTOM
=__SS_SP __DSS_SP
=__MOVE_HW_SS __DSS_MOVE_HW_SS
=__MOVE_SS_HW __DSS_MOVE_SS_HW

:__DSS_SKIP
ENDBLOCK
