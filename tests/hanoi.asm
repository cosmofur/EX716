I common.mc
L heapmgr.ld
L softstack.ld

:ExternalHeap 0

:Var01 0 :Var02 0 :Var03 0 :Var04 0 :Var05 0 :Var06 0 :Var07 0 :Var08 0
:Aheight 0 :Bheight 0 :Cheight 0 :MaxHeight 0

:Init
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI ExternalHeap
# Expands the Soft Stack so we can use deeper recursion, about 1K should do for now.
@PUSHI ExternalHeap @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1  #0
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
@RET
:ErrorExit
@PRTLN "Memory Error"
@END



###########################################
# Function hanoi(number, fromRod, toRod, auxRod, Aheight,Bheight,Cheight)
# This is a demostration of tower of hanoi recursion
# using the soft stack
#
:hanoi
@PUSHRETURN
=inNumber Var01
=fromRod Var02
=toRod Var03
=auxRod Var04

@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@POPI auxRod
@POPI toRod
@POPI fromRod
@POPI inNumber
#@PRT "TOP) A:" @PRTI Aheight @PRT " B:" @PRTI Bheight @PRT " C:" @PRTI Cheight @PRTNL
# @PRT "From Rod:"
# @IF_EQ_AV 1 fromRod
#     @PRT "A"
# @ELSE
#     @IF_EQ_AV 2 fromRod
#         @PRT "B"
#     @ELSE
#         @PRT "C"
#     @ENDIF
# @ENDIF
# @PRT " To Rod:"
# @IF_EQ_AV 1 toRod
#     @PRT "A"
# @ELSE
#     @IF_EQ_AV 2 toRod
#         @PRT "B"
#     @ELSE
#         @PRT "C"
#     @ENDIF
# @ENDIF
# @PRTNL
@IF_EQ_AV 1 inNumber
   @PRT "Move disk 1 from rod " @PRTI fromRod @PRT " to rod " @PRTI toRod @PRTNL
   @PUSHI fromRod
   @PUSHI toRod
   @CALL UpdateRodDepths
   @CALL Fancy   
@ELSE
   @PUSHI inNumber @SUB 1
   @PUSHI fromRod
   @PUSHI auxRod
   @PUSHI toRod
   @CALL hanoi
   @PRT "Move disk " @PRTI inNumber @PRT " from rod " @PRTI fromRod @PRT " to rod " @PRTI toRod @PRTNL
   @PUSHI fromRod
   @PUSHI toRod
   @CALL UpdateRodDepths
   @CALL Fancy
   @PUSHI inNumber @SUB 1
   @PUSHI auxRod
   @PUSHI toRod
   @PUSHI fromRod
   @CALL hanoi
@ENDIF
#@PRT "LAST) A:" @PRTI Aheight @PRT " B:" @PRTI Bheight @PRT " C:" @PRTI Cheight @PRTNL

@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

#########################################################
# Function UpdateRodDepths(RodNumber, ToRod)
:UpdateRodDepths
@PUSHRETURN
=FromOne Var01
=ToOne  Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI ToOne
@POPI FromOne
@PUSHI FromOne
@SWITCH
@CASE 1
   @DECI Aheight
   @CBREAK
@CASE 2
   @DECI Bheight
   @CBREAK
@CASE 3
   @DECI Cheight
   @CBREAK
@CDEFAULT
   @PRT "Bad Rod"
   @CBREAK
@ENDCASE
@POPNULL
@PUSHI toRod
@SWITCH
@CASE 1
   @INCI Aheight
   @CBREAK
@CASE 2
   @INCI Bheight
   @CBREAK
@CASE 3
   @INCI Cheight
   @CBREAK
@CDEFAULT
   @PRT "Bad Rod"
   @CBREAK
@ENDCASE
@POPNULL
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###################################################
# Function Print Fancy format
# Fancy
:Fancy
@PUSHRETURN
=Index01 Var01
=Index02 Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
#
@PRT "A:" @PRTI Aheight @PRT " B:" @PRTI Bheight @PRT " C:" @PRTI Cheight @PRTNL
@ForIV2A Index01 MaxHeight 0
   @PUSHI MaxHeight @RTL @ADD 3
   @PUSHI Index01   @PUSHI Aheight
   @IF_LE_S
      @POPNULL @POPNULL
      @PUSHI MaxHeight @SUBI Index01 @ADD 1
   @ELSE
      @POPNULL @POPNULL
      @PUSH 0
   @ENDIF
   @RTL
   @CALL FancyLine

   @PUSHI MaxHeight @RTL @ADD 3
   @PUSHI Index01   @PUSHI Bheight
   @IF_LE_S
      @POPNULL @POPNULL
      @PUSHI MaxHeight @SUBI Index01 @ADD 1
   @ELSE
      @POPNULL @POPNULL
      @PUSH 0
   @ENDIF
   @RTL
   @CALL FancyLine

   @PUSHI MaxHeight @RTL @ADD 3
   @PUSHI Index01   @PUSHI Cheight
   @IF_LE_S
      @POPNULL @POPNULL
      @PUSHI MaxHeight @SUBI Index01 @ADD 1
   @ELSE
      @POPNULL @POPNULL
      @PUSH 0
   @ENDIF
   @RTL
   @CALL FancyLine


@PRTNL
@NextBy Index01 -1
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


    



####################################################
# Function Print fancyLine
# Center a '#' line of space length inside line of space Width wide.
# FancyLine(Width,Space)
:FancyLine
@PUSHRETURN
=Index01 Var01
=Width Var02
=Space Var03
=GroupSpace Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@POPI Space
@POPI Width
#
# First write Width/2-space/2 spaces
@PUSHI Width @RTR
@PUSHI Space @RTR
@SUBS
@POPI GroupSpace
@ForIA2V Index01 0 GroupSpace
   @PRTSP
@Next Index01
#
# Draw the '#' line
@ForIA2V Index01 0 Space
   @PRT "#"
@Next Index01
#
# Finish up with the remaining spaces.
@PUSHI Width @RTR
@PUSHI Space @RTR
@SUBS
@POPI GroupSpace
@ForIA2V Index01 0 GroupSpace
   @PRTSP
@Next Index01
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET







:Main . Main
    @PRT "Number of Disks: "
    @READI Aheight
    @MV2V Aheight MaxHeight    
    @CALL Init
    @PUSHI MaxHeight
    @PUSH 1
    @PUSH 2
    @PUSH 3
#    @PUSH 3 @PUSH 0 @PUSH 0
   @CALL Fancy
    @CALL hanoi
    @END
    




:ENDOFCODE
