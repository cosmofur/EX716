# This is not fully developed but some ideas on useing the Macros to manage a FIFO Queue

M _KeyBufIdxAddr @PUSHI MouseTable @ADD MouseKeyBuffOff
M _KeyBufDataBase @PUSHI MouseTable @ADD MouseKeyBuffOff+2
#               Clear out both indx and set Start of string to null
M KeyBufClear   @PUSH 0 @_KeyBufIdxAddr @POPS \
                @PUSH 0 @_KeyBufDataBase @POPS
M KeyBufIdx     @_KeyBufIdxAddr @PUSHS
M KeyBufSet     @_KeyBufIdxAddr @POPS
#               Start at DataBase use as string to get length. 
M KeyBufCount   @_KeyBufDataBase @CALL strlen @KeyBufIdx @SUBS
#               Append new character to end of string starting at
#               Memory problem if more than 30 characters are added. But should not happen normally.
M KeyBufEnqueue @AND 0xff \
                @_KeyBufDataBase \
                @DUP @CALL strlen \
                @ADDS \
                @POPS
#               If KeyBufClear was recently called, result of peek will be zero.
M KeyBufPeek    @KeyBufCount \
                @IF_NOTZERO \
                     @POPNULL \
                     @KeyBufIdx @_KeyBufDataBase @ADDS \
                     @PUSHS @AND 0xff \
                 @ENDIF
#               As long as Index is not zere
# If value at Peek is zero, we reached end of string, reset queue to 0 0
M KeyBufDequeue @KeyBufIdx @_KeyBufDataBase @ADDS \
                @PUSHS @AND 0xff \
                @IF_NOTZERO \
                   @POPNULL \
                   @KeyBufPeek \
                   @KeyBufIdx @ADD 1 @KeyBufSet \
                   @IF_ZERO \
                      @KeyBufClear \
                   @ENDIF \
                @ENDIF
M KeyBufDiscard @KeyBufDequeue @POPNULL
                                    
