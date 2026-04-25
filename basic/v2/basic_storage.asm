I common.mc
L heapmgr.ld
# basic/v2/basic_storage.asm
# BASIC v2 – Program Line Storage (ESX716 compliant)
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
#   - FreePtr always points to first unused byte


# --------------------------------------------------
# Global state
# --------------------------------------------------
G PROGRAM_MEMORY_START
G RenderLine


:ProgramUsed         0           # WORD
G ProgramLineCount
:ProgramLineCount    0           # WORD
G ProgramLineCapacity
:ProgramLineCapacity 0           # WORD

:FirstLinePtr        0           # WORD

:FreePtr             0           # WORD

G ProgramLinCount
:ProgramLineCount    0           # WORD

G LineTableBase
:LineTableBase       0           # WORD

G NullProgram
:NullProgram         1           # Word 1 means no program in memory

G RunTimeHeap
:RunTimeHeap           0
:VarHeapBase         0
:VarFirstEntry       0           # WORD, first of used created variables.


:ArenaSize    0         # WORD
# Eval Engine Storage
:BPC          0
:LRL          0
:RET_CODE     0
:RET_ERRTYPE  0
:RET_ERRLINE  0
:RET_ERRDOM   0
:RET_ERRINFO  0
:RUN_ACTIVE   0
:Debug_Mode   0
:InputBuf     0
#


# --------------------------------------------------
# Input buffer (READSI requires full 256 bytes)
# --------------------------------------------------

=INPUTBUF_SIZE 256
G InputBuf
=TOLKBUF_SIZE INPUTBUF_SIZE+INPUTBUF_SIZE+INPUTBUF_SIZE

=LINE_HEADER_SIZE 4
=LINE_ENTRY_SIZE 4

#--------------------------------------------------
# SystemInit, one time system setup.
#--------------------------------------------------
# As the SystemInit setups things like the SoftStack
# it can not safely use SoftStack dependended functions
# So we keep a few words of local storage here.
:InitWorkSize 0
:InitReturn 0

:SystemInit
    #
    # Setup Heap (one time)

    @POPI InitReturn
    
    @PUSH 0xfffe
    @SUB _END_
    @POPI InitWorkSize
    @Call(AV) HeapDefineMemory _END_ InitWorkSize
    @IF_ULT_A 100
        @PRT "Error allocating main heap."
        @END
    @ENDIF
    @POPI RunTimeHeap

    # Create the SoftStack large enough to allow some decent level of funciton recursion.
    =SoftStackSize 2048
    @Call(VA) HeapNewObject RunTimeHeap SoftStackSize
    @DUP @ADD SoftStackSize @SWP
    @CALL SetSSStack
    #
    # Setup in the InputBuf
    @Call(VA) HeapNewObject RunTimeHeap INPUTBUF_SIZE
    @POPI InputBuf

    #
    # Allocate the Basic 100 line LineTableBase  or 4*100

    @Call(VA) HeapNewObject RunTimeHeap 400
    @POPI LineTableBase
    @MA2V 0 ProgramLineCount


    @PRTLN "Initial Memory Map:" 
    @Call(V) HeapListMap RunTimeHeap

    @Call(V) SetDiskHeap RunTimeHeap
    # Initilize DiskOS for Disk00
    @Call(A) FSReadHeader 0
    @IF_ZERO @PRT "File System failed to initilize.\n" @POPNULL @JMP BasicPanic @ENDIF
    @POPNULL    

@PUSHI InitReturn    
@RET
#---------------------------------------------------
# ProgramInit
# Prepears editor and setup for empty basic program
#---------------------------------------------------
:ProgramInit
    # Setup Sentinel Header at offset 0
    
    @MA2V 100 ProgramLineCapacity
    @MA2V 0 ProgramLineCount    
    @MA2V 4 FreePtr

    @MA2V 0 FirstLinePtr

    @MA2V 1 NullProgram
 
