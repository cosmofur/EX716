! __LIB_BANKED_RUNTIME_B2_LOADED
M __LIB_BANKED_RUNTIME_B2_LOADED 1

# Bank-2 C-frame support.  Load this file while .CODE 2 is selected and
# rewrite compiler-generated frame macros to their B2_ equivalents.  Stack
# metadata and storage remain in the shared DS bank; only executable helpers
# are copied into this code bank.

G B2_MOVE_HW_SS G B2_MOVE_SS_HW G B2_SS_StackError

M B2_PUSHRETURN @CALL B2_MOVE_HW_SS
M B2_POPRETURN @CALL B2_MOVE_SS_HW

# Compatibility layer for the older assembly helpers.  It has the same
# save/restore discipline as softstack.ld's deprecated @Locals family, but
# never emits a near call into bank 0.
M B2_LocalVar = %1 Var%2 @PUSHI Var%2 @CALL B2_MOVE_HW_SS
M B2_RestoreVar @CALL B2_MOVE_SS_HW @POPI Var%1
M B2_Locals `MF __B2_VarCount 1 ; MF __B2_VarLimit 0`
M B2_Local `\
  MF __B2_LocalNum {__B2_VarCount} ; \
  @B2_LocalVar %1 {__B2_LocalNum} ; \
  MF __B2_VarCount %EVAL {__B2_LocalNum}+1 ; \
  MF __B2_VarLimit {__B2_LocalNum} \
`
M B2_EndLocals `\
  %REPEAT {__B2_VarLimit} \
    MF __B2_VarCount %EVAL {__B2_VarCount}-1 ; \
    MF __B2_LocalNum {__B2_VarCount} ; \
    @B2_RestoreVar {__B2_LocalNum} ; \
  %ENDR \
`

M B2_CLocals `\
  MF __B2_CLocalOffset 0 ; \
  MF __B2_CFrameSize %1 ; \
  @PUSHI __C_FP ; \
  @CALL B2_MOVE_HW_SS ; \
  @PUSHI __SS_SP ; \
  @SUBI __SS_BOTTOM ; \
  @IF_ULT_A %1 ; \
    @POPNULL ; \
    @JMP B2_SS_StackError ; \
  @ENDIF ; \
  @POPNULL ; \
  @PUSHI __SS_SP ; \
  @SUB %1 ; \
  @POPI __SS_SP ; \
  @PUSHI __SS_SP ; \
  @POPI __C_FP \
`

M B2_EndCLocals `\
  @PUSHI __C_FP ; \
  @ADD {__B2_CFrameSize} ; \
  @POPI __SS_SP ; \
  @CALL B2_MOVE_SS_HW ; \
  @POPI __C_FP \
`

# FCALL already returns to the next instruction in the calling bank, so a
# bank-2 call site needs no synthetic near return address.
M B2_CALL_B0 @FCALL 0 %1

@FUNCTION B2_MOVE_HW_SS
:B2_MOVE_HW_SS
@PUSHI __SS_SP
@SUB 2
@IF_ULT_V __SS_BOTTOM
   @POPNULL
   @JMP B2_SS_StackError
@ENDIF
@POPNULL
@SWP
@DEC2I __SS_SP
@POPII __SS_SP
@RET
@ENDFUNCTION

@FUNCTION B2_MOVE_SS_HW
:B2_MOVE_SS_HW
@PUSHI __SS_SP
@IF_UGT_V __SS_TOP
   @POPNULL
   @JMP B2_SS_StackError
@ENDIF
@POPNULL
@PUSHII __SS_SP
@INC2I __SS_SP
@SWP
@RET
@ENDFUNCTION

:B2_SS_StackError
@PRT "Error. Bank-2 C Stack Out of Bounds; SP="
@PRTHEXI __SS_SP
@PRTNL
@END
