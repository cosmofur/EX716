I common.mc
L heapmgr.ld
# basic/v1/basic_storage.asm
# BASIC v1 – Program Line Storage (ESX716 compliant)
#
# Line record format:
#   WORD line_number
#   WORD next_ptr
#   BYTE text...
#   BYTE 0
#
# Invariants:
#   - Lines sorted ascending by line number
#   - No duplicate line numbers
#   - ProgramArenaBase == 0 means empty program
#   - FreePtr always points to first unused byte


# --------------------------------------------------
# Global state
# --------------------------------------------------
G PROGRAM_MEMORY_START

:ProgramArenaBase    0           # WORD

:ProgramUsed         0           # WORD

:FirstLinePtr        0           # WORD

:LastLinePtr         0           # WORD

:FreePtr             0           # WORD

G NullProgram
:NullProgram         1           # Word 1 means no program in memory

G MainHeap
:MainHea    0           # WORD

:ArenaSize    0         # WORD


# --------------------------------------------------
# Input buffer (READSI requires full 256 bytes)
# --------------------------------------------------

=INPUTBUF_SIZE 256
G InputBuf
:InputBuf

=LINE_HEADER_SIZE 4
#--------------------------------------------------
# Relative Memory Macros
#--------------------------------------------------
# Use
# FETCH_REL OffSetPtr       Move to Stack value at relative offset
# PUT_REL OffSetPtr         Saves value on stack to relative offset
# FETCH_REL_OFF OffsetPtr Constant  Move to Stack value at relative + Constant
# PUT_REL_OFF OffsetPtr Constant  Saves value on stack to relative offset + Constant
#
M FETCH_REL @PUSHI %1 @ADDI ProgramArenaBase @PUSHS
M PUT_REL @PUSHI %1 @ADDI ProgramArenaBase @POPS
M FETCH_REL_OFF @PUSHI %1 @ADDI ProgramArenaBase @ADD %2 @PUSHS
M PUT_REL_OFF @PUSHI %1 @ADDI ProgramArenaBase @ADD %2 @POPS
#
# Convert to to use as paramater Relative Prt to Absolute 
M REL_TO_ABS @PUSHI %1 @ADDI ProgramArenaBase @POPI %2
M PUSH_REL_TO_ABS @PUSHI %1 @ADDI ProgramArenaBase
#
# Puts constant Byte value %1 as byte at relative offset
M PUT_A_BYTE_REL @PUSHI %2 @ADDI ProgramArenaBase \
     @DUP @PUSHS @AND 0xff00 \
     @PUSH %1 @ORS @SWP \
     @POPS
M PUT_V_BYTE_REL @PUSHI %2 @ADDI ProgramArenaBase \
     @DUP @PUSHS @AND 0xff00 \
     @PUSH %1 @ORS @SWP \
     @POPS
     

# --------------------------------------------------
# InitProgramStorage
# --------------------------------------------------

:InitProgramStorage
    #
    # Setup Heap (one time)
    #
    @PUSH _END_
    @PUSH 0xff00
    @SUB _END_
    @CALL HeapDefineMemory
    @IF_LT_A 100
        @PRT "Error allocating main heap."
        @END
    @ENDIF
    @POPI MainHeap

    @Call(V) SetDiskHeap MainHeap

    #
    # Setup Program Arena (32K initial)
    #
    @MA2V 0x8000 ArenaSize           # total capacity
    @Call(VV) HeapNewObject MainHeap ArenaSize
    @POPI ProgramArenaBase               # base pointer

    # Setup Sentinel Header at offset 0
    @PUSH 0xffff @PUSHI ProgramArenaBase @POPS
    @PUSH 0 @PUSHI ProgramArenaBase @ADD 2 @POPS
    
    @MA2V 4 ProgramUsed               # 4 bytes reserved for header
    @MA2V 4 FreePtr

    @MA2V 0 FirstLinePtr

    @MA2V 1 NullProgram
 
    # Initilize DiskOS for Disk00
    @Call(A) FSReadHeader 0
    @IF_ZERO @PRT "File System failed to initilize.\n" @POPNULL @END @ENDIF
    @POPNULL