@RET
M ZeroOutVar @MA2V 0 %1
#----------------------------------------------------
# RunTimeInit
#----------------------------------------------------
:RunTimeInit
@PUSHRETURN
    
    @MA2V RET_OK RET_CODE
    @ZeroOutVar RET_ERRTYPE
    @ZeroOutVar RET_ERRLINE
    @ZeroOutVar RET_ERRDOM
    @ZeroOutVar RET_ERRINFO
    @MA2V True RUN_ACTIVE

@POPRETURN
@RET

      
    
    
    
    

@POPRETURN
@RET
# --------------------------------------------------
# InitProgramStorage
# --------------------------------------------------

:InitProgramStorage

    #
    #

@RET
# --------------------------------------------------
# FindLine
#
# IN:
#   LineNum
#
# OUT:
#   CurPtr PrevPtr Found
# --------------------------------------------------

:FindLine
@PUSHRETURN

    @LocalVar LineNum 01
    @LocalVar CurPtr  02
    @LocalVar PrevPtr 03
    @LocalVar EndPtr  04
    @LocalVar CurLine 05

    @POPI LineNum

    @MA2V -1 PrevPtr
    @MV2V LineTableBase CurPtr

    # EndPtr = base + count*entrysize
    @PUSHI ProgramLineCount
    @SHL2
    @ADDI LineTableBase
    @POPI EndPtr


:FindLineLoop

    # if CurPtr >= EndPtr → append case
    @PUSHI CurPtr
    @IF_UGE_V EndPtr
        @POPNULL
        @PUSHI CurPtr
        @PUSHI PrevPtr
        @PUSH 0
        @JMP FindLineExit
    @ENDIF
    @POPNULL

    # load current line number
    @PUSHII CurPtr
    @POPI CurLine

    # if CurLine >= LineNum
    @PUSHI CurLine
    @IF_UGE_V LineNum
        @POPNULL
        @PUSHI CurPtr
        @PUSHI PrevPtr

        @IF_EQ_VV CurLine LineNum
            @PUSH 1
        @ELSE
            @PUSH 0
        @ENDIF

        @JMP FindLineExit
    @ENDIF
    @POPNULL
    
    # advance
    @PUSHI CurPtr
    @POPI PrevPtr

    @PUSHI CurPtr
    @ADD LINE_ENTRY_SIZE
    @POPI CurPtr

    @JMP FindLineLoop


:FindLineExit

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

    @PRT "Inserting line: " @PRTI LineNum @PRT " with data: "
    @Call(VVA) HexDump TextPtr TextLen 1

    @Call(V) FindLine LineNum
    @POPI Found
    @POPI PrevPtr
    @POPI CurPtr

    @PRT " Located at: " @PRTHEXI CurPtr

    # delete case
    @IF_EQ_AV 0 TextLen
        @IF_NEQ_AV 0 Found
            @Call(VAA) DeleteLine CurPtr 0 0
        @ENDIF
        @JMP IOD_Exit
    @ENDIF

    # replace case
    @IF_NEQ_AV 0 Found
        @Call(VVV) ReplaceLine CurPtr TextPtr TextLen
    @ELSE
        @Call(VAVAV) InsertLine LineNum 0 TextPtr 0  CurPtr
        @MA2V 0 NullProgram
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
# InsertLine(LineNum, Temp1, TextPtr, Temp2, CurPtr)
# --------------------------------------------------

