I common.mc
#
# Implements a very basic Chess game.
#
# lowercase is White, and Uppercase is Black.

@CALL InitChess
@CALL InitScreen
@CALL RefreshScreen
@CALL MainLoop
@END
:InitChess
@PRTLN "Start Setup"
@MC2M cboard BoardPtrWhite     # Note moving C to M, turn lable into pointer.
@ADDAV2C BoardPtrWhite 126 BoardPtrBlack # (Add 0-63)*2 for start of Black
# White officers are spots 0-7 and 'reverse' 63-65
@MC2M initOrder OfficePtr
@PRTLN "Set Officers"
@ForIfA2B Initx 0 8 InitLoop0
   @PUSHII OfficePtr       # Push Officer to stack
   @PUSHI BoardPtrWhite
   @POPS                   # Board[PtrBlack]=[OfficePtr]
   @PUSHII OfficePtr       # Add 'other side' bit let display deal with it.
   @OR SIDE
   @PUSHI BoardPtrBlack
   @POPS                   # Board[PtrWhite]=OfficePtr
   @INC2I OfficePtr        # Move pointers to next work (2 bytes)
   @INC2I BoardPtrWhite    # Lower address is top screen, so Add 2
   @DEC2I BoardPtrBlack    # Black pices start at bottom work 'up'
@NextStep Initx 1 InitLoop0
# Now set Pawn Rows
@PRTLN "Set Pawns"
@ForIfA2B Initx cboard+16 cboard+32 InitLoop1
  @PUSH PAWN
  @POPII Initx      # Set top row of pawns board[Initx]=Pawn
  @PUSH PAWN
  @OR SIDE          # Set bottom row of paws with Side Bit
  @PUSHI Initx      #    board[Initx+48]=(Pawn|Side)
  @ADD 80           # (cells are two bytes wide)
  @POPS             #Pops Pawn to index
@NextStep Initx 2 InitLoop1
  
# Now fill in with spaces all the empty parts of the cboard
@PRTLN "Clear Center"
@ForIfA2B Initx cboard+32 cboard+64 InitLoop2
   @PUSH SPACE
   @POPII Initx
@NextStep Initx 2 InitLoop2
# Board is now setup, we now setup the game variables
@MC2M 0 ActivePlayer       # 0=computer 1=player
@MC2M 0 BestMScore
@MC2M 0 BestMove
@PUSH cboard
@PUSH wboard
@CALL CopyBoard
@PRTLN "Finish Setup:"
@RET
=SPACE 0x00
=PAWN 0x01
=ROOK 0x02
=BISHOP 0x03
=QUEEN 0x04
=KNIGHT 0x05
=KING 0x06
=FRONTIER 0x07
=SIDE 0x20
# Local Storage
:OfficePtr 0
:BoardPtrWhite 0
:BoardPtrBlack 0
:Initx 0
:initOrder
ROOK KNIGHT BISHOP QUEEN KING BISHOP KNIGHT
:cboard
#0 2 4 6 8 A C E 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 1 1 1 1 1 1 1 1 1   # This is here to make the boarder clearer when hexdumped
 :wboard
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 0 0 0 0 0 0 0 0 0
 2 2 2 2 2 2 2 2 2
#
#
:InitScreen
@PRTLN "Clearing Screen:"
@PRTS ClearScreen
@RET
:ClearScreen
# This is the escape codes to clear the screen in ANSI
#b$27 "[0m" b$27 "[0;0H" b$27 "[2J" b0
"<ESC>ClearScreen\n" b0
#
:RefreshScreen
@PRTLN "Black(Capitals): " 
@PRTLN "White(Lowercase): "
@PRTLN "  abcdefgh"
@PRTLN "  --------"
@MC2M 0 DisX
@MC2M 0 DisY
@PRT "8:"
@ForIfA2B Initx cboard cboard+128 RefreshLoop0
   @PUSHII Initx  # cboard[Initx]
   @DUP
   @AND SIDE      # Check for SIDE (0x20) bit   
   @JMPZ DisWhite
      @POPNULL
      @AND 0b1111     # Get rid of the 0x20 bit
      @RTL
      @ADD CharDBBlack
      @PUSHS      # Stack has ptr to string.
      @POPI DisHolder
      @PRTS DisHolder
      @JMP DisSkipWhite
   :DisWhite
      @POPNULL
      @RTL
      @ADD CharDBWhite
      @PUSHS      # Stack has ptr to string.
      @POPI DisHolder
      @PRTS DisHolder      
   :DisSkipWhite
   @INCI DisX
   @PUSHI DisX
   @CMP 8
   @POPNULL
   @JNZ DisSameLine
     @MC2M 0 DisX
     @INCI DisY
     @PRTNL
     @PUSH 8  @CMPI DisY @POPNULL # Until last, Print Next line Lable
     @JMPZ DisSameLine
     @PUSHI DisY
     @SUB 8
     @PRTTOP
     @POPNULL
     @PRT ":"
   :DisSameLine
