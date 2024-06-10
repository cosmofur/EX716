I common.mc
L softstack.ld
L random.ld
L heapmgr.ld
L fat16lib.ld
#
#
# Dynamic Variables
:Var01 0 :Var02 0 :Var03 0 :Var04 0 :Var05 0 :Var06 0
:Var07 0 :Var08 0 :Var09 0 :Var10 0 :Var11 0 :Var12 0
# Static Variables
:MainHeapID 0
:RootObject 0
:RootDirInfo 0
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
#
@PUSH 0 @POPII RootObject                 # Zero the two words of RootObject.
@PUSH 0 @PUSHI RootObject @ADD 2 @POPS
#
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
@PUSHLOCALI UserKey
@PUSHLOCALI SeedCount
#
@PRTLN "Intro:...."
@PRT "Bla...Bla...Bla\n"
@PRT "Bla...Bla...Bla\n"
@PRT "Bla...Bla...Bla\n"
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
@POPNULL
@TTYECHO
@PUSHI SeedCount @ADDI UserKey @AND 0x7fff
@PRT "Random Seed: " @PRTTOP @PRTNL
@CALL rndsetseed
@POPLOCAL SeedCount
@POPLOCAL UserKey
@POPRETURN
@RET
#
:BufferPtr 0

:Main . Main
@CALL Init
@PRTLN "Start:"
@PUSH 0 @PUSHI MainHeapID
@CALL SelectDisk
@POPI BufferPtr
@CALL ReportParseBootSector
@CALL ReadRootDir
@POPI RootDirInfo
:Break1
@PUSHI RootDirInfo
@CALL ListRootDir



@PRT "1 =" @PUSH 1 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "2 =" @PUSH 2 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "3 =" @PUSH 3 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "4 =" @PUSH 4 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "5 =" @PUSH 5 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@END





:ENDOFCODE

