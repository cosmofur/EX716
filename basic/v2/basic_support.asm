I common.mc
L string.ld
#
#
# basic/v0/basic_support.asm
# BASIC v0 – Support Functions
#
# Purpose:
#   - BASIC-specific helpers that do not belong in libraries
#   - Resolve editor-shell dispatch targets
#
# This file intentionally avoids:
#   - String algorithms (use string.ld)
#   - Tokenization
#   - Program execution
#
# Included by basic_main.asm after string.ld and basic_storage.asm


# --------------------------------------------------
# ListProgram
# --------------------------------------------------
# Walk BASIC program storage and print each line
# --------------------------------------------------
#--------------------------------------------------
# ListProgram
#--------------------------------------------------
:ListProgram
@PUSHRETURN
   @LocalVar Ptr       01
   @LocalVar DataPtr   02
   @LocalVar OutBuf    03
   @LocalVar EndPtr    04
   @LocalVar OutLen    05

   @IF_EQ_AV 1 NullProgram
      @PRTLN "No Program."
      @JMP LP_EXIT
   @ENDIF
 
   # Allocate temp ASCII buffer
   @Call(VA) HeapNewObject RunTimeHeap TOLKBUF_SIZE
   @IF_ULT_A 100
      @PRT "Memory Error"
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
      @Call(VA) RenderLine OutBuf TOLKBUF_SIZE      # Convert tolkenized data in string into human readable string.
      @POPI OutLen

      @PUSH 0 @PUSHI OutBuf @ADDI OutLen            # Null last byte.
      @POPS

      @PRTSI OutBuf
      @PRTNL
      @PUSHI Ptr @ADD 4 @POPI Ptr
   @ENDWHILE
   @POPNULL
   @PRTNL
   # Free buffer
   @Call(VV) HeapDeleteObject RunTimeHeap OutBuf
   @POPNULL
   :LP_EXIT
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET


