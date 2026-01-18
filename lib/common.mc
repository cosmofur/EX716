! COMMON_SEEN
MF COMMON_SEEN 1
# Setup Library
# Values which make up opcodes
#
# The '!' code marks a block to skip if already defined.
:NewHereMem
G SizeHereVar
G NewHereMem
G OldHereVar
=OldHereVar NewHereMem
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
=CastPrintErrMsg 36
=CastSelectDisk 20
=CastSelectDiskI 24
=CastSeekDisk 21
=CastSeekDiskI 25
=CastWriteSector 22
=CastWriteSectorI 26
=CastSyncDisk 23
=CastPrint32S 33
=CastTapeWrite 34
=CastTapeWriteI 35
=PollReadIntI 1
=PollReadStrI 2
=PollReadCharI 3
=PollSetNoEcho 4
=PollSetEcho 5
=PollReadCINoWait 6
=PollSetRaw 7
=PollReSetRaw 8
=PollTTYState 9
=PollReadSector 22
=PollReadTapeI 23
=PollRewindTape 24
=PollReadTime 25
=PollReadSectorI 26
=PollReadTape 27

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

#     Our rotate and shift functions are someone limited, here some macros to imprve them
#

# ============================================================
# Flag control macros
# ============================================================

# Clear Carry (CC)
M CLC   @PUSH 1 @XOR 1 @XOR 1 @POPNULL
# Set Carry (SC) - force a carry by adding max value + 1
M SETC   @PUSH 0xFFFF @ADD 1 @POPNULL
# Clear Overflow (CLO) - safe add with no overflow
M CLO   @PUSH 0 @ADD 0 @POPNULL
# Set Overflow (SETO) - force signed overflow
M SETO  @PUSH 40000 @ADD 40000 @POPNULL
# Clear Zero (CLZ) - push nonzero and compare
M CLZ   @PUSH 1 @SUB 2 @POPNULL  # result = -1, not zero
# Set Zero (SETZ) - subtract equal values
M SETZ  @PUSH 1 @SUB 1 @POPNULL
# Set Neg (SETN) - Negative Value
M SETN @PUSH 0 @SUB 1 @POPNULL
#
# Rotate Left n bits (pure, deterministic)
M ROL1 @CLC @RLTC
M ROL2 @CLC @RLTC @RLTC
M ROL3 @CLC @RLTC @RLTC @RLTC
M ROL4 @CLC @RLTC @RLTC @RLTC @RLTC
M ROL5 @CLC @RLTC @RLTC @RLTC @RLTC @RLTC
M ROLN @CLC \
     %REPEAT %1 @RLTC %ENDR
# Rotate Right n bits (pure, deterministic)
M ROR1 @CLC @RRTC
M ROR2 @CLC @RRTC @RRTC
M ROR3 @CLC @RRTC @RRTC @RRTC
M ROR4 @CLC @RRTC @RRTC @RRTC @RRTC
M ROR5 @CLC @RRTC @RRTC @RRTC @RRTC @RRTC
M ROLN @CLC \
     %REPEAT %1 @RRTC %ENDR
# Logical Shifts (no carry involvement)
M SHL2 @SHL @SHL
M SHL4 @SHL @SHL @SHL @SHL
M SHLN %REPEAT %1 @SHL %ENDR
M SHR2 @SHR @SHR
M SHR4 @SHR @SHR @SHR @SHR
M SHR7 @SHR @SHR @SHR @SHR @SHR @SHR @SHR
M SHR8 @SHR @SHR @SHR @SHR @SHR @SHR @SHR @SHR
M SHRN %REPEAT %1 @SHR %ENDR




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
M MV2V @PUSHI %1 @POPI %2  # Move Memory to Memory
#
# Some people prefer the terms LOAD and STORE for memory
# moves, so for convience here are some macros that mimic that.
#
# Word Versions are alias of PUSH and POP
M STOREI @POPI
M STOREII @POPII
M LOADI @PUSHI
M LOADII @PUSHII
M LOAD @PUSHS
#
# Byte version of Store stack to Pointer
M STOREBII \        
     @AND 0xff @PUSHII %1 \
     @AND 0xff00 @ORS \
     @POPII %1
