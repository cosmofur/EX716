I common.mc
# Psudo Code
# Input N
# A,B,OUT,Idx = 0,1,0,2
# while (Idx < N)
#    OUT=A+B
#    A=B
#    B=OUT
#    Idx ++
#    Print OUT
@PRTLN "Fibonacci Series"
@MC2M 0 A
@MC2M 1 B
@MC2M 0 OUT
@MC2M 2 Idx
@PRT "Number of Terms: "
@READI N
@PRTNL
@PRTLN "The Fibonacci Series is:"
@PRTI A @PRTSP @PRTI B @PRTSP      # Print ## ## \n
:MainLoop
# WHILE Idx < N
@PUSHI N
@CMPI Idx      # Subtract N from Idx and N flag set if N is > Idx
@POPNULL
@JMPN EndofLoop
     @PUSHI A  @PUSHI B   @ADDS    @POPI OUT    #  OUT=A+B
     @MM2M B A    #  A=B
     @MM2M OUT B  #  B=OUT
     @INCI Idx    #  Idx++
     @PRTI OUT   #  Print OUT
     @PRTSP
     @JMP MainLoop
:EndofLoop
@PRTNL
@END
# Setup Storage
:A 0
:B 0
:N 0
:Idx 0
:OUT 0