#--------------------------------------------------
# RenderLine(DataPtr, OutPtr, MaxLen) : Length
#--------------------------------------------------
:RenderLine
@PUSHRETURN
   @LocalVar DataPtr   01
   @LocalVar OutPtr    02
   @LocalVar MaxLen    03
   @LocalVar TokenID   04
   @LocalVar StrLength 05
   @LocalVar EntryPtr  06
   @LocalVar OutLen    07

   @POPI MaxLen
   @POPI OutPtr
   @POPI DataPtr

   @MA2V 0 OutLen

   @PUSHII DataPtr @AND 0xff
   @POPI TokenID

   @WHILE_NEQ_AV EOL_TOKEN TokenID

      @PUSHI TokenID
      @SWITCH

      #--------------------------
      # STRING_TOKEN
      #--------------------------
      @CASE STRING_TOKEN
         @POPNULL

         # emit "
         @Call(VAV) EmitByte OutPtr "\"\0" OutLen
         @POPI OutLen
         @POPI OutPtr

         @INCI DataPtr
         @PUSHII DataPtr @AND 0xff
         @POPI StrLength
         @INCI DataPtr

         @Call(VVVV) EmitBlock OutPtr DataPtr StrLength OutLen
         @POPI OutLen
         @POPI OutPtr

         @PUSHI DataPtr @ADDI StrLength @POPI DataPtr

         # emit closing "
         @Call(VAV) EmitByte OutPtr "\"\0" OutLen
         @POPI OutLen
         @POPI OutPtr
         
         @Call(VAV) EmitByte OutPtr " \0" OutLen
         @POPI OutLen
         @POPI OutPtr                              

         @CBREAK

      #--------------------------
      # Numeric Token
      #--------------------------
      @CASE_RANGE INT_TOKEN FLOAT_TOKEN
         @POPNULL

         @INCI DataPtr
         @PUSHII DataPtr @AND 0xff
         @POPI StrLength
         @INCI DataPtr

         @Call(VVVV) EmitBlock OutPtr DataPtr StrLength OutLen
         @POPI OutLen
         @POPI OutPtr
         
         @Call(VAV) EmitByte OutPtr " \0" OutLen
         @POPI OutLen
         @POPI OutPtr                     
         @PUSHI DataPtr @ADDI StrLength @POPI DataPtr
         @CBREAK

      #--------------------------
      # VAR_TOKEN
      #--------------------------
      @CASE VAR_TOKEN
         @POPNULL
         @INCI DataPtr
         @PUSHII DataPtr @AND 0xff
         @POPI StrLength
         @INCI DataPtr

         @Call(VVVV) EmitBlock OutPtr DataPtr StrLength OutLen
         @POPI OutLen
         @POPI OutPtr

         @Call(VAV) EmitByte OutPtr " \0" OutLen
         @POPI OutLen
         @POPI OutPtr                     

         @PUSHI DataPtr @ADDI StrLength @POPI DataPtr
         @CBREAK

      #--------------------------
      # Special operator tokens
      #--------------------------
      @CASE NE_TOKEN
         @POPNULL
         @Call(VAV) EmitByte OutPtr "<\0" OutLen
         @POPI OutLen
         @POPI OutPtr
         @Call(VAV) EmitByte OutPtr ">\0" OutLen
         @POPI OutLen
         @POPI OutPtr
         @INCI DataPtr
         @CBREAK

      @CASE LE_TOKEN
         @POPNULL
         @Call(VAV) EmitByte OutPtr "<\0" OutLen
         @POPI OutLen
         @POPI OutPtr
         @Call(VAV) EmitByte OutPtr "=\0" OutLen
         @POPI OutLen
         @POPI OutPtr
         @INCI DataPtr
         @CBREAK

      @CASE GE_TOKEN
         @POPNULL
         @Call(VAV) EmitByte OutPtr ">\0" OutLen
         @POPI OutLen
         @POPI OutPtr
         @Call(VAV) EmitByte OutPtr "=\0" OutLen
         @POPI OutLen
         @POPI OutPtr
         @INCI DataPtr
         @CBREAK

      #--------------------------
      # Default (ASCII or keyword)
      #--------------------------
      @CDEFAULT        
         @IF_LT_A 0x80
            @POPNULL
            @Call(VVV) EmitByte OutPtr TokenID OutLen
            @POPI OutLen
            @POPI OutPtr
         @ELSE
            @POPNULL
            @Call(V) FindByID TokenID
            @POPI StrLength
            @POPI EntryPtr

            @Call(VVVV) EmitBlock OutPtr EntryPtr StrLength OutLen
            @POPI OutLen
            @POPI OutPtr
            @Call(VAV) EmitByte OutPtr " \0" OutLen
            @POPI OutLen
            @POPI OutPtr            
         @ENDIF

         @INCI DataPtr
         @CBREAK

      @ENDCASE

#      @POPNULL

      @PUSHII DataPtr @AND 0xff
      @POPI TokenID

   @ENDWHILE

   @PUSHI OutLen

   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01

@POPRETURN
@RET


#-------------------------------
# FindByID(TokenID):(EntryPtr,StrLength)
# searchs table looking for ID rather than String.
#-------------------------------
:FindByID
@PUSHRETURN
   @LocalVar TokenID    01
   @LocalVar TablePtr   02
   @LocalVar EntryPtr   03
   @LocalVar StrLength  04
   @LocalVar LastAnswer 05


   @POPI TokenID

   @MA2V KeyWordTable TablePtr
   @PUSHII TablePtr @AND 0xff
   @WHILE_NOTZERO
      @AND 0xff
      @POPI StrLength
      @PUSHI TablePtr @ADD 1 @POPI LastAnswer # Location where string starts
      @PUSHI TablePtr @ADDI StrLength @ADD 1
      @POPI TablePtr
      @PUSHII TablePtr @AND 0xff
      @IF_NEQ_V TokenID
         @POPNULL
         @INC2I TablePtr
         @PUSHII TablePtr @AND 0xff
      @ELSE
         @JMP FBI_FOUND
      @ENDIF
   @ENDWHILE
   @PRT "No Match for " @PRTHEXI TokenID @PRTNL