@RET


# --------------------------------------------------
# FindLine
# --------------------------------------------------
# IN:
#   LineNum (argument passed on stack)
#
# OUT (via stack): (CurPtr, PrevPtr,, Found)
# --------------------------------------------------

# --------------------------------------------------
# FindLine
# --------------------------------------------------
# IN:
#   LineNum
#
# OUT (stack):
#   CurPtr, PrevPtr, HasPrev, Found
# --------------------------------------------------
:FindLine
    @PUSHRETURN
    @LocalVar LineNum  01
    @LocalVar CurPtr   02
    @LocalVar PrevPtr  03
    @LocalVar CurNum   04
    @LocalVar Found    05

    @POPI LineNum


    # ----------------------------------------------
    # Initialize traversal at sentinel
    # ----------------------------------------------

    @MA2V 0 PrevPtr                 # Prev = sentinel (offset 0)
    @FETCH_REL_OFF PrevPtr 2              # sentinel.Next
    @POPI CurPtr

    @MA2V 0 Found

    # ----------------------------------------------
    # Main traversal loop
    # ----------------------------------------------

:FL_LOOP
    @IF_EQ_AV 0 CurPtr
        @JMP FL_EXIT
    @ENDIF

    @FETCH_REL CurPtr               # load CurPtr.LineNum
    @POPI CurNum

    # ----------------------------------------------
    # Exact match?
    # ----------------------------------------------

    @IF_EQ_VV CurNum LineNum
        @MA2V 1 Found
        @PRT "  Found exact match" @PRTNL
        @JMP FL_EXIT
    @ENDIF

    # ----------------------------------------------
    # Insert-before condition?
    # ----------------------------------------------

    @PUSHI CurNum
    @IF_GT_V LineNum
        @POPNULL
        @PRT "  Insert before CurPtr" @PRTNL
        @JMP FL_EXIT
    @ENDIF
    @POPNULL

    # ----------------------------------------------
    # Advance
    # ----------------------------------------------

    @MV2V CurPtr PrevPtr
    @FETCH_REL_OFF CurPtr 2          # CurPtr = CurPtr.Next
    @POPI CurPtr

    @JMP FL_LOOP

# ----------------------------------------------
# Exit
# ----------------------------------------------

:FL_EXIT
    @PUSHI CurPtr
    @PUSHI PrevPtr
    @PUSHI Found

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN
    @RET



# --------------------------------------------------
# InsertOrDeleteLine
# --------------------------------------------------
# IN:
#   stack:
#     LineNum
#     TextPtr
#     TextLen
# --------------------------------------------------

:InsertOrDeleteLine
    @PUSHRETURN
    @LocalVar LineNum 01
    @LocalVar TextPtr 02
    @LocalVar TextLen 03
    @LocalVar Found   04    
    @LocalVar PrevPtr 05
    @LocalVar CurPtr  06
    @LocalVar HasPrev 07

    @POPI TextLen
    @POPI TextPtr
    @POPI LineNum

    @PUSHI LineNum
    @CALL FindLine
    @POPI Found
    @POPI PrevPtr
    @POPI CurPtr

    @IF_EQ_AV 0 TextLen
        @IF_NEQ_AV 0 Found
            @PRT "Deleting reused line:" @StackDump
            @Call(VV) DeleteLine CurPtr PrevPtr HasPrev
        @ENDIF
        @JMP IOD_Exit   # Force break to end of function.
    @ENDIF

    @IF_NEQ_AV 0 Found
            @PRT "Replacing reused line:" @StackDump    
        @PUSHI TextLen     # To allow 5 arguments to Call
        @PUSHI LineNum @Call(VVVV) ReplaceLine TextPtr HasPrev PrevPtr CurPtr    
    @ELSE
        @PUSHI LineNum
        @PUSHI TextLen    # To allow 5 arguments to Call                
        @Call(VVV) InsertLine TextPtr PrevPtr CurPtr
    @ENDIF
:IOD_Exit
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN    
@RET


