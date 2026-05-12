! BASIC_COMMONFLAG
M BASIC_COMMONFLAG 1

# Constants
=ARG_TYPE_NUM  0
=ARG_TYPE_STR 1
=ARG_TYPE_WORD 3
=ARG_WORDS  3
=RUNCODE 0xd0
=LISTCODE 0xd1
=LOADCODE 0xd2
=SAVECODE 0xd3
=NEWCODE 0xd4
=QUITCODE 0xd5
=DIRCODE 0xd6
=TYPECODE 0xd7
=RENAMECODE 0xd8
=DELETECODE 0xd9


#
# Keywords: Core Control 0x80-0x9f
=IF_CODE      0x80
=THEN_CODE    0x81
=ELSE_CODE    0x82
=FOR_CODE     0x83
=TO_CODE      0x84
=STEP_CODE    0x85
=NEXT_CODE    0x86
=WHILE_CODE   0x87
=WEND_CODE    0x88
=GOTO_CODE    0x89
=GOSUB_CODE   0x8a
=RETURN_CODE  0x8b
=LET_CODE     0x8c      # Match up keywords that also happen to be commands.
=DIM_CODE     0x8d
=END_CODE     0x8e
=STOP_CODE    0x8f
=PRINT_CODE   0x90
=MEM_CODE     0x91
# I/O & Filesystem
=OPEN_CODE     0xa0
=CLOSE_CODE    0xa1
=FREAD_CODE    0xa2
=FWRITE_CODE   0xa3
=FGET_CODE     0xa4
=FPUT_CODE     0xa5
=SEEK_CODE     0xa6
=EOF_CODE      0xa7
=PRINTF_CODE   0xa8
# Screen UI
=CLS_CODE       0xb0
=MOVE_CODE      0xb1
=MOVEXY_CODE    0xb2
=COLOR_CODE     0xb3
=COLORFG_CODE   0xb4
=COLORBG_CODE   0xb5
=CURSOR_CODE    0xb6
# Math / Functions
=SIN_CODE     0xc0
=COS_CODE     0xc1
=TAB_CODE     0xc2
=ATAN_CODE    0xc3
=ABS_CODE     0xc4
=SGN_CODE     0xc5
=INT_CODE     0xc6
=RND_CODE     0xc7
=LEN_CODE     0xc8
=VAL_CODE     0xc9
=STR_CODE     0xca

# Logic
=AND_TOKEN    0xd0
=OR_TOKEN     0xd1
=NOT_TOKEN    0xd2
# Data Catagoty and Multi character tolkens
=STRING_TOKEN   0xe0
=VAR_TOKEN      0xe1
=LINE_REFERENCE 0xe4
=NE_TOKEN       0xe5
=LE_TOKEN       0xe6
=GE_TOKEN       0xe7
=INT_TOKEN      0xe9
=FLOAT_TOKEN    0xea
=LONG_TOKEN     0xeb

#

=EOL_TOKEN      0xfb

# IMPORTANT:
# KeywordTable MUST be sorted by descending string length.
# This ensures longest-match-first semantics (e.g. PRINTF before PRINT).
# New keywords MUST be inserted in the correct order.

