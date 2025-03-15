I common.mc
L screen.ld
L softstack.ld
L heapmgr.ld
L random.ld
M LocalVar = %1 Var%2 @PUSHLOCALI Var%2
M RestoreVar @POPLOCAL Var%1
#################################################
# Shared Variables
:Var01 0 :Var02 0 :Var03 0 :Var04 0 :Var05 0 :Var06 0 :Var07 0 :Var08 0 :Var09 0
:Var10 0 :Var11 0 :Var12 0 :Var13 0 :Var14 0 :Var15 0 :Var16 0
##################################################
#
# Screen Library provides
# WinHeight and WinWidth
#
:BLOCKCHAR "#\0"
:EMPTYCHAR " \0"
:BlockX 0
:BlockY 0
:MainHeap 0
:BitMapBytes
:BoardMap 0
:RESIZEABLE 0
:Speed 32
:CurrentBlockType 0  # index (0=I, 1=O, 2=T, 3=L, 4=J)
:CurrentRotation 0

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
  @MA2V 80 WinWidth
  @MA2V 24 WinHeight
@ELSE
  @CALL WinResize
@ENDIF
@PUSHI WinHeight @PUSHI WinWidth @CALL MULU @PUSH 8 @CALL DIVU
@POPI BitMapBytes
@POPNULL
#
@PUSHI MainHeap @PUSHI BitMapBytes @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 40" @END @ENDIF
@POPI BoardMap
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
@SWP @POPNULL   # Get rid of the part that doesn't change oftent
@CALL rndsetseed
#
@CALL MInit
@CALL WinClear
@TTYNOECHO
@CALL GameLoop
@TTYECHO
@PRTNL
@END
##################################################
# Function GameLoop
:GameLoop
@PUSHRETURN
@LocalVar Key 01
@LocalVar FrameCounter 02
@LocalVar PrevX 03
@LocalVar PrevY 04
@LocalVar BoomFlag 05
#
@PUSH 1
@MA2V 0 FrameCounter
@MA2V 0 BoomFlag
@WHILE_NOTZERO
   @POPNULL
#   @PUSH 65 @PUSH 1 @CALL WinCursor @PRTI PrevX @PRT "," @PRTI PrevY @PRT " "  @StackDump
   @MV2V BlockX PrevX
   @MV2V BlockY PrevY
   #
   @READCNW Key
#   @LOOP
#     @READC Key
#     @PUSHI Key     
#   @UNTIL_NOTZERO
#   @POPNULL
   #
   @PUSHI Key
   @SWITCH
   @CASE "q\0"
       @POPNULL
       @PUSHI WinWidth @SHR @SUB 3 @PUSHI WinHeight @SHR @PRT "\nGood Bye\n" @StackDump
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
   @CASE "s\0"
       @POPNULL
       @PUSH 0 @PUSH 1
       @CALL MoveBlock
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
   @CDEFAULT
       # Do Nothing.
       @POPNULL
       @PUSH 1  # Continue While
       @CBREAK
   @ENDCASE
   @POPNULL
   #
   @PUSHI FrameCounter
   @ANDI Speed          # Check every 16 cycles? also can use 2 4 or 8
   @IF_NOTZERO
      @PUSH 0 @PUSH 1
      @CALL MoveBlock
      @MA2V 0 FrameCounter
      @IF_EQ_AV 1 BoomFlag
           @MA2V 0 BoomFlag
           @PUSHI WinWidth @SHR @SUB 3 @PUSHI WinHeight @SHR @PRT "     "           
      @ENDIF
   @ENDIF
   @POPNULL
   #
   # If ( PrevX != BlockX ) || ( PrevY != BlockY)   
   @PUSH 0
   @IF_EQ_VV PrevX BlockX
   @ELSE
       @POPNULL @PUSH 1
   @ENDIF
   @IF_EQ_VV PrevY BlockY
   @ELSE
       @POPNULL @PUSH 1
   @ENDIF
   @IF_NOTZERO
      @POPNULL
      @PUSHI PrevX @PUSHI PrevY
      @CALL WinCursor
      @PRTSTR EMPTYCHAR
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI BlockX @PUSHI BlockY
   @CALL WinCursor
   @PRTSTR BLOCKCHAR
   @INCI FrameCounter
   @PUSHI BlockY
   @IF_GE_V WinHeight
       @PUSHI WinWidth @SHR @SUB 3 @PUSHI WinHeight @SHR @CALL WinCursor @PRT "BOOM!:"
       @MA2V 1 BlockY
   @ENDIF
@ENDWHILE
:QuitExit
@POPNULL
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
###############################################
# Function MoveBlock(DX,DY)
:MoveBlock
@PUSHRETURN
@LocalVar Dx 01
@LocalVar Dy 02
@LocalVar NewX 03
@LocalVar NewY 04
#
@POPI Dy
@POPI Dx
#

@PUSHI BlockX @ADDI Dx @POPI NewX
@PUSHI BlockY @ADDI Dy @POPI NewY