:FBI_FOUND
   @IF_NOTZERO
      @POPNULL
      @PUSHI LastAnswer
      @PUSHI StrLength
   @ELSE
      @PRTLN "No Match:"
      @POPNULL
   @ENDIF
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

#-----------------------------------
# CleanQuotes(StrPtr):StrPtr
# Moves StrPtr to just past first quote if any
# then turns the second quote, if any, into NULL
#-----------------------------------
:CleanQuotes
@PUSHRETURN
    @LocalVar StrPtr 01
    @LocalVar CharPtr 02
    @LocalVar StrLen 03
    @LocalVar Index 04
    
    @POPI StrPtr

    # IF 1st char is quote, inc StrPtr past quote
    @PUSHII StrPtr @AND 0xff
    @IF_EQ_A "\"\0"
       @INCI StrPtr
    @ENDIF
    @POPNULL

    @Call(V) strlen StrPtr
    @POPI StrLen
    @MA2V 0 Index

    @MV2V StrPtr CharPtr

    # Change any remaining quotes with null
    @ForIA2V Index 0 StrLen
       @PUSHII CharPtr
       @DUP
       @AND 0xff
       @IF_EQ_A "\"\0"
          # Is a quote, replace with null
          @POPNULL
          @AND 0xff00    # Keep high byte
          @POPII CharPtr
       @ELSE
          @POPNULL
          @POPNULL
       @ENDIF
       @INCI CharPtr
    @Next Index
    #
    @PUSHI StrPtr
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#--------------------------------
# IsDigit(ch):0|1
# True if "0" <= ch <= "9" or "-" for negative numbers
#--------------------------------
:IsDigit
@PUSHRETURN
    @LocalVar IDResult 01
    @MA2V 0 IDResult
    @AND 0xff
    @IF_LE_A "9\0"
       @IF_GE_A "0\0"
          @MA2V 1 IDResult
       @ENDIF
    @ENDIF
    @POPNULL
    @PUSHI IDResult
    @RestoreVar 01
@POPRETURN
@RET
#---------------------------------
# IsLetter(ch):0|1
# True is character is letter a-z
#---------------------------------
:IsLetter
@PUSHRETURN
   @LocalVar ILResult 01
   @MA2V 0 ILResult
   @AND 0xff
   # Test for Lowercase
   @IF_GE_A "a\0"
      @IF_LE_A "z\0"
         @AND 0xdf   #Mask out bit 5 to turn to uppercase
      @ENDIF
   @ENDIF
   @IF_GE_A "A\0"
      @IF_LE_A "Z\0"
         @MA2V 1 ILResult
      @ENDIF
   @ENDIF
   @POPNULL
   @PUSHI ILResult
   @RestoreVar 01
