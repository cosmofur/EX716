! IMath32Define
M IMath32Define
I common.mc
L mul.ld
M SIZESINCECOMMENT lmath.ld

########################
# Published functions
G ADD32S G SUB32S G CMP32S
G AND32S G OR32S G XOR32S G INV32S G COMP232S
G SHL32 G SHR32
G Flags32 G C32Flag G N32Flag G Z32Flag G O32Flag
G MUL32US G MUL16x32U G OVF32 G SHL16x32 G SHR16x32
G MUL32S G ONE32 G TWO32 G ZERO32

=C32Flag 0x8
=N32Flag 0x4
=Z32Flag 0x2
=O32Flag 1



########################
# Common Local Storage. Non-Reentrent
:A32_Low 0
:A32_High 0
:B32_Low 0
:B32_High 0
:R32_Low 0
:R32_High 0
:Temp_Low 0
:Temp_High 0
:Flags32 0   # Flags32 CNZO  (C<<3 | N<<2 | Z<<1 | O)
:OVF32 0 0 # Stores overflow High 32 bits for cases when 32bit mul requires 64 bit result
#
# Some common fixed numbers to save some memory
:ONE32 $$$01
:ZERO32 $$$0
:TWO32 $$$2

#########################
# Utility Macros, use after a CMP32 or flag chaning 32 function.
#
# Base Cases
#  A == B  Z=1
M IF32_EQ @PUSHI Flags32 @AND Z32Flag @CMP 0 @POPNULL @IF_NOTZF
#  A != B  Z=0
M IF32_NE @PUSHI Flags32 @AND Z32Flag @CMP 0 @POPNULL @IF_ZFLAG
# Unsigned group
#
#  A>B C=1
M IF32_UGT @PUSHI Flags32 @AND C32Flag @CMP 0 @POPNULL @IF_NOTZF
# A <= B   C=0  (not greater)
M IF32_ULE @PUSHI Flags32 @AND C32Flag @CMP 0 @POPNULL @IF_ZFLAG
# A < B (C=0 and Z=0)
M IF32_ULT @PUSH C32Flag @ORI Z32Flag @AND C32Flag @CMP 0 @POPNULL @IF_ZFLAG
# A >= B (C=1 and Z=1)
M IF32_UGE @PUSHI Flags32 @PUSHI C32Flag @OR Z32Flag @ANDS @CMP 0 @POPNULL @IF_NOTZF
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
#
# Call Macros to make Calling mixed 32 bit values eaiser

# Helper Macro call
# Insert32 Label1(AA) $$$Value1 Label $$$Value2
M Insert32(AA) @JMP Skip_%0 :%1 %2 :%3 %4 :Skip_%0
# Insert32(A) Label1 $$$Value1
M Insert32(A) @JMP Skip_%0 :%1 %2 :Skip_%0
#
# Call32(AA) turn immeidate $$$'s into lables then Call(vvvv) with those lables
M Call32(AA) @Insert32(AA) V1_%0 %2 V2_%0 %3 @Call(vvvv) %1 V1_%0 V1_%0+2 V2_%0 V2_%0+2
#
# Call32(Av) turn first immediate into $$$ and and pass variable as well to Call(vvvv)
M Call32(Av) @Insert32(A) V1_%0 %2 @Call(vvvv) %1 V1_%0 V1_%0+2 %3 %3+2
#
# Call32(vA) turn second immediate into $$$ and and pass variable as well to Call(vvvv)
M Call32(vA) @Insert32(A) V2_%0 %3 @Call(vvvv) %1 %2 %2+2 V2_%0 V2_%0+2
#
# Call32(vv) when both paramaters or 32b variables
M Call32(vv) @Call(vvvv) %1 %2 %2+2 %3 %3+2
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
M Call32(A) @Insert32(A) V1_%0 %2 @Call(vv) %1 V1_%0 V1_%0+2
#
# Call32(v) For single paramater 32 bit paramager function calls
M Call32(v) @PUSHI %2 @PUSHI %2+2 @CALL %1
#
# Call32(P) For single paramater PtrTo32bit function calls
M Call32(P) @PUSHII %2 @PUSHI %2 @ADD 2 @PUSHS @CALL %1
#
# Now the POP versions for simpifying POPing 2 word results into 32 bit variables
#
# POP32I(v) Pops right into a simple 32 bit variable stack High val on top
M POP32I(v) @PUSH %1+2 @POPS @POPI %1
#
# POP32II(v) Pops into PtrTo32bit (Note we're not using the 'P' term to stay consistent with POPII)
M POP32II(v) @PUSHI %1 @ADD 2 @POPS @PUSHI %1 @POPS 




