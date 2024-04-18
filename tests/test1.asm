# Test Basic Functions
I common.mc
# List of all core OPS
# NOP PUSH DUP PUSHI PUSHII PUSHS POPNULL SWP POPI POPII POPS
# CMP CMPS CMPI CMPII ADD ADDS ADDI ADDII SUB SUBS SUBI SUBII
# OR ORS ORI ORII AND ANDS ANDI ANDII XOR XORS XORI XORII JMPZ
# JMPN JMPC JMPO JMP JMPI JMPS CAST POLL RRTC RLTC RTR RTL
# INV COMP2 FCLR FSAV FLOD
#
M RePort @CALL RePort
M SetVal @CALL SetVal
#
#
=Constant 0x100
:Var1 0x1001
:Var2 0x2002
:Var3 0x3003
:Ref1 Var1
:Ref2 Var2
:Ref3 Var3
. 0x500
:Main . Main
@PRTLN "Test Ops"
@PRTLN "---------------"
@PRTLN "NOP: "
:Break1
@SetVal
@PRT "Before: " @RePort
@NOP
:Break2
@PRT "After: " @RePort
@PRTLN "---------------"
@PRTLN "PUSH 0x100"
:Break3
@SetVal
@PUSH 0x100
@PRT "After:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "[1 2] DUP"
@SetVal
@PUSH 1 @PUSH 2
@PRT "Before: " @RePort
@DUP
@PRT "After:" @RePort
@POPNULL @POPNULL @POPNULL
@PRTLN "---------------"
@PRTLN "PUSHI Var1;PushI Var2"
@SetVal
@PRT "Before: " @RePort
@PUSHI Var1 @PUSHI Var2
@PRT "After:" @RePort
@POPNULL @POPNULL
@PRTLN "---------------"
@PRTLN "PUSHII Ref1; PUSHII Ref2"
@SetVal
@PRT "Before: " @RePort
@PUSHII Ref1 @PUSHII Ref2
@PRT "After:" @RePort
@POPNULL @POPNULL
@PRTLN "---------------"
@PRTLN "[Ref1] PUSHS"
@SetVal
@PUSH Ref1
@PRT "Before: " @RePort
@PUSHS
@PRT "After: " @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "[101] POPNULL"
@SetVal
@PUSH 101
@PRT "Before: " @RePort
@POPNULL
@PRT "After: " @RePort
@PRTLN "---------------"
@PRTLN "[101 202] SWP"
@SetVal
@PUSH 101 @PUSH 202
@PRT "Before:" @RePort
@SWP
@PRT "After:" @RePort
@POPNULL @POPNULL
@PRTLN "---------------"
@PRTLN "[Var1] POPI"
@SetVal
@PUSH 1
@PRT "Before:" @RePort
@POPI Var1
@PRT "After:" @RePort
@PRTLN "---------------"
@PRTLN "POPII"
@SetVal
@PUSH 101
@PRT "Before:" @RePort
@POPII Ref1
@PRT "After:" @RePort
@PRTLN "---------------"
@PRTLN "POPS"
@SetVal
@PUSH 102 @PUSH Var1
@PRT "Before:" @RePort
@POPS
@PRT "After:" @RePort
@PRTLN "---------------"
@PRTLN "CMP 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100
@PRT "Before:" @RePort
@CMP 0x100
@PRT "After CMP 0x100:" @RePort
@CMP 0x50
@PRT "After CMP 0x50:" @RePort
@CMP 0x200
@PRT "After CMP 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "CMPS 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100 @PUSH 0x100
@PRT "Before:" @RePort
@CMPS
@PRT "After CMPS 0x100:" @RePort
@POPNULL @PUSH 0x50
@CMPS
@PRT "After CMPS 0x50:" @RePort
@POPNULL @PUSH 0x200
@CMPS
@PRT "After CMPS 0x200:" @RePort
@POPNULL @POPNULL
@PRTLN "---------------"
@PRTLN "CMPI 0x100 vs Var1,Var2,Var3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@CMPI Var1
@PRT "After CMPI Var1:" @RePort
@CMPI Var2
@PRT "After CMPI Var2:" @RePort
@CMPI Var3
@PRT "After CMPI Var3:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "CMPII 0x100 vs Ref11,Ref2,Ref3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@CMPI Ref1
@PRT "After CMPII Ref1:" @RePort
@CMPI Ref2
@PRT "After CMPII Ref2:" @RePort
@CMPI Ref3
@PRT "After CMPII Ref3:" @RePort
@POPNULL
#########
@PRTLN "---------------"
@PRTLN "ADD 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100
@PRT "Before:" @RePort
@ADD 0x100
@PRT "After ADD 0x100:" @RePort
@POPNULL @PUSH 0x100
@ADD 0x50
@PRT "After ADD 0x50:" @RePort
@POPNULL @PUSH 0x100
@ADD 0x200
@PRT "After ADD 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ADDS 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100 @PUSH 0x100
@PRT "Before:" @RePort
@ADDS
@PRT "After ADDS 0x100:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x50
@ADDS
@PRT "After ADDS 0x50:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x200
@ADDS
@PRT "After ADDS 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ADDI 0x100 vs Var1,Var2,Var3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@ADDI Var1
@PRT "After ADDI Var1:" @RePort
@POPNULL @PUSH 0x100
@ADDI Var2
@PRT "After ADDI Var2:" @RePort
@POPNULL @PUSH 0x100
@ADDI Var3
@PRT "After ADDI Var3:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ADDII 0x100 vs Ref11,Ref2,Ref3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@ADDI Ref1
@PRT "After ADDII Ref1:" @RePort
@POPNULL @PUSH 0x100
@ADDI Ref2
@PRT "After ADDII Ref2:" @RePort
@POPNULL @PUSH 0x100
@ADDI Ref3
@PRT "After ADDII Ref3:" @RePort
@POPNULL
#################
@PRTLN "---------------"
@PRTLN "SUB 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100
@PRT "Before:" @RePort
@SUB 0x100
@PRT "After SUB 0x100:" @RePort
@POPNULL @PUSH 0x100
@SUB 0x50
@PRT "After SUB 0x50:" @RePort
@POPNULL @PUSH 0x100
@SUB 0x200
@PRT "After SUB 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "SUBS 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100 @PUSH 0x100
@PRT "Before:" @RePort
@SUBS
@PRT "After SUBS 0x100:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x50
@SUBS
@PRT "After SUBS 0x50:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x200
@SUBS
@PRT "After SUBS 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "SUBI 0x100 vs Var1,Var2,Var3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@SUBI Var1
@PRT "After SUBI Var1:" @RePort
@POPNULL @PUSH 0x100
@SUBI Var2
@PRT "After SUBI Var2:" @RePort
@POPNULL @PUSH 0x100
@SUBI Var3
@PRT "After SUBI Var3:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "SUBII 0x100 vs Ref11,Ref2,Ref3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@SUBII Ref1
@PRT "After SUBII Ref1:" @RePort
@POPNULL @PUSH 0x100 @SUBII Ref2
@PRT "After SUBII Ref2:" @RePort
@POPNULL @PUSH 0x100 @SUBII Ref3
@PRT "After SUBII Ref3:" @RePort
@POPNULL
######################
@PRTLN "---------------"
@PRTLN "OR 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100
@PRT "Before:" @RePort
@OR 0x100
@PRT "After OR 0x100:" @RePort
@POPNULL @PUSH 0x100
@OR 0x50
@PRT "After OR 0x50:" @RePort
@POPNULL @PUSH 0x100
@OR 0x200
@PRT "After OR 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ORS 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100 @PUSH 0x100
@PRT "Before:" @RePort
@ORS
@PRT "After ORS 0x100:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x50
@ORS
@PRT "After ORS 0x50:" @RePort
@PUSH 0x100 @PUSH 0x200
@ORS
@PRT "After ORS 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ORI 0x100 vs Var1,Var2,Var3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@ORI Var1
@PRT "After ORI Var1:" @RePort
@POPNULL @PUSH 0x100
@ORI Var2
@PRT "After ORI Var2:" @RePort
@POPNULL @PUSH 0x100
@ORI Var3
@PRT "After ORI Var3:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ORII 0x100 vs Ref11,Ref2,Ref3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@ORI Ref1
@PRT "After ORII Ref1:" @RePort
@POPNULL @PUSH 0x100
@ORI Ref2
@PRT "After ORII Ref2:" @RePort
@POPNULL @PUSH 0x100
@ORI Ref3
@PRT "After ORII Ref3:" @RePort
@POPNULL
#####################
@PRTLN "---------------"
@PRTLN "AND 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100
@PRT "Before:" @RePort
@AND 0x100
@PRT "After AND 0x100:" @RePort
@POPNULL @PUSH 0x100
@AND 0x50
@PRT "After AND 0x50:" @RePort
@POPNULL @PUSH 0x100
@AND 0x200
@PRT "After AND 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ANDS 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100 @PUSH 0x100
@PRT "Before:" @RePort
@ANDS
@PRT "After ANDS 0x100:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x50
@ANDS
@PRT "After ANDS 0x50:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x200
@ANDS
@PRT "After ANDS 0x200:" @RePort