:InsertLine
@PUSHRETURN
    @LocalVar LineNum 01
    @LocalVar Temp1 02
    @LocalVar TextPtr 03
    @LocalVar Temp2 04
    @LocalVar CurPtr  05
    @LocalVar EndPtr  06
    @LocalVar PIndex  07

    @POPI CurPtr
    @POPI Temp2
    @POPI TextPtr
    @POPI Temp1      # Not currently being used, available as 
    @POPI LineNum

    @PUSHI ProgramLineCount
    @IF_UGE_V ProgramLineCapacity    
       # Reached Current Limit, add space for 50 more lines
       @ADD 50
       @POPI ProgramLineCapacity
       @PUSHI ProgramLineCapacity @SHL2       # *4
       @POPI Temp1
       # Calculate offsets
       @PUSHI CurPtr
       @SUBI LineTableBase
       @POPI Temp2
       @Call(VVV) HeapResizeObject RunTimeHeap LineTableBase Temp1  # Resize preserves data.
       @IF_LT_A 100
          @PRT "Out Of Memory"
          @Call(AA) BasicRaiseError  ERR_MEMORY 0
       @ENDIF
       @POPI LineTableBase
       @PUSHI LineTableBase
       @ADDI Temp2
       @POPI CurPtr
    @ELSE
       @POPNULL
    @ENDIF

    @PUSHI ProgramLineCount
    @SHL2
    @ADDI LineTableBase
    @POPI EndPtr

    
    @ForIV2V PIndex EndPtr CurPtr
       @PUSHII PIndex
       @PUSHI PIndex @ADD 2 @PUSHS
       @PUSHI PIndex @SUB 4 @POPS
       @PUSHI PIndex @SUB 2 @POPS
    @NextBy PIndex -4

    @PUSHI LineNum
    @POPII CurPtr
    @INC2I CurPtr
    @PUSHI TextPtr
    @POPII CurPtr

    @INCI ProgramLineCount

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
    @LocalVar CurPtr 01 
    @LocalVar TextPtr 02
    @LocalVar TextLen 03
    @LocalVar OldText 04
    @LocalVar NewText 05

    @POPI TextLen
    @POPI TextPtr
    @POPI CurPtr

    @PUSHI CurPtr @ADD 2 @PUSHS
    @POPI OldText

    @Call(VV) HeapDeleteObject RunTimeHeap OldText
    @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
    @POPNULL

    @Call(VV) HeapNewObject RunTimeHeap TextLen
    @POPI NewText
    @Call(VVV) strncpy NewText TextPtr TextLen
    
    @PUSHI NewText
    @PUSHI CurPtr @ADD 2 @POPS

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN
    
@RET


# --------------------------------------------------
# DeleteLine(CurPtr, PrevPtr, HasPrev)
# --------------------------------------------------

:DeleteLine
@PUSHRETURN
    @LocalVar CurPtr  01
    @LocalVar Temp02 02
    @LocalVar PIndex  03
    @LocalVar Temp01 04
    @LocalVar EndPtr  05


    @POPI Temp01
    @POPI Temp02
    @POPI CurPtr

    # Free old CurLine string
    @PUSHI CurPtr @ADD 2 @PUSHS
    @IF_NOTZERO
       @POPI Temp1
       @Call(VV) HeapDeleteObject RunTimeHeap Temp1
       @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
       @POPNULL
    @ELSE
       @POPNULL
    @ENDIF

    # EndPtr = LineTableBase + ProgramLineCount*4
    @PUSHI ProgramLineCount
    @SHL2
    @ADDI LineTableBase
    @POPI EndPtr

    @ForIV2V PIndex CurPtr EndPtr
       @PUSHI PIndex @ADD 4 @PUSHS
       @PUSHI PIndex @ADD 6 @PUSHS
       @PUSHI PIndex @ADD 2 @POPS
       @POPII PIndex
    @NextBy PIndex 4

    @DECI ProgramLineCount

    @RestoreVar 05
    @RestoreVar 04
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
   
   @MV2V InputBuf OutStrPtr

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
   @POPS           # This should put LF hex 0xa and null at end of line

   @PUSHI InputBuf

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01   

@POPRETURN
@RET

