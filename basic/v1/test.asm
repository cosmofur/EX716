I common.mc
L basic_diskos.asm
L heapmgr.ld

:HeapID 0
:FilePointer 0
:Data 0
:DataCopy 0
:_I 0

:Main . Main
@PRT "Start\n"
# Setup Heap
@PUSH _END_
@PUSH 0xff00 @SUB _END_
@CALL HeapDefineMemory
@POPI HeapID
#
@Call(V) SetDiskHeap HeapID
#
@STRSTACK "TestFile01"
@PUSH 0x7772
@CALL file_open
@POPI FilePointer
@IF_ZERO
   @PRT "Error opening File"
   @END
@ENDIF

# Create some fill data
@Call(VA) HeapNewObject HeapID 4096
@POPI Data
@ForIA2B _I 0 4096
   @PUSHI _I @AND 0x3f @ADD 32
   @PUSHI _I
   @ADDI Data       # Address
   @POPS
@Next _I
#
# Write it
@Call(VVA) DiskFileWrite FilePointer Data 4096
@PRT "Wrote " @PRTTOP @PRTLN " Bytes."
@POPNULL
#
# Close the file
@Call(V) DiskClose FilePointer
#
@IF_EQ_A 1
   @PRT "Success Close"
@ELSE
   @PRT "Fail Close"
   @StackDump
   @END
@ENDIF
@POPNULL
#
#
# Now reopen it and read it to new space.
@STRSTACK "TestFile01"
@PUSH 0x7772
@CALL file_open
@POPI FilePointer
#
# Now Fetch the data into DataCopy
@Call(VA) HeapNewObject HeapID 4096
@POPI DataCopy

@Call(VVA) DiskFileRead FilePointer DataCopy -1
@PRT "Read in " @PRTHEXTOP @PRT " Bytes for data.\n"
@PRTLN "Validating."

@ForIA2B _I 0 4096
   @PUSHI _I @ADDI Data @PUSHS
   @PUSHI _I @ADDI DataCopy @PUSHS
   @CMPS
   @IF_NOTZERO
      @PRT "Word: " @PRTHEXI _I @PRT " Differ.\n"
      @FORBREAK
   @ENDIF
   @POPNULL
   @POPNULL   
@NextBy _I 2

@Call(V) DiskClose FilePointer

@END



