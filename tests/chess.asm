I common.mc
L softstack.ld
L heapmgr.ld
L screen.ld
L string.ld

##################################
# Functions Summary
#
# SetupStack: Setup
# InitBoard: Setup
# NibbleGet(MemPtr, Index): Get nibble inside byte array by nibble index
# NibblePut(Value, MemPtr, Index): Store Nibble value at array by nibble index
# GetPieceInfo(PieceIndex): (Square, Alive, Color, Xpos, Ypos)
# SetPieceInfo(PieceIndex,Alive,Color,Xpos,Ypos):void
# SHLI: Support
# SHRI: Support
# CandidatePack(LocX,LocY,CaptFlag,CapPieceIndex)
# CandidateUnpack(Encoded):(LocX,LocY,CaptFlag, CapPieceIndex)
# CheckBoard(X,Y): Returns either piece index, or -1 for invalud/empty square.
# ValidMoves(PieceIndex, Depth):Candidate...CandiateN,Count | 0
# GetPieceMove(PieceType, Direction, Color):(MoveInvalid | DeltaX,DeltaY)
# GetPieceType(PieceIndex):(Type# | PieceInvalid)
# MovePiece(PieceIndex,Candidate):void
# SquareXYtoSqr(X,Y):Square| -1
# SquareSqrtoXY(Square):(X,Y)|-1
# DisplayBoard(ViewPoint)
# UserMoveValid(PieceIndex, TargetX, TargetY):(MoveInvalid| Candidate)
# PieceToString(PieceID): Print["K","Q","R","N","B","P","k","q","r","n","b","p"]
#
###########
# Globals
:MainHeap 0
:Temp01 0
:Temp02 0
:CPX 0               # current considered piece location info
:CPY 0
:CPDIR 0
:CPMR 0
:ActiveColor 0
:WRook   1
:WBishop 3
:WKnight 5
:WPawn   7
:WQueen  15

:BRook   17
:BBishop 19
:BKnight 21
:BPawn   23
:BQueen  31
:PTSString 0 0 0 
:PiecesArray
. PiecesArray+32     # Allocate 32 bytes


###########
# Constants
=StackSizeDefault 400
=AliveBit 0b10000000
=ColorBit 0b01000000
=XBits 0b111
=YBits 0b111000
=SquareBits 0b111111
=BlackColor 1
=WhiteColor 0
# Pack Structure constants
=CPDIR_N    0
=CPDIR_NE   1
=CPDIR_E    2
=CPDIR_SE   3
=CPDIR_S    4
=CPDIR_SW   5
=CPDIR_W    6
=CPDIR_NW   7
=CPMR_Any       0   # Ordinary piece movement
=CPMR_Empty     1   # Destination must be empty
=CPMR_Capture   2   # Destination must contain an enemy
=CPMR_Double    3   # Pawn double move; path and destination empty
=CPMR_EnPassant 4
=CPMR_Castle    5
=CP_XBits      0b0000000000000111
=CP_YBits      0b0000000000111000
=CP_DIRBits    0b0000000111000000
=CP_MRBits     0b0000111000000000

=CP_YShift     3
=CP_DIRShift   6
=CP_MRShift    9

=MoveInvalid -999
=EmptySquare -1

# Both unique and ranking of value for game logic
=PieceKing 99
=PieceQueen 90
=PieceRook 50
=PieceBishop 31
=PieceKnight 30
=PiecePawn  10
=PieceInvalid -1

###########
# Common Macros
M MaskValue @PUSHI %1 @AND %2 @POPI %1
M MaskValueI @PUSHI %1 @ANDI %2 @POPI %1

#####################
# Setup Stack
:SetupStack
   @PUSH 0xff00
   @SUB END__
   @POPI Temp01
   @Call(AV) HeapDefineMemory END__ Temp01
   @POPI MainHeap
   @Call(VA) HeapNewObject MainHeap StackSizeDefault
   @IF_ULT_A 100
      @PRTLN "Error out of memory"
      @END
   @ENDIF
   @POPI Temp01
   @PUSHI Temp01
   @ADD StackSizeDefault
   @POPI Temp02
   @Call(VV) SetSSStack Temp02 Temp01
@RET

###################
# InitBoard
:InitBoard
@PUSHRETURN
@Locals
   @Local PColumn
   @Local Index1
   @Local Address

# Macro SetPiece
# SetPiect(X,Y,PID,Color)
   M SetPiece \
      @PUSH 0 \
      @Call(AA) SquareXYtoSqr %1 %2 \
      @ORS \
      @PUSH AliveBit \
      @ORS \
      @PUSH %4 \
      @SHLN 6 \
      @ORS \
      @PUSH PiecesArray @ADD %3 \
      @POPI Address \
      @STOREBI Address

# Version for Pawns as they use a variable for X position
   M SetPieceA \
      @PUSH 0 \
      @Call(VA) SquareXYtoSqr %1 %2 \
      @ORS \
      @PUSH AliveBit \
      @ORS \
      @PUSH %4 \
      @SHLN 6 \
      @ORS \
      @PUSH PiecesArray @ADDI %3 \
      @POPI Address \
      @STOREBI Address

   # Set White Pieces
   @SetPiece 4 0 0 0    # King
   @SetPiece 0 0 1 0    # Rook
   @SetPiece 7 0 2 0    # Rook
   @SetPiece 2 0 3 0    # Bishop
   @SetPiece 5 0 4 0    # Bishop
   @SetPiece 1 0 5 0    # Knight
   @SetPiece 6 0 6 0    # Knight
   @MA2V 7 Index1
   @ForIA2B PColumn 0 8
      @SetPieceA PColumn 1 Index1 0   # Pawns
      @INCI Index1
   @Next PColumn
   @SetPiece 3 0 15 0   # Queen
