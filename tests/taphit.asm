I common.mc
L softstack.ld
L random.ld
L heapmgr.ld
L screen.ld
L timetool.ld
#
#
# Static Variables
:MainHeapID 0
:RootObject 0
:TimeDelta 0

#
#############################################################################
# Function Init, setup heap and memory
:Init
# Defined memory between endofcode and 0xf000 as available
@PUSH ENDOFCODE @PUSH 0xf000 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeapID
#
# Expands the Soft Stack so we can use deeper recursion, about 1K should do for now.
@PUSHI MainHeapID @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
#
# The 'Root' Obejct will always just contain the ID of 0, and one pointer to first available room.
@PUSHI MainHeapID @PUSH 4
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 2 @CALL ErrorExit @ENDIF   # Error code 2
@POPI RootObject
@PUSH 0 @POPII RootObject                 # Zero the two words of RootObject.
@PUSH 0 @PUSHI RootObject @ADD 2 @POPS
#
@CALL WinClear
@CALL RunIntro
@RET
###########################################################################
# Function ErrorExit
:ErrorExit
@TTYECHO
@PRT "From Location: " @PRTHEXTOP
@POPNULL
@PRT " Error Code: " @PRTTOP
@PRTNL
@POPNULL
@END

###########################################################################
# Function RunIntro
:RunIntro
@PUSHRETURN
#
=UserKey Var01
=SeedCount Var02
=TimeCount Var03
@PUSHLOCALI UserKey
@PUSHLOCALI SeedCount
@PUSHLOCALI TimeCount

#
@PRTLN "Intro:...."
@PRT "Bla...Bla...Bla\n"
@PRT "Bla...Bla...Bla\n"
@PRT "Bla...Bla...Bla\n"
@PUSH 1 @CALL Sleep
@PRT "\n\nHit Any Key to Continue."
@TTYNOECHO
# First When is to 'drain' and keybuffer
@WHEN
   @READCNW UserKey
   @PUSHI UserKey
   @DO_NOTZERO
      @POPNULL
@ENDWHEN
@POPNULL
@WHEN
   @IF_EQ_AV -1 TimeCount
      # Reached end already
   @ELSE
      @GETTIME
      @POPNULL
      @IF_UGT_V TimeDelta
          @POPNULL
          @MV2V TimeCount TimeDelta
          @MA2V -1 TimeCount
      @ELSE
          @POPNULL
          @INCI TimeCount
      @ENDIF
   @ENDIF
   @READCNW UserKey
   @PUSHI UserKey
   @IF_EQ_AV 0 UserKey
   @ELSE
      @PRTSTR UserKey
   @ENDIF
   @DO_ZERO
      @POPNULL
      @INCI SeedCount
@ENDWHEN
@IF_EQ_AV -1 TimeCount
   # Then TimeDelta has the real TimeCount for 5 secnds.
@ELSE
   # Else we didn't stay in the loop long enough for 5 seconds.
   @WHEN
      @GETTIME
      @POPNULL
      @IF_UGT_V TimeDelta
          @POPNULL
          @MV2V TimeCount TimeDelta
          @PUSH 0
      @ELSE
          @POPNULL
          @PUSH 1
      @ENDIF
      @DO_NOTZERO   
   @ENDWHEN
@ENDIF
@POPNULL
@TTYECHO
@PUSHI SeedCount @ADDI UserKey @AND 0x7fff
@CALL rndsetseed
@POPLOCAL TimeCount
@POPLOCAL SeedCount
@POPLOCAL UserKey
@POPRETURN
@RET
#
:Main . Main
=XPostion Var01
=BarSize Var02
=Direction Var03
=RightLimit Var04
=LeftLimit Var05
@CALL Init
@MA2V 10 XPostion
@MA2V 1 Direction
@MA2V 0 BarSize
@MA2V 70 RightLimit
@MA2V 10 LeftLimit
@PUSH 1
@WHILE_NOTZERO
   @PRT "Top: " @StackDump
   @PUSH 0 @PUSH 0 @CALL WinCursor
   @PRTI BarSize @PRTSP @PRTI XPostion
   @PUSHI BarSize   
   @PUSHI XPostion
   @PUSH 10   
   @CALL DrawBar
   @PUSHI XPostion @ADDI Direction @POPI XPostion
   @PUSHI XPostion
   @IF_LT_V LeftLimit
       @MA2V 1 Direction
   @ENDIF
   @IF_GT_V RightLimit
       @MA2V -1 Direction
       @INCI BarSize
       @PUSHI BarSize
       @IF_GE_A 4
          @MA2V 0 BarSize
       @ENDIF
       @POPNULL
   @ENDIF
   @POPNULL
   @PUSH 50
   @CALL SleepMilli
@ENDWHILE
@END

#########################################################################
# Function DrawBar(TargetID, Postion, Row)
:DrawBar
@PUSHRETURN
=TargetID Var01
=PostionCenter Var02
=BarIndex Var03
=BarString Var04
=PostionRow Var05
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
#
@POPI PostionRow
@POPI PostionCenter
@POPI TargetID
#
@PUSH TargetArray @ADDI TargetID @ADDI TargetID
@PUSHS
@POPI BarIndex
@PUSHI BarIndex @ADD 2 @POPI BarString
#
# Clear Line
@PUSH 0 @PUSHI PostionRow @CALL WinCursor
@PRTS CISCODE @PRT "2K"   # Ansi code erase current line
@PUSHII BarIndex @SHR
@ADDI PostionCenter
@SUBII BarIndex
@PUSHI PostionRow @CALL WinCursor
:Break1
@PRTSI BarString
#
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
:TargetArray
L10 L8 L6 L4
:L10 10 "##########\0"
:L8 8 "########\0"
:L6 6 "######\0
:L4 4 "####\0"




:ENDOFCODE