#--------------------------------------------------
# SAVEMEM(filename)
#--------------------------------------------------
:SAVEMEM
@PUSHRETURN
   @LocalVar Ptr       01
   @LocalVar EndPtr    02
   @LocalVar OutBuf    03
   @LocalVar OutLen    04
   @LocalVar FilePtr   05
   @LocalVar FileName  06
   @LocalVar LineNum   07
   @LocalVar BufLen    08

   @IF_EQ_AV 1 NullProgram
      @PRTLN "No Program."
      @JMP SM_EXIT
   @ENDIF

   @POPI FileName
   @Call(VA) file_open FileName 0x6f77   # "wo"
   @POPI FilePtr
   # Allocate temp ASCII buffer
   @Call(VA) HeapNewObject RunTimeHeap TOLKBUF_SIZE
   @IF_ULT_A 100
      @Call(AA) BasicRaiseError ERR_MEMORY 0      
   @ENDIF
   @POPI OutBuf
   @MV2V LineTableBase Ptr
   @PUSHI LineTableBase
   @PUSHI ProgramLineCount @SHL2   # *4
   @ADDS
   @POPI EndPtr
   @PUSHI EndPtr
   @WHILE_UGT_V Ptr          # While EndPtr > Ptr
      @PUSHII Ptr
      @PRTTOP
      @PRTSP
      @POPNULL
      @PUSHI Ptr @ADD 2 @PUSHS                      # Start of Line
      @ADD 2                                        # Start of Text part
      @Call(VA) RenderLine OutBuf TOLKBUF_SIZE      # Convert tolkenized data in string into human readable string.
      @POPI OutLen
      @PUSH 0 @PUSHI OutBuf @ADDI OutLen            # Null last byte.
      @POPS
      @Call(V) strlen OutBuf
      @POPI OutLen
      @Call(VVV) DiskFileWrite FilePtr OutBuf OutLen
      @IF_ULT_V BufLen
         @PRT "Truncated Write."
      @ENDIF
      @POPNULL      
      @PRTSI OutBuf
      @PRTNL
      @PUSHI Ptr @ADD 4 @POPI Ptr
   @ENDWHILE
   @POPNULL
   @PRTNL
   # Free buffer
   @Call(VV) HeapDeleteObject RunTimeHeap OutBuf
   @POPNULL
   @Call(V) DiskClose FilePtr
   @IF_ZERO
      @PRT "Error Writing File:"
   @ENDIF
   @POPNULL
   
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
        @Call(VV) DiskFileReadLine  FilePtr InputBuf
        @WHILE_NOTZERO
            @POPNULL
            @Call(V) ParseLineOrCommand InputBuf
            @Call(VV) DiskFileReadLine  FilePtr InputBuf
        @ENDWHILE
        @POPNULL
    @ENDIF       
:LM_EXIT
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

   

# Support Tolkenize functions
####
#--------------------------------------
# EmitByte(DataPtr,ByteValue,Size):(DataPtr,Size)
#--------------------------------------
:EmitByte
@PUSHRETURN
   @LocalVar Size 01
   @LocalVar ByteVal 02
   @LocalVar DataPtr 03
   @POPI Size  
   @POPI ByteVal
   @POPI DataPtr

   @PUSHII DataPtr
   @AND 0xff00
   @ORI ByteVal
   @POPII DataPtr

   @INCI DataPtr
   @INCI Size

   @PUSHI DataPtr
   @PUSHI Size

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#
#
#---------------------------------------
# EmitBlock(DataPtr, SrcPtr, Length, Size)
# DataPtr is destination
# SrcPtr is source
# Length is size in bytes of Soruce data
# Size is tracking full size of resulting string/block
#----------------------------------------
:EmitBlock
@PUSHRETURN
   @LocalVar Size    01
   @LocalVar Length  02
   @LocalVar SrcPtr  03
   @LocalVar DataPtr 04
   
   @POPI Size
   @POPI Length
   @POPI SrcPtr
   @POPI DataPtr

   @Call(VVV) memcpy DataPtr SrcPtr Length

   @PUSHI Size @ADDI Length @POPI Size
   @PUSHI DataPtr @ADDI Length @POPI DataPtr

   @PUSHI DataPtr
   @PUSHI Size

   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02   
   @RestoreVar 01