# Set Black Piece
   @SetPiece 4 7 16 1    # King
   @SetPiece 0 7 17 1    # Rook
   @SetPiece 7 7 18 1    # Rook
   @SetPiece 2 7 19 1    # Bishop
   @SetPiece 5 7 20 1    # Bishop
   @SetPiece 1 7 21 1    # Knight
   @SetPiece 6 7 22 1    # Knight
   @MA2V 23 Index1
   @ForIA2B PColumn 0 8
      @SetPieceA PColumn  6 Index1 1   # Pawns
      @INCI Index1
   @Next PColumn
   @SetPiece 3 7 31 1   # Queen
   # Initilize Rank indexes
   @MA2V  15 WQueen
   @MA2V  17 BRook
   @MA2V  19 BBishop
   @MA2V  21 BKnight
   @MA2V  23 BPawn
   @MA2V  31 BQueen

@EndLocals
@POPRETURN
@RET


#################
# Nibble Functions
#
##################
# NibbleGet(MemPtr,Index):Nibble
:NibbleGet
@PUSHRETURN
@Locals
    @Local Odd
    # Stack: [MemPtr, Index]

    @DUP
    @AND 1
    @POPI Odd              # Stack: [MemPtr, Index]

    @SHR                   # Stack: [MemPtr, Index/2]
    @ADDS                  # Stack: [MemPtr + Index/2]
    @PUSHS                 # Stack: [ByteValue]

    @PUSHI Odd
    @IF_NOTZERO
        @POPNULL           # Remove condition value
        @SHRN 4            # Move upper nibble into bits 0..3
    @ELSE
        @POPNULL           # Remove condition value
    @ENDIF

    @AND 0xf

@EndLocals
@POPRETURN
@RET
###################
# NibblePut(Value, MemPtr, Index):void
:NibblePut
@PUSHRETURN
@Locals
    @Local Odd
    @Local MemPtr
    @Local Value
    @Local Index

    @POPI3 Index MemPtr Value

    @PUSHI Index
    @AND 1
    @POPI Odd

    @PUSHI Index
    @SHR
    @ADDI MemPtr
    @POPI MemPtr

    @PUSHI Odd
    @IF_ZERO
        @POPNULL           # Remove condition value
        @PUSHII MemPtr
        @AND 0xfff0        # Preserve old upper nibble and upper byte
        @PUSHI Value
        @AND 0xf           # Just to make sure it a nibble value
        @ORS
        @POPII MemPtr
    @ELSE
        @POPNULL
        @PUSHII MemPtr
        @AND 0xff0f        # Preserve old lower nibble and upper byte
        @PUSHI Value
        @AND 0xf           # Just to make sure it a nibble value
        @SHLN 4
        @ORS
        @POPII MemPtr
    @ENDIF
@EndLocals
@POPRETURN
@RET



###################
# GetPieceInfo(PieceIndex):
#     (Square, Alive, Color, XPos, YPos)
#
:GetPieceInfo
@PUSHRETURN
@Locals
    @Local PieceIndex
    @Local Address
    @Local PieceValue
    @Local Square
    @Local Alive
    @Local Color
    @Local XPos
    @Local YPos

    @POPI PieceIndex

    # Address = PiecesArray + PieceIndex
    @PUSH PiecesArray
    @ADDI PieceIndex
    @POPI Address

    # PieceValue = PiecesArray[PieceIndex]
    @LOADBII Address
    @POPI PieceValue

    # Square = low six bits
    @PUSHI PieceValue
    @AND SquareBits
    @POPI Square

    # Alive = Boolean(PieceValue & AliveBit)
    @PUSHI PieceValue
    @AND AliveBit
    @SHRN 7
    @POPI Alive

    # Color = Boolean(PieceValue & ColorBit)
    @PUSHI PieceValue
    @AND ColorBit
    @SHRN 6
    @POPI Color

    @Call(V) SquareSqrtoXY Square
    @POPI2 YPos XPos

    # Return values:
    # (Square, Alive, Color, XPos, YPos)
    @PUSHI Square
    @PUSHI Alive
    @PUSHI Color
    @PUSHI XPos
    @PUSHI YPos

@EndLocals
@POPRETURN
@RET

##########################
# SetPieceInfo(PieceIndex,Alive,Color,Xpos,Ypos):void
:SetPieceInfo
@PUSHRETURN
@Locals
   @Local PieceIndex
   @Local Alive
   @Local Color
   @Local XLocation
   @Local YLocation
   @Local Address

   @POPI5 YLocation XLocation Color Alive PieceIndex


   @Call(VV) SquareXYtoSqr XLocation YLocation
   
   @PUSHI Alive
   @AND 1
   @SHLN 7
   
   @ORS
   
   @PUSHI Color
   @AND 1
   @SHLN 6
   
   @ORS
   
   @PUSHI PiecesArray
   @ADDI PieceIndex   
   @POPI Address
   
   @STOREBI Address
@EndLocals
@POPRETURN
@RET



   
########################
# SHLI Support function  SHLI(Value,Shift count)
:SHLI
@PUSHRETURN
@Locals
   @Local I1
   @Local Limit

   @POPI Limit
   @ForIA2V I1 0 Limit
      @SHL
   @Next I1
@EndLocals
@POPRETURN
@RET

########################
# SHRI Support function  SHRI(Value,Shift count)
:SHRI
@PUSHRETURN
@Locals
   @Local I1
   @Local Limit

   @POPI Limit
   @ForIA2V I1 0 Limit
      @SHR
   @Next I1
