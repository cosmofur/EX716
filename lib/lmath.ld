! __LIB_LMATH_LOADED
M __LIB_LMATH_LOADED 1
P Loading lmath.ld
I lmath.ref
P Past Red
L shift16.ld
P Past Shift16
L string.ld
P Past string.ld load in lmath
M SIZESINCECOMMENT lmath.ld

########################
# Published functions
G ADD32S G ADD32U G SUB32S G SUB32U                   # Core math functoins Signed Unsigned
G ADD32_BASE
G ADD16U G ADD32 G SUB32
G MUL32U G MUL32S
G DIV32U G DIV32S
G CMP32S G CMP32U                                   # Compair Signed Unsigned
G CMP32
G AND32 G OR32 G XOR32 G INV32                      # Boolean operations.
G SHL32 G SHR32                                     # Multi bit shifts
G SHL32_1 G SHR32_1 G SHL32_8 G SHR32_8             # fixed bit shifts
G SHL32_small G SHR32_small
G SetBit32 G ClearBit32                             # Bit operations
G COMP232                                           # 2s complimnet 32
G Flags32 G C32Flag G N32Flag G Z32Flag G O32Flag   # Logical Flag variables
G OVF32 G ONE32 G TWO32 G ZERO32                    # Common fixed constants.
G SHL3264                                           # Bit shifts as if 64 bit
G MUL16x32U                                         # MUL 2 16bit for 32b result
G SHL16x32 G SHR16x32                               # SHL/SHR with overflow into 32 bit value
G DIV10_32U                                         # Shortcut Divide by 10
G i32tos G stoi32                                   # 32 bit string converstions
G SetFlags32

=C32Flag 1
=InvC32Flag 0xfffe   # Invert C32Flag
=N32Flag 2
=InvN32Flag 0xfffd   # Invert N32Flag
=Z32Flag 4
=InvZ32Flag 0xfffb   # Invert Z32Flag
=O32Flag 8
=InvO32Flag 0xfff7   # Invert O32Flag
#M DebugFlag 1



#########################
# Utility Macros, use after a CMP32 or flag chaning 32 function.
#
# Base Cases
#  A == B  Z=1
M IF32_EQ @PUSHI Flags32 @AND Z32Flag @CMP Z32Flag @POPNULL @IF_ZFLAG
#  A != B  Z=0
M IF32_NE @PUSHI Flags32 @AND Z32Flag @CMP Z32Flag @POPNULL @IF_NOTZF
# Unsigned group
#
M IF32_ULT         @PUSHI Flags32 @AND C32Flag @CMP 0 @POPNULL @IF_NOTZF     # A < B  (borrow)
M IF32_UGE         @PUSHI Flags32 @AND C32Flag @CMP 0 @POPNULL @IF_ZFLAG     # A ≥ B  (no borrow)
M IF32_ULE         @PUSHI Z32Flag @ANDI Flags32 \
                   @PUSHI C32Flag @ANDI Flags32 \
                   @ORS @CMP 0 @POPNULL @IF_NOTZF                     # (A < B or A == B)
M IF32_UGT         @PUSHI Z32Flag @ANDI Flags32 \
                   @PUSHI C32Flag @ANDI Flags32 \
                   @ORS @CMP 0 @POPNULL @IF_ZFLAG                     # (A > B)  no borrow and not equal
#
#
# Signed Group
#
# A > B : (N = O) and Z=0
M IF32_GT @PUSHI Flags32 \
          @AND N32Flag \
          @PUSHI Flags32 \
          @AND O32Flag \
          @XORS \
          @PUSHI Flags32 \
          @AND Z32Flag \
          @ORS \
          @CMP 0 @POPNULL \
          @IF_ZFLAG
# A < B : (N ≠ O)
M IF32_LT @PUSHI Flags32 @AND N32Flag \
          @PUSHI Flags32 @AND O32Flag \
          @XORS \
          @CMP 0 @POPNULL \
          @IF_NOTZF

# A >= B : (N = O)
M IF32_GE @PUSHI Flags32 @AND N32Flag \
          @PUSHI Flags32 @AND O32Flag \
          @XORS \
          @CMP 0 @POPNULL \
          @IF_ZFLAG

# A <= B : (N ≠ O) or Z=1
M IF32_LE @PUSHI Flags32 @AND N32Flag \
          @PUSHI Flags32 @AND O32Flag \
          @XORS \
          @PUSHI Flags32 @AND Z32Flag \
          @ORS \
          @CMP 0 @POPNULL \
          @IF_NOTZF
# Borrow and No Borrow are ways to interpert the C flag
M IF32_Borrow      @PUSHI Flags32 @AND C32Flag @POPNULL @IF_NOTZF     # CF=1 → borrow
M IF32_NoBorrow    @PUSHI Flags32 @AND C32Flag @POPNULL @IF_ZFLAG     # CF=0 → no borrow
# Simple flag tests
M IF32_CARRY @PUSHI Flags32 @AND C32Flag @POPNULL @IF_NOTZF
M IF32_NOTCARRY @PUSHI Flags32 @AND C32Flag @POPNULL @IF_ZFLAG
M IF32_NEG @PUSHI Flags32 @AND N32Flag @POPNULL @IF_NOTZF
M IF32_NOTNEG @PUSHI Flags32 @AND N32Flag @POPNULL @IF_ZFLAG
M IF32_ZERO @PUSHI Flags32 @AND Z32Flag @POPNULL @IF_NOTZF
M IF32_NOTZERO @PUSHI Flags32 @AND Z32Flag @POPNULL @IF_ZFLAG
M IF32_OVER @PUSHI Flags32 @AND O32Flag @POPNULL @IF_NOTZF
M IF32_NOTOVER @PUSHI Flags32 @AND O32Flag @POPNULL @IF_ZFLAG



#
# Call Macros to make Calling mixed 32 bit values eaiser

# Helper Macro call
# Insert32 Label1(AA) $$$Value1 Label $$$Value2
M Insert32(AA) @JMP Skip_%0 :%1 %2 :%3 %4 :Skip_%0
# Insert32(A) Label1 $$$Value1
M Insert32(A) @JMP Skip_%0 :%1 %2 :Skip_%0
#
# Call32(AA) turn immeidate $$$'s into lables then Call(VVVV) with those lables
M Call32(AA) @Insert32(AA) V1_%0 %2 V2_%0 %3 @Call(VVVV) %1 V1_%0 V1_%0+2 V2_%0 V2_%0+2
#
# Call32(AV) turn first immediate into $$$ and and pass variable as well to Call(VVVV)
M Call32(AV) @Insert32(A) V1_%0 %2 @Call(VVVV) %1 V1_%0 V1_%0+2 %3 %3+2
#
# Call32(VA) turn second immediate into $$$ and and pass variable as well to Call(VVVV)
M Call32(VA) @Insert32(A) V2_%0 %3 @Call(VVVV) %1 %2 %2+2 V2_%0 V2_%0+2
#
# Call32(VV) when both paramaters or 32b variables
M Call32(VV) @Call(VVVV) %1 %2 %2+2 %3 %3+2
#
# Call32(AP) when first is immediate and second value is PtrTo32bit
M Call32(AP) @Insert32(A) V1_%0 %2 @PUSHI V1_%0 @PUSHI V1_%0+2 @PUSHII %3 @PUSHI %3 @ADD 2 @PUSHS @CALL %1
#
# Call32(PA) when second is immediate and first value is PtrTo32bit
M Call32(PA) @Insert32(A) V1_%0 %3 @PUSHII %2  @PUSHI %2 @ADD 2 @PUSHS @PUSHI V1_%0 @PUSHI V1_%0+2 @CALL %1
#
# Call32(PP) when both are PtrTo32bit pointers
M Call32(PP) @PUSHII %2 @PUSHI %2 @ADD 2 @PUSHS @PUSHII %3 @PUSHI %3 @ADD 2 @PUSHS @CALL %1
#
# Call32(A) For sigle parameter 32 bit immediate $$$ value function calls
M Call32(A) @Insert32(A) V1_%0 %2 @Call(VV) %1 V1_%0 V1_%0+2
#
# Call32(V) For single paramater 32 bit paramager function calls
M Call32(V) @PUSHI %2 @PUSHI %2+2 @CALL %1
#
# Call32(P) For single paramater PtrTo32bit function calls
M Call32(P) @PUSHII %2 @PUSHI %2 @ADD 2 @PUSHS @CALL %1
#
# Now the POP versions for simpifying POPing 2 word results into 32 bit variables
#
# POP32I(V) Pops right into a simple 32 bit variable stack High val on top
P Defining POP32I
M POP32I(V) @PUSH %1+2 @POPS @POPI %1
M POP32I(VV) @PUSH %1+2 @POPS @POPI %1 @PUSH %2+2 @POPS @POPI %2
#M POP32I(VVV) @PUSH %1+2 @POPS @POPI %1 @PUSH %2+2 @POPS @POPI %2 @PUSH %3+2 @POPS @POPI %3
#
# While VV and VVV make sense for simple POP32I, it gets too complex for double indirection.
#
# POP32II(V) Pops into PtrTo32bit (Note we're not using the 'P' term to stay consistent with POPII)
M POP32II(V) @PUSHI %1 @ADD 2 @POPS @PUSHI %1 @POPS
# PUSH32I(V) Pushing 32 bit word by passing name of lower word. LOW, High push
M PUSH32I(V) @PUSHI %1 @PUSHI %1+2
# Push 32 value based on ptr to word rather than address of word.
M PUSH32II(V) PUSHII %1 @PUSHI %1 @ADD 2 @PUSHS
M PUSH32(A) @JMP _%0_Skip :_%0_Val %1 :_%0_Skip @PUSHI _%0_Val @PUSHI _%0_Val+2
M M32A2V @PUSH32(A) %1 @POP32I(V) %2
M M32V2V @PUSH32I(V) %1 @POP32I(V) %2
M M32P2V `@PUSHII %1 @PUSHI %1 @ADD 2 @PUSHS @POP32I(V) %2`
M M32VTO16V @PUSHI %1 @POPI %2
M M16VTO32V @PUSHI %1 @POPI %2 @PUSH 0 @POPI %2+2
M PRT32HEXI @PRTHEXI %1+2 @PRTHEXI %1
M PRT32HEXS @PRTHEXTOP @SWP @PRTHEXTOP @SWP