# --------------------------------------------------
# InsertLine(LineNumer, TextLen, TextPtr,  PrevPtr, CurPtr)
# --------------------------------------------------
# --------------------------------------------------
# InsertLine(LineNum, TextLen, TextPtr, PrevPtr, CurPtr)
# --------------------------------------------------

:InsertLine
    @PUSHRETURN
    @LocalVar LineNum   01
    @LocalVar TextLen   02
    @LocalVar TextPtr   03
    @LocalVar NewPtr    04
    @LocalVar PrevPtr   05
    @LocalVar CurPtr    06
    @LocalVar AbsPtr    07

    @POPI CurPtr
    @POPI PrevPtr
    @POPI TextPtr
    @POPI TextLen
    @POPI LineNum

    # ---- space check ----
    @PUSHI ProgramUsed
    @ADDI TextLen
    @ADD 5
    @IF_UGT_V ArenaSize
        @PRT "Out of Memory."
        @JMP IL_EXIT
    @ENDIF
    @POPNULL

    # ---- allocate record ----
    @MV2V ProgramUsed NewPtr

    # word 0 = line number
    @PUSHI LineNum
    @PUT_REL NewPtr

    # word 1 = next pointer
    @PUSHI CurPtr
    @PUT_REL_OFF NewPtr 2
    @PRT "Setting Next Pointer to :" @PRTHEXI CurPtr @PRTNL

    @FETCH_REL_OFF NewPtr 2
    @IF_NEQ_A 0
       @IF_NEQ_V CurPtr
          @PRT "CORRUPT NEXT PTR: NewPtr=" @PRTHEXI NewPtr
          @PRT " Expected=" @PRTHEXI CurPtr
          @PRT " Found=" @PRTHEXTOP
          @PRTNL
       @ENDIF
    @ENDIF
    @POPNULL



    # ---- copy string ----
    @REL_TO_ABS NewPtr AbsPtr
    @PUSHI AbsPtr @ADD 4 @POPI AbsPtr

    @Call(VVV) strncpy AbsPtr TextPtr TextLen
    @PUSH AbsPtr @ADD TextLen @POPI AbsPtr
    @PUSH 0 @STOREBI AbsPtr

    # ---- link into list ----
    @PUSHI NewPtr
    @PUT_REL_OFF PrevPtr 2

    # ---- update ProgramUsed / FreePtr ----
    @PUSHI ProgramUsed
    @ADDI TextLen
    @ADD 5
    @POPI ProgramUsed

    @MV2V ProgramUsed FreePtr

:IL_EXIT
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN
    @RET


# --------------------------------------------------
# ReplaceLine
# --------------------------------------------------

:ReplaceLine
    @PUSHRETURN
    @LocalVar CurPtr 01   @POPI CurPtr
    @LocalVar PrevPtr 02  @POPI PrevPtr
    @LocalVar TextPtr 03  @POPI TextPtr
    @LocalVar TextLen 04  @POPI TextLen
    @LocalVar LineNum 05 @POPI LineNum
    @LocalVar Found 06
    @LocalVar HasPrev 07
    @Call(VV) DeleteLine CurPtr PrevPtr
    @Call(v) FindLine LineNum
    @POPI Found   @POPI PrevPtr    @POPI CurPtr
    @IF_EQ_AV 0 Found
       @PUSHI LineNum     # Call(VVVV) is limited to 4 argument, push 1st to allow 5
       @PUSHI TextLen
       @Call(VVV) InsertLine TextPtr PrevPtr CurPtr
    @ELSE
       @PRT "Error: Edit of " @PRTI LineNum @PRTLN " Failed to free memory."
    @ENDIF
    @RestoreVar 07
    @RestoreVar 06    
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN
    
@RET
# --------------------------------------------------
# DeleteLine(CurPtr, PrevPtr) -> NextPtr
# --------------------------------------------------

