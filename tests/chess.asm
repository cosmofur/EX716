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
# GetPieceInfo(PieceIndex): (Square, Alive, Color, Xpos, Ypos)
# SetPieceInfo(PieceIndex,Alive,Color,Xpos,Ypos):void
# SHLI: Support
# SHRI: Support
# CandidatePack(LocX,LocY,CaptFlag,CapPieceIndex)
# CandidateUnpack(Encoded):(LocX,LocY,CaptFlag, CapPieceIndex)
# ReadChessCmd():("q","p",ABab)
# KingCheck(Color):1|0
# HasLegalMove(Color):1|0
# ReportGameState(Color):void
# SuggestMove(Color, SearchDepth):(Result, PieceIndex, Candidate, Score)
# PrintSuggestedMove(Result, PieceIndex, Candidate, Score):void
# CastleSetValid(Color)
# CastleInvalidKing(Color)
# CastleInvalidRook(PieceIndex, Color)
# CastleTestRook(PieceIndex, Color):(0|1)
# CastleTestKing(Color):(0|1)
# CastleMoveTest(CmdMode):(0|1)
# CastleMoveValid(CmdMode):(MoveInvalid | KingPiece,RookPiece,KingDestX,RookDestX,KingY,Result)
# CastleMoveTry(CmdMode):(MoveInvalid|RookPieceIndex)
# ManualPlay():void
# CheckBoard(X,Y): Returns either piece index, or -1 for invalud/empty square.
# ValidMoves(PieceIndex, Depth):Candidate...CandiateN,Count | 0
# GetPieceMove(PieceType, Direction, Color):(MoveInvalid | DeltaX,DeltaY)
# GetPieceType(PieceIndex):(Type# | PieceInvalid)
# MovePiece(PieceIndex,Candidate):void
# SquareXYtoSqr(X,Y):Square| -1
# SquareSqrtoXY(Square):(X,Y)|-1
# DisplayBoard(ViewPoint)
# UserMovePossible(PieceIndex, TargetX, TargetY):(MoveInvalid| Candidate)
# UserMoveValid(PieceIndex, TargetX, TargetY):(MoveInvalid| Candidate)
# PieceToString(PieceType, Color): Print["K","Q","R","N","B","P","k","q","r","n","b","p"]
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
:WPieceEnd 100

:BRook   17
:BBishop 19
:BKnight 21
:BPawn   23
:BQueen  31
:BPieceEnd 100

:WhiteRangePtr
WRook WBishop WKnight WPawn WQueen WPieceEnd
:BlackRangePtr
BRook BBishop BKnight BPawn BQueen BPieceEnd

:PTSString 0 0 0
:PiecesArray
. PiecesArray+32     # Allocate 32 bytes
:PromotionArray
. PromotionArray+32  # Per-piece promoted type override, or 0.
:CastleArray 0 0     # Castling information.
:EnPassantSquare 0     # Square capturable by en passant, or MoveInvalid.
:EnPassantPiece 0      # Pawn index capturable by en passant, or MoveInvalid.


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
# CmdCode Constants
=PromotionQueen  0x0001
=PromotionKnight 0x0002
=PromotionRook   0x0003
=PromotionBishop 0x0000

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
=SuggestMoveOK 1
=SuggestMoveNoMove 0
=SuggestMoveDefaultDepth 1
=SuggestMoveCmdMask 0xff
=SuggestMoveDepthShift 8
=SMFrameMoveScore 0
=SMFrameReplyResult 2
=SMFrameReplyScore 4
=SMFrameBestScore 6
=SMFrameBestPieceIndex 8
=SMFrameBestCandidate 10
=SMFrameSize 12

M SM_FILL_A @PUSH %3  @PUSHI %1 @ADD %2 @POPS
M SM_FILL_V @PUSHI %3 @PUSHI %1 @ADD %2 @POPS
M SM_FILL_S @PUSHI %1 @ADD %2 @POPS
M SM_GET @PUSHI %1 @ADD %2 @PUSHS


# Both unique and ranking of value for game logic
=PieceKing 99
=PieceQueen 90
=PieceRook 50
=PieceBishop 31
=PieceKnight 30
=PiecePawn  10
=PieceInvalid -1
=PieceSpace 0

###########
# Common Macros
M MaskValue @PUSHI %1 @AND %2 @POPI %1
M MaskValueI @PUSHI %1 @ANDI %2 @POPI %1
# BOARD SAVE/LOAD/DUMP are macros rather than functions as we can not use normal softstack return address logic.
M SAVEBOARD @JMP %0_LocJmp :%0_Index 0 :%0_LocJmp \
    @ForIA2B %0_Index 0 32 \
       @PUSH PiecesArray \
       @ADDI %0_Index \
       @PUSHS \
       @PUSHHW \
    @NextBy %0_Index 2 \
    @PUSHI ActiveColor \
    @PUSHHW \
    @PUSHI EnPassantSquare \
    @PUSHHW \
    @PUSHI EnPassantPiece \
    @PUSHHW \
    @PUSHI CastleArray \
    @PUSHHW \
    @PUSHI CastleArray+2 \
    @PUSHHW \
    @ForIA2B %0_Index 0 32 \
       @PUSH PromotionArray \
       @ADDI %0_Index \
       @PUSHS \
       @PUSHHW \
    @NextBy %0_Index 2


M RESTOREBORD @JMP %0_LocJmp :%0_Index 0 :%0_LocJmp \
    @ForIA2B %0_Index 30 -2 \
       @POPHW \
       @PUSH PromotionArray \
       @ADDI %0_Index \
       @POPS \
    @NextBy %0_Index -2 \
    @POPHW \
    @POPI CastleArray+2 \
    @POPHW \
    @POPI CastleArray \
    @POPHW \
    @POPI EnPassantPiece \
    @POPHW \
    @POPI EnPassantSquare \
    @POPHW \
    @POPI ActiveColor \
    @ForIA2B %0_Index 30 -2 \
       @POPHW \
       @PUSH PiecesArray \
       @ADDI %0_Index \
       @POPS \
    @NextBy %0_Index -2

M DUMPBORD @JMP %0_LocJmp :%0_Index 0 :%0_LocJmp \
    @ForIA2B %0_Index 30 -2 \
       @POPHW \
       @POPNULL \
    @NextBy %0_Index -2 \
    @POPNULL \
    @POPNULL \
    @POPNULL \
    @POPNULL \
    @POPNULL \
    @ForIA2B %0_Index 30 -2 \
       @POPHW \
       @POPNULL \
    @NextBy %0_Index -2





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
      @STOREBII Address

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
      @STOREBII Address

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
   @MA2V   1 WRook
   @MA2V   3 WBishop
   @MA2V   5 WKnight
   @MA2V  15 WQueen
   @MA2V  17 BRook
   @MA2V  19 BBishop
   @MA2V  21 BKnight
   @MA2V  23 BPawn
   @MA2V  31 BQueen
   # Initlize promotion overrides
   @ForIA2B Index1 0 32
      @PUSH PromotionArray
      @ADDI Index1
      @POPI Address
      @PUSH 0
      @STOREBII Address
   @Next Index1
   # Initlize Castleing Flags
   @Call(A) CastleSetValid WhiteColor
   @Call(A) CastleSetValid BlackColor
   @MA2V MoveInvalid EnPassantSquare
   @MA2V MoveInvalid EnPassantPiece
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

   @PUSH PiecesArray
   @ADDI PieceIndex
   @POPI Address

   @STOREBII Address
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
      @POPI PTemp
      @LOADBII PTemp
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
                         @Call(VV) SquareXYtoSqr TestX TestY
                         @POPI TargetSquare
                         @IF_EQ_VV TargetSquare EnPassantSquare
                            @Call(VVAV) CandidatePack TestX TestY 1 EnPassantPiece
                            @INCI CandidateCount
                         @ENDIF
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
   @Local Address
   @Local PromotionType

   @POPI PIndex
   @MA2V PieceInvalid PType

   @PUSHI PIndex
   @IF_ULE_A 31
      @POPNULL
   @ELSE
      @POPNULL
      @JMP GPTExitNoPop
   @ENDIF

   @PUSH PromotionArray
   @ADDI PIndex
   @POPI Address
   @LOADBII Address
   @AND 0xff
   @POPI PromotionType
   @PUSHI PromotionType
   @IF_NOTZERO
      @POPNULL
      @MV2V PromotionType PType
      @JMP GPTExitNoPop
   @ELSE
      @POPNULL
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
:GPTExitNoPop
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
    @Local PieceType
    @Local CaptPieceColor
    @Local SourceX
    @Local SourceY
    @Local CaptureX
    @Local CaptureY
    @Local TargetSquare

    @POPI2 Candidate PieceIndex

    @Call(V) GetPieceInfo PieceIndex
    @POPI2 SourceY SourceX
    @POPI2 PieceColor PieceAlive
    @POPNULL                         # Don't need square

    @Call(V) CandidateUnpack Candidate
    @POPI4 CapPieceIndex CaptFlag TargetY TargetX

    # Handle Capture

    @IF_EQ_AV 1 CaptFlag
       @Call(V) GetPieceInfo CapPieceIndex
       @POPI4 CaptureY CaptureX CaptPieceColor PieceAlive
       @POPNULL               # Original square no longer matters

       # If Captured piece is original Rook it can't castle after capture.
       @Call(VV) CastleInvalidRook CapPieceIndex CaptPieceColor
       # Mark as dead.
       @Call(VAVVV) SetPieceInfo CapPieceIndex 0 CaptPieceColor CaptureX CaptureY
    @ENDIF

    # Makes sure if we move King or Rook invalidate Castling
    @Call(V) GetPieceType PieceIndex
    @POPI PieceType

    @IF_EQ_AV PieceKing PieceType
       @Call(V) CastleInvalidKing PieceColor
    @ENDIF

    # Safe to call always as only does something if piece is original rook.
    @Call(VV) CastleInvalidRook PieceIndex PieceColor


    # En passant is available only immediately after a pawn double move.
    @MA2V MoveInvalid EnPassantSquare
    @MA2V MoveInvalid EnPassantPiece
    @IF_EQ_AV PiecePawn PieceType
       @IF_EQ_AV WhiteColor PieceColor
          @IF_EQ_AV 1 SourceY
             @IF_EQ_AV 3 TargetY
                @Call(VA) SquareXYtoSqr TargetX 2
                @POPI EnPassantSquare
                @MV2V PieceIndex EnPassantPiece
             @ENDIF
          @ENDIF
       @ELSE
          @IF_EQ_AV 6 SourceY
             @IF_EQ_AV 4 TargetY
                @Call(VA) SquareXYtoSqr TargetX 5
                @POPI EnPassantSquare
                @MV2V PieceIndex EnPassantPiece
             @ENDIF
          @ENDIF
       @ENDIF
    @ENDIF

    @Call(VVVVV) SetPieceInfo PieceIndex PieceAlive PieceColor TargetX TargetY
