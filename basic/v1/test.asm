#---------------------------------------
# test.asm – DiskOS basic FS validation
#---------------------------------------

I common.mc
L diskos.ld
L heapmgr.ld

:HeapID      0
:FilePointer 0
:FileNum     0
:Data        0
:DataCopy   0
:_I          0

:Main . Main
@PRT "Start DiskOS Test\n"

#-------------------------------------------------
# Setup Heap
#-------------------------------------------------
@PUSH _END_
@PUSH 0xff00
@SUB _END_
@CALL HeapDefineMemory
@POPI HeapID

@Call(V) SetDiskHeap HeapID

# -------------------------------------------------
# Initialize filesystem context
#--------------------------------------------------
@Call(AA) FSFormat 101 0
@Call(A) FSReadHeader 0
@IF_ZERO
   @PRT "FSReadHeader failed\n"
   @END
@ENDIF
@POPNULL

#-------------------------------------------------
# Validate filesystem header
#-------------------------------------------------
@PUSH 0
@CALL FSReadHeader
@IF_ZERO
   @PRT "FS header invalid\n"
   @END
@ENDIF
@POPNULL

#-------------------------------------------------
# Open file for read/write (create if needed)
#-------------------------------------------------
@STRSTACK "TestFile01"
@PUSH 0x7772        # "rw"
@CALL file_open
@POPI FilePointer

@IF_ZERO
   @PRT "Error opening file\n"
   @END
@ENDIF

#-------------------------------------------------
# Capture FileNum for bitmap checks
#-------------------------------------------------
@PUSHI FilePointer
@ADD FPTR_FILENUM
@PUSHS
@POPI FileNum

#-------------------------------------------------
# Allocate and fill write buffer
#-------------------------------------------------
@Call(VA) HeapNewObject HeapID 4096
@POPI Data

@ForIA2B _I 0 4096
   @PUSHI _I
   @AND 0x3f
   @ADD 32
   @PUSHI Data
   @ADDI _I
   @POPS
@Next _I

@Call(VA) HexDump Data 32

#-------------------------------------------------
# Write data
#-------------------------------------------------
@Call(VVA) DiskFileWrite FilePointer Data 4096
@IF_NEQ_A 4096
   @PRT "Short write detected\n"
   @END
@ENDIF
@POPNULL

#-------------------------------------------------
# Validate cursor and filesize
#-------------------------------------------------
@PUSHI FilePointer @ADD FPTR_CURSOR @PUSHS
@PRT "Cursor after write: " @PRTHEXTOP @PRTNL
@POPNULL

@PUSHI FilePointer @ADD FPTR_FILESIZE @PUSHS
@PRT "Filesize after write: " @PRTHEXTOP @PRTNL
@POPNULL

#-------------------------------------------------
# Append test (exercise non-zero offset)
#-------------------------------------------------
@Call(VVA) DiskFileWrite FilePointer Data 1024
@IF_NEQ_A 1024
   @PRT "Append failed\n"
   @END
@ENDIF
@POPNULL

#-------------------------------------------------
# Close file
#-------------------------------------------------
@Call(V) DiskClose FilePointer
@IF_EQ_A 1
   @PRT "File closed successfully\n"
@ELSE
   @PRT "File close failed\n"
   @END
@ENDIF
@POPNULL

#-------------------------------------------------
# Flush FS metadata
#-------------------------------------------------
@CALL FSWriteHeader
@POPNULL

#-------------------------------------------------
# Verify bitmap reflects file usage
#-------------------------------------------------
@Call(V) FSIsFileUsed FileNum
@IF_ZERO
   @PRT "Bitmap not set for file\n"
   @END
@ENDIF
@POPNULL

#-------------------------------------------------
# Reopen file
#-------------------------------------------------
@StackDump
@STRSTACK "TestFile01"
@PUSH 0x7772        # "rw"
@CALL file_open
@POPI FilePointer

@IF_EQ_AV 0 FilePointer
   @PRT "Reopen failed\n"
   @END
@ENDIF
@StackDump

#-------------------------------------------------
# Allocate read buffer
#-------------------------------------------------
@Call(VA) HeapNewObject HeapID 0x1500
@POPI DataCopy

@PRT "Start\n" @Call(V) HeapListMap HeapID @PRTNL
#-------------------------------------------------
# Read entire file
#-------------------------------------------------
@Call(VVA) DiskFileRead FilePointer DataCopy -1
@IF_NEQ_A 5120       # 4096 + 1024
   @PRT "Short read detected\n"
   @END
@ENDIF
@POPNULL

@PRT "Read validation starting\n"
@Call(VA) HexDump DataCopy 32
#-------------------------------------------------
# Compare buffers (first 4096 bytes)
#-------------------------------------------------
@ForIA2B _I 0 4096
   @PUSHI Data
   @ADDI _I
   @PUSHS

   @PUSHI DataCopy
   @ADDI _I
   @PUSHS

   @CMPS
   @IF_NOTZF
      @PRT "Mismatch at byte " @PRTHEXI _I @PRTNL
      @PRT "Source Bytes at " @PUSHI _I @SUB 8 @PRTTOP @POPNULL @PRTNL
      @PUSHI Data @ADDI _I @SUB 8 @PUSH 32
      @CALL HexDump
      @PRT "Destination Bytes at " @PUSHI _I @SUB 8 @PRTTOP @POPNULL @PRTNL
      @PUSHI DataCopy @ADDI _I @SUB 8 @PUSH 32
      @CALL HexDump
      @END
   @ENDIF
   @POPNULL
   @POPNULL
@NextBy _I 2

#-------------------------------------------------
# Close again
#-------------------------------------------------
@Call(V) DiskClose FilePointer
@POPNULL

#-------------------------------------------------
# Clear bitmap (future delete sanity check)
#-------------------------------------------------
@Call(V) FSClearFileUsed FileNum
@Call(V) FSIsFileUsed FileNum
@IF_NOTZERO
   @PRT "Bitmap clear failed\n"
@ENDIF
@POPNULL

@PRT "DiskOS basic test PASSED\n"
@END

# HexDump (Start, size)
:HexDump
@PUSHRETURN
@LocalVar _I 01
@LocalVar Start 02
@LocalVar Size 03
@POPI Size
@POPI Start
@PRT " 0 1 2 3 4 5 6 7 8 9 A B C D E F"
@ForIA2V _I 0 Size
   @PUSHI _I
   @AND 0xf
   @IF_ZERO
      @PRTNL @PRTSP
   @ENDIF
   @POPNULL

   @PUSHI Start
   @ADDI _I
   @PUSHS
   @AND 0xff
   @DUP
   @AND 0xf0
   @SHRN 4
   @ADD 0x30
   @IF_GT_A 0x39
      @ADD 0x7
   @ENDIF
   @PRTCHS
   @POPNULL
   @AND 0xf
   @ADD 0x30
   @IF_GT_A 0x39
      @ADD 0x7
   @ENDIF
   @PRTCHS
   @POPNULL
@Next _I
@PRTNL
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