# ===========================================================
# Function : ADD32S
# Purpose  : Add two 32-bit values on the stack (little-endian)
# Inputs   : [ ... A32_Low A32_High B32_Low B32_High ]
# Outputs  : [ ... R32_Low R32_High ]
# Notes    :
#   - Operates purely on the stack, no pointers.
#   - Carry out beyond 32 bits is discarded.
#   - Ideal for mantissa math and temporary sums.
# ===========================================================
:ADD32S
@PUSHRETURN
#
@LocalVar SumLow 01
@LocalVar CarryAmt 02
    @POP32I(v) B32_Low
    @POP32I(v) A32_Low
    @MA2V 0 SumLow
    @MA2V 0 CarryAmt
    # --- Compute full 16+16-bit sum of low halves
    @PUSHI A32_Low
    @ADDI B32_Low      # result on stack, carry flag set accordingly
    @POPI  SumLow
    @PUSHI A32_Low
    @ADDI B32_Low
    @SUBI SumLow       # (A32_Low+B32_Low) - result_low = carry portion.
    @POPI CarryAmt

    # --- High word addition ---
    @PUSHI A32_High
    @ADDI B32_High
    @ADDI CarryAmt
    @POPI  R32_High

    # --- Push result back to stack (low first, then high) ---
    @PUSHI SumLow
    @PUSHI R32_High
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

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
:SUB32S
@PUSHRETURN
    @POP32I(v) B32_Low
    @POP32I(v) A32_Low

    # --- Low word subtraction ---
    @PUSHI A32_Low
    @SUBI  B32_Low
    @POPI  R32_Low

    # --- Adjust high word if borrow occurred ---
    @IF_CARRY           # Carry → borrow
        @DECI A32_High  # Subtract 1 from A_high
    @ENDIF

    # --- High word subtraction ---
    @PUSHI A32_High
    @SUBI  B32_High
    @POPI  R32_High

    # --- Push result back (low first, then high) ---
    @PUSHI R32_Low
    @PUSHI R32_High
@POPRETURN
@RET

# ===========================================================
# Function : CMP32S
# Purpose  : Compare two 32-bit values on the stack (little-endian)
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : none (flags set: Z,N,C)
# Notes    :
#   - Sets flags as if performing A − B.
#   - Uses same carry convention as SUB32S (carry = borrow).
# ===========================================================
:CMP32S
@PUSHRETURN
@LocalVar Carry32Tmp 01
    @POP32I(v) B32_Low
    @POP32I(v) A32_Low

    @MA2V 0 Flags32
    @MA2V 0 Carry32Tmp

    # --- Low word subtraction ---
    @PUSHI A32_Low
    @SUBI  B32_Low
    @POPI  R32_Low
    @IF_CARRY
        @DECI A32_High
        @MA2V 1 Carry32Tmp    # Record borrow from low word
    @ENDIF

    # --- High word subtraction ---
    @PUSHI A32_High
    @SUBI  B32_High
    @POPI  R32_High

    # --- Compute composite flags ---
    # Carry (A < B)
    @IF_EQ_AV 1 Carry32Tmp       # No borrow in 32-bit sense
       @PUSHI Flags32
       @OR C32Flag
       @POPI Flags32
    @ELSE
       @PUSHI A32_High
       @IF_ULT_V B32_High
           @PUSHI Flags32
           @OR C32Flag
           @POPI Flags32
       @ENDIF
    @ENDIF

    # Zero flag
    @PUSHI R32_Low
    @ORI R32_High
    @IF_ZERO
        @PUSHI Flags32
        @OR Z32Flag
        @POPI Flags32
    @ENDIF
    @POPNULL

    # Negative flag (check sign bit of high word)
    @PUSHI R32_High
    @AND 0x8000
    @IF_NOTZERO
        @PUSHI Flags32
        @OR N32Flag
        @POPI Flags32
    @ENDIF
    @POPNULL

