! __LIB_CLOCALS_LOADED
M __LIB_CLOCALS_LOADED 1
P Loading clocals.ld
L softstack.ld
L heapmgr.ld
L c_runtime_stubs.ld

# Addressable stack frames for C-generated functions.
#
# These macros intentionally do not replace softstack.ld's @Locals/@Local
# macros.  The traditional locals save shared VarNN storage; C locals occupy
# unique space in the software stack so their addresses remain valid across
# nested calls and recursion.
#
# A function must save its return address before opening the frame:
#
#   @PUSHRETURN
#   @CLocals frame-size-in-bytes
#   @CLocal argument
#   @CLocal value
#      ...
#   @EndCLocals
#   @POPRETURN
#   @RET
#
# @CLocals is given the complete frame size because allocation must happen
# before arguments are removed from the hardware stack.  @CLocal and
# @CLocal32 assign successive byte offsets within that frame.

G __C_FP
G __EX716_HEAP_ID
G __EX716_MAIN_RETURN

@JMP __CLOCALS_DATA_END
? CPU24_SEGMENTED
::__C_FP 0
::__EX716_HEAP_ID 0
::__EX716_MAIN_RETURN 0
ENDBLOCK
! CPU24_SEGMENTED
:__C_FP 0
:__EX716_HEAP_ID 0
:__EX716_MAIN_RETURN 0
ENDBLOCK
:__CLOCALS_DATA_END

# Save the caller's frame pointer, reserve this frame, and make __C_FP point
# at its lowest address.  The EX716 software stack grows downward.
M CLocals `\
  MF __CLocalOffset 0 ; \
  MF __CFrameSize %1 ; \
  @PUSHI __C_FP ; \
  @CALL __MOVE_HW_SS ; \
  @PUSHI __SS_SP ; \
  @SUBI __SS_BOTTOM ; \
  @IF_ULT_A %1 ; \
    @POPNULL ; \
    @StackDump ; \
    @JMP __SS_StackError ; \
  @ENDIF ; \
  @POPNULL ; \
  @PUSHI __SS_SP ; \
  @SUB %1 ; \
  @POPI __SS_SP ; \
  @PUSHI __SS_SP ; \
  @POPI __C_FP \
`

# Define 16- and 32-bit names as byte offsets from __C_FP.  For a 32-bit
# object, name is the low word and name.high is the high word.
M CLocal `\
  = %1 {__CLocalOffset} ; \
  MF __CLocalOffset %EVAL {__CLocalOffset}+2 \
`

M CLocal32 `\
  = %1 {__CLocalOffset} ; \
  MF __CLocalOffset %EVAL {__CLocalOffset}+2 ; \
  = %1.high {__CLocalOffset} ; \
  MF __CLocalOffset %EVAL {__CLocalOffset}+2 \
`

# Compiler-facing explicit frame offsets.  These make it possible to reserve
# byte arrays and aggregates while retaining C's alignment and layout rules.
M CLocalAt = %1 %2
M CLocal32At `= %1 %2 ; = %1.high %2+2`

# Address, load, and store operations for frame-relative objects.
M CPUSHADDR @PUSHI __C_FP @ADD %1
M CPUSHI @CPUSHADDR %1 @PUSHS
M CPOPI @CPUSHADDR %1 @POPS
# Derive the high-word address from the byte offset rather than a separately
# declared .high alias.  lcc uses numeric offsets for array elements and
# struct fields, which are not named @CLocal32At objects.
M CPUSH32I @CPUSHI %1 @CPUSHI %1.high
M CPOP32I @CPOPI %1.high @CPOPI %1

# Byte operations use the low byte of EX716's word memory access.  Stores
# preserve the following byte, matching the existing string-library model.
M CLOADB @CPUSHADDR %1 @PUSHS @AND 0xff
M CSTOREB `\
  @AND 0xff ; \
  @CPUSHADDR %1 ; \
  @PUSHS ; \
  @AND 0xff00 ; \
  @ORS ; \
  @CPUSHADDR %1 ; \
  @POPS \
`

# Sign-extend an eight-bit value already on the hardware stack.
M CSIGNEXT8 `\
  @DUP ; \
  @AND 0x80 ; \
  @IF_NOTZERO ; \
     @POPNULL ; \
     @OR 0xff00 ; \
  @ELSE ; \
     @POPNULL ; \
  @ENDIF \
`

# Discard the current frame, restore the caller's frame pointer, and leave the
# saved return address at the top of the software stack for @POPRETURN.
M EndCLocals `\
  @PUSHI __C_FP ; \
  @ADD {__CFrameSize} ; \
  @POPI __SS_SP ; \
  @CALL __MOVE_SS_HW ; \
  @POPI __C_FP \
`
