! COMMON_SEEN
MF COMMON_SEEN 1
# Setup Library
# Values which make up opcodes
#
# The '!' code marks a block to skip if already defined.
# MF USE_ONLY 1
:NewHereMem
G SizeHereVar
G NewHereMem
G OldHereVar
=OldHereVar {NewHereMem}
G Var01 G Var02 G Var03 G Var04 G Var05 G Var06 G Var07 G Var08 G Var09 G Var10
G Var11 G Var12 G Var13 G Var14 G Var15 G Var16 G Var17 G Var18 G Var19 G Var20
G Var1 G Var2 G Var3 G Var4 G Var5 G Var6 G Var7 G Var8 G Var9
:Var1          # Allow both Var01 and Var1 to be same memory location.
:Var01 0
:Var2
:Var02 0
:Var3
:Var03 0
:Var4
:Var04 0
:Var5
:Var05 0
:Var6
:Var06 0
:Var7
:Var07 0
:Var8
:Var08 0
:Var9
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
G NOP G PUSH G PUSHS G PUSHI G PUSHII G POPI G POPII G POPB G CMPI G CMPII G JMPZ
G JMPN G JMPC G JMPO G JMP G JMPI G ADD G SUB G AND G OR G INV G ADDI G SUBI
G ANDI G ORI G ADDII G SUBII G ANDII G ORII G CAST G POLL G CPUID G SETAPP G CLEAR
G RRT G RLTC G RTR G RTL G FCLR G FSAV G FLOD
G Var01 G Var02 G Var03 G Var04 G Var05 G Var06 G Var07 G Var08 G Var09 G Var10
G Var11 G Var12 G Var13 G Var14 G Var15 G Var16 G Var17 G Var18 G Var19 G Var20

=True 1
=False 0

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

M TRUE 1
=TRUE 1
M FALSE 0
=FALSE 0

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
=CastPrintErrMsg 19
=CastSelectDisk 20
=CastSeekDisk 21
=CastWriteSector 22
=CastSyncDisk 23
=CastSelectDiskI 24
=CastSeekDiskI 25
=CastWriteSectorI 26
=CastPrint32I 32
=CastPrint32II 33
=CastPrint32S 34
=CastPrint32SignI 35
=CastPrint32SignS 36
=CastTapeWrite 40
=CastTapeWriteI 41
=CastEnd 99
=CastDebugToggle 100
=CastStackDump 102
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
M CLN   @PUSH 2 @SUB 1 @POPNULL
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
M RORN @CLC \
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
M STOREI @POPI %1
M STOREII @POPII %1
M LOADI @PUSHI %1
M LOADII @PUSHII %1
M LOAD @PUSHS %1
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


