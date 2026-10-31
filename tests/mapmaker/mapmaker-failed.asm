.DATA 1
I commonDS.mc
@JMP __mapmaker_entry
:__mapmaker_entry
.ENTRY __mapmaker_entry
@PUSH 1
@SSET SegDS
@PUSH 1
@ADM
@FJMP 2 __ex716_main_direct
@END

L clocals.ld
L lmath.ld
L farptr.ld
@FUNCTION __ex716_uee778e3b_static_0
:__ex716_uee778e3b_static_0
@PUSHRETURN
@CLocals 6
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_0_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_0_local_1 2
   @CLocalAt __ex716_pointer_tmp 4

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_0_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_0_local_0

   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_0_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_0_local_1
   @PUSHS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_0_local_0
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_0_local_1
   @PUSH 2
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L1

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uee778e3b_static_5
:__ex716_uee778e3b_static_5
@PUSHRETURN
@CLocals 12
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_5_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_5_local_2 4
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_5_local_3 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_5_local_4 8
   @CLocalAt __ex716_pointer_tmp 10

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0

   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_1
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_1
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0
   @PUSH 2
   @ADDS
   @PUSHS
   @CMPS
   @POPNULL
   @POPNULL
   @JULE __ex716_uee778e3b_L3
   @PUSH 0
   @JMP __ex716_uee778e3b_L2
:__ex716_uee778e3b_L3
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_2
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_1
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0
   @PUSHS
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_4
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_4
   @PUSHS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_1
   @SUBS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_5_local_2
:__ex716_uee778e3b_L2

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uee778e3b_static_9 3
G tcgetattr
@FUNCTION tcgetattr
:tcgetattr
@PUSHRETURN
@CLocals 6
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_uee778e3b_tcgetattr_local_0 0
   @CLocalAt __ex716_uee778e3b_tcgetattr_local_1 2
   @CLocalAt __ex716_pointer_tmp 4

   @CPOPI __ex716_uee778e3b_tcgetattr_local_1
   @CPOPI __ex716_uee778e3b_tcgetattr_local_0

   @CPUSHI __ex716_uee778e3b_tcgetattr_local_1
   @CPOPI __ex716_uee778e3b_tcgetattr_local_1
   @CPUSHI __ex716_uee778e3b_tcgetattr_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L8
   @CPUSHI __ex716_uee778e3b_tcgetattr_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L6
:__ex716_uee778e3b_L8
   @PUSH -1
   @JMP __ex716_uee778e3b_L5
:__ex716_uee778e3b_L6
   @CPUSHI __ex716_uee778e3b_tcgetattr_local_1
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_tcgetattr_local_1
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_tcgetattr_local_1
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_tcgetattr_local_1
   @PUSH 6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH __ex716_uee778e3b_static_9
   @PUSHS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 0
:__ex716_uee778e3b_L5

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G tcsetattr
@FUNCTION tcsetattr
:tcsetattr
@PUSHRETURN
@CLocals 12
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_uee778e3b_tcsetattr_local_0 0
   @CLocalAt __ex716_uee778e3b_tcsetattr_local_1 2
   @CLocalAt __ex716_uee778e3b_tcsetattr_local_2 4
   @CLocalAt __ex716_uee778e3b_tcsetattr_local_3 6
   @CLocalAt __ex716_uee778e3b_tcsetattr_local_4 8
   @CLocalAt __ex716_pointer_tmp 10

   @CPOPI __ex716_uee778e3b_tcsetattr_local_2
   @CPOPI __ex716_uee778e3b_tcsetattr_local_1
   @CPOPI __ex716_uee778e3b_tcsetattr_local_0

   @PUSH 0
   @CPOPI __ex716_uee778e3b_tcsetattr_local_4
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_0
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L13
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_1
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L13
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L10
:__ex716_uee778e3b_L13
   @PUSH -1
   @JMP __ex716_uee778e3b_L9
:__ex716_uee778e3b_L10
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_2
   @PUSH 6
   @ADDS
   @PUSHS
   @CPOPI __ex716_uee778e3b_tcsetattr_local_3
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_3
   @PUSH 65532
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L14
   @PUSH -1
   @JMP __ex716_uee778e3b_L9
:__ex716_uee778e3b_L14
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_3
   @PUSH 1
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L16
   @CALL __EX716_TTY_COOKED
   @POPNULL
   @JMP __ex716_uee778e3b_L17
:__ex716_uee778e3b_L16
   @CALL __EX716_TTY_RAW
   @POPNULL
:__ex716_uee778e3b_L17
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_3
   @PUSH 2
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L18
   @CALL __EX716_TTY_ECHO
   @POPNULL
   @JMP __ex716_uee778e3b_L19
:__ex716_uee778e3b_L18
   @CALL __EX716_TTY_NOECHO
   @POPNULL
:__ex716_uee778e3b_L19
   @PUSH __ex716_uee778e3b_static_9
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_tcsetattr_local_3
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 0
:__ex716_uee778e3b_L9

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uee778e3b_static_31 $$$1000000000
::__ $$$100000000
::__ $$$10000000
::__ $$$1000000
::__ $$$100000
::__ $$$10000
::__ $$$1000
::__ $$$100
::__ $$$10
::__ $$$1
@FUNCTION __ex716_uee778e3b_static_32
:__ex716_uee778e3b_static_32
@PUSHRETURN
@CLocals 18
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_2 4
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_3 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_4 8
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_5 10
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_6 12
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_32_local_7 14
   @CLocalAt __ex716_pointer_tmp 16

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0

   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 8
   @ADDS
   @PUSHS
   @PUSH 32767
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L21
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 10
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @JMP __ex716_uee778e3b_L20
:__ex716_uee778e3b_L21
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L23
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 4
   @ADDS
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_2
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L24
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_1
   @PUSH 255
   @ANDS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_2
   @CALL fputc
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_3
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_3
   @PUSH -1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L24
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 10
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @JMP __ex716_uee778e3b_L24
:__ex716_uee778e3b_L23
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 6
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L29
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 2
   @ADDS
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_5
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_5
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L27
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_5
   @PUSH 1
   @SUBS
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uee778e3b_L27
:__ex716_uee778e3b_L29
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSHS
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_1
   @AND 0xff
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L27
:__ex716_uee778e3b_L24
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_0
   @PUSH 8
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_7
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_7
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_32_local_7
   @PUSHS
   @PUSH 1
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L20

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uee778e3b_static_45
:__ex716_uee778e3b_static_45
@PUSHRETURN
@CLocals 10
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_45_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_45_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_45_local_2 4
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_45_local_3 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_45_local_4 8

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_0

   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_1
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_2
   @JMP __ex716_uee778e3b_L32
:__ex716_uee778e3b_L31
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_1
   @CALL __ex716_uee778e3b_static_32
:__ex716_uee778e3b_L32
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_3
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_3
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_2
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_3
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uee778e3b_L34
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_0
   @PUSH 10
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_45_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L31
:__ex716_uee778e3b_L34
:__ex716_uee778e3b_L30

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uee778e3b_static_51
:__ex716_uee778e3b_static_51
@PUSHRETURN
@CLocals 60
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_off47 47
   @CLocalAt __ex716_off48 48
   @CLocalAt __ex716_off49 49
   @CLocalAt __ex716_off50 50
   @CLocalAt __ex716_off51 51
   @CLocalAt __ex716_off52 52
   @CLocalAt __ex716_off53 53
   @CLocalAt __ex716_off54 54
   @CLocalAt __ex716_off55 55
   @CLocalAt __ex716_off56 56
   @CLocalAt __ex716_off57 57
   @CLocalAt __ex716_off58 58
   @CLocalAt __ex716_off59 59
   @CLocalAt __ex716_off60 60
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_0 0
   @CLocal32At __ex716_uee778e3b___ex716_uee778e3b_static_51_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_3 8
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4 10
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5 12
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6 14
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_7 16
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_8 28
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_9 30
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_10 32
   @CLocal32At __ex716_uee778e3b___ex716_uee778e3b_static_51_local_11 34
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_12 38
   @CLocal32At __ex716_uee778e3b___ex716_uee778e3b_static_51_local_13 40
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_14 44
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_15 46
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_16 48
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_17 50
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_18 52
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_19 54
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_51_local_20 56
   @CLocalAt __ex716_pointer_tmp 58

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_3
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_0

#USE SUB32U
#USE AND32
#USE SHR32
#USE CMP32U
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_0
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_3
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_3
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @PUSH 16
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L38
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @PUSH 8
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L36
:__ex716_uee778e3b_L38
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @PUSH 16
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L40
   @PUSH 4
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_12
   @JMP __ex716_uee778e3b_L41
:__ex716_uee778e3b_L40
   @PUSH 3
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_12
:__ex716_uee778e3b_L41
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_12
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_10
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @PUSH 16
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L43
   @PUSH32(A) $$$15
   @CPOPI __ex716_off42
   @CPOPI __ex716_off40
   @JMP __ex716_uee778e3b_L44
:__ex716_uee778e3b_L43
   @PUSH32(A) $$$7
   @CPOPI __ex716_off42
   @CPOPI __ex716_off40
:__ex716_uee778e3b_L44
   @CPUSHI __ex716_off40
   @CPUSHI __ex716_off42
   @CPOPI __ex716_off36
   @CPOPI __ex716_off34
:__ex716_uee778e3b_L45
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_off34
   @CPUSHI __ex716_off36
   @CALL AND32
   @POPNULL
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_16
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_16
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @PUSH 10
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L50
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @PUSH 48
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_14
   @JMP __ex716_uee778e3b_L51
:__ex716_uee778e3b_L50
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L52
   @PUSH 65
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_15
   @JMP __ex716_uee778e3b_L53
:__ex716_uee778e3b_L52
   @PUSH 97
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_15
:__ex716_uee778e3b_L53
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_15
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @ADDS
   @PUSH 10
   @SUBS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_14
:__ex716_uee778e3b_L51
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_16
   @CPUSHADDR __ex716_uee778e3b___ex716_uee778e3b_static_51_local_7
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_14
   @AND 0xff
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_10
   @AND 0x7fff
   @CALL SHR32
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
:__ex716_uee778e3b_L46
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @PUSH32(A) $$$0
   @CALL CMP32U
   @IF32_NE
      @JMP __ex716_uee778e3b_L45
   @ENDIF
   @JMP __ex716_uee778e3b_L37
:__ex716_uee778e3b_L36
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_17
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_17
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_8
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_17
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
:__ex716_uee778e3b_L54
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @JMP __ex716_uee778e3b_L59
:__ex716_uee778e3b_L58
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @SHLN 2
   @PUSH __ex716_uee778e3b_static_31
   @ADDS
   @DUP
   @PUSHS
   @SWP
   @ADD 2
   @PUSHS
   @CALL SUB32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
:__ex716_uee778e3b_L59
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @SHLN 2
   @PUSH __ex716_uee778e3b_static_31
   @ADDS
   @DUP
   @PUSHS
   @SWP
   @ADD 2
   @PUSHS
   @CALL CMP32U
   @IF32_UGE
      @JMP __ex716_uee778e3b_L58
   @ENDIF
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_18
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_18
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L64
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_8
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_18
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L64
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @PUSH 9
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L61
:__ex716_uee778e3b_L64
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_19
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_19
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_19
   @CPUSHADDR __ex716_uee778e3b___ex716_uee778e3b_static_51_local_7
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_5
   @PUSH 48
   @ADDS
   @AND 0xff
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_8
:__ex716_uee778e3b_L61
:__ex716_uee778e3b_L55
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @PUSH 10
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L54
:__ex716_uee778e3b_L37
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @JMP __ex716_uee778e3b_L68
:__ex716_uee778e3b_L65
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_2
   @PUSH 10
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L71
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @CPUSHADDR __ex716_uee778e3b___ex716_uee778e3b_static_51_local_7
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_20
   @JMP __ex716_uee778e3b_L72
:__ex716_uee778e3b_L71
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @SUBS
   @CPUSHADDR __ex716_off15
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_20
:__ex716_uee778e3b_L72
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_0
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_20
   @AND 0xff
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L66
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
:__ex716_uee778e3b_L68
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L65
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_0
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_51_local_6
:__ex716_uee778e3b_L35

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uee778e3b_static_95
:__ex716_uee778e3b_static_95
@PUSHRETURN
@CLocals 18
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_2 4
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_3 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_4 8
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_5 10
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_6 12
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_95_local_7 14
   @CLocalAt __ex716_pointer_tmp 16

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_0

   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_0
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_1
   @JMP __ex716_uee778e3b_L75
:__ex716_uee778e3b_L74
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_0
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_3
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_0
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_3
   @PUSH 1
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_3
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 48
   @SUBS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_2
   @PUSH 3276
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_1
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uee778e3b_L79
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_1
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L77
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_2
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uee778e3b_L77
:__ex716_uee778e3b_L79
   @PUSH -1
   @JMP __ex716_uee778e3b_L73
:__ex716_uee778e3b_L77
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_1
   @SHL
   @DUP
   @SHLN 2
   @ADDS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_2
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_1
:__ex716_uee778e3b_L75
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_0
   @PUSHS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_7
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_7
   @PUSH 48
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L80
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_7
   @PUSH 57
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uee778e3b_L74
:__ex716_uee778e3b_L80
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_95_local_1
:__ex716_uee778e3b_L73

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uee778e3b_static_107
:__ex716_uee778e3b_static_107
@PUSHRETURN
@CLocals 32
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2 4
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_3 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4 8
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_5 10
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_6 12
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_7 14
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_8 16
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9 18
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_10 20
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11 22
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_12 24
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_13 26
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_14 28
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_107_local_15 30

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_8
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_7
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_6
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_5
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_3
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0

   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_1
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_7
   @AND 0xff
   @CSTOREB __ex716_uee778e3b___ex716_uee778e3b_static_107_local_7
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_8
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_8
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_10
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L82
   @JMP __ex716_uee778e3b_L85
:__ex716_uee778e3b_L84
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_10
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_10
:__ex716_uee778e3b_L85
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_10
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_8
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L84
:__ex716_uee778e3b_L82
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_12
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_6
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L87
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_5
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uee778e3b_L87
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_5
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2
   @SUBS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_12
:__ex716_uee778e3b_L87
   @CLOADB __ex716_uee778e3b___ex716_uee778e3b_static_107_local_7
   @CSIGNEXT8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L90
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_13
   @JMP __ex716_uee778e3b_L91
:__ex716_uee778e3b_L90
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_13
:__ex716_uee778e3b_L91
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_3
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2
   @SUBS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_12
   @SUBS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_10
   @SUBS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_13
   @SUBS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L92
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11
:__ex716_uee778e3b_L92
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_15
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4
   @PUSH 8
   @ANDS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L94
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4
   @PUSH 1
   @ANDS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L94
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_5
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L94
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L94
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_12
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_12
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11
:__ex716_uee778e3b_L94
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4
   @PUSH 1
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L96
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @PUSH 32
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11
   @CALL __ex716_uee778e3b_static_45
:__ex716_uee778e3b_L96
   @CLOADB __ex716_uee778e3b___ex716_uee778e3b_static_107_local_7
   @CSIGNEXT8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L98
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @CLOADB __ex716_uee778e3b___ex716_uee778e3b_static_107_local_7
   @CSIGNEXT8
   @CALL __ex716_uee778e3b_static_32
:__ex716_uee778e3b_L98
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @JMP __ex716_uee778e3b_L103
:__ex716_uee778e3b_L100
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_8
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CALL __ex716_uee778e3b_static_32
:__ex716_uee778e3b_L101
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
:__ex716_uee778e3b_L103
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_10
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L100
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @PUSH 48
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_12
   @CALL __ex716_uee778e3b_static_45
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @JMP __ex716_uee778e3b_L107
:__ex716_uee778e3b_L104
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_1
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CALL __ex716_uee778e3b_static_32
:__ex716_uee778e3b_L105
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
:__ex716_uee778e3b_L107
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_9
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_2
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L104
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_4
   @PUSH 1
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L108
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_0
   @PUSH 32
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_107_local_11
   @CALL __ex716_uee778e3b_static_45
:__ex716_uee778e3b_L108
:__ex716_uee778e3b_L81

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G __ex716_vformat
@FUNCTION __ex716_vformat
:__ex716_vformat
@PUSHRETURN
@CLocals 154
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_off47 47
   @CLocalAt __ex716_off48 48
   @CLocalAt __ex716_off49 49
   @CLocalAt __ex716_off50 50
   @CLocalAt __ex716_off51 51
   @CLocalAt __ex716_off52 52
   @CLocalAt __ex716_off53 53
   @CLocalAt __ex716_off54 54
   @CLocalAt __ex716_off55 55
   @CLocalAt __ex716_off56 56
   @CLocalAt __ex716_off57 57
   @CLocalAt __ex716_off58 58
   @CLocalAt __ex716_off59 59
   @CLocalAt __ex716_off60 60
   @CLocalAt __ex716_off61 61
   @CLocalAt __ex716_off62 62
   @CLocalAt __ex716_off63 63
   @CLocalAt __ex716_off64 64
   @CLocalAt __ex716_off65 65
   @CLocalAt __ex716_off66 66
   @CLocalAt __ex716_off67 67
   @CLocalAt __ex716_off68 68
   @CLocalAt __ex716_off69 69
   @CLocalAt __ex716_off70 70
   @CLocalAt __ex716_off71 71
   @CLocalAt __ex716_off72 72
   @CLocalAt __ex716_off73 73
   @CLocalAt __ex716_off74 74
   @CLocalAt __ex716_off75 75
   @CLocalAt __ex716_off76 76
   @CLocalAt __ex716_off77 77
   @CLocalAt __ex716_off78 78
   @CLocalAt __ex716_off79 79
   @CLocalAt __ex716_off80 80
   @CLocalAt __ex716_off81 81
   @CLocalAt __ex716_off82 82
   @CLocalAt __ex716_off83 83
   @CLocalAt __ex716_off84 84
   @CLocalAt __ex716_off85 85
   @CLocalAt __ex716_off86 86
   @CLocalAt __ex716_off87 87
   @CLocalAt __ex716_off88 88
   @CLocalAt __ex716_off89 89
   @CLocalAt __ex716_off90 90
   @CLocalAt __ex716_off91 91
   @CLocalAt __ex716_off92 92
   @CLocalAt __ex716_off93 93
   @CLocalAt __ex716_off94 94
   @CLocalAt __ex716_off95 95
   @CLocalAt __ex716_off96 96
   @CLocalAt __ex716_off97 97
   @CLocalAt __ex716_off98 98
   @CLocalAt __ex716_off99 99
   @CLocalAt __ex716_off100 100
   @CLocalAt __ex716_off101 101
   @CLocalAt __ex716_off102 102
   @CLocalAt __ex716_off103 103
   @CLocalAt __ex716_off104 104
   @CLocalAt __ex716_off105 105
   @CLocalAt __ex716_off106 106
   @CLocalAt __ex716_off107 107
   @CLocalAt __ex716_off108 108
   @CLocalAt __ex716_off109 109
   @CLocalAt __ex716_off110 110
   @CLocalAt __ex716_off111 111
   @CLocalAt __ex716_off112 112
   @CLocalAt __ex716_off113 113
   @CLocalAt __ex716_off114 114
   @CLocalAt __ex716_off115 115
   @CLocalAt __ex716_off116 116
   @CLocalAt __ex716_off117 117
   @CLocalAt __ex716_off118 118
   @CLocalAt __ex716_off119 119
   @CLocalAt __ex716_off120 120
   @CLocalAt __ex716_off121 121
   @CLocalAt __ex716_off122 122
   @CLocalAt __ex716_off123 123
   @CLocalAt __ex716_off124 124
   @CLocalAt __ex716_off125 125
   @CLocalAt __ex716_off126 126
   @CLocalAt __ex716_off127 127
   @CLocalAt __ex716_off128 128
   @CLocalAt __ex716_off129 129
   @CLocalAt __ex716_off130 130
   @CLocalAt __ex716_off131 131
   @CLocalAt __ex716_off132 132
   @CLocalAt __ex716_off133 133
   @CLocalAt __ex716_off134 134
   @CLocalAt __ex716_off135 135
   @CLocalAt __ex716_off136 136
   @CLocalAt __ex716_off137 137
   @CLocalAt __ex716_off138 138
   @CLocalAt __ex716_off139 139
   @CLocalAt __ex716_off140 140
   @CLocalAt __ex716_off141 141
   @CLocalAt __ex716_off142 142
   @CLocalAt __ex716_off143 143
   @CLocalAt __ex716_off144 144
   @CLocalAt __ex716_off145 145
   @CLocalAt __ex716_off146 146
   @CLocalAt __ex716_off147 147
   @CLocalAt __ex716_off148 148
   @CLocalAt __ex716_off149 149
   @CLocalAt __ex716_off150 150
   @CLocalAt __ex716_off151 151
   @CLocalAt __ex716_off152 152
   @CLocalAt __ex716_off153 153
   @CLocalAt __ex716_off154 154
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_2 4
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_3 6
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_4 8
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_5 10
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_6 12
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_7 14
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_8 16
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_9 28
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_10 30
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_11 32
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_12 34
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_13 36
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_14 38
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_15 50
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_16 52
   @CLocal32At __ex716_uee778e3b___ex716_vformat_local_17 54
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_18 58
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_19 60
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_20 62
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_21 64
   @CLocal32At __ex716_uee778e3b___ex716_vformat_local_22 66
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_23 70
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_24 72
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_25 74
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_26 76
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_27 78
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_28 80
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_29 82
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_30 84
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_31 86
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_32 88
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_33 90
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_34 92
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_35 94
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_36 96
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_37 98
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_38 100
   @CLocal32At __ex716_uee778e3b___ex716_vformat_local_39 102
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_40 106
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_41 108
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_42 110
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_43 112
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_44 114
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_45 116
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_46 118
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_47 120
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_48 122
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_49 124
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_50 126
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_51 128
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_52 130
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_53 132
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_54 134
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_55 136
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_56 138
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_57 140
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_58 142
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_59 144
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_60 146
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_61 148
   @CLocalAt __ex716_uee778e3b___ex716_vformat_local_62 150
   @CLocalAt __ex716_pointer_tmp 152

   @CPOPI __ex716_uee778e3b___ex716_vformat_local_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_3
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_2
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_0

