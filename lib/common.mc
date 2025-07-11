! COMMON_SEEN
MF COMMON_SEEN 1
# Setup Library
# Values which make up opcodes
#
# The '!' code marks a block to skip if already defined.
:Var01 0
:Var02 0
:Var03 0
:Var04 0
:Var05 0
:Var06 0
:Var07 0
:Var08 0
:Var09 0
:Var10 0
:Var11 0
:Var12 0
:Var13 0
:Var14 0
:Var15 0
:Var16 0
:Var17 0
:Var18 0
:Var19 0
:Var20 0
G NOP G PUSH G PUSHB G PUSHI G PUSHII G POPI G POPII G POPB G CMPI G CMPII G JMPZ
G JMPN G JMPC G JMPO G JMP G JMPI G ADD G SUB G AND G OR G INV G ADDI G SUBI
G ANDI G ORI G ADDII G SUBII G ANDII G ORII G CAST G POLL G CPUID G SETAPP G CLEAR
G RRT G RLTC G RTR G RTL G FCLR G FSAV G FLOD
G Var01 G Var02 G Var03 G Var04 G Var05 G Var06 G Var07 G Var08 G Var09 G Var10
G Var11 G Var12 G Var13 G Var14 G Var15 G Var16 G Var17 G Var18 G Var19 G Var20


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
=XOR 31
=XORS 32
=XORI 33
=XORII 34
=JMPZ 35
=JMPN 36
=JMPC 37
=JMPO 38
=JMP 39
=JMPI 40
=JMPS 41
=CAST 42
=POLL 43
=RRTC 44
=RLTC 45
=SHR 46
=SHL 47
=INV 48
=COMP2 49
=FCLR 50
=FSAV 51
=FLOD 52
=ADM 53
=SCLR 54
=SRTP 55

# Cast and Poll Codes
=CastPrintStr 1
=CastPrintInt 2
=CastPrintIntI 3
=CastPrintSignI 4
=CastPrintBinI 5
=CastPrintChar 6
=CastPrintStrI 11
=CastPrintIntUI 12
=CastPrintCharI 16
=CastPrintHexI 17
=CastPrintHexII 18
=CastPrint32I 32
=CastPrint32II 33
=CastSelectDisk 20
=CastSelectDiskI 24
=CastSeekDisk 21
=CastSeekDiskI 25
=CastWriteSector 22
=CastWriteSectorI 26
=CastSyncDisk 23
=CastPrint32S 33
=CastTapeWriteI 34
=PollReadIntI 1
=PollReadStrI 2
=PollReadCharI 3
=PollSetNoEcho 4
=PollSetEcho 5
=PollReadCINoWait 6
=PollReadSector 22
=PollReadSectorI 26
=PollReadTapeI 23
=PollRewindTape 24
=PollReadTime 25


# Warning about Macros
# When defining a macro you can refrence other  macros on the same line.
# When executing a macro, the rule is one macro per line.
# If you need a Macro to Define another 'macro' for the purpose of flags
# You can use the MF or MacroFlag command which takes only one argument
# and unlike 'M' macros can be enbeded inside other macros.
M NOP $$NOP
M PUSH $$PUSH %1
M DUP $$DUP
M PUSHI $$PUSHI %1
M PUSHII $$PUSHII %1
M PUSHS $$PUSHS
M POPNULL $$POPNULL
M SWP $$SWP
M POPI $$POPI %1
M POPII $$POPII %1
M POPS $$POPS
M CMP $$CMP %1
M CMPS $$CMPS
M CMPI $$CMPI %1
M CMPII $$CMPII %1
M ADD $$ADD %1
M ADDS $$ADDS
M ADDI $$ADDI %1
M ADDII $$ADDII %1
M SUB $$SUB %1          # (updated SUB ~ TOS=(TOS-P1))
M SUBS $$SUBS
M SUBI $$SUBI %1
M SUBII $$SUBII %1
M OR $$OR %1
M ORS $$ORS
M ORI $$ORI %1
M ORII $$ORII %1
M AND $$AND %1
M ANDS $$ANDS
M ANDI $$ANDI %1
M ANDII $$ANDII %1
M XOR $$XOR %1
M XORS $$XORS
M XORI $$XORI %1
M XORII $$XORII %1
M JMPZ $$JMPZ %1
M JMPN $$JMPN %1
M JMPC $$JMPC %1
M JMPO $$JMPO %1
M JMP $$JMP %1
M JMPI $$JMPI %1
M JMPS $$JMPS
M CAST $$CAST %1
M POLL $$POLL %1
M RRTC $$RRTC
M RLTC $$RLTC
M SHR $$SHR
M SHL $$SHL
M INV $$INV
M COMP2 $$COMP2
M FCLR $$FCLR                  # the F group is for clearing, saving, and loading Flag states. Usefill in Interupts
M FSAV $$FSAV
M FLOD $$FLOD
M ADM $$ADM
M SCLR $$SCLR
M SRTP $$SRTP