@PUSHI NewX @PUSHI NewY
@CALL CheckCollision
@IF_NOTZERO
   # Collision detected
   @PUSHI Dy
   @IF_GT_A 0
      @PUSHI BlockX @PUSHI BlockY @PUSHI CurrentBlockType @PUSHI CurrentRotation @PUSH 1
      @CALL DrawBlock
      @CALL DrawBoard
      #
      # Check for game over.
      @PUSHI BlockX @PUSHI BlockY
      @CALL CheckCollision
      @IF_NOTZERO
         @PUSHI WinWidth @SHR @SUB 5  # Position the message slightly left
         @PUSHI WinHeight @SHR        # Center Y position
         @CALL WinCursor
         @PRT "GAME OVER"             # Display the message
         @END                         # Halt execution
      @ENDIF
      #
      # Spawn new block.
      @PUSH 5 @CALL rndint
      @POPI CurrentBlockType
      @MA2V 0 CurrentRotation
      @PUSHI WinWidth @SHR @POPI BlockX
      @MA2V 1 BlockY
   @ENDIF
@ELSE
   # No Collision just update position
   @MV2V NewX BlockX
   @MV2V NewY BlockY
   @PUSHI BlockX @PUSHI BlockY @PUSHI CurrentBlockType @PUSHI CurrentRotation @PUSH 0
   @CALL DrawBlock   
@ENDIF
@POPNULL
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
@RET
########################################
# Function PlaceBlock(PX,PY)
:PlaceBlock
   @CALL SetBit
   @CALL DrawBoard
   # Check if new block spawn poition is aready occupied   
   @PUSHI WinWidth @SHR
   @PUSH 1
   @CALL GetBit
   # Else game is not over, continue.
   @CALL rndint @PUSH 5 @CALL DIVU @POPNULL   # RND MOD 5
   @POPI CurrentBlockType
   @MA2V 0 CurrentRotation
   @PUSHI WinWidth @SHR @POPI BlockX
   @MA2V 1 BlockY
@RET

#########################################
# Function DrawBoard
:DrawBoard
:PUSHRETURN
@LocalVar XP 01
@LocalVar YP 02
#
@CALL WinClear
@ForIA2V YP 0 WinHeight
   @ForIA2V XP 0 WinWidth
      @PUSHI XP @PUSHI YP
      @CALL GetBit
      @IF_NOTZERO
          @PUSHI YP @ADD 1 @PUSHI XP @ADD 1
          @PRTSTR BLOCKCHAR
      @ENDIF
      @POPNULL
   @Next XP
@Next YP
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#########################################
# Function SetBit(X,Y)
:SetBit
@PUSHRETURN
@LocalVar XP 01
@LocalVar YP 02
@LocalVar Index 03
@LocalVar Bit 04
@LocalVar YRsult 05
#
@POPI YP
@POPI XP
#
@PUSH YP @PUSHI WinWidth @CALL MULU @POPI YRsult
@PUSHI YRsult @ADDI XP @SHR @SHR @SHR @SHR
@POPI Index
@PUSHI YRsult @ADD XP @AND 0xf
@POPI Bit
@AND 0x1
@ForIA2V YRsult 0 Bit
   @SHL
@Next YRsult
@PUSHI BoardMap @ADDI Index @PUSHS
@ORS
@PUSHI BoardMap @ADDI Index @POPS
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#################################################
# Function GetBit(X,Y)
:GetBit
@PUSHRETURN
@LocalVar XP 01
@LocalVar YP 02
@LocalVar Index 03
@LocalVar Bit 04
@LocalVar YRsult 05
#
@POPI YP
@POPI XP
#
@PUSHI YP @PUSHI WinWidth @CALL MULU @POPI YRsult
@PUSHI YRsult @ADDI XP @SHR @SHR @SHR @SHR
@POPI Index
@PUSHI YRsult @AND 0xf
@POPI Bit
@PUSHI BoardMap @ADDI Index @PUSHS
@ForIA2V YRsult 0 Bit
   @SHL