@EndLocals
@POPRETURN
@RET


#######################################
# PromotePiece(PieceIndex, Promotion):void
:PromotePiece
@PUSHRETURN
@Locals
    @Local PieceIndex
    @Local Promotion
    @Local PieceType
    @Local PieceAlive
    @Local PieceColor
    @Local PieceX
    @Local PieceY
    @Local PieceSquare
    @Local NewPieceType
    @Local Address

    @POPI2 Promotion PieceIndex

    @Call(V) GetPieceType PieceIndex
    @POPI PieceType
    @IF_NEQ_AV PiecePawn PieceType
       @JMP PPExit
    @ENDIF

    @Call(V) GetPieceInfo PieceIndex
    @POPI5 PieceY PieceX PieceColor PieceAlive PieceSquare

    @IF_EQ_AV 0 PieceAlive
       @JMP PPExit
    @ENDIF

    @IF_EQ_AV WhiteColor PieceColor
       @IF_NEQ_AV 7 PieceY
          @JMP PPExit
       @ENDIF
    @ELSE
       @IF_NEQ_AV 0 PieceY
          @JMP PPExit
       @ENDIF
    @ENDIF

    @PUSHI Promotion
    @SWITCH
    @CASE PromotionKnight
       @POPNULL
       @MA2V PieceKnight NewPieceType
       @CBREAK
    @CASE PromotionRook
       @POPNULL
       @MA2V PieceRook NewPieceType
       @CBREAK
    @CASE PromotionBishop
       @POPNULL
       @MA2V PieceBishop NewPieceType
       @CBREAK
    @CDEFAULT
       @POPNULL
       @MA2V PieceQueen NewPieceType
       @CBREAK
    @ENDCASE

    @PUSH PromotionArray
    @ADDI PieceIndex
    @POPI Address
    @PUSHI NewPieceType
    @STOREBII Address
:PPExit
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
    @Local PieceType
    @Local EPX
    @Local EPY

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
             @Call(V) GetPieceType PieceIndex
             @POPI PieceType
             @Call(V) GetPieceInfo PieceIndex
             @POPNULL @POPNULL
             @POPI PieceColor
             @POPNULL @POPNULL
             @Call(VV) PieceToString PieceType PieceColor
             @POPI PieceString
             @PRTSI PieceString
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
   @IF_NEQ_AV MoveInvalid EnPassantSquare
      @Call(V) SquareSqrtoXY EnPassantSquare
      @POPI2 EPY EPX
      @PRT "En passant active: target X,Y "
      @PRTI EPX
      @PRT ","
      @PRTI EPY
      @PRT "; captured pawn index "
      @PRTI EnPassantPiece
      @PRTNL
   @ENDIF
@EndLocals
@POPRETURN
@RET
##################################
# UserMovePossible(PieceIndex, TargetX, TargetY)
:UserMovePossible
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
      @JMP UMPExit
   @ENDIF
   @POPNULL

   @Call(V) GetPieceInfo PieceIndex
   @POPNULL @POPNULL   # Do not need duplicate X and Y
   @POPI2 StartColor StartAlive
   @POPNULL # Dont need square

   @IF_EQ_AV 0 StartAlive
      # Player tried to move dead piece.
      @JMP UMPExit
   @ENDIF
   @IF_NEQ_VV ActiveColor StartColor
      # Player tried to move piece he didn't own.
      @JMP UMPExit
   @ENDIF
   @ForIA2B DepthIndex 1 8
      @Call(VV) ValidMoves PieceIndex DepthIndex
      @POPI Count
      @IF_EQ_AV 0 Count
         @JMP UMPExit
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
      @IF_NEQ_VA Result MoveInvalid
         # Requested destination found at this depth
         @JMP UMPExit
      @ENDIF
   @Next DepthIndex
:UMPExit
   @PUSHI Result
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
      @IF_NEQ_VA Result MoveInvalid
         # Requested destination found at this depth
         @JMP UMVExit
      @ENDIF
   @Next DepthIndex
:UMVExit
   @IF_NEQ_AV MoveInvalid Result
      # Lastly check if move puts king into check
      # First simulate the move, then look for Check
      @SAVEBOARD
      @Call(VV) MovePiece PieceIndex Result
      @Call(V) KingCheck ActiveColor
      @RESTOREBORD
      @IF_NOTZERO
         @MA2V MoveInvalid Result
      @ENDIF
      @POPNULL
   @ENDIF
   @PUSHI Result
@EndLocals
@POPRETURN
@RET