@RestoreVar 01
@POPRETURN
@RET
# ===========================================================
# Function : AND32S
# Purpose  : Bitwise AND of two 32-bit values on the stack
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================
:AND32S
@PUSHRETURN
    @POP32I(v) B32_Low
    @POP32I(v) A32_Low


    @PUSHI A32_Low
    @ANDI B32_Low
    @POPI  R32_Low

    @PUSHI A32_High
    @ANDI B32_High
    @POPI  R32_High

    @PUSHI R32_Low
    @PUSHI R32_High
@POPRETURN
@RET
# ===========================================================
# Function : OR32S
# Purpose  : Bitwise OR of two 32-bit values on the stack
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

:OR32S
@PUSHRETURN
    @POP32I(v) B32_Low
    @POP32I(v) A32_Low


    @PUSHI A32_Low
    @ORI   B32_Low
    @POPI  R32_Low

    @PUSHI A32_High
    @ORI   B32_High
    @POPI  R32_High

    @PUSHI R32_Low
    @PUSHI R32_High
@POPRETURN
@RET
# ===========================================================
# Function : XOR32S
# Purpose  : Bitwise XOR of two 32-bit values on the stack
# Inputs   : [ ... A_low A_high B_low B_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

:XOR32S
@PUSHRETURN
    @POP32I(v) B32_Low
    @POP32I(v) A32_Low

    @PUSHI A32_Low
    @XORI  B32_Low
    @POPI  R32_Low

    @PUSHI A32_High
    @XORI  B32_High
    @POPI  R32_High

    @PUSHI R32_Low
    @PUSHI R32_High
@POPRETURN
@RET
# ===========================================================
# Function : INV32S
# Purpose  : Bitwise INV/NOT of a 32-bit value on the stack
# Inputs   : [ ... A_low A_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

:INV32S
@PUSHRETURN
    @POP32I(v) A32_Low

    @PUSHI A32_Low
    @INV
    @POPI R32_Low

    @PUSHI A32_High
    @INV
    @POPI R32_High

    @PUSHI R32_Low
    @PUSHI R32_High
@POPRETURN
@RET
# ===========================================================
# Function : COMP232S
# Purpose  : Take the 2's compliment of 32-bit value on stack
# Inputs   : [ ... A_low A_high ]
# Outputs  : [ ... R_low R_high ]
# ===========================================================

:COMP232S
@PUSHRETURN
    @POP32I(v) A32_Low

    # Invert both words
    @PUSHI A32_Low
    @INV
    @POPI R32_Low
    
    @PUSHI A32_High
    @INV
    @POPI R32_High

    # Add 1 (low word only, with carry)
    @PUSHI R32_Low
    @ADD 1
    @POPI R32_Low
    @IF_CARRY
       @INCI R32_High    
    @ENDIF

    @PUSHI R32_Low
    @PUSHI R32_High
@POPRETURN
@RET

# ===========================================================
# Function : SHL32
# Purpose  : Shift 32-bit value left by N bits (unsigned)
# Inputs   : [ ... Low High Count ]
# Outputs  : [ ... NewLow NewHigh ]
# ===========================================================
:SHL32
@PUSHRETURN
    @LocalVar Low 01
    @LocalVar High 02
    @LocalVar Count 03
    @LocalVar BitShift 04
    @LocalVar WordShift 05
    @LocalVar Temp 06

    @POPI Count
    @POPI High
    @POPI Low

    # If Count >= 32 → zero result
    @PUSHI Count
    @IF_UGE_A 32
        @POPNULL
        @PUSH 0
        @PUSH 0
        @JMP SHL32_Exit
    @ENDIF
    @POPNULL

    # WordShift = Count / 16
    @MV2V Count WordShift
    @PUSHI WordShift
    @SHRN 4
    @POPI WordShift

    # BitShift = Count % 16
    @MV2V Count BitShift
    @AND 0x000F

    # Case 1: WordShift = 1 → move low→high
    @IF_EQ_AV 1 WordShift
        @MV2V Low Temp
        @MA2V 0 Low
        @MV2V Temp High
    @ENDIF

    # Shift both halves
    @IF_NEQ_AV 0 BitShift
        @PUSHI Low
        @CALL SHL16x32
        @POPI Low
        @POPI Temp
        # Mix carry from Low into High
        @PUSHI High
        @ORI Temp
        @POPI High
        @PUSHI High
        @CALL SHL16x32
        @POPI High
        @POPNULL
    @ENDIF

