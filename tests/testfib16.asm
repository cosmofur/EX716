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
@MA2V 0 Aval
@MA2V 1 Bval
@MA2V 0 OUT
@MA2V 2 Idx
@PRT "Number of Terms: "
@READI Nval
@DECI Nval
@PRTNL
@PRT "The Fibonacci Series is: "
@PRTI Aval @PRTSP @PRTI Bval @PRTSP      # Print ## ## \n
:MainLoop
# WHILE Idx < N
@PUSHI Idx
@CMPI Nval
@POPNULL
@JMPN EndofLoop
     @PUSHI Aval  @PUSHI Bval   @ADDS    @POPI OUT    #  OUT=A+B
     @MV2V Bval Aval    #  A=B
     @MV2V OUT Bval  #  B=OUT
     @INCI Idx    #  Idx++
     @PRTI OUT   #  Print OUT
     @PRTSP
     @JMP MainLoop
:EndofLoop
@PRTNL
@END
# Setup Storage
:Aval 0
:Bval 0
:Nval 0
:Idx 0
:OUT 0
