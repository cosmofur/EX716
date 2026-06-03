! __LIB_MUL_LOADED
M __LIB_MUL_LOADED 1
I mul.ref
# ============================================================
# mul.ld  -  Software Multiply Library for EX716
#
# Provides 16-bit multiplication functions:
#   - MULU(a,b) → unsigned multiply
#   - MUL(a,b)  → signed multiply
#
# Algorithm:
#   MULU uses the classic “shift-and-add” method:
#     while (MM != 0):
#       if (MM & 1) then ANS += NN
#       NN <<= 1
#       MM >>= 1
#
# Notes:
#   - MULU maintains a 32-bit accumulator (low+high words).
#   - Returns only the low 16 bits, but sets flags if the
#     high word is nonzero (overflow).
#   - MUL uses MULU and adjusts result for sign.
# ============================================================

G MULU G MUL 
M SIZESINCECOMMENT mul.ld

M RETURN_RESULT  @RestoreVar 04 @RestoreVar 03 @RestoreVar 02 @RestoreVar 01  @POPRETURN @RET

# --- Public entry points ---

# ============================================================
# MULU(N, M) → Unsigned multiply
#
# Input:
#   Stack: RET, N (multiplier), M (multiplicand)
# Output:
#   Stack: Result (low 16 bits)
# Flags:
#   Overflow flag set if high word of result ≠ 0
# ============================================================
P Before MULU
@FUNCTION MULU
:MULU
    @PUSHRETURN
    @LocalVar MM      01   # multiplier
    @LocalVar NN      02   # multiplicand
    @LocalVar ANSLO   03   # accumulator (low word)
    @LocalVar ANSHI   04   # accumulator (high word)

    # --- Load arguments into locals ---
    @POPI MM
    @POPI NN
    @MA2V 0 ANSLO
    @MA2V 0 ANSHI

    # --- Handle trivial cases first ---
    @PUSHI MM
    @SWITCH
        @CASE 0
            @POPNULL
            @PUSH 0
            @RETURN_RESULT
            @CBREAK
        @CASE 1
            @POPNULL
            @PUSHI NN
            @RETURN_RESULT
            @CBREAK
        @CASE 2
            @POPNULL
            @PUSHI NN @SHL
            @RETURN_RESULT
            @CBREAK
        @CASE 3
            @POPNULL
            @PUSHI NN @DUP SHL @ADDS
            @RETURN_RESULT
            @CBREAK
        @CASE 4
            @POPNULL
            @PUSHI NN @SHL2
            @RETURN_RESULT
            @CBREAK
        @CASE 5
            @POPNULL
            @PUSHI NN @DUP @SHL2 @ADDS
            @RETURN_RESULT
            @CBREAK            
        @CASE 6
            @POPNULL
            @PUSHI NN @SHL @DUP @DUP @ADDS @ADDS
            @RETURN_RESULT
            @CBREAK
        @CASE 7
            @POPNULL
            @PUSHI NN @DUP @SHLN 3 @SWP @SUBS
            @RETURN_RESULT
            @CBREAK            
        @CASE 8
            @POPNULL
            @PUSHI NN @SHLN 3   # 3 shifts 
            @RETURN_RESULT
            @CBREAK
        @CASE 10
            @POPNULL
            @PUSHI NN @SHL @DUP @SHLN 2 @ADDS  # (ADD (NN*2), (NN*8))
            @RETURN_RESULT
            @CBREAK
        @CASE 16
            @POPNULL
            @PUSHI NN @SHL4
            @RETURN_RESULT
            @CBREAK
        @CDEFAULT
            @POPNULL
            @CBREAK
    @ENDCASE

    # --- Generic shift-and-add loop ---
    @PUSHI MM
    @WHILE_NOTZERO
        # If MM & 1 → add NN to result
        @AND 1
        @IF_NOTZERO
            @PUSHI ANSLO
            @ADDI NN
            @POPI ANSLO
            @IF_CARRY
                @INCI ANSHI
            @ENDIF
        @ENDIF
        @POPNULL

        # Shift NN left, update ANSHI if carry
        @PUSHI NN
        @SHL
        @POPI NN
        @IF_CARRY
            @INCI ANSHI
        @ENDIF

        # Shift MM right
        @PUSHI MM
        @SHR
        @POPI MM

        @PUSHI MM
    @ENDWHILE
    @POPNULL

    # --- Return low word only ---
    @PUSHI ANSLO

    # --- Overflow flag if high word ≠ 0 ---
    @PUSHI ANSHI
    @IF_NOTZERO
        @SETO        # Set OverFlow Flag
    @ELSE
        @CLO         # Clear OverFlow Flag
    @ENDIF
    @POPNULL

    # --- Clean up ---
    @RETURN_RESULT
ENDBLOCK

# ============================================================
# MUL(N, M) → Signed multiply
#
# Input:
#   Stack: RET, N, M
# Output:
#   Stack: Result (signed 16-bit, low word)
# Flags:
#   Overflow flag set if high word not equal to sign extension
# ============================================================
@FUNCTION MUL
:MUL
    @PUSHRETURN
    @LocalVar SIGN 01

    @MA2V 0 SIGN     # sign = +1

    # --- Check first operand ---
    @IF_LT_A 0
        @INV
        @POPI SIGN
    @ENDIF
    @SWP

    # --- Check second operand ---
    @IF_LT_A 0
        @INV
        @POPI SIGN
    @ENDIF
    @SWP

    # --- Do unsigned multiply ---
    @CALL MULU

    # --- Apply sign if needed ---
    @PUSHI SIGN
    @IF_GT_A 0
        @POPNULL
        @COMP2
    @ELSE
        @POPNULL
    @ENDIF

    # --- For signed multiply, overflow is set if
    #     high word is not equal to sign-extension of low word.
    @PUSHI ANSLO
    @AND 0x8000   # Using Mask rather and multiple SHR's
    @IF_ZERO
       # Not negative, so basic test against ANSHI
       # Positive results overflow test
       @POPNULL
       @PUSHI ANSHI
       @IF_ZERO
          @CLO
       @ELSE
          @SETO
       @ENDIF
       @POPNULL
    @ELSE
       @POPNULL
       @PUSHI ANSHI
       @IF_EQ_A 0xffff
          @SETO
       @ELSE
          @CLO
       @ENDIF
       @POPNULL
     @ENDIF

    # --- Clean up and return ---
    @RestoreVar 01
    @POPRETURN
    @RET
ENDBLOCK
@SIZESINCE
ENDBLOCK