:SHL32_Exit
    @PUSHI Low
    @PUSHI High

    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

# ===========================================================
# Function : SHR32
# Purpose  : Shift 32-bit value right by N bits (unsigned)
# Inputs   : [ ... Low High Count ]
# Outputs  : [ ... NewLow NewHigh ]
# ===========================================================
:SHR32
@PUSHRETURN
    @LocalVar Low 01
    @LocalVar High 02
    @LocalVar Count 03
    @LocalVar BitShift 04
    @LocalVar WordShift 05
    @LocalVar Temp 06

    @POPI Count
    @POPI High
    @POPI Low

    @PUSHI Count
    @IF_UGE_A 32
        @POPNULL
        @PUSH 0
        @PUSH 0
        @JMP SHR32_Exit
    @ENDIF
    @POPNULL

    # WordShift = Count / 16
    @MV2V Count WordShift
    @PUSHI WordShift
    @SHRN 4
    @POPI WordShift

    # BitShift = Count % 16
    @MV2V Count BitShift
    @AND 0x000F

    # Case 1: WordShift = 1 → move high→low
    @IF_EQ_AV WordShift 1
        @MV2V High Temp
        @MA2V 0 High
        @MV2V Temp Low
    @ENDIF

    # Shift both halves
    @IF_NOTZERO BitShift
        @PUSHI High
        @CALL SHR16x32
        @POPI Temp
        @POPI High
        # Mix borrow from High into Low
        @PUSHI Low
        @ORI Temp
        @POPI Low
        @PUSHI Low
        @CALL SHR16x32
        @POPI Temp
        @POPI Low
    @ENDIF

:SHR32_Exit
    @PUSHI Low
    @PUSHI High

    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET



