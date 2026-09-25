# FuncCalc Language Guide

FuncCalc is a small, interactive, expression-oriented language implemented in
EX716 assembly. It supports signed 32-bit integer arithmetic, strings,
variables, reusable statement lists, and user-defined functions.

## Starting FuncCalc

Run the same source with either the original CPU or the experimental segmented
CPU24 runtime:

```sh
python3 cpu.py tests/FuncCalc.asm
python3 cpu24.py tests/FuncCalc.asm
```

FuncCalc displays an `FC>` prompt. Enter `HELP` for a short command summary and
`QUIT` or `EXIT` to leave.

## Values and identifiers

FuncCalc currently has these user-visible value types:

- Signed 32-bit integers
- Strings
- Stored statement lists
- User-defined functions

Integer literals are decimal. Negative values are formed with unary `-`.
Strings are enclosed in double quotes. String escape sequences are not
currently implemented.

Names begin with a letter or underscore. Remaining characters may contain
letters, digits, underscores, or `$`. Keep the spelling and case of user names
consistent. Commands and built-in function names may be entered in upper- or
lowercase, although the examples use uppercase.

Examples:

```text
COUNT=12
offset_2=-7
GREETING="Hello"
TOTAL$="42"
```

Assigning a new value to an existing name replaces its old value.

## Expressions

The arithmetic operators, from highest to lowest precedence, are:

1. Parentheses and function calls
2. Unary negation: `-value`
3. Multiplication, division, and remainder: `*`, `/`, `%`
4. Addition and subtraction: `+`, `-`
5. Signed comparisons: `<`, `<=`, `>`, `>=`
6. Logical AND: `&&`
7. Logical OR: `||`

Comparisons and logical operators return integer `1` for true and `0` for false. Logical operands use zero as false and any nonzero integer as true.

All arithmetic uses signed 32-bit integers. Arithmetic operators do not
concatenate strings. Division or remainder by zero reports an error.

```text
PRINT 2+3*4
PRINT (2+3)*4
PRINT -12/5
PRINT 17%5
PRINT 10 >= 2
PRINT 1 < 2 && 3 < 4
PRINT 0 || 7

A=100
B=A/4+3
PRINT B
```

An expression may also appear by itself. Its result is evaluated and then
discarded.

## Statements

Multiple statements can be entered on one line by separating them with
semicolons. Semicolons inside a string or parenthesized expression do not split
the line.

```text
A=10; B=20; PRINT A+B
```

### Assignment

```text
name=expression
```

The expression may produce an integer or string. Stored lists and functions are
created with `LIST` and `DEFUN` rather than ordinary assignment.

### Printing

Both forms below are accepted:

```text
PRINT expression
PRINT(expression)
```

Examples:

```text
PRINT 40+2
PRINT "hello"
PRINT STR$(2026)
```

### Ending the session

```text
QUIT
EXIT
```

## Built-in functions

### `ABS(value)`

Returns the absolute value of one integer.

```text
PRINT ABS(-17)
```

### `MIN(value, ...)`

Returns the smallest of one or more integer arguments.

```text
PRINT MIN(8,-3,12,4)
```

### `LEN(string)`

Returns the number of characters in a string.

```text
NAME="Ada"
PRINT LEN(NAME)
```

### `VAL(string)`

Converts a decimal string to a signed 32-bit integer.

```text
N=VAL("1234")
PRINT N+1
```

### `STR$(integer)`

Converts an integer to a decimal string.

```text
TEXT=STR$(-716)
PRINT TEXT
```

### `SPLIT(string, start, stop)`

Returns a substring using inclusive, one-based indexes. `start` must be at
least 1. A stop position beyond the end of the string is clipped to the string
length. Invalid or reversed ranges return an empty string.

```text
PRINT SPLIT("EX716 computer",1,5)
PRINT SPLIT("abcdef",2,4)
```

### `IF(condition, true-expression, false-expression)`