@EndLocals
@POPRETURN
@RET



########################
# CandidatePack(LocX,LocY,CaptFlag,CapPieceIndex)
# Stores multiple fields in single word for passing/returing from functions.
:CandidatePack
@PUSHRETURN
@Locals
    @Local LocX
    @Local LocY
    @Local CaptFlag
    @Local CapPieceIndex

    @POPI4 CapPieceIndex CaptFlag LocY LocX

    @PUSHI LocX @AND 0x7
    @PUSHI LocY @AND 0x7 @SHLN 3
    @ORS
    @PUSHI CaptFlag @AND 1 @SHLN 6
    @ORS
    @PUSHI CapPieceIndex @AND 31 @SHLN 7
    @ORS
@EndLocals
@POPRETURN
@RET

#############################
# CandidateUnpack(Encoded):(LocX,LocY,CaptFlag, CapPieceIndex)
:CandidateUnpack
@PUSHRETURN
@Locals
    @Local LocX
    @Local LocY
    @Local CaptFlag
    @Local CapPieceIndex
    @Local Encoded

    @POPI Encoded

    @PUSHI Encoded         @AND 7  @POPI LocX
    @PUSHI Encoded @SHRN 3 @AND 7  @POPI LocY
    @PUSHI Encoded @SHRN 6 @AND 1  @POPI CaptFlag
    @PUSHI Encoded @SHRN 7 @AND 31 @POPI CapPieceIndex

    @PUSHI4 LocX LocY CaptFlag CapPieceIndex

@EndLocals
@POPRETURN
@RET

###############################
# CheckBoard(X,Y):(EmptySquare|PieceIndex)
###############################
:CheckBoard
@PUSHRETURN
@Locals
   @Local Xin
   @Local Yin
   @Local ReturnCode
   @Local PIndex
   @Local PTemp
   @Local Square

   # Input stack: [X, Y] <TOS
   @POPI2 Yin Xin

   @MA2V EmptySquare ReturnCode
   # Convert X,Y to packed square; helper also validates coordinates.
   @Call(VV) SquareXYtoSqr Xin Yin
   @IF_EQ_A EmptySquare
      @POPNULL
      @JMP CBFExit
   @ENDIF
   @POPI Square

   # Search the 32 piece records.
   @ForIA2B PIndex 0 32
      @PUSH PiecesArray
      @ADDI PIndex
      @PUSHS
      @AND 0xff
      @POPI PTemp
      # Ignore captured/dead pieces.
      @PUSHI PTemp
      @AND AliveBit
      @IF_NOTZERO
         @POPNULL
         # Compare the six-bit packed squares.
         @PUSHI PTemp
         @AND SquareBits
         @IF_EQ_V Square
            @POPNULL
            @MV2V PIndex ReturnCode
            @JMP CBFExit
         @ELSE
            @POPNULL
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
   @Next PIndex

:CBFExit
   @PUSHI ReturnCode

