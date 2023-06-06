# Setup Library
# Values which make up opcodes
#
# The '!' code marks a block to skip if already defined. 
! COMMON_SEEN
M COMMON_SEEN 1
G NOP G PUSH G PUSHB G PUSHI G PUSHII G POPI G POPII G POPB G CMPI G CMPII G JMPZ
G JMPN G JMPC G JMPO G JMP G JMPI G ADD G SUB G AND G OR G INV G ADDI G SUBI
G ANDI G ORI G ADDII G SUBII G ANDII G ORII G CAST G POLL G CPUID G SETAPP G CLEAR
G RRT G RLTC G RTR G RTL G FCLR G FSAV G FLOD

=NOP 0
=PUSH 1
=DUP 2
=PUSHI 3
=PUSHII 4
=PUSHS 5
=POPNULL 6
=SWP 7
=POPI 8
=POPII 9
=POPS 10
=CMP 11
=CMPS 12
=CMPI 13
=CMPII 14
=ADD 15
=ADDS 16
=ADDI 17
=ADDII 18
=SUB 19
=SUBS 20
=SUBI 21
=SUBII 22
=OR 23
=ORS 24
=ORI 25
=ORII 26
=AND 27
=ANDS 28
=ANDI 29
=ANDII 30
=JMPZ 31
=JMPN 32
=JMPC 33
=JMPO 34
=JMP 35
=JMPI 36
=CAST 37
=POLL 38
=RRTC 39
=RLTC 40
=RTR 41
=RTL 42
=INV 43
=COMP2 44
=FCLR 45
=FSAV 46
=FLOD 47

# Cast and Poll Codes
=CastPrintStrI 1
=CastPrintInt 2
=CastPrintIntI 3
=CastPrintSignI 4
=CastPrintBinI 5
=CastPrintChar 6
=CastPrintStrII 11
=CastPrintCharI 16
=CastPrintHexI 17
=CastPrintHexII 18
=CastPrint32Int 32
=CastSelectDisk 20
=CastSeekDisk 21
=CastWriteBlock 22
=CastSyncDisk 23
=CastPrint32I 32
=CastPrint32S 33
=PollReadIntI 1
=PollReadStrI 2
=PollReadCharI 3
=PollSetNoEcho 4
=PollSetEcho 5
=PollReadBlock 22


# Warning about Macros
# When defining a macro you can refrence other  macros on the same line.
# When executing a macro, the rule is one macro per line.
M NOP b$NOP
M PUSH b$PUSH %1
M DUP b$DUP
M PUSHI b$PUSHI %1
M PUSHII b$PUSHII %1
M PUSHS b$PUSHS
M POPNULL b$POPNULL
M SWP b$SWP
M POPI b$POPI %1
M POPII b$POPII %1
M POPS b$POPS
M CMP b$CMP %1
M CMPS b$CMPS
M CMPI b$CMPI %1
M CMPII b$CMPII %1
M ADD b$ADD %1
M ADDS b$ADDS
M ADDI b$ADDI %1
M ADDII b$ADDII %1
M SUB b$SUB %1          # (updated SUB ~ TOS=(TOS-P1))
M SUBS b$SUBS
M SUBI b$SUBI %1
M SUBII b$SUBII %1
M OR b$OR %1
M ORS b$ORS
M ORI b$ORI %1
M ORII b$ORII %1
M AND b$AND %1
M ANDS b$ANDS
M ANDI b$ANDI %1
M ANDII b$ANDII %1
M JMPZ b$JMPZ %1
M JMPN b$JMPN %1
M JMPC b$JMPC %1
M JMPO b$JMPO %1
M JMP b$JMP %1
M JMPI b$JMPI %1
M CAST b$CAST %1
M POLL b$POLL %1
  M RRTC b$RRTC
M RLTC b$RLTC
M RTR b$RTR
M RTL b$RTL
M INV b$INV
M COMP2 b$COMP2
M FCLR b$FCLR                  # the F group is for clearing, saving, and loading Flag states. Usefill in Interupts
M FSAV b$FSAV
M FLOD b$FLOD