@POPRETURN
@RET

#--------------------------------------
# VarFindByStr(StrPtr,StrLen):VarPtr
#--------------------------------------
:VarFindByStr
@PUSHRETURN
   @LocalVar StrPtr 01
   @LocalVar WalkPtr 02
   @LocalVar StrNum 03
   @LocalVar StrLen 04

   @POPI StrLen
   @POPI StrPtr
   # We only care about the first 2 character of any string name
   @PUSHII StrPtr
   @IF_EQ_AV 1 StrLen
      @AND 0xff   # Its a one character varaible, so ignore upper character
   @ENDIF
   @POPI StrNum

   @MV2V VarFirstEntry WalkPtr    # If VarFirstEntry is zero then there are no variables.
   @WHEN
      @PUSHI WalkPtr
   @DO_NOTZERO
      @ADD VAROFF_Name @PUSHS
      @IF_EQ_V StrNum
         @POPNULL
         # Names match
         @JMP VFBS_Exit
      @ENDIF
      @POPNULL
      @PUSHI WalkPtr
      @ADD VAROFF_Next
      @PUSHS
      @POPI WalkPtr
   @ENDWHEN
   @POPNULL
   # Drop here means no Match
   @MA2V 0 WalkPtr # Result is zero on no match
   :VFBS_Exit
   @PUSHI WalkPtr
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#----------------------------------------
# VarType(VarPtr):TypeValue
#----------------------------------------
:VarType
@PUSHRETURN
   @PUSHS
   @AND 0x7
@POPRETURN
@RET
#---------------------------------------
# VarIsArray(VarPtr):(0|1)
#---------------------------------------
:VarIsArray
@PUSHRETURN
   @PUSHS
   @AND 0x80
   @IF_NOTZERO
      @POPNULL
      @PUSH 1
   @ENDIF
@POPRETURN
@RET
#--------------------------------------
# VarArrayInRange(VarPtr,Index):(0:1)
#--------------------------------------
:VarArrayInRange
@PUSHRETURN
   @LocalVar VarPtr 01
   @LocalVar InIndex 02
   @LocalVar MaxSize 03
   @LocalVar VAResult 04

   @POPI InIndex
   @POPI VarPtr

   @PUSHI VarPtr @ADD VAROFF_Pay1 @PUSHS    # Address of Array Start
   @PUSHS                                   # First word is size of array
   @POPI MaxSize

   @PUSHI InIndex
   @IF_GE_V MaxSize
      @MA2V 0 VAResult
   @ELSE
      @MA2V 1 VAResult
   @ENDIF
   @POPNULL
   @PUSHI VAResult
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
   
