# EX716 Assembler – Lesson 09: Working with ANSI Terminal "Graphics"

When dealing with older style computers, modern concepts about display and graphics did not yet exist. Instead, user interfaces were created by controlling ANSI text terminals. This meant “drawing” your screen with text.

---

## 🎯 Goals

1. Understand the nature of text-based terminal interfaces.
2. Develop a simple text-based program to control the display.
3. Build and run an animated demo program using `screen.ld`.

---

## 📜 Historical Background

From the 1970s into the early 1980s, even large computers had little in the way of graphics. True graphics required very specialized (and expensive) hardware, and performance was poor by modern standards.

Most interaction with computers was done through **text terminals**. Early “TTY” terminals were essentially typewriters connected to computers. When these evolved into **“glass TTYs”** like the DEC VT52 and, most influentially, the VT100, programmers quickly discovered that being able to control where the **cursor** was, and what **colors** were used, made user interfaces far more powerful.

These terminals worked strictly by **receiving characters one at a time** over a serial line. Special control sequences beginning with the “escape” character told the terminal to move the cursor, clear parts of the screen, or change colors. There was no concept of a graphical “frame buffer” or block copy — you had to redraw every character individually.

---

## 🛠 Functions in `screen.ld`

The `screen.ld` library provides routines that hide the messy escape codes and let you work at a higher level.

### Screen Management

* **WinClear**
  Clears the screen and moves the cursor to the upper-left (1,1).

* **WinResize**
  Asks the terminal to report its current size and sets the `WinHeight` and `WinWidth` variables.

* **WinHeight**, **WinWidth**
  Hold the screen dimensions (defaults are 24×80).

### Cursor Control

* **WinCursor(X,Y)**
  Moves the cursor to the given column (`X`) and row (`Y`).
  Call form:

  ```asm
  PUSHI X
  PUSHI Y
  CALL WinCursor
  ```

* **WinHideCursor**, **WinShowCursor**
  Turns the blinking cursor off and on.

* **WinNorth(N), WinSouth(N), WinEast(N), WinWest(N)**
  Moves the cursor relative to its current position. Example:

  ```asm
  PUSHI 1
  CALL WinEast    ; move right by 1
  ```

### Color Control

* **ColorReset**
  Restores terminal defaults.

* **ColorFGSet(ColorCode)**
  Sets foreground color.

* **ColorBGSet(ColorCode)**
  Sets background color.

Color codes range from 0–255:

* 0–7: normal colors (black, red, green, yellow, blue, magenta, cyan, white).
* 8–15: bright versions of the above.
* 16–231: 6×6×6 RGB cube (use `36*R + 6*G + B + 16`).
* 232–255: grayscale, 24 levels.

### Drawing

* **WinPlot(X0,Y0,X1,Y1,StrPtr)**
  Draws a line from (X0,Y0) to (X1,Y1), printing a string at each point.

* **WinBox(X1,Y1,X2,Y2)**
  Draws a hollow box using line characters.

### Scrolling

* **WinScrollRegion(Top,Bottom)**
  Restricts scrolling to a subsection of the screen.

* **WinResetScrollRegion()**
  Resets scrolling to full screen.

* **WinScrollUp(N)**
  Scrolls region upward by N lines.

* **WinScrollDown(N)**
  Scrolls region downward by N lines.

---

## 🐄 Demo Program: Cow Animation

The following program demonstrates how to combine **screen functions**, **timing**, and **randomness** into a simple animation. Copy this into a new file (for example `cowdemo.asm`) and run it with your assembler and emulator.