# For compleatness we can proview VV VA AV versions of major math functions.

M CMPVV @PUSHI %1 @PUSHI %2 @CMPS
M CMPVA @PUSHI %1 @PUSH %2 @CMPS
M CMPAV @PUSH %1 @PUSHI %2 @CMPS
M ADDVV @PUSHI %1 @PUSHI %2 @ADDS
M ADDVA @PUSHI %1 @PUSH %2 @ADDS
M ADDAV @PUSH %1 @PUSHI %2 @XORS
M SUBVV @PUSHI %1 @PUSHI %2 @SUBS
M SUBVA @PUSHI %1 @PUSH %2 @SUBS
M SUBAV @PUSH %1 @PUSHI %2 @SUBS
M ORVV @PUSHI %1 @PUSHI %2 @ORS
M ORVA @PUSHI %1 @PUSH %2 @ORS
M ORAV @PUSH %1 @PUSHI %2 @XORS
M ANDVV @PUSHI %1 @PUSHI %2 @ANDS
M ANDVA @PUSHI %1 @PUSH %2 @ANDS
M ANDAV @PUSH %1 @PUSHI %2 @ANDS
M XORVV @PUSHI %1 @PUSHI %2 @XORS
M XORVA @PUSHI %1 @PUSH %2 @XORS
M XORAV @PUSH %1 @PUSHI %2 @XORS


M MA2V @PUSH %1 @POPI %2   # Move Constant to Memory
M MC2M @PUSH %1 @POPI %2   # Another way to say it, move Constant A to Variable
M MV2V @PUSHI %1 @POPI %2  # Move Memory to Memory
M MM2M @PUSHI %1 @POPI %2  # Another way to say it, Move Variable to Variable
M MMI2M @PUSHII %1 @POPI %2
M MM2IM @PUSHI %1 @POPII %2
M JMPNZ @JMPZ $_%01 @JMP %1 :_%01        # A != B
M JMPNZI @JMPZ $_%01 @JMPI %1 :_%0
M JMPZI @JMPNZ $_%01 @JMPI %1 :_%0
M JMPNC @JMPC $_%0SKIP @JMP %1 :_%0SKIP  # No Carry
M JMPNO @JMPO $_%01 @JMP %1 :_%01        # No Overflow
#  For this group, remeber the flags are based on the B-A
#  Example PUSH A20 PUSH B30 CMPS, flag would  be N as 20 < 30 
#          PUSH A40 PUSH B20 CMPS, FLAG would be !N as 40 > 20
M JGT @JMPZ _%0_Skip \
      @JMPN _%0_Skip \
      @JMP %1 \
      :_%0_Skip                          # GT true if Both Z and N are false
