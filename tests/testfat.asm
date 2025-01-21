# this is just test calls to check the individual fat16 functions
I common.mc
I fat16code.asm      # Use I rather than I so I can view all the variables.
L lmath.ld

:ExternalHeap 0
:ExternalFile1 0
:FP 0
:FileBuffer 0
:File32Address $$$100  # Setup 32 bit address to byte 100 in file for FSeek.
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
@CALL Init
#
@PUSHI ExternalHeap
@CALL initdisk
#
@PUSH 0           # Select Disk 0
@CALL readBootRecord
#
@STRSTACK "/test3.bin"      # Set up string with filename.
@POPI ExternalFile1
#
@PUSHI ExternalFile1        
@PUSH 0                     # Start search at root DIR

@CALL ParsePath
@IF_ZERO
   @PRT "File Could not be Parsed."
@ELSE
@POPI FP

#
# Create a common Buffer for data

@PUSHI ExternalHeap @PUSH 0x200
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1  #0
@POPI FileBuffer
#
# Diffrent types of 'Reads'
#
# ReadSector(FP,LogicalSector,Buffer):Size_Read
#
@PUSHI FP @PUSH 2 @PUSHI FileBuffer
@CALL ReadSector
@IF_LT_A 512
   @PRT "Reached End Of File: "
@ENDIF
@POPNULL
@PRT "ReadSector: \n"
@PRTSI FileBuffer
@PRTNL
#
#
# FSEEK(FP,Ptr-32bit)
@PUSHI FP @PUSHI File32Address
@CALL FSEEK
@IF_ZERO
   @PRT "Error in FSEEK\n"
@ENDIF
@POPNULL
@PRT "Fseek to: " @PRT32I File32Address @PRTNL
@PRTNL
#
# 
# ReadLine(FP,Buffer):Size_Read
@PUSHI FP @PUSHI FileBuffer
@CALL ReadLine
@IF_LT_A 512
   @PRT "Reached End Of File: "
@ENDIF
@POPNULL
@PRT "ReadLine: " @PRTSI FileBuffer @PRTNL
@PRTNL
#
#
# ReadBlock(FP,Size,Buffer)
@PUSHI FP @PUSH 450 @PUSHI FileBuffer
@CALL ReadBlock
@IF_LT_A 512
   @PRT "Reached End Of File: "
@ENDIF
@POPNULL
@PRT "ReadBlock: " @PRTSI FileBuffer @PRTNL
@PRTNL
#
#

@PRT "End of Run:"
@END
:TestBuffer
. TestBuffer+2048

:ErrorExit
@PRT "Error" @StackDump
@END
:ENDOFCODE

. Main
