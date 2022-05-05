L mul.ld
L div.ld
@JMP TCC_COM_DATA
:PR_FN
0
:PR_FO
0
:PR_FC
0
:PR_FZ
0
# Soft Stack Management variables
:SSP
b0 b18
# Default Pointer variable
:SSPPTR
0
# Primary memory swap variable
:SSWAP1
0
# Variable for 'very short' memory storage.
:NullStore
0
# FRAME points to start of local variable storage in SSP stack
:FRAME
0
# AFRAME points to start of argument variable storage in SSP stack
:AFRAME
0

# Move SSP to point to top value rather than next available slot.
M PTSP2VAL \
  @PUSHI SSP \
  @ADD 2 \
  @POPI SSP

# Move SSP from pointing at top value to the next available slot, which is where it should end a squence as default
M PTSP2FREE \
  @PUSHI SSP \
  @SUB 2 \
  @POPI SSP

# In line code to set global software flags from current HW flags state.
M SFLAGS \
  @MC2M 0 PR_FN \
  @MC2M 0 PR_FO \
  @MC2M 0 PR_FC \
  @MC2M 0 PR_FZ \
  @JMPZ %0PR_SetZ \
  :%0RT_SetC \
  @JMPC %0PR_SetC \
  :%0RT_SetO \
  @JMPO %0PR_SetO \
  :%0RT_SetN \
  @JMPN %0PR_SetN \
  @JMP %0PR_END \
  :%0PR_SetZ \
  @MC2M 1 PR_FZ \
  @JMP %0RT_SetC \
  :%0PR_SetC \
  @MC2M 1 PR_FC \
  @JMP %0RT_SetO \
  :%0PR_SetO \
  @MC2M 1 PR_FO \
  @JMP %0RT_SetN \
  :%0PR_SetN \
  @MC2M 1 PR_FN \
  :%0PR_END

# Imed value to SP Stack
M SPUSH \
    @PUSH %1 \
    @POPII SSP \
    @PTSP2FREE

# [Imed] value to SP Stack
M SPUSHI \
    @PUSHI %1 \
    @POPII SSP \
    @PTSP2FREE

# [[Imed]] value to SP Stack    
M SPUSHII \
    @PUSHII %1 \
    @POPII SSP \
    @PTSP2FREE

# SP Stack to [Imed]
M SPOPI \
    @PTSP2VAL \
    @PUSHII SSP \
    @POPI %1

# SP Stack to [[Imed]]
M SPOPII \
    @PTSP2VAL \
    @PUSHII SSP \
    @POPII %1

# POP value top of SP stack to HW Stack
M SPOP2HWS \
    @PTSP2VAL \
    @PUSHII SSP

# Take value on top of HW Stack and push to SP Stack
M SMVHW2SP \
    @POPII SSP \
    @PTSP2FREE

# ADD two items on SSP stack and put back on stack
# At start SSP points to blank 'future' top so move it down one word
# Then stack the [sp]
# Then mov SSP to the previous word
# Do the ADDI with current top of stack and [SSP]
# POP it to current SSP and then move SSP to new top
M SADD \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @ADDII SSP \
    @POPII SSP \
    @PTSP2FREE

# SUB two items on SSP stack and put back on stack
M SSUB \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @SUBII SSP \
    @POPII SSP \
    @PTSP2FREE

M SNEG \
   @PTSP2VAL \
   @PUSH 0 \
   @INV SSP \
   @ADD 1 \
   @POPII SSP \
   @PTSP2FREE

M SMUL \
    @PTSP2VAL \
    @PUSHII SSP \    
    @PTSP2VAL \
    @PUSHII SSP \
    @CALL $MUL \
    @POPII SSP \
    @PTSP2FREE

M SDIV \
    @PTSP2VAL \
    @PUSHII SSP \    
    @PTSP2VAL \
    @PUSHII SSP \
    @CALL $DIV \
    @POPII SSP \
    @PTSP2FREE

# SPRTI prints TOP of SP stack, but does not pop it off, leaving the value there and not modifying SSP
M SPRTI \
    @JMP %0J \
    :%0_H \
    0 \
    :%0J \
    @PUSHI SSP \
    @ADD 2 \
    @POPI SSPPTR \
    @PUSHII SSPPTR \
    @POPI %0_H \
    @PUSH 3 \
    @CAST %0_H \
    @POPI %0_H

# Swap SP's top to values.
M SSWAP \
  @SPOPI SSWAP1 \
  @SPOPI NullStore \
  @SPUSHI SSWAP1 \
  @SPUSHI NullStore

# Duplicate SP's top value.
M SDUP \
  @SPOPI SSWAP1 \
  @SPUSHI SSWAP1 \
  @SPUSHI SSWAP1