:KeyWordTable
:CommandTable
:TokenTable
$$3 "RUN" RUNCODE
$$4 "LIST" LISTCODE
$$4 "LOAD" LOADCODE
$$4 "SAVE" SAVECODE
$$3 "NEW" NEWCODE
$$4 "QUIT" QUITCODE
$$3 "DIR" DIRCODE
$$4 "TYPE" TYPECODE
$$6 "RENAME" RENAMECODE
$$6 "DELETE" DELETECODE
$$5 "PRINT" PRINT_CODE
$$7 "COLORBG" COLORBG_CODE
$$7 "COLORFG" COLORFG_CODE
$$6 "CURSOR" CURSOR_CODE
$$6 "MOVEXY" MOVEXY_CODE
$$6 "PRINTF" PRINTF_CODE
$$6 "FWRITE" FWRITE_CODE
$$6 "RETURN" RETURN_CODE
$$5 "COLOR" COLOR_CODE
$$5 "FREAD" FREAD_CODE
$$5 "CLOSE" CLOSE_CODE
$$5 "PRINT" PRINT_CODE
$$5 "GOSUB" GOSUB_CODE
$$5 "WHILE" WHILE_CODE
$$4 "ATAN" ATAN_CODE
$$4 "MOVE" MOVE_CODE
$$4 "SEEK" SEEK_CODE
$$4 "FPUT" FPUT_CODE
$$4 "FGET" FGET_CODE
$$4 "OPEN" OPEN_CODE
$$4 "STOP" STOP_CODE
$$4 "GOTO" GOTO_CODE
$$4 "WEND" WEND_CODE
$$4 "NEXT" NEXT_CODE
$$4 "STEP" STEP_CODE
$$4 "ELSE" ELSE_CODE
$$4 "THEN" THEN_CODE
$$3 "STR" STR_CODE
$$3 "VAL" VAL_CODE
$$3 "LEN" LEN_CODE
$$3 "RND" RND_CODE
$$3 "INT" INT_CODE
$$3 "SGN" SGN_CODE
$$3 "ABS" ABS_CODE
$$3 "TAB" TAB_CODE
$$3 "COS" COS_CODE
$$3 "SIN" SIN_CODE
$$3 "CLS" CLS_CODE
$$3 "EOF" EOF_CODE
$$3 "END" END_CODE
$$3 "DIM" DIM_CODE
$$3 "LET" LET_CODE
$$3 "FOR" FOR_CODE
$$3 "MEM" MEM_CODE
$$2 "TO" TO_CODE
$$2 "IF" IF_CODE
$$2 "<>" NE_TOKEN
$$2 "<=" LE_TOKEN
$$2 "=<" LE_TOKEN
$$2 ">=" GE_TOKEN
$$2 "=>" GE_TOKEN
$$3 "AND" AND_TOKEN
$$2 "OR"  OR_TOKEN
$$3 "NOT" NOT_TOKEN
$$6 "String" STRING_TOKEN
$$6 "Symbol" VAR_TOKEN
$$7 "LineNum" LINE_REFERENCE
$$8 "FloatNum" FLOAT_TOKEN
$$7 "LongNum" LONG_TOKEN
$$1 "?"     PRINT_CODE
$$1 "=" "=\0"          # Single character codes with valid values are here.
$$1 "+" "+\0"
$$1 "-" "-\0"
$$1 "*" "*\0"
$$1 "/" "/\0"
$$1 "^" "^\0"
$$1 "(" "(\0"
$$1 ")" ")\0"
$$1 "<" "<\0"
$$1 ">" ">\0"
$$1 "," ",\0"
$$1 ";" ";\0"
$$1 "#" "#\0"
$$1 "^" "^\0"

0       # END OF LIST
#
# Return Codes:
=RET_OK 0           # Program RAN OK
=RET_ERROR 1        # Some sort of Run time error occured
=RET_BREAK 2        # User or app triggered break
=RET_EOP 3          # END of Program
# Error Runtime
=ERR_NONE             0
=ERR_SYNTAX           1
=ERR_DIV_ZERO         2
=ERR_UNDEF_VAR        3
=ERR_TYPE_MISMATCH    4
=ERR_BAD_GOTO         5
=ERR_BAD_RETURN       6
=ERR_OUT_RANGE        7
=ERR_MEMORY           8
# Error Resource
=ERR_OUT_OF_MEMORY    1
=ERR_STRING_SPACE     2
=ERR_NO_FILE_HANDLES  3
# IO Errors
=ERR_FILE_NOT_FOUND   1
=ERR_FILE_OPEN_FAIL   2
=ERR_FILE_READ_FAIL   3
=ERR_FILE_WRITE_FAIL  4
# Internal Error
=ERR_INTERNAL_FAULT   1

# Set Var Types, not arrays
=INT_TYPE 0
=LONG_TYPE 1
=FLOAT_TYPE 2
=STRING_TYPE 3
# Var Stucture offsets
=VAROFF_Name 0
=VAROFF_TypeID 2
=VAROFF_Pay1 4
=VAROFF_Pay2 6
=VAROFF_Next 8
#
=MaxVarNameLen 10

@USE  ADD32S
@USE  AND32
@USE  CMP32S
@USE  CMP32U
@USE  COMP232
@USE  DIV
@USE  DIV32S
@USE  DiskClose
@USE  DiskFileReadLine
@USE  DiskFileWrite
@USE  DiskOpen
@USE  DirReadEntry
@USE  FSFindFile
@USE  FSReadHeader
@USE  file_open
@USE  HeapDefineMemory
@USE  HeapDeleteObject
@USE  HeapListMap
@USE  HeapNewObject
@USE  HeapResizeObject
@USE  HexDump
@USE  ISAlphaNum
@USE  ISNumeric
@USE  MODE
@USE  MUL
@USE  MULU
@USE  MUL32S
@USE  OR32
@USE  SUB32S
@USE  SetDiskHeap
@USE  SetSSStack
@USE  file
@USE  itos
@USE  memcpy
@USE  stoi32
@USE  stoifirst
@USE  strcpy
@USE  strlen
@USE  strncmp
@USE  strncpy


ENDBLOCK
M SIZESINCECOMMENT basic_common.h
@SIZESINCE  

  
