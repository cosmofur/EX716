:IsMultiple3
@POPI IMReturn
@CALL absint    # only care if possitive
@PUSHI TestN

# Handle the simple 0 and 1 cases.
@PUSH 0
@IF_EQ_S             # If TestN == 0
   @POPNULL @POPNULL
   @PUSH 1
   @PUSHI IMReturn
   @RET
@ENDIF
@POPNULL
@PUSH 1
@IF_EQ_S             # If TestN == 1
   @POPNULL @POPNULL
   @PUSH 0
   @PUSHI IMReturn
   @RET
@ENDIF
@POPNULL @POPNULL
@MC2M 0 Odd_Count    # Odd_Count = Even_Count = 0
@MC2M 0 Even_Count
@PUSHI TestN
@WHILE_NOTZERO      # While TestN != 0, Do
   @DUP
   @AND 0x1
   @IF_NOTZERO      # IF RightMost bit is set
      @INCI Odd_Count
   @ENDIF
   @POPNULL
   @RTR             # TOS is TestN again, so Rotate Right
   @DUP             # Repeating same test, but this time for Even_Count
   @AND 0x1
   @IF_NOTZERO      # If RightMost bit is still set
      @INCI Even_Count
   @ENDIF
   @POPNULL
   @RTR             # TOS is TestN again, Leave for While Loop Test
@ENDWHILE
@POPNULL
@PUSHI Odd_Count
@PUSHI Even_Count
@SUBS
@CALL absint
@PUSHI IMReturn
@RET
:IMReturn 0
:Odd_Count 0
:Even_Count 0
:TestN 0
#
# Local Utility function (Since i don't wan't to pull in a full math library)
# absint(n): int
:absint
@SWP             # When there only one possible argument, save return on stack with a SWP
@DUP
@AND 0x8000
@IF_NOTZERO
   @POPNULL
   @COMP2
@ELSE
   @POPNULL
@ENDIF
@SWP
@RET
# MAIN
:main
. main
@ForIA2B Index 3 100
   @PUSHI Index
   @PRT "Can N: " @PRTI Index @PRT " Be divided by 3:"
   @CALL IsMultiple3
   @POPI Result
   @PRTSGNI Result @PRTNL
@Next Index
@END
:Index 0
:Result 0