####################################
# PieceToString(PieceType,Color):StrPtr
:PieceToString
@PUSHRETURN
@Locals
   @Local PieceType
   @Local Color


   @POPI2 Color PieceType

   @PUSHI PieceType
   @SWITCH
   @CASE PieceKing
      @POPNULL
      @PUSH "K\0"
      @CBREAK
   @CASE PieceQueen
      @POPNULL
      @PUSH "Q\0"
      @CBREAK
   @CASE PieceRook
      @POPNULL
      @PUSH "R\0"
      @CBREAK
   @CASE PieceBishop
      @POPNULL
      @PUSH "B\0"
      @CBREAK
   @CASE PieceKnight
      @POPNULL
      @PUSH "N\0"
      @CBREAK
   @CASE PiecePawn
      @POPNULL
      @PUSH "P\0"
      @CBREAK
   @CDEFAULT
      @POPNULL
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
#
# Returns:
#
# Normal move:
#
#   Bits  0-2  From X
#   Bits  3-5  From Y
#   Bits  6-8  To X
#   Bits  9-11 To Y
#   Bits 12-13 Promotion
#
# Promotion:
#
#   0 = Bishop
#   1 = Queen, also used as the default when no suffix is supplied
#   2 = Knight
#   3 = Rook
#
# Single-character commands return their character value.
#
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
   @Local Promotion

   @Call(VA) HeapNewObject MainHeap 255
   @IF_ULT_A 100
      @PRTLN "Error, out of memory."
      @END
   @ENDIF
   @PUSH 0
   @POPII InputStr    # Null out any previous string.
   @POPI InputStr

   @PRT ") "
   @READSI InputStr

   @Call(V) strlen InputStr
   @IF_ZERO
      @POPNULL
      @PRTLN "No entry."
      @JMP RCCErrExit
   @ELSE
      @PRT "c:" @PRTHEXI InputStr @PRT "(" @PRTSI InputStr @PRT ")" @PRTNL
      @POPI StrLen
   @ENDIF


   ##################################
   # Single character commands
   ##################################

   @IF_EQ_AV 1 StrLen

      @MA2V 0 Index1

      @PUSHI InputStr
      @ADDI Index1
      @PUSHS
      @AND 0xff

      @SWITCH
      @CASE "q\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CASE "p\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CASE "s\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CASE "l\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CASE "r\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CASE "b\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CASE "B\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CASE "?\0"
         @POPI Value01
         @JMP RCCCmdExit
         @CBREAK

      @CDEFAULT
         @POPNULL
         @PRTLN "Syntax Error"
         @JMP RCCErrExit
         @CBREAK
      @ENDCASE
   @ENDIF

   ##################################
   # Suggest command with explicit depth: ?1 through ?9
   ##################################

   @IF_EQ_AV 2 StrLen
      @MA2V 0 Index1
      @PUSHI InputStr
      @ADDI Index1
      @PUSHS
      @AND 0xff
      @IF_EQ_A "?\0"
         @POPNULL
         @INCI Index1
         @PUSHI InputStr
         @ADDI Index1
         @PUSHS
         @AND 0xff
         @IF_INRANGE_AB "1\0" "9\0"
            @SUB "0\0"
            @SHLN SuggestMoveDepthShift
            @OR "?\0"
            @POPI Value01
            @JMP RCCCmdExit
         @ELSE
            @POPNULL
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF


   ##################################
   # Must now be either:
   #
   #   a2a4
   #   c7c8q
   ##################################

   @IF_NEQ_AV 4 StrLen
      @IF_NEQ_AV 5 StrLen
         @PRT "Syntax Error"
         @JMP RCCErrExit
      @ENDIF
   @ENDIF

   @MA2V PromotionQueen Promotion


   ##################################
   # Character 0 - From file
   ##################################

   @MA2V 0 Index1

   @PUSHI InputStr
   @ADDI Index1
   @PUSHS
   @AND 0xff

   @IF_INRANGE_AB "a\0" "h\0"
      @SUB "a\0"
      @POPI Value01
   @ELSE
      @PRT "Syntax Error"
      @JMP RCCErrExit
   @ENDIF


   ##################################
   # Character 1 - From rank
   ##################################

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


   ##################################
   # Character 2 - To file
   ##################################

   @INCI Index1

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


   ##################################
   # Character 3 - To rank
   ##################################

   @INCI Index1

   @PUSHI InputStr
   @ADDI Index1
   @PUSHS
   @AND 0xff

   @IF_INRANGE_AB "1\0" "8\0"
      @SUB "1\0"
      @POPI Value04
   @ELSE
      @PRT "Syntax Error"
      @JMP RCCErrExit
   @ENDIF


   ##################################
   # Character 4 - Promotion
   #
   # Only present for length 5.
   ##################################

   @IF_NEQ_AV 5 StrLen
      @JMP RCCPackMove
   @ENDIF

   @INCI Index1

   @PUSHI InputStr
   @ADDI Index1
   @PUSHS
   @AND 0xff

   @SWITCH
   @CASE "q\0"
      @POPNULL
      @MA2V PromotionQueen Promotion
      @CBREAK

   @CASE "n\0"
      @POPNULL
      @MA2V PromotionKnight Promotion
      @CBREAK

   @CASE "r\0"
      @POPNULL
      @MA2V PromotionRook Promotion
      @CBREAK

   @CASE "b\0"
      @POPNULL
      @MA2V PromotionBishop Promotion
      @CBREAK

   @CDEFAULT
      @POPNULL
      @PRT "Syntax Error"
      @JMP RCCErrExit
      @CBREAK
   @ENDCASE


   ##################################
   # Pack move
   ##################################

   :RCCPackMove

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

   @PUSHI Promotion
   @AND 0x3
   @SHLN 12
   @ORS

   @POPI Value01
   @JMP RCCCmdExit


   ##################################
   # Error
   ##################################

   :RCCErrExit
   @MA2V MoveInvalid Value01


   ##################################
   # Return
   ##################################

   :RCCCmdExit
   @PUSHI Value01

   @Call(VV) HeapDeleteObject MainHeap InputStr
   @IF_UGT_A 0
      @PRT "Memory Error"
      @END
   @ENDIF
   @POPNULL

@EndLocals
@POPRETURN
@RET


#########################################
# KingCheck(Color):1|0
# Returns 1 if Color's king is currently attacked.
:KingCheck
@PUSHRETURN
@Locals
   @Local MyColor
   @Local MyKingIndex
   @Local MyKingX
   @Local MyKingY

   @Local EnemyBase
   @Local EnemyPieceIndex
   @Local EnemyAlive

   @Local Index1
   @Local Index2
   @Local Depth
   @Local Count
   @Local Candidate
   @Local CandidateX
   @Local CandidateY
   @Local KCVoid
   @Local Result

   @POPI MyColor
   @MA2V 0 Result

   # Determine king and enemy piece ranges.
   @IF_EQ_AV WhiteColor MyColor
      @MA2V 0  MyKingIndex
      @MA2V 16 EnemyBase
   @ELSE
      @MA2V 16 MyKingIndex
      @MA2V 0  EnemyBase
   @ENDIF

   # Locate our king.
   @Call(V) GetPieceInfo MyKingIndex
   @POPI MyKingY
   @POPI MyKingX
   @POPNULL
   @POPI KCVoid
   @POPNULL

   # Scan all 16 enemy pieces.
   @ForIA2B Index1 0 16

      @PUSHI EnemyBase
      @ADDI Index1
      @POPI EnemyPieceIndex

      # Ignore captured enemy pieces.
      @Call(V) GetPieceInfo EnemyPieceIndex
      @POPNULL @POPNULL     # Y,X
      @POPNULL              # Color
      @POPI EnemyAlive
      @POPNULL              # Square

      @IF_NEQ_AV 0 EnemyAlive

         @ForIA2B Depth 1 8

            @Call(VV) ValidMoves EnemyPieceIndex Depth
            @POPI Count

            @IF_EQ_AV 0 Count
               @FORBREAK
            @ENDIF

            @ForIA2V Index2 0 Count
               @POPI Candidate

               @Call(V) CandidateUnpack Candidate
               @POPI4 KCVoid KCVoid CandidateY CandidateX

               @IF_EQ_VV CandidateX MyKingX
                  @IF_EQ_VV CandidateY MyKingY
                     @MA2V 1 Result
                  @ENDIF
               @ENDIF
            @Next Index2

            # We deliberately drain all returned candidates
            # before exiting.
            @IF_EQ_AV 1 Result
               @JMP KCExit
            @ENDIF

         @Next Depth
      @ENDIF

   @Next Index1

:KCExit
   @PUSHI Result

@EndLocals
@POPRETURN
@RET