@POPRETURN
@RET
#--------------------------------
# IsIdentChar(ch):0|1
# True is a-z or 0-9 or _
#--------------------------------
:IsIdentChar
@PUSHRETURN
    @LocalVar ICResult 01
    @LocalVar TestCh 02
    @AND 0xff
    @POPI TestCh
    @MA2V 0 ICResult

    @PUSHI TestCh
    @SWITCH
    @CASE "_\0"
       @MA2V 1 ICResult
       @CBREAK
    @CASE_RANGE "0\0" "9\0"
       @MA2V 1 ICResult
       @CBREAK
    @CASE_RANGE "A\0" "z\0"
       @MA2V 1 ICResult
       @CBREAK    
    @CASE "#\0"
       @MA2V 1 ICResult
       @CBREAK
    @CASE "%\0"
       @MA2V 1 ICResult
       @CBREAK
    @CASE "$\0"
       @MA2V 1 ICResult
       @CBREAK       
    @CDEFAULT
       @CBREAK        
    @ENDCASE
    @POPNULL
    @PUSHI ICResult
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#------------------------------
# IsWhiteSpace(ch):0|1
# True if space, tab
#------------------------------
:IsWhiteSpace
@PUSHRETURN
   @LocalVar IWResult 01
   @MA2V 0 IWResult
   @AND 0xff
   @IF_EQ_A " \0"             # Space test
      @MA2V 1 IWResult
   @ELSE
      @IF_EQ_A "\t\0"
         @MA2V 1 IWResult       # TAB test
      @ENDIF
   @ENDIF
   @POPNULL
   @PUSHI IWResult
   @RestoreVar 01
@POPRETURN
@RET
#-------------------------------
# IsOperator(ch):0|1
# Tests if character in set "+-*/=<>(),;:"
#-------------------------------
:IsOperator
@PUSHRETURN
   @LocalVar IOResult 01

   @MA2V 0 IOResult
   @AND 0xff
   @SWITCH
   @CASE_RANGE 0x28 0x2d   # Ascii ( to -
      @MA2V 1 IOResult
      @CBREAK
   @CASE_RANGE 0x3a 0x3e   # Ascii : to >
      @MA2V 1 IOResult
      @CBREAK
   @CASE 0x2f              # Ascii /
      @MA2V 1 IOResult
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
   @PUSHI IOResult
   @RestoreVar 01
@POPRETURN
@RET

#-----------------------------------
# TYPEFILE(filename)
# TYPES FileName to screen
#-----------------------------------
:TYPEFILE
@PUSHRETURN
    @LocalVar FileName      01
    @LocalVar FilePtr       02
    @LocalVar LineStatus    03
    @LocalVar LineLen       04

    @POPI FileName

    # Open file for read ("ro")
    @Call(VA) file_open_basic FileName MODE_RO
    @POPI FilePtr

    @IF_EQ_AV 0 FilePtr
       @Call(AA) BasicRaiseError ERR_FILE_NOT_FOUND 0
       @JMP TPM_EXIT
    @ENDIF

    @Call(VVA) DiskFileReadLine  FilePtr InputBuf INPUTBUF_SIZE
    @DUP
    @AND LINE_STATE_MASK
    @POPI LineStatus
    @AND LINE_LEN_MASK
    @POPI LineLen    
    @WHILE_NEQ_AV LINE_EOF LineStatus
        @PRTSI InputBuf
        @PRTNL
        @Call(VVA) DiskFileReadLine  FilePtr InputBuf INPUTBUF_SIZE
        @DUP
        @AND LINE_STATE_MASK
        @POPI LineStatus
        @AND LINE_LEN_MASK
        @POPI LineLen
    @ENDWHILE
:TPM_EXIT
    @IF_NEQ_AV 0 FilePtr
       @Call(V) DiskClose FilePtr
       @POPNULL
    @ENDIF

    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
 @POPRETURN
 @RET