#   @PRT "Before Loop Back"
@NextStep Initx 2 RefreshLoop0
@PRTLN "End of Refresh"
@RET
:DisX 0
:DisY 0
:DisHolder 0
:CharDBBlack
"_" b0
"P" b0
"R" b0
"B" b0
"Q" b0
"N" b0
"K" b0
:CharDBWhite
"_" b0
"p" b0
"r" b0
"b" b0
"q" b0
"n" b0
"k" b0
# CopyBoard routeen copies board from A memory to B memory
# Some thoughts about simple light weight subrouteens:
#      We save the Return address in CopyReturn
#      BUT we don't have to leave it there long, just long
#      enough to allow the other paramters to be POPed
#      Pushing the Return back on the stack would allow some light recursion.
#          Just as long as the other variables can be also preserved.
:CopyBoard
@POPI CopyReturn
@POPI CopyAVal
@POPI CopyBVal
@PUSHI CopyReturn
@ForIfA2B Initx CopyAVal CopyAVal+128 CopyLoop
  @PUSHII Initx
  @POPII CopyBVal     # [Bval] <- [Initx]
  @INC2 CopyBVal
@NamedStep Index 2 CopyLoop
@RET
:CopyReturn 0
:CopyAVal 0
:CopyBVal 0
# Moves are a sized list of Deltas based on
# board indexs, taking in factor that width is 2xbytes*8
# Format starts MaxLength MoveTypes delta ...
# Logic is basicly try all possible MaxLengths for all the MoveType and rank for best
:RookMoves
8 4 -16 16 2 -2  # North, South, East, West
:BishopMoves
8 4 -14 18 14 -18  # NE, SE, SW, NW
:QueenMoves
8 8 -16 -14 2 18 16 14 -2 -18  # N, NE, E, SE, S, SW, W, NW
:KnightMoves
8 -34 -30  -12  20   34   30   12   -20
# 2N1W 2N1E 2E1N 2E1S 2S1E 2S1W 2W1S 2W1N
:KingMoves
1 8 -16 -14 2 18 16 14 -2 -18  # N, NE, E, SE, S, SW, W, NW
# Here is the offset index of the move database
:MoveDB  # We use this as the piece ID index of where the move db is.
0 0      # Pawns(1) and spaces(0) have there own rules
RookMoves
BishopMoves
QueenMoves
KnightMoves
KingMoves
:EvalDB
0    # Space doesn't even show up here.
1    # Pawns follow their own rules
3    # Rooks are worth more
3    # but no more than Bishop
9    # Queens are second most valuable
5    # Knights less than queen
46   # King is the game winner.
:MainLoopEntry
@PRTLN "Put Main Loop Here"
# Now we get to the meat and potatos of the logic
#
# ActivePlayer=0 for computer and 1 for Player
# We have 3 layers of loops
#  Outer most is looking at every cell and finding the ones owned by the active player
#  Middle loop goes though 0 to max number of steps that piece can make
#  Inner loop goes though the possible directions the piece can move.
#     At each step we see if piece is allowed to make that move or can
#     take and enemy piece. Taking a piece is given a rank based on the
#     value of the piece being taken.
#     We then call recusivly this same subroutine but with the new board.
#     
# 
@ForIfA2B EvalCellIdx wboard wboard+126 MLOuter
   @PUSHII EvalCellIdx   #EvalCellIdx is the tested cells's location
   @DUP
   @POPI CurCell   # CurCell holds the Piece Idenity
   # If CurCell is space or not owned by ActivePlayer then skip it.
   @PUSHI CurCell
   @PUSHI AcvitePlayer
   @CALL CellOwned      #return 1 if cell is owned by active player and not zero
   @CMP 0
   @POPNULL
   @JMPZ SkipMLOuter
      # AP owns this cell
      # Find the Database for this type of Cell

      @PUSHI CurCell
      @AND 0xf        # Zero out the 0x20 color bit
      # First we need to hanle Pawns a little diffent
      @CMP PAWN
      @JMPZ PawnLogic
      # Otherwise officers are in this loop
      @ADD MoveDB
      @PUSHS   # Adds Cell+MoveDB and gets Index of moves for that type of cell
      @POPI PieceMoveFrame
      @PUSHII PieceMoveFrame  # Get max number of moves
      @POPI MaxMoves
      @INCI PieceMoveFrame
      @POPI MaxDirections
      @ForIfV2V MoveIndex Zero MaxMoves MoveCountLoop
         @ForIfV2V Dir Zero MaxDirections DirCountLoop
	    # Make sure wboard not been modified yet.
	    @PUSH cboard @PUSH wboard @CALL CopyBoard
	    @PUSHI EvalCellIdx    # EvalCell 
	    @PUSHII Dir
	    @ADDS
	    @POPI NewCellIdx
	    @PUSHII NewCellIdx     # NewCellIdx is the board position of NewCell
	    @POPI NewCell          # NewCell holds the Piece ID
	    @PUSHI NewCellIdx      # setup for test call
	    @PUSHI EvalCellIdx
	    @CALL TestIfOffBoard   #returns 1 if A - B would be off wboard
	    @CMP 1
	    @JMPZ SkipDirCountLoop   # Not a valid direction, skip to next try
               # Here if new cell is valid. Check for possible target.
	       @PUSHI NewCell
	       @PUSHI ActivePlayer  # We want to know if Cell is owne
	       @NEG                 # By the 'other' player.
	       @CALL CellOwned
	       @CMP 0
	       @POPNULL
	       @JMPZ SkipDirCountLoop 
	          # Here is owned by other player an not space.
		  # Use the EvalDB to rate this move
		  
          
         :SkipDirCountLoop
         @NextStep Dir 2 DirCountLoop
       @NextStep MoveIndex 2 MoveCountLoop
	 
:SkipMLOuter
@NextStep EvalCell 2 MLOuter

@RET

