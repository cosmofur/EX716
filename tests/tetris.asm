I common.mc
L softstack.ld
L screen.ld
L heapmgr.ld
L random.ld
L timetool.ld
#################################################
#
# Screen Library provides
# WinHeight and WinWidth
#
:BLOCKCHAR "#\0"
:EMPTYCHAR " \0"
:BlockX 0
:BlockY 0
:MainHeap 0
:BitMapBytes 0
:BoardMap 0
:RESIZEABLE 0
:Speed 500
:BoardWidth 10
:Score 0
:CurrentBlockType 0  # index (0=I, 1=O, 2=T, 3=L, 4=J)
:NextBlockType 0
:CurrentRotation 0
:FMULTable 0         # We multiply Y*Width often, so use a table as it max WinHight*2 in size.


################################################
# Function: MInit initilizes softstack and memory
:MInit
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeap
@PUSHI MainHeap @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 24" @END @ENDIF
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
#
# Setup Global Storage
@IF_EQ_AV 0 RESIZEABLE
  # ALlowing resizing makes debugging a bit harder, so set Macro Variable if you need it.
  @MA2V 24 WinWidth
  @MA2V 20 WinHeight
@ELSE
  @CALL WinResize
@ENDIF
@PUSHI WinHeight @ADD 1
@PUSHI WinWidth @ADD 1
@CALL MULU
@ADD 7
@SHR @SHR @SHR
@POPI BitMapBytes
#
@PUSHI MainHeap @PUSHI BitMapBytes @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 54" @END @ENDIF
@POPI BoardMap
#
@PUSHI MainHeap @PUSHI WinHeight @SHL @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 57" @END @ENDIF
@POPI FMULTable
#
@PUSHI BoardWidth @SHR @POPI BlockX
@MA2V 1 BlockY
@RET
#
##################################################
# Function Main
:Main . Main
#
# Set Random Seed based on time program was run.
@GETTIME   # Gets time as 32 bit number
@POPNULL   # Drop high word; low word changes most often.
@CALL rndsetseed
@CALL MInit
@CALL WinClear

@Call(AA) WinCursor 0 25
@MA2V 0 Var02
@PUSHI WinHeight @ADD 1
# Setup Multiplication table as multiples of winheight
@ForIA2S Var01 0
   @PUSHI Var02
   @PUSHI Var01 @SHL @ADDI FMULTable
   @POPS
   @PUSHI Var02 @ADDI WinWidth @POPI Var02
@Next Var01
# Setup display and draw line to mark bottom of screen.

@CALL WinClear

@ForIA2B Var01 0 10
    @PUSHI Var01
    @PUSHI WinHeight @SUB 1
    @CALL SetBit
@Next Var01
    
@CALL DrawBoard
@CALL InitPieceQueue
@CALL DrawScore
@CALL DrawNextBlock
@PUSHI BlockX @PUSHI BlockY
@PUSHI CurrentBlockType @PUSHI CurrentRotation @PUSH 0
@CALL DrawBlock
@CALL DrawGuideBar
@TTYNOECHO
@TTYRAW
@CALL GameLoop
@TTYECHO
@PRTNL
@END
##################################################
# Function GameLoop
:GameLoop
@PUSHRETURN
@Locals
@Local Key
@Local FrameCounter
@Local PrevX
@Local PrevY
#
@PUSH 1
@MA2V 0 FrameCounter
@PUSH 0 @PUSH 0
@CALL MoveBlock
@WHILE_NOTZERO
   @POPNULL
   @MV2V BlockX PrevX
   @MV2V BlockY PrevY
   #
   @READCNW Key
   #

   @PUSHI Key
   @SWITCH
   @CASE "q\0"
       @POPNULL
       @JMP QuitExit
       @CBREAK
   @CASE "a\0"

       @POPNULL
       @PUSH -1 @PUSH 0
       @CALL MoveBlock
       @PUSH 1  # Continue While
       @CBREAK
   @CASE "d\0"

       @POPNULL
       @PUSH 1 @PUSH 0
       @CALL MoveBlock
       @PUSH 1  # Continue While
       @CBREAK
   @CASE " \0"

       @POPNULL
       @PUSH 0 @PUSH 1
       @CALL MoveBlock
       @PUSH 1  # Continue While
       @CBREAK
   @CASE "w\0"

       @POPNULL
       @Call(A) RotateBlock 1
       @PUSH 1  # Continue While
       @CBREAK
   @CASE "s\0"

       @POPNULL
       @Call(A) RotateBlock -1
       @PUSH 1  # Continue While
       @CBREAK
   @CASE "-\0"

       @POPNULL
       @PUSHI Speed @SHR @POPI Speed
       @PUSH 1
       @CBREAK
   @CASE "+\0"

       @POPNULL
       @PUSHI Speed @SHL @POPI Speed
       @PUSH 1
       @CBREAK
   @CASE "o\0"

      @POPNULL
      @PRT "But Break Point here for debug."
      @PUSH 1
      @CBREAK
   @CDEFAULT

       # Do Nothing.
       @POPNULL       
       @PUSH 1  # Continue While

       @CBREAK
   @ENDCASE

   #
   @Call(A) SleepMilli 25

   @PUSHI FrameCounter
   @ADD 25
   @IF_UGE_V Speed
      @SUBI Speed
      @POPI FrameCounter
      @Call(AA) MoveBlock 0 1
   @ELSE
      @POPI FrameCounter
   @ENDIF
   @MA2V 0 Key
   @SRTP
   @IF_NEQ_A 1
      @PRTNL
      @PRT "Stack Issue"
      @StackDump
      @PRTCHI Key
      @PRTNL
   @ENDIF
   @POPNULL
      