# ===========================================================
# Function : MUL32US
# Purpose  : Multiplytwo 32-bit values on the stack (little-endian)
# Inputs   : [ ... A32_Low A32_High B32_Low B32_High ]
# Outputs  : [ ... R32_Low R32_High ]
# Notes    :
#   - Carry out beyond 32 is store in OVF32
# ===========================================================
:MUL32US
@PUSHRETURN
    @LocalVar A_Low     01
    @LocalVar A_High    02
    @LocalVar B_Low     03
    @LocalVar B_High    04
    @LocalVar P0_Low    05
    @LocalVar P0_High   06
    @LocalVar P1_Low    07
    @LocalVar P1_High   08
    @LocalVar P2_Low    09
    @LocalVar P2_High   10
    @LocalVar P3_Low    11
    @LocalVar P3_High   12
    @LocalVar Sum_Low   13
    @LocalVar Sum_High  14
    @LocalVar Carry     15

    # Pop operands
    @POP32I(v) B_Low
    @POP32I(v) A_Low

    # Zero out the upper 32 bits for the 64 bit overflow.
    @MA2V 0 OVF32
    @MA2V 0 OVF32+2    

    # ---- 16×16 partial products ----
    # P0 = A_lo * B_lo
    @Call(vv) MUL16x32U A_Low B_Low
    @POPI P0_High
    @POPI P0_Low

    # P1 = A_hi * B_lo
    @Call(vv) MUL16x32U A_High B_Low
    @POPI P1_High
    @POPI P1_Low

    # P2 = A_lo * B_hi
    @Call(vv) MUL16x32U A_Low B_High
    @POPI P2_High
    @POPI P2_Low

    # P3 = A_hi * B_hi
    @Call(vv) MUL16x32U A_High B_High
    @POPI P3_High
    @POPI P3_Low

    @PRT "Partial Products are:"
    @PRT "PO: " @PRTHEXI P0_Low @PRTHEXI P0_High @PRTSP @PRT32 P0_Low @PRTNL
    @PRT "P1: " @PRTHEXI P1_Low @PRTHEXI P1_High @PRTSP @PRT32 P0_Low @PRTNL
    @PRT "P2: " @PRTHEXI P2_Low @PRTHEXI P2_High @PRTSP @PRT32 P0_Low @PRTNL
    @PRT "P3: " @PRTHEXI P3_Low @PRTHEXI P3_High @PRTSP @PRT32 P0_Low @PRTNL
    
    

    # ---- Combine partial products ----
    # Low 32 bits: P0 + ((P1 + P2) << 16)
    # High 32 bits: P3 + (P1_High + P2_High) + carry from lower sum

    # Step 1: Sum (P1_Low + P2_Low)
    @Call(vv) ADD16U P1_Low P2_Low
    @POPI Sum_High    # carry out (0/1)
    @POPI Sum_Low

    @PRT "    # Step 1: Sum (P1_Low + P2_Low)\n"
    @PRT "Sum=" @PRTHEXI Sum_Low @PRTHEXI Sum_High @PRTSP @PRT32 Sum_Low @PRTNL
    

    # Step 2: Add ((Sum_Low << 16) + P0)
    # Simulate 32-bit addition
    @Call(Avvv) ADD32S 0 Sum_Low P0_Low P0_High
    @POPI Sum_High
    @POPI Sum_Low

    @PRT "    # Step 2: Add ((Sum_Low << 16) + P0)\n"
    @PRT "Sum=" @PRTHEXI Sum_Low @PRTHEXI Sum_High @PRTSP @PRT32 Sum_Low @PRTNL

    # Step 3: Compute upper 32 bits (for overflow / mantissa)
    # OVF32 = P3 + P1_High + P2_High + carry
    @Call(vv) ADD16U P3_Low P1_High    
    @POPI Carry
    @POPI P3_Low

    @PRT "    # Step 3: Compute upper 32 bits (for overflow / mantissa)\n"
    @PRT "Carry = " @PRTHEXI Carry @PRTNL
    @PRT "P3_Low = " @PRTHEXI P3_Low @PRTNL
    
    @PUSHI Carry         # Save First Carry
    @Call(vv) ADD16U P3_Low P2_High
    @POPI Carry
    @POPI P3_Low
    @ADDI Carry          # First Carry + 2nd Carry

    @PRT "     # Step P3_Low + P2+High + Carry\n"
    @PRT "Result = :" @PRTHEXTOP @PRTNL

    @Call(vv) ADD16U  P2_High P3_Low
    @POPI Carry
    @POPI P3_Low
    @ADDI Carry          # All 3 Carries added
    @ADDI P3_Low
    @POPI P3_Low         # IF there should be another carry here, that could be capture for 128bit math? Naaa

    @PRT "     # Step Add P2_High + P3_Low + Carry"
    @PRT "Result = " @PRTHEXI P3_Low @PRTNL

    @MV2V P3_Low OVF32   # global register
    @MV2V Carry OVF32+2  # High part of overflow.

    # ---- Return result ----
    @PUSHI Sum_Low
    @PUSHI Sum_High
    @RestoreVar 15
    @RestoreVar 14
    @RestoreVar 13
    @RestoreVar 12
    @RestoreVar 11
    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

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
:MUL16x32U
@PUSHRETURN
    @LocalVar A16       01
    @LocalVar B16       02
    @LocalVar R_Low     03
    @LocalVar R_High    04
    @LocalVar Bit       05

    # --- Pop inputs ---
    @POPI B16
    @POPI A16

    # --- Initialize result to 0 ---
    @MA2V 0 R_Low
    @MA2V 0 R_High

    # --- For each bit in B16 ---
    @ForIA2B Bit 0 16
        # Test current bit of B16
        @PUSHI B16
        @AND 1
        @IF_NOTZERO
           # Add current A16 to low word
           @PUSHI R_Low
           @ADDI A16
           @POPI R_Low
           @IF_CARRY
              @INCI R_High
           @ENDIF
        @ENDIF
        @POPNULL        
        # Shift 32 bit accumulator left 1 bit
        @PUSHI R_High @SHL @POPI R_High

        # Shift A16 left by 1
        @PUSHI A16   @SHL   @POPI A16
        # Shift B16 right by 1
        @PUSHI B16   @SHR   @POPI B16

    @Next Bit

    # --- Push result (low, then high) ---
    @PUSHI R_Low
    @PUSHI R_High

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

