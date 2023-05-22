# Input: Stack RET, NUM DENOM (Reminder NUM is the larger number being divided by the smaller DENOM) 
# Requires common.mc
! DEFINEDDIV
M DEFINEDDIV 0
G DIVU G DIV
@JMP DIVINIT
:DIVU
@POPI RETURN
@POPI B_VAL
@POPI A_VAL
@PUSHI B_VAL
@IF_ZERO
   @PRTLN "Divide by Zero error:"
   @PUSH 0 @PUSH 0
   @PUSHI RETURN
   @RET
@ENDIF
@POPNULL
@MA2V 0 QVal
@MA2V 0 Remainder
@MA2V 0x8000 MASK   # For the ith bit tests MASK will be bit at ith location of 16 bits
@ForIA2B Index 0 16
    @PUSHI Remainder @RTL @POPI Remainder        # Remainder << 1
    @PUSHI MASK @PUSHI A_VAL @ANDS
    @IF_NOTZERO
       @POPNULL
       @PUSH 1
       @PUSHI Remainder
       @ORS
       @POPI Remainder        # Remainder[16-i]=A_VAL[16-i]
    @ELSE
       @POPNULL
    @ENDIF
    @PUSHI Remainder @PUSHI B_VAL
    @IF_GE_S
       @POPNULL @POPNULL
       @PUSHI Remainder @PUSHI B_VAL @SUBS @POPI Remainder
       @PUSHI QVal @PUSHI MASK @ORS @POPI QVal
    @ELSE
       @POPNULL @POPNULL
    @ENDIF
    @PUSHI MASK @RTR @POPI MASK  # Shift Mask to next bit from left to right
@Next Index
@PUSHI Remainder
@PUSHI QVal
@PUSHI RETURN
@RET
:RETURN 0
:RETURN2 0
:A_VAL 0
:B_VAL 0
:QVal 0
:Remainder 0
:MASK 0
:Index 0
:SIGN 0
#
# Now handle case for Signed DIV
:DIV
@POPI RETURN2
@POPI B_VAL
@POPI A_VAL
@MA2V 0 SIGN
@PUSH 0
@PUSHI A_VAL
@IF_GT_S
   @PUSHI SIGN @INV @POPI SIGN
   @PUSHI A_VAL @COMP2 @POPI A_VAL
@ENDIF
@POPNULL
@PUSHI B_VAL
@IF_GT_S
   @PUSHI SIGN @INV @POPI SIGN
   @PUSHI B_VAL @COMP2 @POPI B_VAL
@ENDIF
@IF_EQ_S
   # IF they are equal, save time and just return '1'
   @POPNULL @POPNULL
   @PUSH 0 @PUSH 1
   @PUSHI RETURN2
   @RET
@ENDIF
@POPNULL @POPNULL
@PUSHI A_VAL @PUSHI B_VAL
@CALL DIVU
@POPI A_VAL
@POPI B_VAL
@PUSHI SIGN
@IF_NOTZERO
   @PUSHI A_VAL @COMP2 @POPI A_VAL
@ENDIF
@POPNULL
@PUSHI B_VAL
@PUSHI A_VAL
@PUSHI RETURN2
@RET
:DIVINIT
ENDBLOCK