@EndLocals
@POPRETURN
@RET
###############################
# ValidMoves(PieceIndex, Depth):
#     Candidate1 ... CandidateN Count
#
:ValidMoves
@PUSHRETURN
@Locals
        # Moving piece
    @Local TestPieceIndex
    @Local PieceType
    @Local PieceAlive
    @Local PieceColor
    @Local TestPieceX
    @Local TestPieceY

    # Requested search
    @Local RequestedDepth
    @Local CandidateCount

    # Current direction/path
    @Local TestDir
    @Local TestDepth
    @Local TestX
    @Local TestY
    @Local DeltaX
    @Local DeltaY

    # Piece encountered on path
    @Local TargetPieceIndex
    @Local TargetColor
    @Local TargetAlive

    # Loop Structures
    @Local Index1
    @Local IsAngle

    @POPI2 RequestedDepth TestPieceIndex

    @MA2V 0 CandidateCount

    # Reject invalid piece index.
    @PUSHI TestPieceIndex
    @IF_UGT_A 31
        @POPNULL
        @JMP VMExit
    @ELSE
        @POPNULL
    @ENDIF

    # Load source piece information.
    @PUSHI TestPieceIndex
    @CALL GetPieceInfo

    # Pop returned values in reverse order.
    @POPI TestPieceY
    @POPI TestPieceX
    @POPI PieceColor
    @POPI PieceAlive
    @POPNULL              # Square is not needed

    # Captured piece has no moves.
    @PUSHI PieceAlive
    @IF_ZERO
        @POPNULL
        @JMP VMExit
    @ELSE
        @POPNULL
    @ENDIF

    @Call(V) GetPieceType TestPieceIndex
    @POPI PieceType


    # Reject requested depths that can not exist for this piece
    # King/Knight max depth 1
    # Pawn max depth 2
    # Others are handled normally.
    @PUSHI RequestedDepth
    @IF_GE_A 2
       @IF_EQ_AV PieceKing PieceType
          @POPNULL
          @JMP VMExit   # CandidateCount will still be zero
       @ENDIF
       @IF_EQ_AV PieceKnight PieceType
          @POPNULL
          @JMP VMExit   # CandidateCount will still be zero
       @ENDIF
    @ENDIF
    # Pawn logic says 2 step moves are possible only if on original row, 1 for white, 6 for black
    @IF_EQ_A 2
       @IF_EQ_AV PiecePawn PieceType
           @IF_EQ_AV WhiteColor PieceColor
               # White 2 move valid only on Row 1
               @IF_NEQ_AV 1 TestPieceY
                   @POPNULL
                   @JMP VMExit
               @ENDIF
           @ELSE
               # Black 2 move valid only on Row 6
               @IF_NEQ_AV 6 TestPieceY
                   @POPNULL
                   @JMP VMExit
               @ENDIF
           @ENDIF
       @ENDIF
    @ENDIF
    # And no distance > 2 is ever legal for Pawns
    @IF_GE_A 3
       @POPNULL
       @IF_EQ_AV PiecePawn PieceType
          @JMP VMExit   # CandidateCount will still be zero
       @ENDIF
    @ELSE
       @POPNULL
    @ENDIF

    # Now we start our Direction loop.
    @ForIA2B TestDir 0 8
        @Call(VVV) GetPieceMove PieceType TestDir PieceColor
        @IF_NEQ_A MoveInvalid
            @POPI2 DeltaY DeltaX        
            # We need Angle informaiton for Pawns
            @PUSHI TestDir
            @AND 1
            @POPI IsAngle
            #
            # Angle is only valid for pawns if Depth is 1
            @IF_EQ_AV PiecePawn PieceType
               @IF_NEQ_AV 1 RequestedDepth
                  @IF_NEQ_AV 0 IsAngle
                     @JMP VMEContinueDir
                  @ENDIF
               @ENDIF
            @ENDIF
            @MV2V TestPieceX TestX
            @MV2V TestPieceY TestY
            @MA2V 0 TestDepth
            @ForIA2V Index1 0 RequestedDepth
                @INCI TestDepth
                @PUSHI TestX @ADDI DeltaX @POPI TestX
                @PUSHI TestY @ADDI DeltaY @POPI TestY
                # Check still on board
                @PUSHI TestX
                @IF_UGE_A 8
                   # Off board edge
                   @POPNULL
                   @JMP VMEContinueDir
                @ENDIF
                @POPNULL
                @PUSHI TestY
                @IF_UGE_A 8
                   # Off board edge
                   @POPNULL
                   @JMP VMEContinueDir
                @ENDIF
                @POPNULL
                # Check if empty or has piece
                @Call(VV) CheckBoard TestX TestY
                @POPI TargetPieceIndex
                @PUSHI TargetPieceIndex
                @IF_NEQ_A EmptySquare
                   # Not empty
                   @CALL GetPieceInfo # index already on stack
                   @POPNULL @POPNULL      # Dont need x,y
                   @POPI2 TargetColor TargetAlive
                   @POPNULL               # Don't need square
                   @IF_EQ_AV 0 TargetAlive
                      # If not alive treat as empty.
                      @IF_EQ_AV PiecePawn PieceType
                         # Special Rule for Pawns
                         @IF_NEQ_AV 0 IsAngle
                            # Pawns can not move at an Angle if not taking an enemy.                            
                            @JMP VMEContinueDir
                         @ENDIF
                      @ENDIF
                      @IF_EQ_VV TestDepth RequestedDepth
                          @Call(VVAA) CandidatePack TestX TestY 0 0
                          @INCI CandidateCount
                      @ELSE
                          @JMP VMEContinueDir
                      @ENDIF
                   @ELSE
                      # It alive, see if friendly
                      @IF_EQ_VV TargetColor PieceColor
                          # Friendly
                          # not a candidate
                          @JMP VMEContinueDir
                      @ELSE
                         # Enemy possible candidate
                         @IF_EQ_VV TestDepth RequestedDepth
                         # Special Rule for Pawns
                            @IF_EQ_AV PiecePawn PieceType
                               @IF_EQ_AV 0 IsAngle
                                  # As this is not diagonal, pawn can't take piece going straight
                                  @JMP VMEContinueDir
                               @ENDIF
                             @ENDIF                             
                             @Call(VVAV) CandidatePack TestX TestY 1 TargetPieceIndex
                             @INCI CandidateCount
                             @ELSE
                             @JMP VMEContinueDir
                         @ENDIF
                      @ENDIF
                   @ENDIF
                @ELSE
                   # Empty Square
                   @POPNULL
                   @IF_EQ_AV PiecePawn PieceType
                      # Special Rule for Pawns
                      @IF_NEQ_AV 0 IsAngle
                         # Pawns can not move at an Angle if not taking an enemy.                            
                         @JMP VMEContinueDir
                      @ENDIF
                   @ENDIF                   
                   @IF_EQ_VV TestDepth RequestedDepth
                      # Enemy possible candidate
                      # Add to possible candidate list
                      @Call(VVAA) CandidatePack TestX TestY 0 0
                      @INCI CandidateCount
                   @ENDIF
                @ENDIF
            @Next Index1
       @ELSE
          # Move invalide
          @POPNULL
       @ENDIF
    :VMEContinueDir
    @Next TestDir
    #
    # Handle the return here.

:VMExit
    @PUSHI CandidateCount

@EndLocals
@POPRETURN
@RET



#################################
# GetPieceMove(PieceType, Direction, Color):(MoveInvalid | DeltaX,DeltaY)
# Returns the 1 step delta the piece can move in given direction or MoveInvalid if direction not allowed.
# Does not know location on board, so can't tell if move is valid for current position.
#
:DirFixedXTable
0 1 1 1 0 -1 -1 -1    # N NE E SE S SW W NW  X
:DirFixedYTable
1 1 0 -1 -1 -1 0 1    # N NE E SE S SW W NW  Y
:DirFixedKnightXTable
-1 1 2 2 1 -1 -2 -2   # n=nnW, ne=nnE, e=EEn, se=EEs, s=SSe,sw=SSw,w=wwS,nw=NNw
:DirFixedKnightYTable
2 2 1 -1 -2 -2 -1 1   # n=NNw, ne=NNe, e=eeN, se=eeS, s=ssE,sw=ssW,w=WWs,nw=nnW