M MA2V @PUSH %1 @POPI %2   # Move Constant to Memory
M MA2V @PUSH %1 @POPI %2   # Another way to say it, move Constant A to Variable
M MV2V @PUSHI %1 @POPI %2  # Move Memory to Memory
M MV2V @PUSHI %1 @POPI %2  # Another way to say it, Move Variable to Variable
M MMI2M @PUSHII %1 @POPI %2
M MM2IM @PUSHI %1 @POPII %2
M JMPNZ @JMPZ $%01 @JMP %1 :%01        # A != B
M JMPNZI @JMPZ $%01 @JMPI %1 :%0
M JMPZI @JMPNZ $%01 @JMPI %1 :%0
M JMPNC @JMPC $%0SKIP @JMP %1 :%0SKIP  # No Carry
M JMPNO @JMPO $%01 @JMP %1 :%01        # No Overflow
#  For this group, remeber the flags are based on the B-A
#  Example PUSH A20 PUSH B30 CMPS, flag would  be N as 20 < 30 
#          PUSH A40 PUSH B20 CMPS, FLAG would be !N as 40 > 20
M JGT @JMPN %1                           # A=A-B, if B>A or A<=B JMP %1
M JGE @JMPN %1 @JMPZ %1                  # A=A-B, if B>=A or A<B JMP %1
M JLT @JMPZ %0Skp @JMPN %0Skp @JMP %1 :%0Skp   #  if B<A or A>=B JMP %1
M JLE @JMPN %0Skp @JMP %1 :%0Skp         # A=A-B, if B<=A or A>B JMP %1
M CALL @PUSH $%01 @JMP %1 :%01
M CALLZ @PUSH $%0_Loc @JMPZ %0_Do @JMP %0_After :%0_Do @JMP %1 :%0_Loc :%0_After
M CALLNZ @PUSH $%0_Loc @JMPZ %0_After @JMP %1 :%0_Loc :%0_After
M RET @POPI $%0D @JMPI $%0D :%0D 0
M JNZ @JMPZ $%0J @JMP %1 :%0J
M JZ @JMPZ %1                           # Just an abbriviation as its really commonly used.
# Simple Text output for headers or labels, LN includes linefeed.
# Print simple test message with no variables and LineFeed
M PRTLN @JMP $%01 :%0M %1 b0 :%0NL 10 b0 :%01 @PUSH CastPrintStrI @CAST $%0M @CAST $%0NL @POPNULL
# Print simple test message with no variables no linefeed
M PRT @JMP J%0J1 :%0M1 %1 0 :J%0J1 @PUSH CastPrintStrI @CAST $%0M1 @POPNULL
# Print value of variable
M PRTI @PUSH CastPrintIntI @CAST %1 @POPNULL
# Print value of variable in Hex
M PRTHEXI @PUSH CastPrintHexI @CAST %1 @POPNULL
# Print value Pointer is pointing at in Hex
M PRTHEXII @PUSH CastPrintHexII @CAST %1 @POPNULL
# Print value of variable but surrounded with spaces for readability
M PRTIC @PRT " " @PUSH CastPrintIntI @CAST %1 @POPNULL @PRT " "
# Print string starting at address
M PRTS @PUSH CastPrintStrI @CAST %1 @POPNULL
# Print string starting at the address that is stored AT the given pointer.
M PRTSI @PUSHI %1 @POPI %0ptr @PUSH CastPrintStrI @CAST :%0ptr 0 @POPNULL
# Print value Pointer is pointing at.
M PRTII @PUSHII %1 @POPI %0Store \
        @PUSH CastPrintInt @CAST :%0Store 0 @POPNULL