# ===========================================================
# Function : ADD32_BASE
# Purpose  : 32-bit binary addition (no flag semantics)
# Inputs   : [ ... A32_Low A32_High B32_Low B32_High ]
# Outputs  : [ ... R32_Low R32_High CarryOut ]
# Notes    : Performs 32-bit addition with carry detection.
# ===========================================================
@FUNCTION ADD32_BASE
:ADD32_BASE
  @PUSHRETURN
  @Locals
  @Local SumLow
  @Local CarryAmt
  @Local A32_Low
  @Local A32_High
  @Local B32_Low
  @Local B32_High
  @Local R32_Low
  @Local R32_High  
  

    @POP32I(V) B32_Low
    @POP32I(V) A32_Low

    # --- Add low words ---
    @PUSHI A32_Low
    @ADDI B32_Low
    @POPI SumLow

    # Compute carry = (A32_Low + B32_Low) - SumLow

    @PUSHI SumLow
    @IF_ULT_V A32_Low
       @MA2V 1 CarryAmt
    @ELSE
       @MA2V 0 CarryAmt
    @ENDIF
    @POPNULL

    # --- Add high words + carry ---
    @PUSHI A32_High
    @ADDI B32_High
    @ADDI CarryAmt
    @POPI R32_High

    # Return R32_Low, R32_High, CarryAmt
    @PUSHI SumLow
    @PUSHI R32_High
    @PUSHI CarryAmt
  @EndLocals
  @POPRETURN
  @RET
  @ENDFUNCTION

@FUNCTION ADD32
:ADD32
@PUSHRETURN
#USE ADD32S
@CALL ADD32S
@POPRETURN
@RET
@ENDFUNCTION
# ===========================================================
# Function : ADD32S
# Purpose  : Signed 32-bit addition with signed overflow flag
# ===========================================================
@FUNCTION ADD32S
:ADD32S
  @PUSHRETURN
  @Locals
  @Local SumLow
  @Local R32_High
  @Local CarryAmt
  @Local OverFlow
#USE ADD32_BASE,SetFlags32
    @CALL ADD32_BASE
    @POPI CarryAmt
    @POPI R32_High
    @POPI SumLow

    # --- Compute signed overflow ---
    @MA2V 0 OverFlow
    @PUSHI A32_High
    @XORI R32_High
    @PUSHI B32_High
    @XORI R32_High
    @ANDS
    @PUSH 0x8000
    @ANDS
    @IF_NOTZERO
        @INCI OverFlow
    @ENDIF
    @POPNULL

    # --- Set flags (signed mode = 1) ---
    @PUSHI SumLow
    @PUSHI R32_High
    @PUSH 1                # Mode: 1 = ADD
    @PUSHI CarryAmt
    @PUSHI OverFlow
    @CALL SetFlags32
    
    # --- Push result ---
    @PUSHI SumLow
    @PUSHI R32_High

  @EndLocals
  @POPRETURN
  @RET
@ENDFUNCTION
# ===========================================================
# Function : ADD32U
# Purpose  : Unsigned 32-bit addition with carry flag
# ===========================================================
@FUNCTION ADD32U
:ADD32U
  @PUSHRETURN
  @Locals
  @Local SumLow
  @Local R32_High
  @Local CarryAmt
  @Local OverFlow
#USE ADD32_BASE,SetFlags32
    @CALL ADD32_BASE
    @POPI CarryAmt
    @POPI R32_High
    @POPI SumLow

    # --- Set flags (unsigned mode = 0) ---
    @MA2V 0 OverFlow
    @PUSHI SumLow
    @PUSHI R32_High
    @PUSH 1                # Mode = ADD
    @PUSHI CarryAmt
    @PUSHI OverFlow        # Always 0 for unsigned
    @CALL SetFlags32

    # --- Push result ---
    @PUSHI SumLow
    @PUSHI R32_High

  @EndLocals
  @POPRETURN
  @RET
  @ENDFUNCTION


# ===========================================================
# Function : SUB32S
# Purpose  : Subtract two 32-bit values on the stack (little-endian)
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# Notes    :
#   - Uses shared workspace (A32_*, B32_*, R32_*).
#   - Carry flag acts as "no borrow" flag.
#   - Discards borrow out of high word.
# ===========================================================
@FUNCTION SUB32
#USE SUB32S
JMP SUB32S
@ENDFUNCTION

@FUNCTION SUB32S
:SUB32S
@PUSHRETURN
@Locals
    @Local BorrowFlag
    @Local A32_Low
    @Local A32_High
    @Local B32_Low
    @Local B32_High
    @Local R32_Low
    @Local R32_High

