# basic/v0/basic_tokens.asm
# BASIC v0 – Command Tokens (ESX716 style)

=TK_NONE 0
=TK_LIST 1
=TK_NEW  2
=TK_RUN  3

# Assembly-time macro to emit:
#   <string>\0 <token-byte>
M BASIC_CMD \
    %1 \          # keyword string
    $$0 \         # explicit NUL terminator (byte)
    $$%2          # token value as byte

:BasicCommandTable
    @BASIC_CMD "LIST", TK_LIST
    @BASIC_CMD "NEW",  TK_NEW
    @BASIC_CMD "RUN",  TK_RUN
    $$0              # end-of-table marker
