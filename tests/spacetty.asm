I common.mc
L screen.ld
L softstack.ld
L heapmgr.ld
L random.ld
:MainHeap 0
:OldX 0
:OldY 0
:OldDir 0
:TimeLimit 10
###################
:GameInit
#
#
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeap
@PUSHI MainHeap @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 24" @END @ENDIF
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
#
# Set Random Seed based on time program was run.
@GETTIME   # Gets time as 32 bit number
@POPNULL   # Get rid of the part that doesn't change often
@CALL rndsetseed
#
# We want to allow windows resize but control it if the RESIZEABLE flag is set or not
# WinWidth and WinHeight are globals provided by the screen.ld library.
@IF_EQ_AV 0 RESIZEABLE
  # ALlowing resizing makes debugging a bit harder, so set Macro Variable if you need it.
  @MA2V 24 WinWidth
  @MA2V 20 WinHeight
@ELSE
  @CALL WinResize
@ENDIF
@CALL WinClear
@CALL GameLoop
@END
#########################################################
# Function GameLoop
:GameLoop
@PUSHRETURN
@LocalVar CharIn 01
@LocalVar TimeLimt 02
@LocalVar MaxTime 03
@LocalVar ShipX 04
@LocalVar ShipY 05
@LocalVar ShipDir 06
@LocalVar ShipDeltaX 07
@LocalVar ShipDeltaY 08


# Start with Ship flying north.
@MA2V 1 ShipDeltaY
@MA2V 0 ShipDeltaX
@MA2V 96 ShipDir
# Center Ship on screen.
@PUSHI WinWidth @SHR @POPI ShipX
@PUSHI WinHeight @SHR @POPI ShipY
#
@MA2V 0 TimeLimit
@MA2V 10 MaxTime    # used to control time or speed. Count of polls of the keyboard

@PUSH 0
@WHILE_ZERO
   @READC CharIn @POPNULL
#   @POPI CharIn
   @IF_EQ_AV 0 CharIn
      # No extry do timer loop for speed control of movement.
      @INCI TimeLimit
      @IF_EQ_VV TimeLimit MaxTime
          @PUSHI ShipX @ADDI ShipDeltaX @POPI ShipX
          @PUSHI ShipY @ADDI ShipDeltaY @POPI ShipY
          @MA2V 0 TimeLimit
      @ENDIF
   @ELSE
      # A key was hit. See what it was.
      @PUSHI CharIn
      @SWITCH
      @CASE " \0"
         # Fire Engine, need to figure out math to turn direction into a change in DeltaY and DetaY
         # TO be done later.
         @CBREAK
      @CASE "<\0"
         # Rotate Left
         @PUSHI ShipDir @ADD 16 @AND 0xff @POPI ShipDir
         @CBREAK
      @CASE ">\0"
         # Rotate Right
         @PUSHI ShipDir @SUB 16 @AND 0xff @POPI ShipDir         
         @CBREAK
   # Until we get engine working, use directional thrusters.  w=North, s=South, a=West, d=East
      @CASE "a\0"      
         @DECI ShipDeltaX
         @CBREAK
      @CASE "d\0"      
         @INCI ShipDeltaX
         @CBREAK
      @CASE "w\0"      
         @DECI ShipDeltaY
         @CBREAK
      @CASE "a\0"      
         @INCI ShipDeltaY
         @CBREAK
      @CASE "Q\0"
         # Uppercase Q quits
         @POPNULL
         @POPNULL
         @PUSH 1   # Quit Code
         @PUSH 0   # trash value for case exiting popnull
         @CBREAK
      @CDEFAULT
         @CBREAK
      @ENDCASE
      @POPNULL
   @ENDIF
   @PUSHI WinWidth @SUBI ShipX
   @IF_LT_A 3
      # Wrap Ship to other size of screen when reach edge.
      @POPNULL
      @MA2V 2 ShipX
   @ELSE
      @POPNULL
      @PUSHI ShipX
      @IF_LT_A 3
         @POPNULL
         @PUSHI WinWidth @SUB 3 @POPI ShipX
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
   @PUSHI WinHeight @SUBI ShipY
   @IF_LT_A 3
      # Wrap Ship to other size of screen when reach edge.
      @POPNULL
      @MA2V 2 ShipY
   @ELSE
      @POPNULL
      @PUSHI ShipY
      @IF_LT_A 3
         @POPNULL
         @PUSHI WinHeight @SUB 3 @POPI ShipY
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
   @PUSHI ShipX @PUSHI ShipY @PUSHI ShipDir
   @CALL DrawShip
