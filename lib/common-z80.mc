# This is an alternative version of the common.mc but targes a traditional Z80 CPU rather than EX716
# while trying to remain code compatable with the EX716 assembly code.
#
; -------------------------
; Universal CALL helper
; -------------------------
; @CALL <label> – insert Z80 CALL <label>
M CALL $$0xCD %1     ; 0xCD = CALL nn (16-bit address follows)

; -------------------------
; Z80 primitives (direct encodings)
; -------------------------
M Z80_NOP     $$0x00
M Z80_INC_HL  $$0x23


; --- Core Z80 macros we’ll reuse ---
M Z80_LD_HL_ADDR   $$0x2A %1          ; LD HL,(nn)
M Z80_ST_HL_ADDR   $$0x22 %1          ; LD (nn),HL
M Z80_DEC_HL       $$0x2B             ; DEC HL
M Z80_LD_A_IMM     $$0x3E $$%( %AND %1 0xFF %)   ; LD A,n (8-bit imm)
M Z80_ST_HL_A      $$0x77             ; LD (HL),A
M Z80_RET          $$0xC9             ; RET

; --- Split a 16-bit value into high/low bytes ---
M LOW_BYTE  %( %AND %1 0xFF %)
M HIGH_BYTE %( %Field 8 8 %1 %)

; LD (HL),n
M Z80_ST_AT_HL $$0x36 $$%1

; LD A,n
M Z80_LD_A    $$0x3E $$%1

; CP A,n
M Z80_CP_A    $$0xFE $$%1

; Helpers for byte extraction
M Z80_HighByte %( %Field 8 8 %1 %)
M Z80_LowByte  %( %AND %1 0xFF %)

; -------------------------
; Soft stack pointer storage
; -------------------------
. 0xF800
:SPTR 0          ; 16-bit word for soft stack pointer
; 0 NOP
M NOP @Z80_NOP

; 6 POPNULL
M POPNULL \
    @Z80_LD_HL SPTR \
    @Z80_INC_HL @Z80_ST_HL SPTR \
    @Z80_INC_HL @Z80_ST_HL SPTR \
    @Z80_RET

; 55 RET (we map EX716 SRTP to RET)
M SRTP @Z80_RET
; 1 PUSH
M PUSH  @CALL PUSH_HELPER

; 2 DUP
M DUP   @CALL DUP_HELPER

; 3 PUSHI imm16
M PUSHI \
    @Z80_LD_HL SPTR \
    @Z80_DEC_HL @Z80_ST_HL SPTR \
    @Z80_ST_AT_HL @Z80_LowByte %1 \
    @Z80_DEC_HL @Z80_ST_HL SPTR \
    @Z80_ST_AT_HL @Z80_HighByte %1 \
    @Z80_RET

; 4 PUSHII
M PUSHII @CALL PUSHII_HELPER

; 5 PUSHS
M PUSHS  @CALL PUSHS_HELPER

; 7 SWP
M SWP    @CALL SWP_HELPER

; 8 POPI
M POPI   @CALL POPI_HELPER

; 9 POPII
M POPII  @CALL POPII_HELPER

; 10 POPS
M POPS   @CALL POPS_HELPER

; ADD family
M ADD   @CALL ADD_HELPER
M ADDS  @CALL ADDS_HELPER
M ADDI  @CALL ADDI_HELPER
M ADDII @CALL ADDII_HELPER

; SUB family
M SUB   @CALL SUB_HELPER
M SUBS  @CALL SUBS_HELPER
M SUBI  @CALL SUBI_HELPER
M SUBII @CALL SUBII_HELPER

; OR family
M OR    @CALL OR_HELPER
M ORS   @CALL ORS_HELPER
M ORI   @CALL ORI_HELPER
M ORII  @CALL ORII_HELPER

; AND family
M AND   @CALL AND_HELPER
M ANDS  @CALL ANDS_HELPER
M ANDI  @CALL ANDI_HELPER
M ANDII @CALL ANDII_HELPER

; XOR family
M XOR   @CALL XOR_HELPER
M XORS  @CALL XORS_HELPER
M XORI  @CALL XORI_HELPER
M XORII @CALL XORII_HELPER

M CMP   @CALL CMP_HELPER
M CMPS  @CALL CMPS_HELPER
M CMPI  @CALL CMPI_HELPER
M CMPII @CALL CMPII_HELPER

M JMPZ @CALL JMPZ_HELPER
M JMPN @CALL JMPN_HELPER
M JMPC @CALL JMPC_HELPER
M JMPO @CALL JMPO_HELPER

M JMP  @CALL JMP_HELPER
M JMPI @CALL JMPI_HELPER
M JMPS @CALL JMPS_HELPER

M RRTC  @CALL RRTC_HELPER
M RLTC  @CALL RLTC_HELPER
M SHR   @CALL SHR_HELPER
M SHL   @CALL SHL_HELPER
M INV   @CALL INV_HELPER
M COMP2 @CALL COMP2_HELPER

M FCLR  @CALL FCLR_HELPER
M FSAV  @CALL FSAV_HELPER
M FLOD  @CALL FLOD_HELPER

M ADM   @CALL ADM_HELPER
M SCLR  @CALL SCLR_HELPER

. 0xf000

:PUSH_HELPER
    @Z80_LD_HL_ADDR SPTR

    @Z80_DEC_HL
    @Z80_DEC_HL
    @Z80_ST_HL_ADDR SPTR

    @Z80_LD_A_IMM LOW_BYTE %1
    @Z80_ST_HL_A
    @Z80_DEC_HL

    @Z80_LD_A_IMM HIGH_BYTE %1
    @Z80_ST_HL_A

    @Z80_RET                        


;------------------------------------------------------
; Helper: ADD_HELPER
; Pops two 16-bit operands from softstack, adds them,
; pushes result back.
;------------------------------------------------------

:ADD_HELPER
    ; --- Load SPTR into HL ---
    @Z80_LD_HL_ADDR SPTR

    ; --- Pop first operand into DE ---
    @Z80_LD_A_HL         ; A = (HL) → low byte
    @Z80_LD_E_L          ; E = A
    @Z80_DEC_HL
    @Z80_LD_A_HL         ; A = (HL) → high byte
    @Z80_LD_D_H          ; D = A
    @Z80_INC_HL          ; HL += 2 (restore after pop)
    @Z80_INC_HL
    @Z80_ST_HL_ADDR SPTR ; update SPTR

    ; --- Pop second operand into HL ---
    @Z80_LD_A_HL
    @Z80_LD_L_A
    @Z80_DEC_HL
    @Z80_LD_A_HL
    @Z80_LD_H_A
    @Z80_INC_HL
    @Z80_INC_HL
    @Z80_ST_HL_ADDR SPTR

    ; --- Perform HL = HL + DE ---
    @Z80_ADD_HL_DE

    ; --- Push result (HL) ---
    @Z80_LD_DE_ADDR SPTR   ; DE = SPTR
    @Z80_DEC_DE            ; DE -= 1
    @Z80_ST_DE_ADDR SPTR   ; store back SPTR
    @Z80_LD_A_L
    @Z80_ST_AT_DE_A        ; store low byte
    @Z80_DEC_DE
    @Z80_ST_DE_ADDR SPTR
    @Z80_LD_A_H
    @Z80_ST_AT_DE_A        ; store high byte

    @Z80_RET
