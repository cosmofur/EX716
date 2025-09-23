I common.mc
L random.ld
L mul.ld
=SIZE 10000
:Index 0
:Index2 0
:Index3 0
:StartTime 0
:EndTime 0
:RndTable
. RndTable+200
:Main . Main
   # Fill Random Table with 100 values
   @PRT "Filling Random Table\n"
   @GETTIME
   @POPNULL   
   @CALL rndsetseed
   @ForIA2B Index 0 100
      @PUSH 0
      @WHILE_ZERO
        @POPNULL
        @CALL frnd16 @AND 0xfe
      @ENDWHILE
      @PUSHI Index @SHL @ADD RndTable
      @POPS
   @Next Index
   @GETTIME
   @POPNULL      
   @POPI StartTime
   @PRT "Running " @PRTREF SIZE @PRT " Operations\n"
   @PRT "Start:\n"
   @MA2V 100 Index2
   @ForIA2B Index3 0 SIZE
      @PUSHI Index @SHL @ADD RndTable @PUSHS
      @PUSHI Index2 @SHL @ADD RndTable @PUSHS
#      @CALL DIVU
#      @CALL frndint
       @SHL
      @POPNULL @POPNULL
       
      @IF_EQ_AV 100 Index
         @MA2V 0 Index
         @MA2V 100 Index2
      @ENDIF
   @Next Index3
   @PRT "End:\nSeconds:"
   @GETTIME
   @POPNULL
   @POPI EndTime
   @PUSH SIZE   
   @PUSHI EndTime @SUBI StartTime
   @PRTTOP    @PRTNL
:Break01   
   @CALL DIVU
   @PRT "Ops Per Second:" @PRTTOP @POPNULL @POPNULL @PRTNL
@END

      
      
