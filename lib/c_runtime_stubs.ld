! __LIB_C_RUNTIME_STUBS_LOADED
M __LIB_C_RUNTIME_STUBS_LOADED 1
P Loading c_runtime_stubs.ld

# Load services first; rebind only names whose C contract needs adaptation.
L string.ld
# DiskOS is filtered at this point, before per-function #USE directives inside
# the bridges below are parsed. Request its C-facing entry points up front so
# their transitive DiskOS dependencies are retained in the filtered library.
#USE SetDiskHeap,FSReadHeader,file_open,DiskClose,DiskFileRead,DiskFileWrite
D diskos.ld
G malloc G free G memset G putchar G __EX716_GETCHAR_RAW G __EX716_INPUT_STATUS
G __EX716_TTY_RAW G __EX716_TTY_COOKED G __EX716_TTY_ECHO G __EX716_TTY_NOECHO
G __EX716_DISK_INIT G __EX716_DISK_OPEN G __EX716_DISK_CLOSE
G __EX716_DISK_READ G __EX716_DISK_WRITE G __EX716_DISK_TRUNCATE
G __EX716_DISK_REWIND G __EX716_DISK_APPEND

? CPU24_SEGMENTED
::__EX716_PUTCHAR_BYTE 0
::__EX716_INPUT_STATUS 0
ENDBLOCK
! CPU24_SEGMENTED
:__EX716_PUTCHAR_BYTE 0
:__EX716_INPUT_STATUS 0
ENDBLOCK

=__ex716_strcpy strcpy
=__ex716_strncpy strncpy
=__ex716_strcat strcat
=__ex716_strncat strncat
=__ex716_memcpy memcpy
=__ex716_memmove EX716_MEMMOVE

@FUNCTION putchar
:putchar
@PUSHRETURN
   @Locals
   @Local Value
   @POPI Value
   @PUSHI Value
   @AND 0xff
   @POPI __EX716_PUTCHAR_BYTE
   @PUSH CastPrintChar
   @CAST __EX716_PUTCHAR_BYTE
   @PUSHI Value
   @AND 0xff
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# DiskOS uses the application's heap and requires its filesystem header to be
# loaded before name-based opens. C calls this lazily after generated startup
# has initialized __EX716_HEAP_ID.
@FUNCTION __EX716_DISK_INIT
:__EX716_DISK_INIT
@PUSHRETURN
   @Locals
#USE SetDiskHeap,FSReadHeader
   @PUSHI __EX716_HEAP_ID
   @CALL SetDiskHeap
   @PUSH 0
   @CALL FSReadHeader
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# C mode constants are translated in stdio_format.c to DiskOS's two-letter
# legacy modes. These bridges preserve the C calling convention at the edge.
@FUNCTION __EX716_DISK_OPEN
:__EX716_DISK_OPEN
@PUSHRETURN
   @Locals
#USE file_open
   @Local FileName
   @Local Mode
   @POPI Mode
   @POPI FileName
   @PUSHI FileName
   @PUSHI Mode
   @CALL file_open
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_DISK_CLOSE
:__EX716_DISK_CLOSE
@PUSHRETURN
   @Locals
#USE DiskClose
   @Local FilePtr
   @POPI FilePtr
   @PUSHI FilePtr
   @CALL DiskClose
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_DISK_READ
:__EX716_DISK_READ
@PUSHRETURN
   @Locals
#USE DiskFileRead
   @Local FilePtr
   @Local Buffer
   @Local Count
   @POPI Count
   @POPI Buffer
   @POPI FilePtr
   @PUSHI FilePtr
   @PUSHI Buffer
   @PUSHI Count
   @CALL DiskFileRead
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_DISK_WRITE
:__EX716_DISK_WRITE
@PUSHRETURN
   @Locals
#USE DiskFileWrite
   @Local FilePtr
   @Local Buffer
   @Local Count
   @POPI Count
   @POPI Buffer
   @POPI FilePtr
   @PUSHI FilePtr
   @PUSHI Buffer
   @PUSHI Count
   @CALL DiskFileWrite
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_DISK_TRUNCATE
:__EX716_DISK_TRUNCATE
@PUSHRETURN
   @Locals
   @Local FilePtr
   @POPI FilePtr
   @FILL_AT_A FilePtr FPTR_FILESIZE 0
   @FILL_AT_A FilePtr FPTR_FILESIZE+2 0
   @FILL_AT_A FilePtr FPTR_CURSOR 0
   @FILL_AT_A FilePtr FPTR_CURSOR+2 0
   @PUSH 1
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_DISK_REWIND
:__EX716_DISK_REWIND
@PUSHRETURN
   @Locals
   @Local FilePtr
   @POPI FilePtr
   @FILL_AT_A FilePtr FPTR_CURSOR 0
   @FILL_AT_A FilePtr FPTR_CURSOR+2 0
   @PUSH 1
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_DISK_APPEND
:__EX716_DISK_APPEND
@PUSHRETURN
   @Locals
   @Local FilePtr
   @POPI FilePtr
   @PUSHI FilePtr @ADD FPTR_FILESIZE @PUSHS
   @PUSHI FilePtr @ADD FPTR_CURSOR @POPS
   @PUSHI FilePtr @ADD FPTR_FILESIZE+2 @PUSHS
   @PUSHI FilePtr @ADD FPTR_CURSOR+2 @POPS
   @PUSH 1
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# Small C-callable bridge for the EX716 termios compatibility layer.
@FUNCTION __EX716_TTY_RAW
:__EX716_TTY_RAW
@PUSHRETURN
   @TTYRAW
   @PUSH 0
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_TTY_COOKED
:__EX716_TTY_COOKED
@PUSHRETURN
   @TTYRAWOFF
   @PUSH 0
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_TTY_ECHO
:__EX716_TTY_ECHO
@PUSHRETURN
   @TTYECHO
   @PUSH 0
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_TTY_NOECHO
:__EX716_TTY_NOECHO
@PUSHRETURN
   @TTYNOECHO
   @PUSH 0
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION __EX716_GETCHAR_RAW
:__EX716_GETCHAR_RAW
@PUSHRETURN
   @Locals
   @Local InputWord
   @Local InputStatus
