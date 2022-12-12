# Input: Stack RET, Divident, Divisor
# Requires common.mc
! DEFINEDDIV
M DEFINEDDIV 0
@JMP DIVINIT
G DIV
:DIV
@POPI RETURN
@POPI Denominator
@POPI Numerator        # Is also known as Dividend
# Test for divide by zero
@PUSH 0 @CMPI Denominator @POPNULL
@JMPZ DivideByZero
# Test for sign
@MC2M 0 NEGFLAG
# Test for Negative Numbers and set NEGFLAG if just one is negative. 
@PUSH 0 @CMPI Numerator @POPNULL
@JMPN ISNEG1
@JMP NOTNEG1
:ISNEG1
# Invert Negflag
   @PUSHI NEGFLAG @INV @POPI NEGFLAG
   # Do Abs(Numerator)
   @PUSHI Numerator @INV @ADD 1 @POPI Numerator
:NOTNEG1
# Now for Denominator
@PUSH 0 @CMPI Denominator @POPNULL
@JMPN ISNEG2
@JMP NOTNEG2
:ISNEG2
# Invert NegFlag
   @PUSHI NEGFLAG @INV @POPI NEGFLAG
   # Do Abs(Denominator)
   @PUSHI Denominator @INV @ADD 1 @POPI Denominator
:NOTNEG2
@MC2M 0 QVal
@MC2M 0 Remainder
@MC2M 0x8000 ReverseBit
@MC2M 16 Index
:MainLoop
@PUSHI Index @CMP 0 @POPNULL
@JMPZ ExitMainLoop
    @PUSHI Remainder @RTL @POPI Remainder    # R = R << 1
    @PUSHI Numerator @ANDI ReverseBit        # Set True if Ith bit is on.
    @CMP 0 @POPNULL         # If Ith bit is off.
    @JMPZ BitNotSet
    #Here Bit is set
      @PUSH 1
      @ORI Remainder         # Set the low bit to one
      @POPI Remainder
    :BitNotSet
    @PUSHI Denominator      # if R >= D
    @CMPI Remainder         # logic is based on B - A. So Nflag set if A > B bit not set if R >= D
    @POPNULL
    @JMPN SkipQSet
       @PUSHI Denominator @SUBI Remainder @POPI Remainder  # R = R - D
       # We need to modify just the Ith bit of Qval to be a 1
       @PUSH 0xFFFF
       @ANDI ReverseBit          # QVal(indexbit) = 1
       @ADDI QVal
       @POPI QVal
    :SkipQSet
    @PUSHI ReverseBit @RTR @POPI ReverseBit   # ReverseBit >> 1
    @DECI Index
    @JMP MainLoop
:ExitMainLoop
@PUSHI NEGFLAG
@CMP 0
@POPNULL
@JMPZ NotNeg
   @PUSHI QVal
   @COMP2
   @POPI QVal
:NotNeg
@PUSHI Remainder
@PUSHI QVal
@PUSHI RETURN
@RET
:DivideByZero
@PRTLN "Divide By Zero"
@PUSH 0 @PUSH 0
@PUSHI RETURN
@RET
:RETURN 0
:Numerator 0
:Denominator 0
:NEGFLAG 0
:ReverseBit 0
:Index 0
:QVal 0
:Remainder 0
:DIVINIT
ENDBLOCK
