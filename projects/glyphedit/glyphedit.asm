# Glyphedit
#
I common.mc
L screen.ld
L event.ld
L heapmgr.ld
L mul.ld

:VLine "|\0"
:HLine "-\0"
:GlyphWidth 4          # Default is 4x4 glyphs
:GlyphHeight 4         # Range is 1x1 to 8x8
:GlyphStoreLen 0       # Length in Bytes of the Main Arrays
:GlyphLength 0
:GlyphChars 0          # Ptr to string array of Chars
:GlyphColors 0         # Ptr to int array of colors
:MainHeap 0            # Main storage Heap
:ForGroundArray 0       # Array holding current FG color values
:BackGroundArray 0      # Array holding current BG color values
:PalletArray 0           # Array holding active combined colors for color table
:MainEventTable 0       # Main screen event table.
:CPEventTable 0         # Event Table for the Color Picker
:EndLoopFlag 0          # Control when the main loop exits.
:CharTableSelect 0      # Index in Char array that will get next Key Code
:FGColorTableSelect 0   # What Index of the FG color line is selected.
:BGColorTableSelect 0   # What Index of the BG color line is selected.
:CurrentPalletValue 0  # Combined high byte low byte of FG/BG in order.
:CurrentPalleteIndex 0  # Index in active Color Pallet.
:ColorBarsColumn 32      # Where on the screen the color bars start on the X axis
:Alphabit " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()-_=+[]{}\\|\';:<>,./?~`\"\0"
:CtrlLCode $$12 $$18 0   # Accept Ctrl-L or Ctrl-R for screen refresh
:CtrlCCode $$3 0
#
# For the Color Selection
:Current_Red 0
:Current_Blue 0
:Current_Green 0


############# Important constants
=E_Click_Draw 101
=E_Click_Color 102
=E_Click_Pick_FGColor 110
=E_Click_Pick_BGColor 120
=E_Click_Pick_Pallet 130
=E_Click_But_Edit 140
=E_Click_But_Gen 150
=E_Click_But_Clear 160
=E_Click_But_Exit 170
=E_CP_Exit 180
=E_CP_Red 189
=E_CP_Green 200
=E_CP_Blue 210
=E_CP_Gray 220
=E_CP_Exit 230
=E_Time_Draw 300
=E_KEYPress 400
=E_KeyCtrlL 401
=E_KeyCtrlC 402
############## UI Constants
=ColorButLine 12
=GenButLine ColorButLine+1
=ClearButLine 17
=QuitButLine ClearButLine+1
=FGColorLine 5
=BGColorLine FGColorLine+1
=PalletColorLine BGColorLine+1
=PalletMarkerLine PalletColorLine+1
=ColorStatusLine PalletMarkerLine+1
=ColorBarLeft 30
=ColorStatusColumn ColorBarLeft
=BlackColor 0
=WhiteColor 7

M SetBWText   @Call(A) ColorFGSet WhiteColor @Call(A) ColorBGSet BlackColor
M SetWBText   @Call(A) ColorFGSet BlackColor @Call(A) ColorBGSet WhiteColor

###################################################
# Function DrawPrimary.
# Active parts will be 2,2 to 78,23 which should be sufficent for our max 8x8 glyphs
:DrawPrimary
@LocalVar Index 01

@CALL WinClear
# Draw Box around Screen

# Here is an example how we can 'extend' the Call() for 5 paramater calls
# Simple we put the 'first' paramater on stack with normal push then use the 4 argument version