@ENDWHILE
@POPNULL
:QuitExit
@EndLocals
@POPRETURN
@RET

#########################################
# Function InitPieceQueue()
:InitPieceQueue
@PUSH 7 @CALL rndint
@POPI CurrentBlockType
@PUSH 7 @CALL rndint
@POPI NextBlockType
@RET

#########################################
# Function DrawScore()
:DrawScore
@PUSHRETURN
@Locals
@Local BoxX
#
@PUSHI BoardWidth @ADD 3 @POPI BoxX
@PUSHI BoxX @PUSH 0 @CALL WinCursor
@PRT "SCORE"
@PUSHI BoxX @PUSH 1 @CALL WinCursor
@PRT "        "
@PUSHI BoxX @PUSH 1 @CALL WinCursor
@PRTI Score
@EndLocals
@POPRETURN
@RET

#########################################
# Function DrawNextBlock()
:DrawNextBlock
@PUSHRETURN
@Locals
@Local BoxX
@Local BoxY
#
@PUSHI BoardWidth @ADD 3 @POPI BoxX
@MA2V 4 BoxY
@PUSHI BoxX @PUSHI BoxY
@PUSHI BoxX @ADD 7
@PUSHI BoxY @ADD 6
@CALL WinBox
@PUSHI BoxX @ADD 1
@PUSHI BoxY @ADD 1
@PUSHI BoxX @ADD 6
@PUSHI BoxY @ADD 5
@CALL WinClearRect
@PUSHI BoxX @ADD 2
@PUSHI BoxY @ADD 1
@PUSHI NextBlockType @PUSH 0 @PUSH 0
@CALL DrawBlock
@EndLocals
@POPRETURN
@RET

#########################################
# Function DrawGuideBar()
:DrawGuideBar
@PUSHRETURN
@Locals
@Local X
@Local HIndex
@Local WIndex
@Local RowBits
@Local Mask
@Local Shift
@Local GuideCol
@Local HasBlock
#
@PUSH 0 @PUSHI WinHeight @CALL WinCursor
@ForIA2B X 0 10
   @PRT "."
@Next X
@PUSH BlockShapes
@PUSHI CurrentBlockType @SHL @SHL @SHL
@ADDS
@PUSHI CurrentRotation @SHL @ADDS
@PUSHS
@POPI Mask
@ForIA2B WIndex 0 4
   @MA2V 0 HasBlock
   @ForIA2B HIndex 0 4
      @PUSH 12
      @PUSHI HIndex @SHL @SHL
      @SUBS
      @POPI Shift
      @Call(VV) FastSHR Mask Shift
      @AND 0xf
      @POPI RowBits
      @ForIA2B X 0 4
         @PUSHI RowBits @AND 0x8
         @IF_NOTZERO
            @POPNULL
            @IF_EQ_VV X WIndex
               @MA2V 1 HasBlock
            @ENDIF
         @ELSE
            @POPNULL
         @ENDIF
         @PUSHI RowBits @SHL @POPI RowBits
      @Next X
   @Next HIndex
   @PUSHI HasBlock
   @IF_NOTZERO
      @POPNULL
      @PUSHI BlockX @ADDI WIndex @POPI GuideCol
      @PUSHI GuideCol
      @IF_GE_A 0
         @PUSHI GuideCol
         @IF_ULT_V BoardWidth
            @PUSHI GuideCol @PUSHI WinHeight @CALL WinCursor
            @PRT "^"
         @ENDIF
         @POPNULL
      @ENDIF
      @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