#USE CMP32S    

    @POP32I(V) B32_Low
    @POP32I(V) A32_Low

    # --- Low word subtraction ---
    @PUSHI A32_Low
    @SUBI  B32_Low
    @POPI  R32_Low

    # --- Adjust high word if borrow occurred ---
    @IF_CARRY           # Carry → borrow
        @MA2V 1 BorrowFlag
    @ELSE
        @MA2V 0 BorrowFlag
    @ENDIF

    # --- High word subtraction ---
    @PUSHI A32_High
    @SUBI  B32_High
    @POPI R32_High
    
    @IF_EQ_AV 1 BorrowFlag
       @DECI R32_High
    @ENDIF    


    # --- Set Flags ---
    @Call32(VV) CMP32S A32_Low B32_Low

    # --- Push result back (low first, then high) ---
    @PUSH32I(V) R32_Low
    
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : SUB32U
# Purpose  : Unsigned 32-bit subtraction (A - B)
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# Notes    :
#   - Carry flag is set if *no borrow* occurred (C=1 => A >= B)
#   - Uses workspace A32_*, B32_*, R32_*
#   - Sets Flags32 via CMP32U
# ===========================================================
@FUNCTION SUB32U
:SUB32U
@PUSHRETURN
@Locals
@Local UCA_Low
@Local UCA_High
@Local UCB_Low
@Local UCB_High
@Local UCR_Low
@Local UCR_High
@Local BorrowFlag
=UCA UCA_Low
=UCB UCB_Low
#USE SetFlags32
    @POP32I(V) UCB
    @POP32I(V) UCA
    # --- Low word subtraction ---
    @PUSHI UCA_Low    @SUBI  UCB_Low    @POPI  UCR_Low

    # --- Adjust high word for borrow ---
    @IF_CARRY
        @MA2V 1 BorrowFlag
    @ELSE
        @MA2V 0 BorrowFlag
    @ENDIF
    # --- High word subtraction ---
    @PUSHI UCA_High
    @SUBI UCB_High

    @IF_EQ_AV 1 BorrowFlag
       @SUB 1
    @ENDIF
    @POPI UCR_High

    # Re-evaluate final borrow after high-word subtraction.
    @IF_CARRY
       @MA2V 1 BorrowFlag
    @ELSE
       @MA2V 0 BorrowFlag
    @ENDIF

    @PUSHI UCR_Low @PUSHI UCR_High
    @PUSH 2   # Mode 2 = SUB/CMP
    @PUSHI BorrowFlag
    @PUSH 0   # OverFlowIn
    @CALL SetFlags32

    # --- Push result (Low then High) ---
    @PUSH32I(V) UCR_Low

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : CMP32S
# Purpose  : Compare two 32-bit values on the stack (little-endian)
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : none (flags set: Z,N,C)
# Notes    :
#   - Sets flags as if performing A − B.
#   - Uses same carry convention as SUB32S (carry = borrow).
# ===========================================================
@FUNCTION CMP32S
:CMP32
:CMP32S
@PUSHRETURN
@Locals
@Local LowBorrowTmp   # borrow from low word (used for CF)
@Local HighBorrowTmp   # borrow from high word
@Local BorrowTmp   # final CF (unsigned borrow)
@Local OverflowTmp   # signed overflow flag
@Local AVar_Low
@Local AVar_High
@Local BVar_Low
@Local BVar_High
@Local RVar_Low
@Local RVar_High
@Local TmpA
@Local TmpB
@Local TmpR
=AVar AVar_Low
=BVar BVar_Low

    @POP32I(V) BVar
    @POP32I(V) AVar
    @MA2V 0 Flags32
    @MA2V 0 LowBorrowTmp
    @MA2V 0 HighBorrowTmp
    @MA2V 0 BorrowTmp
    @MA2V 0 OverflowTmp

    # --- Low word subtraction ---
    @PUSHI AVar_Low  @SUBI  BVar_Low  @POPI  RVar_Low
    @IF_CARRY
        @MA2V 1 LowBorrowTmp
    @ENDIF
    @FCLR

    # --- High word subtraction (simulate SBB) ---
    @PUSHI AVar_High
    @SUBI  BVar_High
    @IF_NEQ_AV 0 LowBorrowTmp
        @SUB 1
    @ENDIF
    @POPI  RVar_High
    @IF_CARRY
        @MA2V 1 HighBorrowTmp
    @ENDIF
    @FCLR

    # --- Compute final carry (unsigned borrow) ---
    @PUSHI LowBorrowTmp
    @ORI   HighBorrowTmp
    @IF_NOTZERO
        @MA2V 1 BorrowTmp
    @ELSE
        @MA2V 0 BorrowTmp
    @ENDIF
    @POPNULL

    # --- Compute signed overflow ---
    # Overflow occurs if sign(A) != sign(B) and sign(Result) != sign(A)
    @PUSHI AVar_High
    @AND 0x8000
    @POPI TmpA
    @PUSHI BVar_High
    @AND 0x8000
    @POPI TmpB
    @PUSHI RVar_High
    @AND 0x8000
    @POPI TmpR

    # Test (sign(A) != sign(B)) and (sign(R) != sign(A))
    @PUSHI TmpA
    @XORI TmpB
    @IF_NOTZERO          # sign(A) != sign(B)
        @PUSHI TmpR
        @XORI TmpA
        @IF_NOTZERO      # sign(R) != sign(A)
            @MA2V 1 OverflowTmp
        @ENDIF
        @POPNULL
    @ENDIF
    @POPNULL
    @FCLR

    # --- Compose flag word (OZNC order) ---

    # Overflow flag
    @IF_NEQ_AV 0 OverflowTmp
        @PUSHI Flags32
        @OR O32Flag
        @POPI Flags32
    @ENDIF

    # Carry flag (for completeness)
    @IF_NEQ_AV 0 BorrowTmp
        @PUSHI Flags32
        @OR C32Flag
        @POPI Flags32
    @ENDIF

    # Zero flag
    @PUSHI RVar_Low
    @ORI   RVar_High
    @IF_ZERO
        @PUSHI Flags32
        @OR Z32Flag
        @POPI Flags32
    @ENDIF
    @POPNULL

    # Negative flag (bit 15 of high word)
    @PUSHI RVar_High
    @AND 0x8000
    @IF_NOTZERO
        @PUSHI Flags32
        @OR N32Flag
        @POPI Flags32
    @ENDIF
    @POPNULL

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Function : CMP32U
# Purpose  : Compare two 32-bit unsigned values (A - B)
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : none (sets Z, C, N flags)
# Notes    :
#   - Carry flag set if borrow (A >= B)
#   - Uses hardware CF=1 ⇒ no borrow convention
#   - Overflow flag cleared (not meaningful for unsigned)
# ===========================================================
@FUNCTION CMP32U
:CMP32U
@PUSHRETURN
@Locals
  @Local LowBorrowTmp
  @Local HighBorrowTmp
  @Local A_L
  @Local A_H
  @Local B_L
  @Local B_H
  @Local R_L
  @Local R_H

  @POP32I(V) B_L
  @POP32I(V) A_L

  @MA2V 0 Flags32
  @MA2V 0 LowBorrowTmp
  @MA2V 0 HighBorrowTmp

  @PUSHI A_L @XORI B_L
  @IF_ZERO
     @PUSHI A_H @XORI B_H
     @IF_ZERO
        @PUSHI Flags32 @OR Z32Flag @POPI Flags32
     @ENDIF
     @POPNULL
  @ENDIF
  @POPNULL

# First test the High Words
@PUSHI A_H @SUBI B_H

@IF_CARRY                 # A_H < B_H
   @POPNULL
   @PUSHI Flags32 @OR C32Flag @POPI Flags32
   @JMP CMP32Ucmp_done
@ENDIF

@IF_NOTZERO                  # A_H > B_H
   @POPNULL
   @PUSHI Flags32 @AND InvC32Flag @POPI Flags32
   @JMP CMP32Ucmp_done
@ENDIF
@POPNULL                     # A_H == B_H

# High words equal → test low words
@PUSHI A_L @SUBI B_L
@IF_CARRY                 # A_L < B_L
   @PUSHI Flags32 @OR C32Flag @POPI Flags32
@ELSE
   @PUSHI Flags32 @AND InvC32Flag @POPI Flags32
@ENDIF
@POPNULL

:CMP32Ucmp_done

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : AND32
# Purpose  : Bitwise AND of two 32-bit values on the stack
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================
@FUNCTION AND32
:AND32
@PUSHRETURN

@Locals
    @Local A32_Low
    @Local A32_High
    @Local B32_Low
    @Local B32_High
    @Local R32_Low
    @Local R32_High
#USE SetFlags32    

    @POP32I(V) B32_Low
    @POP32I(V) A32_Low


    @PUSHI A32_Low
    @ANDI B32_Low
    @POPI  R32_Low

    @PUSHI A32_High
    @ANDI B32_High
    @POPI  R32_High

    # --- SetFlags ---
    @PUSH32I(V) R32_Low
    @PUSH 0 @PUSH 0 @PUSH 0 # Mode 0=logical Carry=0 Overflow=0
    @CALL SetFlags32

    
    @PUSHI R32_Low
    @PUSHI R32_High

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ===========================================================
# Function : OR32
# Purpose  : Bitwise OR of two 32-bit values on the stack
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

@FUNCTION OR32
:OR32
@PUSHRETURN
@Locals
    @Local A32_Low
    @Local A32_High
    @Local B32_Low
    @Local B32_High
    @Local R32_Low
    @Local R32_High
#USE SetFlags32

    @POP32I(V) B32_Low
    @POP32I(V) A32_Low


    @PUSHI A32_Low
    @ORI   B32_Low
    @POPI  R32_Low

    @PUSHI A32_High
    @ORI   B32_High
    @POPI  R32_High

    # --- SetFlags ---
    @PUSH32I(V) R32_Low
    @PUSH 0 @PUSH 0 @PUSH 0 # Mode 0=logical Carry=0 Overflow=0
    @CALL SetFlags32

    @PUSHI R32_Low
    @PUSHI R32_High

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ===========================================================
# Function : XOR32
# Purpose  : Bitwise XOR of two 32-bit values on the stack
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

@FUNCTION XOR32
:XOR32
@PUSHRETURN
@Locals
    @Local A32_Low
    @Local A32_High
    @Local B32_Low
    @Local B32_High
    @Local R32_Low
    @Local R32_High
#USE SetFlags32

    @POP32I(V) B32_Low
    @POP32I(V) A32_Low

    @PUSHI A32_Low
    @XORI  B32_Low
    @POPI  R32_Low

    @PUSHI A32_High
    @XORI  B32_High
    @POPI  R32_High
    
    # --- SetFlags ---
    @PUSH32I(V) R32_Low
    @PUSH 0 @PUSH 0 @PUSH 0 # Mode 0=logical Carry=0 Overflow=0
    @CALL SetFlags32    

    @PUSHI R32_Low
    @PUSHI R32_High

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ===========================================================
# Function : INV32
# Purpose  : Bitwise INV/NOT of a 32-bit value on the stack
# Inputs   : [ ... A_low A_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

@FUNCTION INV32
:INV32
@PUSHRETURN
@Locals
    @Local A32_Low
    @Local A32_High
    @Local B32_Low
    @Local B32_High
#USE SetFlags32    
    @POP32I(V) A32_Low

    @PUSHI A32_Low
    @INV
    @POPI R32_Low

    @PUSHI A32_High
    @INV
    @POPI R32_High

    # --- SetFlags ---
    @PUSH32I(V) R32_Low
    @PUSH 0 @PUSH 0 @PUSH 0 # Mode 0=logical Carry=0 Overflow=0
    @CALL SetFlags32    


    @PUSHI R32_Low
    @PUSHI R32_High
    
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ===========================================================
# Function : COMP232
# Purpose  : Take the 2's compliment of 32-bit value on stack
# Inputs   : [ ... A_low A_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

