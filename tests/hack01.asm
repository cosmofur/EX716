I common.mc
L screen.ld
L softstack.ld
L heapmgr.ld
L random.ld
#################################################
:MainHeap 0
:CurrentMap 0
#############################################
# Function InitMem
# Initilzie Memory
:InitMem
:MInit
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeap
@PUSHI MainHeap @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 24" @END @ENDIF
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
@IF_EQ_AV 0 RESIZEABLE
  # ALlowing resizing makes debugging a bit harder, so set Macro Variable if you need it.
  @MA2V 24 WinWidth
  @MA2V 20 WinHeight
@ELSE
  @CALL WinResize
@ENDIF
@RET
###################################################
# Function BuildAdventure(Seed,Depth):HeapTable
# Generates an 'adventure' which is a multi path tree.
# Each node up to 'Depth' deep can have 1 to 4 child nodes.
# Child nodes can/will be locked but the keys will alway be found at
# either a parent node, or a down a sibling node which already had a reachable key.
#
# So the 