@Next WIndex
@EndLocals
@POPRETURN
@RET

###############################################
# Function MoveBlock(DX,DY)
:MoveBlock
@PUSHRETURN
@Locals
@Local Dx
@Local Dy
@Local NewX
@Local NewY
#
@POPI Dy
@POPI Dx
#
@PUSHI BlockX @ADDI Dx @POPI NewX
@PUSHI BlockY @ADDI Dy @POPI NewY
@IF_EQ_VV BlockX NewX
   @IF_EQ_VV BlockY NewY
      # Nothing changed, skip tests.
      @JMP SkipMoveBlock
   @ENDIF
@ENDIF
#
@PUSHI NewX @PUSHI NewY
@CALL CheckCollision
@IF_EQ_A 2
   # Hit Boundry, reset NewX, NewY to old values
   @MV2V BlockX NewX
   @MV2V BlockY NewY
   @POPNULL
   @JMP SkipMoveBlock
@ENDIF
@PUSHI BlockX @PUSHI BlockY
@PUSHI CurrentBlockType @PUSHI CurrentRotation @PUSH 1
@CALL DrawBlock
@IF_NOTZERO
   @POPNULL
   :Debug01
   # Collision detected
   @PUSHI Dy
   @IF_LE_A 0
      # Sideways or upward collisions only reject the proposed move.
      @POPNULL
      @MV2V BlockX NewX
      @MV2V BlockY NewY
      @JMP SkipCollisionFix
   @ENDIF
   @POPNULL
   @PUSHI BlockY
   @IF_LE_A 1
      # End Game.
      @PUSHI BoardWidth @SHR @SUB 5  # Position the message slightly left
      @PUSHI WinHeight @SHR        # Center Y position
      @CALL WinCursor
      @TTYECHO
      @PRT "GAME OVER"             # Display the message
      @END                         # Halt execution
   @ENDIF
   @POPNULL
   # Collision, but not at top of screen, freeze blocks.
   @PUSHI BlockX @PUSHI BlockY
   @CALL FixBlock
   @CALL ClearFullLines
   @CALL DrawBoard
   #
   # Spawn new block.
   @MV2V NextBlockType CurrentBlockType
   @PUSH 7 @CALL rndint
   @POPI NextBlockType
   @CALL DrawNextBlock
   @MA2V 0 CurrentRotation
   @PUSHI BoardWidth @SHR @POPI BlockX
   @MA2V 1 BlockY
@ELSE
   @POPNULL
   # No Collision just update position
   @MV2V NewX BlockX
   @MV2V NewY BlockY
@ENDIF

:SkipCollisionFix
@PUSHI BlockX @PUSHI BlockY
@PUSHI CurrentBlockType @PUSHI CurrentRotation @PUSH 0
@CALL DrawBlock
@CALL DrawGuideBar
:SkipMoveBlock
@PUSH 1 @PUSH 1 @CALL WinCursor @PRT " "
@EndLocals
@POPRETURN
@RET
#########################################
# Function FastSHR(Value,Steps)
:FastSHR
@PUSHRETURN
@Locals
@Local Steps
@Local Index1
@AND 0xf @POPI Steps  # We limit our selves to max of 0-15 steps

@ForIA2V Index1 0 Steps
   @SHR
@Next Index1
@EndLocals
@POPRETURN
@RET
#########################################
# Function FastSHL(Value,Steps)
:FastSHL
@PUSHRETURN
@Locals
@Local Steps
@Local Index1
@AND 0xf @POPI Steps  # We limit our selves to max of 0-15 steps
@ForIA2V Index1 0 Steps
   @SHL
@Next Index1
@EndLocals
@POPRETURN
@RET