#########################################
# HasLegalMove(Color):1|0
# Returns 1 if Color has at least one legal move.
:HasLegalMove
@PUSHRETURN
@Locals
   @Local Color
   @Local OldActiveColor
   @Local PieceBase
   @Local PieceIndex
   @Local PieceAlive
   @Local Index1
   @Local Index2
   @Local Depth
   @Local Count
   @Local Candidate
   @Local InCheck
   @Local Result

   @POPI Color
   @MV2V ActiveColor OldActiveColor
   @MV2V Color ActiveColor
   @MA2V 0 Result

   @IF_EQ_AV WhiteColor Color
      @MA2V 0 PieceBase
   @ELSE
      @MA2V 16 PieceBase
   @ENDIF

   @ForIA2B Index1 0 16
      @PUSHI PieceBase
      @ADDI Index1
      @POPI PieceIndex

      @Call(V) GetPieceInfo PieceIndex
      @POPNULL @POPNULL
      @POPNULL
      @POPI PieceAlive
      @POPNULL

      @IF_NEQ_AV 0 PieceAlive
         @ForIA2B Depth 1 8
            @Call(VV) ValidMoves PieceIndex Depth
            @POPI Count
            @IF_EQ_AV 0 Count
               @FORBREAK
            @ENDIF

            @ForIA2V Index2 0 Count
               @POPI Candidate
               @IF_EQ_AV 0 Result
                  @SAVEBOARD
                  @Call(VV) MovePiece PieceIndex Candidate
                  @Call(V) KingCheck Color
                  @POPI InCheck
                  @RESTOREBORD
                  @IF_EQ_AV 0 InCheck
                     @MA2V 1 Result
                  @ENDIF
               @ENDIF
            @Next Index2

            @IF_EQ_AV 1 Result
               @FORBREAK
            @ENDIF
         @Next Depth
      @ENDIF

      @IF_EQ_AV 1 Result
         @FORBREAK
      @ENDIF
   @Next Index1

   @IF_EQ_AV 0 Result
      # Castling is not produced by ValidMoves, so test each castle command.
      @Call(A) CastleMoveValid 0x0184
      @POPI InCheck
      @IF_NEQ_AV MoveInvalid InCheck
         @POPI5 InCheck InCheck InCheck InCheck InCheck
         @MA2V 1 Result
      @ENDIF
   @ENDIF
   @IF_EQ_AV 0 Result
      @Call(A) CastleMoveValid 0x0084
      @POPI InCheck
      @IF_NEQ_AV MoveInvalid InCheck
         @POPI5 InCheck InCheck InCheck InCheck InCheck
         @MA2V 1 Result
      @ENDIF
   @ENDIF
   @IF_EQ_AV 0 Result
      @Call(A) CastleMoveValid 0x0fbc
      @POPI InCheck
      @IF_NEQ_AV MoveInvalid InCheck
         @POPI5 InCheck InCheck InCheck InCheck InCheck
         @MA2V 1 Result
      @ENDIF
   @ENDIF
   @IF_EQ_AV 0 Result
      @Call(A) CastleMoveValid 0x0ebc
      @POPI InCheck
      @IF_NEQ_AV MoveInvalid InCheck
         @POPI5 InCheck InCheck InCheck InCheck InCheck
         @MA2V 1 Result
      @ENDIF
   @ENDIF

:HLMExit
   @MV2V OldActiveColor ActiveColor
   @PUSHI Result
@EndLocals
@POPRETURN
@RET

#########################################
# ReportGameState(Color):void
# Prints check/checkmate/stalemate status for Color.
:ReportGameState
@PUSHRETURN
@Locals
   @Local Color
   @Local InCheck
   @Local HasMove

   @POPI Color
   @Call(V) KingCheck Color
   @POPI InCheck
   @Call(V) HasLegalMove Color
   @POPI HasMove

   @IF_EQ_AV 0 HasMove
      @IF_EQ_AV 0 InCheck
         @PRTLN "Stalemate."
      @ELSE
         @PRTLN "Checkmate."
      @ENDIF
   @ELSE
      @IF_NEQ_AV 0 InCheck
         @PRTLN "Check."
      @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET


#########################################
# SuggestMove(Color, SearchDepth):(Result, PieceIndex, Candidate, Score)
# Recursive material scorer. Captures score as captured piece value;
# quiet legal moves score 0. Deeper searches subtract the opponent's best reply.
:SuggestMove
@PUSHRETURN
@Locals
   @Local Color
   @Local SearchDepth
   @Local OppColor
   @Local FramePtr
   @Local PieceBase
   @Local PieceIndex
   @Local PieceAlive
   @Local Index1
   @Local Index2
   @Local Depth
   @Local Count
   @Local Candidate
   @Local CaptFlag
   @Local CapPieceIndex
   @Local InCheck
   @Local ReturnResult
   @Local ReturnScore

   @POPI2 SearchDepth Color
   @MA2V SuggestMoveNoMove ReturnResult
   @MA2V 0 ReturnScore
   @MA2V 0 FramePtr
   @Call(VA) HeapNewObject MainHeap SMFrameSize
   @POPI FramePtr
   @PUSHI FramePtr
   @IF_ULT_A 100
      @POPNULL
      @MA2V MoveInvalid PieceIndex
      @MA2V MoveInvalid Candidate
      @JMP SMReturn
   @ENDIF
   @POPNULL

   @SM_FILL_A FramePtr SMFrameBestScore 0
   @SM_FILL_A FramePtr SMFrameBestPieceIndex MoveInvalid
   @SM_FILL_A FramePtr SMFrameBestCandidate MoveInvalid

   @IF_EQ_AV WhiteColor Color
      @MA2V 0 PieceBase
      @MA2V BlackColor OppColor
   @ELSE
      @MA2V 16 PieceBase
      @MA2V WhiteColor OppColor
   @ENDIF

   @ForIA2B Index1 0 16
      @PUSHI PieceBase
      @ADDI Index1
      @POPI PieceIndex

      @Call(V) GetPieceInfo PieceIndex
      @POPNULL @POPNULL
      @POPNULL
      @POPI PieceAlive
      @POPNULL

      @IF_NEQ_AV 0 PieceAlive
         @ForIA2B Depth 1 8
            @Call(VV) ValidMoves PieceIndex Depth
            @POPI Count
            @IF_EQ_AV 0 Count
               @FORBREAK
            @ENDIF

            @ForIA2V Index2 0 Count
               @POPI Candidate
               @SAVEBOARD
               @Call(VV) MovePiece PieceIndex Candidate
               @Call(V) KingCheck Color
               @POPI InCheck

               @IF_EQ_AV 0 InCheck
                  @Call(V) CandidateUnpack Candidate
                  @POPI4 CapPieceIndex CaptFlag Temp02 Temp01
                  @SM_FILL_A FramePtr SMFrameMoveScore 0
                  @IF_EQ_AV 1 CaptFlag
                     @Call(V) GetPieceType CapPieceIndex
                     @SM_FILL_S FramePtr SMFrameMoveScore
                  @ENDIF
                  @PUSHI SearchDepth
                  @IF_GT_A 1
                     @POPNULL
                     @PUSHI SearchDepth
                     @SUB 1
                     @POPI Temp01
                     @Call(VV) SuggestMove OppColor Temp01
                     @POPI Temp02
                     @POPNULL
                     @POPNULL
                     @POPI Temp01
                     @SM_FILL_V FramePtr SMFrameReplyScore Temp02
                     @SM_FILL_V FramePtr SMFrameReplyResult Temp01
                     @SM_GET FramePtr SMFrameReplyResult
                     @IF_EQ_A SuggestMoveOK
                        @POPNULL
                        @SM_GET FramePtr SMFrameMoveScore
                        @SM_GET FramePtr SMFrameReplyScore
                        @POPI Temp01
                        @SUBI Temp01
                        @SM_FILL_S FramePtr SMFrameMoveScore
                     @ELSE
                        @POPNULL
                     @ENDIF
                  @ELSE
                     @POPNULL
                  @ENDIF
                  @SM_GET FramePtr SMFrameBestPieceIndex
                  @IF_EQ_A MoveInvalid
                     @POPNULL
                     @SM_GET FramePtr SMFrameMoveScore
                     @SM_FILL_S FramePtr SMFrameBestScore
                     @SM_FILL_V FramePtr SMFrameBestPieceIndex PieceIndex
                     @SM_FILL_V FramePtr SMFrameBestCandidate Candidate
                  @ELSE
                     @POPNULL
                     @SM_GET FramePtr SMFrameBestScore
                     @POPI Temp01
                     @SM_GET FramePtr SMFrameMoveScore
                     @IF_GT_V Temp01
                        @POPNULL
                        @SM_GET FramePtr SMFrameMoveScore
                        @SM_FILL_S FramePtr SMFrameBestScore
                        @SM_FILL_V FramePtr SMFrameBestPieceIndex PieceIndex
                        @SM_FILL_V FramePtr SMFrameBestCandidate Candidate
                     @ELSE
                        @POPNULL
                     @ENDIF
                  @ENDIF
               @ENDIF
               @RESTOREBORD
            @Next Index2
         @Next Depth
      @ENDIF
   @Next Index1

   @SM_GET FramePtr SMFrameBestPieceIndex
   @IF_EQ_A MoveInvalid
      @POPNULL
      @MA2V SuggestMoveNoMove ReturnResult
      @MA2V MoveInvalid PieceIndex
      @MA2V MoveInvalid Candidate
      @MA2V 0 ReturnScore
   @ELSE
      @POPNULL
      @MA2V SuggestMoveOK ReturnResult
      @SM_GET FramePtr SMFrameBestScore
      @POPI ReturnScore
      @SM_GET FramePtr SMFrameBestCandidate
      @POPI Candidate
      @SM_GET FramePtr SMFrameBestPieceIndex
      @POPI PieceIndex
   @ENDIF