#USE SUB32U
#USE CMP32S
#USE CMP32U
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_5
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_8
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_1
   @CPOPI __ex716_off18
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_3
   @CPOPI __ex716_off20
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_2
   @CPOPI __ex716_off22
   @PUSH 0
   @CPOPI __ex716_off24
   @PUSH 0
   @CPOPI __ex716_off26
   @JMP __ex716_uee778e3b_L117
:__ex716_uee778e3b_L116
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 37
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L120
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_8
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_23
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_23
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_23
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @AND 0xff
   @CALL __ex716_uee778e3b_static_32
   @JMP __ex716_uee778e3b_L117
:__ex716_uee778e3b_L120
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 37
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L122
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_8
   @PUSH 37
   @CALL __ex716_uee778e3b_static_32
   @JMP __ex716_uee778e3b_L117
:__ex716_uee778e3b_L122
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_6
:__ex716_uee778e3b_L124
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 45
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L128
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 1
   @ORS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_6
   @JMP __ex716_uee778e3b_L129
:__ex716_uee778e3b_L128
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 43
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L130
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 2
   @ORS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_6
   @JMP __ex716_uee778e3b_L131
:__ex716_uee778e3b_L130
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 32
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L132
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 4
   @ORS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_6
   @JMP __ex716_uee778e3b_L133
:__ex716_uee778e3b_L132
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 48
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L134
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 8
   @ORS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_6
   @JMP __ex716_uee778e3b_L135
:__ex716_uee778e3b_L134
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 35
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L126
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 16
   @ORS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_6
:__ex716_uee778e3b_L137
:__ex716_uee778e3b_L135
:__ex716_uee778e3b_L133
:__ex716_uee778e3b_L131
:__ex716_uee778e3b_L129
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @JMP __ex716_uee778e3b_L124
:__ex716_uee778e3b_L126
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 42
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L138
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 2
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_24
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_24
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_10
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L139
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @DUP
   @SHRN 15
   @COMP2
   @PUSH32(A) $$$-32768
   @CALL CMP32S
   @IF32_NE
      @JMP __ex716_uee778e3b_L142
   @ENDIF
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L142
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 1
   @ORS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_6
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @COMP2
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_10
   @JMP __ex716_uee778e3b_L139
:__ex716_uee778e3b_L138
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_4
   @CALL __ex716_uee778e3b_static_95
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_25
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_25
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_10
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L145
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L145
:__ex716_uee778e3b_L139
   @PUSH -1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_7
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 46
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L147
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 42
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L149
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 2
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_26
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_26
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_7
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L150
   @PUSH -1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_7
   @JMP __ex716_uee778e3b_L150
:__ex716_uee778e3b_L149
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_4
   @CALL __ex716_uee778e3b_static_95
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_27
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_27
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_7
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L153
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L153
:__ex716_uee778e3b_L150
:__ex716_uee778e3b_L147
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_12
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 104
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L155
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_12
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 104
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L156
   @PUSH 2
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_12
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @JMP __ex716_uee778e3b_L156
:__ex716_uee778e3b_L155
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 108
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L159
   @PUSH 3
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_12
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 108
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L160
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L159
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_28
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_28
   @PUSH 122
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L165
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_28
   @PUSH 116
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L163
:__ex716_uee778e3b_L165
   @PUSH 4
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_12
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @JMP __ex716_uee778e3b_L164
:__ex716_uee778e3b_L163
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_29
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_29
   @PUSH 106
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L168
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_29
   @PUSH 76
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L166
:__ex716_uee778e3b_L168
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L166
:__ex716_uee778e3b_L164
:__ex716_uee778e3b_L160
:__ex716_uee778e3b_L156
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_30
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_30
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_4
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_30
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @AND 0xff
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_11
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_14
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_13
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_16
   @PUSH 0
   @CSTOREB __ex716_uee778e3b___ex716_vformat_local_15
   @PUSH 88
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_32
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_32
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L197
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_32
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uee778e3b_L249
:__ex716_uee778e3b_L248
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 65
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L144
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 71
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uee778e3b_L144
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @SHLN 1
   @PUSH __ex716_uee778e3b_static_252-130
   @ADDS
   @PUSHS
   @JMPS
::__ex716_uee778e3b_static_252 __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
:__ex716_uee778e3b_L249
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 97
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L144
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 120
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uee778e3b_L144
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @SHLN 1
   @PUSH __ex716_uee778e3b_static_255-194
   @ADDS
   @PUSHS
   @JMPS
::__ex716_uee778e3b_static_255 __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L234
::__ __ex716_uee778e3b_L171
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L171
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L197
::__ __ex716_uee778e3b_L231
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L237
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L197
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L144
::__ __ex716_uee778e3b_L197
:__ex716_uee778e3b_L171
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L172
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 4
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_35
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_35
   @DUP
   @PUSHS
   @SWP
   @ADD 2
   @PUSHS
   @CPOPI __ex716_off68
   @CPOPI __ex716_off66
   @CPUSHI __ex716_off66
   @CPUSHI __ex716_off68
   @PUSH32(A) $$$0
   @CALL CMP32S
   @IF32_GE
      @JMP __ex716_uee778e3b_L175
   @ENDIF
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_36
   @JMP __ex716_uee778e3b_L176
:__ex716_uee778e3b_L175
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_36
:__ex716_uee778e3b_L176
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_36
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_20
   @CPUSHI __ex716_off66
   @CPUSHI __ex716_off68
   @CPOPI __ex716_off56
   @CPOPI __ex716_off54
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_20
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L173
   @PUSH32(A) $$$0
   @CPUSHI __ex716_off54
   @CPUSHI __ex716_off56
   @CALL SUB32U
   @CPOPI __ex716_off56
   @CPOPI __ex716_off54
   @JMP __ex716_uee778e3b_L173
:__ex716_uee778e3b_L172
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 2
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_37
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_37
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_21
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L179
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_21
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_21
:__ex716_uee778e3b_L179
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 2
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L181
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_21
   @AND 0xff
   @CSIGNEXT8
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_21
:__ex716_uee778e3b_L181
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_21
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L184
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_38
   @JMP __ex716_uee778e3b_L185
:__ex716_uee778e3b_L184
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_38
:__ex716_uee778e3b_L185
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_38
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_20
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_21
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_18
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_20
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L187
   @PUSH 0
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_18
   @SUBS
   @PUSH 0
   @CPOPI __ex716_off104
   @CPOPI __ex716_off102
   @JMP __ex716_uee778e3b_L188
:__ex716_uee778e3b_L187
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_18
   @PUSH 0
   @CPOPI __ex716_off104
   @CPOPI __ex716_off102
:__ex716_uee778e3b_L188
   @CPUSHI __ex716_off102
   @CPUSHI __ex716_off104
   @CPOPI __ex716_off56
   @CPOPI __ex716_off54
:__ex716_uee778e3b_L173
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_20
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L189
   @PUSH 45
   @CSTOREB __ex716_uee778e3b___ex716_vformat_local_15
   @JMP __ex716_uee778e3b_L190
:__ex716_uee778e3b_L189
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 2
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L191
   @PUSH 43
   @CSTOREB __ex716_uee778e3b___ex716_vformat_local_15
   @JMP __ex716_uee778e3b_L192
:__ex716_uee778e3b_L191
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 4
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L193
   @PUSH 32
   @CSTOREB __ex716_uee778e3b___ex716_vformat_local_15
:__ex716_uee778e3b_L193
:__ex716_uee778e3b_L192
:__ex716_uee778e3b_L190
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_14
   @CPUSHI __ex716_off54
   @CPUSHI __ex716_off56
   @PUSH 10
   @PUSH 0
   @CALL __ex716_uee778e3b_static_51
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_40
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_40
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L195
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L195
   @CLOADB __ex716_uee778e3b___ex716_vformat_local_14
   @CSIGNEXT8
   @PUSH 48
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L195
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
:__ex716_uee778e3b_L195
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_8
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_13
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @PUSH 1
   @CLOADB __ex716_uee778e3b___ex716_vformat_local_15
   @CSIGNEXT8
   @PUSH 0
   @CALL __ex716_uee778e3b_static_107
   @JMP __ex716_uee778e3b_L170
:__ex716_uee778e3b_L197
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L198
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 4
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_41
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_41
   @DUP
   @PUSHS
   @SWP
   @ADD 2
   @PUSHS
   @CPOPI __ex716_off56
   @CPOPI __ex716_off54
   @JMP __ex716_uee778e3b_L199
:__ex716_uee778e3b_L198
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 2
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_42
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_42
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_18
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L200
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_18
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_18
:__ex716_uee778e3b_L200
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 2
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L202
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_18
   @AND 0xff
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_18
:__ex716_uee778e3b_L202
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_18
   @PUSH 0
   @CPOPI __ex716_off56
   @CPOPI __ex716_off54
:__ex716_uee778e3b_L199
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 111
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L206
   @PUSH 8
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_43
   @JMP __ex716_uee778e3b_L207
:__ex716_uee778e3b_L206
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 120
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L210
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 88
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L208
:__ex716_uee778e3b_L210
   @PUSH 16
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_44
   @JMP __ex716_uee778e3b_L209
:__ex716_uee778e3b_L208
   @PUSH 10
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_44
:__ex716_uee778e3b_L209
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_44
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_43
:__ex716_uee778e3b_L207
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_43
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_19
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_14
   @CPUSHI __ex716_off54
   @CPUSHI __ex716_off56
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_19
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 88
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L212
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_45
   @JMP __ex716_uee778e3b_L213
:__ex716_uee778e3b_L212
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_45
:__ex716_uee778e3b_L213
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_45
   @CALL __ex716_uee778e3b_static_51
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_47
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_47
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L214
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L214
   @CLOADB __ex716_uee778e3b___ex716_vformat_local_14
   @CSIGNEXT8
   @PUSH 48
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L214
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
:__ex716_uee778e3b_L214
   @PUSH 16
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_48
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_48
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L216
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_19
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_48
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L216
   @CPUSHI __ex716_off54
   @CPUSHI __ex716_off56
   @PUSH32(A) $$$0
   @CALL CMP32U
   @IF32_EQ
      @JMP __ex716_uee778e3b_L216
   @ENDIF
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_11
   @PUSH 88
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L221
   @PUSH __ex716_uee778e3b_static_224
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_49
   @JMP __ex716_uee778e3b_L222
:__ex716_uee778e3b_L221
   @PUSH __ex716_uee778e3b_static_225
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_49
:__ex716_uee778e3b_L222
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_49
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_16
   @JMP __ex716_uee778e3b_L217
:__ex716_uee778e3b_L216
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 16
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L223
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_19
   @PUSH 8
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L223
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L225
   @PUSH 48
   @CSTOREB __ex716_uee778e3b___ex716_vformat_local_14
   @PUSH 0
   @CSTOREB __ex716_off39
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
   @JMP __ex716_uee778e3b_L226
:__ex716_uee778e3b_L225
   @CLOADB __ex716_uee778e3b___ex716_vformat_local_14
   @CSIGNEXT8
   @PUSH 48
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L228
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uee778e3b_L228
   @PUSH __ex716_uee778e3b_static_234
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_16
:__ex716_uee778e3b_L228
:__ex716_uee778e3b_L226
:__ex716_uee778e3b_L223
:__ex716_uee778e3b_L217
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_8
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_13
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @PUSH 1
   @PUSH 0
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_16
   @CALL __ex716_uee778e3b_static_107
   @JMP __ex716_uee778e3b_L170
:__ex716_uee778e3b_L231
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L232
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L232
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 2
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_50
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_50
   @PUSHS
   @PUSH 0
   @CPOPI __ex716_off56
   @CPOPI __ex716_off54
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_14
   @CPUSHI __ex716_off54
   @CPUSHI __ex716_off56
   @PUSH 16
   @PUSH 0
   @CALL __ex716_uee778e3b_static_51
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_51
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_51
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_8
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_14
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @PUSH 1
   @PUSH 0
   @PUSH __ex716_uee778e3b_static_225
   @CALL __ex716_uee778e3b_static_107
   @JMP __ex716_uee778e3b_L170
:__ex716_uee778e3b_L234
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L235
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L235
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 2
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_52
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_52
   @PUSHS
   @PUSH 255
   @ANDS
   @AND 0xff
   @CSTOREB __ex716_uee778e3b___ex716_vformat_local_14
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_8
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_14
   @PUSH 1
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH -1
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_53
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_53
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_53
   @PUSH 0
   @CALL __ex716_uee778e3b_static_107
   @JMP __ex716_uee778e3b_L170
:__ex716_uee778e3b_L237
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_12
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L238
   @JMP __ex716_uee778e3b_L144
:__ex716_uee778e3b_L238
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_5
   @PUSH 2
   @CALL __ex716_uee778e3b_static_5
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_54
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_54
   @PUSHS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_13
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_13
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L240
   @PUSH __ex716_uee778e3b_static_242
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_13
:__ex716_uee778e3b_L240
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
   @JMP __ex716_uee778e3b_L244
:__ex716_uee778e3b_L243
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_9
:__ex716_uee778e3b_L244
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_56
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_13
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_56
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L246
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_56
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L243
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L243
:__ex716_uee778e3b_L246
   @CPUSHADDR __ex716_uee778e3b___ex716_vformat_local_8
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_13
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_9
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_10
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_6
   @PUSH 1
   @ANDS
   @PUSH -1
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_58
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_58
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_58
   @PUSH 0
   @CALL __ex716_uee778e3b_static_107
:__ex716_uee778e3b_L170
:__ex716_uee778e3b_L117
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_59
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_4
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_59
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L254
   @CPUSHI __ex716_off26
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_59
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L116
:__ex716_uee778e3b_L254
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L255
   @CPUSHI __ex716_off22
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L259
   @CPUSHI __ex716_off18
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L255
:__ex716_uee778e3b_L259
   @CPUSHI __ex716_off22
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L268
   @CPUSHI __ex716_off24
   @CPUSHI __ex716_off18
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uee778e3b_L266
:__ex716_uee778e3b_L268
   @CPUSHI __ex716_off24
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_60
   @JMP __ex716_uee778e3b_L267
:__ex716_uee778e3b_L266
   @CPUSHI __ex716_off18
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_60
:__ex716_uee778e3b_L267
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_60
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_8
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L255
   @CPUSHI __ex716_off26
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L272
   @PUSH -1
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_61
   @JMP __ex716_uee778e3b_L273
:__ex716_uee778e3b_L272
   @CPUSHI __ex716_off24
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_61
:__ex716_uee778e3b_L273
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_61
   @JMP __ex716_uee778e3b_L110
:__ex716_uee778e3b_L144
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L274
   @CPUSHI __ex716_off22
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L278
   @CPUSHI __ex716_off18
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L274
:__ex716_uee778e3b_L278
   @CPUSHI __ex716_off22
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L287
   @CPUSHI __ex716_off24
   @CPUSHI __ex716_off18
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uee778e3b_L285
:__ex716_uee778e3b_L287
   @CPUSHI __ex716_off24
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_62
   @JMP __ex716_uee778e3b_L286
:__ex716_uee778e3b_L285
   @CPUSHI __ex716_off18
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uee778e3b___ex716_vformat_local_62
:__ex716_uee778e3b_L286
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_62
   @CPUSHI __ex716_uee778e3b___ex716_vformat_local_8
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L274
   @PUSH -1
:__ex716_uee778e3b_L110

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G printf
@FUNCTION printf
:printf
@PUSHRETURN
@CLocals 12
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_uee778e3b_printf_local_0 0
   @CLocalAt __ex716_uee778e3b_printf_local_1 4
   @CLocalAt __ex716_uee778e3b_printf_local_2 8
   @CLocalAt __ex716_uee778e3b_printf_local_3 10

   @CPOPI __ex716_off2
   @CPOPI __ex716_uee778e3b_printf_local_0

   @CPUSHADDR __ex716_uee778e3b_printf_local_1
   @CPUSHI __ex716_off2
   @CALL __ex716_uee778e3b_static_0
   @PUSH 0
   @PUSH 0
   @PUSH 0
   @PUSH stdout
   @PUSHS
   @CPUSHI __ex716_uee778e3b_printf_local_0
   @CPUSHADDR __ex716_uee778e3b_printf_local_1
   @CALL __ex716_vformat
   @CPOPI __ex716_uee778e3b_printf_local_3
   @CPUSHI __ex716_uee778e3b_printf_local_3
   @CPOPI __ex716_uee778e3b_printf_local_2
   @CPUSHI __ex716_uee778e3b_printf_local_2
:__ex716_uee778e3b_L288

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G snprintf
@FUNCTION snprintf
:snprintf
@PUSHRETURN
@CLocals 16
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_uee778e3b_snprintf_local_0 0
   @CLocalAt __ex716_uee778e3b_snprintf_local_1 2
   @CLocalAt __ex716_uee778e3b_snprintf_local_2 4
   @CLocalAt __ex716_uee778e3b_snprintf_local_3 8
   @CLocalAt __ex716_uee778e3b_snprintf_local_4 12
   @CLocalAt __ex716_uee778e3b_snprintf_local_5 14

   @CPOPI __ex716_off6
   @CPOPI __ex716_uee778e3b_snprintf_local_2
   @CPOPI __ex716_uee778e3b_snprintf_local_1
   @CPOPI __ex716_uee778e3b_snprintf_local_0

   @CPUSHADDR __ex716_uee778e3b_snprintf_local_3
   @CPUSHI __ex716_off6
   @CALL __ex716_uee778e3b_static_0
   @CPUSHI __ex716_uee778e3b_snprintf_local_0
   @CPUSHI __ex716_uee778e3b_snprintf_local_1
   @PUSH 0
   @PUSH 0
   @CPUSHI __ex716_uee778e3b_snprintf_local_2
   @CPUSHADDR __ex716_uee778e3b_snprintf_local_3
   @CALL __ex716_vformat
   @CPOPI __ex716_uee778e3b_snprintf_local_5
   @CPUSHI __ex716_uee778e3b_snprintf_local_5
   @CPOPI __ex716_uee778e3b_snprintf_local_4
   @CPUSHI __ex716_uee778e3b_snprintf_local_4
:__ex716_uee778e3b_L290

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G vprintf
@FUNCTION vprintf
:vprintf
@PUSHRETURN
@CLocals 6
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_uee778e3b_vprintf_local_0 0
   @CLocalAt __ex716_uee778e3b_vprintf_local_1 2
   @CLocalAt __ex716_uee778e3b_vprintf_local_2 4

   @CPOPI __ex716_uee778e3b_vprintf_local_1
   @CPOPI __ex716_uee778e3b_vprintf_local_0

   @PUSH 0
   @PUSH 0
   @PUSH 0
   @PUSH stdout
   @PUSHS
   @CPUSHI __ex716_uee778e3b_vprintf_local_0
   @CPUSHI __ex716_uee778e3b_vprintf_local_1
   @CALL __ex716_vformat
   @CPOPI __ex716_uee778e3b_vprintf_local_2
   @CPUSHI __ex716_uee778e3b_vprintf_local_2
:__ex716_uee778e3b_L292

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G vfprintf
@FUNCTION vfprintf
:vfprintf
@PUSHRETURN
@CLocals 8
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_uee778e3b_vfprintf_local_0 0
   @CLocalAt __ex716_uee778e3b_vfprintf_local_1 2
   @CLocalAt __ex716_uee778e3b_vfprintf_local_2 4
   @CLocalAt __ex716_uee778e3b_vfprintf_local_3 6

   @CPOPI __ex716_uee778e3b_vfprintf_local_2
   @CPOPI __ex716_uee778e3b_vfprintf_local_1
   @CPOPI __ex716_uee778e3b_vfprintf_local_0

   @CPUSHI __ex716_uee778e3b_vfprintf_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L294
   @PUSH -1
   @JMP __ex716_uee778e3b_L293
:__ex716_uee778e3b_L294
   @PUSH 0
   @PUSH 0
   @PUSH 0
   @CPUSHI __ex716_uee778e3b_vfprintf_local_0
   @CPUSHI __ex716_uee778e3b_vfprintf_local_1
   @CPUSHI __ex716_uee778e3b_vfprintf_local_2
   @CALL __ex716_vformat
   @CPOPI __ex716_uee778e3b_vfprintf_local_3
   @CPUSHI __ex716_uee778e3b_vfprintf_local_3
