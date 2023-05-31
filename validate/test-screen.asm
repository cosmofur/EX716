I common.mc
L screen.ld
L random.ld
:Main . Main
#@CALL WinInit
@CALL WinClear
@CALL WinHideCursor
@PUSH 100
@CALL rndint
@PUSH 20 @PUSH 30 @CALL WinCursor
@STRSET "Hello World" StrPtr1
@PRTS StrPtr1
:Break1

@PUSHI WinWidth @RTR @DUP @RTR @POPI WCornerX
@ADDI WCornerX @POPI ECornerX
@PUSHI WinHeight @RTR @DUP @RTR @POPI NCornerY
@ADDI NCornerY @POPI SCornerY

@PUSHI WCornerX @PUSHI NCornerY @PUSHI ECornerX @PUSHI NCornerY @PUSH XICON @CALL WinPlot
@PUSHI ECornerX @PUSHI NCornerY @PUSHI ECornerX @PUSHI SCornerY @PUSH XICON @CALL WinPlot
@PUSHI ECornerX @PUSHI SCornerY @PUSHI WCornerX @PUSHI SCornerY @PUSH XICON @CALL WinPlot
@PUSHI WCornerX @PUSHI SCornerY @PUSHI WCornerX @PUSHI NCornerY @PUSH XICON @CALL WinPlot
@PUSHI WCornerX @PUSHI NCornerY @PUSHI ECornerX @PUSHI SCornerY @PUSH XICON @CALL WinPlot
@PUSHI ECornerX @PUSHI NCornerY @PUSHI WCornerX @PUSHI SCornerY @PUSH XICON @CALL WinPlot
@PUSH 0 @PUSH 0 @CALL WinCursor

@PUSHI WinWidth
@RTR
@POPI BallX
@PUSHI WinHeight
@RTR
@POPI BallY
@MV2V BallX OldBallX
@MV2V BallY OldBallY
@MA2V 0 Direction 
@CALL SetDirection
@ForIA2B Index 0 2000
  @PUSH 3 @PUSH 1 @CALL WinCursor @PRTI Index @PRTSP @PRTI BallX @PRT ":" @PRTI BallY @PRTSP @PRTI Direction
  @PUSHI OldBallX @PUSHI OldBallY @CALL WinCursor @PRTS SPACEICON
  @PUSHI BallX  @ADDI BDX  @POPI BallX
  @PUSHI BallY  @ADDI BDY  @POPI BallY
  @PUSHI BallX
  @IF_GE_V WinWidth
    @PUSH 8 @CALL rndint @POPI Direction
    @CALL SetDirection
    @MV2V OldBallX BallX
  @ENDIF
  @IF_LT_A 1   
    @PUSH 8 @CALL rndint @POPI Direction
    @CALL SetDirection
    @MV2V OldBallX BallX
  @ENDIF
  @POPNULL
  @PUSHI BallY
  @IF_GE_V WinHeight
    @PUSH 8 @CALL rndint @POPI Direction    
    @CALL SetDirection
    @MV2V OldBallY BallY
  @ENDIF
  @IF_LT_A 1
    @PUSH 8 @CALL rndint @POPI Direction    
    @CALL SetDirection
    @MV2V OldBallY BallY
  @ENDIF
  @POPNULL
  @PUSHI BallX @PUSHI BallY @CALL WinCursor @PRTS XICON
  @MV2V BallX OldBallX
  @MV2V BallY OldBallY	
@Next Index
@CALL WinShowCursor
@END

:SetDirection
@PUSHI Direction
@AND 0b111
@SWITCH
   @CASE 0
      # North 
      @MA2V -1 BDY
      @MA2V  0 BDX
      @CBREAK
   @CASE 1
      # NE
      @MA2V -1 BDY
      @MA2V  1 BDX   
      @CBREAK
   @CASE 2
      # East
      @MA2V  0 BDY
      @MA2V  1 BDX   
      @CBREAK
   @CASE 3
      # SE
      @MA2V  1 BDY
      @MA2V  1 BDX   
      @CBREAK
   @CASE 4
      # South
      @MA2V 1 BDY
      @MA2V 0 BDX   
      @CBREAK
   @CASE 5
      # SW
      @MA2V  1 BDY
      @MA2V -1 BDX   
      @CBREAK      
   @CASE 6
      # West
      @MA2V  0 BDY
      @MA2V -1 BDX   
      @CBREAK      
   @CASE 7
      # NW
      @MA2V -1 BDY
      @MA2V -1 BDX   
      @CBREAK
   @CDEFAULT
      @MA2V 0 Direction
      @CBREAK
@ENDCASE
@POPI Direction
@RET
   
:StrPtr1 "--------------------------------------------------------"
:Index 0
:BallX 0
:BallY 0
:BDX 0
:BDY 0
:OldBallX 0
:OldBallY 0
:Direction 0
:XICON "X" b0
:SPACEICON " " b0
:WCornerX 0
:NCornerY 0
:ECornerX 0
:SCornerY 0