@FUNCTION COMP232
:COMP232
@PUSHRETURN
@Locals
@Local AVar_Low
@Local AVar_High
@Local RVar_Low
@Local RVar_High
#USE CMP32S
    @POP32I(V) AVar_Low

    # Invert both words
    @PUSHI AVar_Low
    @INV
    @POPI RVar_Low
    
    @PUSHI AVar_High
    @INV
    @POPI RVar_High

    # Add 1 (low word only, with carry)
    @PUSHI RVar_Low
    @ADD 1
    @POPI RVar_Low
    @IF_CARRY
       @INCI RVar_High    
    @ENDIF
    # --- SetFlags ---
    @Call32(AV) CMP32S $$$0 RVar_Low

    @PUSHI RVar_Low
    @PUSHI RVar_High

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Function : SetFlags32
# Purpose  : Set Logical Flags after basic maths
# Inputs   : [ ... ResultLow ResultHigh Mode CarryIn OverFlowIn ]
# Outputs  : [ ... ]

@FUNCTION SetFlags32
:SetFlags32
@PUSHRETURN
@Locals
    @Local RLow
    @Local RHigh
    @Local Mode
    @Local CarryIn
    @Local OverflowIn
    @Local IsZero

    @POPI OverflowIn
    @POPI CarryIn
    @POPI Mode
    @POPI RHigh
    @POPI RLow

    @MA2V 0 Flags32
    # ---- Zero flag ----
    @PUSHI RLow
    @ORI RHigh
    @POPI IsZero
    @IF_EQ_VA IsZero 0
        @PUSHI Flags32 @OR Z32Flag @POPI Flags32
    @ELSE
        @PUSHI Z32Flag @INV @ANDI Flags32 @POPI Flags32    
    @ENDIF

    # ---- Negative flag ----
    @PUSHI RHigh
    @PUSHI 0x8000
    @ANDS
    @IF_NOTZERO
        @PUSHI Flags32 @OR N32Flag @POPI Flags32    
    @ELSE
        @PUSHI N32Flag @INV @ANDI Flags32 @POPI Flags32    
    @ENDIF
    @POPNULL

    # ---- Mode-dependent carry/overflow ----
    @IF_EQ_AV 0 Mode         # Logical o1ps
        @PUSHI C32Flag @INV @ANDI Flags32 @POPI Flags32
        @PUSHI O32Flag @INV @ANDI Flags32 @POPI Flags32                
    @ELSE
      @IF_EQ_AV 1 Mode     # ADD
        @IF_EQ_AV 0 CarryIn
            @PUSHI C32Flag @INV @ANDI Flags32 @POPI Flags32
        @ELSE
            @PUSHI Flags32 @OR C32Flag @POPI Flags32
        @ENDIF
        @IF_EQ_AV 0 OverflowIn
            @PUSHI O32Flag @INV @ANDI Flags32 @POPI Flags32        
        @ELSE
            @PUSHI Flags32 @OR O32Flag @POPI Flags32
        @ENDIF
     @ELSE             # SUB / CMP
        @IF_EQ_AV 0 CarryIn
            @PUSHI C32Flag @INV @ANDI Flags32 @POPI Flags32                                            
        @ELSE
            @PUSHI Flags32 @OR C32Flag @POPI Flags32
        @ENDIF
        @IF_EQ_AV 0 OverflowIn
            @PUSHI O32Flag @INV @ANDI Flags32 @POPI Flags32 
        @ELSE
            @PUSHI Flags32 @OR O32Flag @POPI Flags32                            
        @ENDIF
      @ENDIF
    @ENDIF

    # Clean up
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#===========================================================
# Function : SHL32_8
# Purpose  : Shifts 32 bit value left by 8 bits for efficency
# Input    : [ ... Lowword Highword ]
# Output   : [ ... NewLow NewHigh ]
#===========================================================
@FUNCTION SHL32_8
:SHL32_8     # ( NUM{LowWord,HighWord} -- )   Modify 32-bit value in place
@PUSHRETURN
@Locals
  @Local NUM    # We will be testing NUM-1 we must make sure NUM address != 0
  @Local Num_High
  

  @POP32I(V) NUM        # NUM = base address of the 32-bit value
  @PUSH NUM @ADD 1 @PUSHS
  @PUSH NUM @ADD 2 @POPS
  @PUSH NUM @SUB 1 @PUSHS 
  @AND 0xff00
  @PUSH NUM @POPS

  @PUSH32I(V) NUM
  @EndLocals
  @POPRETURN
@RET
@ENDFUNCTION

#===========================================================
# Function : SHR32_8
# Purpose  : Shifts 32-bit value right by 8 bits efficiently
# Input    : [ ... LowWord HighWord ]
# Output   : [ ... NewLow NewHigh ]
#===========================================================
@FUNCTION SHR32_8
:SHR32_8     # ( NUM{LowWord,HighWord} -- )
@PUSHRETURN
@Locals
  @Local NUM      # We will be testing NUM-1 we must make sure NUM address != 0
  @Local NUM_High

  @POP32I(V) NUM     # NUM = base address of 32-bit value



  
  @PUSH NUM @ADD 1 @PUSHS
  @PUSH NUM @POPS
  @PUSH NUM @ADD 2 @PUSHS
  @PUSH NUM @ADD 1 @POPS
  @PUSH NUM @ADD 2 @PUSHS @AND 0xff
  @PUSH NUM @ADD 2 @POPS

  @PUSH32I(V) NUM

  @EndLocals
  @POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Function : SHL32
# Purpose  : Shift 32-bit value left by N bits (logical)
# Inputs   : [ ... Low High Count ]
# Outputs  : [ ... NewLow NewHigh ]
# ===========================================================
@FUNCTION SHL32
:SHL32
@PUSHRETURN
@Locals
    @Local Low
    @Local High
    @Local Count
    @Local CarryOut
    @Local C8
    @Local C1
    @Local _I
#USE SetFlags32,SHL32_8,SHL32_small
    # Read args
    @POPI Count
    @POP32I(V) Low

    # ------------------------------
    # Case: Count >= 32 → result = 0
    # ------------------------------
    @PUSHI Count
    @IF_UGE_A 32
        @POPNULL
        @MA2V 0 Low
        @MA2V 0 High
        @MA2V 0 CarryOut

        # Set flags: (Low=0,High=0, Mode=1, Carry=0, OF=0)
        @PUSH32I(V) Low
        @PUSH 1
        @PUSH 0
        @PUSH 0
        @CALL SetFlags32

        @JMP SHL32_End    # (Structured “end section”, not an early escape)
    @ENDIF
    @POPNULL

    # ------------------------------
    # Case: Count == 0 → no shift
    # ------------------------------
    @PUSHI Count
    @IF_EQ_A 0
        @POPNULL
        @MA2V 0 CarryOut

        @PUSH32I(V) Low
        @PUSH 1
        @PUSH 0
        @PUSH 0
        @CALL SetFlags32

        @JMP SHL32_End
    @ENDIF
    @POPNULL

    # ------------------------------
    # Compute C8 = Count >> 3
    #         C1 = Count & 7
    # ------------------------------

    @PUSHI Count    @SHRN 3    @POPI C8
    @PUSHI Count    @AND 0x7   @POPI C1

    # ------------------------------
    # Perform full byte shifts
    # ------------------------------
    @ForIA2V _I 0 C8
        @Call32(V) SHL32_8 Low
        @POP32I(V) Low
    @Next _I

    # ------------------------------
    # Perform Small bit shift left over if any
    # ------------------------------
    @PUSHI C1
    @IF_NOTZERO
       @POPNULL
       @PUSH32I(V) Low
       @PUSHI C1
       @CALL SHL32_small
       @POPI CarryOut
       @POP32I(V) Low
    @ELSE
       @POPNULL
       @MA2V 0 CarryOut
    @ENDIF
       

    # ------------------------------
    # Fallthrough: Set flags normally
    # ------------------------------
    @PUSH32I(V) Low
    @PUSH 1               # Mode 1 = ADD style → CarryIn sets CF
    @PUSHI CarryOut
    @PUSH 0               # Overflow always 0 for logical shift
    @CALL SetFlags32