# ===========================================================
# Function : ADD16U
# Purpose  : Add two unsigned 16-bit values, return result + carry word
# Inputs   : [ ... A16 B16 ]
# Outputs  : [ ... R_Low Carry ]
# Notes    :
#   - Carry is returned as full word 0x0000 or 0x0001
#   - Does not affect Flags32
# ===========================================================
:ADD16U
@PUSHRETURN
    @LocalVar A16    01
    @LocalVar B16    02
    @LocalVar R16    03
    @LocalVar Carry  04

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

    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


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

:SHL16x32
@PUSHRETURN
    @LocalVar ShiftCount 01
    @LocalVar Value 02
    @LocalVar PR_Low 03
    @LocalVar PR_High 04
    @LocalVar Index 05
    

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

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

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
:SHR16x32
@PUSHRETURN
    @LocalVar ShiftCount 01
    @LocalVar Value      02
    @LocalVar R_Low      03
    @LocalVar R_High     04
    @LocalVar Index      05

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

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


# ===========================================================
# Purpose  : Multiplytwo 32-bit signed values on the stack (little-endian)
# Inputs   : [ ... A32_Low A32_High B32_Low B32_High ]
# Outputs  : [ ... R32_Low R32_High ]
# Notes    :
#   - Carry out beyond 32 bits is discarded.
#   - Ideal for mantissa math and temporary sums.
# ===========================================================
:MUL32S
@PUSHRETURN
    @LocalVar A_Low 01
    @LocalVar A_High 02
    @LocalVar B_Low 03
    @LocalVar B_High 04
    @LocalVar SignA 05
    @LocalVar SignB 06
    @LocalVar R_Low 07
    @LocalVar R_High 08

    # Pop inputs (stack: [ ... A_Low A_High B_Low B_High ])
    @POPI B_High
    @POPI B_Low
    @POPI A_High
    @POPI A_Low

    # Determine signs (1 if negative)
    @PUSHI A_High
    @AND 0x8000
    @POPNULL   
    @IF_NOTZF
       @PUSH 1
    @ELSE
       @PUSH 0
    @ENDIF
    @POPI SignA


    @PUSHI B_High
    @AND 0x8000
    @POPNULL   
    @IF_NOTZF
       @PUSH 1
    @ELSE
       @PUSH 0
    @ENDIF
    @POPI SignB

    # If negative, negate to get absolute value

    @IF_EQ_AV 1 SignA
        @PUSHI A_Low
        @PUSHI A_High
        @CALL COMP232S
        @POPI A_High
        @POPI A_Low
    @ENDIF

    @IF_EQ_AV 1 SignB
        @PUSHI B_Low
        @PUSHI B_High
        @CALL COMP232S
        @POPI B_High
        @POPI B_Low
    @ENDIF

    # Multiply absolute values
    @Call32(vv) MUL32US A_Low B_Low
    @POPI R_High
    @POPI R_Low

    # If signs differ, negate result
    @PUSHI SignA
    @PUSHI SignB
    @XORS
    @IF_NOTZERO
        @Call32(v) COMP232S R_Low
        @POP32I(v) R_Low
    @ENDIF
    @POPNULL
    
    # Push final result
    @PUSHI R_Low
    @PUSHI R_High

    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
# ===========================================================
# Function : DIV32U
# Purpose  : Unsigned 32-bit divide (Dividend ÷ Divisor)
# Inputs   : [ ... A_Low A_High B_Low B_High ]
# Outputs  : [ ... Quotient_Low Quotient_High Remainder_Low Remainder_High ]
# Notes    :
#   - Performs full 32/32-bit unsigned integer division
#   - Uses bitwise restoring division method
#   - Division by zero sets OVF32=1 and returns 0 quotient/remainder
#   - Result truncated to 32 bits; remainder < divisor
# ===========================================================