# CALL(X1,Y1,X2,Y2,String)
#
# 1,1-WinWidth,1,HLine
@PUSH 1 @Call(AvAA) WinPlot 1,WinWidth,1,HLine
# 1,WinHeight-WinWidth,WinHeight,Hline
@PUSH 1 @Call(vvvA) WinPlot WinHeight,WinWidth,WinHeight,HLine
# 1,1-1,WinHeight, VLine
@PUSH 1 @Call(AAvA) WinPlot 1,1,WinHeight,VLine
# WinWidth,1 - WinWidth, WinHeight, VLine
@PUSHI WinWidth @Call(AvvA) WinPlot 1,WinWidth,WinHeight,VLine
#
# We need to use some math here, so can't use the Call() notation
# Call WinPlot(GlyphWidth+2,1,GlyphWidth+2,GlyphHeight+2,"|")
@PUSHI GlyphWidth @ADD 2
@PUSH 2
@PUSHI GlyphWidth @ADD 2
@PUSHI GlyphHeight @ADD 1
@PUSH VLine

@CALL WinPlot


# Call WinPlot(GlyphWidth*2+2,1,GlyphWidth*2+2,GlyphHeight+2,"|")
@PUSHI GlyphWidth @SHL @ADD 3
@PUSH 2
@PUSHI GlyphWidth @SHL @ADD 3
@PUSHI GlyphHeight @ADD 1
@PUSH VLine
@CALL WinPlot



# Call WinPlot(1, GlythHeight+2, GlyphWindth+2, GlyphHeight+2, "-")
@PUSH 2
@PUSHI GlyphHeight @ADD 2
@PUSHI GlyphWidth @SHL @ADD 2
@PUSHI GlyphHeight @ADD 2
@PUSH HLine
@CALL WinPlot

@Call(AA) WinCursor ColorBarLeft,FGColorLine-1 @PRT "0123456789_123456789_123456789_123456789"
@Call(AA) WinCursor ColorBarLeft-10,FGColorLine @PRT "Forground: "
@Call(AA) WinCursor ColorBarLeft-10,BGColorLine @PRT "Background:"
@Call(AA) WinCursor ColorBarLeft-10,PalletColorLine @PRT "Pallet:    "
@Call(AA) WinCursor ColorBarLeft-10,ColorStatusLine @PRT "Current:   "
@Call(AA) WinCursor ColorStatusColumn,ColorStatusLine 
@Call(v) EnablePalletColor CurrentPalletValue @PRT "#" 
@SetBWText
@IF_EQ_AV 0 MixingNow @PRT " Mix" @ELSE @PRT "    " @ENDIF

@MA2V ColorBarLeft+2 ColorBarsColumn
@CALL WinUnderLineOn
@ForIA2B Index 0 40
   @Call(A) ColorFGSet BlackColor
   @Call(A) ColorBGSet WhiteColor
   @PUSHI Index @ADDI ColorBarsColumn
   @PUSH FGColorLine
   @CALL WinCursor
   @PUSHI Index @SHL @ADDI ForGroundArray @PUSHS
   @CALL ColorFGSet
   @PRT "#"
   @SetBWText
   @Call(A) ColorBGSet BlackColor
   @PUSHI Index @ADDI ColorBarsColumn
   @PUSH BGColorLine
   @CALL WinCursor
   @PUSHI Index @SHL @ADDI BackGroundArray @PUSHS
   @CALL ColorBGSet
   @PRT "#"
   @SetBWText   
   @PUSHI Index @ADDI ColorBarsColumn
   @PUSH PalletColorLine
   @CALL WinCursor
   @PUSHI Index @SHL @ADDI PalletArray @PUSHS
   @AND 0xff
   @CALL ColorFGSet
   @PUSHI Index @SHL @ADDI PalletArray @PUSHS   
   @AND 0xff00 @SHRN 8
   @CALL ColorBGSet
   @PRT "#"
@Next Index
@CALL WinUnderLineOff
@PRTNL
@SetBWText
#@CALL ColorReset

@Call(AA) WinCursor 3,ColorButLine @PRT "<Edit Color>"
@Call(AA) WinCursor 3,GenButLine @PRT "<Generate>"
@Call(AA) WinCursor 3,ClearButLine @PRT "<Clear>"
@Call(AA) WinCursor 3,QuitButLine @PRT "<QUIT>"
@CALL RefreshGlyphDraw         