:__ex716_uee778e3b_L293

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G vsprintf
@FUNCTION vsprintf
:vsprintf
@PUSHRETURN
@CLocals 8
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_uee778e3b_vsprintf_local_0 0
   @CLocalAt __ex716_uee778e3b_vsprintf_local_1 2
   @CLocalAt __ex716_uee778e3b_vsprintf_local_2 4
   @CLocalAt __ex716_uee778e3b_vsprintf_local_3 6

   @CPOPI __ex716_uee778e3b_vsprintf_local_2
   @CPOPI __ex716_uee778e3b_vsprintf_local_1
   @CPOPI __ex716_uee778e3b_vsprintf_local_0

   @CPUSHI __ex716_uee778e3b_vsprintf_local_0
   @PUSH 0
   @PUSH 1
   @PUSH 0
   @CPUSHI __ex716_uee778e3b_vsprintf_local_1
   @CPUSHI __ex716_uee778e3b_vsprintf_local_2
   @CALL __ex716_vformat
   @CPOPI __ex716_uee778e3b_vsprintf_local_3
   @CPUSHI __ex716_uee778e3b_vsprintf_local_3
:__ex716_uee778e3b_L296

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G vsnprintf
@FUNCTION vsnprintf
:vsnprintf
@PUSHRETURN
@CLocals 10
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_uee778e3b_vsnprintf_local_0 0
   @CLocalAt __ex716_uee778e3b_vsnprintf_local_1 2
   @CLocalAt __ex716_uee778e3b_vsnprintf_local_2 4
   @CLocalAt __ex716_uee778e3b_vsnprintf_local_3 6
   @CLocalAt __ex716_uee778e3b_vsnprintf_local_4 8

   @CPOPI __ex716_uee778e3b_vsnprintf_local_3
   @CPOPI __ex716_uee778e3b_vsnprintf_local_2
   @CPOPI __ex716_uee778e3b_vsnprintf_local_1
   @CPOPI __ex716_uee778e3b_vsnprintf_local_0

   @CPUSHI __ex716_uee778e3b_vsnprintf_local_0
   @CPUSHI __ex716_uee778e3b_vsnprintf_local_1
   @PUSH 0
   @PUSH 0
   @CPUSHI __ex716_uee778e3b_vsnprintf_local_2
   @CPUSHI __ex716_uee778e3b_vsnprintf_local_3
   @CALL __ex716_vformat
   @CPOPI __ex716_uee778e3b_vsnprintf_local_4
   @CPUSHI __ex716_uee778e3b_vsnprintf_local_4
:__ex716_uee778e3b_L297

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fprintf
@FUNCTION fprintf
:fprintf
@PUSHRETURN
@CLocals 14
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_uee778e3b_fprintf_local_0 0
   @CLocalAt __ex716_uee778e3b_fprintf_local_1 2
   @CLocalAt __ex716_uee778e3b_fprintf_local_2 6
   @CLocalAt __ex716_uee778e3b_fprintf_local_3 10
   @CLocalAt __ex716_uee778e3b_fprintf_local_4 12

   @CPOPI __ex716_off4
   @CPOPI __ex716_uee778e3b_fprintf_local_1
   @CPOPI __ex716_uee778e3b_fprintf_local_0

   @CPUSHADDR __ex716_uee778e3b_fprintf_local_2
   @CPUSHI __ex716_off4
   @CALL __ex716_uee778e3b_static_0
   @CPUSHI __ex716_uee778e3b_fprintf_local_0
   @CPUSHI __ex716_uee778e3b_fprintf_local_1
   @CPUSHADDR __ex716_uee778e3b_fprintf_local_2
   @CALL vfprintf
   @CPOPI __ex716_uee778e3b_fprintf_local_4
   @CPUSHI __ex716_uee778e3b_fprintf_local_4
   @CPOPI __ex716_uee778e3b_fprintf_local_3
   @CPUSHI __ex716_uee778e3b_fprintf_local_3
:__ex716_uee778e3b_L298

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G sprintf
@FUNCTION sprintf
:sprintf
@PUSHRETURN
@CLocals 14
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_uee778e3b_sprintf_local_0 0
   @CLocalAt __ex716_uee778e3b_sprintf_local_1 2
   @CLocalAt __ex716_uee778e3b_sprintf_local_2 6
   @CLocalAt __ex716_uee778e3b_sprintf_local_3 10
   @CLocalAt __ex716_uee778e3b_sprintf_local_4 12

   @CPOPI __ex716_off4
   @CPOPI __ex716_uee778e3b_sprintf_local_1
   @CPOPI __ex716_uee778e3b_sprintf_local_0

   @CPUSHADDR __ex716_uee778e3b_sprintf_local_2
   @CPUSHI __ex716_off4
   @CALL __ex716_uee778e3b_static_0
   @CPUSHI __ex716_uee778e3b_sprintf_local_0
   @CPUSHI __ex716_uee778e3b_sprintf_local_1
   @CPUSHADDR __ex716_uee778e3b_sprintf_local_2
   @CALL vsprintf
   @CPOPI __ex716_uee778e3b_sprintf_local_4
   @CPUSHI __ex716_uee778e3b_sprintf_local_4
   @CPOPI __ex716_uee778e3b_sprintf_local_3
   @CPUSHI __ex716_uee778e3b_sprintf_local_3
:__ex716_uee778e3b_L300

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uee778e3b_static_282 0
::__ 0
::__ 0
::__ -1
::__ $$0 * 8
::__ex716_uee778e3b_static_283 1
::__ 0
::__ 0
::__ -1
::__ $$0 * 8
::__ex716_uee778e3b_static_284 2
::__ 0
::__ 0
::__ -1
::__ $$0 * 8
G stdin
::stdin __ex716_uee778e3b_static_282
G stdout
::stdout __ex716_uee778e3b_static_283
G stderr
::stderr __ex716_uee778e3b_static_284
G getchar
@FUNCTION getchar
:getchar
@PUSHRETURN
@CLocals 2
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_uee778e3b_getchar_local_0 0

   @PUSH stdin
   @PUSHS
   @CALL fgetc
   @CPOPI __ex716_uee778e3b_getchar_local_0
   @CPUSHI __ex716_uee778e3b_getchar_local_0
:__ex716_uee778e3b_L302

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fgetc
@FUNCTION fgetc
:fgetc
@PUSHRETURN
@CLocals 20
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_uee778e3b_fgetc_local_0 0
   @CLocalAt __ex716_uee778e3b_fgetc_local_1 2
   @CLocalAt __ex716_uee778e3b_fgetc_local_2 4
   @CLocalAt __ex716_uee778e3b_fgetc_local_3 6
   @CLocalAt __ex716_uee778e3b_fgetc_local_4 8
   @CLocalAt __ex716_uee778e3b_fgetc_local_5 10
   @CLocalAt __ex716_uee778e3b_fgetc_local_6 12
   @CLocalAt __ex716_uee778e3b_fgetc_local_7 14
   @CLocalAt __ex716_uee778e3b_fgetc_local_8 16
   @CLocalAt __ex716_pointer_tmp 18

   @CPOPI __ex716_uee778e3b_fgetc_local_0

   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @CPOPI __ex716_uee778e3b_fgetc_local_0
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L307
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSHS
   @CPOPI __ex716_uee778e3b_fgetc_local_4
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fgetc_local_5
   @CPUSHI __ex716_uee778e3b_fgetc_local_4
   @CPUSHI __ex716_uee778e3b_fgetc_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L304
   @CPUSHI __ex716_uee778e3b_fgetc_local_4
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L307
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b_fgetc_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L304
:__ex716_uee778e3b_L307
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L308
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L308
   @PUSH -1
   @JMP __ex716_uee778e3b_L303
:__ex716_uee778e3b_L304
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 6
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L310
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 6
   @ADDS
   @CPOPI __ex716_uee778e3b_fgetc_local_6
   @CPUSHI __ex716_uee778e3b_fgetc_local_6
   @PUSHS
   @CPOPI __ex716_uee778e3b_fgetc_local_1
   @CPUSHI __ex716_uee778e3b_fgetc_local_6
   @CPOPI __ex716_pointer_tmp
   @PUSH -1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fgetc_local_1
   @JMP __ex716_uee778e3b_L303
:__ex716_uee778e3b_L310
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSHS
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L312
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 14
   @ADDS
   @PUSHS
   @CPUSHADDR __ex716_uee778e3b_fgetc_local_2
   @PUSH 1
   @CALL __EX716_DISK_READ
   @CPOPI __ex716_uee778e3b_fgetc_local_7
   @CPUSHI __ex716_uee778e3b_fgetc_local_7
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L314
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH -1
   @JMP __ex716_uee778e3b_L303
:__ex716_uee778e3b_L314
   @CLOADB __ex716_uee778e3b_fgetc_local_2
   @JMP __ex716_uee778e3b_L303
:__ex716_uee778e3b_L312
   @CALL __EX716_GETCHAR_RAW
   @CPOPI __ex716_uee778e3b_fgetc_local_8
   @CPUSHI __ex716_uee778e3b_fgetc_local_8
   @CPOPI __ex716_uee778e3b_fgetc_local_1
   @CPUSHI __ex716_uee778e3b_fgetc_local_1
   @PUSH -1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L316
   @PUSH __EX716_INPUT_STATUS
   @PUSHS
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L318
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @JMP __ex716_uee778e3b_L319
:__ex716_uee778e3b_L318
   @CPUSHI __ex716_uee778e3b_fgetc_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L319
   @PUSH -1
   @JMP __ex716_uee778e3b_L303
:__ex716_uee778e3b_L316
   @CPUSHI __ex716_uee778e3b_fgetc_local_1
   @PUSH 255
   @ANDS
:__ex716_uee778e3b_L303

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fputc
@FUNCTION fputc
:fputc
@PUSHRETURN
@CLocals 18
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_uee778e3b_fputc_local_0 0
   @CLocalAt __ex716_uee778e3b_fputc_local_1 2
   @CLocalAt __ex716_uee778e3b_fputc_local_2 4
   @CLocalAt __ex716_uee778e3b_fputc_local_3 6
   @CLocalAt __ex716_uee778e3b_fputc_local_4 8
   @CLocalAt __ex716_uee778e3b_fputc_local_5 10
   @CLocalAt __ex716_uee778e3b_fputc_local_6 12
   @CLocalAt __ex716_uee778e3b_fputc_local_7 14
   @CLocalAt __ex716_pointer_tmp 16

   @CPOPI __ex716_uee778e3b_fputc_local_1
   @CPOPI __ex716_uee778e3b_fputc_local_0

   @CPUSHI __ex716_uee778e3b_fputc_local_0
   @CPOPI __ex716_uee778e3b_fputc_local_0
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @CPOPI __ex716_uee778e3b_fputc_local_1
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L321
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSHS
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L321
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 10
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L323
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH -1
   @JMP __ex716_uee778e3b_L320
:__ex716_uee778e3b_L323
   @CPUSHI __ex716_uee778e3b_fputc_local_0
   @AND 0xff
   @CSTOREB __ex716_uee778e3b_fputc_local_2
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 12
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L325
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 14
   @ADDS
   @PUSHS
   @CALL __EX716_DISK_APPEND
   @POPNULL
:__ex716_uee778e3b_L325
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 14
   @ADDS
   @PUSHS
   @CPUSHADDR __ex716_uee778e3b_fputc_local_2
   @PUSH 1
   @CALL __EX716_DISK_WRITE
   @CPOPI __ex716_uee778e3b_fputc_local_4
   @CPUSHI __ex716_uee778e3b_fputc_local_4
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L327
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH -1
   @JMP __ex716_uee778e3b_L320
:__ex716_uee778e3b_L327
   @CLOADB __ex716_uee778e3b_fputc_local_2
   @JMP __ex716_uee778e3b_L320
:__ex716_uee778e3b_L321
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L331
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSHS
   @CPOPI __ex716_uee778e3b_fputc_local_6
   @CPUSHI __ex716_uee778e3b_fputc_local_6
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L329
   @CPUSHI __ex716_uee778e3b_fputc_local_6
   @PUSH 2
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L329
:__ex716_uee778e3b_L331
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L332
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L332
   @PUSH -1
   @JMP __ex716_uee778e3b_L320
:__ex716_uee778e3b_L329
   @CPUSHI __ex716_uee778e3b_fputc_local_0
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uee778e3b_fputc_local_0
   @CPUSHI __ex716_uee778e3b_fputc_local_0
   @CALL putchar
   @CPOPI __ex716_uee778e3b_fputc_local_7
   @CPUSHI __ex716_uee778e3b_fputc_local_7
   @PUSH -1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L334
   @CPUSHI __ex716_uee778e3b_fputc_local_1
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH -1
   @JMP __ex716_uee778e3b_L320
:__ex716_uee778e3b_L334
   @CPUSHI __ex716_uee778e3b_fputc_local_0
:__ex716_uee778e3b_L320

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G getc
@FUNCTION getc
:getc
@PUSHRETURN
@CLocals 4
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_uee778e3b_getc_local_0 0
   @CLocalAt __ex716_uee778e3b_getc_local_1 2

   @CPOPI __ex716_uee778e3b_getc_local_0

   @CPUSHI __ex716_uee778e3b_getc_local_0
   @CALL fgetc
   @CPOPI __ex716_uee778e3b_getc_local_1
   @CPUSHI __ex716_uee778e3b_getc_local_1
:__ex716_uee778e3b_L336

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G putc
@FUNCTION putc
:putc
@PUSHRETURN
@CLocals 6
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_uee778e3b_putc_local_0 0
   @CLocalAt __ex716_uee778e3b_putc_local_1 2
   @CLocalAt __ex716_uee778e3b_putc_local_2 4

   @CPOPI __ex716_uee778e3b_putc_local_1
   @CPOPI __ex716_uee778e3b_putc_local_0

   @CPUSHI __ex716_uee778e3b_putc_local_0
   @CPUSHI __ex716_uee778e3b_putc_local_1
   @CALL fputc
   @CPOPI __ex716_uee778e3b_putc_local_2
   @CPUSHI __ex716_uee778e3b_putc_local_2
:__ex716_uee778e3b_L337

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fputs
@FUNCTION fputs
:fputs
@PUSHRETURN
@CLocals 20
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_uee778e3b_fputs_local_0 0
   @CLocalAt __ex716_uee778e3b_fputs_local_1 2
   @CLocalAt __ex716_uee778e3b_fputs_local_2 4
   @CLocalAt __ex716_uee778e3b_fputs_local_3 6
   @CLocalAt __ex716_uee778e3b_fputs_local_4 8
   @CLocalAt __ex716_uee778e3b_fputs_local_5 10
   @CLocalAt __ex716_uee778e3b_fputs_local_6 12
   @CLocalAt __ex716_pointer_tmp 18

   @CPOPI __ex716_uee778e3b_fputs_local_1
   @CPOPI __ex716_uee778e3b_fputs_local_0

   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @CPOPI __ex716_uee778e3b_fputs_local_1
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fputs_local_3
   @CPUSHI __ex716_uee778e3b_fputs_local_0
   @CPUSHI __ex716_uee778e3b_fputs_local_3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L343
   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @CPUSHI __ex716_uee778e3b_fputs_local_3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L343
   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @PUSHS
   @CPOPI __ex716_uee778e3b_fputs_local_5
   @CPUSHI __ex716_uee778e3b_fputs_local_5
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L339
   @CPUSHI __ex716_uee778e3b_fputs_local_5
   @PUSH 2
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L339
   @CPUSHI __ex716_uee778e3b_fputs_local_5
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L343
   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @PUSH 10
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L339
:__ex716_uee778e3b_L343
   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L344
   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L344
   @PUSH -1
   @JMP __ex716_uee778e3b_L338
:__ex716_uee778e3b_L339
   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @PUSH __ex716_uee778e3b_static_317
   @CPUSHI __ex716_uee778e3b_fputs_local_0
   @CPOPI __ex716_off16
   @PUSH 2
   @CPOPI __ex716_off14
   @CPUSHADDR __ex716_off14
   @CALL fprintf
   @CPOPI __ex716_uee778e3b_fputs_local_6
   @CPUSHI __ex716_uee778e3b_fputs_local_6
   @CPOPI __ex716_uee778e3b_fputs_local_2
   @CPUSHI __ex716_uee778e3b_fputs_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uee778e3b_L347
   @CPUSHI __ex716_uee778e3b_fputs_local_1
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L347
   @CPUSHI __ex716_uee778e3b_fputs_local_2
:__ex716_uee778e3b_L338

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G puts
@FUNCTION puts
:puts
@PUSHRETURN
@CLocals 8
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_uee778e3b_puts_local_0 0
   @CLocalAt __ex716_uee778e3b_puts_local_1 2
   @CLocalAt __ex716_uee778e3b_puts_local_2 4
   @CLocalAt __ex716_uee778e3b_puts_local_3 6

   @CPOPI __ex716_uee778e3b_puts_local_0

   @CPUSHI __ex716_uee778e3b_puts_local_0
   @CPOPI __ex716_uee778e3b_puts_local_1
   @CPUSHI __ex716_uee778e3b_puts_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L353
   @CPUSHI __ex716_uee778e3b_puts_local_1
   @PUSH stdout
   @PUSHS
   @CALL fputs
   @CPOPI __ex716_uee778e3b_puts_local_2
   @CPUSHI __ex716_uee778e3b_puts_local_2
   @PUSH -1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L353
   @PUSH 10
   @PUSH stdout
   @PUSHS
   @CALL fputc
   @CPOPI __ex716_uee778e3b_puts_local_3
   @CPUSHI __ex716_uee778e3b_puts_local_3
   @PUSH -1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L350
:__ex716_uee778e3b_L353
   @PUSH -1
   @JMP __ex716_uee778e3b_L349
:__ex716_uee778e3b_L350
   @PUSH 0
:__ex716_uee778e3b_L349

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fgets
@FUNCTION fgets
:fgets
@PUSHRETURN
@CLocals 24
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_uee778e3b_fgets_local_0 0
   @CLocalAt __ex716_uee778e3b_fgets_local_1 2
   @CLocalAt __ex716_uee778e3b_fgets_local_2 4
   @CLocalAt __ex716_uee778e3b_fgets_local_3 6
   @CLocalAt __ex716_uee778e3b_fgets_local_4 8
   @CLocalAt __ex716_uee778e3b_fgets_local_5 10
   @CLocalAt __ex716_uee778e3b_fgets_local_6 12
   @CLocalAt __ex716_uee778e3b_fgets_local_7 14
   @CLocalAt __ex716_uee778e3b_fgets_local_8 16
   @CLocalAt __ex716_uee778e3b_fgets_local_9 18
   @CLocalAt __ex716_uee778e3b_fgets_local_10 20
   @CLocalAt __ex716_pointer_tmp 22

   @CPOPI __ex716_uee778e3b_fgets_local_2
   @CPOPI __ex716_uee778e3b_fgets_local_1
   @CPOPI __ex716_uee778e3b_fgets_local_0

   @CPUSHI __ex716_uee778e3b_fgets_local_0
   @CPOPI __ex716_uee778e3b_fgets_local_0
   @CPUSHI __ex716_uee778e3b_fgets_local_1
   @CPOPI __ex716_uee778e3b_fgets_local_1
   @CPUSHI __ex716_uee778e3b_fgets_local_2
   @CPOPI __ex716_uee778e3b_fgets_local_2
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fgets_local_5
   @CPUSHI __ex716_uee778e3b_fgets_local_0
   @CPUSHI __ex716_uee778e3b_fgets_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L360
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fgets_local_6
   @CPUSHI __ex716_uee778e3b_fgets_local_1
   @CPUSHI __ex716_uee778e3b_fgets_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uee778e3b_L360
   @CPUSHI __ex716_uee778e3b_fgets_local_2
   @CPUSHI __ex716_uee778e3b_fgets_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L360
   @CPUSHI __ex716_uee778e3b_fgets_local_2
   @PUSHS
   @CPOPI __ex716_uee778e3b_fgets_local_8
   @CPUSHI __ex716_uee778e3b_fgets_local_8
   @CPUSHI __ex716_uee778e3b_fgets_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L355
   @CPUSHI __ex716_uee778e3b_fgets_local_8
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L360
   @CPUSHI __ex716_uee778e3b_fgets_local_2
   @PUSH 8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b_fgets_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L355
:__ex716_uee778e3b_L360
   @CPUSHI __ex716_uee778e3b_fgets_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L361
   @CPUSHI __ex716_uee778e3b_fgets_local_2
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L361
   @PUSH 0
   @JMP __ex716_uee778e3b_L354
:__ex716_uee778e3b_L355
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fgets_local_4
   @JMP __ex716_uee778e3b_L364
:__ex716_uee778e3b_L363
   @CPUSHI __ex716_uee778e3b_fgets_local_2
   @CALL fgetc
   @CPOPI __ex716_uee778e3b_fgets_local_9
   @CPUSHI __ex716_uee778e3b_fgets_local_9
   @CPOPI __ex716_uee778e3b_fgets_local_3
   @CPUSHI __ex716_uee778e3b_fgets_local_3
   @PUSH -1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L366
   @CPUSHI __ex716_uee778e3b_fgets_local_4
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L365
   @PUSH 0
   @JMP __ex716_uee778e3b_L354
:__ex716_uee778e3b_L366
   @CPUSHI __ex716_uee778e3b_fgets_local_4
   @CPOPI __ex716_uee778e3b_fgets_local_10
   @CPUSHI __ex716_uee778e3b_fgets_local_10
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b_fgets_local_4
   @CPUSHI __ex716_uee778e3b_fgets_local_10
   @CPUSHI __ex716_uee778e3b_fgets_local_0
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_fgets_local_3
   @AND 0xff
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fgets_local_3
   @PUSH 10
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L370
   @JMP __ex716_uee778e3b_L365
