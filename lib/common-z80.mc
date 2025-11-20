# This is an alternative version of the common.mc but targes a traditional Z80 CPU rather than EX716
# while trying to remain code compatable with the EX716 assembly code.
#
# Global Variable used to define software versions of EX716 features
I z80-base.mc
=VSP 0xf000        # 16 bit stack pointer
=VBASE 0xf002      # Base or low memory of Virtual Stack Pointer
#
M PUSHII \
    @Z_LD_HL_MEM %1        \ # HL = ( %1 ) = pointer
    @Z_LD_DE_HL            \ # DE = HL (copy pointer)
    @Z_LD_HL_MEM DE        \ # HL = ( pointer ) = final value
    @Z_LD_DE_I VSP         \ # DE = VSP \
    @Z_ST_HL_MEM DE        \ # push HL
    @Z_DEC_DE              \
    @Z_DEC_DE              \
    @Z_ST_DE_MEM VSP
M PUSHI \
    @Z_LD_HL_I %1 \
    @Z_LD_DE_I VSP \
    @Z_ST_HL_MEM DE \
    @Z_DEC_DE \
    @Z_DEC_DE \
    @Z_ST_DE_MEM VSP      # store new VSP
M PUSH \
    @Z_LD_HL_MEM %1        \ # HL = (address)
    @Z_LD_DE_I VSP         \ # DE = VSP
    @Z_ST_HL_MEM DE        \ # store HL at stack top
    @Z_DEC_DE              \ # move stack down
    @Z_DEC_DE              \
    @Z_ST_DE_MEM VSP         # update VSP
M PUSHS \
    @Z_LD_DE_I VSP         \ # DE = VSP  
    @Z_LD_HL_MEM DE        \ # HL = (VSP) = address
    @Z_INC_DE              \ # move VSP up
    @Z_INC_DE              \
    @Z_ST_DE_MEM VSP       \ # store new VSP
    @Z_LD_DE_HL            \ # DE = HL (address)
    @Z_LD_HL_MEM DE        \ # HL = (address) (load value)
    @Z_LD_DE_I VSP         \ # DE = VSP (push location)
    @Z_ST_HL_MEM DE        \ # push HL
    @Z_DEC_DE              ; adjust VSP downward 
    @Z_DEC_DE              \
    @Z_ST_DE_MEM VSP
M @POP \
    @Z_LD_DE_MEM VSP \
    @Z_LD_HL_MEM DE \
    @Z_INC_DE \
    @Z_INC_DE \
    @Z_ST_DE_MEM VSP
M @ADD \
    @POP      \ # gets RHS → HL \
    @Z_PUSH_HL \ # (temp)      \
    @POP      \ # gets LHS → HL \
    @Z_POP_DE  \ # DE = RHS      \
    @Z_ADD_HL_DE \
    @Z_PUSH_HL
M @SUB \
    @POP \
    @Z_PUSH_HL \
    @POP \
    @Z_POP_DE \ # A←H, CP D does compare but we want actual subtract:
    @Z_OR_A_A \ # clear carry
    @Z_SBC_HL_DE \
    @Z_PUSH_HL
M @CMP \
    @POP \
    @Z_PUSH_HL \
    @POP \
    @Z_POP_DE \
    @Z_CP_HL \
    @Z_PUSH_DE \
    @Z_PUSH_HL
M @JMP @Z_JMP %1
M @JLE \
    @Z_JP_M %1 \
    @Z_JZ %1
M @JGE \
    @Z_JP_P %1 \
    @Z_JZ %1
M @CALL  @Z_CALL %1
M @RET @Z_RET
M @AND \
    @POP \
    @Z_PUSH_HL \
    @POP \
    @Z_POP_DE \
    @Z_LD_A_L \  #     AND L,E and propagate into HL:
    @Z_AND_A_E \
    @Z_LD_L_A \
    @Z_LD_A_H \ #      AND H,D:
    @Z_AND_A_D \
    @Z_LD_H_A \
    @Z_PUSH_HL
