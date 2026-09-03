I common.mc
L softstack.ld
L screen.ld
L heapmgr.ld
L random.ld
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
:Speed 32
:CurrentBlockType 0  # index (0=I, 1=O, 2=T, 3=L, 4=J)
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
@PUSHI WinWidth @SHR @POPI BlockX
@MA2V 1 BlockY
@RET
#
##################################################
# Function Main
:Main . Main
#
# Set Random Seed based on time program was run.
@GETTIME   # Gets time as 32 bit number
@POPNULL   # Get rid of the part that doesn't change often
@CALL rndsetseed

#
@CALL MInit
@CALL WinClear
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


@ForIA2V Var01 0 WinWidth
    @PUSHI Var01
    @PUSHI WinHeight @SUB 1
    @CALL SetBit
@Next Var01
    
@CALL DrawBoard
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
       @PUSHI CurrentRotation @ADD 1 @AND 0x3
       @POPI CurrentRotation
       @PUSH 1  # Continue While
       @CBREAK
   @CASE "s\0"
       @POPNULL
       @PUSHI CurrentRotation @SUB 1 @AND 0x3
       @POPI CurrentRotation
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
      :Debug00
      @CBREAK
   @CDEFAULT
       # Do Nothing.
       @POPNULL
       @PUSH 1  # Continue While
       @CBREAK
   @ENDCASE
   #
   @PUSHI FrameCounter
   @ANDI Speed          # Check every 16 cycles? also can use 2 4 or 8
   @IF_NOTZERO
      @IF_EQ_AV 14 Var16
         # Break Here
         :Break02
      @ENDIF
      @INCI Var16
      @PUSH 0 @PUSH 1
      @CALL MoveBlock
      @MA2V 0 FrameCounter
   @ENDIF
   @POPNULL
   @INCI FrameCounter
@ENDWHILE
@POPNULL
:QuitExit
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
   @PUSHI BlockY
   @IF_LE_A 1
      # End Game.
      @PUSHI WinWidth @SHR @SUB 5  # Position the message slightly left
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
   @CALL DrawBoard
   #
   # Spawn new block.
   @PUSH 7 @CALL rndint
   @POPI CurrentBlockType
   @MA2V 0 CurrentRotation
   @PUSHI WinWidth @SHR @POPI BlockX
   @MA2V 1 BlockY
@ELSE
   @POPNULL
   # No Collision just update position
   @MV2V NewX BlockX
   @MV2V NewY BlockY
@ENDIF

@PUSHI BlockX @PUSHI BlockY
@PUSHI CurrentBlockType @PUSHI CurrentRotation @PUSH 0
@CALL DrawBlock
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
@AND 0xf @POPI Steps  # We limit our selves to max of 0-15 steps
@PUSH FSHRCase0
@ADD 16 @SUBI Steps
@JMPS
:FSHRCase0
@SHR @SHR @SHR @SHR
@SHR @SHR @SHR @SHR
@SHR @SHR @SHR @SHR
@SHR @SHR @SHR @SHR
@EndLocals
@POPRETURN
@RET
#########################################
# Function FastSHL(Value,Steps)
:FastSHL
@PUSHRETURN
@Locals
@Local Steps
@AND 0xf @POPI Steps  # We limit our selves to max of 0-15 steps
@PUSH FSHLCase0
@ADD 16 @SUBI Steps
@JMPS
:FSHLCase0
@SHL @SHL @SHL @SHL
@SHL @SHL @SHL @SHL
@SHL @SHL @SHL @SHL
@SHL @SHL @SHL @SHL
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
@Local ByteIndex
@Local Shift
@Local BmapPtr
@Local Mask
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
   @PUSHI Mask
   @PUSH 12 @PUSHI HIndex @SHL @SHL @SUBS
   @CALL FastSHR
   @AND 0xf
   @POPI RowBits
   @IF_EQ_AV 0 RowBits
       # Don't do anything if zero
   @ELSE
      # BaseBitOffset = FMULTablep[YP+HIndex] + XP
      @PUSHI YP @ADDI HIndex @SHL @ADDI FMULTable @PUSHS @ADDI XP
      # Shift = BaseBitOffset & 0x7
      @DUP @AND 0x7 @POPI Shift
      # ByteIndex = BaseBitOffset >> 3
      @SHR @SHR @SHR @POPI ByteIndex
      # BmapPtr = &BoardMap[ByteIndex]
      @PUSHI ByteIndex @ADDI BoardMap @POPI BmapPtr
      # WordValue = BoardMap[BmapPtr]
      @PUSHII BmapPtr
      # WordValue |= (RowBits << Shift)      
      @PUSHI RowBits  @PUSHI Shift   @CALL FastSHL
      @ORS
      @POPII BmapPtr
   @ENDIF
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
@Local BitIndex
@Local ByteIndex
@Local BitOffset
#
@MA2V 0 BitIndex
#
@ForIA2V Line 0 WinHeight
   @PUSH 0
   @PUSHI Line
   @CALL WinCursor
   @ForIA2V Col 0 WinWidth
       @PUSHI BitIndex @SHR @SHR @SHR # ByteIndex = BitIndex >> 3
       @POPI ByteIndex
       @PUSHI BitIndex @AND 0x7       # BitOffset = BitIndex & 7
       @POPI BitOffset
       @PUSHI BoardMap @ADDI ByteIndex
       @PUSHS @AND 0xff                        # On Stack is TempByte
       @PUSHI BitOffset @SHL
       @ADD BitMaskTable
       @PUSHS
       @ANDS
       @IF_ZERO
          @PRT " "
       @ELSE
          @PRT "#"
       @ENDIF
       @POPNULL
       @INCI BitIndex
   @Next Col
