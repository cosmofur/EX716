# #         Common macros fo CCLIB
L softstack.ld
L mul.ld
L div.ld
##################
:R_EBP 0  
:R_ESP 0
M MULS @CALL MULU @POPI %1
M DIVS @CALL DIVU @POPI %1 @POPNULL
M MODS @CALL DIVU @POPNULL @POPI %1
M SETLE @JLE %0True @PUSH 0 @JMP %0End :%0True @PUSH 1 :%0End @POPI %1
M SETGE @JGE %0True @PUSH 0 @JMP %0End :%0True @PUSH 1 :%0End @POPI %1
M SETL @JLT %0True @PUSH 0 @JMP %0End :%0True @PUSH 1 :%0End @POPI %1
M SETG @JGT %0True @PUSH 0 @JMP %0End :%0True @PUSH 1 :%0End @POPI %1
M SETNE @JMPNZ %0True @PUSH 0 @JMP %0End :%0True @PUSH 1 :%0End @POPI %1
M SETE @JMPZ %0True @PUSH 0 @JMP %0End :%0True @PUSH 1 :%0End @POPI %1
M CALLS @PUSH %0Return @SWP @JMPS :%0Return