:SMReturn
   @PUSHI FramePtr
   @IF_UGE_A 100
      @POPNULL
      @Call(VV) HeapDeleteObject MainHeap FramePtr
      @POPNULL
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI ReturnResult
   @PUSHI PieceIndex
   @PUSHI Candidate
   @PUSHI ReturnScore
:SMExit
@EndLocals
@POPRETURN
@RET

#########################################
# PrintSuggestedMove(Result, PieceIndex, Candidate, Score):void
:PrintSuggestedMove
@PUSHRETURN
@Locals
   @Local Result
   @Local PieceIndex
   @Local Candidate
   @Local Score
   @Local PieceX
   @Local PieceY
   @Local CandidateX
   @Local CandidateY
   @Local CaptFlag
   @Local CapPieceIndex

   @POPI4 Score Candidate PieceIndex Result

   @IF_NEQ_AV SuggestMoveOK Result
      @PRTLN "No legal move found."
   @ELSE
      @Call(V) GetPieceInfo PieceIndex
      @POPI2 PieceY PieceX
      @POPNULL @POPNULL @POPNULL
      @Call(V) CandidateUnpack Candidate
      @POPI4 CapPieceIndex CaptFlag CandidateY CandidateX

      @PRT "Best move: "
      @PUSHI PieceX
      @ADD "a\0"
      @POPI Temp01
      @PRTCHI Temp01
      @PUSHI PieceY
      @ADD 1
      @PRTTOP
      @POPNULL
      @PUSHI CandidateX
      @ADD "a\0"
      @POPI Temp01
      @PRTCHI Temp01
      @PUSHI CandidateY
      @ADD 1
      @PRTTOP
      @POPNULL
      @PRT " value "
      @PRTI Score
      @PRTNL
   @ENDIF
@EndLocals
@POPRETURN
@RET

M InvertPlayer  @IF_EQ_AV WhiteColor ActiveColor \
                 @MA2V BlackColor ActiveColor \
               @ELSE \
                 @MA2V WhiteColor ActiveColor \
               @ENDIF
########################################
# Castling logic tests tools
########################################
# CastleArray = 4 byte/2 word array, word 0 is white state, 1 is black
# Bits
# FEDCBA9876543210  < For readability bit order is reversed
# xxxvrrrrrVRRRRRK
# Bit 0: True if King can still Castle
# Bits 6, C: True if Rook 1 or Rook 2 can Castle
# Bits 1-5 and 7-b are PieceID of Rook 1 and 2
# xxx are reserved
# Clear King Valid             0xfffe
# Clear Rook1 Valid            0xffbf
# Clear Rook2 Valid            0xefff
# Clear Rook1 Index            0xffc1
# Clear Rook2 Index            0xf07f
########################################
# CastleSetValid(Color)
:CastleSetValid
@PUSHRETURN
@Locals
   @Local Color
   @Local CastlePtr
   @Local ColorOffset

   @POPI Color

   @PUSHI Color
   @SHLN 4
   @POPI ColorOffset

   @PUSH CastleArray
   @ADDI Color
   @ADDI Color
   @POPI CastlePtr

   @PUSH 0x1041   # Set 'V/v' and K to true bit 12, 6 and 0
   # Calculate Rook Pieces R1 will go to bits 1-5
   @PUSHI WRook
   @ADDI ColorOffset
   @AND 0x1f
   @SHL
   @ORS
   # Calcualte Rook Pieces R2 will go to bits 7-b
   @PUSHI WRook
   @ADDI ColorOffset
   @ADD 1
   @AND 0x1f
   @SHLN 7
   @ORS
   #
   # Save result in array
   @POPII CastlePtr
@EndLocals
@POPRETURN
@RET

########################################
# CastleInvalidKing(Color)
:CastleInvalidKing
@PUSHRETURN
@Locals
   @Local Color
   @Local CastlePtr

   @POPI Color

   @PUSH CastleArray
   @ADDI Color
   @ADDI Color
   @POPI CastlePtr

   @PUSHII CastlePtr
   @AND 0xfffe
   @POPII CastlePtr

@EndLocals
@POPRETURN
@RET

########################################
# CastleInvalidRook(PieceIndex, Color)
#
# If PieceIndex is one of this color's
# original castling rooks, clear that
# rook's castling-valid bit.
########################################
:CastleInvalidRook
@PUSHRETURN
@Locals
   @Local RookIndex
   @Local Color
   @Local CastlePtr

   @POPI2 Color RookIndex

   @PUSH CastleArray
   @ADDI Color
   @ADDI Color
   @POPI CastlePtr

   ####################################
   # Check Rook 1
   # PieceIndex stored in bits 1-5
   ####################################

   @PUSHII CastlePtr
   @SHR
   @AND 0x1f

   @IF_EQ_V RookIndex
      @POPNULL

      @PUSHII CastlePtr
      @AND 0xffbf          # Clear bit 6
      @POPII CastlePtr

      @JMP CIRExit
   @ELSE
      @POPNULL
   @ENDIF

   ####################################
   # Check Rook 2
   # PieceIndex stored in bits 7-11
   ####################################

   @PUSHII CastlePtr
   @SHRN 7
   @AND 0x1f

   @IF_EQ_V RookIndex
      @POPNULL

      @PUSHII CastlePtr
      @AND 0xefff          # Clear bit 12
      @POPII CastlePtr
   @ELSE
      @POPNULL
   @ENDIF

   :CIRExit

@EndLocals
@POPRETURN
@RET



########################################
# CastleTestRook(PieceIndex, Color):(0|1)
# 0 Castling not legal, 1 is legal
:CastleTestRook
@PUSHRETURN
@Locals
   @Local RookIndex
   @Local Color
   @Local CastlePtr
   @Local Result

   @POPI2 Color RookIndex
   @MA2V 0 Result

   @PUSH CastleArray
   @ADDI Color
   @ADDI Color
   @POPI CastlePtr


   ##########################
   # Check Rook 1
   # PieceIndex stored in bits 1-5
   @PUSHII CastlePtr
   @SHR
   @AND 0x1f
   @IF_EQ_V RookIndex
      @PUSHII CastlePtr
      @AND 0x40
      @IF_NOTZERO
         @MA2V 1 Result
      @ENDIF
      @POPNULL
   @ENDIF
   @POPNULL
   #########################
   # Check Rook 2
   # PieceInfor Stored in bits 7-11
   @PUSHII CastlePtr
   @SHRN 7
   @AND 0x1f

   @IF_EQ_V RookIndex
      @PUSHII CastlePtr
      @AND 0x1000
      @IF_NOTZERO
         @MA2V 1 Result
      @ENDIF
      @POPNULL
   @ENDIF
   @POPNULL
   @PUSHI Result
@EndLocals
@POPRETURN
@RET
#######################################
# CastleTestKing(Color):(0|1)
:CastleTestKing
@PUSHRETURN
@Locals
   @Local Color
   @Local CastlePtr

   @POPI Color

   @PUSH CastleArray
   @ADDI Color
   @ADDI Color
   @POPI CastlePtr

   @PUSHII CastlePtr
   @AND 0x0001

@EndLocals
@POPRETURN
@RET

########################################
# CastleUpdateRook(OldPieceIndex,NewPieceIndex,Color)
:CastleUpdateRook
@PUSHRETURN
@Locals
   @Local NewIndex
   @Local RookIndex
   @Local Color
   @Local CastlePtr
   @Local Result

   @POPI2 Color NewIndex RookIndex

   @PUSH CastleArray
   @ADDI Color
   @ADDI Color
   @POPI CastlePtr


   ##########################
   # Check Rook 1
   # PieceIndex stored in bits 1-5
   @PUSHII CastlePtr
   @SHR
   @AND 0x1f
   @IF_EQ_V RookIndex
      @POPNULL
      @PUSHII CastlePtr
      @AND 0xffc1
      @PUSHI NewIndex
      @AND 0x1f
      @SHL
      @ORS
      @POPII CastlePtr
   @ELSE
      @POPNULL
   @ENDIF
   ##########################
   # Check Rook 2
   # PieceIndex stored in bits 7-11
   @PUSHII CastlePtr
   @SHRN 7
   @AND 0x1f
   @IF_EQ_V RookIndex
      @POPNULL
      @PUSHII CastlePtr
      @AND 0xf07f
      @PUSHI NewIndex
      @AND 0x1f
      @SHLN 7
      @ORS
      @POPII CastlePtr
   @ELSE
      @POPNULL
   @ENDIF
@EndLocals
@POPRETURN
@RET