# Byte version of Store stack to memory at address %1
M STOREBI @AND 0xff @PUSHI %1 @AND 0xff00 @ORS @POPII %1
#
# LOADB moves BYTE value from memory to stack.
#
# Load Byte value from Pointer to stack
M LOADBII \
      @PUSHII %1 @AND 0xff
# Load Byte value from memory at address %1 to stack.
M LOADBI \
      @PUSHI %1 @AND 0xff
#

M JMPNZ @JMPZ %01_SKIP @JMP %1 :%01_SKIP        # A != B
M JMPNZI @JMPZ %01 @JMPI %1 :%01_SKIP
M JMPZI @JMPNZ %01_SKIP @JMPI %1 :%01_SKIP
M JMPNC @JMPC %01_SKIP @JMP %1 :%01_SKIP   # No Carry
M JMPNO @JMPO %01_SKIP @JMP %1 :%01_SKIP        # No Overflow
M JMPNN @JMPO %01_SKIP @JMP %1 :%01_SKIP   # Not Negative
#  For this group, remeber the flags are based on the B-A
#  Example PUSH A20 PUSH B30 CMPS, flag would  be N as 20 < 30 
#          PUSH A40 PUSH B20 CMPS, FLAG would be !N as 40 > 20
# ---------------------------------------------------------------
# Signed Jump Helpers (for use after CMP/CMPI)
# ---------------------------------------------------------------
# Signed Logic Tables
#    NF          OF       ZF           Means
#    0           0        0             >
#    0           0        1            ==
#    0           1        0             <
#    1           0        0             <
#    1           1        0             >
#    -           -        1            ==
#
# LT = (NF=1, OF=0) OR (NF=0, OF=1)   (Xor NF and OF)
M CheckSignedLess \
  @JMPN %0_Test1 \ # If NF=1 -> Check OF next
  @JMPO %1        \ # NF=0,O=0 -> Skip else fall though
  @JMP %2 \         # NF=0, OF=1 -> Less true
  :%0_Test1 \
  @JMPO %2 \        # NF=1 OF=1 -> Not Less, False
  @JMP %1         # NF=1, OF=0 -> is Less, True


M JLT \
  @JMPZ _%0_Skip \  # Equal -> Not Less, False
  @CheckSignedLess %1 _%0_Skip \
  :_%0_Skip 
M JLE \
  @JMPZ %1 \        # Equal -> Always true.
  @CheckSignedLess %1 _%0_Skip \
  :_%0_Skip         # Not true, continue next.
# GT = (NF=1, OF=1, ZF=0) or ( NF=0, OF=0, ZF=0)
# GT = same as NF=OF and ZF=0
M CheckSignedGreater \
  @JMPN %0_Test1 \   # If NF=1 -> Check OF
  @JMPO %2 \          # NF=0, OF=1  So not GT
  @JMP %1 \           # NF=OF==0, So GT True
  :%0_Test1 \
  @JMPO %1 \          # NF=1 OF=1 so both are equal
  @JMP %2             # NF!=OF so Not Greater than

M JGT \
  @JMPZ _%0_Skip \    # Equal -> Not Greater Than, False
  @JMPN %0_Test1 \    # If NF=1 -> Check OF
  @JMPO _%0_Skip \    # NF=0, OF=1  So not GT
  @JMP %1 \           # NF=OF==0, So GT True
  :%0_Test1 \
  @JMPO %1 \          # NF=1 OF=1 so both are equal
  @JMP _%0_Skip \     # NF!=OF so Not Greater than  
  :_%0_Skip
  