#########################################
# Function FixBlock(XP,YP)
:FixBlock
@PUSHRETURN
@Locals
@Local XP
@Local YP
@Local RowBits
@Local HIndex
@Local WIndex
@Local Mask
@Local Shift
#
@POPI YP
@POPI XP
#
# Get Current Blocktype as a 16bit Mask
@PUSH BlockShapes
@PUSHI CurrentBlockType @SHL @SHL @SHL  # *8
@ADDS
@PUSHI CurrentRotation @SHL @ADDS       # *2
@PUSHS
@POPI Mask
#
@ForIA2B HIndex 0 4
   # RowBit= (Mask >> (12 - HIndex * 4) & 0xf)
   @PUSH 12 @PUSHI HIndex @SHL @SHL @SUBS
   @POPI Shift
   @Call(VV) FastSHR Mask Shift
   @AND 0xf
   @POPI RowBits
   @ForIA2B WIndex 0 4
      @PUSHI RowBits
      @AND 0x8
      @IF_NOTZERO
         @POPNULL

         @PUSHI XP @ADDI WIndex @SUB 1
         @PUSHI YP @ADDI HIndex
         @CALL SetBit
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI RowBits @SHL @POPI RowBits
   @Next WIndex
@Next HIndex      
@EndLocals
@POPRETURN
@RET

#########################################
# Function DrawBoard
:DrawBoard
@PUSHRETURN
@Locals
@Local Line
@Local Col
#
@ForIA2V Line 0 WinHeight
   @PUSH 0
   @PUSHI Line
   @CALL WinCursor
   @ForIA2B Col 0 10
       @PUSHI Col
       @PUSHI Line
       @CALL GetBit
       @IF_ZERO
          @PRT " "
       @ELSE
          @PRT "#"
       @ENDIF
       @POPNULL
   @Next Col
@Next Line
@PUSH 0 @PUSHI WinHeight @ADD 1 @CALL WinCursor
:Debug02
@EndLocals
@POPRETURN
@RET
# Local BitMaskTable
:BitMaskTable
0x80 0x40 0x20 0x10 0x8 0x4 0x2 0x1 0

:SwapBytes
@PUSHRETURN
@Locals
@Local highbyte
@Local lowbyte
@Local InWord
@POPI InWord
@PUSHI InWord @PUSH 8
@CALL FastSHR
@AND 0xff
@POPI highbyte
@PUSHI InWord @PUSH 8
@CALL FastSHL
@AND 0xff00
@ORI highbyte
@EndLocals
@POPRETURN
@RET
#########################################
# Function SetBit(X,Y)
:SetBit
@PUSHRETURN
@Locals
@Local XP
@Local YP
@Local Index
@Local Bit
@Local YRsult
@Local Index2
#
@POPI YP
@POPI XP
#

#@PUSHI YP @PUSHI WinWidth @CALL MULU @POPI YRsult
@PUSHI YP @SHL @ADDI FMULTable @PUSHS @POPI YRsult
@PUSHI YRsult @ADDI XP @SHR @SHR @SHR
@POPI Index
@PUSHI YRsult @ADDI XP @AND 0x7
@POPI Bit
@PUSH 0x80 @PUSHI Bit
@CALL FastSHR
@PUSHI BoardMap @ADDI Index @PUSHS
@ORS
@PUSHI BoardMap @ADDI Index @POPS
@EndLocals
@POPRETURN
@RET
#################################################
# Function GetBit(X,Y)
:GetBit
@PUSHRETURN
@Locals
@Local XP
@Local YP
@Local BitIndex
@Local ByteIndex
@Local BitOffset
@Local BitLoop
#
@POPI YP
@POPI XP
#

@PUSHI YP @SHL @ADDI FMULTable @PUSHS @ADDI XP
@POPI BitIndex
@PUSHI BitIndex @SHR @SHR @SHR
@POPI ByteIndex
@PUSHI BitIndex @AND 0x7
@POPI BitOffset
@PUSHI BoardMap @ADDI ByteIndex @PUSHS @AND 0xff
@ForIA2V BitLoop 0 BitOffset
   @SHL
@Next BitLoop
@AND 0x80
@IF_NOTZERO
   @POPNULL
   @PUSH 1
@ENDIF
@EndLocals
@POPRETURN
@RET

#########################################
# Function ClearBit(X,Y)
:ClearBit
@PUSHRETURN
@Locals
@Local XP
@Local YP
@Local Index
@Local Bit
@Local YRsult
#
@POPI YP
@POPI XP
#
@PUSHI YP @SHL @ADDI FMULTable @PUSHS @POPI YRsult
@PUSHI YRsult @ADDI XP @SHR @SHR @SHR
@POPI Index
@PUSHI YRsult @ADDI XP @AND 0x7
@POPI Bit
@PUSH 0x80 @PUSHI Bit
@CALL FastSHR
@INV
@PUSHI BoardMap @ADDI Index @PUSHS
@ANDS
@PUSHI BoardMap @ADDI Index @POPS
@EndLocals
@POPRETURN
@RET