@POPNULL
@PRTLN "---------------"
@PRTLN "ANDI 0x100 vs Var1,Var2,Var3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@ANDI Var1
@PRT "After ANDI Var1:" @RePort
@POPNULL @PUSH 0x100
@ANDI Var2
@PRT "After ANDI Var2:" @RePort
@POPNULL @PUSH 0x100
@ANDI Var3
@PRT "After ANDI Var3:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "ANDII 0x100 vs Ref11,Ref2,Ref3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@ANDI Ref1
@PRT "After ANDII Ref1:" @RePort
@POPNULL @PUSH 0x100
@ANDI Ref2
@PRT "After ANDII Ref2:" @RePort
@POPNULL @PUSH 0x100
@ANDI Ref3
@PRT "After ANDII Ref3:" @RePort
@POPNULL
########################
@PRTLN "---------------"
@PRTLN "XOR 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100
@PRT "Before:" @RePort
@XOR 0x100
@PRT "After XOR 0x100:" @RePort
@POPNULL @PUSH 0x100
@XOR 0x50
@PRT "After XOR 0x50:" @RePort
@POPNULL @PUSH 0x100
@XOR 0x200
@PRT "After XOR 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "XORS 0x100 vs 0x100,50,200"
@SetVal
@PUSH 0x100 @PUSH 0x100
@PRT "Before:" @RePort
@XORS
@PRT "After XORS 0x100:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x50
@XORS
@PRT "After XORS 0x50:" @RePort
@POPNULL @PUSH 0x100 @PUSH 0x200
@XORS
@PRT "After XORS 0x200:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "XORI 0x100 vs Var1,Var2,Var3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@XORI Var1
@PRT "After XORI Var1:" @RePort
@POPNULL @PUSH 0x100
@XORI Var2
@PRT "After XORI Var2:" @RePort
@POPNULL @PUSH 0x100
@XORI Var3
@PRT "After XORI Var3:" @RePort
@POPNULL
@PRTLN "---------------"
@PRTLN "XORII 0x100 vs Ref11,Ref2,Ref3
@SetVal
@MA2V 0x100 Var1
@MA2V 0x50 Var2
@MA2V 0x200 Var3
@PUSH 0x100
@PRT "Before:" @RePort
@XORI Ref1
@PRT "After XORII Ref1:" @RePort
@POPNULL @PUSH 0x100
@XORI Ref2
@PRT "After XORII Ref2:" @RePort
@POPNULL @PUSH 0x100
@XORI Ref3
@PRT "After XORII Ref3:" @RePort
@POPNULL
#########################
@PRTLN "---------------"
@PRTLN "JMPZ"
@SetVal
@PUSH 0x100 @SUB 0x100 @POPNULL
@PRT "Before JMPZ:" @RePort
@JMPZ Succ01
@PRTLN "Fail"
@JMP Next01
:Succ01
@PRTLN "Success"
:Next01
@PRT "After:" @RePort
@PRTLN "---------------"
@PRTLN "JMPN"
@SetVal
@PUSH 0x100 @SUB 0x200 @POPNULL
@PRT "Before JMPN:" @RePort
@JMPN Succ02
@PRTLN "Fail"
@JMP Next02
:Succ02
@PRTLN "Success"
:Next02
@PRT "After:" @RePort
@PRTLN "---------------"
@PRTLN "JMPC"
@SetVal
@PUSH 0x8001 @ADD 0x8001 @POPNULL
@PRT "Before JMPC:" @RePort
@JMPC Succ03
@PRTLN "Fail"
@JMP Next03
:Succ03
@PRTLN "Success"
:Next03
@PRT "After:" @RePort

