# this is just test calls to check the individual fat16 functions
I common.mc
I fat16code.asm      # Use I rather than I so I can view all the variables.

:ExternalHeap 0
:ExternalFile1 0
:DebugCount 0



:Init
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI ExternalHeap
# Expands the Soft Stack so we can use deeper recursion, about 1K should do for now.
@PUSHI ExternalHeap @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1  #0
@PRT "NewObject: Stack: " @PRTHEXTOP @PRTNL
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
@RET

#
#
#
:Main . Main
@MA2V 0 DebugCount
@CALL Init
#
@PUSHI ExternalHeap
@CALL initdisk
#
@PUSH 0
@CALL readBootRecord
#
@STRSTACK "/test2.txt"
@POPI ExternalFile1
#
@PUSHI ExternalFile1
@PUSH 0
@PRT "Debug Count:" @PRTI DebugCount  @StackDump @INCI DebugCount
@CALL ParsePath
@PRT "Debug Count:" @PRTI DebugCount  @StackDump @INCI DebugCount


         @StackDump
         @PUSHI ExternalHeap
         @CALL HeapListMap   
         :Break01

@END
:ErrorExit
@PRT "Error" @StackDump
@END
:ENDOFCODE