@Next Line
@PUSH 0 @PUSHI WinHeight @ADD 1 @CALL WinCursor
@StackDump
:Debug02
@ForIupA2B Line 0 66
   @PUSHI BoardMap @ADDI Line
   @PUSHS 
   @CALL SwapBytes
   @POPI ByteIndex   
   @PRTBINI ByteIndex
   @PUSHI BoardMap @ADDI Line @ADD 2
   @PUSHS @AND 0xff @CALL SwapBytes
   @POPI ByteIndex
   @PRTBINI ByteIndex @PRTNL
@NextBy Line 3
@StackDump
#
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
#################################################
# Functoin CheckCollision(XP,YP) 0:No Collision 1:Collision 2:Invalid Boudry
:CheckCollision
@PUSHRETURN
@Locals
@Local XP
@Local YP
@Local RowBits
@Local HIndex
@Local ByteIndex
@Local Shift
@Local BmapPtr
@Local Mask
#
@POPI YP
@POPI XP


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
   @PUSHI Mask
   @PUSH 12 @PUSHI HIndex @SHL @SHL @SUBS
   @CALL FastSHR
   @AND 0xf
   @POPI RowBits
   @IF_EQ_AV 0 RowBits
        # Skip empty rows
    @ELSE
      # BaseBitOffset = FMULTablep[YP+HIndex] + XP
      @PUSHI YP @ADDI HIndex @SHL @ADDI FMULTable @PUSHS @ADDI XP
      # Shift = BaseBitOffset & 0x7
      @DUP @AND 0x7 @POPI Shift
      # ByteIndex = BaseBitOffset >> 3
      @SHR @SHR @SHR @POPI ByteIndex
      # BmapPtr = &BoardMap[ByteIndex]
      @PUSHI ByteIndex @ADDI BoardMap @POPI BmapPtr
      # WordValue = BoardMap[BmapPtr]
      @PUSHII BmapPtr
      @PUSH 0xf @PUSHI Shift @CALL FastSHL
      @ANDS
      # WordValue |= (RowBits << Shift)      
      @PUSHI RowBits  @PUSHI Shift   @CALL FastSHL
      @ANDS
      @IF_NOTZERO
         # Found match, report it and exit.
         @POPNULL
         @PUSH 1
         @JMP COLAbort
      @ENDIF
      @POPNULL
    @ENDIF
@Next HIndex

# No collision found
@PUSH 0
:COLAbort

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
   @PUSHI Mask
   @PUSHI 12 @PUSHI Index1 @SHL @SHL @SUBS
   @CALL FastSHR
   @AND 0xf
   @POPI RowBits
   # Set cursor on row
   @PUSHI XP @PUSHI YP @ADDI Index1 @CALL WinCursor   
   #
   @IF_EQ_AV 0 RowBits
      # Do nothing
   @ELSE
   @ForIA2B Index2 0 4
      @PUSHI RowBits @AND 0x8
      @IF_EQ_AV 0 Erase      
         @IF_NOTZERO
            @PRT "#"
         @ELSE
            @PRT " "
         @ENDIF
         @POPNULL
      @ELSE
         @IF_NOTZERO
            @PRT " "
         @ELSE
            @PRT " "
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




#################################################
# Function SleepT(Secs)
:SleepT
@PUSHRETURN
@Locals
@Local Secs
@POPI Secs
#
@GETTIME @POPNULL
@ADDI Secs @POPI Secs
@GETTIME @POPNULL
@WHILE_LT_V Secs
   @POPNULL
   @GETTIME @POPNULL
@ENDWHILE
@POPNULL
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
0b0000000001000110       # 0464

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
