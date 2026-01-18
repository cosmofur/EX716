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

:ProgramArenaBase
    0           # WORD

:ProgramUsed
    0           # WORD

:FirstLinePtr
    0           # WORD

:LastLinePtr
    0           # WORD

:FreePtr
    0           # WORD

G MainHeap
:MainHeap
    0           # WORD

:ArenaSize
    0

=LINE_HEADER_SIZE 4


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
    @Call(V) HeapNewObject MainHeap ArenaSize
    @POPI ProgramArenaBase               # base pointer

    @MA2V 0 ProgramUsed               # bytes used = 0
    @MV2V ProgramArenaBase FreePtr       # FreePtr = base
    @MA2V 0 FirstLinePtr
@RET


# --------------------------------------------------
# FindLine
# --------------------------------------------------
# IN:
#   LineNum (argument passed on stack)
#
# OUT (via stack): (CurPtr, PrevPtr, Found)
# --------------------------------------------------

:FindLine
    @PUSHRETURN
    @LocalVar LineNum 01
    @LocalVar CurPtr  02
    @LocalVar PrevPtr 03
    @LocalVar Found   04
    @LocalVar CurNum  05

    @POPI LineNum

    @IF_EQ_AV 0 ProgramUsed
       # Abort with all zeros if there no program.
       @MA2V 0 CurPtr
       @MA2V 0 PrevPtr
       @MA2V 0 Found
       @JMP  FLEXIT
    @ENDIF
    
    @MA2V 0 PrevPtr

    @MV2V FirstLinePtr CurPtr

    @MA2V 0 Found

    @PUSH 0
    @WHILE_ZERO
        @POPNULL
        @IF_EQ_AV 0 CurPtr
	    @PUSH 1       # Break Loop Not Found
        @ELSE
            @PUSHII CurPtr
            @POPI CurNum

            @IF_EQ_VV CurNum LineNum
	       @MA2V 1 Found
               @JMP FLBreakWhile
            @ENDIF

            @PUSHI CurNum
	    @IF_GT_V LineNum
	       @POPNULL
               @JMP FLBreakWhile
            @ENDIF
            @POPNULL
            @MV2V CurPtr PrevPtr
            @PUSHI CurPtr  # Next Address after CurPtr will be next line ptr
            @ADD 2
            @PUSHS
            @POPI CurPtr
            @PUSH 0        # Loop continues untilone of the break conditions are met.
	@ENDIF
    @ENDWHILE
    @POPNULL
    :FLBreakWhile
    :FLEXIT
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
            @Call(VV) DeleteLine CurPtr PrevPtr
        @ENDIF
        @JMP IOD_Exit   # Force break to end of function.
    @ENDIF

    @IF_NEQ_AV 0 Found
        @PUSHI LineNum @Call(VVVV) ReplaceLine TextLen TextPtr PrevPtr CurPtr    
    @ELSE
        @PUSHI LineNum @Call(VVVV) InsertLine TextLen TextPtr PrevPtr CurPtr
    @ENDIF
:IOD_Exit
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN    
@RET


# --------------------------------------------------
# InsertLine(LineNumer, TextLen, TextPtr, PrevPtr, CurPtr)
# --------------------------------------------------