:DeleteLine
@PUSHRETURN
    @LocalVar CurPtr  01
    @LocalVar PrevPtr 02
    @LocalVar NextPtr 03

    @POPI PrevPtr
    @POPI CurPtr

    # NextPtr = CurPtr.Next
    @FETCH_REL_OFF CurPtr 2
    @POPI NextPtr

    # PrevPtr.Next = NextPtr
    @PUSHI NextPtr
    @PUT_REL_OFF PrevPtr 2

    # Return successor
    @PUSHI NextPtr

    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#-----------------------------------------
# Line2String(RecordPtr):StrPtr
# Converts given Line into string format.
# This will do real work when we have tolkenized lines
#---------------------------------------
:Line2String
@PUSHRETURN
   @LocalVar RecPtr 01
   @LocalVar LineNum 02
   @LocalVar OutStrPtr 03
   @POPI RecPtr
   
   @MA2V InputBuf OutStrPtr

   @PUSHII RecPtr # Get the Line Number
   @POPI LineNum
   @Call(VVA) itos OutStrPtr LineNum 10

   # Mve OutStrPtr to spot after number.
   @Call(V) strlen OutStrPtr
   @ADDI OutStrPtr
   @POPI OutStrPtr

   @PUSH " \0"      # Put a space after the number
   @POPII OutStrPtr
   @INCI OutStrPtr

   # A later version of this will do all sort of tolken to string operations but we don't need that yet.
   @PUSHI RecPtr @ADD 4 @POPI RecPtr
   
   @Call(VV) strcpy OutStrPtr RecPtr

   # Put a CR
   @PUSH 10        # EOL LF character
   @Call(V) strlen OutStrPtr
   @ADDI OutStrPtr
   @POPS           # THis should put LF hex 0xa and null at end of line

   @PUSH InputBuf

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01   

@POPRETURN
@RET

   


#------------------------------------------
# SAVEMEM(filename)
# SAVE FileName
#-----------------------------------------
:SAVEMEM
@PUSHRETURN
    @LocalVar FileName    01
    @LocalVar StrPtr      02
    @LocalVar Ptr         03
    @LocalVar FilePtr     04
    @LocalVar StrLen      05

    @POPI FileName

    @Call(VA) file_open FileName 0x6f77   # "wo"
    @POPI FilePtr

    @PUSHI ProgramArenaBase @ADD 2 @PUSHS
    @POPI Ptr
    @PUSH 0
    @WHILE_ZERO
       @IF_EQ_AV 0 Ptr
          @WHILEBREAK
       @ENDIF
       @PUSH_REL_TO_ABS Ptr
       @CALL Line2String
       @POPI StrPtr
       @Call(V) strlen StrPtr
       @POPI StrLen
       @Call(VVV) DiskFileWrite FilePtr StrPtr StrLen

       @IF_LT_V StrLen
           @PRT "Truncated Write."
       @ENDIF
       @POPNULL

       # Here we need something like printf(fp,string)
       @PRTSTRI StrPtr
       @PRTNL

       @FETCH_REL_OFF Ptr 2
       @POPI Ptr
    @ENDWHILE
    @POPNULL

    @Call(V) DiskClose FilePtr
    @IF_ZERO
       @PRT "Error Writing File:"
    @ENDIF
    @POPNULL
    @RestoreVar 05    
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
       
    
#------------------------------------------
# LOADMEM(filename)
# LOAD FileName into memory
#------------------------------------------
:LOADMEM
@PUSHRETURN
    @LocalVar FileName    01
    @LocalVar FilePtr     02
    @LocalVar ReadCount   03

    @POPI FileName

    # Open file for read ("ro")
    @Call(VA) file_open FileName MODE_RO  # 0x726f "ro"
    @POPI FilePtr
    @IF_EQ_AV 0 FilePtr
        @PRT "File: " @PRTSI FileName @PRT " could not be opened."
        @JMP LM_EXIT
    @ELSE
        @MA2V 0 ReadCount
        @Call(VA) DiskFileReadLine  FilePtr InputBuf
        @WHILE_NOTZERO
            @POPNULL
            @Call(A) ParseLineOrCommand InputBuf
            @Call(VA) DiskFileReadLine  FilePtr InputBuf
        @ENDWHILE
        @POPNULL
    @ENDIF       
:LM_EXIT
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

   

      
      
      