@RestoreVar 01
@RET
##################################################
# Function EnablePalletColor(color16)
:EnablePalletColor
@PUSHRETURN
@LocalVar CurrentColor 01
@POPI CurrentColor
    @PUSHI CurrentColor
    @AND 0xff
    @CALL ColorFGSet
    @PUSHI CurrentColor
    @AND 0xff00 @SHRN 8
    @CALL ColorBGSet
@RestoreVar 01
@POPRETURN
@RET

##################################################
# Function GetSize
:GetSize
@LocalVar Index 01
@PROMPT "GlyphWidth: " GlyphWidth
@PROMPT "GlyphHeight: " GlyphHeight

@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeap

@Call(vA) HeapNewObject MainHeap 80
@POPI BackGroundArray
@Call(vA) HeapNewObject MainHeap 80
@POPI ForGroundArray
@Call(vA) HeapNewObject MainHeap 80
@POPI PalletArray

@ForIA2B Index 0 38
   @PUSH BlackColor @PUSHI Index @SHL @ADDI ForGroundArray @POPS
   @PUSH BlackColor @PUSHI Index @SHL @ADDI BackGroundArray @POPS
   @PUSH BlackColor @PUSHI Index @SHL @ADDI PalletArray @POPS
@NextBy Index 2
@ForIA2B Index 0 16
   @PUSHI Index @PUSHI Index @SHL @ADDI ForGroundArray @POPS
   @PUSHI Index @PUSHI Index @SHL @ADDI BackGroundArray @POPS
   @PUSHI Index @SHLN 8 @ORI Index
   @PUSHI Index @SHL @ADDI PalletArray @POPS   
@Next Index
@RestoreVar 01

@RET

####################################################
# POPUP Color Picker Display
:ColorPickerView
@LocalVar Index1 01

@Call(AAAA) WinBox ColorBarLeft-1 10 ColorBarLeft+42 20

@ForIA2B Index1 0 6
   # Draw Red Line
   # Location
   @PUSH 35 @PUSHI Index1 @ADD 12 @CALL WinCursor
   # Red=16 + 36*Red
   @PUSHI Index1 @SHLN 2
   @DUP @SHLN 3
   @ADDS
   @ADD 16
   @CALL ColorFGSet
   @PRT "#"
   # Draw Green Line
   # Location
   @PUSH 44 @PUSHI Index1 @ADD 12 @CALL WinCursor
   # Green=16+6*Green
   @PUSHI Index1 @SHL   # *2
   @DUP @SHL            # *4
   @ADDS
   @ADD 16
   @CALL ColorFGSet
   @PRT "#"
   # Draw Blue Line
# Location
   @PUSH 53 @PUSHI Index1 @ADD 12 @CALL WinCursor
   @PUSHI Index1
   @ADD 16
   @CALL ColorFGSet
   @PRT "#"
@Next Index1

@Call(AA) WinCursor 33 19
@ForIA2B Index1 0 24
   @PUSHI Index1 @ADD 232
   @CALL ColorFGSet
   @PRT "#"
@Next Index1

@CALL ColorReset
@Call(AA) WinCursor 58 11
@PRT "X"
@RestoreVar 01
@RET

#####################################
# Setup two event loop strucutures
:SetupEventTables

# The following structure is to allow to independent event loops.
# One for the main screen, and another when the Color picker is displayed.
@Call(v) EventTableNew MainHeap
@POPI MainEventTable
@Call(v) EventTableNew MainHeap
@POPI CPEventTable

