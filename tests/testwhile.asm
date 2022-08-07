#
I common.mc
# This experiment demostrates diffrent types of loops.
#
#
# While
#
# This Loop will repeat while VarX < VarY
#
@MC2M 10 VarY
@MC2M 0 VarX
@PRTLN "Start of While Loop"
:WhileTop
   @PUSHI VarY
   @CMPI VarX    # Set Flags as VarX - VarY
   @POPNULL
   @JMPN WhileEnd
   @JMPZ WhileEnd
      # While Body start
      @INCI VarX
      # While Body end
   @JMP WhileTop
:WhileEnd
@PRTLN "End of While Loop"
#
#
# Until Loop Repeat until VarX > VarY
@MC2M 10 VarY
@MC2M 0 VarX
@PRTLN "Start Of Until Loop"
:UntilTop
   #Until Body Start
   @INCI VarX
   #Until Body End
   @PUSHI VarY
   @CMPI VarX    # Flags as if VarX - VarY
   @POPNULL
   @JMPZ UntilTop    # We want VarX > VarY NOT VarX == VarY
   @JMPN UntilTop    # When VarX < VarY N-flag will be set.
# End of Until Loop
@PRTLN "End Of Until Loop"
#
#
# Case like statement
# We can get something like a case statement by using an array
# That is filled with the addresses of our target cases.
#
# Set VarX to value of case we care about...must fall in range of the array
#
@MC2M 5 VarX
# Values are Words not bytes, so multiply VarX by two
@PUSHI VarX @RTL @POPI VarX
#
@PUSH CaseArray        # Note we need a pointer to the Address of Array not its value
@ADDI VarX
@PUSHS
@POPI VarY             # VarY now has value stored at Array[VarX]
#
@JMPI VarY
#
# Start of Case functions
:Case0
   @PRTLN "Case Zero"
   @JMP EndCase
:Case1
   @PRTLN "Case One"
   @JMP EndCase
:Case2
   @PRTLN "Case two"
   @JMP EndCase
:Case3
   @PRTLN "Case three"
   @JMP EndCase
:Case4
   @PRTLN "Case four"
   @JMP EndCase
:Case5
   @PRTLN "Case five"
   @JMP EndCase
:Case6
   @PRTLN "Case six"
   @JMP EndCase
:Case7
   @PRTLN "Case seven"
   @JMP EndCase
:Case8
   @PRTLN "Case eight"
   @JMP EndCase
@PRTLN "Default Case"
@JMP EndCase
# While we could save this array in some distant data memory
# There should be no logical way for the program code to reach
# this address, so its a good place to put the variables.
#
# Data
:VarX 0
:VarY 0
:CaseArray Case0 Case1 Case2 Case3 Case4 Case5 Case6 Case7 Case8
#
#
:EndCase
@PRTLN "End of Case"
@PRTLN "End of examples."
@END




   