:InsertLine
@PUSHRETURN
    @LocalVar LineNum       01
    @LocalVar TextLen       02
    @LocalVar TextPtr       03
    @LocalVar NewPtr        04
    @LocalVar PrevPtr       05
    @LocalVar CurPtr        06
    @LocalVar RecPtr        07

    @POPI CurPtr
    @POPI PrevPtr
    @POPI TextPtr
    @POPI TextLen
    @POPI LineNum

    # Test if we need to resize Arena
    @PUSHI ProgramUsed
    @ADDI TextLen
    @ADD 5                  # Line header space needed
    @IF_GT_V ArenaSize
       @PRT "Out of Memory."
       @JMP IL_EXIT
    @ENDIF
    #
    # Refresh FreePtr
    @PUSHI ProgramArenaBase @ADDI ProgramUsed @POPI FreePtr

    @MV2V FreePtr NewPtr
    @MV2V NewPtr RecPtr

    @PUSHI LineNum @POPII NewPtr     # Save LineNum [FreePtr]

    @INC2I NewPtr                    # Save CurPtr [FreePtr+2]
    @PUSHI CurPtr    @POPII NewPtr

    @INC2I NewPtr

    @Call(VVV) strncpy NewPtr TextPtr TextLen  # Save String starting at [FreePtr+4]

    @PUSHI NewPtr @ADDI TextLen @POPI NewPtr  # This is the address we need to force to be zero

    @PUSH 0
    @STOREBI NewPtr

    @IF_NEQ_AV 0 PrevPtr
       @PUSHI RecPtr
       @PUSHI PrevPtr
       @ADD 2
       @POPS              # Put PrevPtr at [FreePtr+2]
    @ENDIF

    @IF_EQ_AV 0 PrevPtr               # If no Previous, then mark as FirstLinePtr
       @MV2V RecPtr FirstLinePtr
    @ENDIF

    # Update ProgramUsed    
    @PUSHI ProgramUsed
    @ADDI TextLen
    @ADD 5
    @POPI ProgramUsed
    #
    # Update FreePtr
    @PUSHI ProgramArenaBase
    @ADDI ProgramUsed
    @POPI FreePtr

#    @PUSH 0 @POPII FreePtr

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
    @Call(VV) DeleteLine CurPtr PrevPtr
    @Call(v) FindLine LineNum
    @POPI Found    @POPI PrevPtr    @POPI CurPtr
    @IF_EQ_AV 0 Found
       @PUSHI LineNum @Call(VVVV) InsertLine TextLen TextPtr PrevPtr CurPtr
    @ELSE
       @PRT "Error: Edit of " @PRTI LineNum @PRTLN " Failed to free memory."
    @ENDIF
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
    @LocalVar CurPtr     01
    @LocalVar PrevPtr    02
    @LocalVar DelPtr     03
    @LocalVar NextPtr    04
    @LocalVar TextLen    05
    @LocalVar RecSize    06
    @LocalVar SrcPtr     07
    @LocalVar MoveLen    08
    @LocalVar ScanPtr    09
    @LocalVar TmpPtr     10

    # -------------------------------
    # Inputs
    # -------------------------------
    @POPI PrevPtr
    @POPI CurPtr

    @MV2V CurPtr DelPtr

    # -------------------------------
    # NextPtr = [DelPtr + 2]
    # -------------------------------
    @PUSHI DelPtr
    @ADD 2
    @PUSHS
    @POPI NextPtr

    # -------------------------------
    # Logical unlink
    # -------------------------------
    @IF_EQ_AV 0 PrevPtr
        @MV2V NextPtr FirstLinePtr
    @ELSE
        @PUSHI NextPtr
        @PUSHI PrevPtr
        @ADD 2
        @POPS                  # PrevPtr->Next = NextPtr
    @ENDIF

    # -------------------------------
    # Compute record size
    # RecSize = 5 + strlen(text)
    # -------------------------------
    @PUSHI DelPtr
    @ADD 4             # Move point to where string starts.
    @CALL strlen
    @POPI TextLen

    @PUSHI TextLen
    @ADD 5
    @POPI RecSize

    # -------------------------------
    # Compact arena
    # -------------------------------
    # SrcPtr  = DelPtr + RecSize
    # MoveLen = ProgramUsed - (SrcPtr - ProgramArenaBase)
    #
    @PUSHI DelPtr
    @ADDI RecSize
    @POPI SrcPtr

    @PUSHI ProgramUsed          
    @PUSHI SrcPtr           # (SrcPtr - ProgramArenaBase)
    @SUBI ProgramArenaBase
    @SUBS
    @POPI MoveLen

    @SafeMove(VVV) SrcPtr DelPtr MoveLen

    # -------------------------------
    # Update ProgramUsed / FreePtr
    # -------------------------------
    @PUSHI ProgramUsed
    @SUBI RecSize
    @POPI ProgramUsed

    @PUSHI ProgramArenaBase
    @ADDI ProgramUsed
    @POPI FreePtr

    # -------------------------------
    # Fix all NextPtr fields
    # -------------------------------
    @MV2V FirstLinePtr ScanPtr

    @WHILE_NEQ_AV 0 ScanPtr

        @PUSHI ScanPtr
        @ADD 2
        @PUSHS
        @POPI TmpPtr

        @PUSHI TmpPtr
        @IF_GT_V DelPtr
            @SUBI RecSize
            @POPI TmpPtr

            @PUSHI TmpPtr
            @PUSHI ScanPtr
            @ADD 2
            @POPS
        @ELSE
            @POPNULL
        @ENDIF

        @MV2V TmpPtr ScanPtr
    @ENDWHILE

    # -------------------------------
    # Return successor
    # -------------------------------
    @PUSHI NextPtr

    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
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
#
# Deletes the record at CurPtr, compacts memory,
# fixes all links, updates ProgramArenaBase/End/FreePtr,
# and RETURNS NextPtr on stack.
# --------------------------------------------------

