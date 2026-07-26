# EX716 Assembler - Lesson 13: Event Library Fundamentals

`event.ld` lets a program react to terminal input without hard-wiring every read into the main loop. The library watches an active event table and reports an application-defined event ID when a mouse, keyboard, or timer event matches.

---

## Goals

1. Load the libraries needed by `event.ld`.
2. Create an event table on the heap.
3. Register events with `EventAdd`.
4. Poll for events with `EventPoll`.

---

## Required Libraries

Event tables are heap objects, so a normal event program starts with `heapmgr.ld` and `event.ld`.

```asm
I common.mc
L heapmgr.ld
L event.ld
```

If the program also draws a terminal UI, include `screen.ld` as well.

---

## Event Table Setup

First define heap memory, then create an event table from that heap.

```asm
=HEAP_START 0x8000
=HEAP_SIZE  1024

:MainHeap 0
:MainEvents 0

@Call(AA) HeapDefineMemory HEAP_START HEAP_SIZE
@POPI MainHeap

@Call(V) EventTableNew MainHeap
@POPI MainEvents
```

`EventTableNew(HeapID):EventTableID` also makes the new table active. If your program uses more than one table, call `EventSetActive(EventTableID)` before polling or adding events.

---

## The EventAdd Shape

Every event is registered with the same stack layout:

```text
EventAdd(Type, X1, Y1, X2, Y2, EventID)
```

`EventAdd` has six arguments, so it is too large for the friendly `@Call(...)` macros. Push its arguments explicitly and then use `@CALL EventAdd`.

The meaning of the middle four values depends on `Type`.

```text
MouseEventClick: X1, Y1, X2, Y2 define the clickable rectangle.
KeyEvent:        X1 is a pointer to a string of accepted keys; Y1/X2/Y2 are 0.
TimerEvent:      X1 is duration in seconds; Y1 is repeat flag; X2/Y2 are 0.
```

`EventID` is your own constant. It is the value `EventPoll` returns when that event fires.

---

## Polling Pattern

A typical loop calls `EventPoll`, compares the returned event ID, and branches to the matching handler.

```asm
=E_NONE 0
=E_QUIT 100

:Running 1

@PUSHI Running
@WHILE_NOTZERO
   @CALL EventPoll
   @IF_EQ_A E_QUIT
      @MA2V 0 Running
   @ENDIF
   @POPNULL
   @PUSHI Running
@ENDWHILE
@POPNULL
```

When `EventPoll` returns `0`, nothing matched. When it returns a nonzero value, the `LastEvent...`, `LastMouse...`, `LastKey...`, or `LastTimer...` variables describe what happened.

---

## Cleanup

If mouse reporting was enabled, disable it before ending the program.

```asm
@CALL TermMouseDisable
@Call(V) EventTableFree MainEvents
@END
```

---

## Summary

- `EventTableNew` creates and activates an event table.
- `EventAdd` registers mouse, keyboard, and timer events.
- `EventPoll` returns your event ID, or `0` when nothing matched.
- The `Last...` variables hold details about the most recent matched event.