M JGE \
  @JMPZ %1      \    # Equal ->  Then Always true
  @JMPN %0_Test1 \    # If NF=1 -> Check OF
  @JMPO _%0_Skip \    # NF=0, OF=1  So not GT
  @JMP %1 \           # NF=OF==0, So GT True
  :%0_Test1 \
  @JMPO %1 \          # NF=1 OF=1 so both are equal
  @JMP _%0_Skip \     # NF!=OF so Not Greater than  
  :_%0_Skip

# ---------------------------------------------------------------
# Unsigned Jump Helpers (for use after CMP/CMPI)
# ---------------------------------------------------------------
# ============================================================
# Jump if A < B (unsigned)
# CF=1 (borrow)
# ============================================================
M JULT \
  @JMPNC _%0_skip \        # Skip if CF=0 (A ≥ B)
  @JMP %1          \       # Jump if CF=1 (A < B)
  :_%0_skip

# ============================================================
# Jump if A <= B (unsigned)
# CF=1 (borrow) OR Z=1 (equal)
# ============================================================
M JULE \
  @JMPZ %1          \       # Equal → jump
  @JMPNC _%0_skip   \       # Skip if CF=0 (A ≥ B)
  @JMP %1           \       # CF=1 (A < B) → jump
  :_%0_skip

# ============================================================
# Jump if A >= B (unsigned)
# CF=0 (no borrow)
# ============================================================
M JUGE \
  @JMPNC %1          \      # Jump if CF=0 (A ≥ B)

# ============================================================
# Jump if A > B (unsigned)
# CF=0 (no borrow) AND Z=0 (not equal)
# ============================================================
M JUGT \
  @JMPZ _%0_skip     \      # Equal → skip
  @JMPC _%0_skip     \      # Borrow (A < B) → skip
  @JMP %1            \      # Jump if CF=0 and Z=0 → A > B
  :_%0_skip
# --------------------------------------------------------------
# CALL and Return Functions
# --------------------------------------------------------------
M CALL @PUSH $_%01 @JMP %1 :_%01
M CALLZ @PUSH $_%0_Loc @JMPZ _%0_Do @JMP _%0_After :_%0_Do @JMP %1 :_%0_Loc :_%0_After
M CALLNZ @PUSH $_%0_Loc @JMPZ _%0_After @JMP %1 :_%0_Loc :_%0_After
M CALLI @PUSH $_%01 @PUSHI %1 @JMPS :_%01

M RET @JMPS
M JNZ @JMPZ _%0J @JMP %1 :_%0J
M JZ @JMPZ %1                           # Just an abbriviation as its really commonly used.

# Simple Text output for headers or labels, LN includes linefeed.
# Print simple test message with no variables and LineFeed
M PRTLN @JMP _J%0J1 :_%0M1 %1 "\n\0" :_J%0J1 @PUSH CastPrintStr @CAST $_%0M1
# Print simple test message with no variables no linefeed
M PRT @JMP _J%0J1 :_%0M1 %1 0 :_J%0J1 @PUSH CastPrintStr @CAST $_%0M1
# Print Fixed Message to stderr
M PRTERR @JMP _J%0J1 :_%0M1 %1 0 :_J%0J1 @PUSH CastPrintErrMsg @CAST $_%0M1
# Print value of variable
M PRTI @PUSH CastPrintIntI @CAST %1
# Print Value of unsigned variable
M PRTUI @PUSH CastPrintIntUI @CAST %1
# Print value of variable in Hex
M PRTHEXI @PUSH CastPrintHexI @CAST %1
# Print value Pointer is pointing at in Hex
M PRTHEXII @PUSH CastPrintHexII @CAST %1
# Print string starting at address
M PRTSTR @PUSH CastPrintStr @CAST %1
# Print string start at variable
M PRTSTRI @PUSH CastPrintStrI @CAST %1
# Alternative name for PRTSTR
M PRTS @PUSH CastPrintStr @CAST %1
# Alternative name for PRTSTRI
M PRTSI @PUSH CastPrintStrI @CAST %1
# Print given Character
M PRTCH @PUSH CastPrintChar @CAST %1
# Print Character at Variable
M PRTCHI @PUSH CastPrintCharI @CAST %1
# Print Character on Stack
M PRTCHS @JMP _%0SkipF \
     :_%0Data 0 \
     :_%0SkipF @DUP @AND 0xff @POPI _%0Data @PUSH CastPrintChar @CAST _%0Data
