I common.mc
L screen.ld
L mouse.ld
L timetool.ld
@LocalVar MidX 01
@LocalVar MidY 02
@LocalVar Index 03
@LocalVar StringStart 04
M DEBUGSCREEN True


# Clears screen and prints screen size at top-left.
:Demo_ClearAndSize
    @CALL WinClear
    @CALL WinResize
    @PUSH 1 @PUSH 1 @CALL WinCursor
    @PRT "Screen: "
    @PUSH WinWidth @PRTI
    @PRT "x"
    @PUSH WinHeight @PRTI
    @PUSH 5 @CALL Sleep
    @RET
# Draws a cross using cursor movement from center
:Demo_CursorMovement
    @CALL WinResize
    @PUSH WinWidth @PUSH 2 @CALL DIV @POPI MidX @POPNULL # Drop Remainder 
    @PUSH WinHeight @PUSH 2 @CALL DIV @POPI MidY @POPNULL
    @PUSH MidY @PUSH MidX @CALL WinCursor
    @PRT "+"
    @PUSH 3 @CALL WinNorth @PRT "^"
    @PUSH 2 @CALL WinSouth
    @PUSH 3 @CALL WinSouth @PRT "v"
    @PUSH 1 @CALL WinNorth
    @PUSH 4 @CALL WinWest @PRT "<"
    @PUSH 2 @CALL WinEast
    @PUSH 3 @CALL WinEast @PRT ">"
    @PUSH 3 @CALL WinWest
    :Break01
    @RET
# Show sample text in several colors
:Demo_Colors
    @CALL WinClear
    @PUSH 2 @PUSH 1 @CALL WinCursor
    @PUSH 1 @CALL ColorFGSet
    @PRT "Red Text "
    @PUSH 2 @CALL ColorFGSet
    @PRT "Green Text "
    @PUSH 4 @CALL ColorFGSet
    @PRT "Blue Text"
    @CALL ColorReset
    @PUSH 5 @CALL Sleep        
    @RET
# Draws a diagonal using WinPlot
:Demo_Plot
    @CALL WinClear
    @PUSH 10 @PUSH 5 @PUSH 40 @PUSH 20 @PUSH PlotChar
    @CALL WinPlot
    @PUSH 5 @CALL Sleep        
    @RET

# Data: String used for plotting
:PlotChar
     "*"
     $$0

# Hides and shows the cursor with delay
:Demo_CursorHideShow
    @CALL WinClear
    @PUSH 5 @PUSH 10 @CALL WinCursor
    @PRT "Cursor will disappear..."
    @CALL WinHideCursor
    @PUSH 5 @CALL Sleep
    @PUSH 6 @PUSH 10 @CALL WinCursor
    @CALL WinShowCursor
    @PRT "Cursor back!"
    @PUSH 5 @CALL Sleep            
    @RET

# Sets a scroll region and scrolls it up/down
:Demo_Scrolling
    @CALL WinClear
    @PUSH 5 @PUSH 15 @CALL WinScrollRegion
    @PUSH 1 @PUSH 1 @CALL WinCursor
    @ForIA2B Index 0 15
       @PRT "Scroll Line: " @PRTI Index @PRT "<----->\n"
    @Next Index
    @PUSH 7 @PUSH 2 @CALL WinCursor
    @PUSH 1 @CALL Sleep
    @PUSH 1 @CALL WinScrollUp
    @PUSH 1 @CALL Sleep
    @PUSH 3 @CALL WinScrollUp
    @PUSH 1 @CALL Sleep        
    @PUSH 1 @CALL WinScrollDown
    @PUSH 1 @CALL Sleep
    @PUSH 3 @CALL WinScrollDown
    @PUSH 1 @CALL Sleep    
    @PUSH 8 @PUSH 2 @CALL WinCursor
    @PRT "Scroll test complete"
    @PUSH 5 @CALL Sleep     
    @CALL WinResetScrollRegion
    @PRT "Test ending:\n"
    @RET



:Main . Main
#    @CALL Demo_ClearAndSize
    @CALL Demo_CursorMovement
    @PRT "2" @PUSH 1 @CALL Sleep
    @CALL Demo_Colors
    @PRT "3" @PUSH 1 @CALL Sleep    
    @CALL Demo_Plot
    @PRT "4" @PUSH 1 @CALL Sleep    
    @CALL Demo_CursorHideShow
    @PRT "5" @PUSH 1 @CALL Sleep    
    @CALL Demo_Scrolling
    @PRT "6" @PUSH 1 @CALL Sleep    
    @PRTS CSICODE @PRT "r"
    @CALL WinClear
    @PRT "Testing Mouse:"
    
@END