# CMP evaluates:
#
#        TOS - Operand
#
# For:
#
#        PUSH A
#        CMP B
#
# the flags describe A-B.
#
# ---------------------------------------------------------------
# Normal non-overflow examples
# ---------------------------------------------------------------
#
# Signed and unsigned agree when both values have the same sign
# and no signed overflow occurs.
#
#----A------B------A-B------ZF----NF----CF----OF----Signed----Unsigned
#----10-----10------0--------1-----0-----0-----0------==--------==
#----10-----11----- -1-------0-----1-----1-----0------<---------<
#----10------9------ 1-------0-----0-----0-----0------>--------->
#--- -10--- -10------0-------1-----0-----0-----0------==--------==
#--- -10--- -11------1-------0-----0-----0-----0------>--------->
#--- -10---- -9----- -1------0-----1-----1-----0------<---------<
#
# ---------------------------------------------------------------
# Signed vs unsigned disagreement examples
# ---------------------------------------------------------------
#
# These differ because the same 16-bit bit-patterns have different
# signed and unsigned interpretations.
#
#----A------B------A-B------ZF----NF----CF----OF----Signed----Unsigned
#----10---- -10-----20-------0-----0-----1-----0------>---------<
#--- -10----10----- -20------0-----1-----0-----0------<--------->
#
# ---------------------------------------------------------------
# Derived comparison logic
# ---------------------------------------------------------------
#
# Equality:
#
#        A == B       ZF == 1
#        A != B       ZF == 0
#
# Unsigned comparison:
#
#        A <  B       CF == 1
#        A >= B       CF == 0
#        A >  B       CF == 0 AND ZF == 0
#        A <= B       CF == 1 OR  ZF == 1
#
# Signed comparison:
#
#        A <  B       NF XOR OF
#        A >= B       NOT (NF XOR OF)
#        A >  B       ZF == 0 AND NOT (NF XOR OF)
#        A <= B       ZF == 1 OR  (NF XOR OF)
#
M JMPNZ @JMPZ %0_SKIP @JMP %1 :%0_SKIP        # A != B
M JMPNZI @JMPZ %0_SKIP @JMPI %1 :%0_SKIP      # Indirect Jmp When A !=B
M JMPZI @JMPNZ %0_SKIP @JMPI %1 :%0_SKIP      # Indirect Jmp when A==B
M JMPNC @JMPC %0_SKIP @JMP %1 :%0_SKIP        # No Carry
M JMPNO @JMPO %0_SKIP @JMP %1 :%0_SKIP        # No Overflow
M JMPNN @JMPN %0_SKIP @JMP %1 :%0_SKIP        # Not Negative
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
  @JMPNC %1      # Jump if CF=0 (A ≥ B)
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
M CALL @PUSH $_%0A @JMP %1 :_%0A
M CALLZ @PUSH $_%0_Loc @JMPZ _%0_Do @JMP _%0_After :_%0_Do @JMP %1 :_%0_Loc :_%0_After
M CALLNZ @PUSH $_%0_Loc @JMPZ _%0_After @JMP %1 :_%0_Loc :_%0_After
M CALLI @PUSH $_%0A @PUSHI %1 @JMPS :_%0A

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
M PRTNL @JMP _%0A :_%0NL 10 $$0 :_%0A @PUSH CastPrintStr @CAST _%0NL
# Print a space by itself
M PRTSP @JMP _%0AJ :_%0M " \0" :_%0AJ @PUSH CastPrintStr @CAST _%0M
# Print immediate value (usefull to print value of pointer)
# Print N number of spaces
M PRTSPN  @JMP _%0A  \
         :_%0M %REPEAT %1 $$0x20  %ENDR \
         $$0  :_%0A @PUSH \
         CastPrintStr @CAST _%0M
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
M PRT32I @PUSH CastPrint32I @CAST %1
M PRT32II @PUSH CastPrint32II @CAST %1
M PRT32S @PUSH CastPrint32S @CAST 0
M PRT32SignI @PUSH CastPrint32SignI @CAST %1
M PRT32SignS @PUSH CastPrint32SignS @CAST %1
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
M END @PUSH CastEnd @CAST 0
# Like POPI but leaves copy of value on stack
M TOP @DUP @POPI %1
# Print a debug dump of the stack
M StackDump @JMP _%0J :_%0J @PUSH CastStackDump @CAST 0
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
M DEBUGTOGGLE @PUSH CastDebugToggle @CAST 0

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
#     5 Paramater family

