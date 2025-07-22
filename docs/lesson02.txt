# Our First Lesson

When we talk about the EX716 we are actually working with the program
cpu.py which has several modes and does multiple things related to
this CPU. The biggest separate parts are the Assembler and the
Emulator.

For this lesson we are going to talk about some of the most basic
concepts behind the Assembler and as an example, we'll use it not to
do Assembly Language, but something more like Machine Language and
build up from there.

1) The core purpose of the Assembler is to turn instructions into code
and data, which as laid out in the memory of the CPU to hopefully do
something useful when we execute it.

2) The Assembler has very limited knowledge about the CPU and what it
can do, so it trusts you the programmer to tell it what to do and will
do it blindly. Or in other words, the Assembler will do what you TELL
it to do, but that may not be the same as what you WANT it to do.

3) The goal, in as much as it has one, of the Assembler is to put
numbers into memory. Its most core logic loop is:
     a) Has the user given me a valid number? If not can I turn it
     into a number?
     b) Is it a byte, word or perhaps something bigger?
     c) Save it into memory at the current insertion point.
     d) Move the insertion point forward by the number of bytes the
     data took up.
     e) Repeat until you've run out of input.

Everything else the Assembler does is in service of this loop.
That part of line 'a' that said 'If not can I turn it into a number?'
is where much of the meat and potato power of the Assembler comes
from, and it's complex and extensive, so for now... we'll ignore it and
for our first steps into the Assembly, we will only give it clear
numbers and forget using symbols and other complex concepts. Don't
worry, we'll get to them soon enough.

Another term for giving a CPU just numbers rather than Assembly
language is 'machine code'. So our first project is going to be pure
machine code.

There are a bit over 50 machine code instructions the CPU can
understand, but we'll work with a very limited subset for now.

Byte  Length  Common Name  Description
0x01     3    PUSH         Push the direct parameter value onto the stack
0x03     3    PUSHI        Pushes value stored at address to stack
0x06     1    POPNULL      Drops TOS off stack
0x08     3    POPI         Pops value on stack to be stored at address
0x0B     1    CMPS         Sets logic flags
0x10     1    ADDS         Adds top two values on stack
0x23     3    JMPZ         If Z flag is set, jump to address; else fall through
0x24     3    JMP          Absolute jump to address
0x25     3    CAST         Write output to device
0x26     3    POLL         Read input from device

.ORG is used to move the insert point to a specific memory address.
It also tells the emulator what address will be the start of the
program. You can have multiple .ORGs in a file; just the last one
identifies the start address of the program.

CAST and POLL is how we do IO and also provide CPU control like
halt and enabling I/O-based debugging. They receive a device code from
the top of the stack and an argument for address or data.

This is a limited subset of the device control codes for our test.

POLL table:
Code   TOS      Argument
 0x1   Address  Allows user to enter +/- 16-bit decimal number
 0x2   Address  Reads line of raw text to Address

CAST table:
 0x1   Address  Print null-terminated string at Address
 0x4   Address  Print signed number at Address
 0x63  —        Ends the program
 0x64  —        Drops to Debugger

Now we need to talk about numbers and their lengths.

EX716 is mostly a 16-bit CPU, so the vast majority of operations work
on 16-bit data. Any number that is not specifically defined as
something else defaults to being a 16-bit integer in little-endian
format. What this means is if you split the 16-bit number into two 8-bit
bytes, the byte that represents the lower part of the word will go into
memory first, and the upper byte follows.

For example, 10,000 decimal is 0x2710 in hex. The low byte is 0x10 and
the high byte is 0x27, so it appears 'backward' in memory—this is
natural to the CPU but may look strange to us.

You can enter 16-bit numbers in any of these formats:

 10000         Decimal
 0x2710        Hexadecimal
 0o23420       Octal
 0b10011100010000  Binary

If you want to store an 8-bit value instead of 16-bit, prefix it with `$$`:

 $$0x08      Backspace character
 $$0x32      ASCII code for '2'
 $$127       Largest positive signed value for a byte
 $$-3        Negative byte

32-bit values can be entered with `$$$`, but support is limited:

 $$$2500000  Two million five hundred thousand

Strings are enclosed in double quotes:

 "This is hello world"
 "This one is correctly null terminated\0"
 "This one \"has quotes inside\" the string"

##################################################################
Using just the above, we will write our first program.

It loops from 1 to 10 and prints each number.

Memory layout:
 1) Program starts at memory address 0x100
 2) Variables start at address 0x64 (only one needed)
 3) After initialization, loop starts at a label
 4) Ending condition jumps to cleanup code



Address    OptCode           Note
.ORG 0x64                    Index
.ORG 0x66   "\n\0"           String for Linefeed
.ORG 0x100
    # This is where the program itself will be stored and started from.
           $$01   0          PUSH 0
           $$08   0x64       POPI Index
:LOOPTOP
           $$03   0x64       PUSHI Index
           $$01   10         PUSH 10
           $$0c              CMPS
           $$6               POPNULL
           $$6               POPNULL
           $$23   0x012d     JMPZ to 0x12d End Loop
           $$01   4          CAST Code 4, PRT Int
           $$2a   0x64       CAST 0x64
           $$01   1          CAST Code 1, Print STR
           $$2a   0x66       CAST 0x66
           $$6               POPNULL
           $$6               POPNULL
           $$01   0x01       PUSH 1
           $$03   0x64       PUSHI 0x64           
           $$10   ---        ADDS
           $$08   0x64       POPI 0x64
           $$27   0x27       JMP 0x106
           $$01   63         PUSH 63
           $$2a   x64       CAST 0x64 exist shell

A hex dump of 0x100 to 0x132 should look like
      00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  ASCII