:__ex716_uee778e3b_L370
:__ex716_uee778e3b_L364
   @CPUSHI __ex716_uee778e3b_fgets_local_4
   @CPUSHI __ex716_uee778e3b_fgets_local_1
   @PUSH 1
   @SUBS
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L363
:__ex716_uee778e3b_L365
   @CPUSHI __ex716_uee778e3b_fgets_local_4
   @CPUSHI __ex716_uee778e3b_fgets_local_0
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fgets_local_0
:__ex716_uee778e3b_L354

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G feof
@FUNCTION feof
:feof
@PUSHRETURN
@CLocals 4
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_uee778e3b_feof_local_0 0
   @CLocalAt __ex716_uee778e3b_feof_local_1 2

   @CPOPI __ex716_uee778e3b_feof_local_0

   @CPUSHI __ex716_uee778e3b_feof_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L374
   @CPUSHI __ex716_uee778e3b_feof_local_0
   @PUSH 2
   @ADDS
   @PUSHS
   @CPOPI __ex716_uee778e3b_feof_local_1
   @JMP __ex716_uee778e3b_L375
:__ex716_uee778e3b_L374
   @PUSH 0
   @CPOPI __ex716_uee778e3b_feof_local_1
:__ex716_uee778e3b_L375
   @CPUSHI __ex716_uee778e3b_feof_local_1
:__ex716_uee778e3b_L372

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G ferror
@FUNCTION ferror
:ferror
@PUSHRETURN
@CLocals 4
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_uee778e3b_ferror_local_0 0
   @CLocalAt __ex716_uee778e3b_ferror_local_1 2

   @CPOPI __ex716_uee778e3b_ferror_local_0

   @CPUSHI __ex716_uee778e3b_ferror_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L378
   @CPUSHI __ex716_uee778e3b_ferror_local_0
   @PUSH 4
   @ADDS
   @PUSHS
   @CPOPI __ex716_uee778e3b_ferror_local_1
   @JMP __ex716_uee778e3b_L379
:__ex716_uee778e3b_L378
   @PUSH 0
   @CPOPI __ex716_uee778e3b_ferror_local_1
:__ex716_uee778e3b_L379
   @CPUSHI __ex716_uee778e3b_ferror_local_1
:__ex716_uee778e3b_L376

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G clearerr
@FUNCTION clearerr
:clearerr
@PUSHRETURN
@CLocals 4
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_uee778e3b_clearerr_local_0 0
   @CLocalAt __ex716_pointer_tmp 2

   @CPOPI __ex716_uee778e3b_clearerr_local_0

   @CPUSHI __ex716_uee778e3b_clearerr_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L381
   @CPUSHI __ex716_uee778e3b_clearerr_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_clearerr_local_0
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L381
:__ex716_uee778e3b_L380

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G ungetc
@FUNCTION ungetc
:ungetc
@PUSHRETURN
@CLocals 12
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_uee778e3b_ungetc_local_0 0
   @CLocalAt __ex716_uee778e3b_ungetc_local_1 2
   @CLocalAt __ex716_uee778e3b_ungetc_local_2 4
   @CLocalAt __ex716_uee778e3b_ungetc_local_3 6
   @CLocalAt __ex716_uee778e3b_ungetc_local_4 8
   @CLocalAt __ex716_pointer_tmp 10

   @CPOPI __ex716_uee778e3b_ungetc_local_1
   @CPOPI __ex716_uee778e3b_ungetc_local_0

   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @CPOPI __ex716_uee778e3b_ungetc_local_1
   @CPUSHI __ex716_uee778e3b_ungetc_local_0
   @PUSH -1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L388
   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L388
   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @PUSHS
   @CPOPI __ex716_uee778e3b_ungetc_local_3
   @PUSH 0
   @CPOPI __ex716_uee778e3b_ungetc_local_4
   @CPUSHI __ex716_uee778e3b_ungetc_local_3
   @CPUSHI __ex716_uee778e3b_ungetc_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L389
   @CPUSHI __ex716_uee778e3b_ungetc_local_3
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L388
   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @PUSH 8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b_ungetc_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L388
:__ex716_uee778e3b_L389
   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @PUSH 6
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L384
:__ex716_uee778e3b_L388
   @PUSH -1
   @JMP __ex716_uee778e3b_L383
:__ex716_uee778e3b_L384
   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @PUSH 6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_ungetc_local_0
   @PUSH 255
   @ANDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_ungetc_local_1
   @PUSH 6
   @ADDS
   @PUSHS
:__ex716_uee778e3b_L383

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fflush
@FUNCTION fflush
:fflush
@PUSHRETURN
@CLocals 6
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_uee778e3b_fflush_local_0 0
   @CLocalAt __ex716_uee778e3b_fflush_local_1 2
   @CLocalAt __ex716_uee778e3b_fflush_local_2 4

   @CPOPI __ex716_uee778e3b_fflush_local_0

   @CPUSHI __ex716_uee778e3b_fflush_local_0
   @CPOPI __ex716_uee778e3b_fflush_local_0
   @CPUSHI __ex716_uee778e3b_fflush_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L395
   @CPUSHI __ex716_uee778e3b_fflush_local_0
   @PUSHS
   @CPOPI __ex716_uee778e3b_fflush_local_2
   @CPUSHI __ex716_uee778e3b_fflush_local_2
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L395
   @CPUSHI __ex716_uee778e3b_fflush_local_2
   @PUSH 2
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L395
   @CPUSHI __ex716_uee778e3b_fflush_local_2
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L391
:__ex716_uee778e3b_L395
   @PUSH 0
   @JMP __ex716_uee778e3b_L390
:__ex716_uee778e3b_L391
   @PUSH -1
:__ex716_uee778e3b_L390

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uee778e3b_static_355
:__ex716_uee778e3b_static_355
@PUSHRETURN
@CLocals 40
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0 0
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_1 2
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_2 4
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_3 6
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_4 8
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_5 10
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_6 12
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7 14
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_8 16
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_9 18
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_10 20
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_11 22
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_12 24
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_13 26
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_14 28
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_15 30
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_16 32
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_17 34
   @CLocalAt __ex716_uee778e3b___ex716_uee778e3b_static_355_local_18 36
   @CLocalAt __ex716_pointer_tmp 38

   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_5
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_4
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_3
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_2
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0

   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L400
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_10
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_10
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L400
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_10
   @PUSH 114
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L397
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_10
   @PUSH 119
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L397
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_10
   @PUSH 97
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L397
:__ex716_uee778e3b_L400
   @PUSH 0
   @JMP __ex716_uee778e3b_L396
:__ex716_uee778e3b_L397
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_11
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_11
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_11
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_8
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_6
   @JMP __ex716_uee778e3b_L404
:__ex716_uee778e3b_L401
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 43
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L405
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L405
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @JMP __ex716_uee778e3b_L406
:__ex716_uee778e3b_L405
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 98
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L407
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L407
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_8
   @JMP __ex716_uee778e3b_L408
:__ex716_uee778e3b_L407
   @PUSH 0
   @JMP __ex716_uee778e3b_L396
:__ex716_uee778e3b_L408
:__ex716_uee778e3b_L406
:__ex716_uee778e3b_L402
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_6
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_6
:__ex716_uee778e3b_L404
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_6
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @ADDS
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L401
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 97
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L410
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_12
   @JMP __ex716_uee778e3b_L411
:__ex716_uee778e3b_L410
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_12
:__ex716_uee778e3b_L411
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_4
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_12
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 119
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L413
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_13
   @JMP __ex716_uee778e3b_L414
:__ex716_uee778e3b_L413
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_13
:__ex716_uee778e3b_L414
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_5
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_13
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 114
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L418
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L416
:__ex716_uee778e3b_L418
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_14
   @JMP __ex716_uee778e3b_L417
:__ex716_uee778e3b_L416
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_14
:__ex716_uee778e3b_L417
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_2
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_14
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 114
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L422
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L420
:__ex716_uee778e3b_L422
   @PUSH 1
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_15
   @JMP __ex716_uee778e3b_L421
:__ex716_uee778e3b_L420
   @PUSH 0
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_15
:__ex716_uee778e3b_L421
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_3
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_15
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 114
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L423
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L426
   @PUSH 30578
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_16
   @JMP __ex716_uee778e3b_L427
:__ex716_uee778e3b_L426
   @PUSH 28530
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_16
:__ex716_uee778e3b_L427
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_1
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_16
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @JMP __ex716_uee778e3b_L424
:__ex716_uee778e3b_L423
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_0
   @PUSHS
   @AND 0xff
   @CSIGNEXT8
   @PUSH 119
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L428
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L431
   @PUSH 11105
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_17
   @JMP __ex716_uee778e3b_L432
:__ex716_uee778e3b_L431
   @PUSH 28535
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_17
:__ex716_uee778e3b_L432
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_1
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_17
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @JMP __ex716_uee778e3b_L429
:__ex716_uee778e3b_L428
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L434
   @PUSH 11105
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_18
   @JMP __ex716_uee778e3b_L435
:__ex716_uee778e3b_L434
   @PUSH 11127
   @CPOPI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_18
:__ex716_uee778e3b_L435
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_1
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b___ex716_uee778e3b_static_355_local_18
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L429
:__ex716_uee778e3b_L424
   @PUSH 1
:__ex716_uee778e3b_L396

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fopen
@FUNCTION fopen
:fopen
@PUSHRETURN
@CLocals 34
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_uee778e3b_fopen_local_0 0
   @CLocalAt __ex716_uee778e3b_fopen_local_1 2
   @CLocalAt __ex716_uee778e3b_fopen_local_2 4
   @CLocalAt __ex716_uee778e3b_fopen_local_3 6
   @CLocalAt __ex716_uee778e3b_fopen_local_4 8
   @CLocalAt __ex716_uee778e3b_fopen_local_5 10
   @CLocalAt __ex716_uee778e3b_fopen_local_6 12
   @CLocalAt __ex716_uee778e3b_fopen_local_7 14
   @CLocalAt __ex716_uee778e3b_fopen_local_8 16
   @CLocalAt __ex716_uee778e3b_fopen_local_9 18
   @CLocalAt __ex716_uee778e3b_fopen_local_10 20
   @CLocalAt __ex716_uee778e3b_fopen_local_11 22
   @CLocalAt __ex716_uee778e3b_fopen_local_12 24
   @CLocalAt __ex716_uee778e3b_fopen_local_13 26
   @CLocalAt __ex716_uee778e3b_fopen_local_14 28
   @CLocalAt __ex716_uee778e3b_fopen_local_15 30
   @CLocalAt __ex716_pointer_tmp 32

   @CPOPI __ex716_uee778e3b_fopen_local_1
   @CPOPI __ex716_uee778e3b_fopen_local_0

   @CPUSHI __ex716_uee778e3b_fopen_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L439
   @CPUSHI __ex716_uee778e3b_fopen_local_1
   @CPUSHADDR __ex716_uee778e3b_fopen_local_6
   @CPUSHADDR __ex716_uee778e3b_fopen_local_4
   @CPUSHADDR __ex716_uee778e3b_fopen_local_7
   @CPUSHADDR __ex716_uee778e3b_fopen_local_5
   @CPUSHADDR __ex716_uee778e3b_fopen_local_8
   @CALL __ex716_uee778e3b_static_355
   @CPOPI __ex716_uee778e3b_fopen_local_9
   @CPUSHI __ex716_uee778e3b_fopen_local_9
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L437
:__ex716_uee778e3b_L439
   @PUSH 0
   @JMP __ex716_uee778e3b_L436
:__ex716_uee778e3b_L437
   @PUSH __ex716_uee778e3b_static_285
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L440
   @CALL __EX716_DISK_INIT
   @CPOPI __ex716_uee778e3b_fopen_local_10
   @CPUSHI __ex716_uee778e3b_fopen_local_10
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L442
   @PUSH 0
   @JMP __ex716_uee778e3b_L436
:__ex716_uee778e3b_L442
   @PUSH __ex716_uee778e3b_static_285
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L440
   @CPUSHI __ex716_uee778e3b_fopen_local_0
   @CPUSHI __ex716_uee778e3b_fopen_local_6
   @CALL __EX716_DISK_OPEN
   @CPOPI __ex716_uee778e3b_fopen_local_11
   @CPUSHI __ex716_uee778e3b_fopen_local_11
   @CPOPI __ex716_uee778e3b_fopen_local_3
   @CPUSHI __ex716_uee778e3b_fopen_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L444
   @PUSH 0
   @JMP __ex716_uee778e3b_L436
:__ex716_uee778e3b_L444
   @CPUSHI __ex716_uee778e3b_fopen_local_8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L446
   @CPUSHI __ex716_uee778e3b_fopen_local_3
   @CALL __EX716_DISK_TRUNCATE
   @CPOPI __ex716_uee778e3b_fopen_local_12
   @CPUSHI __ex716_uee778e3b_fopen_local_12
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L447
   @CPUSHI __ex716_uee778e3b_fopen_local_3
   @CALL __EX716_DISK_CLOSE
   @POPNULL
   @PUSH 0
   @JMP __ex716_uee778e3b_L436
:__ex716_uee778e3b_L446
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fopen_local_13
   @CPUSHI __ex716_uee778e3b_fopen_local_5
   @CPUSHI __ex716_uee778e3b_fopen_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L450
   @CPUSHI __ex716_uee778e3b_fopen_local_4
   @CPUSHI __ex716_uee778e3b_fopen_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L450
   @CPUSHI __ex716_uee778e3b_fopen_local_3
   @CALL __EX716_DISK_REWIND
   @CPOPI __ex716_uee778e3b_fopen_local_14
   @CPUSHI __ex716_uee778e3b_fopen_local_14
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L452
   @CPUSHI __ex716_uee778e3b_fopen_local_3
   @CALL __EX716_DISK_CLOSE
   @POPNULL
   @PUSH 0
   @JMP __ex716_uee778e3b_L436
:__ex716_uee778e3b_L452
:__ex716_uee778e3b_L450
:__ex716_uee778e3b_L447
   @PUSH 16
   @CALL malloc
   @CPOPI __ex716_uee778e3b_fopen_local_15
   @CPUSHI __ex716_uee778e3b_fopen_local_15
   @CPOPI __ex716_uee778e3b_fopen_local_2
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L454
   @CPUSHI __ex716_uee778e3b_fopen_local_3
   @CALL __EX716_DISK_CLOSE
   @POPNULL
   @PUSH 0
   @JMP __ex716_uee778e3b_L436
:__ex716_uee778e3b_L454
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @CPOPI __ex716_pointer_tmp
   @PUSH 3
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH -1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 8
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_fopen_local_4
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 10
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_fopen_local_7
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 12
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_fopen_local_5
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
   @PUSH 14
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_fopen_local_3
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fopen_local_2
:__ex716_uee778e3b_L436

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fclose
@FUNCTION fclose
:fclose
@PUSHRETURN
@CLocals 12
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_uee778e3b_fclose_local_0 0
   @CLocalAt __ex716_uee778e3b_fclose_local_1 2
   @CLocalAt __ex716_uee778e3b_fclose_local_2 4
   @CLocalAt __ex716_uee778e3b_fclose_local_3 6
   @CLocalAt __ex716_uee778e3b_fclose_local_4 8
   @CLocalAt __ex716_pointer_tmp 10

   @CPOPI __ex716_uee778e3b_fclose_local_0

   @CPUSHI __ex716_uee778e3b_fclose_local_0
   @CPOPI __ex716_uee778e3b_fclose_local_0
   @CPUSHI __ex716_uee778e3b_fclose_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L459
   @CPUSHI __ex716_uee778e3b_fclose_local_0
   @PUSHS
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L457
:__ex716_uee778e3b_L459
   @PUSH -1
   @JMP __ex716_uee778e3b_L456
:__ex716_uee778e3b_L457
   @CPUSHI __ex716_uee778e3b_fclose_local_0
   @PUSH 14
   @ADDS
   @PUSHS
   @CALL __EX716_DISK_CLOSE
   @CPOPI __ex716_uee778e3b_fclose_local_3
   @CPUSHI __ex716_uee778e3b_fclose_local_3
   @CPOPI __ex716_uee778e3b_fclose_local_1
   @CPUSHI __ex716_uee778e3b_fclose_local_0
   @PUSH 14
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fclose_local_0
   @CALL free
   @CPUSHI __ex716_uee778e3b_fclose_local_1
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L461
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fclose_local_4
   @JMP __ex716_uee778e3b_L462
:__ex716_uee778e3b_L461
   @PUSH -1
   @CPOPI __ex716_uee778e3b_fclose_local_4
:__ex716_uee778e3b_L462
   @CPUSHI __ex716_uee778e3b_fclose_local_4
:__ex716_uee778e3b_L456

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fread
@FUNCTION fread
:fread
@PUSHRETURN
@CLocals 30
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_uee778e3b_fread_local_0 0
   @CLocalAt __ex716_uee778e3b_fread_local_1 2
   @CLocalAt __ex716_uee778e3b_fread_local_2 4
   @CLocalAt __ex716_uee778e3b_fread_local_3 6
   @CLocalAt __ex716_uee778e3b_fread_local_4 8
   @CLocalAt __ex716_uee778e3b_fread_local_5 10
   @CLocalAt __ex716_uee778e3b_fread_local_6 12
   @CLocalAt __ex716_uee778e3b_fread_local_7 14
   @CLocalAt __ex716_uee778e3b_fread_local_8 16
   @CLocalAt __ex716_uee778e3b_fread_local_9 18
   @CLocalAt __ex716_uee778e3b_fread_local_10 20
   @CLocalAt __ex716_uee778e3b_fread_local_11 22
   @CLocalAt __ex716_uee778e3b_fread_local_12 24
   @CLocalAt __ex716_uee778e3b_fread_local_13 26
   @CLocalAt __ex716_pointer_tmp 28

   @CPOPI __ex716_uee778e3b_fread_local_3
   @CPOPI __ex716_uee778e3b_fread_local_2
   @CPOPI __ex716_uee778e3b_fread_local_1
   @CPOPI __ex716_uee778e3b_fread_local_0

#USE MULU
#USE DIVU
   @CPUSHI __ex716_uee778e3b_fread_local_1
   @CPOPI __ex716_uee778e3b_fread_local_1
   @CPUSHI __ex716_uee778e3b_fread_local_2
   @CPOPI __ex716_uee778e3b_fread_local_2
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @CPOPI __ex716_uee778e3b_fread_local_3
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fread_local_7
   @CPUSHI __ex716_uee778e3b_fread_local_1
   @CPUSHI __ex716_uee778e3b_fread_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L466
   @CPUSHI __ex716_uee778e3b_fread_local_2
   @CPUSHI __ex716_uee778e3b_fread_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L464
:__ex716_uee778e3b_L466
   @PUSH 0
   @JMP __ex716_uee778e3b_L463
:__ex716_uee778e3b_L464
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fread_local_8
   @CPUSHI __ex716_uee778e3b_fread_local_0
   @CPUSHI __ex716_uee778e3b_fread_local_8
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L471
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @CPUSHI __ex716_uee778e3b_fread_local_8
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L471
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSHS
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L471
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 8
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L467
:__ex716_uee778e3b_L471
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L472
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L472
   @PUSH 0
   @JMP __ex716_uee778e3b_L463
:__ex716_uee778e3b_L467
   @CPUSHI __ex716_uee778e3b_fread_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L474
   @CPUSHI __ex716_uee778e3b_fread_local_1
   @PUSH -1
   @CPUSHI __ex716_uee778e3b_fread_local_2
   @CALL DIVU
   @SWP
   @POPNULL
   @CMPS
   @POPNULL
   @POPNULL
   @JULE __ex716_uee778e3b_L474
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 0
   @JMP __ex716_uee778e3b_L463
:__ex716_uee778e3b_L474
   @CPUSHI __ex716_uee778e3b_fread_local_1
   @CPUSHI __ex716_uee778e3b_fread_local_2
   @CALL MULU
   @CPOPI __ex716_uee778e3b_fread_local_5
   @CPUSHI __ex716_uee778e3b_fread_local_0
   @CPOPI __ex716_uee778e3b_fread_local_6
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fread_local_4
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 6
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uee778e3b_L476
   @CPUSHI __ex716_uee778e3b_fread_local_4
   @CPOPI __ex716_uee778e3b_fread_local_11
   @CPUSHI __ex716_uee778e3b_fread_local_11
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uee778e3b_fread_local_4
   @CPUSHI __ex716_uee778e3b_fread_local_11
   @CPUSHI __ex716_uee778e3b_fread_local_6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 6
   @ADDS
   @PUSHS
   @AND 0xff
   @AND 0xff
   @CPUSHI __ex716_pointer_tmp
   @PUSHS
   @AND 0xff00
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH -1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L476
   @CPUSHI __ex716_uee778e3b_fread_local_4
   @CPUSHI __ex716_uee778e3b_fread_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uee778e3b_L478
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 14
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b_fread_local_4
   @CPUSHI __ex716_uee778e3b_fread_local_6
   @ADDS
   @CPUSHI __ex716_uee778e3b_fread_local_5
   @CPUSHI __ex716_uee778e3b_fread_local_4
   @SUBS
   @CALL __EX716_DISK_READ
   @CPOPI __ex716_uee778e3b_fread_local_13
   @CPUSHI __ex716_uee778e3b_fread_local_4
   @CPUSHI __ex716_uee778e3b_fread_local_13
   @ADDS
   @CPOPI __ex716_uee778e3b_fread_local_4