#  Bit Pattern of CPDIR values
#  CPDIR_N    0b000    # Straight
#  CPDIR_NE   0b001    # Angle
#  CPDIR_E    0b010    # Straight
#  CPDIR_SE   0b011    # Angle
#  CPDIR_S    0b100    # Straight
#  CPDIR_SW   0b101    # Angle
#  CPDIR_W    0b110    # Straight
#  CPDIR_NW   0b111    # Angle
#
:GetPieceMove
@PUSHRETURN
@Locals
    @Local PieceType
    @Local Direction
    @Local Color
    @Local Result1
    @Local Result2
    @Local DirX1
    @Local DirY1
    @Local IsAngle

    @POPI3 Color Direction PieceType

    # validate direction
    @PUSHI Direction
    @IF_UGT_A 7
       @POPNULL
       @PUSH MoveInvalid
       @JMP GPMExit
    @ELSE
       @POPNULL
    @ENDIF

    # Set DirX1 and DirY1 for the default values of given direction but individual pieces will override by their rules
    @PUSHI Direction
    @SHL
    @ADD DirFixedXTable
    @PUSHS
    @POPI DirX1
    @PUSHI Direction
    @SHL
    @ADD DirFixedYTable
    @PUSHS
    @POPI DirY1
    # Check for Slopes
    @PUSHI Direction
    @AND 0b1
    @IF_ZERO
       # Straight
       @MA2V 0 IsAngle
    @ELSE
       # Angle
       @MA2V 1 IsAngle
    @ENDIF
    @POPNULL

    @PUSHI PieceType
    @SWITCH
    @CASE PieceRook
       # Move is not valid if its at an Angle
       @POPNULL
       @IF_EQ_AV 0 IsAngle
          @MV2V DirX1 Result1
          @MV2V DirY1 Result2
       @ELSE
          @MA2V MoveInvalid Result1
       @ENDIF
       @CBREAK
    @CASE PieceKnight
       @POPNULL
       # Knigts move in a sort of 'sloped' angle. Do we use this alternative table for directions
       @PUSHI Direction
       @SHL
       @ADD DirFixedKnightXTable
       @PUSHS
       @POPI Result1
       @PUSHI Direction
       @SHL
       @ADD DirFixedKnightYTable
       @PUSHS
       @POPI Result2
       @CBREAK
    @CASE PieceBishop
       # Move is not valid if its not at an Angle
       @POPNULL
       @IF_EQ_AV 1 IsAngle
          @MV2V DirX1 Result1
          @MV2V DirY1 Result2
       @ELSE
          @MA2V MoveInvalid Result1
       @ENDIF
       @CBREAK
    @CASE PieceKing
       # Kings move in any possible directoin
       @POPNULL
       @MV2V DirX1 Result1
       @MV2V DirY1 Result2
       @CBREAK
    @CASE PieceQueen
       # Queens move in any possible directoin
       @POPNULL
       @MV2V DirX1 Result1
       @MV2V DirY1 Result2
       @CBREAK
    @CASE PiecePawn
       # Pawns can move either forward or to side, but as DIR does not know location on board
       # it cant tell if side to side move is valid, it just says its possible.
       # But we need to know color to know which direction is 'forward'
       @POPNULL
       @IF_EQ_AV WhiteColor Color
          @PUSHI Direction
          @SWITCH
          @CASE CPDIR_NW
             @MV2V DirX1 Result1
             @MV2V DirY1 Result2
             @CBREAK
          @CASE CPDIR_N
             @MV2V DirX1 Result1
             @MV2V DirY1 Result2
             @CBREAK
          @CASE CPDIR_NE
             @MV2V DirX1 Result1
             @MV2V DirY1 Result2
             @CBREAK
          @CDEFAULT
             # If not NW,N or NE then not valid.
             @MA2V MoveInvalid Result1
             @CBREAK
          @ENDCASE
          @POPNULL
       @ELSE
          # Black Case
          @PUSHI Direction
          @SWITCH
          @CASE CPDIR_SW
             @MV2V DirX1 Result1
             @MV2V DirY1 Result2
             @CBREAK
          @CASE CPDIR_S
             @MV2V DirX1 Result1
             @MV2V DirY1 Result2
             @CBREAK
          @CASE CPDIR_SE
             @MV2V DirX1 Result1
             @MV2V DirY1 Result2
             @CBREAK
          @CDEFAULT
             # If not SW,S or SE then not valid.
             @MA2V MoveInvalid Result1
             @CBREAK
          @ENDCASE
          @POPNULL
       @ENDIF
       @CBREAK
    @CDEFAULT
       # Not a valid piece
       @POPNULL
       @MA2V MoveInvalid Result1
       @CBREAK
    @ENDCASE
    @IF_EQ_AV MoveInvalid Result1
       @PUSH MoveInvalid
    @ELSE
       @PUSHI Result1
       @PUSHI Result2
    @ENDIF
    :GPMExit
@EndLocals
@POPRETURN
@RET



##################################
# GetPieceType(PieceIndex)
:GetPieceType
@PUSHRETURN
@Locals
   @Local PIndex
   @Local PType

   @POPI PIndex
   @MA2V PieceInvalid PType

   @PUSHI PIndex
   @IF_ULE_A 31
      @POPNULL
   @ELSE
      @POPNULL
      @JMP GPTExit
   @ENDIF

   @PUSHI PIndex
   @IF_ULT_A 16
      # White
      @IF_ZERO
         @MA2V PieceKing PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V WBishop
         @MA2V PieceRook PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V WKnight
         @MA2V PieceBishop PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V WPawn
         @MA2V PieceKnight PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V WQueen
         @MA2V PiecePawn PType
         @JMP GPTExit
      @ENDIF
      @MA2V PieceQueen PType
      @JMP GPTExit
  @ELSE
      # Black
      @IF_EQ_A 16
         @MA2V PieceKing PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V BBishop
         @MA2V PieceRook PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V BKnight
         @MA2V PieceBishop PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V BPawn
         @MA2V PieceKnight PType
         @JMP GPTExit
      @ENDIF
      @IF_ULT_V BQueen
         @MA2V PiecePawn PType
         @JMP GPTExit
      @ENDIF
      @MA2V PieceQueen PType
      @JMP GPTExit
  @ENDIF
