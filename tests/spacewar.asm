#
#   
#   <~=~>  <^=^>  <v=v>   <~=^>  <^=~>  <~=v> <v=~> <<=~>  <~=>>
#
#
#
I common.mc
L screen.ld
L random.ld
L string.ld

:ShipDrift "<~=~>\0"   # 0
:ShipN     "<^=^>\0"   # 1
:ShipNE    "<^=~>\0"   # 2
:ShipE     "<<=~>\0"   # 3
:ShipSE    "<v=~>\0"   # 4
:ShipS     "<v=v>\0"   # 5
:ShipSW    "<~=v>\0"   # 6
:ShipW     "<~=>>\0"   # 7
:ShipNW    "<~=^>\0"   # 8
:ShipSpace "     \0"   # 9
:SHIPX 0
:SHIPY 0
:CHIN 0
:StrPtr 0
:Direction 0
:LoopState 0
:Index1 0
:Index2 0
:DirDelta 0
:NegWidth 0
:NegHeight 0
:DirXDelta 0
:DirYDelta 0
=MaxStars 5
:Stars
0 0
0 0
0 0
0 0
0 0

:DrawShip
@PUSHRETURN
@PUSHI SHIPX
@PUSHI SHIPY
@CALL WinCursor
@PRT "     "
@PUSHI SHIPX
@PUSHI SHIPY
@CALL WinCursor
@PUSHI Direction @SHL @SHL @SUBI Direction
@ADD ShipDrift
@POPI StrPtr
@PRTSI StrPtr
@POPRETURN
@RET


:DrawStars
@PUSHRETURN
#@DEBUGTOGGLE
@PUSHI Direction
@SWITCH
   @CASE 0
     @MA2V 0 DirXDelta
     @MA2V 0 DirYDelta
     @CBREAK
   @CASE 1
     @MA2V 0 DirXDelta
     @MA2V -1 DirYDelta   
     @CBREAK
   @CASE 2
     @MA2V 1 DirXDelta
     @MA2V -1 DirYDelta
     @CBREAK
   @CASE 3
     @MA2V 1 DirXDelta
     @MA2V 0 DirYDelta   
     @CBREAK
   @CASE 4
     @MA2V 1 DirXDelta
     @MA2V 1 DirYDelta   
     @CBREAK
   @CASE 5
     @MA2V 0 DirXDelta
     @MA2V 1 DirYDelta   
     @CBREAK
   @CASE 6
     @MA2V -1 DirXDelta
     @MA2V 1 DirYDelta   
     @CBREAK
   @CASE 7
     @MA2V -1 DirXDelta
     @MA2V 0 DirYDelta   
     @MA2V -1 DirDelta   
     @CBREAK
   @CASE 8
     @MA2V -1 DirXDelta
     @MA2V -1 DirYDelta   
     @CBREAK
   @CDEFAULT
     @CBREAK
@ENDCASE

@POPNULL
@ForIA2B Index1 0 MaxStars
   @PUSHI Index1 @SHL @SHL @POPI Index2
   @PUSHII Index2
   @PUSHI Index2 @ADD 2 @ADD Stars
   @PUSHS
   @CALL WinCursor
   @PRT " "
   @PUSHII Index2
   @ADDI DirXDelta @DUP @POPII Index2
   @IF_GE_V WinWidth
      @PUSH 1
      @POPII Index2
   @ENDIF
   @IF_LE_A 0
      @PUSHI WinWidth @SUB 1
      @POPII Index2
   @ENDIF
   @POPNULL
   @PUSHII Index2
   @PUSHI Index2 @ADD 2 @PUSHS
   @ADDI DirYDelta @DUP @PUSHI Index2 @ADD 2 @POPS
   @IF_GE_V WinHeight
      @PUSH 1
      @PUSHI Index2 @ADD 2 @POPS
   @ENDIF
   @IF_LE_A 0
      @PUSHI WinHeight @SUB 1
      @PUSHI Index2 @ADD 2 @POPS
   @ENDIF
   @POPNULL
   @PUSHI Index2 @ADD 2 @PUSHS
   @CALL WinCursor
   @PRT "*"
@Next Index1
#@DEBUGTOGGLE
@POPRETURN
@RET

   


:InitGame
@CALL WinClear
@CALL WinHideCursor
@MA2V 0 Direction
@PUSH 0 @SUBI WinWidth @POPI NegWidth
@PUSH 0 @SUBI WinHeight @POPI NegHeight

@PUSHI WinHeight
@SHR
@POPI SHIPX
@PUSHI WinWidth
@SHR
@POPI SHIPY
@ForIA2B Index1 0 MaxStars
   @PUSHI WinWidth
   @CALL rndint
   @PUSHI Index1 @SHL @SHL @ADD Stars
   @POPS
   @PUSHI WinHeight
   @CALL rndint
   @PUSHI Index1 @SHL @SHL @ADD 2 @ADD Stars
   @POPS
@Next Index1

@RET

:Main . Main
@CALL InitGame
:Break1    

@MA2V 0 LoopState
@PUSHI LoopState
@CALL DrawStars
@CALL DrawShip
@LOOP
@POPNULL
@READCNW CHIN
@PUSHI CHIN
@IF_NOTZERO
  @SWITCH
       @CASE "w\0"
          @MA2V 1 Direction
          @CBREAK
       @CASE "e\0"
          @MA2V 2 Direction
          @CBREAK
       @CASE "d\0"
          @MA2V 3 Direction
          @CBREAK
       @CASE "c\0"
          @MA2V 4 Direction
          @CBREAK
       @CASE "x\0"
          @MA2V 5 Direction
          @CBREAK
       @CASE "z\0"
          @MA2V 6 Direction
          @CBREAK
       @CASE "a\0"
          @MA2V 7 Direction
          @CBREAK
       @CASE "q\0"
          @MA2V 8 Direction
          @CBREAK
       @CASE "L\0"
          @MA2V 1 LoopState
          @CBREAK
       @CDEFAULT
          @CBREAK
  @ENDCASE
  @POPNULL
  @CALL DrawStars
  @CALL DrawShip
@ELSE
   @POPNULL
@ENDIF
:Break2
@PUSHI LoopState
@UNTIL_NOTZERO
@END