# Print value with sign '-' if negative
M PRTSGNI @PUSH CastPrintSignI @CAST %1 @POPNULL
# Print value in binary
M PRTBINI @PUSH CastPrintBinI @CAST %1 @POPNULL
# Print Line feed
M PRTNL @JMP $%01 :%0NL 10 b0 :%01 @PUSH CastPrintStrI @CAST $%0NL @POPNULL
# Print a space by itself
M PRTSP @JMP $%01J :%0M " " b0 :%01J @PUSH CastPrintStrI @CAST $%0M @POPNULL
# Print string start at address
M PRTSTRI @PUSH CastPrintStrI @CAST %1 @POPNULL
# Print immediate value (usefull to print value of pointer)
M PRTREF @PUSH CastPrintInt @CAST %1 @POPNULL
# Print top value in stack but leave it there.
M PRTTOP @DUP @JMP J%0J1 :%0M1 0 :J%0J1 @POPI %0M1 @PRTI %0M1
# Print 32bit number starting at address
M PRT32I @PUSH CastPrint32Int @CAST %1 @POPNULL
#
M PRT32S @PUSH CastPrint32S @CAST 0 @POPNULL
# Read an Integer from keyboard
M READI @PUSH PollReadIntI @POLL %1 @POPNULL
# Print Prompt string, then read integer.
M PROMPT @PRT %1 @READI %2
# Read a String from Keyboard
M READS @PUSH PollReadStrI @POLL %1 @POPNULL
# Read a unechoed character from keyboard
M READC @PUSH PollReadCharI @POLL %1 @POPNULL
# Turn Keyboard echo off
M TTYNOECHO @PUSH PollSetNoEcho @POLL %1 @POPNULL
# Turn KeyBoard echo on
M TTYECHO @PUSH PollSetEcho @POLL %1 @POPNULL
# End Program
M END @PUSH 99 @CAST 0
# Like POPI but leaves copy of value on stack
M TOP @DUP @POPI %1
# Print a debug dump of the stack
M StackDump @JMP %0J :%0J @PUSH 102 @CAST 0 @POPNULL
# Adds one to variable
M INCI @PUSHI %1 @ADD 1 @POPI %1
# Subtracts one from variable
M DECI @PUSHI %1 @SUB 1 @POPI %1
# Adds two to variable
M INC2I @PUSHI %1 @ADD 2 @POPI %1
# Subtracts one from variable
M DEC2I @PUSHI %1 @SUB 2 @POPI %1

# A way to impliment a 16 bit 2 comp ABS function
M ABSI @PUSH 0x8000 @ANDI %1 @CMP 0 @POPNULL @PUSHI %1 @JMPZ %0IsPos @COMP2 :%0IsPos
# Disk IO Group
M DISKSELI @PUSH CastSelectDisk @CAST %1 @POPNULL
M DISKSEL @MA2V %1 %0_store @PUSH CastSelectDisk @CAST %0_store @JMP %0_End :%0_store 0 :%0_End @POPNULL
M DISKSEEKI @PUSH CastSeekDisk @CAST %1 @POPNULL
M DISKSEEK @MA2V %1 %0_store @PUSH CastSeekDisk @CAST %0_store @JMP %0_End :%0_store 0 :%0_End @POPNULL
# No point of an 'I' version of DISKWRITE or READ as target is always a buffer.
M DISKWRITE @PUSH CastWriteBlock @CAST %1 @POPNULL
M DISKSYNC @PUSH CastSyncDisk @CAST 0 @POPNULL
M DISKREADI @PUSH PollReadBlock @POLL %1 @POPNULL
M DISKREAD @JMP %0_jmp :%0_data 0 :%0_jmp @PUSH %1 @POPI %0_data @PUSH PollReadBlock @POLL %0_data @POPNULL
#M DISKREAD @JMP %0_jmp :%0_data %1 :%0_jmp @PUSH PollReadBlock @POLL %0_data @POPNULL
#M DISKREADI @JMP %0_jmp :%0_data 0 :%0_jmp @PUSHI %1 @POPI %0_data @PUSH PollReadBlock @POLL %0_data @POPNULL
#M DISKREADI @PUSH PollReadBlock @POLL %1 @POPNULL

# A way to enable/disable debugging in running code without requireing the -g option.
M DEBUGTOGGLE @PUSH 100 @CAST 0 @POPNULL
#
# FOR NEXT WHILE and CASE logic structures can be found in this related file.
I structure.asm
ENDBLOCK