@Call(v) EventSetActive MainEventTable   # Make MainEventTable the active one.
##########
# Setup Main EventTable
#
:SetUpEvents
# Event(MouseEvent,2,2,GlyphWidth+1,GlyphHeight+1,E_Click_Draw)
@PUSH MouseEvent
@PUSH 2 @PUSH 2
@PUSHI GlyphWidth @ADD 1 @PUSHI GlyphHeight @ADD 1
@PUSH E_Click_Draw     # Note E_Click_Draw is a constant not a variable.
@CALL EventAdd
#
# Event(MouseEvent,GlyphWidth+2, 2, GlyphWidth*2+2, GlyphHeight+1, E_Click_Color
@PUSH MouseEvent
@PUSHI GlyphWidth @ADD 3 @PUSH 2
@PUSHI GlyphWidth @SHL @ADD 2 @PUSHI GlyphHeight @ADD 1
@PUSH E_Click_Color
@CALL EventAdd
#
# Quick Macro to make adding fixed constant events easier.
M CallAddEvent  @PUSH %1 @PUSH %2 @PUSH %3 @PUSH %4 @PUSH %5 @PUSH %6 @CALL EventAdd

@CallAddEvent MouseEvent,ColorBarLeft,FGColorLine,ColorBarLeft+42,FGColorLine,E_Click_Pick_FGColor
@CallAddEvent MouseEvent,ColorBarLeft BGColorLine ColorBarLeft+42 BGColorLine E_Click_Pick_BGColor
@CallAddEvent MouseEvent,ColorBarLeft PalletColorLine ColorBarLeft+42 PalletColorLine E_Click_Pick_Pallet
@CallAddEvent MouseEvent,3 GenButLine 14 GenButLine E_Click_But_Gen
@CallAddEvent MouseEvent,3 ClearButLine 14 ClearButLine E_Click_But_Clear
@CallAddEvent MouseEvent,3 QuitButLine 14 QuitButLine E_Click_But_Exit
#
@CallAddEvent TimerEvent 5 1 0 0 E_Time_Draw
@CallAddEvent KeyEvent Alphabit 0 0 0 E_KEYPress
@CallAddEvent KeyEvent CtrlLCode 0 0 0 E_KeyCtrlL
@CallAddEvent KeyEvent CtrlCCode 0 0 0 E_KeyCtrlC

@CALL EventGetActive @POPI MainEventTable   # Refresh this after any change to table
#
#
###########
# Setup Color Picker Events
@Call(v) EventSetActive CPEventTable # Switch to the Popups Color Picker Event table
#
# Event(MouseEvent, 35, 12, 35, 18, E_CP_Red)
@CallAddEvent  MouseEvent,35 12 35 18 E_CP_Red
@CallAddEvent  MouseEvent,44 12 44 18 E_CP_Green
@CallAddEvent  MouseEvent,53 12 53 18 E_CP_Blue
@CallAddEvent  MouseEvent,33 19 57 19 E_CP_Gray
@CallAddEvent  MouseEvent,58 11 58 11 E_CP_Exit
@CALL EventGetActive @POPI CPEventTable

@Call(v) EventSetActive MainEventTable   # Make MainEventTable the active one.
@RET
###########
# ClearKeyCache()
:ClearKeyCache
  @CALL KeyQueueSize
  @WHILE_NOTZERO
      @CALL KeyDeQueue
      @POPNULL
      @CALL KeyQueueSize
   @ENDWHILE
   @POPNULL
@RET
#####################################
# FillArray(Array,Size,FillValue)
:FillArray
@PUSHRETURN
@LocalVar Array 01
@LocalVar Size 02
@LocalVar FillValue 03
@LocalVar Index01 04
@LocalVar Preserve 05
   @POPI FillValue
   @POPI Size
   @POPI Array
   # Save the byte that after the last byte
   # Doesn't do much if Size is evem but if odd, needs to preserve it.
   @PUSHI Array @ADDI Size @ADD 1 @PUSHS
   @POPI Preserve   

   @ForIA2V Index01 0 Size
      @PUSHI FillValue @AND 0xff
      @PUSHI Index01 @ADDI Array
      @POPS
   @Next Index01

   # Put back that Preserved Byte just in case Size was odd an it was overwritten
   @PUSHI Preserve      
   @PUSHI Array @ADDI Size @ADD 1 @PUSHS
   @POPS
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

      

