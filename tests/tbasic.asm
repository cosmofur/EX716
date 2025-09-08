I common.mc
L screen.ld
L random.ld
L tokenizer.ld
##########################
#
# Global Storage
:MainHeapID 0
:InputBuf1Ptr 0
:OutputBuf1Ptr 0
:ScratchBuf1Ptr 0
:CodeStore 0
:DataStore 0
:TokenStore 0


##########################
# Reusable locals
#
:index1 0
:index2 0
:index3 0
:index4 0
:char1 0
:strptr1 0
:strptr2 0
##########################
#
# Function initstorage()
:initstorage
@PRT "Start of Init Memory" @StackDump
@PUSH 0xf000
# Call HeapDefineMemory(HighAddress,LowAddress):HeapID
@SUB ENDOFCODE
@PUSH ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeapID
# Call HeapNewObject(HeapID, Size):ObjectPtr
@PUSHI MainHeapID
@PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 41" @END @ENDIF
# Call SetSSStack(HighAddress, LowAddress)
@DUP  # Stack(Low Address, Low Address)
@ADD 0x400 # Stack(Low Address, High Address)
@SWP       # Stack(High Address, Low Address)
@CALL SetSSStack
#
# We will need an Input Buffer, a Print Buffer and a Scratch Buffer.
# Let each be 256 bytes long.
# Call HeapNewObject(HeapID, Size): ObjectPtr
@PUSHI MainHeapID
@PUSH 0x100
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 53" @END @ENDIF
@POPI InputBuf1Ptr
#
@PUSHI MainHeapID
@PUSH 0x100
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 58" @END @ENDIF
@POPI OutputBuf1Ptr
#
@PUSHI MainHeapID
@PUSH 0x100
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 63" @END @ENDIF
@POPI ScratchBuf1Ptr
#
# Setup the initial Code, Data and Token Stores

@PUSHI MainHeapID @PUSH 0x1000 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 68" @END @ENDIF
@POPI CodeStore

@PUSHI MainHeapID @PUSH 0x1000 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 71" @END @ENDIF
@POPI DataStore

@PUSHI MainHeapID @PUSH 0x1000 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 74" @END @ENDIF
@POPI TokenStore

#
# Setup the initil headers for these stores
#
# CodeStore Header
#   w0:MaxCurrentSize Bytes w1:UsedSize Bytes w2: MaxLines w3: PtrFirstLine
@PUSH 0x1000 @PUSHI CodeStore @POPS
#
@PUSH 0 @PUSHI CodeStore @ADD 2 @POPS
#
@PUSH 0 @PUSHI CodeStore @ADD 4 @POPS
#
@PUSHI CodeStore @ADD 8 @PUSHI CodeStore @ADD 6 @POPS
#
# DataStore Header
#     w0:MaxCurrentSize Bytes w1:UsedSize Bytes w2:MaxEntries w3:PtrFirstData
@PUSH 0x1000 @PUSHI DataStore @POPS
#
@PUSH 0 @PUSHI DataStore @ADD 2 @POPS
#
@PUSH 0 @PUSHI DataStore @ADD 4 @POPS
#
@PUSHI DataStore @ADD 8 @PUSHI DataStore @ADD 6 @POPS
#
# TokenStore only needs to make sure first two words are 0, Token's have their own strucutre
@PUSH 0 @POPII TokenStore
@PUSH 0 @PUSHI TokenStore @ADD 2 @POPS
#
# Now start loading into the TokenStore the first fixed keywords
# We'll add some macros to handle the call to inserttoken
#  AB is for immediate data both string and value
#  AV is for immediate string and variable value
#  VV is for both variable string ptr and value
M LoadTokenAB @JMP %0_skip :%0_string %1 :%0_skip @PUSH %0_string @PUSH %2 @CALL inserttoken
M LoadTokenAV @JMP %0_skip :%0_string %1 :%0_skip @PUSH %0_string @PUSHI %2 @CALL inserttoken
M LoadTokenVV @PUSHI %1 @PUSHI %2 @CALL inserttoken
@PRT "Before calliong inserttoken... " @StackDump
=QUITCODE 101
=RUNCODE 102
=LISTCODE 104
=IFCODE 105
=THENCODE 106
=EQUALCODE 107
=ADDCODE 108
=SUBCODE 108
=MULCODE 110
=DIVCODE 111
=MODCODE 112
=SHLCODE 113
=SHRCODE 114
=LTCODE 115
=LECODE 116
=GTCODE 117
=GECODE 118
=LETCODE 119
=WHILECODE 120
=WENDCODE 121
=PRINTCODE 122
=INPUTCODE 123
@LoadTokenAB "QUIT\0" QUITCODE
@LoadTokenAB "RUN\0" RUNCODE
@LoadTokenAB "LIST\0" LISTCODE
@LoadTokenAB "IF\0" IFCODE
@LoadTokenAB "THEN\0" THENCODE
@LoadTokenAB "=\0" EQUALCODE
@LoadTokenAB "+\0" ADDCODE
@LoadTokenAB "-\0" SUBCODE
@LoadTokenAB "*\0" MULCODE
@LoadTokenAB "/\0" DIVCODE
@LoadTokenAB "%\0" MODCODE
@LoadTokenAB "<<\0" SHLCODE
@LoadTokenAB ">>\0" SHRCODE
@LoadTokenAB "<=\0" LECODE
@LoadTokenAB "=<\0" LECODE
@LoadTokenAB "<\0" LTCODE
@LoadTokenAB ">=\0" GECODE
@LoadTokenAB "=>\0" GECODE
@LoadTokenAB ">\0" GTCODE
@LoadTokenAB "LET\0" 114
@LoadTokenAB "WHILE\0" 115
@LoadTokenAB "WEND\0" 116
@LoadTokenAB "PRINT\0" 117





