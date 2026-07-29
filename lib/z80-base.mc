# This defines the Z80 optcodes in terms of the EX716 Macros so we can use them to build a EX716 emulator inside Z80 CPU
#
# Helpers
M LO %( %AND %1 0xff %)
M HI %( %SHR %1 8 %AND 0xff %)
#
# LD r,n (immediate 8-bit)
M Z_LD_A_I  $$0x3E %LO %1
M Z_LD_B_I  $$0x06 %LO %1
M Z_LD_C_I  $$0x0E %LO %1
M Z_LD_D_I  $$0x16 %LO %1
M Z_LD_E_I  $$0x1E %LO %1
M Z_LD_H_I  $$0x26 %LO %1
M Z_LD_L_I  $$0x2E %LO %1
#
# LD 16 bit register nn
M Z_LD_BC_I $$0x01 %LO %1 %HI %1
M Z_LD_DE_I $$0x11 %LO %1 %HI %1
M Z_LD_HL_I $$0x21 %LO %1 %HI %1
M Z_LD_SP_I $$0x31 %LO %1 %HI %1
#
# LD HL,(nn)
M Z_LD_HL_MEM \
    $$0x2A \
    %LO %1 \
    %HI %1
#
# LD (nn),HL
M Z_ST_HL_MEM \
    $$0x22 \
    %LO %1 \
    %HI %1
#
# LD A,(nn) and LD (nn),A
M Z_LD_A_MEM \
    $$0x3A %LO %1 %HI %1

M Z_ST_A_MEM \
    $$0x32 %LO %1 %HI %1
#
# LD (HL),r and LD r,(HL)
M Z_LD_HL_A $$0x77
M Z_LD_A_HL $$0x7E
M Z_LD_HL_B $$0x70
M Z_LD_HL_C $$0x71
M Z_LD_HL_D $$0x72
M Z_LD_HL_E $$0x73
M Z_LD_HL_H $$0x74
M Z_LD_HL_L $$0x75
#
# LD r,r (register copy)
M Z_LD_A_A $$0x7F
M Z_LD_A_B $$0x78
M Z_LD_A_C $$0x79
M Z_LD_A_D $$0x7A
M Z_LD_A_E $$0x7B
M Z_LD_A_H $$0x7C
M Z_LD_A_L $$0x7D
#
# 16-BIT ARITHMETIC
M Z_INC_BC $$0x03
M Z_INC_DE $$0x13
M Z_INC_HL $$0x23
M Z_INC_SP $$0x33

M Z_DEC_BC $$0x0B
M Z_DEC_DE $$0x1B
M Z_DEC_HL $$0x2B
M Z_DEC_SP $$0x3B
#
# ADDHL,rr
M Z_ADD_HL_BC $$0x09
M Z_ADD_HL_DE $$0x19
M Z_ADD_HL_HL $$0x29
M Z_ADD_HL_SP $$0x39
#
# 8-BIT ALU INSTRUCTIONS
#
# ADD
M Z_ADD_A_B $$0x80
M Z_ADD_A_C $$0x81
M Z_ADD_A_D $$0x82
M Z_ADD_A_E $$0x83
M Z_ADD_A_H $$0x84
M Z_ADD_A_L $$0x85
M Z_ADD_A_HL $$0x86
M Z_ADD_A_I $$0xC6 %LO %1
#
# SUB
M Z_SUB_A_B $$0x90
M Z_SUB_A_C $$0x91
M Z_SUB_A_D $$0x92
M Z_SUB_A_E $$0x93
M Z_SUB_A_H $$0x94
M Z_SUB_A_L $$0x95
M Z_SUB_A_HL $$0x96
M Z_SUB_A_I $$0xD6 %LO %1
#
# AND/OR/XOR
M Z_AND_A_B $$0xA0
M Z_AND_A_C $$0xA1
M Z_AND_A_HL $$0xA6
M Z_AND_A_I $$0xE6 %LO %1

M Z_OR_A_B  $$0xB0
M Z_OR_A_C  $$0xB1
M Z_OR_A_HL $$0xB6
M Z_OR_A_I  $$0xF6 %LO %1

M Z_XOR_A_B $$0xA8
M Z_XOR_A_C $$0xA9
M Z_XOR_A_HL $$0xAE
M Z_XOR_A_I $$0xEE %LO %1
#
# CP
M Z_CP_B  $$0xB8
M Z_CP_C  $$0xB9
M Z_CP_HL $$0xBE
M Z_CP_I  $$0xFE %LO %1
#
# BRANCHING / FLOW CONTROL
#
# Unconditional
M Z_JMP     $$0xC3 %LO %1 %HI %1
M Z_CALL    $$0xCD %LO %1 %HI %1
M Z_RET     $$0xC9
M Z_RETI    $$0xED $$0x4D
M Z_RETN    $$0xED $$0x45
#
# Conditional jumps
M Z_JZ   $$0xCA %LO %1 %HI %1
M Z_JNZ  $$0xC2 %LO %1 %HI %1
M Z_JC   $$0xDA %LO %1 %HI %1
M Z_JNC  $$0xD2 %LO %1 %HI %1
M Z_JP   $$0xF2 %LO %1 %HI %1
M Z_JM   $$0xFA %LO %1 %HI %1
#
# Conditional returns
M Z_RET_Z   $$0xC8
M Z_RET_NZ  $$0xC0
M Z_RET_C   $$0xD8
M Z_RET_NC  $$0xD0
#
# SHIFTS / ROTATES
M Z_RLC_A $$0xCB $$0x07
M Z_RRC_A $$0xCB $$0x0F
M Z_RL_A  $$0xCB $$0x17
M Z_RR_A  $$0xCB $$0x1F

M Z_SLA_A $$0xCB $$0x27
M Z_SRA_A $$0xCB $$0x2F
M Z_SRL_A $$0xCB $$0x3F
#
# NOP/HALT
M Z_NOP $$0x00
M Z_HALT $$0x76

#
#
