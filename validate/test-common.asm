I common.mc
# Setup some storage.
:Var1 0
:Var2 0
:Ref1 $Var1
:Ref2 $Var2
:Main . Main
@NOP
@PUSH 101
@DUP
@PUSHI Var1
@PUSHII Ref1
@PUSH Var2 @PUSHS
@POPNULL @POPNULL @POPNULL
    @PUSH 101 @PUSH 202
@SWP
@POPI Var1
@POPII Ref1
   @PUSH 303 @PUSH Var2
@POPS
   @PUSH 100
@CMP 50
@CMP 100
@CMP 150
  @POPNULL
  @PUSH 0x8000
@CMP 0x8001    # Should cause Overflow
  @PUSH 50
@CMPS
  @POPNULL @PUSH 100
@CMPS
  @POPNULL @PUSH 150
@CMPS
   @PUSH 50 @POPI Var1
@CMPI Var1
   @PUSH 100 @POPI Var1
@CMPI Var1
   @PUSH 150 @POPI Var1
@CMPI Var1
   @PUSH 50 @POPI Var1
@CMPII Ref1
   @PUSH 100 @POPI Var1
@CMPII Ref1
   @PUSH 150 @POPI Var1
@CMPII Ref1
   @POPNULL
   @PUSH 90
@ADD 10
   @POPNULL
   @PUSH 80
   @PUSH 20 @POPI Var1
@ADDI Var1
   @POPNULL
   @PUSH 70 @POPI Var1
@ADDII Ref1
   @POPNULL
   @PUSH 15 @PUSH 45
@ADDS
   @POPNULL
   @PUSH 90   
@SUB 10
   @POPNULL
   @PUSH 80
   @PUSH 20 @POPI Var1
@SUBI Var1
   @POPNULL
   @PUSH 70 @POPI Var1
@SUBII Ref1
   @POPNULL
   @PUSH 15 @PUSH 45
@SUBS
   @POPNULL
   @PUSH 90
@OR 10
   @POPNULL
   @PUSH 80
   @PUSH 20 @POPI Var1
@ORI Var1
   @POPNULL
   @PUSH 70 @POPI Var1
@ORII Ref1
   @POPNULL
   @PUSH 15 @PUSH 45
@ORS
   @POPNULL   
   @PUSH 90
@AND 10
   @POPNULL
   @PUSH 80
   @PUSH 20 @POPI Var1
@ANDI Var1
   @POPNULL
   @PUSH 70 @POPI Var1
@ANDII Ref1
   @PUSH 15 @PUSH 45
@ANDS
   @POPNULL
   @FCLR
   @PUSH 100 @SUB 100 @POPNULL
@JMPZ NextTest1
   @END
:NextTest1
   @FCLR
   @PUSH 100 @SUB 150 @POPNULL
@JMPN NextTest2
   @END
:NextTest2
   @FCLR
   @PUSH 0xffff @ADD 1 @POPNULL
@JMPC NextTest3
   @END
:NextTest3
   @FCLR
   @PUSH 0x8000 @SUB 0x8001 @POPNULL
@JMPO NextTest4
   @END
:NextTest4
   @PUSH Forward @POPI Var1
@JMPI Var1
   @END
:Forward
   @FCLR
   @PUSH 0x2222
@RTR
@RTR
@RTR
@RTR
   @POPNULL
   @FCLR
   @PUSH 0x4444
@RTL
@RTL
@RTL
@RTL
   @POPNULL
   @FCLR
   @PUSH 0x1111
@RRTC
@RRTC
@RRTC
@RRTC
@RRTC
@RRTC
@RRTC
@RRTC
    @POPNULL
    @FCLR
    @PUSH 0x1111
@RLTC
@RLTC
@RLTC
@RLTC
@RLTC
@RLTC
@RLTC
@RLTC
    @POPNULL
    @FCLR
    @PUSH 0xFF00
@INV
@INV
@INV
@INV
    @POPNULL
    @PUSH -100
@COMP2
@COMP2
@ForIA2B Var1  -10 10
  @ABSI Var1
  @PRTTOP @PRTSP
@Next Var1
    @PRTLN "Successfull End"
    @END
    