@PRT "End of Init Memory" @StackDump
@RET
#
#
#############################
# Read Line into input buffer.
#
# Someday mayreplace this with an editing interface but for now just use the built in READSI
:ReadLineInput
@READSI InputBuf1Ptr
@RET
############################
# Function inserttoken(stringptr,value)
# Adds string and value to the tokenizer TokenData
:inserttoken
# Here is a technique to give local variables useful names while reusing common storage.
=Value index1
=SizeToken index2
=WalkPtr index3
=UsedSize index4
#
@PUSHRETURN
@PUSHLOCALI Value
@PUSHLOCALI SizeToken
@PUSHLOCALI WalkPtr
@PUSHLOCALI UsedSize
@PUSHLOCALI strptr1
#
@POPI Value
@POPI strptr1
#
@PUSHI strptr1 @CALL strlen @ADD 4 @POPI SizeToken # SizeToken = size of new token
#
# Get the used size of current object
@PUSHI TokenStore @ADD 2 @POPI WalkPtr
@PUSHII WalkPtr
@WHILE_NOTZERO
   @POPI WalkPtr
   @PUSHII WalkPtr  # Walk down the token structure.
@ENDWHILE
@POPNULL
@PUSHI WalkPtr @SUBI TokenStore # This will be the size of used space in TolkeStore
@ADDI SizeToken      # add in needed size for new token.
@POPI UsedSize      
# If UsedSize > than the maxsize of the current TokenStore, we need to expand it.
# Call GetObjectRealSize(TokenStore)
@PUSHI MainHeapID
@PUSHI TokenStore
@CALL GetObjectRealSize
@IF_LT_V UsedSize
   # need to expand the object for more space.
   # Call HeapResizeObject(HeapID,ObjectID,newsize)
   @POPNULL
   @PUSHI MainHeapID
   @PUSHI TokenStore
   # We want to expand it infrquently as its expensive, but we also want to use a reasonable number
   # Picking 256 bytes for each expansion UNLESS the SizeToken size is larger than that, then use that number
   @PUSHI SizeToken
   @IF_LT_A 0xf0
      @POPNULL   # SizeToken is < 256 so we'll bump up by just 256
      @PUSH 0x100
   @ENDIF
   @ADDI UsedSize
   @CALL HeapResizeObject
   @IF_LT_A 100
     @PRT "Error expanding TolkeStore, likely out of memory." @PRTTOP @PRTNL
     @END
   @ENDIF
   @POPI TokenStore
   # Because we resized TokenStore, the WalkPtr is no longer valid. Re-do it
   @PUSHI TokenStore @ADD 2 @POPI WalkPtr
   @PUSHII WalkPtr   
   @WHILE_NOTZERO
      @POPI WalkPtr
      @PUSHII WalkPtr
   @ENDWHILE
   @POPI WalkPtr     # This should be address of where to put the new token
@ELSE
   @POPNULL
@ENDIF
@PUSHI UsedSize @ADDI  SizeToken @POPI UsedSize # Save the NewSize at top of strucutre
@PUSHI UsedSize
@POPII TokenStore
#
# At location WalkPtr is put the address of the future 'next' token
# this is addres + SizeToken + 2
@PUSHI WalkPtr @ADDI SizeToken @ADD 2
@POPII WalkPtr
# Now put the numeric Value in the WalkPtr+2 word
@PUSHI Value
@PUSHI WalkPtr @ADD 2
@POPS
# Now Copy the StrPtr to WalkPtr + 4
@PUSHI WalkPtr @ADD 4        # Destination
@PUSHI strptr1
@PUSHI SizeToken @SUB 4      # We already got strlen, just remove the extra two words.
@CALL memcpy
#
# Now just make sure the address of future 'next' token is zeroed out
@PUSH 0
@PUSHII WalkPtr
@POPS
#
@POPLOCAL strptr1
@POPLOCAL UsedSize
@POPLOCAL WalkPtr
@POPLOCAL SizeToken
@POPLOCAL Value
@POPRETURN
@RET
#############################
# Command Line Parce
# CommandLine(strptr): (-1:exit,0:continue, other errocode)
#
:CommandLine
@PUSHRETURN
#
@POPI strptr1
# GetNextWord(index1,Scratch,TermChars,SepChars):Length
  @PUSHI strptr1
  @PUSHI ScratchBuf1Ptr
  @PUSH TermCharOne
  @PUSH SepCharOne
