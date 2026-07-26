# EX716 Assembler – Lesson 09: Working with ANSI Terminal "Graphics"

When dealing with older style computers, modern concepts about display and graphics did not yet exist. Instead, user interfaces were created by controlling ANSI text terminals. This meant “drawing” your screen with text.

---

## 🎯 Goals

1. Understand the basics of text-based terminal interfaces.  
2. Learn how to move the cursor and control screen position.  
3. Write a simple program that places messages at different points on the screen.

---

## 📜 Historical Background

From the 1970s into the early 1980s, even large computers had little in the way of graphics. True graphics required specialized (and expensive) hardware, and performance was poor by modern standards.

Most interaction with computers was done through **text terminals**. Early “TTY” terminals were essentially typewriters connected to computers. When these evolved into **“glass TTYs”** like the DEC VT52 and, most influentially, the VT100, programmers discovered that being able to control where the **cursor** was, and what **colors** were used, made user interfaces much more powerful.

These terminals worked strictly by **receiving characters one at a time** over a serial line. Special control sequences beginning with the “escape” character told the terminal to move the cursor, clear parts of the screen, or change colors. There was no concept of a graphical “frame buffer” — you had to redraw every character individually.

---

## 🛠 Functions in `screen.ld`

The `screen.ld` library provides routines that hide the messy escape codes and let you work at a higher level.

### Screen Management

- **WinClear**  
  Clears the screen and moves the cursor to the upper-left (1,1).

- **WinResize**  
  Asks the terminal to report its current size and sets the `WinHeight` and `WinWidth` variables.

### Cursor Control

- **WinCursor(X,Y)**  
  Moves the cursor to the given column (`X`) and row (`Y`).  
  Call form:  

  ~~~asm
  PUSHI X
  PUSHI Y
  CALL WinCursor

  ~~~

---

## Compass points across the screen

The following program uses WinCursor to print the eight compass labels at the
screen edges: NW, N, NE, E, SE, S, SW, and W. It uses the WinWidth and
WinHeight values supplied by screen.ld; they default to 80 and 24.

The SHR instruction shifts the top stack value right by one bit. For a
non-negative integer, that is the same as integer division by two, so it gives
us the horizontal and vertical centers without a division routine. Odd values
round down, which is exactly what we want for a screen coordinate.

~~~asm
I common.mc
L screen.ld

:CenterX 0
:CenterY 0

:Main . Main
  @CALL WinClear

  # CenterX = WinWidth / 2; CenterY = WinHeight / 2.
  @PUSHI WinWidth
  @SHR
  @POPI CenterX
  @PUSHI WinHeight
  @SHR
  @POPI CenterY

  # WinCursor receives X (column), then Y (row).
  @Call(AA) WinCursor 1 1 @PRT "NW"
  @Call(VA) WinCursor CenterX 1 @PRT "N"
  @Call(VA) WinCursor WinWidth 1 @PRT "NE"
  @Call(VV) WinCursor WinWidth CenterY @PRT "E"
  @Call(VV) WinCursor WinWidth WinHeight @PRT "SE"
  @Call(VV) WinCursor CenterX WinHeight @PRT "S"
  @Call(AV) WinCursor 1 WinHeight @PRT "SW"
  @Call(AV) WinCursor 1 CenterY @PRT "W"

  # Leave the cursor somewhere visible after drawing.
  @Call(AV) WinCursor 1 WinHeight
  @END
~~~

The right and bottom labels use WinWidth and WinHeight directly, so a label
may extend past the visible edge on a narrow terminal. That is useful here: it
makes the coordinate boundaries obvious.

To query a real ANSI terminal before drawing, add `@CALL WinResize` after
`@CALL WinClear`. In the emulator or a debugger, the default 80 by 24 values
keep this example self-contained.

## Next

Lesson 10 builds on the same cursor and midpoint techniques to animate an
ASCII sprite.