```asm
I common.mc
L screen.ld        # screen control functions
L timetool.ld      # for delay between frames
L string.ld        # for strlen()
L mul.ld           # for MULU
L random.ld        # for random direction changes

=FaceRight 0
=FaceLeft  1

# ----------------------------------------------------------------------
# DrawCow(UpX,UpY,Dir)
# Draws cow facing Dir (1=Right, -1=Left) starting at X,Y
# ----------------------------------------------------------------------
:DrawCow
@PUSHRETURN
@LocalVar UpX 01
@LocalVar UpY 02
@LocalVar Dir 03
@LocalVar Index1 04
@LocalVar CowStr 05
@LocalVar CowWidth 06
@POPI Dir

@POPI UpY
@POPI UpX
   @PUSH RightCow @CALL strlen @ADD 1 @POPI CowWidth
   @ForIA2B Index1 0 8
      # Set cursor at left side of cow
      @PUSHI UpX
      @PUSHI UpY @ADDI Index1
      @CALL WinCursor
      @IF_EQ_AV 1 Dir
          @PUSH RightCow
      @ELSE
          @PUSH LeftCow
      @ENDIF
      @PUSHI CowWidth @PUSHI Index1 @CALL MULU
      @ADDS
      @POPI CowStr
      @PRTSI CowStr
   @Next Index1
@RestoreVar 06 @RestoreVar 05 @RestoreVar 04 @RestoreVar 03
@RestoreVar 02 @RestoreVar 01
@POPRETURN
@RET

:LeftCow

"                   \0"
"  (__)             \0"
"  (oo)\_______     \0"
"  (__)       )\/\  \0"
"      ||----w |    \0"
"      ||     ||    \0"
"                   \0"
"                   \0"
:RightCow
"                   \0"
"             (__)  \0"
"     _______/(oo)  \0"
"  /\/(       (__)  \0"
"    | w----||      \0"
"    ||     ||      \0"
"                   \0"
"                   \0"

# ----------------------------------------------------------------------
# DemoCow
# Clears screen, sets limits, animates cow bouncing inside
# ----------------------------------------------------------------------
:DemoCow
  @PUSHRETURN
  @LocalVar CowX 01
  @LocalVar CowY 02
  @LocalVar CowDX 03
  @LocalVar CowDY 04
  @LocalVar Distance 05
  @LocalVar Index01 06
  @LocalVar CowDir 07
  @LocalVar WinRightLimit 08
  @LocalVar WinLeftLimit 09
  @LocalVar WinTopLimit 10
  @LocalVar WinBotLimit 11
 


  @MA2V 1 CowDX
  @MA2V 0 CowDY

  @PUSHI WinWidth @SUB 24 @POPI WinRightLimit
  @MA2V 20 WinLeftLimit
  @PUSHI WinHeight @SUB 10 @POPI WinBotLimit
  @MA2V 3 WinTopLimit

  @MA2V FaceRight CowDir
  @PUSHI WinWidth @SHR @SUB 11 @POPI CowX
  @PUSHI WinHeight @SHR @SUB 3 @POPI CowY
  @MA2V 10 Distance

  @ForIA2B Index01 0 100
     # Reverse direction if we near an edge
     @PUSHI CowX
     @ADDI CowDX
     @POPI CowX     
     @PUSHI CowX
     @IF_ULE_V WinLeftLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Left Edge: " @PRTI CowX @PRT "        "
        @MV2V WinLeftLimit CowX
        @MA2V FaceRight CowDir
        @MA2V -1 CowDX
     @ENDIF
     @IF_UGE_V WinRightLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Right Edge: " @PRTI CowX @PRT "        "     
        @MV2V WinRightLimit CowX
        @MA2V FaceLeft CowDir
        @MA2V 1 CowDX
     @ENDIF
     @POPNULL

     @PUSH CowY
     @ADDI CowDY
     @POPI CowY
     @PUSHI CowY
     @IF_ULE_V WinTopLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Top Edge: " @PRTI CowY @PRT "        "          
        @MV2V WinTopLimit CowY
        @MA2V 1 CowDY
     @ENDIF
     @IF_UGE_V WinBotLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Bot Edge: " @PRTI CowY @PRT "        "               
        @MV2V WinBotLimit CowY     
        @MA2V -1 CowDY
     @ENDIF
     @POPNULL


     @DECI Distance
     @IF_EQ_AV 0 Distance
        # Walk a number of steps, then pick a new random direction
        @PUSH 8 @CALL frndint
        @ADD 2
        @POPI Distance
        @PUSH 2 @CALL frndint
        @PUSH 1 @PUSH 3 @CALL WinCursor @PRT "Rnd: " @PRTTOP
        @IF_EQ_A 1
           @MA2V -1 CowDX
        @ELSE
           @MA2V 1 CowDX
        @ENDIF
        @POPNULL
        @PUSH 2 @CALL frndint
        @IF_EQ_A 1
           @MA2V -1 CowDY
        @ELSE
           @MA2V 1 CowDY
        @ENDIF
        @POPNULL                  
     @ENDIF
     @PUSH 1 @CALL Sleep
     
     @PUSHI CowX @PUSHI CowY @PUSHI CowDX @CALL DrawCow
  @Next Index01

 @RestoreVar 11 @RestoreVar 10 @RestoreVar 09 @RestoreVar 08
 @RestoreVar 07 @RestoreVar 06 @RestoreVar 05 @RestoreVar 04
 @RestoreVar 03 @RestoreVar 02 @RestoreVar 01
@POPRETURN
@RET

:Main . Main
@CALL TimeCalabrate
@CALL WinClear
@GETTIME @POPNULL 
@POPNULL @PUSH 101
@CALL rndsetseed
@CALL DemoCow
@END

```

---

## 🔎 Wrap-Up

This lesson introduced ANSI terminal graphics, the `screen.ld` functions, and showed how they can be used to build fun visual programs. You built an animated ASCII cow that moves around the screen, bouncing off edges and flipping direction.

---

## 🚀 Further Projects

Try extending this lesson by writing your own:

1. **ASCII Game**: Replace the cow with a spaceship, and add keyboard input to “steer.”
2. **Bouncing Ball**: A single character that bounces endlessly inside a box.
3. **Scrolling Text Window**: Use `WinScrollRegion` to make a log or chat window that scrolls independently.
4. **Color Effects**: Experiment with `ColorFGSet` and `ColorBGSet` to make colorful animations.
5. **Maze Drawer**: Use `WinBox` and `WinCursor` to draw a simple maze layout.
