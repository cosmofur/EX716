# EX716 Assembler - Lesson 4: Structured Programming in Assembly

In previous lessons, we introduced traditional assembly concepts — stack operations, low-level flow control, and the use of labels with `JMP`, `JMPZ`, `JMPN`, etc. Now, we step forward into **structured programming**, using EX716 macros to reduce label clutter and improve clarity.

This is where EX716 diverges from "old-school" spaghetti-style jump logic. Our macro system allows us to express `IF`, `WHILE`, and `FOR` loops directly, along with `SWITCH/CASE`, all backed by simple macros and clean conventions.

---

## 🧪 Revisiting a Classic: Max in Table

Original version using labels and raw jumps:

```asm
I common.mc
. 0x1000
:START
  @PUSH DataTable
  @POPI Index
  @PUSH 0
  @POPI MaxFound

:LoopTop
  @PUSHII Index
  @CMP -1
  @JMPZ EndLoop

  @CMPI MaxFound
  @JMPN SkipStore
  @JMP StoreNewMax

:SkipStore
  @PUSHI Index
  @ADD 2
  @POPI Index
  @JMP LoopTop

:StoreNewMax
  @POPI MaxFound
  @JMP SkipStore

:EndLoop
  @PRT "Max value found:\n"
  @PRTI MaxFound
  @END

:Index       0
:MaxFound    0
:DataTable   17 23 14 98 45 -1
```

Structured version:

```asm
I common.mc
:Main . Main
@MA2V 0 MaxFound @MA2V DataTable Index

@PUSHII Index
@WHILE_NEQ_A -1
   @IF_GT_V MaxFound
      @POPI MaxFound
   @ELSE
      @POPNULL
   @ENDIF
   @INC2I Index  @PUSHII Index
@ENDWHILE
@POPNULL
@PRT "Max value found:" @PRTI MaxFound
@END

:MaxFound 0
:Index 0
:DataTable 17 23 14 98 45 -1
```

We replaced multiple labels with a single `@WHILE` loop and nested `@IF`. It's easier to read, easier to debug, and better reflects the algorithm.

---

## 📐 IF Macros and Condition Suffixes

EX716 uses suffix notation to indicate what is being compared. Here's how to read it:

| Suffix | Meaning                          | Example               |
| ------ | -------------------------------- | --------------------- |
| `_A`   | TOS vs Immediate constant        | `@IF_EQ_A 0`          |
| `_V`   | TOS vs Variable (memory address) | `@IF_GT_V Score`      |
| `_S`   | SFT vs TOS Values                | `@IF_EQ_S`            |
| `_AV`  | Constant vs. Variable            | `@IF_LT_AV 5 Max`     |
| `_VV`  | Variable vs. Variable            | `@IF_EQ_VV Var1 Var2` |

Examples:

```asm
@IF_EQ_VV Var1 Var2        # True if Var1 == Var2
@IF_GT_AV 100 MaxValue     # True if 100 > MaxValue
```

---

## 🧠 Compound Logic Example

You can't write complex expressions like Python:

```python
if ((a1 == b1) and (a1 > 100)) or (b1 == 0):
```

But you can express it in EX716 like this:

```asm
@PUSH 0
@IF_EQ_VV a1 b1
   @IF_GT_VA a11 100      # Nested IF's are like ANDs
      @POPNULL @PUSH 1
   @ENDIF
@ENDIF
@IF_EQ_AV 0 b1            # OR logic by using stack.
   @POPNULL @PUSH 1
@ENDIF
@IF_NOTZERO               # That way stack will be 1
   do true block          # if either branch is true.
@ELSE
   do false block
@ENDIF
```

It’s longer, but clear, modular, and avoids labels.

---

## 🔁 WHEN/DO: For Complex Loop Conditions

If your loop condition can’t be expressed with a single-line `@WHILE`, use `@WHEN` and `@DO_NOTZERO`.

```asm
@WHEN
  @PUSHI Index
  @IF_LT_V MaxValue
     @POPNULL @PUSHII Index
     @IF_EQ_A -1
        @POPNULL @PUSH 0
     @ELSE
        @POPNULL @PUSHII Index
        @IF_EQ_V FoundItem
           @POPNULL @PUSH 1
        @ELSE
           @POPNULL @PUSH 0
        @ENDIF
     @ENDIF
  @ELSE
     @POPNULL @PUSH 0
  @ENDIF
@DO_NOTZERO
   loop body here
@ENDWHEN
@POPNULL
```

This separates loop conditions from the loop body, improving clarity.

---

## 🔂 FOR Loops

The `FOR` macro family combines index setup, loop condition, and step logic.

```asm
:Index 0
@ForIA2B Index 0 10
   @PRTI Index @PRT "\n"
@Next Index
```

This prints 0 through 9. 
Loop exits when Index=10, so the body is skipped on 10

### FOR Macro Variants

| Macro                | Description                |
| -------------------- | -------------------------- |
| `@ForIA2B`           | Constant A to B            |
| `@ForIupV2A`         | Var to Const (ascending)   |
| `@ForIdownA2V`       | Const to Var (descending)  |
| `@Next Index`        | Increment by 1             |
| `@NextBy  Index -1   | Increment by -1 (decrement)|
| `@NextByI Index Var` | Add Var to Index each step |

---

## 🔀 SWITCH / CASE Logic

EX716 supports basic `SWITCH`-like behavior using macros. Example:

```asm
@PUSHI Mode
@SWITCH
  @CASE 0
    @PRT "Mode 0 selected\n"
    @CBREAK
  @CASE  1
    @PRT "Mode 1 selected\n"
    @CBREAK
  @CASE 2
    @PRT "Mode 2 selected\n"
    @CBREAK
  @CASE_RANGE 3 10
    @PRT "Future modes selected\n"
    @CBREAK
  @CDEFAULT
    @PRT "Unknown mode\n"
    @CBREAK
@ENDCASE
```

The value on the stack is compared to each `@CASE`. On match, that block executes. Only one case will run.
Each Case Block must have a CBREAK and there must be a CDEFAULT even if its never used.

---

## 🧬 Nested Structures

Structured blocks like `IF` and `WHILE` can be nested, as long as you follow macro rules (no overlapping unmatched `@ENDIF` or `@ENDWHILE`).

Example:

```asm
@PUSHI Var1
@IF_GT_V Threshold
   @PUSHI Var2
   @IF_LT_V Limit
      @PRT "Value in range\n"
   @ELSE
      @PRT "Too high\n"
   @ENDIF
@ELSE
   @PRT "Too low\n"
@ENDIF

For readablity you can puts short IF blocks on one line.

@IF_ZERO @ADD 25 @ELSE @SUB 1 @ENDIF
```

This is much cleaner than manually tracking 3–4 labels for control flow.

---

## 🧭 Recap

- Use suffixes like `_V`, `_A`, `_VV`, etc. to control comparison types
- `@IF`, `@WHILE`, `@WHEN`, and `@FOR` macros replace most label-heavy logic
- Complex conditions can be factored out using `@WHEN` + `@DO_NOTZERO`
- `SWITCH` and `CASE` macros help organize multi-path logic
- Nesting is supported and encouraged

Lesson 5 will introduce layout conventions and style guidelines for clean, readable EX716 code.