########################################
# CastleMove(KingPiece,RookPiece,
#            KingDestX,RookDestX,KingY)
#
# Executes an already validated castle.
#
# Does no legality checking.
########################################
:CastleMove
@PUSHRETURN
@Locals
   @Local KingPiece
   @Local RookPiece
   @Local KingDestX
   @Local RookDestX
   @Local KingY
   @Local Candidate

   @POPI5 KingY RookDestX KingDestX RookPiece KingPiece

   #####################################
   # Move King
   #####################################

   @Call(VVAA) CandidatePack KingDestX KingY 0 0
   @POPI Candidate

   @Call(VV) MovePiece KingPiece Candidate


   #####################################
   # Move Rook
   #####################################

   @Call(VVAA) CandidatePack RookDestX KingY 0 0
   @POPI Candidate

   @Call(VV) MovePiece RookPiece Candidate

@EndLocals
@POPRETURN
@RET

####################################
# CastleMoveTest(CmdMode):(0|1)
#
:CastleMoveTest
@PUSHRETURN
@Locals
   @Local CmdMode
   @Local Result

   @POPI CmdMode
   @MA2V 0 Result

   @PUSHI CmdMode
   @SWITCH
   @CASE 0x0184        # e1g1
      @MA2V 1 Result
      @CBREAK
   @CASE 0x84          # e1c1
      @MA2V 1 Result
      @CBREAK
   @CASE 0x0fbc        # e8g8
      @MA2V 1 Result
      @CBREAK
   @CASE 0x0ebc        # e8c8
      @MA2V 1 Result
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL

   @PUSHI Result
@EndLocals
@POPRETURN
@RET
#######################################
# CastleMoveValid(CmdMode):(MoveInvalid | KingPiece,RookPiece,KingDestX,RookDestX,KingY,Result)
#  1. Castle command belongs to ActiveColor
#  2. CastleTestKing(Color) != 0
#  3. King actually exists on e1/e8 and is the correct color/type
#  4. Required intervening squares are empty
#  5. Rook actually exists on h1/a1/h8/a8
#  6. Rook is correct color/type
#  7. CastleTestRook(RookPieceIndex,Color) != 0
#  8. King is not currently in check
#  9. King's transit square is not attacked
#  10. King's destination is not attacked
:CastleMoveValid
@PUSHRETURN
@Locals
   @Local CmdMode
   @Local Color
   @Local KingX
   @Local KingY
   @Local RookX
   @Local RookY
   @Local TestX
   @Local RookPiece
   @Local KingPiece
   @Local Result
   @Local KingDir
   @Local Candidate
   @Local KingDestX
   @Local RookDestX
   @Local PieceColor
   @Local PieceAlive

   @POPI CmdMode
   @MA2V MoveInvalid Result
   @MA2V MoveInvalid Color

   # Determine Castle geometry, destinations
   @PUSHI CmdMode
   @SWITCH

   @CASE 0x0184             # e1g1
      @MA2V WhiteColor Color
      @MA2V 4 KingX
      @MA2V 0 KingY
      @MA2V 7 RookX
      @MA2V 0 RookY
      @CBREAK

   @CASE 0x0084             # e1c1
      @MA2V WhiteColor Color
      @MA2V 4 KingX
      @MA2V 0 KingY
      @MA2V 0 RookX
      @MA2V 0 RookY
      @CBREAK

   @CASE 0x0fbc             # e8g8
      @MA2V BlackColor Color
      @MA2V 4 KingX
      @MA2V 7 KingY
      @MA2V 7 RookX
      @MA2V 7 RookY
      @CBREAK

   @CASE 0x0ebc             # e8c8
      @MA2V BlackColor Color
      @MA2V 4 KingX
      @MA2V 7 KingY
      @MA2V 0 RookX
      @MA2V 7 RookY
      @CBREAK

   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL

   # Must be current players color
   @IF_NEQ_VV Color ActiveColor
      @JMP CMVExit
   @ENDIF

   # Has King castled before or moved?
   @Call(V) CastleTestKing Color
   @IF_ZERO
      @POPNULL
      @JMP CMVExit
   @ENDIF
   @POPNULL

   # Make sure it really is a King and not some other piece that just landed in old King spot.
   @Call(VV) CheckBoard KingX KingY
   @POPI KingPiece

   @IF_EQ_AV EmptySquare KingPiece
      @JMP CMVExit
   @ENDIF

   @Call(V) GetPieceType KingPiece
   @IF_NEQ_A PieceKing
      @POPNULL
      @JMP CMVExit
   @ENDIF
   @POPNULL

   @Call(V) GetPieceInfo KingPiece
   @POPNULL @POPNULL
   @POPI2 PieceColor PieceAlive
   @POPNULL
   @IF_NEQ_VV PieceColor Color
      @JMP CMVExit
   @ENDIF

   # Make sure Rook is at legal location
   @Call(VV) CheckBoard RookX RookY
   @POPI RookPiece

   @IF_EQ_AV EmptySquare RookPiece
      @JMP CMVExit
   @ENDIF

   @Call(V) GetPieceType RookPiece
   @IF_NEQ_A PieceRook
      @POPNULL
      @JMP CMVExit
   @ENDIF
   @POPNULL

   @Call(V) GetPieceInfo RookPiece
   @POPNULL @POPNULL
   @POPI2 PieceColor PieceAlive
   @POPNULL
   @IF_NEQ_VV PieceColor Color
      @JMP CMVExit
   @ENDIF

   @Call(VV) CastleTestRook RookPiece Color
   @IF_ZERO
      @POPNULL
      @JMP CMVExit
   @ENDIF
   @POPNULL

   # All squars between rook and king must be empty

   @PUSHI RookX
   @IF_UGT_V KingX
      @MA2V 1 KingDir
   @ELSE
      @MA2V -1 KingDir
   @ENDIF
   @POPNULL

   # Calculate final King and Rook locations
   @PUSHI KingX
   @ADDI KingDir
   @POPI RookDestX

   @PUSHI RookDestX
   @ADDI KingDir
   @POPI KingDestX

   @ForIV2V TestX RookDestX RookX

      @Call(VV) CheckBoard TestX KingY
      @IF_NEQ_A EmptySquare
         # Not Valid just exit.a
         @POPNULL
         @JMP CMVExit
      @ENDIF
      @POPNULL
   @NextByV TestX KingDir
   # Path is Clear test if the move will put king in check
   #
   # 1 King can't be in check currently.
   @Call(V) KingCheck ActiveColor
   @IF_NOTZERO
      @POPNULL
      @JMP CMVExit
   @ENDIF
   @POPNULL
   #
   # 2 The transite square can not be under attack.
   @PUSHI KingX
   @ADDI KingDir
   @POPI TestX
   @SAVEBOARD
   @Call(VVAA) CandidatePack TestX KingY 0 0
   @POPI Candidate
   @Call(VV) MovePiece KingPiece Candidate
   @Call(V) KingCheck ActiveColor
   @RESTOREBORD
   @IF_NOTZERO
      @POPNULL
      @JMP CMVExit
   @ENDIF
   @POPNULL
   # 3 King Can not be left in Check at destination.
   @SAVEBOARD
   @Call(VVVVV) CastleMove KingPiece RookPiece KingDestX RookDestX KingY
   @Call(V) KingCheck ActiveColor
   @RESTOREBORD
   @IF_NOTZERO
      @POPNULL
      @JMP CMVExit
   @ENDIF
   @POPNULL
   # All tests passed, return the geometry needed to execute the castle.

   @MV2V RookPiece Result
   @PUSHI KingPiece
   @PUSHI RookPiece
   @PUSHI KingDestX
   @PUSHI RookDestX
   @PUSHI KingY

:CMVExit
   @PUSHI Result
@EndLocals
@POPRETURN
@RET

#######################################
# CastleMoveTry(CmdMode):(MoveInvalid|RookPieceIndex)
#
# Validates and executes a castle move.
:CastleMoveTry
@PUSHRETURN
@Locals
   @Local CmdMode
   @Local KingPiece
   @Local RookPiece
   @Local KingDestX
   @Local RookDestX
   @Local KingY
   @Local Result

   @POPI CmdMode
   @Call(V) CastleMoveValid CmdMode
   @POPI Result
   @IF_EQ_AV MoveInvalid Result
      @JMP CMTExit
   @ENDIF

   @POPI5 KingY RookDestX KingDestX RookPiece KingPiece
   @Call(VVVVV) CastleMove KingPiece RookPiece KingDestX RookDestX KingY

:CMTExit
   @PUSHI Result