# Do a basic HW cmp on the top to values of SP Stack. Sets SP Flag registers to not depenedent on HW Flags later.
M SCMP \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @SUBII SSP \
    @SFLAGS \
    @POPII SSP

# Do a LT compare, and put 1 or 0 on stack based on result
M SCMPLT \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @CMPII SSP \
    @POPI SSPPTR \
    @JMPN %0IS \
    @SPUSH 1 \
    @JMP %0ED \
    :%0IS \
    @SPUSH 0 \
    :%0ED

# Do a GT compare, and put 1 or 0 on stack based on result    
M SCMPGT \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @CMPII SSP \
    @POPI SSPPTR \
    @JMPN %0IS \
    @PUSH 0 \
    @POPII SSP \
    @JMP %0ED \
    :%0IS \
    @PUSH 1 \
    @POPII SSP \
    :%0ED \
    @PTSP2FREE

# Do a LE compare, and put 1 or 0 on stack based on result
M SCMPLE \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @CMPII SSP \
    @POPI SSPPTR \
    @JMPN %0IS \
    @PUSH 1 \
    @POPII SSP \
    @JMP %0ED \
    :%0IS \
    @PUSH 0 \
    @POPII SSP \
    :%0ED \
    @PTSP2FREE
# Do a GE compare, and put 1 or 0 on stack based on result
M SCMPGE \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @CMPII SSP \
    @POPI SSPPTR \
    @JMPN %0IS \
    @JMPZ %0IS \
    @PUSH 0 \
    @POPII SSP \
    @JMP %0ED \
    :%0IS \
    @PUSH 1 \
    @POPII SSP \
    :%0ED \
    @PTSP2FREE

# Do an OR compare, and put 1 or 0 on stack based on result
M SOR \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @ORII SSP \
    @POPII SSP \
    @PTSP2FREE

# Do an AND compare, and put 1 or 0 on stack based on result
M SAND \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @ANDII SSP \
    @POPII SSP \
    @PTSP2FREE

# Do a EQ compare, and put 1 or 0 on stack based on result
M SCMPEQ \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @CMPII SSP \
    @POPI SSPPTR \
    @JMPZ %0IS \
    @PUSH 0    \
    @POPII SSP \
    @JMP %0ED \
    :%0IS \
    @PUSH 1 \
    @POPII SSP \
    :%0ED \
    @PTSP2FREE

# Do a NE compare, and put 1 or 0 on stack based on result
M SCMPNE \
    @PTSP2VAL \
    @PUSHII SSP \
    @PTSP2VAL \
    @CMPII SSP \
    @POPI SSPPTR \
    @JMPZ %0IS \
    @PUSH 1    \
    @POPII SSP \
    @JMP %0ED \
    :%0IS \
    @PUSH 0 \
    @POPII SSP \
    :%0ED \
    @PTSP2FREE    

# Do a Logical Jump based on if SP Stack is 'false' or zero.
M SJMPZ \
  @SPOPI LJunk \
  @PUSH 0 \
  @CMPI LJunk \
  @POPI LJunk \
  @JMPZ %1

# Non destructure print of "TOP' of SP stack
M SPRTTOP \
  @PTSP2VAL \
  @PRTII SSP \
  @PTSP2FREE

# Assign a constant String to memory with null termination and put address of start of string to HW Stack.
M STRNEW \
  @JMP J%0 \
  :%0M1 %1 b0 \
  :%0UN1 0 \
  :J%0 \
  @PUSH %0M1

M SCALL \
  @SPUSH %0R \
  @JMP %1 \
  :%0R

M SRET \
  @SPOPI %0Dst \
  @JMPI %0Dst \
  :%0Dst 0
  
:Lptr
	0
:Lidx
	0
:LJunk
	0
:LReturn
        0
:PrintStack
	@POPI LReturn
	@MM2M SSP Lptr
	@MC2M 0 Lidx
	@PRT "------Stack Dump:"
	@PRTI Lptr
	@PRTNL
	@PRT "SSP: "
	@PRTI SSP
	@PRT " FRAME: "
	@PRTI FRAME
	@PRT " AFRAME: "
	@PRTI AFRAME
	@PRTNL
:LLoop1
	@PUSH 4
	@CMPI Lidx
	@POPI LJunk
	@JMPZ LLexit
	@PRTI Lptr
	@PRT ":["
	@PRTII Lptr
	@PRT "] "
	@PUSHI Lptr
	@ADD 2
	@POPI Lptr
	@PUSHI Lidx
	@ADD 1
	@POPI Lidx
	@JMP LLoop1
:LLexit
	@PRTNL
	@PUSH 102
	@CAST 1
	@POPI LJunk
	@PUSHI LReturn
	@RET
:TCC_COM_DATA