:__ex716_uee778e3b_L478
   @CPUSHI __ex716_uee778e3b_fread_local_4
   @CPUSHI __ex716_uee778e3b_fread_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uee778e3b_L480
   @CPUSHI __ex716_uee778e3b_fread_local_3
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L480
   @CPUSHI __ex716_uee778e3b_fread_local_4
   @CPUSHI __ex716_uee778e3b_fread_local_1
   @CALL DIVU
   @SWP
   @POPNULL
:__ex716_uee778e3b_L463

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G fwrite
@FUNCTION fwrite
:fwrite
@PUSHRETURN
@CLocals 24
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_uee778e3b_fwrite_local_0 0
   @CLocalAt __ex716_uee778e3b_fwrite_local_1 2
   @CLocalAt __ex716_uee778e3b_fwrite_local_2 4
   @CLocalAt __ex716_uee778e3b_fwrite_local_3 6
   @CLocalAt __ex716_uee778e3b_fwrite_local_4 8
   @CLocalAt __ex716_uee778e3b_fwrite_local_5 10
   @CLocalAt __ex716_uee778e3b_fwrite_local_6 12
   @CLocalAt __ex716_uee778e3b_fwrite_local_7 14
   @CLocalAt __ex716_uee778e3b_fwrite_local_8 16
   @CLocalAt __ex716_uee778e3b_fwrite_local_9 18
   @CLocalAt __ex716_uee778e3b_fwrite_local_10 20
   @CLocalAt __ex716_pointer_tmp 22

   @CPOPI __ex716_uee778e3b_fwrite_local_3
   @CPOPI __ex716_uee778e3b_fwrite_local_2
   @CPOPI __ex716_uee778e3b_fwrite_local_1
   @CPOPI __ex716_uee778e3b_fwrite_local_0

#USE MULU
#USE DIVU
   @CPUSHI __ex716_uee778e3b_fwrite_local_1
   @CPOPI __ex716_uee778e3b_fwrite_local_1
   @CPUSHI __ex716_uee778e3b_fwrite_local_2
   @CPOPI __ex716_uee778e3b_fwrite_local_2
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @CPOPI __ex716_uee778e3b_fwrite_local_3
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fwrite_local_6
   @CPUSHI __ex716_uee778e3b_fwrite_local_1
   @CPUSHI __ex716_uee778e3b_fwrite_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L485
   @CPUSHI __ex716_uee778e3b_fwrite_local_2
   @CPUSHI __ex716_uee778e3b_fwrite_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L483
:__ex716_uee778e3b_L485
   @PUSH 0
   @JMP __ex716_uee778e3b_L482
:__ex716_uee778e3b_L483
   @PUSH 0
   @CPOPI __ex716_uee778e3b_fwrite_local_7
   @CPUSHI __ex716_uee778e3b_fwrite_local_0
   @CPUSHI __ex716_uee778e3b_fwrite_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L490
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @CPUSHI __ex716_uee778e3b_fwrite_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L490
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSHS
   @PUSH 3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L490
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 10
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uee778e3b_L486
:__ex716_uee778e3b_L490
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L491
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L491
   @PUSH 0
   @JMP __ex716_uee778e3b_L482
:__ex716_uee778e3b_L486
   @CPUSHI __ex716_uee778e3b_fwrite_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L493
   @CPUSHI __ex716_uee778e3b_fwrite_local_1
   @PUSH -1
   @CPUSHI __ex716_uee778e3b_fwrite_local_2
   @CALL DIVU
   @SWP
   @POPNULL
   @CMPS
   @POPNULL
   @POPNULL
   @JULE __ex716_uee778e3b_L493
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 0
   @JMP __ex716_uee778e3b_L482
:__ex716_uee778e3b_L493
   @CPUSHI __ex716_uee778e3b_fwrite_local_1
   @CPUSHI __ex716_uee778e3b_fwrite_local_2
   @CALL MULU
   @CPOPI __ex716_uee778e3b_fwrite_local_4
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 12
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uee778e3b_L495
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 14
   @ADDS
   @PUSHS
   @CALL __EX716_DISK_APPEND
   @POPNULL
:__ex716_uee778e3b_L495
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 14
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uee778e3b_fwrite_local_0
   @CPUSHI __ex716_uee778e3b_fwrite_local_4
   @CALL __EX716_DISK_WRITE
   @CPOPI __ex716_uee778e3b_fwrite_local_10
   @CPUSHI __ex716_uee778e3b_fwrite_local_10
   @CPOPI __ex716_uee778e3b_fwrite_local_5
   @CPUSHI __ex716_uee778e3b_fwrite_local_5
   @CPUSHI __ex716_uee778e3b_fwrite_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uee778e3b_L497
   @CPUSHI __ex716_uee778e3b_fwrite_local_3
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uee778e3b_L497
   @CPUSHI __ex716_uee778e3b_fwrite_local_5
   @CPUSHI __ex716_uee778e3b_fwrite_local_1
   @CALL DIVU
   @SWP
   @POPNULL
:__ex716_uee778e3b_L482

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G __EX716_GETCHAR_RAW
::__ex716_uee778e3b_static_285 $$0 * 2
G __EX716_DISK_APPEND
G __EX716_DISK_REWIND
G __EX716_DISK_TRUNCATE
G __EX716_DISK_WRITE
G __EX716_DISK_READ
G __EX716_DISK_CLOSE
G __EX716_DISK_OPEN
G __EX716_DISK_INIT
G __EX716_INPUT_STATUS
G __EX716_TTY_NOECHO
G __EX716_TTY_ECHO
G __EX716_TTY_COOKED
G __EX716_TTY_RAW
G strtol
G exit
G free
G malloc
G putchar
::__ex716_uee778e3b_static_317 $$37
::__ $$115
::__ $$0
::__ex716_uee778e3b_static_242 $$40
::__ $$110
::__ $$117
::__ $$108
::__ $$108
::__ $$41
::__ $$0
::__ex716_uee778e3b_static_234 $$48
::__ $$0
::__ex716_uee778e3b_static_225 $$48
::__ $$120
::__ $$0
::__ex716_uee778e3b_static_224 $$48
::__ $$88
::__ $$0

::__ex716_uece6cc12_static_0 512
::__ 2
@FUNCTION __ex716_uece6cc12_static_2
:__ex716_uece6cc12_static_2
@PUSHRETURN
@CLocals 4
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_2_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_2_local_1 2

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_0

   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L2
   @PUSH 0
   @JMP __ex716_uece6cc12_L1
:__ex716_uece6cc12_L2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_1
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_1
   @JMP __ex716_uece6cc12_L1
:__ex716_uece6cc12_L4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_2_local_0
:__ex716_uece6cc12_L1

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uece6cc12_static_8
:__ex716_uece6cc12_static_8
@PUSHRETURN
@CLocals 30
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_1 2
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_3 6
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4 8
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5 10
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6 12
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_7 14
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_8 16
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_9 18
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_10 20
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_11 22
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_12 24
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_8_local_13 26
   @CLocalAt __ex716_pointer_tmp 28

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_3
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_0

#USE SHL16_BY_N
#USE SHR16_BY_N
#USE MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_3
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @PUSH 7
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @JMP __ex716_uece6cc12_L10
:__ex716_uece6cc12_L7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L13
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L11
:__ex716_uece6cc12_L13
   @JMP __ex716_uece6cc12_L8
:__ex716_uece6cc12_L11
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_1
   @PUSH 7
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @JMP __ex716_uece6cc12_L17
:__ex716_uece6cc12_L14
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L20
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L18
:__ex716_uece6cc12_L20
   @JMP __ex716_uece6cc12_L15
:__ex716_uece6cc12_L18
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_1
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L21
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @COMP2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
:__ex716_uece6cc12_L21
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @SUBS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L23
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @SUBS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @JMP __ex716_uece6cc12_L24
:__ex716_uece6cc12_L23
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @SUBS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
:__ex716_uece6cc12_L24
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @SHLN 4
   @CMPS
   @POPNULL
   @POPNULL
   @JUGT __ex716_uece6cc12_L25
   @JMP __ex716_uece6cc12_L15
:__ex716_uece6cc12_L25
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_5
   @SHLN 4
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_7
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_8
   @PUSH 255
   @ANDS
   @CMPS
   @POPNULL
   @POPNULL
   @JULE __ex716_uece6cc12_L27
   @PUSH 8
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_12
   @PUSH 255
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_13
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_12
   @AND 0x7fff
   @CALL SHR16_BY_N
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_13
   @ANDS
   @PUSH 65520
   @ANDS
   @PUSH 3
   @ORS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_9
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_9
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_13
   @ANDS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_12
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_13
   @ANDS
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L27
:__ex716_uece6cc12_L15
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
:__ex716_uece6cc12_L17
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_1
   @PUSH 7
   @ADDS
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L14
:__ex716_uece6cc12_L8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
:__ex716_uece6cc12_L10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_8_local_2
   @PUSH 7
   @ADDS
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L7
:__ex716_uece6cc12_L6

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uece6cc12_static_35
:__ex716_uece6cc12_static_35
@PUSHRETURN
@CLocals 46
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1 2
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_3 6
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_4 8
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_5 10
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_6 12
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_7 14
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8 16
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9 18
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_10 20
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_11 22
   @CLocal32At __ex716_uece6cc12___ex716_uece6cc12_static_35_local_12 24
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_13 28
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_14 30
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_15 32
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_16 34
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_17 36
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_18 38
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_19 40
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_20 42
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_35_local_21 44

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_6
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_5
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_4
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_3
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_0

#USE ADD32S
#USE MUL32S
#USE DIV32S
#USE DIV32S_Q
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_3
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_4
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_5
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_6
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L30
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @COMP2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
:__ex716_uece6cc12_L30
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L32
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @COMP2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
:__ex716_uece6cc12_L32
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L35
   @PUSH 1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_16
   @JMP __ex716_uece6cc12_L36
:__ex716_uece6cc12_L35
   @PUSH -1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_16
:__ex716_uece6cc12_L36
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_16
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_14
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L38
   @PUSH 1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_17
   @JMP __ex716_uece6cc12_L39
:__ex716_uece6cc12_L38
   @PUSH -1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_17
:__ex716_uece6cc12_L39
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_17
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_15
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L41
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_18
   @JMP __ex716_uece6cc12_L42
:__ex716_uece6cc12_L41
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_18
:__ex716_uece6cc12_L42
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_18
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_13
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_13
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L43
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_3
   @CALL __ex716_uece6cc12_static_8
   @JMP __ex716_uece6cc12_L29
:__ex716_uece6cc12_L43
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_11
:__ex716_uece6cc12_L45
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_3
   @PUSH 0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_3
   @SUBS
   @DUP
   @SHRN 15
   @COMP2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_11
   @DUP
   @SHRN 15
   @COMP2
   @CALL MUL32S
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_13
   @DUP
   @SHRN 15
   @COMP2
   @CALL DIV32S_Q
   @CALL ADD32S
   @CPOPI __ex716_off26
   @CPOPI __ex716_off24
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPUSHI __ex716_off24
   @CPUSHI __ex716_off26
   @POPNULL
   @CALL __ex716_uece6cc12_static_8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L49
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L49
   @JMP __ex716_uece6cc12_L47
:__ex716_uece6cc12_L49
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_10
   @SHLN 1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @COMP2
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L51
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_9
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_14
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_1
:__ex716_uece6cc12_L51
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L53
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_8
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_15
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_2
:__ex716_uece6cc12_L53
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_11
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_35_local_11
   @JMP __ex716_uece6cc12_L45
:__ex716_uece6cc12_L47
:__ex716_uece6cc12_L29

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapInitialize
@FUNCTION MapInitialize
:MapInitialize
@PUSHRETURN
@CLocals 14
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_uece6cc12_MapInitialize_local_0 0
   @CLocal32At __ex716_uece6cc12_MapInitialize_local_1 2
   @CLocalAt __ex716_uece6cc12_MapInitialize_local_2 6
   @CLocalAt __ex716_uece6cc12_MapInitialize_local_3 8
   @CLocalAt __ex716_uece6cc12_MapInitialize_local_4 10
   @CLocalAt __ex716_pointer_tmp 12

   @CPOPI __ex716_uece6cc12_MapInitialize_local_2
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPOPI __ex716_uece6cc12_MapInitialize_local_0

   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @CPOPI __ex716_uece6cc12_MapInitialize_local_0
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L56
   @PUSH 0
   @JMP __ex716_uece6cc12_L55
:__ex716_uece6cc12_L56
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @CPOPI __ex716_pointer_tmp
   @PUSH 7
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 7
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_2
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 2
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 8
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_pointer_tmp
   @ADD 2
   @POPS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 12
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 8
   @ADDS
   @DUP
   @PUSHS
   @SWP
   @ADD 2
   @PUSHS
   @POPNULL
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 12
   @ADDS
   @PUSHS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L58
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 12
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 44257
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L58
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapInitialize_local_3
   @JMP __ex716_uece6cc12_L63
:__ex716_uece6cc12_L60
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_3
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L61
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapInitialize_local_3
:__ex716_uece6cc12_L63
   @CPUSHI __ex716_uece6cc12_MapInitialize_local_3
   @PUSH 49
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L60
   @PUSH 1
:__ex716_uece6cc12_L55

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapSetCell
@FUNCTION MapSetCell
:MapSetCell
@PUSHRETURN
@CLocals 12
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_uece6cc12_MapSetCell_local_0 0
   @CLocalAt __ex716_uece6cc12_MapSetCell_local_1 2
   @CLocalAt __ex716_uece6cc12_MapSetCell_local_2 4
   @CLocalAt __ex716_uece6cc12_MapSetCell_local_3 6
   @CLocalAt __ex716_uece6cc12_MapSetCell_local_4 8
   @CLocalAt __ex716_pointer_tmp 10

   @CPOPI __ex716_uece6cc12_MapSetCell_local_3
   @CPOPI __ex716_uece6cc12_MapSetCell_local_2
   @CPOPI __ex716_uece6cc12_MapSetCell_local_1
   @CPOPI __ex716_uece6cc12_MapSetCell_local_0

#USE MULU
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L68
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapSetCell_local_4
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_1
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uece6cc12_L68
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_2
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L65
:__ex716_uece6cc12_L68
   @PUSH 0
   @JMP __ex716_uece6cc12_L64
:__ex716_uece6cc12_L65
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_2
   @CALL MULU
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_1
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapSetCell_local_3
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 1
:__ex716_uece6cc12_L64

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapGetCell
@FUNCTION MapGetCell
:MapGetCell
@PUSHRETURN
@CLocals 14
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_uece6cc12_MapGetCell_local_0 0
   @CLocalAt __ex716_uece6cc12_MapGetCell_local_1 2
   @CLocalAt __ex716_uece6cc12_MapGetCell_local_2 4
   @CLocalAt __ex716_uece6cc12_MapGetCell_local_3 6
   @CLocalAt __ex716_uece6cc12_MapGetCell_local_4 8
   @CLocalAt __ex716_uece6cc12_MapGetCell_local_5 10
   @CLocalAt __ex716_pointer_tmp 12

   @CPOPI __ex716_uece6cc12_MapGetCell_local_3
   @CPOPI __ex716_uece6cc12_MapGetCell_local_2
   @CPOPI __ex716_uece6cc12_MapGetCell_local_1
   @CPOPI __ex716_uece6cc12_MapGetCell_local_0

#USE MULU
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapGetCell_local_4
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_0
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L74
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_3
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L74
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapGetCell_local_5
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_1
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uece6cc12_L74
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_2
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L70
:__ex716_uece6cc12_L74
   @PUSH 0
   @JMP __ex716_uece6cc12_L69
:__ex716_uece6cc12_L70
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_3
   @CPOPI __ex716_pointer_tmp
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_2
   @CALL MULU
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_1
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapGetCell_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 1
:__ex716_uece6cc12_L69

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapRandom
@FUNCTION MapRandom
:MapRandom
@PUSHRETURN
@CLocals 14
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_uece6cc12_MapRandom_local_0 0
   @CLocalAt __ex716_uece6cc12_MapRandom_local_1 2
   @CLocalAt __ex716_uece6cc12_MapRandom_local_2 4
   @CLocalAt __ex716_uece6cc12_MapRandom_local_3 6
   @CLocalAt __ex716_uece6cc12_MapRandom_local_4 8
   @CLocalAt __ex716_uece6cc12_MapRandom_local_5 10
   @CLocalAt __ex716_pointer_tmp 12

   @CPOPI __ex716_uece6cc12_MapRandom_local_0

   @CPUSHI __ex716_uece6cc12_MapRandom_local_0
   @CPOPI __ex716_uece6cc12_MapRandom_local_0
   @CPUSHI __ex716_uece6cc12_MapRandom_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L76
   @PUSH32(A) $$$0
   @JMP __ex716_uece6cc12_L75
:__ex716_uece6cc12_L76
   @CPUSHI __ex716_uece6cc12_MapRandom_local_0
   @PUSH 12
   @ADDS
   @CPOPI __ex716_uece6cc12_MapRandom_local_2
   @CPUSHI __ex716_uece6cc12_MapRandom_local_2
   @PUSHS
   @CPOPI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @SHLN 7
   @XORS
   @CPOPI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @SHRN 9
   @XORS
   @CPOPI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @SHLN 8
   @XORS
   @CPOPI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_uece6cc12_MapRandom_local_2
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapRandom_local_1
   @PUSH 0
:__ex716_uece6cc12_L75

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapRandomBelow
@FUNCTION MapRandomBelow
:MapRandomBelow
@PUSHRETURN
@CLocals 8
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_uece6cc12_MapRandomBelow_local_0 0
   @CLocalAt __ex716_uece6cc12_MapRandomBelow_local_1 2
   @CLocal32At __ex716_uece6cc12_MapRandomBelow_local_2 4

   @CPOPI __ex716_uece6cc12_MapRandomBelow_local_1
   @CPOPI __ex716_uece6cc12_MapRandomBelow_local_0

#USE DIV32U
#USE DIV32U_Q
   @CPUSHI __ex716_uece6cc12_MapRandomBelow_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L79
   @PUSH 0
   @JMP __ex716_uece6cc12_L78
:__ex716_uece6cc12_L79
   @CPUSHI __ex716_uece6cc12_MapRandomBelow_local_0
   @CALL MapRandom
   @CPOPI __ex716_off6
   @CPOPI __ex716_off4
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_off6
   @CPUSHI __ex716_uece6cc12_MapRandomBelow_local_1
   @PUSH 0
   @CALL DIV32U
   @POPNULL
   @POPNULL
   @POPNULL
:__ex716_uece6cc12_L78

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapSmooth
@FUNCTION MapSmooth
:MapSmooth
@PUSHRETURN
@CLocals 54
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_off47 47
   @CLocalAt __ex716_off48 48
   @CLocalAt __ex716_off49 49
   @CLocalAt __ex716_off50 50
   @CLocalAt __ex716_off51 51
   @CLocalAt __ex716_off52 52
   @CLocalAt __ex716_off53 53
   @CLocalAt __ex716_off54 54
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_0 0
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_1 2
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_2 4
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_3 6
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_4 8
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_5 10
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_6 12
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_7 14
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_8 18
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_9 20
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_10 22
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_11 24
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_12 26
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_13 28
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_14 30
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_15 32
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_16 34
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_17 36
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_18 38
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_19 40
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_20 42
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_21 44
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_22 46
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_23 48
   @CLocalAt __ex716_uece6cc12_MapSmooth_local_24 50
   @CLocalAt __ex716_pointer_tmp 52

   @CPOPI __ex716_uece6cc12_MapSmooth_local_1
   @CPOPI __ex716_uece6cc12_MapSmooth_local_0

#USE SHL16_BY_N
#USE SHR16_BY_N
#USE MUL
#USE MULU
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @CPOPI __ex716_uece6cc12_MapSmooth_local_0
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_1
   @CPOPI __ex716_uece6cc12_MapSmooth_local_1
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L84
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L82
:__ex716_uece6cc12_L84
   @PUSH 0
   @JMP __ex716_uece6cc12_L81
:__ex716_uece6cc12_L82
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapSmooth_local_8
   @JMP __ex716_uece6cc12_L88
:__ex716_uece6cc12_L85
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapSmooth_local_3
:__ex716_uece6cc12_L89
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapSmooth_local_2
:__ex716_uece6cc12_L93
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapSmooth_local_13
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_13
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_6
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_6
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_5
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_5
   @PUSH 255
   @ANDS
   @SHLN 2
   @CPOPI __ex716_uece6cc12_MapSmooth_local_4
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L98
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_9
   @JMP __ex716_uece6cc12_L99
:__ex716_uece6cc12_L98
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CPOPI __ex716_uece6cc12_MapSmooth_local_9
:__ex716_uece6cc12_L99
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapSmooth_local_15
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_4
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_13
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_9
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_15
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 255
   @ANDS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_4
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapSmooth_local_16
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_15
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_16
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L101
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_10
   @JMP __ex716_uece6cc12_L102
:__ex716_uece6cc12_L101
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CPOPI __ex716_uece6cc12_MapSmooth_local_10
:__ex716_uece6cc12_L102
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_4
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_16
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_10
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 255
   @ANDS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_4
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L104
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_11
   @JMP __ex716_uece6cc12_L105
:__ex716_uece6cc12_L104
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @CPOPI __ex716_uece6cc12_MapSmooth_local_11
:__ex716_uece6cc12_L105
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapSmooth_local_18
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_4
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_11
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_18
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 255
   @ANDS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_4
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapSmooth_local_19
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_18
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_19
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L107
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_12
   @JMP __ex716_uece6cc12_L108
