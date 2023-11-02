I common.mc
L lmath.ld
# Psudo Code
# Input N
# A,B,OUT,Idx = 0,1,0,2
# while (Idx < N)
#    OUT=A+B
#    A=B
#    B=OUT
#    Idx ++
#    Print OUT
:Main . Main
@PRTLN "Fibonacci Series"
@MOVE32AV $$$0 Aval
@MOVE32AV $$$1 Bval
@MOVE32AV $$$0 OUT
@PRT "Number of Terms: "
@READI Nval
@PRTNL
:MainLoop
# WHILE Idx < N
@PUSH Nval
@ForIA2V Idx 0  Nval
     @PUSH Aval @PUSH Bval @PUSH OUT @CALL ADD32
     @COPY32VV Bval Aval # A=B
     @COPY32VV OUT Bval  # B=OUT     
     @PRT32I OUT   #  Print OUT
     @PRTSP
@Next Idx
:EndofLoop
@PRTNL
@END
# Setup Storage
:Aval 0 0 
:Bval 0 0
:Nval 0
:Idx 0
:OUT 0 0