:DeleteLine-OLD
@PUSHRETURN
    @LocalVar CurPtr      01   # input
    @LocalVar PrevPtr     02   # input
    @LocalVar DelPtr      03   # invariant delete address
    @LocalVar NextPtr     04   # invariant logical successor
    @LocalVar TextLen     05
    @LocalVar RecSize     06
    @LocalVar SrcPtr      07
    @LocalVar MoveLen     08
    @LocalVar ScanPtr     09
    @LocalVar TmpPtr      10

    # ------------------------------------------
    # Inputs
    # ------------------------------------------
    @POPI PrevPtr
    @POPI CurPtr

    @MV2V CurPtr DelPtr        # DelPtr = CurPtr

    # ------------------------------------------
    # NextPtr = [DelPtr + 2]
    # ------------------------------------------
    @PUSHI DelPtr
    @ADD 2
    @PUSHS
    @POPI NextPtr

    # ------------------------------------------
    # Logical unlink
    # ------------------------------------------
    @IF_EQ_AV 0 PrevPtr
        @MV2V DelPtr ProgramArenaBase
    @ELSE
        @PUSHI NextPtr
        @PUSHI PrevPtr
        @ADD 2
        @POPS                # [PrevPtr+2] = NextPtr
    @ENDIF

    # ------------------------------------------
    # Fast exit: deleting last record
    # ------------------------------------------
    @IF_EQ_VV CurPtr ProgramUsed
        @IF_EQ_AV 0 PrevPtr
            # deleting the only record
            @MA2V 0 ProgramArenaBase
            @MA2V 0 ProgramUsed
            @MV2V CurPtr FreePtr
            @PUSH 0
            @POPII FreePtr
            @MA2V 0 CurPtr
            @MA2V 0 PrevPtr            
            @JMP DLC_Exit
        @ELSE
            # deleting last but not first
            @MV2V PrevPtr ProgramUsed
            @MV2V CurPtr FreePtr
            @PUSH 0
            @POPII FreePtr
            @JMP DLC_Exit
        @ENDIF
    @ENDIF

    # ------------------------------------------
    # TextLen = strlen(DelPtr + 4)
    # ------------------------------------------
    @PUSHI DelPtr
    @ADD 4
    @CALL strlen
    @POPI TextLen

    # RecSize = 4 + TextLen + 1
    @PUSHI TextLen
    @ADD 5
    @POPI RecSize

    # ------------------------------------------
    # Compact memory
    #   SrcPtr  = DelPtr + RecSize
    #   MoveLen = FreePtr - SrcPtr
    # ------------------------------------------
    @PUSHI DelPtr
    @ADDI RecSize
    @POPI SrcPtr

    @PUSHI FreePtr
    @SUBI SrcPtr
    @POPI MoveLen

    @SafeMove(VVV) SrcPtr DelPtr MoveLen

    # ------------------------------------------
    # Fix FreePtr
    # ------------------------------------------
    @PUSHI FreePtr
    @SUBI RecSize
    @POPI FreePtr

    @PUSH 0
    @POPII FreePtr

    # ------------------------------------------
    # Fix ProgramUsed
    # ------------------------------------------
    @PUSHI ProgramUsed
    @IF_GT_V DelPtr
        @SUBI RecSize
        @POPI ProgramUsed
    @ELSE
        @POPNULL
    @ENDIF

    # ------------------------------------------
    # Fix all next-pointers
    # ------------------------------------------
    @MV2V ProgramArenaBase ScanPtr

    @WHILE_NEQ_AV 0 ScanPtr
        # TmpPtr = [ScanPtr + 2]
        @PUSHI ScanPtr
        @ADD 2
        @PUSHS
        @POPI TmpPtr

        @PUSHI TmpPtr
        @IF_GT_V DelPtr
            @SUBI RecSize
            @POPI TmpPtr

            @PUSHI TmpPtr
            @PUSHI ScanPtr
            @ADD 2
            @POPS
        @ELSE
            @POPNULL
        @ENDIF

        @MV2V TmpPtr ScanPtr
    @ENDWHILE

