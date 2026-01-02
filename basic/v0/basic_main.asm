I common.mc
L softstack.ld
L mul.ld
L string.ld
I basic_storage.asm
I basic_support.asm
# basic/v0/basic_main.asm
# BASIC v0 – Editor Shell (ESX716 compliant)
#
# Responsibilities:
#   - Prompt
#   - Read full line via READSI
#   - Distinguish program lines vs commands
#   - Dispatch to storage layer
#
# No tokenizer, no execution yet.

# --------------------------------------------------
# Input buffer (READSI requires full 256 bytes)
# --------------------------------------------------

=INPUTBUF_SIZE 256

:InputBuf
.ORG InputBuf+INPUTBUF_SIZE


# --------------------------------------------------
# BASIC entry point
# --------------------------------------------------

:BasicMain
    @CALL InitProgramStorage

:MainLoop
    @PRT "> "

    # Read a full line (device handles editing & termination)
    @READS InputBuf

    # If empty line, reprompt
    @LOADBI InputBuf
    @IF_ZERO
        @JMP MainLoop
    @ENDIF

    @Call(A) ParseLineOrCommand InputBuf

    @JMP MainLoop


# --------------------------------------------------
# ParseLineOrCommand
# --------------------------------------------------
# IN:
#   TOS = pointer to input buffer
# --------------------------------------------------

:ParseLineOrCommand
@PUSHRETURN
    @LocalVar BufPtr 01
    @LocalVar Ch     02

    @POPI BufPtr

    @Call(v) ISNumeric BufPtr
    @IF_NOTZERO
        @Call(v) ParseLineNumber BufPtr
        @CALL InsertOrDeleteLine
        @RestoreVar 02
        @RestoreVar 01
        @RET
    @ENDIF

    @CALL ParseCommand

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


# --------------------------------------------------
# ParseLineNumber
# --------------------------------------------------
# IN:
#   BufPtr
# OUT (stack):
#   LineNum
#   TextPtr
#   TextLen
# --------------------------------------------------

:ParseLineNumber
@PUSHRETURN
    @LocalVar Acc     01
    @LocalVar Ptr     02
    @LocalVar Ch      03
    @LocalVar TextPtr 04
    @LocalVar TextLen 05

    @POPI BufPtr

    @MV2V BufPtr Ptr
    @Call(v) stoifirst Ptr
    @POPI Acc

    # Now scan forward to find first non space character

    @MV2V Ptr TextPtr   # Base value in case of early exit.
    @MA2V 0 TextLen
    @PUSH 0
    @WHILE_ZERO
       @POPNULL
       @INCI Ptr       
       @LOADBII Ptr
       @IF_EQ_A " \0"
          # Space means just continue.
          @POPNULL
          @PUSH 0
       @ELSE
          # Not space, check for digit.
          @POPNULL
          @Call(v) ISNumeric Ptr
          @IF_ZERO
             # Only get here is not space or digit
             @POPNULL
             @PUSH 1   # Break While Loop
          @ELSE
             # Was digit so just continue.
             @POPNULL
             @PUSH 0
          @ENDIF
       @ENDIF
    @ENDWHILE
    @POPNULL
    # Its possible that PTR is pointing at null EOS
    @LOADBII Ptr
    @IF_NOTZERO
       @Call(v) strlen Ptr
       @POPI TextLen
       @MV2V Ptr TextPtr
    @ENDIF
    @POPNULL


    # Return values on stack (order matters!)
    @LOADI Acc
    @PUSHI TextPtr
    @LOADI TextLen

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


# --------------------------------------------------
# ParseCommand
# --------------------------------------------------
# Simple v0 command dispatch
# --------------------------------------------------

:ParseCommand
    @STRSTACK "LIST\0"    @PUSH InputBuf     @PUSH 4
    @CALL strncmp
    
    @IF_ZERO
        @POPNULL
        @CALL ListProgram
        @RET
    @ELSE
        @POPNULL
    @ENDIF

    @STRSTACK "NEW\0"    @PUSH InputBuf     @PUSH 3
    @CALL strncmp
    @IF_ZERO
        @POPNULL
        @PRTLN "Initilize..."
        @CALL InitProgramStorage
        @RET
    @ELSE
        @POPNULL
    @ENDIF


    @STRSTACK "RUN\0"    @PUSH InputBuf     @PUSH 3
    @CALL strncmp
    @IF_ZERO
        @POPNULL
        @CALL RunStub
        @RET
    @ELSE
        @POPNULL
    @ENDIF

    @PRTLN "?SYNTAX ERROR"
@RET

# End of Code, start of data
:ENDOFCODE
=PROGRAM_MEMORY_START ENDOFCODE

# --------------------------------------------------
# Program entry point
# --------------------------------------------------
. BasicMain