@CALL GetNextWord
@POPI index1          # Save the length of that first word. We'll need it later
# Tokenize(string, StartDatabase, EndDatabase)
@PUSHI ScratchBuf1Ptr
@PUSHI TokenStore @ADD 2    # Start Token Database
@PUSHII TokenStore          # Used size
@ADDI TokenStore            # EndDatabase = UsedSize+TokenStore
@CALL Tokenize
#
# Result of Tokenize will be either a valid keyword tolken or 999 for any unrecognized words.
# if we get 999 then we need to examine ScratchBuf1Ptr for possible line number
# otherwise its and error.
@IF_EQ_A 999
   @POPNULL
   # Line Number or error?
   @PUSHII ScratchBuf1Ptr @AND 0xff  #Get first character.
   @IF_GE_A "0\0"
      @IF_LE_A "9\0"
         # Is a number, send to Line Insert Replate
         @POPNULL
         @PUSHI strptr1
         @CALL LineCodeEdit   # Returns 0 if no errors.
         @IF_NOTZERO
            @PRT "Error Parsing Line: " @PRTS strptr1 @PRTNL
         @ENDIF
         @POPNULL
      @ENDIF
   @ELSE
      @POPNULL
      @PRT "Not a valid Command: " @PRTS strptr1 @PRTNL
   @ENDIF
@ELSE
  # Returned a TokenCode
  #
  # Some of the commands can use an argument: So if there is one fetch it.
  @PUSH strptr1 @ADDI index1     # start at where next word starts if it exists.
  @PUSHI ScratchBuf1Ptr
  @PUSH TermCharOne
  @PUSH SepCharOne
  @CALL GetNextWord
  # Talkenize the second word...if its there at all
  @IF_NOTZERO
     @PUSHI ScratchBuf1Ptr
     @PUSHI TokenStore @ADD 2
     @PUSHII TokenStore
     @ADDI TokenStore
     @CALL Tokenize
  @ENDIF
  @PUSHI strptr1 @ADDI index1 @POPI strptr1 # For possible future use.
  @POPI index1           # This will be the tolken of the 1st paramert if any  
  @SWITCH
  @CASE QUITCODE
     @PUSH -1   # The exit code
     @CBREAK
  @CASE RUNCODE
     @IF_EQ_VA index1 0
        @PUSH 0          # no arguments, give zero to mean start at top.
        @CALL RUNCODE
     @ELSE
        @PUSHI ScratchBuf1Ptr
        @CALL stoi
        @CALL RUNPROGRAM
     @ENDIF
     @CBREAK
  @CASE LISTCODE
     @IF_EQ_VA index1 0
        @PUSH 0
        @CALL LISTPROC
     @ELSE
        @PUSHI ScratchBuf1Ptr
        @CALL stoi
        @CALL LISTPROC
     @ENDIF
     @CBREAK
  @DEFAULT
     @PRTLN "Not understood."
     @CBREAK
  @ENDSWITCH
  
  
@ENDIF





   


@ADDI strptr1 @POPI strptr1


#############################
# Function Main
#
:TermCharOne
"+-*/=.\n\0"
:SepCharOne
" \t\",\0"
#
:Main . Main
@CALL initstorage
@PUSH 1
@WHILE_NOTZERO
  @POPNULL
  @PRT "> "
  @CALL ReadLineInput
  @MV2V InputBuf1Ptr index1
  @PUSH 0
  @LOOP
      @POPNULL
      # GetNextWord(index1,Scratch,TermChars,SepChars):Length
      @PUSHI index1
      @PUSHI ScratchBuf1Ptr
      @PUSH TermCharOne
      @PUSH SepCharOne
      @CALL GetNextWord
      @ADDI index1 @POPI index1
      @PRT "....>" @PRTSI ScratchBuf1Ptr @PRTNL
      # Look up to see if its has a token      
      # Call Tokenize(String, StartDatabase, EndDatabase)
      @PUSHI ScratchBuf1Ptr           # string
      @PUSHI TokenStore @ADD 2       # Startdatabase
      @PUSHII TokenStore             # Used size
      @ADDI TokenStore               # EndDatabase = UsedSize+TokenStore
      :Break1
      @CALL Tokenize
      @PRT "Code: " @PRTTOP @POPNULL @PRTNL
      @PUSHII index1 @AND 0xff      
  @UNTIL_ZERO
  @PUSH 0
@ENDWHILE
@POPNULL
@END
:ENDOFCODE