# Print string whos address is on the stack
M PRTSS @JMP _%0Skip :_%0ptr 0 :_%0Skip @POPI _%0Ptr @PUSH CastPrintCharI @CAST _%0ptr 0
# Print value Pointer is pointing at.
M PRTII @PUSHII %1 @POPI _%0Store \
        @PUSH CastPrintInt @CAST :_%0Store 0
# Print value with sign '-' if negative
M PRTSGNI @PUSH CastPrintSignI @CAST %1
# Print value in binary
M PRTBINI @PUSH CastPrintBinI @CAST %1
# Print Line feed
M PRTNL @JMP _%01 :_%0NL 10 $$0 :_%01 @PUSH CastPrintStr @CAST _%0NL
# Print a space by itself
M PRTSP @JMP _%01J :_%0M " \0" :_%01J @PUSH CastPrintStr @CAST _%0M
# Print immediate value (usefull to print value of pointer)
# Print N number of spaces
M PRTSPN  @JMP _%01  :_%0M  %REPEAT %1  " "  %ENDR $$0  :_%01 @PUSH CastPrintStr @CAST _%0M
M PRTREF @PUSH CastPrintInt @CAST %1
# Print top value in stack but leave it there.
M PRTTOP @DUP @JMP _J%0J1 :_%0M1 0 :_J%0J1 @POPI _%0M1 @PRTI _%0M1
# Print Top valine in Hex
M PRTHEXTOP @DUP @JMP _J%0J1 :_%0M1 0 :_J%0J1 @POPI _%0M1 @PRTHEXI _%0M1
# Print Direct value as Hex
M PRTHEXREF @PUSH %1 @PRTHEXTOP @POPNULL
# Print Top with Sign
M PRTSGNTOP @DUP @POPI _%0Store @PRTSGNI _%0Store @JMP _%0Skip :_%0Store 0 :_%0Skip
# Print 32bit number starting at address
M PRT32 @PUSH CastPrint32I @CAST %1
M PRT32I @PUSH CastPrint32II @CAST %1
#M PRT32I @JMP _%0Jmp :_%0store1 0 :_%0store2 0 \
#   :_%0Jmp @PUSHII %1 @POPI _%0store1 \
#   @PUSHI %1 @ADD 2 @PUSHS @POPI _%0store2 \
#   @PUSH CastPrint32I @CAST _%0store1
# Print 32bit number that tos is pointing to.
M PRT32S @PUSH CastPrint32S @CAST 0
#
# Read an Integer from keyboard
M READI @PUSH PollReadIntI @POLL %1
# Print Prompt string, then read integer.
M PROMPT @PRT %1 @READI %2
# Read a String from Keyboard
# Param of READS is lable of the buffer
M READS @PUSH PollReadStrI @POLL %1
# Param of READSI is lable that contains pointer to buffer
M READSI @PUSHI %1 @POPI _%0ADDR @PUSH PollReadStrI @POLL :_%0ADDR 0xffff
# Read a unechoed character from keyboard
M READC @PUSH PollReadCharI @POLL %1
# Read character from keyboard with no wait if none ready.
M READCNW @PUSH PollReadCINoWait @POLL %1
# Turn Keyboard echo off
M TTYNOECHO @PUSH PollSetNoEcho @POLL 0
# Turn KeyBoard echo on
M TTYECHO @PUSH PollSetEcho @POLL 0
# Turn on Raw Mode
M TTYRAW @PUSH PollSetRaw @POLL 0
# Turn off Raw Mode
M TTYRAWOFF @PUSH PollReSetRaw @POLL 0
# Report current TTY State
M TTYSTATE  @PUSH PollTTYState @POLL 0
# End Program
M END @PUSH 99 @CAST 0
# Like POPI but leaves copy of value on stack
M TOP @DUP @POPI %1
# Print a debug dump of the stack
M StackDump @JMP _%0J :_%0J @PUSH 102 @CAST 0
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
M DISKSEL @PUSH CastSelectDisk @CAST %1
M DISKSELI @PUSH CastSelectDiskI @CAST %1
M DISKSEEK @PUSH CastSeekDisk @CAST %1
M DISKSEEKI @PUSH CastSeekDiskI @CAST %1
M DISKWRITE @PUSH CastWriteSector @CAST %1
M DISKWRITEI @PUSH CastWriteSectorI @CAST %1
M DISKSYNC @PUSH CastSyncDisk @CAST 0
M DISKREAD @PUSH PollReadSector @POLL %1
M DISKREADI @PUSH PollReadSectorI @POLL %1
# We use the same logic for both Tape and Disk Select.
M TAPESEL @PUSH CastSelectDisk @CAST %1
M TAPESELI @PUSH CastSelectDiskI @CAST %1
M TAPEWRITE @PUSH CastTapeWrite @CAST %1
M TAPEWRITEI @PUSH CastTapeWriteI @CAST %1
M TAPEREADI @PUSH PollReadTapeI @PUSHI %1 @POPI _%0_LOC @POLL :_%0_LOC 0
M TAPEREAD @PUSH PollReadTape @POLL %1 0
M TAPEREWIND @PUSH PollRewindTape @POLL 0