:__ex716_uece6cc12_L107
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @CPOPI __ex716_uece6cc12_MapSmooth_local_12
:__ex716_uece6cc12_L108
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapSmooth_local_20
   @PUSH 255
   @CPOPI __ex716_uece6cc12_MapSmooth_local_21
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_4
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_19
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_12
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_20
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_21
   @ANDS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_4
   @PUSH 8
   @CPOPI __ex716_uece6cc12_MapSmooth_local_22
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_20
   @AND 0x7fff
   @CALL SHL16_BY_N
   @PUSH __ex716_uece6cc12_static_1
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_5
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_22
   @AND 0x7fff
   @CALL SHR16_BY_N
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_21
   @ANDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_21
   @ANDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_22
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_4
   @SHRN 3
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_21
   @ANDS
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L94
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_2
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L93
   @PUSH __ex716_uece6cc12_static_0
   @PUSHS
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CALL MULU
   @SHLN 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_7
   @PUSH __ex716_uece6cc12_static_0+2
   @PUSHS
   @CPOPI __ex716_off16
   @CPUSHADDR __ex716_uece6cc12_MapSmooth_local_7
   @PUSH __ex716_uece6cc12_static_1
   @PUSH 7
   @CALL ex716_far_put16v
:__ex716_uece6cc12_L90
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_3
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L89
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapSmooth_local_3
:__ex716_uece6cc12_L111
   @PUSH __ex716_uece6cc12_static_0
   @PUSHS
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CALL MULU
   @SHLN 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_7
   @PUSH __ex716_uece6cc12_static_0+2
   @PUSHS
   @CPOPI __ex716_off16
   @CPUSHADDR __ex716_uece6cc12_MapSmooth_local_7
   @PUSH __ex716_uece6cc12_static_1
   @PUSH 7
   @CALL ex716_far_get16v
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapSmooth_local_2
:__ex716_uece6cc12_L117
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapSmooth_local_24
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @CALL MULU
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_24
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_24
   @AND 0x7fff
   @CALL SHL16_BY_N
   @PUSH __ex716_uece6cc12_static_1
   @ADDS
   @PUSHS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L118
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_2
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_2
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L117
:__ex716_uece6cc12_L112
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_3
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_3
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L111
:__ex716_uece6cc12_L86
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_8
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapSmooth_local_8
:__ex716_uece6cc12_L88
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_8
   @CPUSHI __ex716_uece6cc12_MapSmooth_local_1
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L85
   @PUSH 1
:__ex716_uece6cc12_L81

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapAddMountainRange
@FUNCTION MapAddMountainRange
:MapAddMountainRange
@PUSHRETURN
@CLocals 156
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_off47 47
   @CLocalAt __ex716_off48 48
   @CLocalAt __ex716_off49 49
   @CLocalAt __ex716_off50 50
   @CLocalAt __ex716_off51 51
   @CLocalAt __ex716_off52 52
   @CLocalAt __ex716_off53 53
   @CLocalAt __ex716_off54 54
   @CLocalAt __ex716_off55 55
   @CLocalAt __ex716_off56 56
   @CLocalAt __ex716_off57 57
   @CLocalAt __ex716_off58 58
   @CLocalAt __ex716_off59 59
   @CLocalAt __ex716_off60 60
   @CLocalAt __ex716_off61 61
   @CLocalAt __ex716_off62 62
   @CLocalAt __ex716_off63 63
   @CLocalAt __ex716_off64 64
   @CLocalAt __ex716_off65 65
   @CLocalAt __ex716_off66 66
   @CLocalAt __ex716_off67 67
   @CLocalAt __ex716_off68 68
   @CLocalAt __ex716_off69 69
   @CLocalAt __ex716_off70 70
   @CLocalAt __ex716_off71 71
   @CLocalAt __ex716_off72 72
   @CLocalAt __ex716_off73 73
   @CLocalAt __ex716_off74 74
   @CLocalAt __ex716_off75 75
   @CLocalAt __ex716_off76 76
   @CLocalAt __ex716_off77 77
   @CLocalAt __ex716_off78 78
   @CLocalAt __ex716_off79 79
   @CLocalAt __ex716_off80 80
   @CLocalAt __ex716_off81 81
   @CLocalAt __ex716_off82 82
   @CLocalAt __ex716_off83 83
   @CLocalAt __ex716_off84 84
   @CLocalAt __ex716_off85 85
   @CLocalAt __ex716_off86 86
   @CLocalAt __ex716_off87 87
   @CLocalAt __ex716_off88 88
   @CLocalAt __ex716_off89 89
   @CLocalAt __ex716_off90 90
   @CLocalAt __ex716_off91 91
   @CLocalAt __ex716_off92 92
   @CLocalAt __ex716_off93 93
   @CLocalAt __ex716_off94 94
   @CLocalAt __ex716_off95 95
   @CLocalAt __ex716_off96 96
   @CLocalAt __ex716_off97 97
   @CLocalAt __ex716_off98 98
   @CLocalAt __ex716_off99 99
   @CLocalAt __ex716_off100 100
   @CLocalAt __ex716_off101 101
   @CLocalAt __ex716_off102 102
   @CLocalAt __ex716_off103 103
   @CLocalAt __ex716_off104 104
   @CLocalAt __ex716_off105 105
   @CLocalAt __ex716_off106 106
   @CLocalAt __ex716_off107 107
   @CLocalAt __ex716_off108 108
   @CLocalAt __ex716_off109 109
   @CLocalAt __ex716_off110 110
   @CLocalAt __ex716_off111 111
   @CLocalAt __ex716_off112 112
   @CLocalAt __ex716_off113 113
   @CLocalAt __ex716_off114 114
   @CLocalAt __ex716_off115 115
   @CLocalAt __ex716_off116 116
   @CLocalAt __ex716_off117 117
   @CLocalAt __ex716_off118 118
   @CLocalAt __ex716_off119 119
   @CLocalAt __ex716_off120 120
   @CLocalAt __ex716_off121 121
   @CLocalAt __ex716_off122 122
   @CLocalAt __ex716_off123 123
   @CLocalAt __ex716_off124 124
   @CLocalAt __ex716_off125 125
   @CLocalAt __ex716_off126 126
   @CLocalAt __ex716_off127 127
   @CLocalAt __ex716_off128 128
   @CLocalAt __ex716_off129 129
   @CLocalAt __ex716_off130 130
   @CLocalAt __ex716_off131 131
   @CLocalAt __ex716_off132 132
   @CLocalAt __ex716_off133 133
   @CLocalAt __ex716_off134 134
   @CLocalAt __ex716_off135 135
   @CLocalAt __ex716_off136 136
   @CLocalAt __ex716_off137 137
   @CLocalAt __ex716_off138 138
   @CLocalAt __ex716_off139 139
   @CLocalAt __ex716_off140 140
   @CLocalAt __ex716_off141 141
   @CLocalAt __ex716_off142 142
   @CLocalAt __ex716_off143 143
   @CLocalAt __ex716_off144 144
   @CLocalAt __ex716_off145 145
   @CLocalAt __ex716_off146 146
   @CLocalAt __ex716_off147 147
   @CLocalAt __ex716_off148 148
   @CLocalAt __ex716_off149 149
   @CLocalAt __ex716_off150 150
   @CLocalAt __ex716_off151 151
   @CLocalAt __ex716_off152 152
   @CLocalAt __ex716_off153 153
   @CLocalAt __ex716_off154 154
   @CLocalAt __ex716_off155 155
   @CLocalAt __ex716_off156 156
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_0 0
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_1 2
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_2 4
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_3 6
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_4 8
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_5 10
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_6 34
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_7 58
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_8 60
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_9 84
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_10 86
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_11 88
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_12 90
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_13 92
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_14 94
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_15 96
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_16 98
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_17 100
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_18 102
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_19 104
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_20 106
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_21 108
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_22 110
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_23 112
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_24 114
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_25 116
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_26 118
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_27 120
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_28 122
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_29 124
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_30 126
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_31 128
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_32 130
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_33 132
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_34 134
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_35 136
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_36 138
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_37 140
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_38 142
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_39 144
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_40 146
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_41 148
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_42 150
   @CLocalAt __ex716_uece6cc12_MapAddMountainRange_local_43 152
   @CLocalAt __ex716_pointer_tmp 154

   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_3
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_2
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_0

#USE SHL16_BY_N
#USE MUL
#USE DIV
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_0
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_1
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_2
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_2
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L127
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_15
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_1
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L127
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_2
   @PUSH 255
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uece6cc12_L127
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_1
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_2
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uece6cc12_L127
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_3
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L122
:__ex716_uece6cc12_L127
   @PUSH 0
   @JMP __ex716_uece6cc12_L121
:__ex716_uece6cc12_L122
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_12
:__ex716_uece6cc12_L128
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_17
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_17
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_5
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_18
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_18
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_6
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_19
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_19
   @CPOPI __ex716_off32
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_20
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_20
   @CPOPI __ex716_off56
   @CPUSHI __ex716_off32
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_5
   @SUBS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_9
   @CPUSHI __ex716_off56
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_6
   @SUBS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_10
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_9
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_9
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_10
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_10
   @CALL MUL
   @ADDS
   @PUSH 900
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L136
   @JMP __ex716_uece6cc12_L130
:__ex716_uece6cc12_L136
:__ex716_uece6cc12_L129
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_12
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_12
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_12
   @PUSH 64
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L128
:__ex716_uece6cc12_L130
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_12
   @PUSH 64
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L138
   @PUSH 0
   @JMP __ex716_uece6cc12_L121
:__ex716_uece6cc12_L138
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 6
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_23
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_23
   @PUSH 5
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_13
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_13
   @PUSH 2
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @SHLN 1
   @CPUSHADDR __ex716_off8
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_off32
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @SHLN 1
   @CPUSHADDR __ex716_off32
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_off56
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_4
   @JMP __ex716_uece6cc12_L147
:__ex716_uece6cc12_L144
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_25
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_2
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_1
   @SUBS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_25
   @ADDS
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_26
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_25
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_8
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_1
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_26
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L145
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_4
:__ex716_uece6cc12_L147
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L144
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_4
   @JMP __ex716_uece6cc12_L151
:__ex716_uece6cc12_L148
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_28
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_28
   @SUBS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_30
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_28
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_5
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_5
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_30
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @SUBS
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_28
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_off8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CALL MUL
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_30
   @CALL DIV
   @SWP
   @POPNULL
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_32
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_32
   @SUBS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_34
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_32
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_6
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_34
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @SUBS
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_32
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_off32
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CALL MUL
   @ADDS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_34
   @CALL DIV
   @SWP
   @POPNULL
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @PUSH 11
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_35
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_35
   @PUSH 5
   @SUBS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_11
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_36
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_36
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_5
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_37
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_37
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_36
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_off32
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_6
   @SUBS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_11
   @CALL MUL
   @PUSH 16
   @CALL DIV
   @SWP
   @POPNULL
   @SUBS
   @PUSH 6
   @CALL __ex716_uece6cc12_static_2
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_38
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_37
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_38
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_39
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_39
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_6
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_40
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_40
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_39
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHADDR __ex716_off8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_5
   @SUBS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_11
   @CALL MUL
   @PUSH 16
   @CALL DIV
   @SWP
   @POPNULL
   @ADDS
   @PUSH 6
   @CALL __ex716_uece6cc12_static_2
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_41
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_40
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_41
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L149
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_4
:__ex716_uece6cc12_L151
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @PUSH 1
   @SUBS
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L148
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_4
   @JMP __ex716_uece6cc12_L159
:__ex716_uece6cc12_L156
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @SHLN 1
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_42
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_42
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_5
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_42
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_6
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_42
   @CPUSHADDR __ex716_uece6cc12_MapAddMountainRange_local_8
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_42
   @CPUSHADDR __ex716_off12
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_42
   @CPUSHADDR __ex716_off36
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_42
   @CPUSHADDR __ex716_off62
   @ADDS
   @PUSHS
   @CALL __ex716_uece6cc12_static_35
:__ex716_uece6cc12_L157
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_4
:__ex716_uece6cc12_L159
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_4
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_7
   @PUSH 1
   @SUBS
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L156
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_0
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_3
   @CALL MapSmooth
   @CPOPI __ex716_uece6cc12_MapAddMountainRange_local_43
   @CPUSHI __ex716_uece6cc12_MapAddMountainRange_local_43
:__ex716_uece6cc12_L121

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapClassifyTerrain
@FUNCTION MapClassifyTerrain
:MapClassifyTerrain
@PUSHRETURN
@CLocals 18
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_0 0
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_1 2
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_2 4
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_3 6
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_4 8
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_5 10
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_6 12
   @CLocalAt __ex716_uece6cc12_MapClassifyTerrain_local_7 14
   @CLocalAt __ex716_pointer_tmp 16

   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_1
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_0

   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_0
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_0
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_1
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_1
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L166
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_1
   @PUSH 255
   @CMPS
   @POPNULL
   @POPNULL
   @JULE __ex716_uece6cc12_L164
:__ex716_uece6cc12_L166
   @PUSH 0
   @JMP __ex716_uece6cc12_L163
:__ex716_uece6cc12_L164
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_2
   @JMP __ex716_uece6cc12_L170
:__ex716_uece6cc12_L167
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_2
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_5
   @PUSH 255
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_6
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_5
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_6
   @ANDS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_3
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_5
   @PUSHS
   @SHRN 8
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_6
   @ANDS
   @PUSH 65520
   @ANDS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_3
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_1
   @CMPS
   @POPNULL
   @POPNULL
   @JUGT __ex716_uece6cc12_L171
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @PUSH 4
   @ORS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @JMP __ex716_uece6cc12_L172
:__ex716_uece6cc12_L171
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_3
   @PUSH 192
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L173
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @PUSH 5
   @ORS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @JMP __ex716_uece6cc12_L174
:__ex716_uece6cc12_L173
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_3
   @PUSH 80
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L175
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @PUSH 3
   @ORS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @JMP __ex716_uece6cc12_L176
:__ex716_uece6cc12_L175
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @PUSH 1
   @ORS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_4
:__ex716_uece6cc12_L176
:__ex716_uece6cc12_L174
:__ex716_uece6cc12_L172
   @PUSH 255
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_7
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_2
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_4
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_7
   @ANDS
   @SHLN 8
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_3
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_7
   @ANDS
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L168
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_2
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapClassifyTerrain_local_2
:__ex716_uece6cc12_L170
   @CPUSHI __ex716_uece6cc12_MapClassifyTerrain_local_2
   @PUSH 49
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L167
   @PUSH 1
:__ex716_uece6cc12_L163

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uece6cc12_static_164
:__ex716_uece6cc12_static_164
@PUSHRETURN
@CLocals 20
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_1 2
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_2 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_3 6
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_4 8
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_5 10
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_6 12
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_7 14
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_164_local_8 16
   @CLocalAt __ex716_pointer_tmp 18

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_0

#USE SHL16_BY_N
#USE SHR16_BY_N
#USE MUL
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_2
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_3
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_5
   @PUSHS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_4
   @PUSH 8
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_7
   @PUSH 255
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_8
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_5
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_7
   @AND 0x7fff
   @CALL SHR16_BY_N
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_8
   @ANDS
   @PUSH 32
   @ORS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_8
   @ANDS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_7
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_8
   @ANDS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_164_local_8
   @ANDS
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L177

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uece6cc12_static_167
:__ex716_uece6cc12_static_167
@PUSHRETURN
@CLocals 28
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_1 2
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_2 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3 6
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_4 8
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_5 10
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6 12
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_7 14
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_8 16
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_9 18
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_10 20
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_11 22
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_167_local_12 24
   @CLocalAt __ex716_pointer_tmp 26

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_0

#USE SHL16_BY_N
#USE SHR16_BY_N
#USE MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_2
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6
   @JMP __ex716_uece6cc12_L182
:__ex716_uece6cc12_L179
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L185
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L183
:__ex716_uece6cc12_L185
   @JMP __ex716_uece6cc12_L180
:__ex716_uece6cc12_L183
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_1
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3
   @JMP __ex716_uece6cc12_L189
:__ex716_uece6cc12_L186
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L192
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3
   @PUSH 7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L190
:__ex716_uece6cc12_L192
   @JMP __ex716_uece6cc12_L187
:__ex716_uece6cc12_L190
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_4
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_9
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_9
   @PUSHS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_5
   @PUSH 8
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_11
   @PUSH 255
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_12
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_9
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_11
   @AND 0x7fff
   @CALL SHR16_BY_N
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_12
   @ANDS
   @PUSH 65520
   @ANDS
   @PUSH 4
   @ORS
   @PUSH 32
   @ORS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_12
   @ANDS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_11
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_12
   @ANDS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_12
   @ANDS
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L187
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3
:__ex716_uece6cc12_L189
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_1
   @PUSH 1
   @ADDS
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L186
:__ex716_uece6cc12_L180
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6
:__ex716_uece6cc12_L182
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_167_local_2
   @PUSH 1
   @ADDS
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L179
:__ex716_uece6cc12_L178

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uece6cc12_static_181 0
::__ 1
::__ 0
::__ -1
::__ex716_uece6cc12_static_182 -1
::__ 0
::__ 1
::__ 0
G MapAddRivers
@FUNCTION MapAddRivers
:MapAddRivers
@PUSHRETURN
@CLocals 82
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_off47 47
   @CLocalAt __ex716_off48 48
   @CLocalAt __ex716_off49 49
   @CLocalAt __ex716_off50 50
   @CLocalAt __ex716_off51 51
   @CLocalAt __ex716_off52 52
   @CLocalAt __ex716_off53 53
   @CLocalAt __ex716_off54 54
   @CLocalAt __ex716_off55 55
   @CLocalAt __ex716_off56 56
   @CLocalAt __ex716_off57 57
   @CLocalAt __ex716_off58 58
   @CLocalAt __ex716_off59 59
   @CLocalAt __ex716_off60 60
   @CLocalAt __ex716_off61 61
   @CLocalAt __ex716_off62 62
   @CLocalAt __ex716_off63 63
   @CLocalAt __ex716_off64 64
   @CLocalAt __ex716_off65 65
   @CLocalAt __ex716_off66 66
   @CLocalAt __ex716_off67 67
   @CLocalAt __ex716_off68 68
   @CLocalAt __ex716_off69 69
   @CLocalAt __ex716_off70 70
   @CLocalAt __ex716_off71 71
   @CLocalAt __ex716_off72 72
   @CLocalAt __ex716_off73 73
   @CLocalAt __ex716_off74 74
   @CLocalAt __ex716_off75 75
   @CLocalAt __ex716_off76 76
   @CLocalAt __ex716_off77 77
   @CLocalAt __ex716_off78 78
   @CLocalAt __ex716_off79 79
   @CLocalAt __ex716_off80 80
   @CLocalAt __ex716_off81 81
   @CLocalAt __ex716_off82 82
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_0 0
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_1 2
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_2 4
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_3 6
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_4 8
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_5 10
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_6 12
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_7 14
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_8 16
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_9 18
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_10 20
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_11 22
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_12 24
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_13 26
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_14 28
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_15 30
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_16 32
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_17 34
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_18 36
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_19 38
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_20 40
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_21 42
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_22 44
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_23 46
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_24 48
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_25 50
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_26 52
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_27 54
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_28 56
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_29 58
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_30 60
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_31 62
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_32 64
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_33 66
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_34 68
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_35 70
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_36 72
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_37 74
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_38 76
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_39 78
   @CLocalAt __ex716_uece6cc12_MapAddRivers_local_40 80

   @CPOPI __ex716_uece6cc12_MapAddRivers_local_2
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_1
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_0

#USE MUL
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_0
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_1
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_2
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_2
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L198
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_17
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_17
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L198
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_1
   @PUSH 255
   @CMPS
   @POPNULL
   @POPNULL
   @JGT __ex716_uece6cc12_L198
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_2
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_17
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L194
:__ex716_uece6cc12_L198
   @PUSH -1
   @JMP __ex716_uece6cc12_L193
:__ex716_uece6cc12_L194
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_18
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_18
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_15
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_18
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_14
   @JMP __ex716_uece6cc12_L202
:__ex716_uece6cc12_L199
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_11
:__ex716_uece6cc12_L203
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_19
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_19
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_4
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_20
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_20
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_5
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_13
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 255
   @ANDS
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_1
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L207
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_13
   @PUSH 15
   @ANDS
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L207
   @JMP __ex716_uece6cc12_L205
:__ex716_uece6cc12_L207
:__ex716_uece6cc12_L204
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_11
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_11
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_11
   @PUSH 256
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L203
:__ex716_uece6cc12_L205
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_11
   @PUSH 256
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L209
   @JMP __ex716_uece6cc12_L200
:__ex716_uece6cc12_L209
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_15
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_15
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_12
:__ex716_uece6cc12_L211
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_7
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CALL __ex716_uece6cc12_static_164
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @PUSH 15
   @ANDS
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L215
   @JMP __ex716_uece6cc12_L213
:__ex716_uece6cc12_L215
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_9
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_10
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_7
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_6
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_3
:__ex716_uece6cc12_L217
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_181
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_24
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_182
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_25
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_28
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_24
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_28
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L225
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_29
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_24
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_29
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L225
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_25
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_28
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L225
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_25
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_29
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L221
:__ex716_uece6cc12_L225
   @JMP __ex716_uece6cc12_L218
:__ex716_uece6cc12_L221
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_25
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_24
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_26
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_26
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uece6cc12_L226
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_26
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_6
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_24
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_9
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_25
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_10
:__ex716_uece6cc12_L226
:__ex716_uece6cc12_L218
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_3
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L217
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_9
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L228
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_10
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L228
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CALL __ex716_uece6cc12_static_167
   @JMP __ex716_uece6cc12_L213