M Call(AAAAA)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(AAAAV)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(AAAAP)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(AAAVA)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(AAAVV)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(AAAVP)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(AAAPA)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(AAAPV)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(AAAPP)     @PUSH %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(AAVAA)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(AAVAV)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(AAVAP)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(AAVVA)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(AAVVV)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(AAVVP)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(AAVPA)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(AAVPV)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(AAVPP)     @PUSH %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(AAPAA)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(AAPAV)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(AAPAP)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(AAPVA)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(AAPVV)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(AAPVP)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(AAPPA)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(AAPPV)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(AAPPP)     @PUSH %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(AVAAA)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(AVAAV)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(AVAAP)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(AVAVA)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(AVAVV)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(AVAVP)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(AVAPA)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(AVAPV)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(AVAPP)     @PUSH %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(AVVAA)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(AVVAV)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(AVVAP)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(AVVVA)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(AVVVV)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(AVVVP)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(AVVPA)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(AVVPV)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(AVVPP)     @PUSH %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(AVPAA)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(AVPAV)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(AVPAP)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(AVPVA)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(AVPVV)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(AVPVP)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(AVPPA)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(AVPPV)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(AVPPP)     @PUSH %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(APAAA)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(APAAV)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(APAAP)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(APAVA)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(APAVV)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(APAVP)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(APAPA)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(APAPV)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(APAPP)     @PUSH %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(APVAA)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(APVAV)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(APVAP)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(APVVA)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(APVVV)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(APVVP)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(APVPA)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(APVPV)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(APVPP)     @PUSH %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(APPAA)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(APPAV)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(APPAP)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(APPVA)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(APPVV)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(APPVP)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(APPPA)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(APPPV)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(APPPP)     @PUSH %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VAAAA)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VAAAV)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VAAAP)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VAAVA)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VAAVV)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VAAVP)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VAAPA)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VAAPV)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VAAPP)     @PUSHI %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VAVAA)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VAVAV)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VAVAP)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VAVVA)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VAVVV)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VAVVP)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VAVPA)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VAVPV)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VAVPP)     @PUSHI %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VAPAA)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VAPAV)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VAPAP)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VAPVA)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VAPVV)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VAPVP)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VAPPA)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VAPPV)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VAPPP)     @PUSHI %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VVAAA)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VVAAV)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VVAAP)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VVAVA)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VVAVV)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VVAVP)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VVAPA)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VVAPV)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VVAPP)     @PUSHI %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VVVAA)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VVVAV)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VVVAP)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VVVVA)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VVVVV)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VVVVP)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VVVPA)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VVVPV)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VVVPP)     @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VVPAA)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VVPAV)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VVPAP)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VVPVA)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VVPVV)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VVPVP)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VVPPA)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VVPPV)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VVPPP)     @PUSHI %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VPAAA)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VPAAV)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VPAAP)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VPAVA)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VPAVV)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VPAVP)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VPAPA)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VPAPV)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VPAPP)     @PUSHI %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VPVAA)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VPVAV)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VPVAP)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VPVVA)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VPVVV)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VPVVP)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VPVPA)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VPVPV)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VPVPP)     @PUSHI %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(VPPAA)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(VPPAV)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(VPPAP)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(VPPVA)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(VPPVV)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(VPPVP)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(VPPPA)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(VPPPV)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(VPPPP)     @PUSHI %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PAAAA)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PAAAV)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PAAAP)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PAAVA)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PAAVV)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PAAVP)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PAAPA)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PAAPV)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PAAPP)     @PUSHII %2     @PUSH %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PAVAA)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PAVAV)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PAVAP)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PAVVA)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PAVVV)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PAVVP)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PAVPA)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PAVPV)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PAVPP)     @PUSHII %2     @PUSH %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PAPAA)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PAPAV)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PAPAP)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PAPVA)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PAPVV)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PAPVP)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PAPPA)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PAPPV)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PAPPP)     @PUSHII %2     @PUSH %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PVAAA)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PVAAV)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PVAAP)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PVAVA)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PVAVV)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PVAVP)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PVAPA)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PVAPV)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PVAPP)     @PUSHII %2     @PUSHI %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PVVAA)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PVVAV)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PVVAP)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PVVVA)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PVVVV)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PVVVP)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PVVPA)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PVVPV)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PVVPP)     @PUSHII %2     @PUSHI %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PVPAA)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PVPAV)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PVPAP)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PVPVA)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PVPVV)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PVPVP)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PVPPA)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PVPPV)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PVPPP)     @PUSHII %2     @PUSHI %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PPAAA)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PPAAV)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PPAAP)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PPAVA)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PPAVV)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PPAVP)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PPAPA)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PPAPV)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PPAPP)     @PUSHII %2     @PUSHII %3     @PUSH %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PPVAA)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PPVAV)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PPVAP)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PPVVA)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PPVVV)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PPVVP)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PPVPA)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PPVPV)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PPVPP)     @PUSHII %2     @PUSHII %3     @PUSHI %4     @PUSHII %5     @PUSHII %6     @CALL %1
M Call(PPPAA)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSH %6     @CALL %1
M Call(PPPAV)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSHI %6     @CALL %1
M Call(PPPAP)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSH %5     @PUSHII %6     @CALL %1
M Call(PPPVA)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSH %6     @CALL %1
M Call(PPPVV)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSHI %6     @CALL %1
M Call(PPPVP)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHI %5     @PUSHII %6     @CALL %1
M Call(PPPPA)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSH %6     @CALL %1
M Call(PPPPV)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSHI %6     @CALL %1
M Call(PPPPP)     @PUSHII %2     @PUSHII %3     @PUSHII %4     @PUSHII %5     @PUSHII %6     @CALL %1

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
# Setup Functon headers for profile and Linking
# Multi PUSHI/POPI helpers.
# These do NOT compensate for stack reversal.
# @PUSHI4 A B C D leaves D on top.
# To restore the same logical order, use @POPI4 D C B A.
# Nor do they allow PUSHing of constants or double indirect values like pointers.
M POPI8 @POPI %1 @POPI %2 @POPI %3 @POPI %4 @POPI %5 @POPI %6 @POPI %7 @POPI %8
M POPI7 @POPI %1 @POPI %2 @POPI %3 @POPI %4 @POPI %5 @POPI %6 @POPI %7
M POPI6 @POPI %1 @POPI %2 @POPI %3 @POPI %4 @POPI %5 @POPI %6
M POPI5 @POPI %1 @POPI %2 @POPI %3 @POPI %4 @POPI %5
M POPI4 @POPI %1 @POPI %2 @POPI %3 @POPI %4
M POPI3 @POPI %1 @POPI %2 @POPI %3
M POPI2 @POPI %1 @POPI %2