@ENDWHILE
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
#############################################
# Function DrawShip(NewX,NewY,NewDir)
:DrawShip
@PUSHRETURN
@LocalVar NewX 01
@LocalVar NewY 02
@LocalVar NewDir 03
@LocalVar StrPtr 04
@LocalVar StrLength 05
#
@POPI NewDir
@POPI NewY
@POPI NewX
@MA2V FixedString StrPtr
@PUSH 0 @POPII StrPtr    # Make String Null
@MA2V 0 StrLength
#
# We only care about drawing the ship, if its location changed.
@IF_EQ_VV OldX NewX
   @IF_EQ_VV OldY NewY
      @JMP QuickExit   # Pure stucture says don't do this, but this is also readable.
   @ENDIF
@ENDIF
#
@IF_EQ_AV -1 OldX
  # This is first call
@ELSE
  @PUSHI StrPtr
  @PUSHI OldX
  @PUSHI OldY
  @CALL ansi_cursor
  @CALL strcat
  @PUSHI StrPtr
  @PUSH SpaceGlyph
  @CALL strcat
  @MV2V NewDir OldDir       # First call always sets old direction to new
@ENDIF

@MV2V NewX OldX
@MV2V NewY OldY
#  Append the new cursor location
@PUSHI StrPtr
@PUSHI NewX
@PUSHI NewY
@CALL ansi_cursor
@CALL strcat
#
@PUSHI NewDir @PUSHI OldDir
@CALL SelectGlyph
@CALL strcat
@MA2V FixedString StrPtr
@PRTSI StrPtr
:QuickExit
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#####################################
# Function SelectGlyph(NewDir,OldDir)
:SelectGlyph
@PUSHRETURN
@LocalVar NewDir 01
@LocalVar OldDir 02
#
@POPI OldDir
@POPI NewDir
#
# For our sample cases we'll just worry about NewDir
@PUSHI NewDir  @AND 0xff          # this and may not be requried.
@SWITCH
@CASE_RANGE 0 63
   @PUSH EastGlyph
   @CBREAK
@CASE_RANGE 64 127
   @PUSH NorthGlyph
   @CBREAK
@CASE_RANGE 128 191
   @PUSH WestGlyph
   @CBREAK
@CASE_RANGE 192 256
   @PUSH SouthGlyph
   @CBREAK
@CDEFAULT
   @CBREAK
@ENDCASE
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
##############################################
# Function: ansi_cursor(Xpos,YPos):strptr to new formated ansi code
:ansi_cursor
@PUSHRETURN
@LocalVar XPos 01
@LocalVar YPos 02
@LocalVar Cloc 03
@POPI YPos
@POPI XPos
@IF_EQ_AV 0 outstring
   @PUSHI MainHeap @PUSH 40
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 255" @END @ENDIF
   @POPI outstring
@ENDIF
@PUSH 0 @POPII outstring
@PUSH "\e[" @POPII outstring
@PUSHI outstring @ADD 2
@PUSHI XPos
@PUSH 10
@CALL itos
@PUSHI outstring @CALL strlen
@POPI Cloc
@PUSH ";\0"
@PUSHI Cloc @ADDI outstring @ADD 1
@POPS
@PUSHI outstring @ADDI Cloc @ADD 2
@PUSHI YPos
@PUSH 10
@CALL itos
@PUSHI outstring @CALL strlen
@POPI Cloc
@PUSH "H\0"
@PUSHI Cloc @ADDI outstring @ADD 1
@POPS
@PUSHI outstring
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET



:outstring 0
#################################
# Glyphs
:SpaceGlyph
"  \0"
:NorthGlyph
"/\\\0"        # Note \\ is for single
:EastGlyph
"=>\0"
:SouthGlyph
:\\/\0"
:WestGlyph
"<=\0"
:RESIZEABLE 0
:FixedString "\0                                                                     "
0 0 0 
:ENDOFCODE
. GameInit