:SHL32_End
    @PUSH32I(V) Low

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : SHL32_small
# Purpose  : Shift 32-bit value left by 1..7 bits (unsigned)
# Inputs   : [... Low High Count ]
# Output   : [... NewLow NewHigh CarryOut ]
# ===========================================================
@FUNCTION SHL32_small
:SHL32_small
@PUSHRETURN
@Locals
    @Local Low
    @Local High
    @Local Count
    @Local CarryOut
    @Local Bit15
    @Local i

    
    @POPI Count
    @POPI High
    @POPI Low
    @MA2V 0 CarryOut

    @ForIA2V i 0 Count

        # -------------------------------
        # Extract High’s MSB (bit shifted out)
        # Bit15 = (High & 0x8000) ? 1 : 0
        # -------------------------------
        @PUSHI High
        @AND 0x8000
        @IF_NOTZERO
            @POPNULL
            @MA2V 1 Bit15
        @ELSE
            @POPNULL
            @MA2V 0 Bit15
        @ENDIF

        # -------------------------------
        # Compute carry from Low >> 15
        # This is the bit that flows into High
        # -------------------------------
        @PUSHI Low
        @AND 0x8000
        @IF_NOTZERO
            @POPNULL
            @PUSH 1
        @ELSE
            @POPNULL
            @PUSH 0
        @ENDIF
        @POPI CarryOut   # temporary

        # -------------------------------
        # Low <<= 1
        # -------------------------------
        @PUSHI Low
        @SHLN 1
        @POPI Low

        # -------------------------------
        # High = (High << 1) | CarryOut
        # -------------------------------
        @PUSHI High
        @SHLN 1
        @ADDI CarryOut
        @POPI High

        # -------------------------------
        # Update final CarryOut
        # -------------------------------
        @PUSHI Bit15
        @POPI CarryOut

    @Next i

    @PUSHI Low
    @PUSHI High
    @PUSHI CarryOut
    

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Function : SHL32_1
# Purpose  : Shift 32-bit value left by 1 bit (unsigned)
# Inputs   : [ ... Low High ]
# Outputs  : [ ... NewLow NewHigh ]
# Notes    : Updates Flags32 CF with the last bit shifted out
# ===========================================================
@FUNCTION SHL32_1
:SHL32_1
@PUSHRETURN
#USE SHL32
    @PUSH 1
    @CALL SHL32
@POPRETURN
@RET
@ENDFUNCTION
# ===========================================================
# Function : SHR32
# Purpose  : Shift 32-bit value right by N bits (unsigned)
# Inputs   : [... Low High Count ]
# Outputs  : [... NewLow NewHigh CarryOut ]
# ===========================================================
@FUNCTION SHR32
:SHR32
@PUSHRETURN
@Locals
    @Local Low
    @Local High
    @Local Count
    @Local CarryOut
    @Local C8
    @Local C1
    @Local _I

    @POPI Count
    @POP32I(V) Low

    # -----------------------------
    # Case: Count > 32 -> result =0
    # -----------------------------    
    @PUSHI Count
    @IF_UGE_A 32
        @POPNULL
        @MA2V 0 Low
        @MA2V 0 High
        @MA2V 0 CarryOut
        # Set flags: (Low=0,High=0, Mode=1, Carry=0, OF=0)
        @PUSH32I(V) Low
        @PUSH 1
        @PUSH 0
        @PUSH 0
        @CALL SetFlags32

        @JMP SHR32_End    # (Structured “end section”, not an early escape)
    @ENDIF
    @POPNULL
    # ------------------------------
    # Case: Count == 0 → no shift
    # ------------------------------
    @PUSHI Count
    @IF_EQ_A 0
        @POPNULL
        @MA2V 0 CarryOut

        @PUSH32I(V) Low
        @PUSH 1
        @PUSH 0
        @PUSH 0
        @CALL SetFlags32

        @JMP SHR32_End
    @ENDIF
    @POPNULL

    # ------------------------------
    # Compute C8 = Count >> 3
    #         C1 = Count & 7
    # ------------------------------

    @PUSHI Count    @SHRN 3    @POPI C8
    @PUSHI Count    @AND 0x7   @POPI C1

    # ------------------------------
    # Perform full byte shifts
    # ------------------------------
    @ForIA2V _I 0 C8
        @Call32(V) SHR32_8 Low
        @POP32I(V) Low
    @Next _I

    # ------------------------------
    # Perform Small bit shift right over if any
    # ------------------------------
    @PUSHI C1
    @IF_NOTZERO
       @POPNULL
       @PUSH32I(V) Low
       @PUSHI C1
       @CALL SHR32_small
       @POPI CarryOut
       @POP32I(V) Low
    @ELSE
       @POPNULL
       @MA2V 0 CarryOut
    @ENDIF
       

    # ------------------------------
    # Fallthrough: Set flags normally
    # ------------------------------
    @PUSH32I(V) Low
    @PUSH 1               # Mode 1 = ADD style → CarryIn sets CF
    @PUSHI CarryOut
    @PUSH 0               # Overflow always 0 for logical shift
    @CALL SetFlags32

:SHR32_End
    @PUSH32I(V) Low
    

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ===========================================================
# Function : SHR32_small
# Purpose  : Shift 32-bit value right by 1..7 bits (unsigned)
# Inputs   : [... Low High Count ]
# Output   : [... NewLow NewHigh CarryOut ]
# ===========================================================
@FUNCTION SHR32_small
:SHR32_small
@PUSHRETURN
@Locals
    @Local Low
    @Local High
    @Local Count
    @Local CarryOut
    @Local Bit0
    @Local i

    @POPI Count
    @POP32I(V) Low
    @MA2V 0 CarryOut

    @ForIA2V i 0 Count

        # --------------------------------------------------
        # Extract LSB of Low → CarryOut (bit shifted out)
        # --------------------------------------------------
        @PUSHI Low
        @AND 0x0001
        @POPI CarryOut

        # --------------------------------------------------
        # Extract LSB of High for cascading into Low
        # --------------------------------------------------
        @PUSHI High
        @AND 0x0001
        @IF_NOTZERO
            @POPNULL
            @MA2V 0x8000 Bit0
        @ELSE
            @POPNULL
            @MA2V 0 Bit0
        @ENDIF

        # --------------------------------------------------
        # Low >>= 1, then OR in Bit0 at MSB
        # --------------------------------------------------
        @PUSHI Low
        @SHRN 1
        @ADDI Bit0
        @POPI Low

        # --------------------------------------------------
        # High >>= 1
        # --------------------------------------------------
        @PUSHI High
        @SHRN 1
        @POPI High

    @Next i

    @PUSHI Low
    @PUSHI High
    @PUSHI CarryOut

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : SHR32_1
# Purpose  : Shift 32-bit value right by 1 bit (unsigned)
# Inputs   : [ ... Low High ]
# Outputs  : [ ... NewLow NewHigh ]
# Notes    : Updates Flags32 CF with the last bit shifted out
# ===========================================================
@FUNCTION SHR32_1
:SHR32_1
@PUSHRETURN
@Locals
    @Local Low
    @Local High
#USE SHL32

    @POP32I(V) Low   # Pop Low and High from stack
    @PUSH32I(V) Low
    @PUSH 1
    @CALL SHL32

@EndLocals

@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : MUL32U
# Purpose  : Multiplytwo 32-bit values on the stack (little-endian)
# Inputs   : [ ... A32_Low A32_High B32_Low B32_High ]
# Outputs  : [ ... R32_Low R32_High ]
# Notes    :
#   - Carry out beyond 32 is store in OVF32
# ===========================================================
@FUNCTION MUL32U
:MUL32U
@PUSHRETURN
@Locals
    @Local A_Low
    @Local A_High
    @Local B_Low
    @Local B_High
    @Local P0_Low
    @Local P0_High
    @Local P1_Low
    @Local P1_High
    @Local P2_Low
    @Local P2_High
    @Local P3_Low
    @Local P3_High
    @Local Sum_Low
    @Local Sum_High
    @Local Carry
