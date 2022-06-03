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
=PollReadIntI 1
=PollReadStrI 2
=PollReadCharI 3

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
M SUB b$SUB %1        # Sub Tract %1 FROM top of stack (push A, Sub B == B-A not A-B)
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

M MC2M $$PUSH %1 $$POPI %2
M MM2M $$PUSHI %1 $$POPI %2
M MMI2M $$PUSHII %1 $$POPI %2
M MM2IM $$PUSHI %1 $$POPII %2
M JMPNZ $$JMPZ $%01 $$JMP %1 :%01        # A != B
M JMPNZI $$JMPZ $%01 $$JMPI %1 :%0
M JMPZI @JMPNZ $%01 $$JMPI %1 :%0
M JMPNC $$JMPC $%0SKIP $$JMP %1 :%0SKIP  # No Carry
M JMPNO $$JMPO $%01 $$JMP %1 :%01        # No Overflow
M JLT $$JMPN %1                          # A < B
M JLE $$JMPN %1 $$JMPZ %1                # A <= B
M JGE $$JMPZ %1 $$JMPN $%01 $$JMP %1 :%01   # A >= B
M JGT $$JMPZ $%01 $$JMPN $%01 $$JMP %1 :%01 # A > B
M CALL $$PUSH $%01 $$JMP %1 :%01
M RET $$POPI $%0D $$JMPI $%0D :%0D 0
M JNZ $$JMPZ $%0J $$JMP %1 :%0J
M JZ $$JMPZ %1                           # Just an abbriviation as its really commonly used.
# Simple Text output for headers or labels, LN includes linefeed.
# Print simple test message with no variables and LineFeed
M PRTLN $$JMP $%01 :%0M %1 b0 :%0NL 10 b0 :%01 $$PUSH CastPrintStrI $$CAST $%0M $$CAST $%0NL @POPNULL
# Print simple test message with no variables no linefeed
M PRT @JMP J%0J1 :%0M1 %1 0 :J%0J1 @PUSH CastPrintStrI @CAST $%0M1 @POPNULL
# Print value of variable
M PRTI $$PUSH CastPrintIntI $$CAST %1 @POPNULL
# Print value of variable in Hex
M PRTHEXI $$PUSH CastPrintHexI $$CAST %1 @POPNULL
# Print value Pointer is pointing at in Hex
M PRTHEXII $$PUSH CastPrintHexII $$CAST %1 @POPNULL
# Print value of variable but surrounded with spaces for readability
M PRTIC @PRT " " $$PUSH CastPrintIntI $$CAST %1 @POPNULL @PRT " "
# Print string starting at address
M PRTS $$PUSH CastPrintStrI @CAST %1 @POPNULL
# Print string starting at the address that is stored AT the given pointer.
M PRTSI $$PUSHI %1 $$POPI %0ptr $$PUSH CastPrintStrI @CAST :%0ptr 0 @POPNULL
# Print value Pointer is pointing at.
M PRTII $$JMP $%0Jump1 :%0V1 0 :%0Jump1 $$PUSHII %1 $$POPI $%0V1 @PRTTOP @POPNULL
# Print value with sign '-' if negative
M PRTSGN $$PUSH CastPrintSignI $$CAST %1 @POPNULL
# Print value in binary
M PRTBIN $$PUSH CastPrintBinI $$CAST %1 @POPNULL
# Print Line feed
M PRTNL $$JMP $%01 :%0NL 10 b0 :%01 $$PUSH CastPrintStrI $$CAST $%0NL @POPNULL
# Print a space by itself
M PRTSP $$JMP $%01J :%0M " " b0 :%01J $$PUSH CastPrintStrI $$CAST $%0M @POPNULL
# Print string start at address
M PRTSTRI $$PUSH CastPrintStrI $$CAST %1 @POPNULL
# Print immediate value (usefull to print value of pointer)
M PRTREF $$PUSH CastPrintInt $$CAST %1 @POPNULL
# Print top value in stack but leave it there.
M PRTTOP @JMP J%0J1 :%0M1 0 :J%0J1 @POPI %0M1 @PUSHI %0M1 @PRTI %0M1
# Read an Integer from keyboard
M READI $$PUSH PollReadIntI $$POLL %1 @POPNULL
# Print Prompt string, then read integer.
M PROMPT @PRT %1 @READI %2
# End Program
M END $$PUSH 99 $$CAST 0
# Like POPI but leaves copy of value on stack
M TOP @DUP @POPI %1
# Print a debug dump of the stack
M StackDump @JMP %0J :%0J @PUSH 102 @CAST 0 @POPNULL
# Adds one to variable
M INCI @PUSHI %1 @ADD 1 @POPI %1
# Subtracts one from variable
M DECI @PUSHI %1 @SUB 1 @POPI %1