:DIV32U
@PUSHRETURN
    @LocalVar Dividend_Low 01
    @LocalVar Dividend_High 02
    @LocalVar Divisor_Low 03
    @LocalVar Divisor_High 04
    @LocalVar Quot_Low 05
    @LocalVar Quot_High 06
    @LocalVar Rem_Low 07
    @LocalVar Rem_High 08
    @LocalVar BitIndex 09
    @LocalVar TmpL 10
    @LocalVar TmpH 11

    # --- Pop inputs ---
    @POPI Divisor_High
    @POPI Divisor_Low
    @POPI Dividend_High
    @POPI Dividend_Low

    # --- Check for divide by zero ---
    @PUSHI Divisor_Low
    @Call(v)  OR32S Divisor_High
    @POP32I(v) Divisor_High
    @Call(vv) CMP32S Divisor_High ZERO32
    @IF_ZFLAG
        @MA2V 0 Quot_Low
        @MA2V 0 Quot_High
        @MA2V 0 Rem_Low
        @MA2V 0 Rem_High
        @MA2V 1 OVF32        # set divide-by-zero flag
        @JMP Div32U_Exit
    @ENDIF
    @MA2V 0 OVF32

    # --- Clear result registers ---
    @MA2V 0 Quot_Low
    @MA2V 0 Quot_High
    @MA2V 0 Rem_Low
    @MA2V 0 Rem_High

    # --- 32-bit loop: shift & subtract ---
    @ForIA2B BitIndex 0 32
        # Shift Left (Remainder:Dividend) by 1 bit
        @PUSHI Rem_Low
        @PUSHI Rem_High
        @PUSH 1             # 1 bit shift
        @CALL SHL32
        @POPI Rem_High
        @POPI Rem_Low

        @PUSHI Dividend_Low
        @PUSHI Dividend_High
        @PUSH 1              # 1 bit shift
        @CALL SHL32
        @POPI Dividend_High
        @POPI Dividend_Low

        # Merge top bit of Dividend_High into Rem_Low (simulate 64-bit shift)
        @PUSHI Rem_Low
        @PUSHI Dividend_High
        @SHL
        @POPI Rem_Low

        # Try subtracting divisor
        @PUSHI Rem_Low
        @PUSHI Rem_High
        @PUSHI Divisor_Low
        @PUSHI Divisor_High
        @CALL SUB32S
        @POPI TmpH
        @POPI TmpL

        # If Rem >= Divisor (no borrow)
        @PUSHI Flags32
        @AND C32Flag
        @CMP 0
        @POPNULL
        @IF_NOTZF
            # Successful subtract → update remainder
            @MV2V TmpL Rem_Low
            @MV2V TmpH Rem_High

            # Set quotient bit
            @PUSHI Quot_Low
            @PUSHI Quot_High
            @PUSHI BitIndex
            @CALL SetBit32          # (we’ll define this tiny helper below)
            @POPI Quot_High
            @POPI Quot_Low
        @ENDIF
    @Next BitIndex

:Div32U_Exit
    # --- Push outputs ---
    @PUSHI Quot_Low
    @PUSHI Quot_High
    @PUSHI Rem_Low
    @PUSHI Rem_High

    @RestoreVar 11
    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
# ===========================================================
# Function : SetBit32
# Purpose  : Sets bit N in 32-bit value (Quotient |= 1<<N)
# Inputs   : [ ... Value_Low Value_High BitIndex ]
# Outputs  : [ ... NewLow NewHigh ]
# ===========================================================
:SetBit32
@PUSHRETURN
    @LocalVar ValL 01
    @LocalVar ValH 02
    @LocalVar Bit  03
    @LocalVar BitMask_L 04
    @LocalVar BitMask_H 05

    @POPI Bit
    @POPI ValH
    @POPI ValL

    @PUSHI Bit
    @IF_ULT_A 16
        @POPNULL
        @PUSH 1
        @PUSHI Bit
        @CALL SHL16x32
        @POPI BitMask_H
        @POPI BitMask_L
        @PUSHI ValL
        @ORI BitMask_L
        @POPI ValL
    @ELSE
        @POPNULL
        @SUBI Bit 16
        @PUSH 1
        @PUSHI Bit
        @CALL SHL16x32
        @POPI BitMask_H
        @POPI BitMask_L
        @PUSHI ValH
        @ORI BitMask_L
        @POPI ValH
    @ENDIF

    @PUSHI ValL
    @PUSHI ValH

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


@SIZESINCE
ENDBLOCK