#####################################
# Function SetUpGlyphMem
:SetUpGlyphMem
@PUSHRETURN

   @PUSHI GlyphWidth
   @PUSHI GlyphHeight @CALL MULU
   @POPI GlyphLength          # Size of the GlyphArray
   @PUSHI GlyphLength @SHL @POPI GlyphStoreLen
   #
   @Call(vv)  HeapNewObject MainHeap GlyphStoreLen
   @POPI GlyphChars
   @Call(vv)  HeapNewObject MainHeap GlyphStoreLen
   @POPI GlyphColors
   @Call(vvA) FillArray GlyphChars GlyphStoreLen  " \0"  # Fill with spaces.
   @Call(vvA) FillArray GlyphColors GlyphStoreLen 0
   #

@POPRETURN
@RET


####################################
# DrawCurrentGlyph(X,Y)
:DrawCurrentGlyph
@PUSHRETURN
@LocalVar NWX 01
@LocalVar NWY 02
@LocalVar Index1 03
@LocalVar XPOS 04
@LocalVar CurY 05


@POPI NWY
@POPI NWX
#@Call(AA) WinCursor 1 9 @PRT "Top:" @StackDump @PRT "  "
   @MV2V NWY CurY
   @MA2V 0 XPOS
   @Call(vv) WinCursor NWX NWY
   # XPOS is counter for width, CurY is acutual line Y.
   @ForIA2V Index1 0 GlyphLength
       @PUSHI XPOS
       @IF_GE_V GlyphWidth
          @POPNULL
          @MA2V 0 XPOS
          @INCI CurY
          @Call(vv) WinCursor NWX CurY
       @ELSE
          @POPNULL
       @ENDIF
       @INCI XPOS                 
       @PUSHI GlyphColors @PUSHI Index1 @SHL @ADDS
       @PUSHS
       @CALL EnablePalletColor
       @PUSHI GlyphChars @PUSHI Index1 @ADDS
       @PUSHS @AND 0xff
       @PRTCHS
       @POPNULL
       @SetBWText         # So debugging can see text. Move out of loop later.
   @Next Index1
#@Call(AA) WinCursor 1 10 @PRT "Bot:" @StackDump @PRT "  "   
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#####################################
# RefreshGlyphDraw()  Refreshes the Draw area with current BW glyph
:RefreshGlyphDraw
@PUSHRETURN
@LocalVar NWX 01
@LocalVar NWY 02
@LocalVar Index1 03
@LocalVar XPOS 04
@LocalVar CurY 05

   @MA2V 2 NWX
   @MA2V 2 NWY

   @SetBWText
   @MV2V NWY CurY
   @MA2V 0 XPOS
   @Call(vv) WinCursor NWX NWY
   # XPOS is counter for width, CurY is acutual line Y.
   # First draw the Ruff BW text part
   @ForIA2V Index1 0 GlyphLength
       @PUSHI XPOS
       @IF_GE_V GlyphWidth
          @POPNULL
          @MA2V 0 XPOS
          @INCI CurY
          @Call(vv) WinCursor NWX CurY
       @ELSE
          @POPNULL
       @ENDIF
       @INCI XPOS
       @PUSHI GlyphChars @PUSHI Index1 @ADDS
       @PUSHS @AND 0xff
       @PRTCHS
       @POPNULL
   @Next Index1
   @MV2V NWY CurY
   @MA2V 0 XPOS
   @PUSHI NWX @ADDI GlyphWidth @ADD 1
   @POPI NWX
   # Next draw the color space.
   @ForIA2V Index1 0 GlyphLength
      @PUSHI XPOS
      @IF_GE_V GlyphWidth
         @POPNULL
         @MA2V 0 XPOS
         @INCI CurY
         @Call(vv) WinCursor NWX CurY
      @ELSE
         @POPNULL
      @ENDIF
      @INCI XPOS
      @PUSHI GlyphColors @PUSHI Index1 @SHL @ADDS
      @PUSHS
      @CALL EnablePalletColor
      @PRT "#"
   @Next Index1
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

