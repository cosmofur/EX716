# this is just test calls to check the individual fat16 functions
I common.mc
I fat16code.asm      # Use I rather than I so I can view all the variables.
L lmath.ld

:ExternalHeap 0
:ExternalFile1 0
:FP 0
:FileBuffer 0
:File32Address $$$100  # Setup 32 bit address to byte 100 in file for FSeek.
#############################################################
# Function ErrorExit
:ErrorExit
@StackDump
@END

##############################################################
# Function Init
#  Setup softstack and heap.
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

##############################################################
# Main
#  Main Entrance point
:Main . Main
# Initilize disk system
@CALL Init @PUSHI ExternalHeap @CALL initdisksys 
#
@PUSH 0           # Select Disk 0
@CALL readBootRecord
#
#
# FP=FileOpen(Filename,"rw")
@STRSTACK "/foo" @PUSH "rw"
@CALL FileOpen
@POPI FP
#
#
#
# Alloc 1024 byte buffer for reading file records.
@PUSHI ExternalHeap @PUSH 1024 @CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF
@POPI FileBuffer
#
# Read File Until End.
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   @PUSHI FP  @PUSHI FileBuffer     @CALL ReadLine
   @PRT "<"   @PRTSI FileBuffer    @PRT ">\n"
@ENDWHILE
@POPNULL
@PRT "Heap Info:" @PUSHI ExternalHeap @CALL HeapListMap @PRTNL
@END
:ENDOFCODE