@EndLocals
@POPRETURN
@RET
#########################################
# BoardEditMode(VisualOrder)
# VisualOrder=0 reads rank 1 to rank 8.
# VisualOrder=1 reads rank 8 to rank 1, matching DisplayBoard output.
# Array Data
:PieceNameArray "KQRBNPkqrbnp .\0"
:PieceNameValue
$$PieceKing $$PieceQueen $$PieceRook $$PieceBishop $$PieceKnight $$PiecePawn
$$PieceKing $$PieceQueen $$PieceRook $$PieceBishop $$PieceKnight $$PiecePawn
$$PieceSpace $$PieceSpace
#
:BoardEditMode
@PUSHRETURN
@Locals
   @Local LineIn
   @Local Index1
   @Local XPos
   @Local YPos
   @Local YStep
   @Local VisualOrder
   @Local SearchChar
   @Local SearchIndex
   @Local RepeatInput
   @Local InputColor
   @Local InputPiece

   @POPI VisualOrder

   # Clear the board
   @ForIA2B Index1 0 32
      @PUSH 0
      @PUSH PiecesArray
      @ADDI Index1
      @POPS
   @NextBy Index1 2
   @PUSH 0
   @PUSH CastleArray
   @POPS
   @PUSH 0
   @PUSH CastleArray+2      # We only get away with +2 here as CastleArray is fixed array
   @POPS

   # Setup Input string
   @Call(VA) HeapNewObject MainHeap 255
   @POPI LineIn

   @IF_EQ_AV 1 VisualOrder
      @MA2V 7 YPos
      @MA2V -1 YStep
   @ELSE
      @MA2V 0 YPos
      @MA2V 1 YStep
   @ENDIF
   @ForIA2B Index1 1 9
      @MA2V 1 RepeatInput
      @WHILE_EQ_AV 1 RepeatInput
         @MA2V 1 RepeatInput   # Only successfull parsing will allow moving to next line.
         @READSI LineIn
         @Call(V) strlen LineIn
         @IF_EQ_A 8
            @POPNULL
            # First validate input
            @ForIA2B XPos 0 8
               @PUSHI LineIn
               @ADDI XPos
               @PUSHS
               @AND 0xff
               @POPI SearchChar
               @Call(AV) strfndc PieceNameArray SearchChar
               @IF_ZERO
                  # Invalid characters in string
                  @POPNULL
                  @PRTLN "Syntax Error in line"
                  @JMP EBAbortLine
               @ENDIF
               @POPNULL
            @Next XPos
            @ForIA2B XPos 0 8
               @PUSHI LineIn
               @ADDI XPos
               @PUSHS
               @AND 0xff
               @POPI SearchChar
               @Call(AV) strfndc PieceNameArray SearchChar
               @POPI SearchIndex
               @MA2V WhiteColor InputColor   # Default is White Pieces
               @IF_EQ_AV 0 SearchIndex
                  # Result is no match so invalid character, so repromt for this line.
                  @MA2V 1 RepeatInput
               @ELSE
                  # Result is a ptr to matching character, turn into 0-13 index
                  @PUSHI SearchIndex
                  @SUB PieceNameArray
                  @IF_UGE_A 6
                     @IF_ULT_A 12
                        # 12 > Index >= 6 is a blacks piece
                       @MA2V BlackColor InputColor
                     @ENDIF
                  @ENDIF
                  @POPI SearchIndex
                  # Get the pieces real value
                  @PUSHI SearchIndex
                  @ADD PieceNameValue
                  @PUSHS
                  @AND 0xff
                  @POPI InputPiece
                  @IF_EQ_AV 0 InputPiece
                    # Zero means just space, skip to next XPos
                    @MA2V 0 RepeatInput
                  @ELSE
                    @Call(VVVV) AddPieceToTable InputPiece InputColor XPos YPos
                    @IF_NOTZERO
                       @POPNULL
                       # Successfull insert
                       @MA2V 0 RepeatInput
                    @ELSE
                       @POPNULL
                       # Failed to insert, try input again
                       @PRTLN "Error Parsing input, try again."
                       @MA2V 1 RepeatInput
                    @ENDIF
                  @ENDIF
               @ENDIF
               @IF_EQ_AV 1 RepeatInput
                  # Reach here with WhiteContinue=True means something failed to parse, abort for loop
                  @FORBREAK
               @ENDIF
            @Next XPos
         @ELSE
            @POPNULL
            @PRTLN "Error Parsing input, try again."
         @ENDIF
         :EBAbortLine
      @ENDWHILE
      @PUSHI YPos
      @ADDI YStep
      @POPI YPos
  @Next Index1
  @Call(V) DisplayBoard ActiveColor
  @Call(VV) HeapDeleteObject MainHeap LineIn
  @IF_UGT_A 0
     @PRT "Memory Error"
     @END
  @ENDIF
  @POPNULL
  @Call(A) CastleSetValid WhiteColor
  @Call(A) CastleSetValid BlackColor
@EndLocals
@POPRETURN
@RET

###################################
# AddPieceToTable(InputPiece InputColor XPos YPos):0|1
:AddPieceToTable
@PUSHRETURN
@Locals
    @Local InputPiece
    @Local InputColor
    @Local XPos
    @Local YPos
    @Local Index1
    @Local PAStart
    @Local HighFreeIndex
    @Local RangeID
    @Local RangeStart
    @Local RangeEnd
    @Local RangePtr
    @Local Result



    @POPI4 YPos XPos InputColor InputPiece

    @IF_EQ_AV BlackColor InputColor
        @MA2V 16 PAStart
        @MA2V BlackRangePtr RangePtr
    @ELSE
        @MA2V 0 PAStart
        @MA2V WhiteRangePtr RangePtr
    @ENDIF

    # There has to be at least one empty slot.
    @MA2V 0 Result
    @ForIA2B Index1 15 -1
       @PUSH PiecesArray
       @ADDI PAStart
       @ADDI Index1
       @PUSHS
       @AND 0xff
       @IF_ZERO
          @POPNULL
          @PUSHI Index1
          @ADDI PAStart
          @POPI HighFreeIndex
          @MA2V 1 Result
          @FORBREAK
       @ELSE
          @POPNULL
       @ENDIF
    @NextBy Index1 -1

    @IF_EQ_AV 0 Result
       @PRTLN "No more valid slots left."
       @JMP APTTExit
    @ENDIF

# King is specal case it can only go into slot 0 of the color
    @IF_EQ_AV PieceKing InputPiece
        @PUSH PiecesArray
        @ADDI PAStart
        @POPI RangeID
        @PUSHII RangeID
        @AND 0xff
        @IF_NOTZERO
            @POPNULL
            @PRTLN "Only one King of each color is allowed."
            @MA2V 0 Result
            @JMP APTTExit
        @ENDIF
        # Insert King at this spot.
        @POPNULL
        @Call(VAVVV) SetPieceInfo PAStart 1 InputColor XPos YPos
        @MA2V 1 Result
        @JMP APTTExit
    @ENDIF
# The values of InputPiece need to be normalized into range
    @PUSHI InputPiece
    @SWITCH
    @CASE PieceRook    @PUSH 0 @CBREAK
    @CASE PieceBishop  @PUSH 1 @CBREAK
    @CASE PieceKnight  @PUSH 2 @CBREAK
    @CASE PiecePawn    @PUSH 3 @CBREAK
    @CASE PieceQueen   @PUSH 4 @CBREAK
    @CDEFAULT
       @PRTLN "Not a valid piece."
       @POPNULL
       @MA2V 0 Result
       @JMP APTTExit
       @CBREAK
    @ENDCASE
    @POPI RangeID
    @POPNULL
    # Now use that as indexes to get range
    @PUSHI RangeID
    @SHL     # *2 for words
    @ADDI RangePtr
    @PUSHS
    @PUSHS
    @POPI RangeStart
    @PUSHI RangeID @ADD 1 @SHL
    @ADDI RangePtr
    @PUSHS
    @PUSHS
    @POPI RangeEnd

    @ForIV2V Index1 RangeStart RangeEnd
       @PUSH PiecesArray
       @ADDI Index1
       @PUSHS
       @AND 0xff
       @IF_ZERO
          # Found Free one in range
          @POPNULL
          @Call(VAVVV) SetPieceInfo Index1 1 InputColor XPos YPos
          @MA2V 1 Result
          @JMP APTTExit
       @ENDIF
       @POPNULL
    @Next Index1
    # Drop Here means we need to expand range by promotion
    @Call(VVVVV) ExpandPieceRange InputColor RangeID RangeEnd RangePtr HighFreeIndex
    @POPI RangeID
    @Call(VAVVV) SetPieceInfo RangeID 1 InputColor XPos YPos
    @MA2V 1 Result