#USE ADD16U,MUL16x32U,ADD32U
    # Pop operands
    @POP32I(V) B_Low
    @POP32I(V) A_Low

    # Zero out the upper 32 bits for the 64 bit overflow.
    @MA2V 0 OVF32
    @MA2V 0 OVF32+2    

    # ---- 16×16 partial products ----
    # P0 = A_lo * B_lo
    @Call(VV) MUL16x32U A_Low B_Low
    @POPI P0_High
    @POPI P0_Low

    # P1 = A_hi * B_lo
    @Call(VV) MUL16x32U A_High B_Low
    @POPI P1_High
    @POPI P1_Low

    # P2 = A_lo * B_hi
    @Call(VV) MUL16x32U A_Low B_High
    @POPI P2_High
    @POPI P2_Low

    # P3 = A_hi * B_hi
    @Call(VV) MUL16x32U A_High B_High
    @POPI P3_High
    @POPI P3_Low


    # ---- Combine partial products ----
    # Low 32 bits: P0 + ((P1 + P2) << 16)
    # High 32 bits: P3 + (P1_High + P2_High) + carry from lower sum

    # Step 1: Sum (P1_Low + P2_Low)
    @Call(VV) ADD16U P1_Low P2_Low
    @POPI Sum_High    # carry out (0/1)
    @POPI Sum_Low

    # Step 2: Add ((Sum_Low << 16) + P0)
    # Simulate 32-bit addition
    @Call(AVVV) ADD32U 0 Sum_Low P0_Low P0_High
    @POPI Sum_High
    @POPI Sum_Low

    # Step 3: Compute upper 32 bits (for overflow / mantissa)
    # OVF32 = P3 + P1_High + P2_High + carry
    @Call(VV) ADD16U P3_Low P1_High    
    @POPI Carry
    @POPI P3_Low

    
    @PUSHI Carry         # Save First Carry
    @Call(VV) ADD16U P3_Low P2_High
    @POPI Carry
    @POPI P3_Low
    @ADDI Carry          # First Carry + 2nd Carry

    @Call(VV) ADD16U  P2_High P3_Low
    @POPI Carry
    @POPI P3_Low
    @ADDI Carry          # All 3 Carries added
    @ADDI P3_Low
    @POPI P3_Low         # IF there should be another carry here, that could be capture for 128bit math? Naaa

    @MV2V P3_Low OVF32   # global register
    @MV2V Carry OVF32+2  # High part of overflow.

    # ---- Return result ----
    @PUSHI Sum_Low
    @PUSHI Sum_High
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : MUL16x32U
# Purpose  : Multiply two unsigned 16-bit values, returning 32-bit result
# Inputs   : [ ... A16 B16 ]
# Outputs  : [ ... R_Low R_High ]
# Notes    :
#   - Performs full 16×16→32-bit multiply using shift/add method.
#   - R_Low = lower 16 bits
#   - R_High = upper 16 bits (overflow bits)
# ===========================================================
@FUNCTION MUL16x32U
:MUL16x32U
@PUSHRETURN
@Locals
    @Local A16
    @Local B16
    @Local R_Low
    @Local R_High
    @Local Bit
    @Local Mask
    @Local AShifter_L
    @Local AShifter_H    
    @Local Carry1
    @Local TempSum
    @Local Carry2
    @Local Carry3
    @Local TempSum_H


    @POPI B16
    @POPI A16
    @MA2V 0 R_Low
    @MA2V 0 R_High
    @MA2V 1 Mask     # Mask start 0x0001
    @MV2V A16 AShifter_L
    @MA2V 0 AShifter_H

    @ForIA2B Bit 0 16

       @IF_NEQ_AV 0 Bit
          # Shift AShifter_L and Mask by one
          @PUSHI AShifter_L @SHL @POPI AShifter_L
          @IF_CARRY
             @MA2V 1 Carry1
          @ELSE
             @MA2V 0 Carry1
          @ENDIF
          @PUSHI AShifter_H @SHL @POPI AShifter_H
          @IF_EQ_AV 1 Carry1
              @INCI AShifter_H
          @ENDIF
       @ENDIF

       # Check if bth-th bit of B16 is set
       
       @PUSHI B16
       @ANDI Mask
       @IF_NOTZERO

           # Step 1: Add AShifter_L to R_Low
           @Call(VV) ADD16U R_Low AShifter_L
           @POPI Carry1
           @POPI TempSum
           @MV2V TempSum R_Low

           # Step 2: Add AShifter_H to R_High
           @Call(VV) ADD16U R_High AShifter_H
           @POPI Carry2
           @POPI TempSum
           @MV2V TempSum TempSum_H
           
           # Step 3: Add carry from Step 1 to R_High
           @Call(VV) ADD16U TempSum_H Carry1
           @POPI Carry3
           @POPI TempSum
           @MV2V TempSum R_High
       @ENDIF
       @POPNULL
       @PUSHI Mask @SHL @POPI Mask     
    @Next Bit

    @PUSHI R_Low
    @PUSHI R_High
    

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : ADD16U
# Purpose  : Add two unsigned 16-bit values, return result + carry word
# Inputs   : [ ... A16 B16 ]
# Outputs  : [ ... R_Low Carry ]
# Notes    :
#   - Carry is returned as full word 0x0000 or 0x0001
#   - Does not affect Flags32
# ===========================================================
@FUNCTION ADD16U
:ADD16U
@PUSHRETURN
@Locals
    @Local A16
    @Local B16
    @Local R16
    @Local Carry

    @POPI B16
    @POPI A16

    @PUSHI A16
    @ADDI B16
    @POPI R16

    @IF_CARRY
        @MA2V 1 Carry
    @ELSE
        @MA2V 0 Carry
    @ENDIF

    @PUSHI R16
    @PUSHI Carry

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Function : SHL16x32
# Purpose  : Shift a 16-bit value left by N bits, producing a 32-bit result
# Inputs   : [ ... Value ShiftCount ]
# Outputs  : [ ... R_Low R_High ]
# Notes    :
#   - Performs logical left shift of Value by ShiftCount (0–15 typical).
#   - R_Low contains the shifted low 16 bits.
#   - R_High accumulates the overflow bits that shifted out of R_Low.
#   - Each shift is done one bit at a time, propagating carry from low to high.
#   - Does not modify Flags32 or any global registers.
#   - Useful for building higher-precision math routines (e.g. 16×32 or 32×64 shifts).
# ===========================================================

@FUNCTION SHL16x32
:SHL16x32
@PUSHRETURN
@Locals
    @Local ShiftCount
    @Local Value
    @Local PR_Low
    @Local PR_High
    @Local Index
    

    @POPI ShiftCount
    @POPI Value
    @MV2V Value PR_Low
    @MA2V 0 PR_High
    @ForIA2V Index 0 ShiftCount
        @PUSHI PR_Low  @SHL  @POPI PR_Low
        @PUSHI PR_High  @SHL  @POPI PR_High        
        @IF_CARRY
            @INCI PR_High
        @ENDIF
    @Next Index
    @PUSHI PR_Low
    @PUSHI PR_High

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : SHR16x32
# Purpose  : Shift a 16-bit unsigned value right by N bits,
#            returning a 32-bit result with zero-extended high word.
# Inputs   : [ ... Value ShiftCount ]
# Outputs  : [ ... R_Low R_High ]
# Notes    :
#   - Logical (unsigned) shift — upper bits are zero-filled.
#   - Equivalent to (Value >> ShiftCount) with zero extension.
#   - Useful for building 32-bit temporary values from 16-bit sources.
#   - Does not affect Flags32.
# ===========================================================
@FUNCTION SHR16x32
:SHR16x32
@PUSHRETURN
@Locals
    @Local ShiftCount
    @Local Value
    @Local R_Low
    @Local R_High
    @Local Index

    @POPI ShiftCount
    @POPI Value

    @PUSHI Value
    @ForIA2V Index 0 ShiftCount
       @SHR
    @Next Index
    @POPI R_Low

    @MA2V 0 R_High         # high word always zero

    @PUSHI R_Low
    @PUSHI R_High

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Purpose  : Multiplytwo 32-bit signed values on the stack (little-endian)
# Inputs   : [ ... A32_Low A32_High B32_Low B32_High ]
# Outputs  : [ ... R32_Low R32_High ]
# Notes    :
#   - Carry out beyond 32 bits is discarded.
#   - Ideal for mantissa math and temporary sums.
# ===========================================================
@FUNCTION MUL32S
:MUL32S
@PUSHRETURN
@Locals
    @Local A_Low
    @Local A_High
    @Local B_Low
    @Local B_High
    @Local SignA
    @Local SignB
    @Local R_Low
    @Local R_High
#USE MUL32U
#USE COMP232
    # Pop inputs (stack: [ ... A_Low A_High B_Low B_High ])
    @POP32I(V) B_Low
    @POP32I(V) A_Low

    # Determine signs (1 if negative)
    @PUSHI A_High
    @AND 0x8000
    @POPNULL   
    @IF_NOTZF       @PUSH 1    @ELSE       @PUSH 0    @ENDIF
    @POPI SignA


    @PUSHI B_High
    @AND 0x8000
    @POPNULL   
    @IF_NOTZF       @PUSH 1    @ELSE       @PUSH 0    @ENDIF
    @POPI SignB

    # If negative, negate to get absolute value

    @IF_EQ_AV 1 SignA
        @Call32(V) COMP232 A_Low
        @POP32I(V) A_Low
    @ENDIF

    @IF_EQ_AV 1 SignB
        @Call32(V) COMP232 B_Low
        @POP32I(V) B_Low
    @ENDIF

    # Multiply absolute values
    @Call32(VV) MUL32U A_Low B_Low
    @POP32I(V) R_Low

    # If signs differ, negate result
    @PUSHI SignA
    @PUSHI SignB
    @XORS
    @IF_NOTZERO
        @Call32(V) COMP232 R_Low
        @POP32I(V) R_Low
    @ENDIF
    @POPNULL
    
    # Push final result
    @PUSH32I(V) R_Low

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
############################################################
# DIV32U  -  Unsigned 32-bit divide A/B
# Inputs:  ( A_L A_H B_L B_H )
# Output:  ( R_L R_H Q_L Q_H )
# Notes:
#   - Restoring division, 32 iterations
#   - No normalization performed (consistent with EX716 rules)
#   - Uses shift16.ld helpers for bitmask creation
############################################################