#########################################
# Function CopyBit(SrcX,SrcY,DstX,DstY)
:CopyBit
@PUSHRETURN
@Locals
@Local SrcX
@Local SrcY
@Local DstX
@Local DstY
#
@POPI DstY
@POPI DstX
@POPI SrcY
@POPI SrcX
#
@PUSHI DstX @PUSHI DstY
@CALL ClearBit
@PUSHI SrcX @PUSHI SrcY
@CALL GetBit
@IF_NOTZERO
   @POPNULL
   @PUSHI DstX @PUSHI DstY
   @CALL SetBit
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

#########################################
# Function IsLineFull(Y)
:IsLineFull
@PUSHRETURN
@Locals
@Local YP
@Local X
@Local Full
#
@POPI YP
@MA2V 1 Full
@ForIA2B X 0 10
   @PUSHI X @PUSHI YP
   @CALL GetBit
   @IF_ZERO
      @MA2V 0 Full
   @ENDIF
   @POPNULL
@Next X
@PUSHI Full
@EndLocals
@POPRETURN
@RET

#########################################
# Function ClearLine(Y)
:ClearLine
@PUSHRETURN
@Locals
@Local YP
@Local X
@Local Row
#
@POPI YP
@ForIA2B Row 18 0
   @PUSHI Row
   @IF_LE_V YP
      @ForIA2B X 0 10
         @PUSHI X @PUSHI Row @SUB 1
         @PUSHI X @PUSHI Row
         @CALL CopyBit
      @Next X
   @ENDIF
   @POPNULL
@NextBy Row -1
@ForIA2B X 0 10
   @PUSHI X @PUSH 0
   @CALL ClearBit
@Next X
@EndLocals
@POPRETURN
@RET

#########################################
# Function ClearFullLines()
:ClearFullLines
@PUSHRETURN
@Locals
@Local Y
#
@ForIA2B Y 0 19
   @PUSHI Y
   @CALL IsLineFull
   @IF_NOTZERO
      @POPNULL
      @PUSHI Y
      @CALL ClearLine
      @PUSHI Score @ADD 100 @POPI Score
      @CALL DrawScore
   @ELSE
      @POPNULL
   @ENDIF
@Next Y
@EndLocals
@POPRETURN
@RET

#################################################
# Function CheckCollision(XP,YP)
# 0 = No Collision
# 1 = Collision
# 2 = Invalid Boundary
:CheckCollision
@PUSHRETURN
@Locals
@Local XP
@Local YP
@Local RowBits
@Local HIndex
@Local WIndex
@Local Mask
@Local Shift
@Local TestX
@Local TestY

@POPI YP
@POPI XP

# Get current BlockType / Rotation mask
@PUSH BlockShapes
@PUSHI CurrentBlockType @SHL @SHL @SHL
@ADDS
@PUSHI CurrentRotation @SHL
@ADDS
@PUSHS
@POPI Mask

	# TestX = XP + WIndex - 1
# TestY = YP + HIndex

@ForIA2B HIndex 0 4

   # Same row extraction as DrawBlock/FixBlock
   @PUSH 12
   @PUSHI HIndex @SHL @SHL
   @SUBS
   @POPI Shift

   @Call(VV) FastSHR Mask Shift
   @AND 0xf
   @POPI RowBits

   @ForIA2B WIndex 0 4

      @PUSHI RowBits
      @AND 0x8

      @IF_NOTZERO
         @POPNULL

         # Convert screen coordinate to bitmap coordinate
         @PUSHI XP
         @ADDI WIndex
         @SUB 1
         @POPI TestX

         @PUSHI YP
         @ADDI HIndex
         @POPI TestY

         #
	         @PUSHI TestX
	         @IF_LT_A 0
	            @POPNULL
	            @PUSH 2
	            @JMP COLAbort
	         @ENDIF
	         @POPNULL

	         @PUSHI TestX
	         @IF_UGE_V BoardWidth
	            @POPNULL
	            @PUSH 2
	            @JMP COLAbort
	         @ENDIF
	         @POPNULL

	         @PUSHI TestY
	         @IF_LT_A 0
	            @POPNULL
	            @PUSH 2
	            @JMP COLAbort
	         @ENDIF
	         @POPNULL

	         @PUSHI TestY
	         @IF_UGE_V WinHeight
	            @POPNULL
	            @PUSH 2
	            @JMP COLAbort
	         @ENDIF
	         @POPNULL

         @PUSHI TestX
         @PUSHI TestY
         @CALL GetBit

         @IF_NOTZERO
            @POPNULL
            @PUSH 1
            @JMP COLAbort
         @ENDIF
         @POPNULL

      @ELSE
         @POPNULL
      @ENDIF

      @PUSHI RowBits @SHL @POPI RowBits

   @Next WIndex