Evaluates the numeric condition and then evaluates only the selected branch.
Zero is false and a nonzero integer is true. Because `IF` is lazy, the branch
not selected has no side effects.

```text
PRINT IF(1,"yes","no")
PRINT IF(0,10/0,42)
```

### `BLOCK(statement; ...)`

Executes a semicolon-separated statement block in the current variable frame.
It is lazy: the statements are executed by `BLOCK`, rather than evaluated as
ordinary function arguments.

```text
BLOCK(A=5; B=A*2; PRINT B)
```

`RETURN` is primarily intended for user-defined functions. A return stops the
remaining statements in the current compiled block.

### `COMMENT(value, ...)`

Accepts and discards its arguments. It is useful for attaching metadata or
notes to stored code without changing the result.

```text
COMMENT("calculate invoice total",2026)
```

## Stored statement lists

`LIST` compiles statements and stores them under a name. `EXEC` runs the stored
list later.

```text
LIST REPORT=A=7; B=A*6; PRINT B
EXEC REPORT
```

The list retains compiled statements, not merely the final result. Variables
are resolved when the list executes, so a list can use values assigned after
the list was created.

```text
LIST SHOW=PRINT VALUE
VALUE=10
EXEC SHOW
VALUE=25
EXEC SHOW
```

## User-defined functions

Begin a definition with `DEFUN name(parameters)`. FuncCalc changes to the
`...` continuation prompt until an `ENDDEF` line is entered.

```text
DEFUN DOUBLE(X)
RETURN X*2
ENDDEF
```

Parameters are stored in a local frame. A function can read global variables,
but assignments to parameter or local names remain in its current frame.
Arguments are evaluated before the function is invoked. The number of supplied
arguments must exactly match the parameter count.

Functions can be called directly in expressions:

```text
PRINT DOUBLE(21)
ANSWER=DOUBLE(10)+1
```

`CALLFUNC` is an interactive command that invokes a function and prints a
returned integer or string:

```text
CALLFUNC DOUBLE(9)
```

Use `RETURN expression` to produce a value and stop the remaining function
body. A function that reaches its end without `RETURN` has no value.

A longer example:

```text
DEFUN SMALLER(A,B)
RETURN IF(A-B,MIN(A,B),A)
ENDDEF

PRINT SMALLER(12,7)
```

Use `LISTFUNC` to inspect a stored function's parameters and compiled body:

```text
LISTFUNC DOUBLE
```

## Variables and memory commands

### `MEMVAR`

Lists active global variables and, while a function is running, its local
variables.

### `MEM`

Displays variable-table counts, available heap memory, variables, and the heap
object map.

### `CLEAN name`

Deletes one variable and releases its owned value:

```text
CLEAN TEMP
```

### `CLEAN`

Deletes all active variables, stored lists, and functions:

```text
CLEAN
```

### `DEBUG ON` and `DEBUG OFF`

Enable or disable FuncCalc's parser and function-call diagnostics.

## Example sessions

### Unit conversion

```text
FC> DEFUN FTOC(F)
... RETURN (F-32)*5/9
... ENDDEF
OK
FC> PRINT FTOC(77)
25
```

### String extraction

```text
FC> RECORD="EX716:READY"
FC> MODEL=SPLIT(RECORD,1,5)
FC> STATE=SPLIT(RECORD,7,LEN(RECORD))
FC> PRINT MODEL
EX716
FC> PRINT STATE
READY
```

### Reusable calculation

```text
FC> LIST TOTAL=SUBTOTAL=1250; TAX=SUBTOTAL*7/100; PRINT SUBTOTAL+TAX
OK
FC> EXEC TOTAL
1337
```

## Current limitations

- `WHILE` support is only a placeholder and is not part of the usable language.
- Arithmetic operators accept integers only; strings are not concatenated.
- String literals do not support escape sequences.
- Integer literals are decimal only.
- FuncCalc is an experimental interpreter and reports most language failures
  as `ERR ...` messages rather than recovering with structured exceptions.