:__ex716_uece6cc12_L228
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_31
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_31
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_8
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_31
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_3
:__ex716_uece6cc12_L230
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_4
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_181
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_32
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_5
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_182
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_33
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_36
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_32
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_36
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L238
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_37
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_32
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_37
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L238
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_33
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_36
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L238
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_33
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_37
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L234
:__ex716_uece6cc12_L238
   @JMP __ex716_uece6cc12_L231
:__ex716_uece6cc12_L234
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_33
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_32
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_34
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_34
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JUGE __ex716_uece6cc12_L239
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_34
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_6
   @PUSH 2
   @ADDS
   @CMPS
   @POPNULL
   @POPNULL
   @JUGT __ex716_uece6cc12_L239
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_8
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_8
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_0
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_8
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_40
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_40
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L241
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_32
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_9
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_33
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_10
:__ex716_uece6cc12_L241
:__ex716_uece6cc12_L239
:__ex716_uece6cc12_L231
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_3
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_3
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L230
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_9
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_4
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_10
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_5
:__ex716_uece6cc12_L212
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_12
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_12
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_12
   @PUSH 49
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L211
:__ex716_uece6cc12_L213
:__ex716_uece6cc12_L200
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_14
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddRivers_local_14
:__ex716_uece6cc12_L202
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_14
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_2
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L199
   @CPUSHI __ex716_uece6cc12_MapAddRivers_local_15
:__ex716_uece6cc12_L193

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uece6cc12_static_224 0
::__ 1
::__ 0
::__ -1
::__ex716_uece6cc12_static_225 -1
::__ 0
::__ 1
::__ 0
@FUNCTION __ex716_uece6cc12_static_223
:__ex716_uece6cc12_static_223
@PUSHRETURN
@CLocals 32
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1 2
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_3 6
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_4 8
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_5 10
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_6 12
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_7 14
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_8 16
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_9 18
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_10 20
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_11 22
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_12 24
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_13 26
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_14 28
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_223_local_15 30

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_0

#USE MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L248
   @PUSH 7
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L248
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L248
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L244
:__ex716_uece6cc12_L248
   @PUSH 0
   @JMP __ex716_uece6cc12_L243
:__ex716_uece6cc12_L244
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_4
   @PUSH 15
   @ANDS
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L251
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_4
   @PUSH 32
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L249
:__ex716_uece6cc12_L251
   @PUSH 0
   @JMP __ex716_uece6cc12_L243
:__ex716_uece6cc12_L249
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_3
:__ex716_uece6cc12_L252
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_224
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_225
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_11
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_13
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L260
   @PUSH 7
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_14
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_14
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L260
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_11
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L260
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_11
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_14
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L256
:__ex716_uece6cc12_L260
   @JMP __ex716_uece6cc12_L253
:__ex716_uece6cc12_L256
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_11
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_10
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_4
   @PUSH 15
   @ANDS
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L261
   @PUSH 0
   @JMP __ex716_uece6cc12_L243
:__ex716_uece6cc12_L261
:__ex716_uece6cc12_L253
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_223_local_3
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L252
   @PUSH 1
:__ex716_uece6cc12_L243

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uece6cc12_static_241 0
::__ 1
::__ 0
::__ -1
::__ex716_uece6cc12_static_242 -1
::__ 0
::__ 1
::__ 0
G MapAddForests
@FUNCTION MapAddForests
:MapAddForests
@PUSHRETURN
@CLocals 78
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_off47 47
   @CLocalAt __ex716_off48 48
   @CLocalAt __ex716_off49 49
   @CLocalAt __ex716_off50 50
   @CLocalAt __ex716_off51 51
   @CLocalAt __ex716_off52 52
   @CLocalAt __ex716_off53 53
   @CLocalAt __ex716_off54 54
   @CLocalAt __ex716_off55 55
   @CLocalAt __ex716_off56 56
   @CLocalAt __ex716_off57 57
   @CLocalAt __ex716_off58 58
   @CLocalAt __ex716_off59 59
   @CLocalAt __ex716_off60 60
   @CLocalAt __ex716_off61 61
   @CLocalAt __ex716_off62 62
   @CLocalAt __ex716_off63 63
   @CLocalAt __ex716_off64 64
   @CLocalAt __ex716_off65 65
   @CLocalAt __ex716_off66 66
   @CLocalAt __ex716_off67 67
   @CLocalAt __ex716_off68 68
   @CLocalAt __ex716_off69 69
   @CLocalAt __ex716_off70 70
   @CLocalAt __ex716_off71 71
   @CLocalAt __ex716_off72 72
   @CLocalAt __ex716_off73 73
   @CLocalAt __ex716_off74 74
   @CLocalAt __ex716_off75 75
   @CLocalAt __ex716_off76 76
   @CLocalAt __ex716_off77 77
   @CLocalAt __ex716_off78 78
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_0 0
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_1 2
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_2 4
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_3 6
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_4 8
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_5 10
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_6 12
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_7 14
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_8 16
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_9 18
   @CLocal32At __ex716_uece6cc12_MapAddForests_local_10 20
   @CLocal32At __ex716_uece6cc12_MapAddForests_local_11 24
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_12 28
   @CLocal32At __ex716_uece6cc12_MapAddForests_local_13 30
   @CLocal32At __ex716_uece6cc12_MapAddForests_local_14 34
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_15 38
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_16 40
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_17 42
   @CLocal32At __ex716_uece6cc12_MapAddForests_local_18 44
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_19 48
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_20 50
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_21 52
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_22 54
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_23 56
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_24 58
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_25 60
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_26 62
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_27 64
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_28 66
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_29 68
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_30 70
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_31 72
   @CLocalAt __ex716_uece6cc12_MapAddForests_local_32 74
   @CLocalAt __ex716_pointer_tmp 76

   @CPOPI __ex716_uece6cc12_MapAddForests_local_1
   @CPOPI __ex716_uece6cc12_MapAddForests_local_0

#USE ADD32U
#USE SHL16_BY_N
#USE SHR16_BY_N
#USE SHR32
#USE MUL
#USE MUL32U
#USE DIV32U
#USE DIV32U_Q
#USE CMP32U
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @CPOPI __ex716_uece6cc12_MapAddForests_local_0
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_1
   @CPOPI __ex716_uece6cc12_MapAddForests_local_1
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L267
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L267
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_1
   @PUSH 100
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L264
:__ex716_uece6cc12_L267
   @PUSH -1
   @JMP __ex716_uece6cc12_L263
:__ex716_uece6cc12_L264
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddForests_local_17
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_17
   @CPOPI __ex716_uece6cc12_MapAddForests_local_15
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_17
   @CPOPI __ex716_uece6cc12_MapAddForests_local_12
   @JMP __ex716_uece6cc12_L271
:__ex716_uece6cc12_L268
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_12
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @PUSH 15
   @ANDS
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L272
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_15
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddForests_local_15
:__ex716_uece6cc12_L272
:__ex716_uece6cc12_L269
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_12
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddForests_local_12
:__ex716_uece6cc12_L271
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_12
   @PUSH 49
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L268
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_15
   @PUSH 0
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_1
   @DUP
   @SHRN 15
   @COMP2
   @CALL MUL32U
   @PUSH32(A) $$$100
   @CALL DIV32U_Q
   @CPOPI __ex716_off26
   @CPOPI __ex716_off24
   @CPUSHI __ex716_off24
   @CPUSHI __ex716_off26
   @PUSH32(A) $$$0
   @CALL CMP32U
   @IF32_NE
      @JMP __ex716_uece6cc12_L274
   @ENDIF
   @PUSH 0
   @JMP __ex716_uece6cc12_L263
:__ex716_uece6cc12_L274
   @CPUSHI __ex716_off24
   @CPUSHI __ex716_off26
   @PUSH 6
   @AND 0x7fff
   @CALL SHR32
   @PUSH32(A) $$$1
   @CALL ADD32U
   @CPOPI __ex716_off36
   @CPOPI __ex716_off34
   @PUSH32(A) $$$0
   @CPOPI __ex716_off46
   @CPOPI __ex716_off44
   @CPUSHI __ex716_off44
   @CPUSHI __ex716_off46
   @CPOPI __ex716_off22
   @CPOPI __ex716_off20
   @CPUSHI __ex716_off44
   @CPUSHI __ex716_off46
   @CPOPI __ex716_off32
   @CPOPI __ex716_off30
   @JMP __ex716_uece6cc12_L279
:__ex716_uece6cc12_L276
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddForests_local_7
:__ex716_uece6cc12_L280
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddForests_local_19
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_19
   @CPOPI __ex716_uece6cc12_MapAddForests_local_5
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddForests_local_20
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_20
   @CPOPI __ex716_uece6cc12_MapAddForests_local_6
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_5
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_6
   @CALL __ex716_uece6cc12_static_223
   @CPOPI __ex716_uece6cc12_MapAddForests_local_21
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_21
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L284
   @JMP __ex716_uece6cc12_L282
:__ex716_uece6cc12_L284
:__ex716_uece6cc12_L281
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_7
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddForests_local_7
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_7
   @PUSH 256
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L280
:__ex716_uece6cc12_L282
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_7
   @PUSH 256
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L286
   @JMP __ex716_uece6cc12_L277
:__ex716_uece6cc12_L286
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_5
   @CPOPI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_6
   @CPOPI __ex716_uece6cc12_MapAddForests_local_3
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddForests_local_8
   @JMP __ex716_uece6cc12_L291
:__ex716_uece6cc12_L288
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_3
   @CALL __ex716_uece6cc12_static_223
   @CPOPI __ex716_uece6cc12_MapAddForests_local_22
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_22
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L292
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_3
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_2
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @CPOPI __ex716_uece6cc12_MapAddForests_local_9
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_9
   @SHRN 8
   @PUSH 255
   @ANDS
   @PUSH 16
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L294
   @PUSH 8
   @CPOPI __ex716_uece6cc12_MapAddForests_local_24
   @PUSH 255
   @CPOPI __ex716_uece6cc12_MapAddForests_local_25
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_3
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_2
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_9
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_24
   @AND 0x7fff
   @CALL SHR16_BY_N
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_25
   @ANDS
   @PUSH 16
   @ORS
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_25
   @ANDS
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_24
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_9
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_25
   @ANDS
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_25
   @ANDS
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_off20
   @CPUSHI __ex716_off22
   @PUSH32(A) $$$1
   @CALL ADD32U
   @CPOPI __ex716_off22
   @CPOPI __ex716_off20
:__ex716_uece6cc12_L294
:__ex716_uece6cc12_L292
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @PUSH 4
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddForests_local_26
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_26
   @CPOPI __ex716_uece6cc12_MapAddForests_local_4
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_4
   @SHLN 1
   @CPOPI __ex716_uece6cc12_MapAddForests_local_27
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_27
   @PUSH __ex716_uece6cc12_static_241
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_3
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_27
   @PUSH __ex716_uece6cc12_static_242
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddForests_local_3
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddForests_local_29
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_29
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L301
   @PUSH 7
   @CPOPI __ex716_uece6cc12_MapAddForests_local_30
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_30
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L301
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_3
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_29
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L301
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_3
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_30
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L301
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_0
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_3
   @CALL __ex716_uece6cc12_static_223
   @CPOPI __ex716_uece6cc12_MapAddForests_local_32
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_32
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L296
:__ex716_uece6cc12_L301
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_5
   @CPOPI __ex716_uece6cc12_MapAddForests_local_2
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_6
   @CPOPI __ex716_uece6cc12_MapAddForests_local_3
:__ex716_uece6cc12_L296
:__ex716_uece6cc12_L289
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_8
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddForests_local_8
:__ex716_uece6cc12_L291
   @CPUSHI __ex716_uece6cc12_MapAddForests_local_8
   @PUSH 96
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L302
   @CPUSHI __ex716_off20
   @CPUSHI __ex716_off22
   @CPUSHI __ex716_off24
   @CPUSHI __ex716_off26
   @CALL CMP32U
   @IF32_ULT
      @JMP __ex716_uece6cc12_L288
   @ENDIF
:__ex716_uece6cc12_L302
:__ex716_uece6cc12_L277
   @CPUSHI __ex716_off30
   @CPUSHI __ex716_off32
   @PUSH32(A) $$$1
   @CALL ADD32U
   @CPOPI __ex716_off32
   @CPOPI __ex716_off30
:__ex716_uece6cc12_L279
   @CPUSHI __ex716_off30
   @CPUSHI __ex716_off32
   @CPUSHI __ex716_off34
   @CPUSHI __ex716_off36
   @CALL CMP32U
   @IF32_UGE
      @JMP __ex716_uece6cc12_L303
   @ENDIF
   @CPUSHI __ex716_off20
   @CPUSHI __ex716_off22
   @CPUSHI __ex716_off24
   @CPUSHI __ex716_off26
   @CALL CMP32U
   @IF32_ULT
      @JMP __ex716_uece6cc12_L276
   @ENDIF
:__ex716_uece6cc12_L303
   @CPUSHI __ex716_off20
   @CPUSHI __ex716_off22
   @POPNULL
:__ex716_uece6cc12_L263

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G SettlementListInitialize
@FUNCTION SettlementListInitialize
:SettlementListInitialize
@PUSHRETURN
@CLocals 8
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_uece6cc12_SettlementListInitialize_local_0 0
   @CLocalAt __ex716_uece6cc12_SettlementListInitialize_local_1 2
   @CLocalAt __ex716_uece6cc12_SettlementListInitialize_local_2 4
   @CLocalAt __ex716_pointer_tmp 6

   @CPOPI __ex716_uece6cc12_SettlementListInitialize_local_2
   @CPOPI __ex716_uece6cc12_SettlementListInitialize_local_1
   @CPOPI __ex716_uece6cc12_SettlementListInitialize_local_0

   @CPUSHI __ex716_uece6cc12_SettlementListInitialize_local_0
   @CPOPI __ex716_uece6cc12_SettlementListInitialize_local_0
   @CPUSHI __ex716_uece6cc12_SettlementListInitialize_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L305
   @JMP __ex716_uece6cc12_L304
:__ex716_uece6cc12_L305
   @CPUSHI __ex716_uece6cc12_SettlementListInitialize_local_0
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_SettlementListInitialize_local_1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_SettlementListInitialize_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_SettlementListInitialize_local_0
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_SettlementListInitialize_local_2
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_uece6cc12_L304

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapFindSettlement
@FUNCTION MapFindSettlement
:MapFindSettlement
@PUSHRETURN
@CLocals 10
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_uece6cc12_MapFindSettlement_local_0 0
   @CLocalAt __ex716_uece6cc12_MapFindSettlement_local_1 2
   @CLocalAt __ex716_uece6cc12_MapFindSettlement_local_2 4
   @CLocalAt __ex716_uece6cc12_MapFindSettlement_local_3 6
   @CLocalAt __ex716_uece6cc12_MapFindSettlement_local_4 8

   @CPOPI __ex716_uece6cc12_MapFindSettlement_local_1
   @CPOPI __ex716_uece6cc12_MapFindSettlement_local_0

   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_0
   @CPOPI __ex716_uece6cc12_MapFindSettlement_local_0
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_1
   @CPOPI __ex716_uece6cc12_MapFindSettlement_local_1
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapFindSettlement_local_4
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_0
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L310
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_0
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L308
:__ex716_uece6cc12_L310
   @PUSH 0
   @JMP __ex716_uece6cc12_L307
:__ex716_uece6cc12_L308
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapFindSettlement_local_2
   @JMP __ex716_uece6cc12_L314
:__ex716_uece6cc12_L311
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_2
   @SHLN 3
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_0
   @PUSHS
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L315
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_2
   @SHLN 3
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_0
   @PUSHS
   @ADDS
   @JMP __ex716_uece6cc12_L307
:__ex716_uece6cc12_L315
:__ex716_uece6cc12_L312
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_2
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapFindSettlement_local_2
:__ex716_uece6cc12_L314
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_2
   @CPUSHI __ex716_uece6cc12_MapFindSettlement_local_0
   @PUSH 2
   @ADDS
   @PUSHS
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L311
   @PUSH 0
:__ex716_uece6cc12_L307

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uece6cc12_static_292 0
::__ 1
::__ 0
::__ -1
::__ex716_uece6cc12_static_293 -1
::__ 0
::__ 1
::__ 0
@FUNCTION __ex716_uece6cc12_static_291
:__ex716_uece6cc12_static_291
@PUSHRETURN
@CLocals 26
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_1 2
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_2 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_3 6
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_4 8
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_5 10
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_6 12
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_7 14
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_8 16
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_9 18
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_10 20
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_11 22
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_291_local_12 24

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_0

#USE MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_2
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_2
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_1
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_4
   @PUSH 15
   @ANDS
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L320
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_4
   @PUSH 128
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L318
:__ex716_uece6cc12_L320
   @PUSH -1
   @JMP __ex716_uece6cc12_L317
:__ex716_uece6cc12_L318
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_3
:__ex716_uece6cc12_L321
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_292
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_3
   @SHLN 1
   @PUSH __ex716_uece6cc12_static_293
   @ADDS
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_7
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_9
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_9
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L329
   @PUSH 7
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_10
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_10
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L329
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_9
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L329
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_10
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L325
:__ex716_uece6cc12_L329
   @JMP __ex716_uece6cc12_L322
:__ex716_uece6cc12_L325
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_7
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_6
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_4
   @PUSH 15
   @ANDS
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L330
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_4
   @PUSH 32
   @ANDS
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L332
   @PUSH 2
   @JMP __ex716_uece6cc12_L317
:__ex716_uece6cc12_L332
   @PUSH 1
   @JMP __ex716_uece6cc12_L317
:__ex716_uece6cc12_L330
:__ex716_uece6cc12_L322
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_3
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_3
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L321
   @PUSH 7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_2
   @CALL MUL
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_1
   @ADDS
   @SHLN 1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @SHRN 8
   @PUSH 255
   @ANDS
   @PUSH 15
   @ANDS
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L335
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_12
   @JMP __ex716_uece6cc12_L336
:__ex716_uece6cc12_L335
   @PUSH -1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_12
:__ex716_uece6cc12_L336
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_291_local_12
:__ex716_uece6cc12_L317

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_uece6cc12_static_309
:__ex716_uece6cc12_static_309
@PUSHRETURN
@CLocals 20
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_0 0
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_1 2
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_2 4
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3 6
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4 8
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_5 10
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_6 12
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_7 14
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_8 16
   @CLocalAt __ex716_uece6cc12___ex716_uece6cc12_static_309_local_9 18

   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_0

#USE DIV
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_0
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_1
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_2
   @PUSH 0
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_5
   @JMP __ex716_uece6cc12_L341
:__ex716_uece6cc12_L338
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_5
   @SHLN 3
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_7
   @PUSH 7
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_9
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_0
   @PUSHS
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_9
   @CALL DIV
   @POPNULL
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_6
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_7
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_0
   @PUSHS
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_9
   @CALL DIV
   @SWP
   @POPNULL
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_1
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_6
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L342
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4
   @COMP2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4
:__ex716_uece6cc12_L342
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_2
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3
   @SUBS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L344
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3
   @COMP2
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3
:__ex716_uece6cc12_L344
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_3
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_4
   @PUSH 8
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L346
   @PUSH 0
   @JMP __ex716_uece6cc12_L337
:__ex716_uece6cc12_L346
:__ex716_uece6cc12_L339
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_5
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_5
:__ex716_uece6cc12_L341
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_5
   @CPUSHI __ex716_uece6cc12___ex716_uece6cc12_static_309_local_0
   @PUSH 2
   @ADDS
   @PUSHS
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L338
   @PUSH 1
:__ex716_uece6cc12_L337

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapAddSettlements
@FUNCTION MapAddSettlements
:MapAddSettlements
@PUSHRETURN
@CLocals 62
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_off41 41
   @CLocalAt __ex716_off42 42
   @CLocalAt __ex716_off43 43
   @CLocalAt __ex716_off44 44
   @CLocalAt __ex716_off45 45
   @CLocalAt __ex716_off46 46
   @CLocalAt __ex716_off47 47
   @CLocalAt __ex716_off48 48
   @CLocalAt __ex716_off49 49
   @CLocalAt __ex716_off50 50
   @CLocalAt __ex716_off51 51
   @CLocalAt __ex716_off52 52
   @CLocalAt __ex716_off53 53
   @CLocalAt __ex716_off54 54
   @CLocalAt __ex716_off55 55
   @CLocalAt __ex716_off56 56
   @CLocalAt __ex716_off57 57
   @CLocalAt __ex716_off58 58
   @CLocalAt __ex716_off59 59
   @CLocalAt __ex716_off60 60
   @CLocalAt __ex716_off61 61
   @CLocalAt __ex716_off62 62
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_0 0
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_1 2
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_2 4
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_3 6
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_4 8
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_5 10
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_6 12
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_7 14
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_8 16
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_9 18
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_10 20
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_11 22
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_12 24
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_13 26
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_14 28
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_15 30
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_16 32
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_17 34
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_18 36
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_19 38
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_20 40
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_21 42
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_22 44
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_23 46
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_24 48
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_25 50
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_26 52
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_27 54
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_28 56
   @CLocalAt __ex716_uece6cc12_MapAddSettlements_local_29 58
   @CLocalAt __ex716_pointer_tmp 60

   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_2
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_1
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_0

