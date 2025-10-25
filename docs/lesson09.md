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

  ```asm
  PUSHI X
  PUSHI Y
  CALL WinCursor