@Next HIndex

@PUSH 0

:COLAbort
@EndLocals
@POPRETURN
@RET

################################################
# Function RotateBlock(Direction)
# Direction = +1 or -1
:RotateBlock
@PUSHRETURN
@Locals
@Local Direction
@Local OldRotation

@POPI Direction
@MV2V CurrentRotation OldRotation

# Erase currently displayed orientation.
@PUSHI BlockX @PUSHI BlockY
@PUSHI CurrentBlockType @PUSHI OldRotation @PUSH 1
@CALL DrawBlock

# Calculate proposed rotation.
@PUSHI CurrentRotation
@ADDI Direction
@AND 0x3
@POPI CurrentRotation

# Check new orientation at CURRENT location.
@PUSHI BlockX @PUSHI BlockY
@CALL CheckCollision

@IF_NOTZERO
    # Rotation isn't legal.
    @POPNULL
    @MV2V OldRotation CurrentRotation
@ELSE
    @POPNULL
@ENDIF

# Draw either accepted new orientation,
# or restored old orientation.
@PUSHI BlockX @PUSHI BlockY
@PUSHI CurrentBlockType @PUSHI CurrentRotation @PUSH 0
@CALL DrawBlock
@CALL DrawGuideBar

@EndLocals
@POPRETURN
@RET

################################################
# Function DrawBlock(X,Y,BlockID,Rotation,EraseCode)
:DrawBlock
@PUSHRETURN
@Locals
@Local XP
@Local YP
@Local BlockID
@Local Rotation
@Local Erase
@Local Mask
@Local RowBits
@Local Index1
@Local Index2
@Local TYP
@Local Shift

@POPI Erase
@POPI Rotation
@POPI BlockID
@POPI YP
@POPI XP


@PUSH BlockShapes
@PUSHI BlockID @SHL @SHL @SHL
@ADDS
@PUSHI Rotation @SHL @ADDS
@PUSHS
@POPI Mask
#

@ForIA2B Index1 0 4
   @PUSH 12
   @PUSHI Index1 @SHL @SHL
   @SUBS
   @POPI Shift
   @Call(VV) FastSHR Mask Shift
   @AND 0xf
   @POPI RowBits


   #
   @IF_EQ_AV 0 RowBits
      # Do nothing
   @ELSE
   @ForIA2B Index2 0 4
      @PUSHI RowBits @AND 0x8
      @IF_EQ_AV 0 Erase      
         @IF_NOTZERO
                 @PUSHI XP @ADDI Index2
                 @PUSHI YP @ADDI Index1
                 @CALL WinCursor
             @PRT "#"
         @ELSE
#            @PRT " "
         @ENDIF
         @POPNULL
      @ELSE
         @IF_NOTZERO
                 @PUSHI XP @ADDI Index2
                 @PUSHI YP @ADDI Index1
                 @CALL WinCursor
             @PRT " "
         @ELSE
#            @PRT " "
         @ENDIF
         @POPNULL
      @ENDIF     
   @PUSHI RowBits @SHL @POPI RowBits
   @Next Index2
   @ENDIF
@Next Index1
@EndLocals
@POPRETURN
@RET

#########################################
# Function TestClearFullLines()
:TestClearFullLines
@PUSHRETURN
@Locals
@Local X
@Local Y
#
@ForIA2B X 0 10
   @PUSHI X @PUSH 17 @CALL SetBit
   @PUSHI X @PUSH 18 @CALL SetBit
@Next X
@PUSH 3 @PUSH 16 @CALL SetBit
@CALL ClearFullLines
@PUSH 3 @PUSH 18 @CALL GetBit
@IF_ZERO
   @PRT "ClearFullLines test failed"
   @END
