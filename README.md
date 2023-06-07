# EX716
An experimental 'toy' CPU emulator based on a 'fictional' 1970's micro computer concepts. Target is be able to experiment with Assembly/Machine Code without the 'compromises and overhead' of 'real' classic CPU's  
The EX716 has no 'practical' use in that it would be easily out performed by even the cheapest off the shelf modern
micro controller. Yet I feel it has some value as a training tool and as an assembly language 'toy'

Unlike emulations of 'real' CPU's this idealized instruction set, has fewer restrictions on mixing modes and fewer
'specialized' instructions. A fairly consistent instruction set with
few restrictions. Little-Endian storage for all large numbers.

EX716 is an imaginary CPU that 'could' have been designed in the 1970s and has characteristics similar to the types of
CPU's available then with design hints taken from such classic CPUs as the 8085, 1802 and some of the specialized
hardware of the original Apple 1. It could be described as a hybrid 8bit/16bit architecture.

A Physical description of a non existent CPU:
           Internal 16bit data path and ALU
           Internal PC and Flag registers, not normality user accessible.
           64K of directly accessible memory.
           255 byte or 127 16b word hardware stack.
           The one accessible user register is also the top of the hardware stack.
           No hardware floating point or BCD
           Very limited, or no soft interrupts.
           Most suitable for single threaded processes.

           External hardware  ports would include 48-64 pin package.
                    24 bit data bus (could be serialized or split into 3 read cycles of 8 bits) as the most common
                    'instruction read' is a 8b opcode followed by 16b parameter. Normal memory reads would use 16b
                    16 bit address bus.
                    A possible external page register could be tied to an IO channel to provide some sort of larger memory.
                    read/write/ready Flags: To support external memory
                    Data/Memory Flag: To support specialized Data CAST POLL instructions
                    Chip Disable Flag: To support DMA hardware.

           Memory Addressing Modes.
              The single most useful feature of the EX716 is it's range of flexible addressing modes.

              First, define what addressing modes are:

              While there are exceptions, the vast majority of all the computer instructions the EX716 understands are
              for the manipulation of one or two 16 bit numbers. For example adding is by default, adding two 16 bit
              numbers together, while logical jumps can change the PC to a given 16 bit address. Addressing modes is the
              different ways you tell the current OPCODE where that 16b number is in memory.
             For Instructions that require two numbers, the first number will be on the HW stack as
              the  'Accumulator'.
              Instructions that do not have an explicit destination for its results will default to
              saving the result in the Accumulator which is also the top of HW stack.

              The Majority of the instructions are a 8 bit opcode (OPT) followed by a 16 bit
              parameter.(PRM) (For efficiency a read cycle that reads 24 bits as the Instruction Load
              state makes sense)

              Addressing Modes:

                        Direct: The PRM is the value to be used. There are no 'write' versions of Direct. Read
                        with the OPT, little additional time required.

                        Indirect: The PRM is the Memory Address where
                        the value is stored or written to.  Requires an additional read/write cycle to fetch or put
                        value.

                        Dbl. Indirect: The PRM is pointing to a memory address WHERE there is another 16b number
                        that is the Address where the value is stored or written to.  Require 2 additional read/write
                        cycles to fetch or put value.

                        Stack: The top two numbers on the stack will
                        both be used as values and for OPTs that
                        return a numeric result, they will normally
                        both be replaced by a single number. PRM is
                        not read or used.  If determined early enough
                        could skip the PRM read, otherwise takes same
                        number of cycles as Direct.

              Instruction 'Groups' Most instructions are in groups where the names of otherwise
              identical functions will vary based on the Addressing Mode it is being used with.

              Direct:       Just the abbreviated name, followed by a space.
                                 Example: ADD, CMP, PUSH
              Indirect      Single capital 'I'
                                 Example: ADDI, POPI, CMPI
              Dbl. Indirect Double capital 'II'
                                 Example: ADDII, POPII, PUSHII
              Stack:        Single capital 'S'
                                 Example: ADDS, CMPS
                                 
                                 
                                 
              Groups:

              PUSH
                PUSH, PUSHI, PUSHII, PUSHS

                Saves Value to top of  HW stack.

		In case of PUSHS, takes value at Top of Stack, uses as address, and replaces it with
		value stored at that address.

              POP
                POPI, POPII, POPS

                Removes top of HW stack and stores it at target address (POPS uses top of stack
                as address and second item on stack as value to be POP'ed both are removed from stack)

              CMP
                CMP, CMPI, CMPII, CMPS

                For setting logic flags, compares two values non-destructively. (Note stack is left
                unchanged, so remember to pop off unneeded values if your not comparing them any
                more) Order matters and same rules apply as in Subtraction.

              ADD
                ADD, ADDI, ADDII, ADDS

                Adds two values, sets logic flags, and saves result to top of stack. Destructive of
                current top of stack, and in case of ADDS, destructive top two stack values.

              SUB
                SUB, SUBI, SUBII, SUBS

                Subtracts two values, sets logic flags, and saves result to top of stack. Destructive of
                current top of stack, and in case of ADDS, destructive top two stack values. Order of paramters
		matter in subtraction, so the rule is, the first paramater(A) is what is on the stack first, then
		the second parameter(B) is based on the operator mode. Order is A-B and stored on replacing
		original stack value. To Be Clear, SUBS means subtrace Top of Stack FROM Second From Top Of Stack.
		Pop both off and save result to stack. PUSH 11 PUSH 3 SUBS results in 4 on stack, not -8.

              OR
                OR, ORI, ORII, ORS

                bitwise OR function on  two values, sets logic flags, and saves result to top of
                stack. Destructive of current top of stack, and in case of ADDS, destructive top two
                stack values.

             AND
                AND, ANDI, ANDII, ANDS

                bitwise AND function on  two values, sets logic flags, and saves result to top of
                stack. Destructive of current top of stack, and in case of ADDS, destructive top two
                stack values.

       The following groups are more specialized and do not follow the same addressing pattern.

             JMP,
                Unconditionally jumps to the address of PRM

             JMPZ,
                Jumps to address of PRM if Z flag is set (set if result of CMP or math == 0)

             JMPN,
                Jumps to address of PRM if N flag is set (set if result of CMP or math < 0)

             JMPO,
                Jumps to address of PRM if O flag is set (Overflow flag is used after subtractions)

             JMPI,
                Unconditional Jump to address stored AT the address PRM points to.

             NOP,        1 byte opcode, No PRM
                No Instruction, skips PC to next instruction, does take some clock cycles so can be
                used for timing.

             DUP,        1 byte opcode, No PRM
                Duplicate the top of stack so top two values are the same. Especially useful as a way
                to preserve a value before modifying it.

             SWP,        1 byte opcode, No PRM
                Swaps the top two values on the stack. Especially useful in cases where the order
                data is discovered is different than the order it needs to be processed.

             CAST
                Main non-memory mapped, data output call. Both the stack and a 16b Direct value are
                available as parameters to the output device 'driver' Typically the Top of Stack
                                would hold the 'device ID' and the PRM would point to memory where output value is
                read from. In a HW version of the CPU, the CAST command would probably be implemented as a soft
                interrupt, and in that version could be used a way to gain access to the normally hidden PC and Flag
                registers.

             POLL
                Main non-memory mapped, data input call. Both the stack and a 16b Direct value are
                available as parameters to the output device 'driver' Typically the Top of Stack
                would hold the 'device ID' and the PRM would point to memory where output value is
                stored to.

                ( The reason they are named CAST and POLL, rather than the more descriptive 'D-IN' and 'D-OUT' was in
                the early draft of this project, they would be used as IO to a 'on chip' hardware network in the
                application of multi-core version of the CPU. The names stuck, but the multi-core version is left as a
                future project)

             Bit Rotate Commands, 1 byte opcode, No PRM, affects just top of stack

                RRTC: Rotate Right Through Carry
                RLTC: Rotate Left Through Carry
                RTR:  Rotate Right
                RTL:  Rotate Left
                             The difference between 'Through Carry' and normal rotates is, in  a
                normal rotate, the 'last' bit in whichever direction is moved into the Carry Flag but
                in 'Through Carry' the Carry bit also acts as the 'input' and its previous state is
                copied into the first bit of the rotation. (Highest or lowest depending on direction)
                Through Carry: ==   CF > ROTATE > CF
                Normal Rotate: ==   0 > ROTATE > CF

             INV, 1 byte opcode, No PRM affects just top of stack

                Invert all the bits of top of stack. Can be combined with AND or OR to effect NOR and
                NAND logic.

             COMP2, 1 byte opcode, No PRM affects just top of stack
             
                             Invert then adds one to bits of top of stack, also known as the 2's compliment. When
                2' compliment is applied to a number, negative numbers have a natural format that
                works with positive numbers without additional hardware logic required.

             FCLR, Clears Flags. Mostly ment as a way to issolate CMP from previous math.

             FSAV, Pushes to the stack, a compact version of the condiitonal flags. Useful for preserving
	        a conditional state before doing addional calculations before restorting it.

             FLOD, Restors the Flag state from the previous FSAV. Need to make sure stack is clear back to
	     what it was after FSAV or may result in unwanted flag states.


The 'Macro Assembler'.

The emulator for EX716 has an integrated macro assembler. This assembler does not attempt to follow
the classic MASM or INTEL assemblers in terms of syntax or structure, but represents its own unique
class of assembler.

The main logic loop of the assembler is:

    Until End of File:
          If processing a macro:
             scan it for % variables not in quotes and replace them with text from parameters.
	     There is specail meaning for variables %S and %P used for stack logic.
             make it the current 'line'
          else
             read in one or more lines from input (if line ends with \ append following line)

          strip line of unnecessary white space and comments.
          Parse the line, split it into words and look for:
                'Letter' Codes that define assembler directions or definitions.
                If word starts with a '@' macro, put it into the Macro Queue and loop back to beginning.
                If word is a label or number string, turn into value and store in memory.
                Numeric data, in decimal, octal, hex or binary formats.
                Quoted text is saved as bytes with some support for common \'s codes like \n for newline.

                Big part of the work is handled by the 'Letter' codes, These codes act as reserved words
		so avoid using single letters for Labels or variables:

                    '.' number    :  Sets the active address to number, also sets start address. You can have multiple
                                     '.' entries in a source file to mark off different blocks of memory. If you use any
                                     '.' numbers, you should always add one at the end of your source file to identify
                                     the program entry point.
				     A common notation to use is:
				     :Main . Main
				     Which will make 'Main' the entry point for the program.
                    'I' filename  :  Imports a file as if it was part of the current input stream.
                    'L' filename  :  Loads a Library, all local labels are hidden, see 'G' command
                    ':' Label     :  Unlike others assemblers labels are identified with a proceeding ":"
                    '@' Macro     :  Executes Macro, %1-%9 (max) are the arguments, %0 is unique ID
                    '=' Label Val :  Assigns a fixed 16b numeric value to a label.
                                     Labels and Macros do not share dictionary space, so you
                                     can reuse a Label and Macro with the same names, but mean different things.
                    'P' Print line:  Print rest of line for logging or debugging, at assembly time.
                    '!' Macro     :  The 'only' conditional logic for the Macro system, if the named
                                     Macro is already defined, then skip forward until ENDBLOCK, meant
                                     as a way to keep from loading a given Library file more than
                                     once.
                    'M' Macro line:  Define a new named Macro, line can be extended by ending with
                                     '\' and can contain variables based on parameters %1 to %9 You
                                     can use %0 adjacent with other text to create local unique
                                     variables for each instance of the Macro called.
                    'G' Label        Defines a Label as Global, All the callable addresses defined
                                     inside a library file, need to be declared with 'G'.
				     'G' declarations should be made near top of the file, before the Label is used.
                    Number           16 bit number, save to current working address.
                    0xNumber         Hex number
                    0oNumber         Octal number
                    0bNumber         Binary (01) number
                    bNumber          Forces number to be treated as 8bit byte rather than 16 bit word
		    		    (This also means that lower case 'b' can
                                     not be used as start of any label, use uppercase 'B' where you need them)
                    $$Number         Another way to treat a number as a byte. 
                    $Number          Treat Number as 16b word, (default)
                    $$$Number        32bit number, Purely for storing assembly time values into memory.
                                     Labels CAN NOT hold a full 32 bit number. But a 16b label can point to where in
                                     memory a 32b number is stored.

                    "text"           ASCII text will be copied to memory as bytes, you have to add a "b0" to NULL terminate.

And that's it! All the opcodes along with basic common quality of life macros, are defined in
 the Include file named common.mc combined with  CPU.json

In the common.mc are some extra Macros that make programming easier. All the following are simple Macros and it maybe
worth some time reading through common.mc to see how they are implemented.

@MMI2M %1 %2 : Move word stored at address THAT address [[%1]] points to address [%2]

@MM2IM %1 %2 : Move word stored at address [%1] to be stored at address THAT address [[%2]] points to

@JMPNZ %1    : Inverse logic of JMPZ

@JNZ %1      : Slightly more readable than JMPNZ

@JMPZI %1    : Jumps to an Indirect address [%1] if Z flag is set

@JMPNZI %1   : Inverse of JMPZI for Indirect Jumps

@JMPNC %1    : Inverse logic of JMPC

@JMPNO %1    : Inverse logic of JMPO

@JLT %1      : More 'readable' version of JMPN, if the last CMP A was < B
               Worth remembering that A is what is put on stack first. B is the PRM or in case of
	       CMPS the next (top) item on the stack.

@JLE %1      : JMP if last CMP A <= B

@JGE %1      : JMP if last CMP A >= B

@JGT %1      : JMP if last CMP A > B

@CALL %1     : handles overhead of pushing return address to HW stack, then calling address %1

@RET         : Handles the Return from CALL...make sure that the return address is still at top

The following Macros are in commmon.mc and provide basic IO, but this is the emulator doing the
'work' and it is left as an exercise to re-write them as 'native' code.

@PRTLN %1    : %1 needs to be a quoted text string constant, print it with a Newline at the end.

@PRT %1      : Like PRTLN but without the ending linefeed. Use it as part of formatted output.

@PRTI %1     : Print in unsigned decimal the value stored at address [%1] no spaces added.

@PRTII %1    : Print in decimal the Indirect value stored at address [[%1]]

@PRTIC %1    : Like PRTI but padded with a space before and after the number.

@PRTS %1     : Print the null terminated ASCII string starting at address [%1:...] b0

@PRTSGN %1   : Print the Signed decimal the value stored at address [%1] no spaces added.

@PRTBIN %1   : Print the value at address [%1] as a 0/1 binary string.

@PRTHEXI %1  : Print the 16b hex value at address [%1]

@PRTNL       : Print just a linefeed

@PRTSP       : Print Just a space.

@PRTSTRI     : More verbose was to say PRTS

@PRTREF %1   : Print the constant given, good for printing actual address of labels

@PRT32I %1   : Prints the value of the 32b signed word starting at address %1

@READI %1    : Read 16b decimal number from keyboard, save to [%1]

@READS %1    : Reads ASCII string from keyboard save it to null terminated buffer starting at %1, LF changed to NULL

@READC %1    : Read one character from keyboard saves it at buffer starting at %1.
               2 or 3 bytes are possible for speical keys, does not echo.

@END         : Tells the emulator to exit

@TOP %1      : Copies rather than POP's top of HW stack to address [%1]

@StackDump   : Emulator driven printout of the current stack state.

@INCI %1     : Adds one to the value at given address [%1] WILL Affect logic flags

@INC2I %1    : Adds two to the value at [%1] since data is 16bit and address are on 8bit boundaries. This is frequently needed.

@DECI %1     : Subtracts one to the value at given address [%1] WILL Affect logic flags

@DEC2I %1    : Subtracts two from the value at [%1], same reason as INC2I

Worth nothing that in several macros the following notation is used:
    If the macro is going to work on multiple parameters, use of 'A','B','C' to mean the parameter at that
    location is a numeric constant. Other wise use 'V' to be variable and should be a label or address where
    that variable value is stored.

@MA2V %1 %2  : Move Constant A to Variable Address . Moves value of %1 to address [%2] Both can also be labels

@MV2V %1 %2  : Move word stored at address [%1] to be stored at address [%2]

You willl also see this use of 'A' 'B' and 'V' in some of the structured programing macros like @ForIA2B

    
@DEBUGTOGGLE     : A macro that directs the emulator to start/stop printing out each instruction as it
is executed. The output of the debug, Output of debug listed is in format

For PRM type commands:

Hex Address  Opcode  PRM[PRM]->[[PRM]]   Flags SP:Stack Depth

or

:label followed by some of the Internal symbol values of label which include the line number and filename.

or for S type commands

Hex Address Opcode HW mini Stack Dump

---------------------------The Structure Macros--------------------

The Macros above are all 'simple' combining several normal operations in some sequence. The most complex
part of them is the idea of local storage or branching lables within a macro.
What follows is a much more complex set of macros that almost emulate mid level language structures
One feature of these macros is they invoke a concept of a Macro Stack, which is a simulated stack that
only has meaning durring the assembly stage of a program and does not 'exist' durring the execution of the
program, but can have major effect on the flow control The main purpose of these stacks is to allow the
Macro system to keep track of 'nested' loops and if blocks.

Unlike 'higher' level languages when these Macros present a condition statment like an IF or a WHILE it
can only perform an elemntry test, not a compond test like you can do in a higher level language. So a
concept like 'IF FLAG=True' is possible, but something like 'IF FLAG=True AND Index>100' To do something like
this, you would have to use two IF Macros, one for the FLAG test and another for the Index test.

The IF_ Family:
all Macros in the 'IF' Family follow the pattern of
@IF_rules parameters
  code
[@ELSE
   code]
@ENDIF
Members or the IF family include:
IF_ZERO    : True if TOS is Zero
IF_NOTZERO : True if TOS is anything but Zero
IF_EQ_S    : True if TOS and SFT are equal
IF_EQ_A    : True if TOS and Constant A are equal
IF_EQ_V    : True if TOS and value stored at address V are equal
IF_EQ_VV   : True if value stored at address V1 is equal to value at address V2
IF_LT_S    : True if SFT < TOS
IF_LT_A    : True if TOS < Constant A
IF_LT_V    : True if TOS < value stored at address V
IF_LE_S    : True if SFT <= TOS
IF_LE_A    : True if TOS <= Constant A
IF_LE_V    : True if TOS <= value stored at address V
IF_GE_S    : True if SFT >= TOS
IF_GE_A    : True if TOS >= Constant A
IF_GE_V    : True if TOS >= value stored at address V
IF_GT_S    : True if SFT > TOS
IF_GT_A    : True if TOS > Constant A
IF_GT_V    : True if TOS > value stored at address V


Now the WHILE group:
The WHILE group tests for the condition only at the 'top' of the loop.
So you should prepare the state before the while loop starts and refresh
it towards the bottom of the loop. 
WHILE_ZERO       : Continue Loop if TOS == Zero
WHILE_NOTZERO    : Continue Loop if TOS does not equal Zero
WHILE_EQ_A       : Continue Loop if TOS equals constant A
WHILE_NEQ_A      : Continue Loop if TOS does not equal constant A
WHILE_EQ_V       : Continue Loop if TOS equals value at address V
WHILE_NEQ_V      : Continue Loop if TOS does not equals value at address V

The LOOP group:
The LOOP group tests for the condition at the END of the loop (so it will do it at least once)
As DO LOOP is less frequently than WHILE DO, we only supor the ZERO and NOTZERO tests
@LOOP
  code
@UNTIL_ZERO      : Exits the Loop if TOS equals Zero
@UNTIL_NOTZERO   : Exits the Loop if TOS does not equal Zero

The SWITCH/CASE Group
The Switch Structure is restricted to only a single 16bit value stored at TOS as the condition value.
Use like
     @PUSHI TestValue
     @SWITCH
     @CASE 1
          code
	  @CBREAK      (required fall though not allowed)
     @CASE_RANGE 2 6
          code
	  @CBREAK
     @CASE_REF VarValue
          code
	  @CBREAK
     @CDEFAULT          (Required)
          code
	  @CBREAK       (Required!)
     @ENDCASE

CASE A          : do block if Constant A equals TOS
CASE_RAGE A B   : do block if constant A <= TOS <= constant B
CASE_REF V      : do block if value at address V is equal TOS
CDEFAULT        : REQUIRED what to do if no Case matches.
@ENDCASE        : Exit point of all blocks.


The FOR loop Macors.
One change from typical 'FOR' loops in higher level languages, is that the loop will exit
immediaatly from the top of the loop, once the ending state is reached, so a loop from 1 to 10 will
only run the code block from 1 to 9 and exit on 10.
Also the Index is a SIGNED number, so rangnes over 0x7fff will require starting with a negative value.
Typical use
  @ForIA2V Index 1 TopValue
     code
  @Next Index           (The Variable must match both For and Next)

ForIA2B Index 1 10 : Index will start at 1 and loop until it equals 10
ForIA2V Index 10 V : Index will start at 10 and loop until it equals value at address V
ForIV2A Index V 100: Index will start at value at address V and exit when it equals 100
ForIV2V Index V1 V2: Index will start at value at V1 and exit when it equals value at V2

Next also has variations which can allow 'reverse' loops or do calculated increments

Next Index         : Basic Index, will Increment Index by 1 each time.
NextBY Index A     : Will add constant A to Index (A can be negative)
NextByI Index V    : Will add value at V to Index (might be negative or anything)

One issue to keep track off, the end condition requires Index to match a value Exactly
It is NOT For Index 1 to 'somthing over 10' but must match 10 exactly to exit.

--------------------------------------------------------------------

Using the cpu.py tool and its options.

Make sure cpu.py is executable with the correct python3 set on the #! top line.

Normal operation is to run it like:

       ./cpy.py input_file [ flags ]

Include and Library files should be set a colon separated list in the Envirmental Variable 'CPUPATH' or by default as
sub-directories in the current working directory ./lib/ and ./test/

Optional Command Line Arguments:

-c       Will output as a new file named 'filename'.o a 'pre-compiled' object version of the current source file. There is no runtime performance benefit to this 'compilation' but the output will be just spaces and hex digits so it might  compress better and certainly would hide the program logic for 'security though obscurity' type distribution.
 Lastly, this output format is what the fcpu emulator uses as input. fcpu is a stripped down version of the emulator that written in C and runs many times faster than the python version.

-d       Debug mode, one -d will print out each optcode as its executed, two -d's will also step though the expansion of macros durring the assembly stage.

-g       Enter the interactive debugger. (See Below)

-l       List the disassemble of the compiled code, useful to have on hand when about to debugging as it will identify the memory locations instructions end up, which is what you need for breakpoints in the debugger.

-r       Enable remote Python Debugger, see python documentation but purpose is to debug the underlying python code behind the CPU emulator in a secondary terminal

----------------------------------------------------------------------
The Debugger:

There is a built in debugger which lets you set breakpoints, single step though code, and print memory in a verity of
ways. It is inspired by, but not compatible with the classic GDB debugger of gnu tools.

b       Break
        Set a breakpoint, can use 'labels' as targets
	Print existing breakpoints if no parameters given.

c       Continue
        Run without debugger output until next break statement or until program naturally exits.

cb      Clear Breakpoints
        Clear all breakpoints. (Sorry no way to remove just one breakpoint)

d       Disassemble
            If provided with parameters will disassemble the range of memory given.
            First time it is entered by itself, will disassemble the current line the PC is on.
	    Additional 'd' commands will disassemble blocks of memory in 20 byte steps.
	    Data mixed in with code, can make the disassembly fall out of sequence.

g       Goto, set the PC to an address.

h       Print a help summery

hex     Hex dump a range of memory. 

m       Modify Memory
            If given two or more parameters will treat first word as starting address and rest of parameters as
	    16 bit values to be inserted in to those addresses.
	    If given just one parameter, will use that as the start of memory to modify, then go into a
	    mini modify sub-mode.
	    In this sub-mode you will be prompted with the address and the two bytes starting at that address.
	    address "XXX:[XX,XX]: "
	    You can enter new values as either
	           [$](default): 16 bit integers (allowing for 0x,0o and 0b for non-decimal entry)
		   $$###       : 8 bit integers
		   $$$###      : 32 bit integer
		   "string"    : 8 bit quoted strings.
		   Blank       : Doesn't change value, moves forward to next address.
            You exit the mode by entering a '.' on line by itself.
	    With some care you can use label values if they are already defined in memory. This included
	    all the major opcodes if the common.mc include file has been loaded.

n       Next step
            Execute an instruction, optionally add a count to execute a number of instructions. Will show
	    the disassembly of each instruction before it is executed. (so any values shown will be the 'before'
	    state before the optcode is executed)

s       Step Over
	    Will set a temporary break point at the instruction 'just beyond' the current instruction. Most usefull when calling a sub-routine and want to skip over it without stepping though it one instruction at a time. 
   	     

p       Print Address
            Print the value stored at that address, it will also attempt to print the value at the address stored AT
            that address for indirect values.

ps      Print Stack
            dumps the current HW stack, and also attempts to print the values that stack values might be pointing to if
            they happen to be pointers.
	    
q       Quit debugger
            Exits the emulator.

r       Reset
            Resets the PC and stops current state. Might be usefull for restarting debugging, but does NOT reset all memory to its original state, just the PC and flags.

w       Set a memory watchpoints, when disassemble is used, it will also print values at any watch points.

--------------------------------------
Disk IO

The CPU is too primative to directly work with a real disk or filesystem, but we do provide some very basic
disk IO tools. In the validate folder are some code examples that use this.

We have to imagine the hard disks attacheed to this CPU are primative 1970's disk packs. Each disk in the
pack holds a max of 16MB of data, broken up in 64K of 256 byte blocks. All read and wrires are directly
at the block level, so to something like apppending a variable length string to a text file will require some
addditional string processing as well as buffering the block being written to.

Code Macros
@DISKSEL  A  Selects which disk to use with a constant number.
@DISKSELI V  Selects which disk to use with a variable.
@DISKSEEK A  Moves the Disk Head to a Block on that disk. 0-0xffff per disk.
@DISKSEEKI V Same but with Id being a variable.
@DISKWRITE V writes the 256 byte buffer pointed to by V
@DISKREADI V read a 256 byte buffer from disk, at address[V] is the address to write to
@DISKREAD A read a 256 byte buffer from disk, A points directly to where the buffer starts in memory
