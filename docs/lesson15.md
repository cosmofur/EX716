# EX716 Assembler - Lesson 15: Mouse Regions with event.ld

Mouse events are registered as screen rectangles. When terminal mouse reporting is enabled and the user clicks inside a registered rectangle, `EventPoll` returns the matching event ID.

---

## Goals

1. Enable and disable terminal mouse reporting.
2. Register clickable screen regions.
3. Use `LastMouseX`, `LastMouseY`, `LastMouseBtn`, and `LastMouseFlags`.
4. Combine mouse events with a clean event loop.

---

## Mouse Setup

Load the normal event dependencies. `screen.ld` is optional, but most mouse programs use it to draw the regions users can click.

```asm
I common.mc
L heapmgr.ld
L screen.ld
L event.ld
```

After creating your heap and event table, enable terminal mouse reporting:

```asm
@CALL TermMouseEnable
```

Always disable it before exiting:

```asm
@CALL TermMouseDisable
```

---

## Registering Click Regions

Use `MouseEventClick` when you only care about clicks. The four coordinates define an inclusive rectangle. `EventAdd` takes six arguments, so use explicit pushes and raw `@CALL EventAdd`.

```asm
=E_SAVE 10
=E_QUIT 11

# Save button: x 2..12, y 3..3
@PUSH MouseEventClick
@PUSH 2
@PUSH 3
@PUSH 12
@PUSH 3
@PUSH E_SAVE
@CALL EventAdd

# Quit button: x 2..12, y 5..5
@PUSH MouseEventClick
@PUSH 2
@PUSH 5
@PUSH 12
@PUSH 5
@PUSH E_QUIT
@CALL EventAdd
```

`EventAdd` normalizes the coordinate order, so `X1/Y1` and `X2/Y2` can be supplied in either corner order.

---

## Drawing Matching UI

The event library only detects regions. Your program should draw something visible at the same coordinates.

```asm
@CALL WinClear
@Call(AA) WinCursor 2 3
@PRT "[ Save ]"
@Call(AA) WinCursor 2 5
@PRT "[ Quit ]"
```

Keeping the event coordinates next to the drawing code makes maintenance easier.

---

## Dispatching Mouse Events

```asm
:Running 1

@PUSHI Running
@WHILE_NOTZERO
   @CALL EventPoll

   @SWITCH
      @CASE E_SAVE
         @Call(AA) WinCursor 2 7
         @PRT "Save clicked at "
         @PRTI LastMouseX
         @PRT ","
         @PRTI LastMouseY
         @PRTNL
         @CBREAK

      @CASE E_QUIT
         @MA2V 0 Running
         @CBREAK

      @CDEFAULT
         @CBREAK
   @ENDCASE

   @POPNULL
   @PUSHI Running
@ENDWHILE
@POPNULL

@CALL TermMouseDisable
@END
```

`LastMouseX` and `LastMouseY` hold the terminal cell that was clicked. `LastMouseBtn` holds the button code, and `LastMouseFlags` contains bits such as `MF_PRESS`, `MF_RELEASE`, `MF_DRAG`, `MF_WHEEL`, `MF_SHIFT`, `MF_ALT`, and `MF_CTRL`.

---

## Choosing Mouse Event Types

```text
MouseEventClick    click/press events
MouseEventRelease  release events
MouseEvent         broad mouse mask for press, release, drag, and wheel
```

Use the narrowest event type that fits the program. It keeps dispatch behavior easier to reason about.

---

## Exercises

- Add a third button and give it a new event ID.
- Print `LastMouseBtn` and `LastMouseFlags` after every click.
- Register a larger drawing area and use the mouse coordinates to update a cell inside it.