:GPTExit
  @POPNULL
  @PUSHI PType
@EndLocals
@POPRETURN
@RET
#######################################
# MovePiece(PieceIndex, Candidate):void
:MovePiece
@PUSHRETURN
@Locals
    @Local PieceIndex
    @Local Candidate
    @Local TargetX
    @Local TargetY
    @Local CaptFlag
    @Local CapPieceIndex
    @Local PieceAlive
    @Local PieceColor
    @Local CaptureX
    @Local CaptureY
    

    @POPI2 Candidate PieceIndex

    @Call(V) CandidateUnpack Candidate
    @POPI4 CapPieceIndex CaptFlag TargetY TargetX

    @Call(VV) CheckBoard TargetX TargetY

    @IF_NEQ_A EmptySquare
       # This is a capture. Mark old piece as dead.
       @POPI CapPieceIndex
       @Call(V) GetPieceInfo CapPieceIndex
       @POPI4 CaptureY CaptureX PieceColor PieceAlive
       @POPNULL               # Original square no longer matters
       @Call(VAVVV) SetPieceInfo CapPieceIndex 0 PieceColor CaptureX CaptureY   # Mark piece as captured.
    @ELSE
       @POPNULL
    @ENDIF
    # Now move active piece to captured pieces location
    @Call(V) GetPieceInfo PieceIndex
    @POPNULL @POPNULL         # don't need original location
    @POPI2 PieceColor PieceAlive
    @POPNULL                  # don't need original square
    @Call(VVVVV) SetPieceInfo PieceIndex PieceAlive PieceColor TargetX TargetY
@EndLocals
@POPRETURN
@RET

       
       
    

    


#######################################
# SquareXYtoSqr(X,Y):Sqr|-1
:SquareXYtoSqr
@PUSHRETURN
@Locals
    @Local Y1

    @IF_UGE_A 8
       @POPNULL
       @POPNULL
       @PUSH -1
       @JMP SXYExit
    @ENDIF
    @SHLN 3
    @POPI Y1
    @IF_UGE_A 8
       @POPNULL
       @PUSH -1
       @JMP SXYExit
    @ENDIF
    @ORI Y1
:SXYExit
@EndLocals
@POPRETURN
@RET
#####################################
# SquareSqrtoXY(Square):(X,Y)|-1
:SquareSqrtoXY
@PUSHRETURN
@Locals
    @Local Square

    @IF_UGE_A 64
       @POPNULL
       @PUSH -1
    @ELSE
       @POPI Square
       @PUSHI Square
       @AND 0x7
       @PUSHI Square
       @SHRN 3
       @AND 0x7
    @ENDIF
@EndLocals
@POPRETURN
@RET

########################################
# DisplayBoard(ViewPoint) 
:DisplayBoard
@PUSHRETURN
@Locals
    @Local ViewPoint
    @Local Index1
    @Local Index2
    @Local XDir
    @Local YDir
    @Local XCur
    @Local YCur
    @Local Temp1
    @Local PieceString
    @Local PieceIndex
    @Local PieceColor
    @Local PieceAlive

    @POPI ViewPoint

    @IF_EQ_AV BlackColor ViewPoint
       @MA2V -1 XDir
       @MA2V 7 XCur
       @MA2V 1 YDir
       @MA2V 0 YCur
    @ELSE
       @MA2V 1 XDir
       @MA2V 0 XCur
       @MA2V -1 YDir
       @MA2V 7 YCur
    @ENDIF
    @IF_EQ_AV BlackColor ViewPoint
         @PRTLN " |h|g|f|e|d|c|b|a|"
    @ELSE
         @PRTLN " |a|b|c|d|e|f|g|h|"
    @ENDIF
    @ForIA2B Index2 0 8
       @MV2V XCur Temp1
       @PUSHI YCur @ADD 1 
       @PRTTOP
       @POPNULL
       @PRT "|"
       @ForIA2B Index1 0 8
          @Call(VV) CheckBoard Temp1 YCur
          @IF_EQ_A -1
             @POPNULL
             @PRT " |"
          @ELSE
             @POPI PieceIndex
             @PUSHI PieceIndex
             @Call(V) PieceToString PieceIndex
             @POPI PieceString
             @PRTSI PieceString
             @Call(V) GetPieceType PieceIndex
             @PRT "|"
          @ENDIF
          @PUSHI Temp1
          @ADDI XDir
          @POPI Temp1
       @Next Index1
       @PRTNL
       @PUSHI YCur
       @ADDI YDir
       @POPI YCur
   @Next Index2
   @PRTNL