#--------------------------------------
# NewVar(StrPtr, StrLen, Type, Index):VarPtr
#--------------------------------------
:NewVar
@PUSHRETURN
    @LocalVar StrPtr     01
    @LocalVar StrNum     02
    @LocalVar TypeVal    03
    @LocalVar ArraySize  04
    @LocalVar WalkPtr    05
    @LocalVar NewStore   06
    @LocalVar NewVarPtr  07
    @LocalVar ArrayMem   08
    @LocalVar StrLen     09

    @POPI ArraySize
    # User should not be passing array bit flag inside type
    @AND 0x7
    @POPI TypeVal
    @POPI StrLen
    @POPI StrPtr
    @PUSHII StrPtr
    @POPI StrNum

    # First Create the new Variable and allocate the space it needs if an array.

    @Call(VA) HeapNewObject RunTimeHeap 10 @IF_ULT_A 100 @PRT "Memory Error" @JMP BasicPanic @ENDIF
    @POPI NewVarPtr    # the 'real' object starts with the name but we pass around the ptr to Type

    # Copy the String into object
    @PUSHII StrPtr
    @IF_EQ_AV 1 StrLen   # Handle case for single letter names.
        @AND 0xff
    @ENDIF
    @PUSHI NewVarPtr @ADD VAROFF_Name
    @POPS

    # Arrays need to allocated but only if ArraySize > 0
    @IF_NEQ_AV 0 ArraySize
       # Its an array, need to calculate size
       @PUSHI ArraySize
       @IF_EQ_VV LONG_TYPE TypeVal
          @SHL            # two words per long
       @ENDIF
       @IF_EQ_VV FLOAT_TYPE TypeVal
          @SHL            # two words per float
       @ENDIF
       #
       # Array data is words or double words, so turn ArraySize into words
       @SHL
       @POPI ArrayMem              # Calculate real size in memory of array.
       @INC2I ArrayMem             # Add spot of DIM size info
       @Call(VV) HeapNewObject RunTimeHeap ArrayMem @IF_ULT_A 100 @PRT "Memmory Error" @JMP BasicPanic @ENDIF
       @POPI NewStore

       # Save that ArraySize in the first word of the space.
       @PUSHI ArraySize
       @POPII NewStore

       # Turn Array Flag on in Type
       @PUSHI TypeVal @OR 0x80 @POPI TypeVal       
    @ELSE
       # Wasn't an array, so NewStore is zeroed
       @MA2V 0 NewStore
    @ENDIF
    #
    # Save the Type
    @PUSHI TypeVal
    @PUSHI NewVarPtr @ADD VAROFF_TypeID
    @POPS
    # Zero out payload words
    @PUSHI NewStore          # Either zero or ptr to array.
    @PUSHI NewVarPtr @ADD VAROFF_Pay1
    @POPS
    @PUSH 0
    @PUSHI NewVarPtr @ADD VAROFF_Pay2
    @POPS
    #
    # Zero out 'Next Var'
    @PUSH 0
    @PUSHI NewVarPtr @ADD VAROFF_Next
    @POPS
    #
    #

    @IF_EQ_AV 0 VarFirstEntry
       # First Variable, set VarFirstEntry to this.
       @MV2V NewVarPtr VarFirstEntry
    @ELSE
        # Find available spot.    
        @MV2V VarFirstEntry WalkPtr
        @PUSHI WalkPtr @ADD VAROFF_Next
        @PUSHS
        @WHILE_NEQ_A 0       # Loop continues until WalkPtr.Next == 0
           @POPI WalkPtr
           @PUSHI WalkPtr @ADD VAROFF_Next
           @PUSHS
       @ENDWHILE
       @POPNULL
       # Now Point the previous Var to this one in the table.
       @PUSHI NewVarPtr
       @PUSHI WalkPtr @ADD VAROFF_Next
       @POPS
    @ENDIF
    #
    @PUSHI NewVarPtr
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
#
#---------------------------------------
# DelVar(VarPtr):(0|1)
#---------------------------------------
:DelVar
@PUSHRETURN
   @LocalVar VarPtr 01
   @LocalVar WalkPtr 02

   @POPI VarPtr

   @IF_EQ_AV 0 VarFirstEntry
      @PUSH 0     # Error can't delete if list is empty.
      @JMP DVM_Exit
   @ENDIF
   @IF_EQ_VV VarFirstEntry VarPtr
      # Deleting the first entry, new First will be current second
      @PUSHI VarFirstEntry @ADD VAROFF_Next
      @PUSHS
      @POPI VarFirstEntry
      # Delete VarPtr
      @PUSHI RunTimeHeap
      @PUSHI VarPtr @ADD VAROFF_Name
      @CALL HeapDeleteObject
      @IF_NOTZERO
         @POPNULL
         @PRT "Failed to clean up old Variables."
         @END
      @ENDIF
      @POPNULL
      @PUSH 1
      @JMP DVM_Exit
   @ENDIF
   # Else delete interior node.
   @MV2V VarFirstEntry WalkPtr
   @WHEN
      @PUSHI WalkPtr @ADD VAROFF_Next
      @PUSHS
      @IF_EQ_A 0
         # End of List, end loop
         @POPNULL   # Remove WalkPtr.Next
         @PUSH 2    # Two will mean, no match exit.         
      @ELSE
         @IF_EQ_V VarPtr
            # Found Match
            @POPNULL   # Remove WalkPtr.Next
            @PUSH 1    # One means Match found exit.
            @PUSHI VarPtr @ADD VAROFF_Next
            @PUSHS
            @PUSHI WalkPtr @ADD VAROFF_Next
            @POPS      # Points WalkPtr.Next to VarPtr.Next
            # Now clean out old object
            @PUSHI RunTimeHeap
            @PUSHI VarPtr @ADD VAROFF_Name
            @CALL HeapDeleteObject
         @ELSE
            @POPNULL
            @PUSH 0
         @ENDIF
      @ENDIF
   @DO_ZERO
      @POPNULL
      @PUSHI WalkPtr @ADD VAROFF_Next
      @PUSHS
      @POPI WalkPtr
   @ENDWHEN
   @IF_EQ_A 2
      # No Match
      @POPNULL
      @PUSH 0
   @ENDIF   
