! __LIB_SHIFT16_LOADED
M __LIB_SHIFT16_LOADED 1
I shift16.ref

############################################################
# shift16.ld — 16-bit shifting and bit-twiddling primitives
#
# Provides:
#   SHL16_BY_N     ( A N → A<<N )
#   SHR16_BY_N     ( A N → A>>N ), logical
# Optional:
#   SAR16_BY_N     ( A N → A>>N ), arithmetic
#   BITMASK16      ( N → (1<<N) )
#   BITTEST16      ( A N → (0 or 1) )
#   BITSET16       ( A N → A|(1<<N) )
#   BITCLEAR16     ( A N → A&~(1<<N) )
#
# All functions expect 16-bit values and preserve stack order.
############################################################
G SHL16_BY_N G SHR16_BY_N G SAR16_BY_N G BITMASK16

############################################################
# SHL16_BY_N
# Logical shift left by N bits.
# Input:   ( A N )
# Output:  ( A<<N )
# Notes:
#   - Shifts by N = 0..15
#   - If N>=16, result = 0
#   - Does NOT use SHLN because N is runtime.
############################################################
@FUNCTION SHL16_BY_N
:SHL16_BY_N
@PUSHRETURN
    @LocalVar A   01
    @LocalVar N   02
    @LocalVar I1   03
    

    @POPI N
    @POPI A

    # If N == 0 → return A
    @PUSHI N @IF_ZERO
        @POPNULL
        @PUSHI A
        @RestoreVar 03
        @RestoreVar 02
        @RestoreVar 01
        @POPRETURN @RET
    @ENDIF
    @POPNULL

    # If N >= 16 → return 0
    @PUSHI N
    @IF_GE_A 16
        @POPNULL
        @PUSH 0
        @RestoreVar 03
        @RestoreVar 02
        @RestoreVar 01
        @POPRETURN @RET
    @ENDIF
    @POPNULL

    # Loop N times: A <<= 1
    @ForIA2B I1 N -1
        @PUSHI A
        @SHL        # built-in 16-bit one-bit shift
        @POPI A
    @NextBy I1 -1

    @PUSHI A
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
@ENDFUNCTION


############################################################
# SHR16_BY_N
# Logical right shift by N bits.
# Input:   ( A N )
# Output:  ( A>>N ), zero-extended
############################################################
@FUNCTION SHR16_BY_N
:SHR16_BY_N
@PUSHRETURN
    @LocalVar A   01
    @LocalVar N   02
    @LocalVar I1   03

    @POPI N
    @POPI A

    @PUSHI N @IF_ZERO
        @POPNULL
        @PUSHI A
        @RestoreVar 03
        @RestoreVar 02
        @RestoreVar 01
        @POPRETURN @RET
    @ENDIF
    @POPNULL

    @PUSHI N @IF_GE_A 16
        @POPNULL
        @PUSH 0
        @RestoreVar 03
        @RestoreVar 02
        @RestoreVar 01
        @POPRETURN @RET
    @ENDIF
    @POPNULL

    @ForIA2B I1 N -1
        @PUSHI A
        @SHR        # built-in 16-bit logical shift right
        @POPI A
    @NextBy I1 -1

    @PUSHI A
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
@ENDFUNCTION


############################################################
# OPTIONAL SECTION
############################################################


############################################################
# SAR16_BY_N — Arithmetic right shift (sign preserved)
# Input:  ( A N )
# Output: ( A>>N ) with sign-extend
############################################################
@FUNCTION SAR16_BY_N
:SAR16_BY_N
@PUSHRETURN
    @LocalVar A   01
    @LocalVar N   02
    @LocalVar S   03     # sign bit mask (0x8000)
    @LocalVar I1   04

    @POPI N
    @POPI A

    # Extract sign bit early
    @PUSHI A @AND 0x8000 @POPI S

    @PUSHI N @IF_ZERO
        @POPNULL
        @PUSHI A
        @RestoreVar 04
        @RestoreVar 03
        @RestoreVar 02
        @RestoreVar 01
        @POPRETURN @RET
    @ENDIF
    @POPNULL
    @PUSHI N @IF_GE_A 16
        @POPNULL
        # result is all sign bit
        @PUSHI S
        @IF_ZERO
            @POPNULL
            @PUSH 0
        @ELSE
            @POPNULL
            @PUSH 0xFFFF
        @ENDIF
        @RestoreVar 04
        @RestoreVar 03
        @RestoreVar 02
        @RestoreVar 01
        @POPRETURN @RET
    @ENDIF
    @POPNULL
    @ForIA2B I1 N -1
        @PUSHI A
        @SHR           # logical right shift
        @POPI A

        # reinsert sign bit
        @PUSHI S @AND 0x8000 @IF_NOTZERO
            @POPNULL
            @PUSHI A @OR 0x8000 @POPI A
        @ELSE
            @POPNULL
        @ENDIF
    @NextBy I1 -1

    @PUSHI A
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
@ENDFUNCTION


############################################################
# BITMASK16 — produces (1<<N)
# Input: ( N )
# Output: ( mask )
############################################################
@FUNCTION BITMASK16
:BITMASK16
@PUSHRETURN
    @LocalVar N 01
    @POPI N

    @Call(AV) SHL16_BY_N 1 N

    @RestoreVar 01
@POPRETURN
@RET
@ENDFUNCTION


############################################################
# BITTEST16 — test bit N of A
# Input:  ( A N )
# Output: ( 0 or 1 )
############################################################
@FUNCTION BITTEST16
:BITTEST16
@PUSHRETURN
    @LocalVar A 01
    @LocalVar N 02

    @POPI N
    @POPI A

    @Call(V) BITMASK16 N
    @ANDI A
@POPRETURN
@RET
@ENDFUNCTION



############################################################
# BITSET16 — set bit N in A
############################################################
@FUNCTION BITSET16
:BITSET16
@PUSHRETURN
    @LocalVar A 01
    @LocalVar N 02

    @POPI N
    @POPI A

    @Call(V) BITMASK16 N
    @ORI A

@POPRETURN
@RET
@ENDFUNCTION


############################################################
# BITCLEAR16 — clear bit N in A
############################################################
@FUNCTION BITCLEAR16
:BITCLEAR16
@PUSHRETURN
    @LocalVar A 01
    @LocalVar N 02

    @POPI N
    @POPI A

    @Call(V) BITMASK16 N
    @INV               # invert mask
    @ANDI A

@POPRETURN
@RET
@ENDFUNCTION
ENDBLOCK