#-------------------------------------
# ERASEDISK(Filepattern)
#-------------------------------------
:ERASEDISK
@PUSHRETURN
@Locals
    @Local Pattern
    @Local StartPoint
    @Local FileNum
    @Local DiskBuff
    @Local ArgTable
    @Local StrPtr
    @Local PromptStr   # We are using READC which only reads 1 byte so safe to use normal word for prompt string.

    @POPI Pattern


    @MA2V 4 StartPoint
    @MA2V 0 FileNum

    @CALL DirNewArgTable @IF_ZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @END @ENDIF
    @POPI ArgTable
    @CALL DiskNewBuffer
    @POPI DiskBuff

    @WHEN
       @Call(VV) FSFindFile Pattern StartPoint
    @DO_NOTZERO
       @POPI FileNum
       @Call(VVV) DirReadEntry FileNum ArgTable DiskBuff
       @IF_ZERO
           @Call(AA) BasicRaiseError ERR_FILE_READ_FAIL 0
           @JMP DD_Exit
       @ENDIF
       @POPNULL
       @PUSHI ArgTable @ADD DIR_AT_FILENAME
       @POPI StrPtr
       @PRTSI StrPtr
       @PRT "\t (Erase Y/N)"
       @READC PromptStr
       @PUSHI PromptStr @AND 0xff
       @IF_GT_A "Z\0"
          @SUB 32   # Change to uppercase
       @ENDIF
       @IF_EQ_A "Y\0"
          @POPNULL
          # Erase file by changing FLAG field from INUSE to DELETED
          @PUSHI ArgTable @ADD DIR_AT_FLAGS @PUSHS
          @PUSH DIR_FLAGS
          @INV
          @ANDS
          @OR FLAG_DELETED
          @PUSHI ArgTable @ADD DIR_AT_FLAGS @POPS
          @Call(VVV) DirWriteRawEntry FileNum ArgTable DiskBuff
          @IF_ZERO
             @POPNULL
             @Call(AA) BasicRaiseError ERR_FILE_WRITE_FAIL 0 
          @ENDIF
          @POPNULL
          @Call(V) FSClearFileUsed FileNum
          @IF_ZERO
             @POPNULL
             @Call(AA) BasicRaiseError ERR_FILE_WRITE_FAIL 0 
          @ENDIF
          @POPNULL
          @CALL FSWriteHeader
          @IF_ZERO
             @Call(AA) BasicRaiseError ERR_FILE_WRITE_FAIL 0 
          @ENDIF
          @POPNULL
       @ELSE
          @POPNULL       
       @ENDIF
       @MV2V FileNum StartPoint
       @INCI StartPoint
   @ENDWHEN
   @POPNULL

   @Call(VV) HeapDeleteObject DiskHeap DiskBuff @IF_NOTZERO  @Call(AA) BasicRaiseError ERR_MEMORY 0 @END @ELSE @POPNULL @ENDIF
   @Call(VV) HeapDeleteObject DiskHeap ArgTable  @IF_NOTZERO  @Call(AA) BasicRaiseError ERR_MEMORY 0 @END @ELSE @POPNULL @ENDIF
   @EndLocals
@POPRETURN
@RET

   


#-------------------------------------
# DIRDISK(Filepattern)
#-------------------------------------
:DIRDISK
@PUSHRETURN
@Locals
    @Local Pattern
    @Local StartPoint
    @Local FileNum
    @Local Count
    @Local DiskBuff
    @Local ArgTable
    @Local StrPtr

    @POPI Pattern


    @MA2V 4 StartPoint
    @MA2V 0 FileNum
    @MA2V 0 Count

    @CALL DirNewArgTable @IF_ZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @END @ENDIF
    @POPI ArgTable
    @CALL DiskNewBuffer
    @POPI DiskBuff

    @PRT "FileName\tSize\tFlags\n"

    @WHEN
       @Call(VV) FSFindFile Pattern StartPoint
    @DO_NOTZERO
       @POPI FileNum
       @INCI Count
       @Call(VVV) DirReadEntry FileNum ArgTable DiskBuff
       @IF_ZERO
           @Call(AA) BasicRaiseError ERR_FILE_READ_FAIL 0
           @JMP DD_Exit
       @ENDIF
       @POPNULL
       @PRTI Count @PRT "> "
       @PUSHI ArgTable @ADD DIR_AT_FILENAME
       @POPI StrPtr
       @PRTSI StrPtr
       @PRT "\t"
       @PUSHI ArgTable @ADD DIR_AT_FILESIZE @PUSHS
       @PUSHI ArgTable @ADD DIR_AT_FILESIZE @ADD 2 @PUSHS       
       @PRT32S

       @PRT "\t"
       @PUSHI ArgTable @ADD DIR_FLAGS @PUSHS
       @PRTHEXTOP
       @POPNULL
       
       @PRTNL
       @MV2V FileNum StartPoint
       @INCI StartPoint
   @ENDWHEN
   @POPNULL   
       
       