0100: 01 00 00 08 64 00 03 64 00 01 0a 00 0c 06 06 23  ____d__d_______#
0110: 2d 01 01 04 00 2a 64 00 01 01 00 2a 66 00 06 06  -____*d____*f___
0120: 01 01 00 03 64 00 10 08 64 00 27 06 01 01 63 00  ____d___d_'___c_
0130: 2a 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  *_______________

The way we can enter this in EX716 is to start cpu.py in the debug
mode and use the debuggers memory editing tools.

So start cpu with

   cpu.py -g
0000> >>                # This is the default prompt for the debugger.

We first want to add the Line Feed to memory address 0x66

We do that with
0000> >>m 0x66 0x0a
0000> >>hex 0x60
Range is 0060 to 0070
      00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  ASCII
0060: 00 00 00 00 00 00 0a 00 00 00 00 00 00 00 00 00  ________________

Next we start to load the code, we'll use the interactive input mode
of the 'm' command.
0000> >>m 0x100
Key: ### is decimal 0-9 Prepend 0x, 0o or 0b for hex, octal or binary format
By default 16 bit integer, prepend $$ for 8 bit bytes or $$$ for 32 bit words
8 bit ascii codes can be entered using double quotes
Use '.' on line byself to exit back to main mode.

0100[b00,b00]:
0100[b00,b00]: $$01
$$01
0101[b00,b00]: 0
0
0103[b00,b00]: $$0x8
$$0x8
0104[b00,b00]: 0x64
0x64
0106[b00,b00]: $$03
$$03
0107[b00,b00]: 0x64
0x64
0109[b00,b00]: $$0x1
$$0x1
010a[b00,b00]: 10
10
010c[b00,b00]: $$0xc
$$0xc
010d[b00,b00]: $$6
$$6
010e[b00,b00]: $$6
$$6
010f[b00,b00]: $$0x23
$$0x23
0110[b00,b00]: 0x012d
0x012d
0112[b00,b00]: $$0x1
$$0x1
0113[b00,b00]: 4
4
0115[b00,b00]: $$0x2a
$$0x2a
0116[b00,b00]: 0x64
0x64
0118[b00,b00]: $$0x1
$$0x1
0119[b00,b00]: 1
1
011b[b00,b00]: $$0x2a
$$0x2a
011c[b00,b00]: 0x66
0x66
011e[b00,b00]: $$6
$$6
011f[b00,b00]: $$6
$$6
0120[b00,b00]: $$1
$$1
0121[b00,b00]: 1
1
0123[b00,b00]: $$3
$$3
0124[b00,b00]: 0x64
0x64
0126[b00,b00]: $$0x10
$$0x10
0127[b00,b00]: $$0x8
$$0x8
0128[b00,b00]: 0x64
0x64
012a[b00,b00]: $$0x27
$$0x27
012b[b00,b00]: 0x106
0x106
012d[b00,b00]: $$0x1
$$0x1
012e[b00,b00]: 0x63
0x63
0130[b00,b00]: $$0x2a
$$0x2a
0131[b00,b00]: .

0000> >>



Once entered via debugger's memory input mode (`m 0x100`), you can
verify with:

 >> hex 0x100 0x31

If the dump matches expected bytes, run with:

 >> r 0x100
 >> c

Expected output:

 0
 1
 2
 3
 ...
 9

END of Run: (360 Opts)



###############################################################
From Machine Code to Assembly: A Gentle Transition
###############################################################

Now that you've completed the machine code exercise, you have a solid
example of how much manual effort it takes to write even a simple
program. This highlights how much more productive you will be using
Assembly language instead.

The next step is to move toward a full-featured assembly approach.

We’ll begin by introducing a stripped-down assembly file that uses
labels, symbolic opcodes, and named constants — but without invoking
the full macro library yet.

---

Put the following into a file named: example1.asm

#---------------------------------------------------------------
# Define minimal opcode macros — just symbolic names for now.
# These tell the assembler to treat them as 8-bit opcodes.
#---------------------------------------------------------------

M PUSH    $$0x01
M PUSHI   $$0x03
M POPNULL $$0x06
M POPI    $$0x08
M CMPS    $$0x0C
M ADDS    $$0x10
M JMPZ    $$0x23
M JMP     $$0x27
M CAST    $$0x2A
M POLL    $$0x2B

#---------------------------------------------------------------
# Define symbolic device codes for use with CAST and POLL
#---------------------------------------------------------------

=CASTSTR    0x01
=CASTINT    0x04
=CASTEND    0x63
=CASTDEBUG  0x64
=POLLINPUT  0x01
=POLLLINE   0x02

#---------------------------------------------------------------
# Use labels instead of raw addresses for better readability
#---------------------------------------------------------------

:Index    0
:NewLine  "\n"
          0         # Null terminator for NewLine string

.ORG 0x100
  # Initialize Index = 0
  @PUSH 0
  @POPI Index

  # Start of main loop
:LOOPTOP
  @PUSHI Index
  @PUSH 10
  @CMPS

  # Clear CMPS result
  @POPNULL
  @POPNULL

  # Jump to EndLoop if equal
  @JMPZ EndLoop

  # Print value at Index
  @PUSH CASTINT
  @CAST Index

  # Print newline
  @PUSH CASTSTR
  @CAST NewLine

  # Clear leftover CAST args
  @POPNULL
  @POPNULL

  # Increment Index
  @PUSH 1
  @PUSHI Index
  @ADDS
  @POPI Index

  @JMP LOOPTOP

:EndLoop
  @PUSH CASTEND
  @CAST 0


You now understand why Assembly is more productive than raw machine
code. Our next lesson introduces macros for readability and control
structures.


################################################################
End of Lesson 2 – Next: Introduction to Macro-Based Assembly
################################################################