@FUNCTION DIV32U
:DIV32U
@PUSHRETURN
@Locals
    @Local A_L
    @Local A_H
    @Local B_L
    @Local B_H
    @Local R_L
    @Local R_H
    @Local Q_L
    @Local Q_H
    @Local BitIndex
#USE SHL32_1,CMP32U,OR32,SUB32U

    ########################################################
    # Load inputs
    ########################################################
    @POP32I(V) B_L
    @POP32I(V) A_L

    ########################################################
    # Zero divisor → OVF32=1, return zeros
    # One divisor 
    ########################################################
    @PUSHI B_L @ORI B_H
    @IF_ZERO
        @POPNULL
        @M32A2V $$$0 R_L
        @M32A2V $$$0 Q_L
        @PUSHI Flags32 @OR O32Flag @POPI Flags32
        @JMP Div32U_Exit
    @ENDIF
    @POPNULL
    @Call32(VV) CMP32U ONE32 B_L
    @IF32_EQ
        @M32A2V $$$0 R_L
        @M32V2V A_L Q_L
        @JMP Div32U_Exit
    @ENDIF

    # Clear OVF32 for non-error case
    @PUSHI Flags32 @AND InvO32Flag @POPI Flags32

    @M32A2V $$$0 R_L
    @M32A2V $$$0 Q_L

    @ForIA2B BitIndex 0 32

        @Call32(V) SHL32_1 R_L           # When calling 32bit functions the R_H is implied.
        @POP32I(V) R_L
        # Flags32 has CF but we don't need it yet.

        # A << 1
        @PUSHI A_L @ORI A_H
        @IF_NOTZERO
          # Don't both Shifting A if its already zero.
          @Call32(V) SHL32_1 A_L
          @POP32I(V) A_L
        @ENDIF
        @POPNULL

        #  true if CF set.
        @PUSHI Flags32 @AND C32Flag
        @IF_NOTZERO
           @PUSH32I(V) R_L   #      R |= 1
           @Call32(V) OR32 ONE32
           @POP32I(V) R_L
        @ENDIF
        @POPNULL
        
        # Q <<1
        @Call32(V) SHL32_1 Q_L
        @POP32I(V) Q_L
        @Call32(VV) CMP32U R_L B_L

        @IF32_UGE
           # R=R-B
           @Call32(VV) SUB32U R_L B_L
           @POP32I(V) R_L
           # Q |= 1
           @PUSH32I(V) Q_L
           @Call32(V) OR32 ONE32
           @POP32I(V) Q_L
        @ENDIF
    @Next BitIndex
:Div32U_Exit
    ########################################################
    # Return:  R then Q
    ########################################################
    @PUSH32I(V) R_L
    @PUSH32I(V) Q_L
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Function : DIV32S
# Purpose  : Divide two 32-bit signed values on the stack (little-endian)
# Inputs   : [ ... A32_Low A32_High B32_Low B32_High ]
# Outputs  : [ ... Quotient_Low Quotient_High, Remainder_Low Remainder_High ]
# Notes    :
#   - Handles full signed range, including INT_MIN edge cases.
#   - Carry out beyond 32 bits is discarded.
#   - Uses DIV32U for magnitude division after normalization.
# ===========================================================
@FUNCTION DIV32S
:DIV32S
@PUSHRETURN
@Locals
    @Local A_Low
    @Local A_High
    @Local B_Low
    @Local B_High
    @Local SignA
    @Local SignB
    @Local R_Low
    @Local R_High
    @Local Rem_Low
    @Local Rem_High
    @Local AB_A_Low
    @Local AB_A_High
    @Local AB_B_Low
    @Local AB_B_High
#USE COMP232,DIV32U,CMP32U
    # Pop inputs (stack: [ ... A_Low A_High B_Low B_High ])
    @POP32I(V) B_Low
    @POP32I(V) A_Low


    @MA2V 0 SignA
    @MA2V 0 SignB

    @M32V2V A_Low AB_A_Low
    @M32V2V B_Low AB_B_Low    

    @Call32(VV) CMP32U AB_A_Low AB_B_Low
    @IF32_EQ
       # |A| == |B| -> 1,0
       @M32A2V $$$01 R_Low
       @M32A2V $$$00 Rem_Low
       @JMP DoneDIV32S
    @ENDIF
    @PUSHI A_High @AND 0x8000
    @IF_NEQ_A 0
       @MA2V 1 SignA
       @Call32(VA) CMP32U A_Low $$$0x80000000
       @IF32_EQ
          # INT_MIN
          @M32V2V A_Low AB_A_Low
       @ELSE
          @Call32(V) COMP232 A_Low
          @POP32I(V) AB_A_Low
       @ENDIF
    @ENDIF
    @POPNULL
    @PUSHI B_High @AND 0x8000
    @IF_NEQ_A 0
       @MA2V 1 SignB
       @Call32(VA) CMP32U B_Low $$$0x80000000
       @IF32_EQ
          # INT_MIN
          @M32V2V B_Low AB_B_Low
       @ELSE
          @Call32(V) COMP232 B_Low
          @POP32I(V) AB_B_Low
       @ENDIF       
    @ENDIF    
    @POPNULL
    @Call32(VV) DIV32U AB_A_Low AB_B_Low
    @POP32I(V) R_Low
    @POP32I(V) Rem_Low


    @IF_NEQ_VV SignA SignB
      @Call32(V) COMP232 R_Low
      @POP32I(V) R_Low
    @ENDIF
    @IF_EQ_AV 1 SignA
      @Call32(V) COMP232 Rem_Low
      @POP32I(V) Rem_Low       
    @ENDIF
    :DoneDIV32S
    # -------------------------------------------------------
    @PUSH32I(V) Rem_Low
    @PUSH32I(V) R_Low

    # -------------------------------------------------------
    # Restore locals and return
    # -------------------------------------------------------
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION



# ===========================================================
# Function  : SHL64
# Purpose   : Shift Lefts 32 bit word up to 32 bits over, overflowing in high 32 bit double word
# Inputs    : [ ... Low-word high-word Count ]
# Outputs   : [ ... OverFlowLow OverFlowHigh New-Low New-High ]
# ===========================================================
@FUNCTION SHL3264
:SHL3264
@PUSHRETURN
@Locals
    @Local In_Low
    @Local In_High
    @Local In_Count
    @Local Over_Low
    @Local Over_High
    @Local Index1

    @POPI In_Count
    @POP32I(V) In_Low

    @MA2V 0 Over_Low
    @MA2V 0 Over_High    

    @ForIA2V Index1 0 In_Count
        # -- Shif low though carry into high ---
        @FCLR
        @PUSHI In_Low   @SHL  @POPI In_Low
        @PUSHI In_High  @RLTC @POPI In_High
        @PUSHI Over_Low @RLTC @POPI Over_Low
        @PUSHI Over_High @SHL @POPI Over_High
    @Next Index1
#   Save the Flag result into the Flags32 register
    @IF_CARRY
       @PUSH C32Flag @ORI Flags32 @POPI Flags32    # Set the CF 32 bit flag
    @ELSE
       @PUSH C32Flag @INV @ANDI Flags32 @POPI Flags32 # Zero the CF flag.
    @ENDIF
    
    @PUSH32I(V) Over_Low
    @PUSH32I(V) In_Low
    
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
     
############################################################
# SetBit32
# (Low High Bit -- Low' High')
#
# Sets the specified bit (0–31) in a 32-bit word.
#
# Uses SHL16_BY_N to construct masks cleanly.
############################################################
@FUNCTION SetBit32
:SetBit32
@PUSHRETURN
@Locals
    @Local ValL
    @Local ValH
    @Local Bit
    @Local Mask
#USE SHL16_BY_N
    # Pop arguments
    @POPI Bit
    @POPI ValH
    @POPI ValL

    ########################################################
    # Case 1: Bit < 16 → operate on low word
    ########################################################
    @PUSHI Bit
    @IF_ULT_A 16
        @POPNULL

        # Build mask = (1 << Bit)
        @Call(AV) SHL16_BY_N 1 Bit
        @POPI Mask

        # ValL |= mask
        @PUSHI ValL  @ORI Mask  @POPI ValL

    @ELSE
        ####################################################
        # Case 2: Bit >= 16 → operate on high word
        ####################################################
        @POPNULL

        # Compute shift = Bit - 16
        @PUSHI Bit  @SUB 16  @POPI Mask      # reuse Mask as temporary shift amount

        # mask = (1 << (Bit - 16))
        @Call(AV) SHL16_BY_N 1 Mask
        @POPI Mask

        # ValH |= mask
        @PUSHI ValH  @ORI Mask  @POPI ValH

    @ENDIF

    ########################################################
    # Return (ValL ValH)
    ########################################################
    @PUSHI ValL
    @PUSHI ValH

    # cleanup

@EndLocals

@POPRETURN
@RET
@ENDFUNCTION