:DD_Exit
   @Call(VV) HeapDeleteObject DiskHeap DiskBuff @IF_NOTZERO  @Call(AA) BasicRaiseError ERR_MEMORY 0 @END @ELSE @POPNULL @ENDIF
   @Call(VV) HeapDeleteObject DiskHeap ArgTable  @IF_NOTZERO  @Call(AA) BasicRaiseError ERR_MEMORY 0 @END @ELSE @POPNULL @ENDIF
   @EndLocals
@POPRETURN
@RET
#-----------------------------------
# FindLine(LineNumber): EntryPtr | 0
# Searchs Basic LibeTable for matching LineNumber or 0 if none found
:FindLine
@PUSHRETURN
    @LocalVar TargetLine 01
    @LocalVar Index      02
    @LocalVar EntryPtr   03
    @LocalVar CurLine    04
    @LocalVar Result     05

    @POPI TargetLine

    @MA2V 0 Result
    @MA2V 0 Index
    @MV2V LineTableBase EntryPtr

    @ForIA2V Index 0 ProgramLineCount
        @PUSHII EntryPtr
        @POPI CurLine

        @IF_EQ_VV CurLine TargetLine
            @MV2V EntryPtr Result
            @FORBREAK
        @ENDIF

        # Since table is sorted, stop early if current line is greater.
        @PUSHI CurLine
        @IF_GT_V TargetLine
            @POPNULL
            @FORBREAK
        @ENDIF
        @POPNULL

        @PUSHI EntryPtr
        @ADD 4
        @POPI EntryPtr
    @Next Index

    @PUSHI Result

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#-------------------------------------------------
# ParseQuotedArgument(BuffPtr, MaxLen):(StringPtr, NewBufPtr, Status)
#-------------------------------------------------
:ParseQuotedArgument
@PUSHRETURN
@Locals
   @Local BufPtr
   @Local InMaxLen
   @Local FileData
   @Local Status
   @Local StrLength
   @Local Index1

   @POPI2 InMaxLen BufPtr

   @MA2V 0 Status
   @MA2V 0 FileData

   @LOADBII BufPtr
   @IF_NEQ_A STRING_TOKEN
      @PRTLN "Argument must be a quoted filename"
      @POPNULL
      @JMP PQAExit
   @ENDIF
   @POPNULL
   @INCI BufPtr
   @LOADBII BufPtr
   @POPI StrLength
   @INCI BufPtr            # Move to first character of string.
   @PUSHI StrLength
   @IF_GT_V InMaxLen
      @PRT "Filename is not valid"
      @POPNULL
      @JMP PQAExit
   @ENDIF
   @POPNULL
   @INCI StrLength         # Add one spot for null term   
   @Call(VV) HeapNewObject RunTimeHeap StrLength
   @DECI StrLength         # Return to real size   
   @IF_ULT_A 100
      @PRT "Memory Error"
      @POPNULL
      @JMP BasicPanic
   @ENDIF
   @POPI FileData   
   @MA2V 1 Status          # If nothing goes wrong return 1 as success
   @ForIA2V Index1 0 StrLength
       @PUSHII BufPtr
       @AND 0xff           # ALso makes sure null follows last character.
       @PUSHI FileData @ADDI Index1
       @POPS
       @INCI BufPtr
   @Next Index1

   :PQAExit
   @PUSHI FileData
   @PUSHI BufPtr
   @PUSHI Status
@EndLocals
@POPRETURN
@RET


M SIZESINCECOMMENT basic_support.h
@SIZESINCE  

    
          

    