@EndLocals
@POPRETURN
@RET
##################################
# UserMoveValid(PieceIndex, TargetX, TargetY)
:UserMoveValid
@PUSHRETURN
@Locals
   @Local PieceIndex
   @Local TargetX
   @Local TargetY
   @Local StartColor
   @Local StartAlive
   @Local DepthIndex
   @Local Count
   @Local Index1
   @Local CapPieceIndex
   @Local CaptFlag
   @Local Result
   @Local Candidate
   @Local CandidateX
   @Local CandidateY

   @POPI3 TargetY TargetX PieceIndex
   @MA2V MoveInvalid Result

   @PUSHI PieceIndex
   @IF_UGE_A 32
      # Not valid
      @POPNULL
      @JMP UMVExit
   @ENDIF
   @POPNULL

   @Call(V) GetPieceInfo PieceIndex
   @POPNULL @POPNULL   # Do not need duplicate X and Y
   @POPI2 StartColor StartAlive
   @POPNULL # Dont need square

   @IF_EQ_AV 0 StartAlive
      # Player tried to move dead piece.
      @JMP UMVExit
   @ENDIF
   @IF_NEQ_VV ActiveColor StartColor
      # Player tried to move piece he didn't own.
      @JMP UMVExit
   @ENDIF
   @ForIA2B DepthIndex 1 8
      @Call(VV) ValidMoves PieceIndex DepthIndex
      @POPI Count
      @IF_EQ_AV 0 Count
         @JMP UMVExit
      @ENDIF
      @ForIA2V Index1 0 Count
         @POPI Candidate
         @Call(V) CandidateUnpack Candidate
         @POPI4 CapPieceIndex CaptFlag CandidateY CandidateX
         @IF_EQ_VV TargetX CandidateX
             @IF_EQ_VV TargetY CandidateY
                @MV2V Candidate Result
             @ENDIF
         @ENDIF
      @Next Index1
      @IF_NEQ_VV Result MoveInvalid
         # Requested destination found at this depth
         @JMP UMVExit
      @ENDIF
   @Next DepthIndex
:UMVExit
   @PUSHI Result
@EndLocals
@POPRETURN
@RET



####################################
# PieceToString(PieceID,Color):StrPtr
:PieceToString
@PUSHRETURN
@Locals
   @Local PieceID
   @Local Color


   @POPI2 Color PieceID

   @PUSHI PieceID
   @SWITCH
   @CASE PieceKing
      @POPNULL
      @PUSH "K\0"
      @CBREAK
   @CASE PieceQueen
      @PUSH "Q\0"
      @CBREAK
   @CASE PieceRook
      @PUSH "R\0"
      @CBREAK
   @CASE PieceBishop
      @PUSH "B\0"
      @CBREAK
   @CASE PieceKnight
      @PUSH "N\0"
      @CBREAK
   @CASE PiecePawn
      @PUSH "P\0"
      @CBREAK
   @CDEFAULT
      @PUSH " \0"
      @CBREAK
   @ENDCASE
   @POPI PTSString
   @IF_EQ_AV BlackColor Color
      # Convert to lowercase
      @PUSHI PTSString
      @PUSH 0x20
      @ORS
      @POPI PTSString
   @ENDIF
   @PUSH PTSString     # Return Ptr to fixed string.
@EndLocals
@POPRETURN
@RET
#####################################
# ChessCmdUnpack(CmdCode)
# Splits cmdcode into 4 3 bit fields
:ChessCmdUnpack
@PUSHRETURN
@Locals
   @Local CmdCode
   @POPI CmdCode

   @PUSHI CmdCode
   @AND 0x7           # X1
   @PUSHI CmdCode
   @SHRN 3
   @AND 0x7           # Y1
   @PUSHI CmdCode
   @SHRN 6
   @AND 0x7           # X2
   @PUSHI CmdCode
   @SHRN 9
   @AND 0x7
@EndLocals
@POPRETURN
@RET

   


######################################
# ReadChessCmd
:ReadChessCmd
@PUSHRETURN
@Locals
   @Local InputStr
   @Local Index1
   @Local StrLen
   @Local Value01
   @Local Value02
   @Local Value03
   @Local Value04


   @Call(VA) HeapNewObject MainHeap 255
   @IF_ULT_A 100
      @PRTLN "Error, out of memory."
      @END
   @ENDIF
   @POPI InputStr
   @READSI InputStr
   
   @Call(V) strlen InputStr
   @IF_ZERO
      @POPNULL      
      @PRT "No entry."
      @JMP RCCErrExit
   @ELSE
      @POPI StrLen
      @MA2V 0 Index1
      @PUSHI InputStr
      @ADDI Index1
      @PUSHS
      @AND 0xff
      @IF_EQ_A "q\0"
         @POPI Value01
         @JMP RCCCmdExit
      @ENDIF
      @IF_EQ_A "p\0"
         @POPI Value01
         @JMP RCCCmdExit
      @ENDIF
      @IF_NEQ_AV 4 StrLen
         @JMP "Syntax Error"
         @JMP RCCErrExit
      @ENDIF
      @IF_INRANGE_AB "a\0" "h\0"
         @SUB "a\0"
         @POPI Value01
      @ELSE
         @PRT "Syntax Error"
         @JMP RCCErrExit
      @ENDIF
      @INCI Index1
      @PUSHI InputStr
      @ADDI Index1
      @PUSHS
      @AND 0xff
      @IF_INRANGE_AB "1\0" "8\0"
         @SUB "1\0"
         @POPI Value02
      @ELSE
         @PRT "Syntax Error"
         @JMP RCCErrExit
      @ENDIF
      @INCI Index1
      @PUSHI Index1
      @PUSHI InputStr
      @ADDI Index1
      @PUSHS
      @AND 0xff   
      @IF_INRANGE_AB "a\0" "h\0"
         @SUB "a\0"
         @POPI Value03
      @ELSE
         @PRT "Syntax Error"
         @JMP RCCErrExit
      @ENDIF
      @INCI Index1
      @PUSHI Index1
      @PUSHI InputStr
      @ADDI Index1
      @PUSHS
      @AND 0xff
      @IF_INRANGE_AB "1\0" "8\0"
         @SUB "0\0"
         @POPI Value04
      @ELSE
         @PRT "Syntax Error"
         @JMP RCCErrExit
      @ENDIF
      @PUSHI Value01
      @AND 0x7
      @PUSHI Value02
      @AND 0x7
      @SHLN 3
      @ORS
      @PUSHI Value03
      @AND 0x7
      @SHLN 6
      @ORS
      @PUSHI Value04
      @AND 0x7
      @SHLN 9
      @ORS
      @POPI Value01
      @JMP RCCCmdExit
  @ENDIF
  :RCCErrExit
  @MA2V MoveInvalid Value01
  :RCCCmdExit
  @PUSHI Value01
  @Call(VV) HeapDeleteObject MainHeap InputStr
