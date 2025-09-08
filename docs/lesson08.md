# EX716 Assembler - Lesson 8: Random Numbers and Simple Games

Up to now, we’ve looked at the EX716 libraries in theory. In this lesson, we’ll roll up our sleeves and use one: `random.ld`.

---

## 🎯 Goals

1. Understand how the library implements random number generation.
2. Learn how to combine randomness with simple I/O to create an interactive dice rolling game.

---

This lesson is hands-on: we’ll study parts of the library and then write a working game that uses it.

---

## 1. Introducing `random.ld`

Computers are not naturally good at producing *true* randomness. A computer given the same inputs will always produce the same outputs. To get around this, we use **pseudo-random number generators (PRNGs)** — algorithms that produce sequences that *look* random, but are actually deterministic. The art of PRNG design is finding a balance between *speed* and *quality* of randomness.

* **Complex algorithms** produce higher-quality random sequences but are slower.
* **Simpler algorithms** run much faster, but can show patterns more quickly.

All PRNGs require a **seed** — the starting value. If you always start with the same seed, you always get the same sequence. In real-world systems, seeds are usually drawn from something unpredictable (mouse movement, clock jitter, system events).

---

### The Two Families in `random.ld`

To balance speed and quality, EX716 provides two families of random number functions:

**Slower, more “classic” (LCG):**

* `rnd16()` → random integer 0..0xFFFF
* `rndint(N)` → random integer 0..N

(These are based on the classic C library `rand()` algorithm. In Python emulation mode, generating 100 numbers can take 5–15 seconds — too slow for real-time games.)

**Faster, lighter (XORShift):**

* `frnd16()` → random integer 0..0xFFFF
* `frndint(N)` → random integer 0..N

**Seeding:**

* `rndsetseed(N)` → set the starting seed

---

### Example: Rolling a Die

Remember, random results start from **0**, not 1.
To roll a 6-sided die (values 1–6):

```asm
@PUSH 6           # range we want
@CALL rndint      # generate random 0..6
@ADD 1            # shift range → 1..6
```

---

## 2. Basic Input/Output Recap

We’ll need simple I/O for our program:

* `@PRT "Text"` → print fixed text (no newline).
* `@PRTLN "Text"` → print text and append newline.
* `@PRTI Var` → print the integer value in `Var`.
* `@READI Var` → read an integer from keyboard into `Var`.

*(⚠️ `@READI` has no protection from overflow — if you type something too large, it may wrap.)*

---

## 3. Designing the Dice Game

Features we want:

1. Display instructions.
2. Seed the RNG (first with a fixed seed for repeatability).
3. Enter a main loop:

   * Generate a die roll (1–6).
   * Ask user for a guess.
   * If guess = 0, exit loop.
   * If guess matches, increment score. Otherwise print “Wrong.”
   * Display current score.
4. End program with final score.

---

## 4. Dice Game Implementation

```asm
I common.mc
L random.ld

# --- Storage ---
:Score 0
:Value 0
:Guess 0

# --- Main entry point ---
:Main . Main
@PRTLN "Dice Rolling Game 1.0"
@PRTLN "Computer will guess a number between 1 and 6."
@PRTLN "Enter your guess, or 0 to exit."

@MA2V 0 Score     # initialize Score

# Seed RNG with fixed number (repeatable sequence)
@PUSH 101
@CALL rndsetseed

# --- Main loop ---
@PUSH 0
@WHILE_NOTZERO
   # Generate random die roll (1–6)
   @PUSHI 6
   @CALL rndint
   @ADD 1
   @POPI Value

   # Prompt and read guess
   @PRT "Guess: "
   @READI Guess

   # Check result
   @IF_EQ_VV Guess Value
      @PRTLN "RIGHT!"
      @INCI Score
   @ELSE
      @PRTLN "WRONG!"
   @ENDIF

   # Show score
   @PRT "Score: ("
   @PRTI Score
   @PRTLN ")"

   # Exit if guess = 0
   @IF_EQ_AV 0 Guess
      @WHILEBREAK
   @ENDIF
@ENDWHILE

# End of program
@PRT "Final Score: "
@PRTI Score
@PRTLN ""
@END
```

---

## 5. Seeding with Time

The above game always plays the same sequence of numbers. To make it less predictable, we can use the system clock.

`@GETTIME` returns the current Unix time (seconds since 1970) as two 16-bit values:

* Low word (fast-changing, ≈ sort of like seconds of the day, aboout 25% less than full day).
* High word (slower, ≈ sort of like days since 1970).

We can throw away the high word and use the low word as a seed:

```asm
@GETTIME
@POPNULL         # discard high word
@CALL rndsetseed # seed with low word
```

This makes each run of the program different.

---

## 6. Exercise: D\&D Style Dice Roller

Modify the program into a general-purpose dice roller.

* Input: the dice type (e.g., `6` for 1d6, `20` for 1d20, '18' for 3d6).
* Output: a random roll in the proper range.

Challenge: detect when the input calls for multiple dice (e.g., `3d6` = three 1–6 rolls added together). Simply using `rndint(18)` would give a flat distribution, but true `3d6` has a bell curve. Write your code smart enough to tell the difference.

### Common dice in D\&D

| Dice | Stats      | Named Max |
| ---- | ---------- | --------- |
| 1d20 | Flat       | 20        |
| d2   | Flat       | 2         |
| d4   | Flat       | 4         |
| d8   | Flat       | 8         |
| 2d6  | Bell Curve | 12        |
| 3d6  | Bell Curve | 18        |
| d100 | Flat       | 100       |
| 4d6  | Bell Curve | 24        |
| 5d6  | Bell Curve | 30        |