#USE SHL16_BY_N
#USE SHR16_BY_N
#USE MUL
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_0
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_0
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_1
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_2
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_2
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_13
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_0
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L354
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L354
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_15
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_2
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L354
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSH 4
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L355
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L354
:__ex716_uece6cc12_L355
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSH 2
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSH 4
   @ADDS
   @PUSHS
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L349
:__ex716_uece6cc12_L354
   @PUSH -1
   @JMP __ex716_uece6cc12_L348
:__ex716_uece6cc12_L349
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_10
   @JMP __ex716_uece6cc12_L357
:__ex716_uece6cc12_L356
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_10
   @SHL
   @DUP
   @SHLN 2
   @ADDS
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_2
   @CALL MUL
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L359
   @PUSH 2
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_12
   @JMP __ex716_uece6cc12_L360
:__ex716_uece6cc12_L359
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_10
   @SHL
   @DUP
   @SHLN 2
   @ADDS
   @PUSH 9
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_2
   @CALL MUL
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L361
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_12
   @JMP __ex716_uece6cc12_L362
:__ex716_uece6cc12_L361
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_12
:__ex716_uece6cc12_L362
:__ex716_uece6cc12_L360
   @PUSH -1
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_7
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_12
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_6
   @JMP __ex716_uece6cc12_L366
:__ex716_uece6cc12_L363
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_5
:__ex716_uece6cc12_L367
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_17
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_17
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_3
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_0
   @PUSH 7
   @CALL MapRandomBelow
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_18
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_18
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_4
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_0
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_3
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_4
   @CALL __ex716_uece6cc12_static_291
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_19
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_19
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_6
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L371
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_3
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_4
   @CALL __ex716_uece6cc12_static_309
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_20
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_20
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_uece6cc12_L371
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_6
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_7
   @JMP __ex716_uece6cc12_L369
:__ex716_uece6cc12_L371
:__ex716_uece6cc12_L368
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_5
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_5
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_5
   @PUSH 512
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L367
:__ex716_uece6cc12_L369
:__ex716_uece6cc12_L364
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_6
   @PUSH 1
   @SUBS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_6
:__ex716_uece6cc12_L366
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_21
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_6
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_21
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L373
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_7
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_21
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L363
:__ex716_uece6cc12_L373
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L374
   @JMP __ex716_uece6cc12_L358
:__ex716_uece6cc12_L374
   @PUSH 7
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_4
   @CALL MUL
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_3
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_9
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_9
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_22
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_22
   @PUSHS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_11
   @PUSH 8
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_24
   @PUSH 255
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_25
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_22
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_11
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_24
   @AND 0x7fff
   @CALL SHR16_BY_N
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_25
   @ANDS
   @PUSH 128
   @ORS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_25
   @ANDS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_24
   @AND 0x7fff
   @CALL SHL16_BY_N
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_11
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_25
   @ANDS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_25
   @ANDS
   @ORS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSH 2
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_27
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_27
   @PUSHS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_26
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_27
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_26
   @PUSH 1
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_26
   @SHLN 3
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSHS
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_8
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_8
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_9
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLE __ex716_uece6cc12_L377
   @PUSH 1
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_28
   @JMP __ex716_uece6cc12_L378
:__ex716_uece6cc12_L377
   @PUSH 2
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_28
:__ex716_uece6cc12_L378
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_8
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_28
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_8
   @PUSH 4
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 1
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_8
   @PUSH 6
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @PUSH 0
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_10
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapAddSettlements_local_10
:__ex716_uece6cc12_L357
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_10
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_2
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_uece6cc12_L379
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSH 2
   @ADDS
   @PUSHS
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_1
   @PUSH 4
   @ADDS
   @PUSHS
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_uece6cc12_L356
:__ex716_uece6cc12_L379
:__ex716_uece6cc12_L358
   @CPUSHI __ex716_uece6cc12_MapAddSettlements_local_10
:__ex716_uece6cc12_L348

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G MapChecksum
@FUNCTION MapChecksum
:MapChecksum
@PUSHRETURN
@CLocals 14
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_uece6cc12_MapChecksum_local_0 0
   @CLocal32At __ex716_uece6cc12_MapChecksum_local_1 2
   @CLocalAt __ex716_uece6cc12_MapChecksum_local_2 6
   @CLocal32At __ex716_uece6cc12_MapChecksum_local_3 8
   @CLocalAt __ex716_uece6cc12_MapChecksum_local_4 12

   @CPOPI __ex716_uece6cc12_MapChecksum_local_0

#USE XOR32
#USE MUL32U
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @CPOPI __ex716_uece6cc12_MapChecksum_local_0
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_uece6cc12_L381
   @PUSH32(A) $$$0
   @JMP __ex716_uece6cc12_L380
:__ex716_uece6cc12_L381
   @PUSH32(A) $$$2166136261
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @PUSH32(A) $$$16777619
   @CPOPI __ex716_off10
   @CPOPI __ex716_off8
   @CPUSHI __ex716_off8
   @CPUSHI __ex716_off10
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSHS
   @PUSH 0
   @CALL XOR32
   @CALL MUL32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPUSHI __ex716_off8
   @CPUSHI __ex716_off10
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSH 2
   @ADDS
   @PUSHS
   @PUSH 0
   @CALL XOR32
   @CALL MUL32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPUSHI __ex716_off8
   @CPUSHI __ex716_off10
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSH 4
   @ADDS
   @PUSHS
   @PUSH 0
   @CALL XOR32
   @CALL MUL32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPUSHI __ex716_off8
   @CPUSHI __ex716_off10
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSH 6
   @ADDS
   @PUSHS
   @PUSH 0
   @CALL XOR32
   @CALL MUL32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPUSHI __ex716_off8
   @CPUSHI __ex716_off10
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSH 8
   @ADDS
   @DUP
   @PUSHS
   @SWP
   @ADD 2
   @PUSHS
   @CALL XOR32
   @CALL MUL32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @CPUSHI __ex716_off8
   @CPUSHI __ex716_off10
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSH 12
   @ADDS
   @PUSHS
   @PUSH 0
   @CALL XOR32
   @CALL MUL32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
   @PUSH 0
   @CPOPI __ex716_uece6cc12_MapChecksum_local_2
   @JMP __ex716_uece6cc12_L386
:__ex716_uece6cc12_L383
   @PUSH32(A) $$$16777619
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_2
   @SHLN 1
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_0
   @PUSH 14
   @ADDS
   @ADDS
   @PUSHS
   @PUSH 0
   @CALL XOR32
   @CALL MUL32U
   @CPOPI __ex716_off4
   @CPOPI __ex716_off2
:__ex716_uece6cc12_L384
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_2
   @PUSH 1
   @ADDS
   @CPOPI __ex716_uece6cc12_MapChecksum_local_2
:__ex716_uece6cc12_L386
   @CPUSHI __ex716_uece6cc12_MapChecksum_local_2
   @PUSH 49
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_uece6cc12_L383
   @CPUSHI __ex716_off2
   @CPUSHI __ex716_off4
:__ex716_uece6cc12_L380

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_uece6cc12_static_1 $$0 * 14
G ex716_far_put16v
G ex716_far_get16v
G ex716_far_put16
G ex716_far_get16

@FUNCTION __ex716_u53ea1f94_static_0
:__ex716_u53ea1f94_static_0
@PUSHRETURN
@CLocals 6
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_0 0
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_1 2
   @CLocalAt __ex716_pointer_tmp 4

   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_0

   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_1
   @PUSHS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_0
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_0_local_1
   @PUSH 2
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
:__ex716_u53ea1f94_L1

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __ex716_u53ea1f94_static_5
:__ex716_u53ea1f94_static_5
@PUSHRETURN
@CLocals 12
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0 0
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_1 2
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_2 4
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_3 6
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_4 8
   @CLocalAt __ex716_pointer_tmp 10

   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0

   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_1
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_1
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0
   @PUSH 2
   @ADDS
   @PUSHS
   @CMPS
   @POPNULL
   @POPNULL
   @JULE __ex716_u53ea1f94_L3
   @PUSH 0
   @JMP __ex716_u53ea1f94_L2
:__ex716_u53ea1f94_L3
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0
   @PUSHS
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_1
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0
   @PUSHS
   @ADDS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_0
   @PUSH 2
   @ADDS
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_4
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_4
   @CPOPI __ex716_pointer_tmp
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_4
   @PUSHS
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_1
   @SUBS
   @CPUSHI __ex716_pointer_tmp
   @POPS
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_5_local_2
:__ex716_u53ea1f94_L2

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_u53ea1f94_static_12 $$69
::__ $$88
::__ $$55
::__ $$49
::__ $$54
::__ $$77
::__ $$66
::__ $$49
@FUNCTION __ex716_u53ea1f94_static_13
:__ex716_u53ea1f94_static_13
@PUSHRETURN
@CLocals 40
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_off25 25
   @CLocalAt __ex716_off26 26
   @CLocalAt __ex716_off27 27
   @CLocalAt __ex716_off28 28
   @CLocalAt __ex716_off29 29
   @CLocalAt __ex716_off30 30
   @CLocalAt __ex716_off31 31
   @CLocalAt __ex716_off32 32
   @CLocalAt __ex716_off33 33
   @CLocalAt __ex716_off34 34
   @CLocalAt __ex716_off35 35
   @CLocalAt __ex716_off36 36
   @CLocalAt __ex716_off37 37
   @CLocalAt __ex716_off38 38
   @CLocalAt __ex716_off39 39
   @CLocalAt __ex716_off40 40
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0 0
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_1 2
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_2 4
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_3 6
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_4 8
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_5 10
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_6 12
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_7 14
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_8 16
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_9 18
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_10 20
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_11 22
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_12 24
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_13 26
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_14 28
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_15 30
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_16 32
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_17 34
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_18 36
   @CLocalAt __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_19 38

   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0

   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @PUSH __ex716_u53ea1f94_static_11+2
   @PUSHS
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_1
   @PUSH __ex716_u53ea1f94_static_12
   @PUSH 8
   @PUSH 1
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_2
   @PUSH 1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_3
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_3
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @PUSH __ex716_u53ea1f94_static_9
   @PUSH 2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_3
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_4
   @PUSH 1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_5
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_4
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_5
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @PUSH __ex716_u53ea1f94_static_9+2
   @PUSH 2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_5
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_6
   @PUSH 1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_7
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_6
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_7
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @PUSH __ex716_u53ea1f94_static_9+4
   @PUSH 2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_7
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_8
   @PUSH 1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_9
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_8
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_9
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @PUSH __ex716_u53ea1f94_static_9+6
   @PUSH 2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_9
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_10
   @PUSH 1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_11
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_10
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_11
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @PUSH __ex716_u53ea1f94_static_9+8
   @PUSH 4
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_11
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_12
   @PUSH 1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_13
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_12
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_13
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @PUSH __ex716_u53ea1f94_static_9+12
   @PUSH 2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_13
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_14
   @PUSH 1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_15
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_14
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_15
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @CPUSHADDR __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_1
   @PUSH 2
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_15
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_16
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_16
   @PUSH 1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_1
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_17
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_17
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_u53ea1f94_L24
   @PUSH __ex716_u53ea1f94_static_11
   @PUSHS
   @PUSH 8
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_17
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_18
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_18
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_1
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L23
:__ex716_u53ea1f94_L24
   @PUSH __ex716_u53ea1f94_static_9+14
   @PUSH 2
   @PUSH 49
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_0
   @CALL fwrite
   @CPOPI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_19
   @CPUSHI __ex716_u53ea1f94___ex716_u53ea1f94_static_13_local_19
   @PUSH 49
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_u53ea1f94_L7
:__ex716_u53ea1f94_L23
   @PUSH 0
   @JMP __ex716_u53ea1f94_L5
:__ex716_u53ea1f94_L7
   @PUSH 1
:__ex716_u53ea1f94_L5

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

G main
@FUNCTION main
G __ex716_main_direct
G __ex716_main_far
:__ex716_main_direct
   @PUSH $__ex716_main_direct_return
   @JMP main
:__ex716_main_direct_return
   @PRT "EX716_MAIN_STATUS="
   @PRTTOP
   @PRTNL
   @POPNULL
   @END
:__ex716_main_far
   @FENTER
   @PUSH $__ex716_main_far_return
   @JMP main
:__ex716_main_far_return
   @FRET
:main
   @POPI __EX716_MAIN_RETURN
? CPU24_SEGMENTED
   @PUSH __DEND
ENDBLOCK
! CPU24_SEGMENTED
   @PUSH END__
ENDBLOCK
   @PUSH 0x0100
   @CMPS
   @POPNULL
   @POPNULL
   @JULT __ex716_stack_use_min
? CPU24_SEGMENTED
   @PUSH __DEND
ENDBLOCK
! CPU24_SEGMENTED
   @PUSH END__
ENDBLOCK
   @JMP __ex716_stack_heap_base_ready
:__ex716_stack_use_min
   @PUSH 0x0100
:__ex716_stack_heap_base_ready
   @DUP
   @PUSH 0xff00
   @SWP
   @SUBS
   @CALL HeapDefineMemory
   @DUP
   @IF_ULT_A 100
      @PRTLN "EX716: unable to initialize heap"
      @END
   @ENDIF
   @POPI __EX716_HEAP_ID
   @PUSHI __EX716_HEAP_ID
   @PUSH 4096
   @CALL HeapNewObject
   @IF_ULT_A 100
      @DUP
      @PRTHEXTOP
      @PRTNL
      @PRTLN "EX716: unable to allocate C stack"
      @END
   @ENDIF
   @POPNULL
   @DUP
   @ADD 4096
   @SWP
   @CALL SetSSStack
   @PUSHI __EX716_MAIN_RETURN
@PUSHRETURN
@CLocals 24
   @CLocalAt __ex716_off0 0
   @CLocalAt __ex716_off1 1
   @CLocalAt __ex716_off2 2
   @CLocalAt __ex716_off3 3
   @CLocalAt __ex716_off4 4
   @CLocalAt __ex716_off5 5
   @CLocalAt __ex716_off6 6
   @CLocalAt __ex716_off7 7
   @CLocalAt __ex716_off8 8
   @CLocalAt __ex716_off9 9
   @CLocalAt __ex716_off10 10
   @CLocalAt __ex716_off11 11
   @CLocalAt __ex716_off12 12
   @CLocalAt __ex716_off13 13
   @CLocalAt __ex716_off14 14
   @CLocalAt __ex716_off15 15
   @CLocalAt __ex716_off16 16
   @CLocalAt __ex716_off17 17
   @CLocalAt __ex716_off18 18
   @CLocalAt __ex716_off19 19
   @CLocalAt __ex716_off20 20
   @CLocalAt __ex716_off21 21
   @CLocalAt __ex716_off22 22
   @CLocalAt __ex716_off23 23
   @CLocalAt __ex716_off24 24
   @CLocalAt __ex716_u53ea1f94_main_local_0 0
   @CLocalAt __ex716_u53ea1f94_main_local_1 2
   @CLocalAt __ex716_u53ea1f94_main_local_2 4
   @CLocalAt __ex716_u53ea1f94_main_local_3 6
   @CLocalAt __ex716_u53ea1f94_main_local_4 8
   @CLocalAt __ex716_u53ea1f94_main_local_5 10
   @CLocalAt __ex716_u53ea1f94_main_local_6 12
   @CLocalAt __ex716_u53ea1f94_main_local_7 14
   @CLocalAt __ex716_u53ea1f94_main_local_8 16
   @CLocalAt __ex716_u53ea1f94_main_local_9 18
   @CLocalAt __ex716_u53ea1f94_main_local_10 20
   @CLocalAt __ex716_u53ea1f94_main_local_11 22

   @PUSH __ex716_u53ea1f94_static_9
   @PUSH32(A) $$$12345
   @PUSH 0
   @CALL MapInitialize
   @CPOPI __ex716_u53ea1f94_main_local_2
   @CPUSHI __ex716_u53ea1f94_main_local_2
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L26
   @PUSH 1
   @JMP __ex716_u53ea1f94_L25
:__ex716_u53ea1f94_L26
   @PUSH 0
   @CPOPI __ex716_u53ea1f94_main_local_0
:__ex716_u53ea1f94_L28
   @PUSH __ex716_u53ea1f94_static_9
   @PUSH 100
   @PUSH 120
   @PUSH 10
   @CALL MapAddMountainRange
   @CPOPI __ex716_u53ea1f94_main_local_3
   @CPUSHI __ex716_u53ea1f94_main_local_3
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L32
   @PUSH 2
   @JMP __ex716_u53ea1f94_L25
:__ex716_u53ea1f94_L32
:__ex716_u53ea1f94_L29
   @CPUSHI __ex716_u53ea1f94_main_local_0
   @PUSH 1
   @ADDS
   @CPOPI __ex716_u53ea1f94_main_local_0
   @CPUSHI __ex716_u53ea1f94_main_local_0
   @PUSH 4
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_u53ea1f94_L28
   @PUSH __ex716_u53ea1f94_static_11
   @PUSH __ex716_u53ea1f94_static_10
   @PUSH 16
   @CALL SettlementListInitialize
   @PUSH __ex716_u53ea1f94_static_9
   @PUSH 24
   @CALL MapClassifyTerrain
   @CPOPI __ex716_u53ea1f94_main_local_4
   @CPUSHI __ex716_u53ea1f94_main_local_4
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPZ __ex716_u53ea1f94_L38
   @PUSH __ex716_u53ea1f94_static_9
   @PUSH 80
   @PUSH 8
   @CALL MapAddRivers
   @CPOPI __ex716_u53ea1f94_main_local_5
   @CPUSHI __ex716_u53ea1f94_main_local_5
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_u53ea1f94_L38
   @PUSH __ex716_u53ea1f94_static_9
   @PUSH 30
   @CALL MapAddForests
   @CPOPI __ex716_u53ea1f94_main_local_6
   @CPUSHI __ex716_u53ea1f94_main_local_6
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JLT __ex716_u53ea1f94_L38
   @PUSH __ex716_u53ea1f94_static_9
   @PUSH __ex716_u53ea1f94_static_11
   @PUSH 12
   @CALL MapAddSettlements
   @CPOPI __ex716_u53ea1f94_main_local_7
   @CPUSHI __ex716_u53ea1f94_main_local_7
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JGE __ex716_u53ea1f94_L34
:__ex716_u53ea1f94_L38
   @PUSH 3
   @JMP __ex716_u53ea1f94_L25
:__ex716_u53ea1f94_L34
   @PUSH __ex716_u53ea1f94_static_57
   @PUSH __ex716_u53ea1f94_static_58
   @CALL fopen
   @CPOPI __ex716_u53ea1f94_main_local_8
   @CPUSHI __ex716_u53ea1f94_main_local_8
   @CPOPI __ex716_u53ea1f94_main_local_1
   @CPUSHI __ex716_u53ea1f94_main_local_1
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L41
   @PUSH 4
   @JMP __ex716_u53ea1f94_L25
:__ex716_u53ea1f94_L41
   @CPUSHI __ex716_u53ea1f94_main_local_1
   @CALL __ex716_u53ea1f94_static_13
   @CPOPI __ex716_u53ea1f94_main_local_9
   @CPUSHI __ex716_u53ea1f94_main_local_9
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L43
   @CPUSHI __ex716_u53ea1f94_main_local_1
   @CALL fclose
   @POPNULL
   @PUSH 5
   @JMP __ex716_u53ea1f94_L25
:__ex716_u53ea1f94_L43
   @CPUSHI __ex716_u53ea1f94_main_local_1
   @CALL fclose
   @CPOPI __ex716_u53ea1f94_main_local_11
   @CPUSHI __ex716_u53ea1f94_main_local_11
   @PUSH 0
   @CMPS
   @POPNULL
   @POPNULL
   @JMPNZ __ex716_u53ea1f94_L46
   @PUSH 0
   @CPOPI __ex716_u53ea1f94_main_local_10
   @JMP __ex716_u53ea1f94_L47
:__ex716_u53ea1f94_L46
   @PUSH 6
   @CPOPI __ex716_u53ea1f94_main_local_10
:__ex716_u53ea1f94_L47
   @CPUSHI __ex716_u53ea1f94_main_local_10
:__ex716_u53ea1f94_L25

@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

::__ex716_u53ea1f94_static_11 $$0 * 6
::__ex716_u53ea1f94_static_10 $$0 * 128
::__ex716_u53ea1f94_static_9 $$0 * 112
G MapChecksum
G MapAddSettlements
G MapFindSettlement
G SettlementListInitialize
G MapAddForests
G MapAddRivers
G MapClassifyTerrain
G MapSmooth
G MapAddMountainRange
G MapRandomBelow
G MapRandom
G MapGetCell
G MapSetCell
G MapInitialize
G ex716_far_put16v
G ex716_far_get16v
G ex716_far_put16
G ex716_far_get16
G snprintf
G vsnprintf
G vsprintf
G vfprintf
G vprintf
G sprintf
G fprintf
G printf
G fwrite
G fread
G fclose
G fopen
G fflush
G ungetc
G clearerr
G ferror
G feof
G fgets
G puts
G fputs
G getc
G putc
G fgetc
G fputc
G getchar
G putchar
G stderr
G stdout
G stdin
::__ex716_u53ea1f94_static_58 $$119
::__ $$98
::__ $$0
::__ex716_u53ea1f94_static_57 $$77
::__ $$65
::__ $$80
::__ $$77
::__ $$65
::__ $$75
::__ $$69
::__ $$82
::__ $$46
::__ $$77
::__ $$65
::__ $$80
::__ $$0