@PRTLN "---------------"
@PRTLN "JMPO"
@SetVal
@PUSH 0x8000 @ADD 0xffff @POPNULL
@PRT "Before JMPO:" @RePort
@JMPO Succ04
@PRTLN "Fail"
@JMP Next04
:Succ04
@PRTLN "Success"
:Next04
@PRT "After:" @RePort
@PRTLN "END"
@END
#
# Report funciton
:RePort
@POPI ReturnVal
@PRT "V1:" @PRTHEXI Var1
@PRT " V2:" @PRTHEXI Var2
@PRT " V3:" @PRTHEXI Var3
@PRT " R1:" @PRTHEXI Ref1
@PRT " R2:" @PRTHEXI Ref2
@PRT " R3:" @PRTHEXI Ref3
@PRT " "
@IF_ZFLAG
  @PRT "Z"
@ELSE
  @PRT "_"
@ENDIF
@IF_NEG
  @PRT "N"
@ELSE
  @PRT "_"
@ENDIF
@IF_CARRY
  @PRT "C"
@ELSE
  @PRT "_"
@ENDIF
@IF_OVERFLOW
  @PRT "O"
@ELSE
  @PRT "_"
@ENDIF
#@PRT " tos:" @SWP @PRTHEXTOP @SWP @PRTNL
@StackDump
@PUSHI ReturnVal
@RET
:ReturnVal 0
#
#
# Function reset values
:SetVal
@MA2V 0x1001 Var1
@MA2V 0x2002 Var2
@MA2V 0x3003 Var3
@FCLR
@RET