:Main . Main
@CALL WinClear
@CALL GetSize
@CALL DrawPrimary
@CALL SetupEventTables
@CALL SetUpEvents
@CALL SetUpGlyphMem
@Call(AA) WinCursor 1 30
#@Call(v) EventList MainEventTable

@CALL TermMouseEnable
@CALL AppLoop
@END


#######################################
# Function AppLoop
:AppLoop
@PUSHRETURN
@LocalVar FixedColor 01
@LocalVar MixingNow 02
@TTYRAW
#@TTYNOECHO
@MA2V 0 EndLoopFlag
@MA2V 0 MixingNow
@SetBWText
 @Call(AA) WinCursor 1 26 @StackDump
@WHILE_EQ_AV 0 EndLoopFlag
   @CALL EventPoll
   @SetBWText
   @Call(AA) WinCursor 1 25
   @PRT "Result: " @PRTI LastMouseX @PRT "," @PRTI LastMouseY
   @PRT " Return Code:" @PRTHEXTOP @PRT " Latest Char:" @PRTHEXI LastKeyChar @PRT "   "
   @IF_NOTZERO
      @SWITCH
      @CASE E_Click_But_Exit
         @MA2V 1 EndLoopFlag
         @CBREAK
      @CASE E_KeyCtrlC
         @MA2V 1 EndLoopFlag
         @CBREAK
      @CASE E_Click_But_Clear
         @LocalVar Index 01
         @CALL TermMouseDisable
         @CALL ClearKeyCache
         @TTYECHO
         @TTYRAWOFF
         @CALL ColorReset      
         @SetBWText
         @Call(AA) WinCursor 1 28
         @PRT "Stack: " @StackDump @PRTNL
         @PRT "Table GlyphChars:"
         @ForIA2V Index 0 GlyphLength
            @PUSHI GlyphChars @ADDI Index @PUSHS @AND 0xff
            @PRTHEXTOP @PRT ":" @PRTCHS @PRT ","
            @POPNULL
         @Next Index
         @PRTNL
         @PRT "Table GlyphColors:"
         @ForIA2V Index 0 GlyphLength
            @PUSHI Index @SHL @ADDI GlyphColors @PUSHS
            @PRTHEXTOP @PRT ","
            @POPNULL
         @Next Index
         @TTYRAW
         @TTYNOECHO
         @CALL TermMouseEnable         
         @RestoreVar 01
         @CBREAK
      @CASE E_Click_Draw
         # We don't acutually draw anything at this time, just selecting which cell to draw in.
         @PUSHI LastMouseX @SUB 2
         @PUSHI LastMouseY @SUB 2
         @PUSHI GlyphWidth
         @CALL MULU
         @ADDS
         @ADDI GlyphChars
         @POPI CharTableSelect
         @PUSHI LastMouseX @PUSHI LastMouseY @CALL WinCursor
         @SetWBText
         @PUSHI CharTableSelect @AND 0xff         
         @PRTCHS
         @SetBWText
         @POPNULL
         @Call(AA) WinCursor ColorStatusColumn ColorStatusLine
         @Call(v) EnablePalletColor CurrentPalletValue @PRT "#" 
         @SetBWText
         @PRT "    "
         @MA2V 0 MixingNow   # Disable  Color Mixing         
         @CBREAK
      @CASE E_Click_Color
         @PUSHI CurrentPalletValue      
         @PUSHI LastMouseX @SUBI GlyphWidth @SUB 3
         @PUSHI LastMouseY @SUB 2
         @PUSHI GlyphWidth
         @CALL MULU
         @ADDS @SHL
         @ADDI GlyphColors
         @POPS
         @PUSHI LastMouseX @PUSHI LastMouseY @CALL WinCursor
         @Call(v) EnablePalletColor CurrentPalletValue
         @PRT "#"
         @SetBWText
         @Call(AA) WinCursor ColorStatusColumn ColorStatusLine
         @Call(v) EnablePalletColor CurrentPalletValue @PRT "#" 
         @SetBWText
         @PRT "    "
         @MA2V 0 MixingNow   # Disable  Color Mixing
        @CBREAK
     @CASE E_Click_Pick_FGColor
         @PUSHI LastMouseX @SUBI ColorBarsColumn @SHL
         @ADDI ForGroundArray
         PUSHS
         @PUSHI CurrentPalletValue
         @AND 0xff00
         @ORS
         @POPI CurrentPalletValue
         @MA2V 1 MixingNow   # Enable Color Mixing
         @Call(AA) WinCursor ColorStatusColumn ColorStatusLine         
         @Call(v) EnablePalletColor CurrentPalletValue @PRT "#" 
         @SetBWText
         @PRT " Mix"
         @CBREAK
     @CASE E_Click_Pick_BGColor
         @PUSHI LastMouseX @SUBI ColorBarsColumn @SHL
         @ADDI BackGroundArray
         PUSHS
         @SHLN 8
         @PUSHI CurrentPalletValue
         @AND 0xff
         @ORS
         @POPI CurrentPalletValue
         @MA2V 1 MixingNow   # Enable Color Mixing
         @Call(AA) WinCursor ColorStatusColumn ColorStatusLine         
         @Call(v) EnablePalletColor CurrentPalletValue @PRT "#" 
         @SetBWText
         @PRT " Mix"
         @CBREAK
      @CASE E_Click_Pick_Pallet
         @PUSHI LastMouseX @SUBI ColorBarsColumn         
         @IF_GE_A 16
            @MA2V 0 FixedColor
         @ELSE
            @MA2V 1 FixedColor
         @ENDIF         
         @SHL
         @ADDI PalletArray
         @IF_EQ_VV 0 FixedColor
            @IF_EQ_VV 1 MixingNow
               # IF its one of editiable Pallet entries, and editing happening. Modfy entry.
               @DUP
               @PUSHI CurrentPalletValue
               @SWP
               @POPS
            @ENDIF
         @ENDIF               
         @PUSHS
         @MA2V 0 MixingNow   # Now make sure no longer editing color Pallet
         @POPI CurrentPalletValue
         @Call(vA) WinCursor ColorBarsColumn PalletMarkerLine
         @SetBWText
         @PRT "                                        "
         @CALL DrawPrimary                           
         @Call(vA) WinCursor LastMouseX PalletMarkerLine
         @PRT "^"
         @Call(AA) WinCursor ColorStatusColumn ColorStatusLine
         @Call(v) EnablePalletColor CurrentPalletValue @PRT "#" 
         @SetBWText
         @PRT "    "
         @CBREAK
      @CASE E_Time_Draw
         @PUSHI WinWidth @SHR
         @PUSHI WinHeight @SHR
         @CALL DrawCurrentGlyph
         @CBREAK
      @CASE E_KEYPress
         @PUSHI LastKeyChar @POPII CharTableSelect
         @CALL RefreshGlyphDraw
         @CBREAK
      @CASE E_KeyCtrlL
         @CALL WinClear
         @CALL DrawPrimary
         @CBREAK
      @CDEFAULT
         @CBREAK
      @ENDCASE
   @ENDIF
   @POPNULL
@ENDWHILE
@CALL TermMouseDisable
@CALL ClearKeyCache
@TTYECHO
@PUSH 1 @PUSH 30 @CALL WinCursor
@CALL ColorReset
# Setup Event Tables
#@CALL ColorPickerView
@TTYRAWOFF
@POPRETURN
@RET
:ENDOFCODE
