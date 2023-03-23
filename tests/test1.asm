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
@MC2M 0 A
@MC2M 1 B
@MC2M 0 OUT
@MC2M 2 Idx
@PROMPT "Number of Terms: " N
@PRTLN "The Fabonacci Series is: "
@PUSH Idx
@WHILE_NOTZERO
   @POPNULL
   @PUSHI A @ADDI B @POPI OUT   # OUT=A+B
   @MM2M B A                    # A=B
   @MM2M OUT B                  # B=OUR
   @INCI Idx                    # Idx++
   @PRTI OUT @PRTNL
   @PUSHI N                     # If Idx > N Push 1 else Push 0
   @PUSHI Idx
   @IF_LT_S
      @POPNULL @POPNULL
      @PUSH 1
   @ELSE
      @POPNULL @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@END
:A 0
:B 0
:OUT 0
:Idx 0
:N 0
G A G B G OUT G Idx G N