:APTTExit
    @PUSHI Result
@EndLocals
@POPRETURN
@RET

###############################################
# ExpandPieceRange(Color,RangeID,RangeEnd,RangePtr,HighFreeIndex)
:ExpandPieceRange
@PUSHRETURN
@Locals
    @Local InColor
    @Local InPieceRange
    @Local RangeEnd
    @Local RangePtr
    @Local HighFreeIndex
    @Local SourceStart
    @Local SourceEnd
    @Local DestStart
    @Local DestEnd
    @Local Index1
    @Local Index2

    @POPI5 HighFreeIndex RangePtr RangeEnd InPieceRange InColor


    @MV2V HighFreeIndex Index1

    @ForIV2V Index1 HighFreeIndex RangeEnd

       # destination = PiecesArray + Index1

       # source = PiecesArray + Index1 - 1
       @PUSH PiecesArray
       @ADDI Index1
       @SUB 1
       @POPI Index2

       @LOADBII Index2

       @PUSH PiecesArray
       @ADDI Index1
       @POPI Index2

       @STOREBII Index2

    @NextBy Index1 -1


    @PUSH PiecesArray
    @ADDI RangeEnd
    @POPI Index1
    @PUSH 0
    @STOREBII Index1

    # Now incriment all the values from RangeID to end of Range table
    # RangePtr points to either WhiteRangePtr or BlackRangePtr
    # Range ID is 0-4 but RangePtr tables are words not bytes
    @PUSHI InPieceRange
    @ADD 1
    @SHL
    @ADDI RangePtr
    @PUSHS
    @POPI SourceStart

    # Last entry in both the white and black tables is 100 to mark end
    @PUSHII SourceStart
    @WHILE_NEQ_A 100
       @ADD 1
       @POPII SourceStart
       @INC2I SourceStart
       @PUSHII SourceStart
    @ENDWHILE
    @POPNULL

    @PUSHI RangeEnd
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
   @Local CmdMode
   @Local TargetX
   @Local TargetY
   @Local SrcPiece
   @Local SrcAlive
   @Local SrcColor
   @Local SrcX
   @Local SrcY
   @Local Candidate
   @Local Promotion
   @Local SoftStackDepth
   @Local Index1
   @Local CheckPiece

   @MA2V WhiteColor ActiveColor
   @MA2V 0 CmdMode
   @MA2V 0 SoftStackDepth

   @WHILE_EQ_AV 0 CmdMode
      @IF_EQ_AV WhiteColor ActiveColor
          @PRTLN "White's Move: "
      @ELSE
          @PRTLN "Black's Move: "
      @ENDIF

      @Call(V) DisplayBoard ActiveColor

      @CALL ReadChessCmd
      @POPI CmdMode

      @PUSHI CmdMode
      @AND SuggestMoveCmdMask
      @IF_EQ_A "?\0"
          @POPNULL
          @PUSHI CmdMode
          @SHRN SuggestMoveDepthShift
          @AND 0xf
          @POPI Index1
          @PUSHI Index1
          @IF_ULT_A 1
             @POPNULL
             @MA2V SuggestMoveDefaultDepth Index1
          @ELSE
             @POPNULL
          @ENDIF
          @Call(VV) SuggestMove ActiveColor Index1
          @CALL PrintSuggestedMove
          @MA2V 0 CmdMode
          @JMP MPContinue
      @ELSE
          @POPNULL
      @ENDIF

      @PUSHI CmdMode
      @SWITCH
      @CASE "q\0"
          @POPNULL
          @PRTLN "Exit..."
          @JMP MPExit
          @CBREAK
      @CASE "p\0"
          @POPNULL
          @PRTLN "Skip Turn"
          @InvertPlayer
          @MA2V 0 CmdMode
          @JMP MPContinue
          @CBREAK
      @CASE "r\0"
          @POPNULL
          @PRTLN "Resign..."
          @CALL InitBoard
          @MA2V WhiteColor ActiveColor
         @MA2V 0 CmdMode
          @JMP MPContinue
          @CBREAK
      @CASE "?\0"
          @POPNULL
          @Call(VA) SuggestMove ActiveColor SuggestMoveDefaultDepth
          @CALL PrintSuggestedMove
          @MA2V 0 CmdMode
          @JMP MPContinue
          @CBREAK
      @CASE "s\0"
          @POPNULL
          @INCI SoftStackDepth
          @PRT "Save Game Slot:" @PRTI SoftStackDepth @PRTNL
          @SAVEBOARD
          @MA2V 0 CmdMode
          @JMP MPContinue
          @CBREAK
      @CASE "l\0"
          @POPNULL
          @PUSHI SoftStackDepth
          @IF_ULT_A 1
             @POPNULL
             @PRTLN "No Saved Game to restore."
          @ELSE
             @POPNULL
             @PRT "Restore Game From Slot:" @PRTI SoftStackDepth @PRTNL
             @DECI SoftStackDepth
             @RESTOREBORD
          @ENDIF
         @MA2V 0 CmdMode
          @JMP MPContinue
          @CBREAK
       @CASE "b\0"
          @POPNULL
          @Call(A) BoardEditMode 0
          @MA2V 0 CmdMode
          @JMP MPContinue
          @CBREAK
       @CASE "B\0"
          @POPNULL
          @Call(A) BoardEditMode 1
          @MA2V 0 CmdMode
          @JMP MPContinue
          @CBREAK
       @CDEFAULT
          @POPNULL
          @IF_EQ_AV MoveInvalid CmdMode
             @MA2V 0 CmdMode
             @JMP MPContinue
          @ENDIF
          @Call(V) ChessCmdUnpack CmdMode
          @POPI4 TargetY TargetX SrcY SrcX
          # Start check for possible Castling move
          @Call(V) CastleMoveTest CmdMode
          @IF_NOTZERO
             @POPNULL
             @Call(V) CastleMoveTry CmdMode
             @IF_EQ_A MoveInvalid
                @POPNULL
                @PRTLN "Castling not legal."
                @MA2V 0 CmdMode
                @JMP MPContinue
             @ENDIF
             @POPNULL
             @InvertPlayer
             @Call(V) ReportGameState ActiveColor
             @MA2V 0 CmdMode
             @JMP MPContinue
          @ELSE
            # Was not an attempt to castle, so just continue.
            @POPNULL
          @ENDIF
          @Call(VV) CheckBoard SrcX SrcY
          @POPI SrcPiece
          @IF_EQ_AV EmptySquare SrcPiece
             @PRTLN "No piece at that location."
             @MA2V 0 CmdMode
             @JMP MPContinue
          @ELSE
             @Call(V) GetPieceInfo SrcPiece
             @POPNULL @POPNULL
             @POPI2 SrcColor SrcAlive
             @POPNULL
             @IF_NEQ_VV ActiveColor SrcColor
                @PRTLN "Can not move other player's pieces"
                @MA2V 0 CmdMode
                @JMP MPContinue
             @ELSE
                @IF_EQ_AV 0 SrcAlive
                   @PRTLN "Can not move captured piece."
                   @MA2V 0 CmdMode
                   @JMP MPContinue
                @ELSE
                   @Call(VVV) UserMoveValid  SrcPiece TargetX TargetY
                   @POPI Candidate
                   @IF_EQ_AV MoveInvalid Candidate
                       @Call(VVV) UserMovePossible SrcPiece TargetX TargetY
                       @IF_EQ_A MoveInvalid
                          @POPNULL
                          @PRTLN "Not a valid move."
                       @ELSE
                          @POPNULL
                          @PRTLN "Not a valid move: king would be in check."
                       @ENDIF
                       @MA2V 0 CmdMode
                       @JMP MPContinue
                   @ELSE
                      @Call(VV) MovePiece SrcPiece Candidate
                      @PUSHI CmdMode
                      @SHRN 12
                      @AND 0x3
                      @POPI Promotion
                      @Call(VV) PromotePiece SrcPiece Promotion
                   @ENDIF
                @ENDIF
             @ENDIF
          @ENDIF
          @CBREAK
      @ENDCASE
      @MA2V 0 CmdMode
      @InvertPlayer
      @Call(V) ReportGameState ActiveColor
   :MPContinue
   @ENDWHILE
   :MPExit
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
   @CALL ManualPlay
   @PRTLN "End."
   @END