@EndLocals
@POPRETURN
@RET

      
      
         

########################################
# ManualPlay():void
# Test play loop where user enters all moves
#    "q\0"       Quit
#    "p\0"       Pass/switch player
#    otherwise   value accepted by ParseCmd
:ManualPlay
@PUSHRETURN
@Locals
   @Local ActiveColor
   @Local CmdMode
   @Local TargetX
   @Local TargetY
   @Local SrcPiece
   @Local SrcAlive
   @Local SrcColor
   @Local SrcX
   @Local SrcY
   @Local Candidate

   @MA2V WhiteColor ActiveColor
   @MA2V 0 CmdMode

   @WHILE_EQ_AV 0 CmdMode
      @IF_EQ_AV WhiteColor ActiveColor
          @PRT "White's Move: "
      @ELSE
          @PRT "Black's Move: "
      @ENDIF

      @Call(V) DisplayBoard ActiveColor

      @CALL ReadChessCmd
      @POPI CmdMode

      @IF_EQ_AV "q\0" CmdMode
         @PRTLN "Exit..."
      @ELSE
         @IF_EQ_AV "p\0" CmdMode
            @PRTLN "Skip Turn"
         @ELSE
            @IF_EQ_AV MoveInvalid CmdMode
               @JMP MPContinue
            @ENDIF
            @Call(V) ChessCmdUnpack CmdMode
            @POPI4 TargetY TargetX SrcY SrcX
            @Call(VV) CheckBoard SrcX SrcY
            @POPI SrcPiece
            @IF_EQ_AV EmptySquare SrcPiece
               @PRTLN "No piece at that location."
               @JMP MPContinue
            @ELSE
               @Call(V) GetPieceInfo SrcPiece
               @POPNULL @POPNULL
               @POPI2 SrcColor SrcAlive
               @POPNULL
               @IF_NEQ_VV ActiveColor SrcColor
                  @PRTLN "Can not move other player's pieces"
                  @JMP MPContinue                                       
               @ELSE
                  @IF_EQ_AV 0 SrcAlive
                     @PRTLN "Can not move captured piece."
                     @JMP MPContinue                     
                  @ELSE
                     @Call(VVV) UserMoveValid  SrcPiece TargetX TargetY
                     @POPI Candidate
                     @IF_EQ_AV MoveInvalid Candidate
                         @PRTLN "Not a valid move."
                         @JMP MPContinue
                     @ELSE
                         @Call(VV) MovePiece SrcPiece Candidate
                     @ENDIF
                  @ENDIF
               @ENDIF
            @ENDIF
         @ENDIF
         @MA2V 0 CmdMode
         @IF_EQ_AV WhiteColor ActiveColor
            @MA2V BlackColor ActiveColor
         @ELSE
            @MA2V WhiteColor ActiveColor
         @ENDIF
      @ENDIF
   :MPContinue
   @ENDWHILE
   @POPNULL
@EndLocals
@POPRETURN
@RET




########################################
# TestDisplayBoard
#
# Initialize the standard chess position,
# then display it from both viewpoints.
########################################

:TestDisplayBoard
@PUSHRETURN
@Locals
   @Local Color
   @POPI Color

   @CALL InitBoard

   @IF_EQ_AV WhiteColor Color
      @PRTLN "White View"
   @ELSE
      @PRTLN "Black View"
  @ENDIF
   @Call(V) DisplayBoard Color


@EndLocals
@POPRETURN
@RET





:Main .ORG Main
   @CALL SetupStack
   @CALL InitBoard
@PRTLN "White Board"
@Call(A)  TestDisplayBoard WhiteColor

@PRTLN "Direct ValidMoves Knight 5 Depth 1"
@Call(AA) ValidMoves 5 1
@PRTLN "Count: " @PRTTOP @PRTNL

   @PRTLN "Tests"
   @PRTLN "Move Knight for test"
   @PRTLN "Test Knight to 0,2"
   @Call(AAA) UserMoveValid 5 0 2
   @PRTLN "Result: " @PRTTOP @PRTNL @POPNULL
   @PRTLN "Test Knight to 2,2"
   @Call(AAA) UserMoveValid 5 2 2
   @PRTLN "Result: " @PRTTOP @PRTNL    @POPNULL
   @PRTLN "Test Knight to 3,1"
   @Call(AAA) UserMoveValid 5 3 1
   @PRTLN "Result: " @PRTTOP @PRTNL @POPNULL
   @PRTLN "Test Knight to 1,2"
   @Call(AAA) UserMoveValid 5 1 2
   @PRTLN "Result: " @PRTTOP @PRTNL    @POPNULL
   @PRTLN "Testing Bishop"
   @PRTLN "Test Bishop to anything"
   @Call(AAA) UserMoveValid 3 4 2
   @PRTLN "Result: " @PRTTOP @PRTNL @POPNULL




   @PRTLN "Black"
   @Call(A)  TestDisplayBoard BlackColor
@END