M JGE @JMPN %1 @JMPZ %1                  # A=A-B, if B>=A or A<B JMP %1
M JLT @JMPZ _%0Skp @JMPN _%0Skp @JMP %1 :_%0Skp   #  if B<A or A>=B JMP %1
M JLE @JMPN _%0Skp @JMP %1 :_%0Skp         # A=A-B, if B<=A or A>B JMP %1
M CALL @PUSH $_%01 @JMP %1 :_%01
M CALLZ @PUSH $_%0_Loc @JMPZ _%0_Do @JMP _%0_After :_%0_Do @JMP %1 :_%0_Loc :_%0_After
M CALLNZ @PUSH $_%0_Loc @JMPZ _%0_After @JMP %1 :_%0_Loc :_%0_After
#M RET @POPI $com%0D @JMPI $_%0D :_%0D 0
M RET @JMPS
M JNZ @JMPZ _%0J @JMP %1 :_%0J
M JZ @JMPZ %1                           # Just an abbriviation as its really commonly used.
# Simple Text output for headers or labels, LN includes linefeed.
# Print simple test message with no variables and LineFeed
M PRTLN @JMP _J%0J1 :_%0M1 %1 "\n\0" :_J%0J1 @PUSH CastPrintStr @CAST $_%0M1 @POPNULL
# Print simple test message with no variables no linefeed
M PRT @JMP _J%0J1 :_%0M1 %1 0 :_J%0J1 @PUSH CastPrintStr @CAST $_%0M1 @POPNULL
# Print value of variable
M PRTI @PUSH CastPrintIntI @CAST %1 @POPNULL
# Print Value of unsigned variable
M PRTUI @PUSH CastPrintIntUI @CAST %1 @POPNULL
# Print value of variable in Hex
M PRTHEXI @PUSH CastPrintHexI @CAST %1 @POPNULL
# Print value Pointer is pointing at in Hex
M PRTHEXII @PUSH CastPrintHexII @CAST %1 @POPNULL
# Print value of variable but surrounded with spaces for readability
M PRTIC @PRT " " @PUSH CastPrintIntI @CAST %1 @POPNULL @PRT " "
# Print string starting at address
M PRTSTR @PUSH CastPrintStr @CAST %1 @POPNULL
# Print string start at variable
M PRTSTRI @PUSH CastPrintStrI @CAST %1 @POPNULL
# Alternative name for PRTSTR
M PRTS @PUSH CastPrintStr @CAST %1 @POPNULL
# Alternative name for PRTSTRI
M PRTSI @PUSH CastPrintStrI @CAST %1 @POPNULL
# Print given Character
M PRTCH @PUSH CastPrintChar @CAST %1 @POPNULL
# Print Character at Variable
M PRTCHI @PUSH CastPrintCharI @CAST %1 @POPNULL
# Print Character on Stack
M PRTCHS @JMP _%0SkipF \
     :_%0Data 0 \
     :_%0SkipF @DUP @AND 0xff @POPI _%0Data @PUSH CastPrintChar @CAST _%0Data @POPNULL 
# Print string whos address is on the stack
M PRTSS @JMP _%0Skip :_%0ptr 0 :_%0Skip @POPI _%0Ptr @PUSH CastPrintCharI @CAST _%0ptr 0
# Print value Pointer is pointing at.
M PRTII @PUSHII %1 @POPI _%0Store \
        @PUSH CastPrintInt @CAST :_%0Store 0 @POPNULL