:DVM_Exit
   @RestoreVar 02
   @RestoreVar 01
 @POPRETURN
 @RET
 #
 #-------------------------------------------------
 # SetVarVal(VarPtr,ValueLow,ValueHigh,Index, VarType):(0|1)
 #--------------------------------------------------
:SetVarVal
@PUSHRETURN
    @LocalVar VarPtr     01
    @LocalVar ValLow     02
    @LocalVar ValHigh    03
    @LocalVar VarIndex   04
    @LocalVar VarTypeIn  05
    @LocalVar ActualType 06
    @LocalVar ArrayPtr   07
    @LocalVar Offset     08
    @LocalVar TargetPtr  09

    @POPI VarTypeIn
    @POPI ValHigh
    @POPI ValLow
    @POPI VarIndex    
    @POPI VarPtr

    @PUSHI VarPtr @ADD VAROFF_TypeID @PUSHS
    @DUP
    @AND 0xf
    @POPI ActualType

    @IF_NEQ_VV ActualType VarTypeIn
       @POPNULL
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

    @AND 0x80
    @IF_NOTZERO
       @POPNULL
       # Array Case
       @PUSHI VarPtr @ADD VAROFF_Pay1 @PUSHS
       @POPI ArrayPtr
       @PUSHII ArrayPtr
       @IF_ULE_V VarIndex
          @POPNULL
          @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
       @ENDIF
       @POPNULL
       #
       # Compute offset
       @PUSHI VarIndex
       @SHL
       @POPI Offset
       @IF_EQ_AV LONG_TYPE ActualType
           @PUSHI Offset @SHL @POPI Offset
       @ELSE
          @IF_EQ_AV FLOAT_TYPE ActualType
              @PUSHI Offset @SHL @POPI Offset
          @ENDIF
       @ENDIF
       # Final Pointer
       @PUSHI Offset
       @ADD 2       # Skip Array Size field
       @ADDI ArrayPtr
       @POPI TargetPtr
       #
       @IF_NEQ_AV STRING_TYPE ActualType
          @PUSHI ValLow
          @POPII TargetPtr
          @IF_NEQ_AV INT_TYPE ActualType
             @INC2I TargetPtr
             @PUSHI ValHigh
             @POPII TargetPtr
          @ENDIF
       @ELSE
          # Stringe Case          
          @PUSHII TargetPtr
          @IF_NOTZERO
             @POPNULL
             # Delete old String
             @PUSHI RunTimeHeap
             @SWP
             @CALL HeapDeleteObject
             @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
             @POPNULL
          @ELSE
             @POPNULL
          @ENDIF
          @PUSHI ValLow
          @POPII TargetPtr          
       @ENDIF
    @ELSE
       @POPNULL
       #Not an Array Case
       @PUSHI VarPtr       
       @ADD VAROFF_Pay1
       @POPI TargetPtr       
       @PUSHI ValLow
       @POPII TargetPtr
       @IF_NEQ_AV INT_TYPE ActualType
          @INC2I TargetPtr
          @PUSHI ValHigh
          @POPII TargetPtr
       @ENDIF
    @ENDIF
    @PUSHI VarPtr

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
#
#------------------------------------------
# GetVarVal(VarPtr,Index):(ValueLow,ValueHigh)
#------------------------------------------