# The Following are some convient macros to simplify some of the most common logic and jump functions
# Math Group,   3 params A, B and C all are simple memeory addresses or lables.
M ADDAB2C @PUSHI %1 @ADDI %2 @POPI %3
M SUBAB2C @PUSHI %1 @SUBI %2 @POPI %3
# Logical IF's results compair A and B and save T(1)/F(0) to C
# This is for simplicity and cases where the result matters mutlitple times or later then when the CMP was done.
M ifAneB2C @PUSH 0 @POPI %3 @PUSHI %1 @CMPI %2 @POPNULL @JMPZ %0Skip @PUSH 1 @POPI %3 :%0Skip
M ifAeqB2C @PUSH 0 @POPI %3 @PUSHI %1 @CMPI %2 @POPNULL @JNZ %0Skip @PUSH 1 @POPI %3 :%0Skip
M ifAltB2C @PUSH 0 @POPI %3 @PUSHI %1 @CMPI %2 @POPNULL @JGE %0Skip @PUSH 1  @POPI %3 :%0Skip
M ifAgtB2C @PUSH 0 @POPI %3 @PUSHI %1 @CMPI %2 @POPNULL @JLE %0Skip @PUSH 1  @POPI %3 :%0Skip
M ifAleB2C @PUSH 0 @POPI %3 @PUSHI %1 @CMPI %2 @POPNULL @JGT %0Skip @PUSH 1  @POPI %3 :%0Skip
M ifAgeB2C @PUSH 0 @POPI %3 @PUSHI %1 @CMPI %2 @POPNULL @JLT %0Skip @PUSH 1  @POPI %3 :%0Skip
# Jumps based not on current flags but T or F values in location.	
M JifT @PUSH 0 @CMPI %1 @POPNULL @JMPZ %0Skip @JMP %2 :%0Skip
M JifF @PUSH 0 @CMPI %1 @POPNULL @JNZ %0Skip @JMP %2 :%0Skip
# The following provides an MACRO verison of 'for next' loops.
# For 1:IndexName 2:Start_Constant 3:Stop_Constant 4:Named_Next
# The first variation is sort of like "for i from 1 to 10" or similure logic with fixed numbers
M ForIfA2B \
   @PUSH %2 @POPI %1 \
   @MC2M %3 %4_stop \
   @PUSHI %1 \
   @CMPI %4_stop \
   @POPNULL \
   @JMPZ %4_exit \
   :%4Loop1
# For 1:IndexName 2:Start_variable 3:Stop_Variable 4:Named_next (vars are only evaluated on first entry to loop)
# This variation is when the range is not fixed and is stored in variables.
M ForIfV2V \
  @PUSHI %2 @POPI %1 \
  @MM2M %3 %4_stop \
  @PUSHI %1 \
  @CMPI %4_stop \
  @POPNULL \
  @JMPZ %4_exit \
  :%4Loop1
# Matching Next command for pass same values as above for 1:IndexName and 2:Named_next
M NextNamed \
   @INCI %1 \
   @PUSHI %1 \
   @CMPI %2_stop \
   @POPNULL \
   @JMPZ %2_exit \
   @JMP %2Loop1 \
   :%2_test 0 \
   :%2_stop 0 \
   :%2_exit 
# A way to enable/disable debugging in running code without requireing the -g option.
M DEBUGTOGGLE @PUSH 100 @CAST 0 @POPNULL


ENDBLOCK
@JMP CODE__BEGIN__
:Buffer
0 0 0
# Put here some libraries
:CODE__BEGIN__
#
# Cast Codes: 1=String b0, 2=Integer imediate Unsigned. 3=Integer mem[address]. 4=Signed Int mem[address] 5=Binary mem[address]
#