:DLC_Exit


    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
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
    @LocalVar ArgTable    02
    @LocalVar FilePtr     03
    @LocalVar LineCount   04
    @LocalVar SaveSize    05
    @LocalVar FileNum     06
    @LocalVar DiskBuffer  07

    @POPI FileName

    @Call(VA) file_open FileName 0x6f77     # "wo" open for write
    @POPI FilePtr
    
    @IF_ZERO
       @PRT "File: " @PRTSI FileName @PRT " could not be opened."
       @JMP SM_EXIT
    @ELSE
       # file_open will have filled in ArgTable meta data, required to customize Basic Header
       @PUSHI FilePtr @ADD FPTR_FILENUM @PUSHS
       @POPI FileNum
       # Setup Storage
       @CALL DirNewArgTable  @IF_ZERO @PRT "Error Alloc ArgTable\n" @JMP SM_EXIT @ENDIF
       @POPI ArgTable
       @CALL DiskNewBuffer @IF_ZERO @PRT "Error Alloc Buffer\n" @JMP SM_EXIT @ENDIF
       @POPI DiskBuffer
       # Fetch the ArgTable for editing.
       @Call(AAA) DirReadEntry FileNum ArgTable DiskBuffer
       
       # Save LineCount
       @CALL LineCountCode
       @POPI LineCount
       @PUSHI LineCount @PUSHI ArgTable @ADD DIR_AT_LINECOUNT @POPS
       # Save "BA" to the File Type field.
       @PUSH 0x4142 @PUSHI ArgTable @ADD DIR_AT_FILETYPE @POPS           
       #
       # Now save updated ArgTable to Disk
       @Call(AAA) DirWriteEntry FileNum ArgTable DiskBuffer
       #
       # Now Clean up storage
       @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
       @POPNULL
       @Call(VV) HeapDeleteObject DiskHeap ArgTable
       @POPNULL
       #       
       # Meta Data is updated, now do the main save.
       # Caclulate Total Bytes for save
       @PUSHI FreePtr @SUB _END_
       @POPI SaveSize       
       #
       @Call(VAV) DiskFileWrite FilePtr _END_ SaveSize
       #
       @Call(V) DiskClose FilePtr
    @ENDIF
:SM_EXIT
    
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01    
 @POPRETURN
 @RET
 
    