#------------------------------------------
# GetVarVal(VarPtr,Index):(ValueLow,ValueHigh)
# Always returns 2 words
#------------------------------------------
:GetVarVal
@PUSHRETURN
   @LocalVar VarPtr   01
   @LocalVar IndexIn  02
   @LocalVar ArrayPtr 03
   @LocalVar VarType  04

   @POPI IndexIn
   @POPI VarPtr

   #----------------------------------
   # Validate VarPtr
   #----------------------------------
   @IF_NEQ_AV 0 VarPtr

      #----------------------------------
      # Load VarType
      #----------------------------------
      @PUSHI VarPtr @ADD VAROFF_TypeID @PUSHS
      @DUP
      @AND 0xf
      @POPI VarType

      #----------------------------------
      # Check if Array
      #----------------------------------
      @AND 0x80
      @IF_NOTZERO

         #----------------------------------
         # ARRAY CASE
         #----------------------------------
         @POPNULL

         # Load base pointer
         @PUSHI VarPtr @ADD VAROFF_Pay1 @PUSHS
         @POPI ArrayPtr

         # Bounds check
         @PUSHII ArrayPtr
         @IF_UGE_V IndexIn

            @POPNULL

            #----------------------------------
            # Compute element offset
            #----------------------------------
            @PUSHI IndexIn
            @SHL                    # *2 (word)
            @POPI IndexIn

            # If wide (LONG/FLOAT), double again
            @IF_EQ_AV LONG_TYPE VarType
               @PUSHI IndexIn
               @SHL
               @POPI IndexIn
            @ELSE
               @IF_EQ_AV FLOAT_TYPE VarType
                  @PUSHI IndexIn
                  @SHL
                  @POPI IndexIn
               @ENDIF
            @ENDIF

            # Add to base
            @PUSHI IndexIn
            @ADD 2                  # Skip the Array Size Entry            
            @ADDI ArrayPtr
            @POPI ArrayPtr

            #----------------------------------
            # LOAD VALUE
            #----------------------------------
            @PUSHII ArrayPtr        # LoWord

            @IF_EQ_AV LONG_TYPE VarType
               @INC2I ArrayPtr
               @PUSHII ArrayPtr     # HighWord
            @ELSE
               @IF_EQ_AV FLOAT_TYPE VarType
                  @INC2I ArrayPtr
                  @PUSHII ArrayPtr  # HighWord
               @ELSE
                  @PUSH 0           # HighWord = 0 (scalar)
               @ENDIF
            @ENDIF

         @ELSE
            @POPNULL
            @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
         @ENDIF

      @ELSE

         #----------------------------------
         # SCALAR CASE
         #----------------------------------
         @POPNULL

         # Low word
         @PUSHI VarPtr @ADD VAROFF_Pay1 @PUSHS

         # High word
         @IF_EQ_AV LONG_TYPE VarType
            @PUSHI VarPtr @ADD VAROFF_Pay2 @PUSHS
         @ELSE
            @IF_EQ_AV FLOAT_TYPE VarType
               @PUSHI VarPtr @ADD VAROFF_Pay2 @PUSHS
            @ELSE
               @PUSH 0
            @ENDIF
         @ENDIF
      @ENDIF

   @ELSE
      # Invalid variable
      @Call(AA) BasicRaiseError ERR_UNDEF_VAR 0
   @ENDIF

   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

M SIZESINCECOMMENT basic_storage.h
@SIZESINCE  


            