M PUSHI8 @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @PUSHI %5 @PUSHI %6 @PUSHI %7 @PUSHI %8
M PUSHI7 @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @PUSHI %5 @PUSHI %6 @PUSHI %7
M PUSHI6 @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @PUSHI %5 @PUSHI %6
M PUSHI5 @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @PUSHI %5
M PUSHI4 @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4
M PUSHI3 @PUSHI %1 @PUSHI %2 @PUSHI %3
M PUSHI2 @PUSHI %1 @PUSHI %2


#--------------------------------------------------
# Mode selection
#--------------------------------------------------

? USE_ONLY
   M __EX716_USE_ONLY 1
   P Enable USE_ONLY, all library functions must be specified.
ENDBLOCK


#--------------------------------------------------
# Common helpers (mode-independent)
#--------------------------------------------------

M REQUIREDSTORE MF __STORE_%1
M ISUSED        `?  __STORE_%1`

# Default: nothing required unless overridden


#--------------------------------------------------
# Default mode (include everything)
#--------------------------------------------------

# Mark function as used (optional in this mode)
M USE MF __USE_%1 %1

# FUNCTION always emits
M FUNCTION \
   MF __FUNC_BEGIN_%1 1 \
   MF __FUNC_LAST %1 \
   :__FuncStart \
   =__FUNC_START_%1 {__FuncStart}

M ENDFUNCTION \
   :__FuncEnd \
   =__FUNC_END_{__FUNC_LAST} {__FuncEnd} \
   MF __FUNC_END_{__FUNC_LAST} 1 \
   =__FUNC_SIZE {__FuncEnd}-{__FuncStart} \
   MF __FUNC_SIZE_{__FUNC_LAST} {__FUNC_SIZE} \
   P Function: {__FUNC_LAST} Size {__FUNC_SIZE} Bytes

# Size Reporting Macro - usefule durring assembling to see how much memory each library module consumes.
M SIZESINCE :NewHereMem \
             =SizeHereVar {NewHereMem}-{OldHereVar} \
             =OldHereVar {NewHereMem} \
             P Module {SIZESINCECOMMENT} : Size {SizeHereVar} Bytes
#
# FOR NEXT WHILE and CASE logic structures can be found in this related file.
#
I structure.asm
M SIZESINCECOMMENT common.mc
@SIZESINCE
ENDBLOCK