@ENDIF
@POPNULL
@ForIA2B Y 0 19
   @ForIA2B X 0 10
      @PUSHI X @PUSHI Y @CALL ClearBit
   @Next X
@Next Y
@EndLocals
@POPRETURN
@RET

#################################################
# Block Shape Data Tetrominos
:BlockShapes
:BlockShapes0
# Share 'I' with 4 rotations 0
#   +----+   +----+   +----+   +----+
#   |    |   |  # |   |    |   |  # |
#   |    |   |  # |   |    |   |  # |
#   |    |   |  # |   |    |   |  # |
#   |####|   |  # |   |####|   |  # |
#   +----+   +----+   +----+   +----+
0b0000000000001111       # 0f00
0b0010001000100010       # 2222
0b0000000000001111       # 0f00
0b0010001000100010       # 2222

:BlockShapes1
#   +----+   +----+   +----+   +----+
#   |    |   |    |   |    |   |    |
#   |    |   |    |   |    |   |    |
#   | ## |   | ## |   | ## |   | ## |
#   | ## |   | ## |   | ## |   | ## |
#   +----+   +----+   +----+   +----+
# Shape 'O' (No rotation needed) 1
# 0123012301230123
0b0000000001100110       # 0660
0b0000000001100110
0b0000000001100110
0b0000000001100110

:BlockShapes2
#   +----+   +----+   +----+   +----+
#   |    |   |    |   |    |   |    |
#   |### |   |  # |   |  # |   | #  |
#   | #  |   | ## |   | ###|   | ## |
#   |    |   |  # |   |    |   | #  |
#   +----+   +----+   +----+   +----+
# Shape 'T'  2
# 0123012301230123
0b0000000011100100       # 0e40
0b0000001001100010       # 0262
0b0000001001110000       # 0270
0b0000010001100100       # 0464

:BlockShapes3
#   +----+   +----+   +----+   +----+
#   |    |   |    |   |    |   |    |
#   | #  |   |    |   | ## |   |    |
#   | #  |   | ###|   |  # |   |   #|
#   | ## |   | #  |   |  # |   | ###|
#   +----+   +----+   +----+   +----+
# Shape 'L'
# 0123012301230123
0b0000010001000110
0b0000000001110100
0b0000011000100010
0b0000000000010111

:BlockShapes4
#   +----+   +----+   +----+   +----+
#   |    |   |    |   |    |   |    |
#   |  # |   |    |   | ## |   |    |
#   |  # |   | #  |   | #  |   | ###|
#   | ## |   | ###|   | #  |   |   #|
#   +----+   +----+   +----+   +----+
# Shape 'J'
# 0123012301230123
0b0000001000100110
0b0000000001000111
0b0000011001000100
0b0000000001110001
:BlockShapes5
#   +----+   +----+   +----+   +----+
#   |    |   |    |   |    |   |    |
#   |    |   |  # |   |    |   |    |
#   |  ##|   |  ##|   |    |   |    |
#   | ## |   |   #|   |    |   |    |
#   +----+   +----+   +----+   +----+
# Shape 'S'
# 0123012301230123
0b0000000000110110
0b0000001000110001
0b0000000000110110
0b0000001000110001
:BlockShapes6
#   +----+   +----+   +----+   +----+
#   |    |   |    |   |    |   |    |
#   |    |   |   #|   |    |   |    |
#   | ## |   |  ##|   |    |   |    |
#   |  ##|   |  # |   |    |   |    |
#   +----+   +----+   +----+   +----+
# Shape 'Z'
# 0123012301230123
0b0000000001100011
0b0000000100110010
0b0000000001100011
0b0000000100110010



:DebugPrintTiles
@MA2V 3 Var01
@ForIA2B Var01 0 7
  @ForIA2B Var02 0 4
    @PUSHI Var02 @SHL @SHL @SHL @ADD 7    
    @PUSHI Var01 @SHL @SHL @SHL @ADD 0
    @CALL WinCursor  @PRT "(" @PRTI Var01 @PRT ")" @PRTI Var02
    @PUSHI Var02 @SHL @SHL @SHL @ADD 5 @PUSHI Var01 @SHL @SHL @SHL @ADD 2
    @PUSHI Var01 @PUSHI Var02 @PUSH 0 @CALL DrawBlock
  @Next Var02
@Next Var01
@PRT "\n\n END \n"
@RET



:ENDOFCODE
