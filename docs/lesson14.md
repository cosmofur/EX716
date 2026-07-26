# EX716 Assembler - Lesson 14: Keyboard and Timer Events

This lesson builds a small event loop that responds to typed keys and a repeating timer. No mouse support is needed yet, so the program can run as a simple terminal loop.

---

## Goals

1. Register keyboard events with `KeyEvent`.
2. Register one-shot and repeating timers with `TimerEvent`.
3. Dispatch events by comparing the ID returned by `EventPoll`.
4. Read event details from `LastKeyChar` and timer metadata.

---

## Event IDs and Key Tables

Keyboard events use a string as a match table. If the typed character appears in the string, the event fires.

```asm
=E_KEY_ANY 10
=E_KEY_QUIT 11
=E_TICK 20

:AnyKeys "abcdefghijklmnopqrstuvwxyz" 0
:QuitKeys "qQ" 0
```

The event ID is separate from the key value. The ID tells your dispatcher what matched; `LastKeyChar` tells you which byte was typed.

---

## Registering Keyboard Events

`EventAdd` takes six arguments, so these examples use explicit pushes followed by raw `@CALL EventAdd`.

```asm
# Any lowercase letter
@PUSH KeyEvent
@PUSH AnyKeys
@PUSH 0
@PUSH 0
@PUSH 0
@PUSH E_KEY_ANY
@CALL EventAdd

# q or Q exits
@PUSH KeyEvent
@PUSH QuitKeys
@PUSH 0
@PUSH 0
@PUSH 0
@PUSH E_KEY_QUIT
@CALL EventAdd
```

Order matters when events overlap. If one key belongs to more than one key table, the first matching event in the table wins.

---

## Registering a Repeating Timer

A timer event uses `X1` as the duration in seconds and `Y1` as the repeat flag.

```asm
# Fire every 5 seconds
@PUSH TimerEvent
@PUSH 5
@PUSH 1
@PUSH 0
@PUSH 0
@PUSH E_TICK
@CALL EventAdd
```

For a one-shot timer, use repeat flag `0`.

---

## Dispatch Loop

```asm
:Running 1

@PUSHI Running
@WHILE_NOTZERO
   @CALL EventPoll

   @SWITCH
      @CASE E_KEY_ANY
         @PRT "Key: "
         @PRTCHI LastKeyChar
         @PRTNL
         @CBREAK

      @CASE E_KEY_QUIT
         @MA2V 0 Running
         @CBREAK

      @CASE E_TICK
         @PRT "Timer tick" @PRTNL
         @CBREAK

      @CDEFAULT
         @CBREAK
   @ENDCASE

   @POPNULL
   @PUSHI Running
@ENDWHILE
@POPNULL
```

`EventPoll` checks queued keyboard bytes before timers, but timers still get checked when no keyboard event matches.

---

## Useful Metadata

```text
LastEventType   MouseEvent, KeyEvent, TimerEvent, or 0
LastEventID     event ID returned by the latest successful EventPoll
LastKeyChar     ASCII code of the matched key
LastKeyMatchPtr pointer into the key match string
LastTimerDur    requested timer duration
LastTimeRep     repeat flag for the matched timer
LastTimerELap   elapsed low-word time value tracked by the timer code
LastTimerSkip   number of timer periods skipped before this poll
```

---

## Exercises

- Add a second timer that fires once after 15 seconds.
- Add a key table for digits and print a different message for numbers.
- Change the quit key to Escape by using a string that contains the escape byte.