@Next YRsult
@AND 0x1
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#################################################
# Function CheckCollision(XP,YP)
:CheckCollision
@PUSHRETURN
@LocalVar XP 01
@LocalVar YP 02
@LocalVar Mask 03
@LocalVar MaskRow 04
@LocalVar MaskBitStream 05
@LocalVar MaskBit 06
@LocalVar DX 07
@LocalVar DY 08
@LocalVar MapX 09
@LocalVar MapY 10
@LocalVar BitIndex 11
@LocalVar ByteIndex 12
@LocalVar BitOffset 13
@LocalVar BitLoop 14
#
@POPI YP
@POPI XP
:Debug01
# Bound Check, if any of these IF's are true, abort with false.
# Check XP
@PUSHI XP
@IF_LT_A 0   @POPNULL @PUSH 0  @JMP COLAbort @ENDIF
@ADD 3
@IF_GT_V WinWidth @POPNULL @PUSH 0 @JMP COLAbort @ENDIF
@POPNULL
# Check YP
@PUSHI YP
@IF_LT_A 0   @POPNULL @PUSH 0  @JMP COLAbort @ENDIF
@ADD 3
@IF_GT_V WinHeight @POPNULL @PUSH 0 @JMP COLAbort @ENDIF
@POPNULL
#
# Passed Bound Check
#
# Figure out what shape and roation to fill the Mask
@PUSH BlockShapes
@PUSHI CurrentBlockType @SHL @SHL @SHL  # Mul * 8 as each block db entry is 8 bytes long
@ADDS
@PUSHI CurrentRotation @SHL @ADDS       # Mul * 2 as each field is 16 bits
@PUSHS
@POPI Mask        # is the 16 bit 4x4 shape data.
#
@MV2V Mask MaskRow      # We'll be modifying Mask as we go down rows.
@PUSH 0
@ForIA2B DY 0 4
   @MV2V MaskRow MaskBitStream
   @ForIA2B DX 0 4
       # MaskBit = MaskBitStream & 0x1
       @PUSHI MaskBitStream @AND 0x1 @POPI MaskBit
       @PUSHI MaskBit
       @IF_NOTZERO
          @PUSHI XP @ADDI DX @POPI MapX
          @PUSHI YP @ADDI DY @POPI MapY
          @PUSHI MapY @PUSHI WinWidth @CALL MULU @ADDI MapX
          @POPI BitIndex
          @PUSHI BitIndex @SHR @SHR @SHR
          @POPI ByteIndex
          @PUSHI ByteIndex @AND 0x7
          @POPI BitOffset
          @PUSH BoardMap @ADD ByteIndex @PUSHS @AND 0xff
          @ForIA2V BitLoop 0 BitOffset
             @SHR
          @Next BitLoop
          @AND 0x1
          @IF_NOTZERO
             @POPNULL
             @POPNULL
             @PUSH 1
             @JMP COLAbort  # True, so shortcut to exit
          @ENDIF
          @POPNULL
       @ENDIF
       @POPNULL
       @PUSHI MaskBit @SHR @POPI MaskBit   # MaskBit >> 1
   @Next DX
   @PUSHI MaskRow @SHR @SHR @SHR @SHR @POPI MaskRow   # MaskRow >> 4
@Next DY
# If we get here then there were no matches, 0 should already be on stack
@PUSH 1 @PUSH 30 @CALL WinCursor @StackDump @PRT "  NO MATCH " @JMP SkipForward
:COLAbort          # Any calls to COLAbort should have just result on stack.
@PUSH 1 @PUSH 30 @CALL WinCursor @StackDump @PRT " WITH MATCH " @JMP SkipForward
:SkipForward
@RestoreVar 14
@RestoreVar 13
@RestoreVar 12
@RestoreVar 11
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
################################################
# Function DrawBlock(x,y,BlockID,Rotation,Erase)
:DrawBlock
@PUSHRETURN
@LocalVar PX 01
@LocalVar PY 02
@LocalVar BlockID 03
@LocalVar Rotation 04
@LocalVar Erase 05
@LocalVar Row 06
@LocalVar Col 07
@LocalVar BitPosition 08
@LocalVar ShapeData 09
@LocalVar IndexT 10
@POPI Erase
@POPI Rotation
@POPI BlockID
@POPI PY
@POPI PX
#
@PUSH BlockShapes
@PUSHI BlockID @SHL @SHL @SHL   # 8 bytes per row entry
@ADDS
@ADDI Rotation
@PUSHS
@POPI ShapeData
#
@ForIA2B Row 0 4
   @ForIA2B Col 0 4
       # 15 - (row * 4 + col)
       @PUSH 15
       @PUSHI Row @SHL @SHL   # *4
       @ADDI Col
       @SUBS
       @POPI BitPosition
       @PUSHI ShapeData
       @ForIA2V IndexT 0 BitPosition
          @SHR
       @Next IndexT
       @AND 0x1
       @IF_NOTZERO
           @PUSHI XP @ADDI Col @ADD 1
           @PUSHI YP @ADDI Row @ADD 1
           @CALL WinCursor
           @IF_EQ_AV 1 Erase
              @PRT " "
           @ELSE
              @PRT "#"
           @ENDIF
       @ENDIF
   @Next Col
@Next Row
@PUSH 1 @PUSH 30 @CALL WinCursor @StackDump @PRT " DrawBlock " @JMP SkipForward
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


      

#################################################
# Block Shape Data
:BlockShapes
# Share 'I' with 4 rotations
0b0000111100000000
0b0010001000100010
0b0000111100000000
0b0010001000100010

# Shape 'O' (No rotation needed)
0b0000011001100000
0b0000011001100000
0b0000011001100000
0b0000011001100000

# Shape 'T'
0b0000111001000000
0b0010011000100000
0b0000010001110000
0b0010001100100000

# Shape 'L'
0b0000111000100000
0b0000010010011000
0b0000100011100000
0b0110010010000000

# Shape 'J'
0b0000111000010000
0b0000110010001000
0b0000100001110000
0b0010001000110000



:ENDOFCODE