# ===========================================================
# Function : ClearBit32
# Purpose  : Clear bit N in 32-bit value (Quotient |= 1<<N)
# Inputs   : [ ... Value_Low Value_High BitIndex ]
# Outputs  : [ ... NewLow NewHigh ]
# ===========================================================
@FUNCTION ClearBit32
:ClearBit32
@PUSHRETURN
@Locals
    @Local ValL
    @Local ValH
    @Local Bit
    @Local BitMask_L
    @Local BitMask_H
#USE SHL16x32
    @POPI Bit
    @POPI ValH
    @POPI ValL

    @PUSHI Bit
    @IF_ULT_A 16
        @POPNULL
        @Call(AV) SHL16x32 1 Bit
        @POP32I(V) BitMask_L
        @PUSHI BitMask_L @INV @ANDI ValL @POPI ValL
    @ELSE
        @POPNULL
        @PUSH 1
        @PUSHI Bit @SUBI 16         
        @CALL SHL16x32
        @POP32I(V) BitMask_H
        @PUSHI BitMask_H @INV @ANDI ValH @POPI ValH
    @ENDIF


    @PUSH32I(V) ValL
    
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ============================================================
# Function : DIV10_32U
# Purpose  : 'quick' divide by ten (When later optimized)
# Inputs   : [ ... N32_Low N32_High ]
# Outputs  : [ ... Quotient_Low Quotient_High Remainder_low Remainder_High ]
# ============================================================
@FUNCTION DIV10_32U
:DIV10_32U
#USE DIV32U
@PUSHRETURN
   @PUSH32(A) 10    # Dirty but not optimized.
   @CALL DIV32U
@POPRETURN
@RET
@ENDFUNCTION
# ============================================================
# Some Later time to optimied with multiplicative inverse
# This will require 64 bit multiple, so do later.
# q = ( n * 0xCCCCCCD) >> 35
# r = n - q*10
# ============================================================
# Function : i32tos
# Purpose  : 32 bit integer to string.
# Inputs   : [ StrPtr InValue(32) InBase(16) ]
# Outputs  : [ ... ]   ( StrPtr points to results )
# ============================================================
@FUNCTION i32tos
:i32tos
@PUSHRETURN
@Locals
   @Local StrPtr
   @Local In_Low
   @Local In_High
   @Local InBase
   @Local InBase_High
   @Local NegFlag
   @Local RevIndex
   @Local Rem_Low
   @Local Rem_High
#USE CMP32S,COMP232,CMP32U,DIV32U
   @IF_GT_A 16            # Limit to max of base 16
      @POPNULL
      @PUSH 16
   @ENDIF
   @POPI InBase
   @MA2V 0 InBase_High    # Base is 16 bit but our math will be on 32 bit functions.
   @POP32I(V) In_Low
   @POPI StrPtr

   @MA2V "0\0" WorkBuff    # Preload with "0\0"
   @MA2V 0 WorkBuff+2
   @MA2V 0 WorkBuff+4
   @MA2V 0 WorkBuff+6
   @MA2V 0 WorkBuff+8

   @MA2V 0 NegFlag

   @Call32(VA) CMP32S In_Low $$$0
   @IF32_EQ
      # Handle the Zero case quickly
      @PUSH "0\0"
      @POPII StrPtr
      @JMP Endi32tos
   @ENDIF   
   @IF32_LT
      # If Negative, invert and set flag.
      @MA2V 1 NegFlag
      @Call32(V) COMP232 In_Low
      @POP32I(V) In_Low
   @ENDIF
   @MA2V WorkBuff RevIndex
   @WHEN           # WHEN DO ENDWHEN allow more complex conditionals than normal WHILEs
      @Call32(VA) CMP32U In_Low $$$0
      @IF32_GT
         @PUSH 1
      @ELSE
         @PUSH 0
      @ENDIF
   @DO_NOTZERO
      @POPNULL
      @Call32(VV) DIV32U In_Low InBase    # In = In/Base, remainder on stack
      @POP32I(V) In_Low        # quotient
      @POP32I(V) Rem_Low       # remainder/digit
      @PUSHI Rem_Low
      @AND 0xf          # Bases larger than 16 not supported
      @ADD 0x30         # Convert to ascii
      @IF_GT_A 0x39     # 'A' is 0x41 so add 7 to 3A to make 'A' for ten
         @ADD 0x7
      @ENDIF
      @POPII RevIndex
      @INCI RevIndex
   @ENDWHEN
   @POPNULL
   # Now revere the work buffer into StrPtr
   @IF_EQ_VA NegFlag 1
      # Handle Negative Sign
      @PUSH "-\0"
      @POPII StrPtr
      @INCI StrPtr
   @ENDIF
   @PUSHI RevIndex
   @WHILE_GT_A WorkBuff
      @POPNULL
      @DECI RevIndex
      @PUSHII RevIndex @AND 0xff
      @POPII StrPtr
      @INCI StrPtr
      @PUSHI RevIndex
   @ENDWHILE
   @POPNULL
:Endi32tos
   @EndLocals
   @POPRETURN
@RET
@ENDFUNCTION

:WorkBuff "00000000000" $$0   # 11 bytes for max length int32 string.
# ============================================================
# Function : stoi32
# Purpose  : string to 32 bit integer
# Inputs   : [ StrPtr ]
# Outputs  : [ ... ]   ( I32PUSH) 
# ============================================================
#
@FUNCTION stoi32
:stoi32
@PUSHRETURN
@Locals
    @Local StrPtr
    @Local NegFlag
    @Local Base
    @Local Base_High
    @Local InValue_Low
    @Local InValue_High
    @Local Mult_Low
    @Local Mult_High
    @Local Length
    @Local Digit
    @Local Digit_High
    @Local Temp_Low
#USE strlen,MUL32U,ADD32U,COMP232

    # --- Initialize ---
    @POPI StrPtr
    @MA2V 0 NegFlag
    @MA2V 10 Base
    @MA2V 0 Base_High
    @MA2V 0 InValue_Low
    @MA2V 0 InValue_High
    @MA2V 1 Mult_Low
    @MA2V 0 Mult_High
    @MA2V 0 Digit_High

    # Get string length
    @PUSHI StrPtr @CALL strlen @POPI Length

    # --- Sign ---
    @PUSHII StrPtr @AND 0xff
    @IF_EQ_A "-\0"
       @POPNULL
       @MA2V 1 NegFlag
       @INCI StrPtr
       @DECI Length
    @ELSE
       @POPNULL
    @ENDIF

    # --- Base prefix ---
    @PUSHI Length
    @IF_GT_A 2
       @POPNULL
       @PUSHII StrPtr @AND 0xff
       @IF_EQ_A 0x0030       # first char '0' ?
          @POPNULL
          @INCI StrPtr
          @PUSHII StrPtr @AND 0xff
          @SWITCH
             @CASE "x\0"
                @MA2V 16 Base
                @INCI StrPtr
                @DEC2I Length
                @CBREAK
             @CASE "o\0"
                @MA2V 8 Base
                @INCI StrPtr
                @DEC2I Length
                @CBREAK
             @CASE "b\0"
                @MA2V 2 Base
                @INCI StrPtr
                @DEC2I Length
                @CBREAK
             @CDEFAULT
                @MA2V 10 Base
                @DECI StrPtr
                @CBREAK
          @ENDCASE
       @ENDIF
    @ENDIF
    @POPNULL

    # --- Main loop ---
    @PUSHI Length
    @WHILE_NOTZERO
        @POPNULL
        @DECI Length
        @PUSHI StrPtr @ADDI Length @PUSHS @AND 0xff
        @SUB "0\0"
        @IF_EQ_VA Base 16
            @IF_GE_A 10
                @SUB 7
            @ENDIF
        @ENDIF
        @POPI Digit

        # Multiply digit by multiplier → add to accumulator
        # Compute product → store in temp
        @Call32(VV) MUL32U Mult_Low Digit
        @POP32I(V) Temp_Low

        # Add to accumulator explicitly
        @PUSH32I(V) InValue_Low
        @PUSH32I(V) Temp_Low
        @CALL ADD32U
        @POP32I(V) InValue_Low

        # Multiplier *= Base
        @Call32(VV) MUL32U Mult_Low Base
        @POP32I(V) Mult_Low

        @PUSHI Length
    @ENDWHILE
    @POPNULL

    # --- Apply sign ---
    @IF_EQ_AV 1 NegFlag
       @Call32(V) COMP232 InValue_Low
       @POP32I(V) InValue_Low
    @ENDIF

    # --- Return ---
    @PUSH32I(V) InValue_Low
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION



########################
# Common Local Storage. Non-Reentrent
:Flags32 0   # Flags32 CNZO  (C<<3 | N<<2 | Z<<1 | O)
:OVF32 0 0 # Stores overflow High 32 bits for cases when 32bit mul requires 64 bit result
#
# Some common fixed numbers to save some memory
:ONE32 $$$01
:ZERO32 $$$0
:TWO32 $$$2

@SIZESINCE
ENDBLOCK