# A way to enable/disable debugging in running code without requireing the -g option.
M DEBUGTOGGLE @PUSH 100 @CAST 0

# For readablity it is frquently usefull to combine with a macro CALL functions with their paramaters in
# order of their pushes without haveing to do it line by line. Here some macros that help with funcitons
# that are between 1 and 4 parameters

#   # PUSH semantics:
#   #   @PUSH   — immediate constant or label
#   #   @PUSHI  — variable (loads contents)
#   #   @PUSHII — pointer to variable (loads through pointer)

# Use Uppercase 'A' to show where constants are, and lowercase 'v' for variables. and 'P' for Pointer

# This section was auto generated with the following python script, use script to regnerate if needed.
#   import itertools
#   
#   # Operand type → assembler instruction
#   push_map = {
#       "A": "@PUSH",
#       "v": "@PUSHI",
#       "P": "@PUSHII",
#   }
#
#   for n in [4,3,2,1]:
#       for combo in itertools.product(["A","v","P"], repeat=n):
#           sig = "".join(combo)
#           pushes = [f"    {push_map[c]} %{i+2}" for i,c in enumerate(combo)]
#           body = " ".join(pushes + ["    @CALL %1"])
#           print(f"M Call({sig}) {body}")
#        


#     4 Paramater family
M Call(AAAA)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(AAAv)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(AAAP)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(AAvA)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(AAvv)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(AAvP)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(AAPA)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(AAPv)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(AAPP)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(AvAA)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(AvAv)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(AvAP)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(AvvA)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(Avvv)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(AvvP)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(AvPA)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(AvPv)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(AvPP)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(APAA)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(APAv)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(APAP)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(APvA)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(APvv)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(APvP)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(APPA)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(APPv)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(APPP)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(vAAA)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(vAAv)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(vAAP)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(vAvA)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(vAvv)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(vAvP)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(vAPA)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(vAPv)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(vAPP)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(vvAA)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(vvAv)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(vvAP)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(vvvA)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(vvvv)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(vvvP)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(vvPA)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(vvPv)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(vvPP)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(vPAA)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(vPAv)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(vPAP)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(vPvA)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(vPvv)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(vPvP)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(vPPA)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(vPPv)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(vPPP)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(PAAA)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(PAAv)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(PAAP)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(PAvA)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(PAvv)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(PAvP)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(PAPA)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(PAPv)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(PAPP)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(PvAA)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(PvAv)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(PvAP)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(PvvA)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(Pvvv)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(PvvP)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(PvPA)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(PvPv)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(PvPP)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(PPAA)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(PPAv)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(PPAP)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(PPvA)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(PPvv)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(PPvP)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(PPPA)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(PPPv)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(PPPP)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @CALL %1
#     3 Paramater family
M Call(AAA)     @PUSH %2     @PUSH %3     @PUSH %4     @CALL %1
M Call(AAv)     @PUSH %2     @PUSH %3     @PUSHI %4     @CALL %1
M Call(AAP)     @PUSH %2     @PUSH %3     @PUSHII %4     @CALL %1
M Call(AvA)     @PUSH %2     @PUSHI %3     @PUSH %4     @CALL %1
M Call(Avv)     @PUSH %2     @PUSHI %3     @PUSHI %4     @CALL %1
M Call(AvP)     @PUSH %2     @PUSHI %3     @PUSHII %4     @CALL %1
M Call(APA)     @PUSH %2     @PUSHII %3     @PUSH %4     @CALL %1
M Call(APv)     @PUSH %2     @PUSHII %3     @PUSHI %4     @CALL %1
M Call(APP)     @PUSH %2     @PUSHII %3     @PUSHII %4     @CALL %1
M Call(vAA)     @PUSHI %2     @PUSH %3     @PUSH %4     @CALL %1
M Call(vAv)     @PUSHI %2     @PUSH %3     @PUSHI %4     @CALL %1
M Call(vAP)     @PUSHI %2     @PUSH %3     @PUSHII %4     @CALL %1
M Call(vvA)     @PUSHI %2     @PUSHI %3     @PUSH %4     @CALL %1
M Call(vvv)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @CALL %1
M Call(vvP)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @CALL %1
M Call(vPA)     @PUSHI %2     @PUSHII %3     @PUSH %4     @CALL %1
M Call(vPv)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @CALL %1
M Call(vPP)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @CALL %1
M Call(PAA)     @PUSHII %2     @PUSH %3     @PUSH %4     @CALL %1
M Call(PAv)     @PUSHII %2     @PUSH %3     @PUSHI %4     @CALL %1
M Call(PAP)     @PUSHII %2     @PUSH %3     @PUSHII %4     @CALL %1
M Call(PvA)     @PUSHII %2     @PUSHI %3     @PUSH %4     @CALL %1
M Call(Pvv)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @CALL %1
M Call(PvP)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @CALL %1
M Call(PPA)     @PUSHII %2     @PUSHII %3     @PUSH %4     @CALL %1
M Call(PPv)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @CALL %1
M Call(PPP)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @CALL %1
#     2 Paramater family
M Call(AA)     @PUSH %2     @PUSH %3     @CALL %1
M Call(Av)     @PUSH %2     @PUSHI %3     @CALL %1
M Call(AP)     @PUSH %2     @PUSHII %3     @CALL %1
M Call(vA)     @PUSHI %2     @PUSH %3     @CALL %1
M Call(vv)     @PUSHI %2     @PUSHI %3     @CALL %1
M Call(vP)     @PUSHI %2     @PUSHII %3     @CALL %1
M Call(PA)     @PUSHII %2     @PUSH %3     @CALL %1
M Call(Pv)     @PUSHII %2     @PUSHI %3     @CALL %1
M Call(PP)     @PUSHII %2     @PUSHII %3     @CALL %1
#     1 Paramater family
M Call(A)     @PUSH %2     @CALL %1
M Call(v)     @PUSHI %2     @CALL %1
M Call(P)     @PUSHII %2     @CALL %1

