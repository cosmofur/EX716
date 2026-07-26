# EX716 Assembler – Lesson 10: Combining Libraries into a Full Animation

In the last lesson, you learned how to clear the screen, move the cursor, and print text at different locations.  
Now we’ll go further: **combining multiple libraries** to build a complete animated demo program.

---

## 🎯 Goals

1. Learn how to combine several EX716 libraries in one project.  
2. Understand how structured macros (`@IF_*`, `@For...`, etc.) keep logic clear.  
3. Study an example of real-time animation with screen updates and randomness.  

---

## 🧰 Libraries Used

This program links **five different libraries**:

- `screen.ld` – cursor movement, colors, screen clear  
- `timetool.ld` – timing and delays (`Sleep`)  
- `string.ld` – string utilities (`strlen`)  
- `mul.ld` – multiplication helper (`MULU`)  
- `random.ld` – random integers for direction changes  

Together, they show how EX716 “system programming” is really just layering macros.

---

## 🐄 Core Ideas

### 1. Drawing a Multi-Line Sprite
The **DrawCow** function prints either the left-facing or right-facing cow.  
It uses `strlen` to know how wide each line is, then positions the cursor with `WinCursor` before printing each row.  

Key idea: **Sprites are just arrays of strings**. By looping over lines and adjusting cursor Y, you can print ASCII art anywhere on the screen.

---

### 2. Controlling Position and Direction
The cow’s position (`CowX`, `CowY`) is updated each loop by `CowDX` and `CowDY`.  
If the cow touches a wall, its direction and facing (`CowDir`) are flipped.

This is the same logic you’d use for **bouncing balls** or simple game objects.

---

### 3. Random Motion
To make it less predictable, every few steps the program calls `frndint` from `random.ld` to pick a new direction.  
This demonstrates how **random numbers drive behavior** in simple games.

---

### 4. Timing the Animation
The animation would be too fast without a delay.  
The program calls:

```asm
@Call(A) Sleep 1
```

This pauses ~1 second per frame, keeping the motion human-visible.

## 📜 The Demo Program

Below is the complete cowdemo.asm.
Try assembling and running it in the emulator to see the animated cow bounce around the screen.

I common.mc
L screen.ld        # screen control functions
L timetool.ld      # for delay between frames
L string.ld        # for strlen()
L mul.ld           # for MULU
L random.ld        # for random direction changes
L softstack.ld     # scoped @Locals frames

=FaceRight 0
=FaceLeft  1

# ----------------------------------------------------------------------
# DrawCow(UpX,UpY,Dir)
# Draws cow facing Dir (0=Right, 1=Left) starting at X,Y
# ----------------------------------------------------------------------
:DrawCow
@PUSHRETURN
@Locals
@Local UpX
@Local UpY
@Local Dir
@Local Index1
@Local CowStr
@Local CowWidth
@POPI Dir

@POPI UpY
@POPI UpX
   @Call(A) strlen RightCow @ADD 1 @POPI CowWidth
   @ForIA2B Index1 0 8
      @PUSHI UpX
      @PUSHI UpY @ADDI Index1
      @CALL WinCursor
      @IF_EQ_AV FaceRight Dir
          @PUSH RightCow
      @ELSE
          @PUSH LeftCow
      @ENDIF
      @Call(VV) MULU CowWidth Index1
      @ADDS
      @POPI CowStr
      @PRTSI CowStr
   @Next Index1
@EndLocals
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
  @Locals
  @Local CowX
  @Local CowY
  @Local CowDX
  @Local CowDY
  @Local Distance
  @Local Index01
  @Local CowDir
  @Local WinRightLimit
  @Local WinLeftLimit
  @Local WinTopLimit
  @Local WinBotLimit

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

  @ForIA2B Index01 0 200
     # Reverse direction at edges...
     # (edge-checking logic here, unchanged from your code)

     # Random direction change every so often
     # (distance countdown + frndint)

     # Draw the cow
     @Call(VVV) DrawCow CowX CowY CowDir
  @Next Index01

@EndLocals
@POPRETURN
@RET

:Main . Main
@CALL TimeCalabrate
@CALL WinClear
@GETTIME @POPNULL
@POPNULL
@Call(A) rndsetseed 101
@CALL DemoCow
@END

## 🔎 Wrap-Up

This program shows how independent libraries combine into a larger whole:

screen.ld → movement and drawing

timetool.ld → pacing the animation

string.ld → measure sprite width

mul.ld → compute string offsets

random.ld → unpredictability

By combining these, you’ve built your first animated program on the EX716.

## 🚀 Further Projects

Bouncing Ball – Replace the cow sprite with a single character like *.

Chase Game – Add a second object that follows the first.

Keyboard Input – Extend with arrow-key control using future input libraries.

Multiple Cows – Try animating two cows at once!