# Print value with sign '-' if negative
M PRTSGNI @PUSH CastPrintSignI @CAST %1 @POPNULL
# Print value in binary
M PRTBINI @PUSH CastPrintBinI @CAST %1 @POPNULL
# Print Line feed
M PRTNL @JMP _%01 :_%0NL 10 $$0 :_%01 @PUSH CastPrintStr @CAST _%0NL @POPNULL
# Print a space by itself
M PRTSP @JMP _%01J :_%0M " \0" :_%01J @PUSH CastPrintStr @CAST _%0M @POPNULL
# Print immediate value (usefull to print value of pointer)
M PRTREF @PUSH CastPrintInt @CAST %1 @POPNULL
# Print top value in stack but leave it there.
M PRTTOP @DUP @JMP _J%0J1 :_%0M1 0 :_J%0J1 @POPI _%0M1 @PRTI _%0M1
# Print Top valine in Hex
M PRTHEXTOP @DUP @JMP _J%0J1 :_%0M1 0 :_J%0J1 @POPI _%0M1 @PRTHEXI _%0M1
# Print Top with Sign
M PRTSGNTOP @DUP @POPI _%0Store @PRTSGNI _%0Store @JMP _%0Skip :_%0Store 0 :_%0Skip
# Print 32bit number starting at address
M PRT32 @PUSH CastPrint32I @CAST %1 @POPNULL
M PRT32I @PUSH CastPrint32II @CAST %1 @POPNULL
#M PRT32I @JMP _%0Jmp :_%0store1 0 :_%0store2 0 \
#   :_%0Jmp @PUSHII %1 @POPI _%0store1 \
#   @PUSHI %1 @ADD 2 @PUSHS @POPI _%0store2 \
#   @PUSH CastPrint32I @CAST _%0store1 @POPNULL
# Print 32bit number that tos is pointing to.
M PRT32S @PUSH CastPrint32S @CAST 0 @POPNULL
#
# Read an Integer from keyboard
M READI @PUSH PollReadIntI @POLL %1 @POPNULL
# Print Prompt string, then read integer.
M PROMPT @PRT %1 @READI %2
# Read a String from Keyboard
# Param of READS is lable of the buffer
M READS @PUSH PollReadStrI @POLL %1 @POPNULL
# Param of READSI is lable that contains pointer to buffer
M READSI @PUSHI %1 @POPI _%0ADDR @PUSH PollReadStrI @POLL :_%0ADDR 0xffff @POPNULL
# Read a unechoed character from keyboard
M READC @PUSH PollReadCharI @POLL %1 @POPNULL
# Read character from keyboard with no wait if none ready.
M READCNW @PUSH PollReadCINoWait @POLL %1 @POPNULL
# Turn Keyboard echo off
M TTYNOECHO @PUSH PollSetNoEcho @POLL %1 @POPNULL
# Turn KeyBoard echo on
M TTYECHO @PUSH PollSetEcho @POLL %1 @POPNULL
# End Program
M END @PUSH 99 @CAST 0
# Like POPI but leaves copy of value on stack
M TOP @DUP @POPI %1
# Print a debug dump of the stack
M StackDump @JMP _%0J :_%0J @PUSH 102 @CAST 0 @POPNULL
# Adds one to variable
M INCI @PUSHI %1 @ADD 1 @POPI %1
# Subtracts one from variable
M DECI @PUSHI %1 @SUB 1 @POPI %1
# Adds two to variable
M INC2I @PUSHI %1 @ADD 2 @POPI %1
# Subtracts one from variable
M DEC2I @PUSHI %1 @SUB 2 @POPI %1

# A way to impliment a 16 bit 2 comp ABS function
M ABSI @PUSH 0x8000 @ANDI %1 @CMP 0 @POPNULL @PUSHI %1 @JMPZ _%0IsPos @COMP2 :_%0IsPos
# Time Fetch, puts on stack 32 bit time as two 16 bit PUSHes
M GETTIME @PUSH PollReadTime @POLL 0

# Disk IO Group
M DISKSEL @PUSH CastSelectDisk @CAST %1 @POPNULL
M DISKSELI @PUSH CastSelectDiskI @CAST %1 @POPNULL
M DISKSEEK @PUSH CastSeekDisk @CAST %1 @POPNULL
M DISKSEEKI @PUSH CastSeekDiskI @CAST %1 @POPNULL
M DISKWRITE @PUSH CastWriteSector @CAST %1 @POPNULL
M DISKWRITEI @PUSH CastWriteSectorI @CAST %1 @POPNULL
M DISKSYNC @PUSH CastSyncDisk @CAST 0 @POPNULL
M DISKREAD @PUSH PollReadSector @POLL %1 @POPNULL
M DISKREADI @PUSH PollReadSectorI @POLL %1 @POPNULL
# We use the same logic for both Tape and Disk Select.
M TAPESEL @PUSH CastSelectDisk @CAST %1 @POPNULL
M TAPESELI @PUSHI %1 @POPI _%0_LOC @PUSH CastSelectDisk @CAST :_%0_LOC 0 @POPNULL
M TAPEWRITE @PUSH CastTapeWriteI @PUSHI %1 @POPI _%0_LOC @CAST :_%0_LOC 0 @POPNULL
M TAPEREADI @PUSH PollReadTapeI @PUSHI %1 @POPI _%0_LOC @POLL :_%0_LOC 0 @POPNULL
M TAPEREAD @PUSH PollReadTapeI @POLL %1 0 @POPNULL
M TAPEREWIND @PUSH PollRewindTape @POLL 0 @POPNULL


# A way to enable/disable debugging in running code without requireing the -g option.
M DEBUGTOGGLE @PUSH 100 @CAST 0 @POPNULL
#
# FOR NEXT WHILE and CASE logic structures can be found in this related file.
I structure.asm
ENDBLOCK