:__EX716_GETCHAR_RETRY
   @READC InputWord
   @PUSHI InputWord
   @SHR8
   @POPI InputStatus
   @IF_EQ_AV PollStatusNoInput InputStatus
      @JMP __EX716_GETCHAR_RETRY
   @ENDIF
   @PUSHI InputStatus
   @POPI __EX716_INPUT_STATUS
   @IF_EQ_AV PollStatusData InputStatus
      @PUSHI InputWord
      @AND 0xff
   @ELSE
      @PUSH 0xffff
   @ENDIF
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION strcpy
:strcpy
@PUSHRETURN
   @Locals
   @Local Dst
   @Local Src
   @POPI Src
   @POPI Dst
   @PUSHI Dst
   @PUSHI Src
   @CALL __ex716_strcpy
   @PUSHI Dst
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION strncpy
:strncpy
@PUSHRETURN
   @Locals
   @Local Dst
   @Local Src
   @Local Count
   @POPI Count
   @POPI Src
   @POPI Dst
   @PUSHI Dst
   @PUSHI Src
   @PUSHI Count
   @CALL __ex716_strncpy
   @PUSHI Dst
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION strcat
:strcat
@PUSHRETURN
   @Locals
   @Local Dst
   @Local Src
   @POPI Src
   @POPI Dst
   @PUSHI Dst
   @PUSHI Src
   @CALL __ex716_strcat
   @PUSHI Dst
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION strncat
:strncat
@PUSHRETURN
   @Locals
   @Local Dst
   @Local Src
   @Local Count
   @POPI Count
   @POPI Src
   @POPI Dst
   @PUSHI Dst
   @PUSHI Src
   @PUSHI Count
   @CALL __ex716_strncat
   @POPNULL
   @PUSHI Dst
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION memcpy
:memcpy
@PUSHRETURN
   @Locals
   @Local Dst
   @Local Src
   @Local Count
   @POPI Count
   @POPI Src
   @POPI Dst
   @PUSHI Dst
   @PUSHI Src
   @PUSHI Count
   @CALL __ex716_memcpy
   @PUSHI Dst
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION memmove
:memmove
@PUSHRETURN
   @Locals
   @Local Dst
   @Local Src
   @Local Count
   @POPI Count
   @POPI Src
   @POPI Dst
   @PUSHI Dst
   @PUSHI Src
   @PUSHI Count
   @CALL __ex716_memmove
   @PUSHI Dst
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION memset
:memset
@PUSHRETURN
   @Locals
   @Local Dst
   @Local Value
   @Local Count
   @Local Index
   @POPI Count
   @POPI Value
   @POPI Dst
   @MA2V 0 Index
   @PUSHI Count
   @WHILE_NOTZERO
      @POPNULL
      @PUSHI Value
      @AND 0xff
      @PUSHI Dst
      @ADDI Index
      @PUSHS
      @AND 0xff00
      @ORS
      @PUSHI Dst
      @ADDI Index
      @POPS
      @INCI Index
      @DECI Count
      @PUSHI Count
   @ENDWHILE
   @POPNULL
   @PUSHI Dst
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION malloc
:malloc
@PUSHRETURN
   @Locals
   @Local Count
   @Local ObjectID
   @Local UserPointer
   @POPI Count
   @PUSHI __EX716_HEAP_ID
   @IF_ULT_A 100
      @POPNULL
      @PUSH 0
      @JMP __EX716_MALLOC_DONE
   @ENDIF
   @POPNULL
   @PUSHI Count
   @IF_UGT_A 65528
      @POPNULL
      @PUSH 0
      @JMP __EX716_MALLOC_DONE
   @ENDIF
   @POPNULL
   @PUSHI __EX716_HEAP_ID
   @PUSHI Count
   @ADD 7
   @CALL HeapNewObject
   @IF_ULT_A 100
      @POPNULL
      @PUSH 0
      @JMP __EX716_MALLOC_DONE
   @ENDIF
   @POPI ObjectID
   @PUSHI ObjectID
   @ADD 5
   @DUP
   @AND 1
   @ADDS
   @POPI UserPointer
   @PUSHI UserPointer
   @SUB 2
   @PUSHI ObjectID
   @SWP
   @POPS
   @PUSHI UserPointer
:__EX716_MALLOC_DONE
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION free
:free
@PUSHRETURN
   @Locals
   @Local UserPointer
   @Local ObjectID
   @POPI UserPointer
   @PUSHI UserPointer
   @IF_ZERO
      @POPNULL
      @JMP __EX716_FREE_DONE
   @ENDIF
   @POPNULL
   @PUSHI UserPointer
   @SUB 2
   @PUSHS
   @POPI ObjectID
   @PUSHI __EX716_HEAP_ID
   @PUSHI ObjectID
   @CALL HeapDeleteObject
   @POPNULL
:__EX716_FREE_DONE
   @EndLocals
@POPRETURN
@RET
@ENDFUNCTION