#
# The recomended notatoin for Call for variable is LOWER case 'v' due to some readablity issues when
# multiple capital A's and V' are next to each other. But as lower case 'v' is a bit out of sync with
# the rest the macro standards, the following lines are to 'allow' uppercase 'V' to be used as an alternative.
# this is probably the only case where 'case sensativity' is in conflict with usage.

M Call(AAAV)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(AAVA)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(AAVV)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(AAVP)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(AAPV)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(AVAA)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(AVAV)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(AVAP)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(AVVA)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(AVVV)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(AVVP)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(AVPA)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(AVPV)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(AVPP)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(APAV)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(APVA)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(APVV)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(APVP)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(APPV)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(VAAA)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(VAAV)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(VAAP)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(VAVA)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(VAVV)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(VAVP)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(VAPA)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(VAPV)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(VAPP)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(VVAA)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(VVAV)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(VVAP)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(VVVA)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(VVVV)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(VVVP)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(VVPA)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(VVPV)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(VVPP)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(VPAA)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(VPAV)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(VPAP)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(VPVA)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(VPVV)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(VPVP)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(VPPA)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(VPPV)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(VPPP)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(PAAV)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(PAVA)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(PAVV)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(PAVP)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(PAPV)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(PVAA)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSH %5     @CALL %1
M Call(PVAV)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(PVAP)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @CALL %1
M Call(PVVA)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(PVVV)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(PVVP)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(PVPA)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @CALL %1
M Call(PVPV)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(PVPP)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @CALL %1
M Call(PPAV)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @CALL %1
M Call(PPVA)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @CALL %1
M Call(PPVV)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @CALL %1
M Call(PPVP)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @CALL %1
M Call(PPPV)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @CALL %1
M Call(AAV)     @PUSH %2     @PUSH %3     @PUSHI %4     @CALL %1
M Call(AVA)     @PUSH %2     @PUSHI %3     @PUSH %4     @CALL %1
M Call(AVV)     @PUSH %2     @PUSHI %3     @PUSHI %4     @CALL %1
M Call(AVP)     @PUSH %2     @PUSHI %3     @PUSHII %4     @CALL %1
M Call(APV)     @PUSH %2     @PUSHII %3     @PUSHI %4     @CALL %1
M Call(VAA)     @PUSHI %2     @PUSH %3     @PUSH %4     @CALL %1
M Call(VAV)     @PUSHI %2     @PUSH %3     @PUSHI %4     @CALL %1
M Call(VAP)     @PUSHI %2     @PUSH %3     @PUSHII %4     @CALL %1
M Call(VVA)     @PUSHI %2     @PUSHI %3     @PUSH %4     @CALL %1
M Call(VVV)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @CALL %1
M Call(VVP)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @CALL %1
M Call(VPA)     @PUSHI %2     @PUSHII %3     @PUSH %4     @CALL %1
M Call(VPV)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @CALL %1
M Call(VPP)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @CALL %1
M Call(PAV)     @PUSHII %2     @PUSH %3     @PUSHI %4     @CALL %1
M Call(PVA)     @PUSHII %2     @PUSHI %3     @PUSH %4     @CALL %1
M Call(PVV)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @CALL %1
M Call(PVP)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @CALL %1
M Call(PPV)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @CALL %1
M Call(AV)     @PUSH %2     @PUSHI %3     @CALL %1
M Call(VA)     @PUSHI %2     @PUSH %3     @CALL %1
M Call(VV)     @PUSHI %2     @PUSHI %3     @CALL %1
M Call(VP)     @PUSHI %2     @PUSHII %3     @CALL %1
M Call(PV)     @PUSHII %2     @PUSHI %3     @CALL %1
M Call(V)     @PUSHI %2     @CALL %1



# Size Reporting Macro - usefule durring assembling to see how much memory each library module consumes.
M SIZESINCE :NewHereMem \
             =SizeHereVar NewHereMem-OldHereVar \
             =OldHereVar NewHereMem \
             P StartAddress {SIZESINCECOMMENT} :Mem: {SizeHereVar} Bytes
M SIZESINCECOMMENT common.mc             
@SIZESINCE
#
# FOR NEXT WHILE and CASE logic structures can be found in this related file.
I structure.asm
ENDBLOCK
