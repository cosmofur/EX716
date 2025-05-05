# Input: Stack RET, NUM DENOM (Reminder NUM is the larger number being divided by the smaller DENOM) 
# Requires common.mc
! DEFINEDDIV
M DEFINEDDIV 0
# Define Local storage (Registers)
I common.mc
L softstack.ld
G DIVU G DIV
@JMP DIVINIT
# Function DIVU unsigned Divide.
:DIVU
# Local Variable Names
=B_VAL Var01
=A_VAL Var02
=QVal Var03
=Remainder Var04
=MASK Var05
=Index Var06
#
@PUSHRETURN
@PUSHLOCALI A_VAL
@PUSHLOCALI B_VAL
@PUSHLOCALI QVal
@PUSHLOCALI Remainder
@PUSHLOCALI MASK
#
@POPI B_VAL
@POPI A_VAL
@PUSHI B_VAL
@IF_ZERO
   @PRTLN "Divide by Zero error:"
   @JMP DIVUEXIT

@ENDIF
@POPNULL
@MA2V 0 QVal
@MA2V 0 Remainder
@MA2V 0x8000 MASK   # For the ith bit tests MASK will be bit at ith location of 16 bits
@ForIA2B Index 0 16
    @PUSHI Remainder @SHL @POPI Remainder        # Remainder << 1
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
    @PUSHI MASK @SHR @POPI MASK  # Shift Mask to next bit from left to right
@Next Index
@PUSHI Remainder
@PUSHI QVal

:DIVUEXIT
@POPLOCAL MASK
@POPLOCAL Remainder
@POPLOCAL QVal
@POPLOCAL B_VAL
@POPLOCAL A_VAL
@POPRETURN
@RET
#
# Function DIV, this version knows about Signs, but uses the DIVU version to do the main work.
:DIV
# Define local names
=A_VAL Var01
=B_VAL Var02
=SIGN Var03
#
@PUSHRETURN
@PUSHLOCALI A_VAL
@PUSHLOCALI B_VAL
@PUSHLOCALI SIGN
#
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
   @JMP DIVEXIT
@ENDIF
@POPNULL @POPNULL
@PUSHI A_VAL @PUSHI B_VAL
@CALL DIVU
@POPI A_VAL
@POPI B_VAL
@PUSHI SIGN
@IF_NOTZERO
   @PUSHI A_VAL @COMP2 @POPI A_VAL   # If Signed use 2s compliment
@ENDIF
@POPNULL
@PUSHI B_VAL
@PUSHI A_VAL
:DIVEXIT
@POPLOCAL SIGN
@POPLOCAL B_VAL
@POPLOCAL A_VAL
@POPRETURN
@RET
:DIVINIT
ENDBLOCK
