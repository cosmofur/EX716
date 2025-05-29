# Set Code start at 0x7700, we're just using 16bit memory, so no long jumps needed.
I common.mc
L string.ld
L heapmgr.ld
L softstack.ld
############################################################
#  EX716 Forth
#
# Built in words: from 
#
#  ".": Print top           ":": Define Word         ";": End Define
#  "@": Fetch Memory addr   "!": Store at addr       "sp@": Get SP
#  "rp@": Get Return RP     "-=": -1 top stack       "+": Add
#  "nand": NAND             "exit:: (resume?)        "tib": Fetch TIB variable
#  "STATE": Fetch STATE     ">in": Read Text In      "HERE": Fetch HERE
#  "latest": Last Def Word  "key": Read Key          "emit": Print 1 char
#  "words": List known words
# ----------------------------------------------

@JMP Main     # Make sure if we drop here from unexpected early jump, we still make it to Main.

# Storage

# Define the main storage variables, including the RP and SP stack pointers.
:TIB 0
:TV 0
:TVP TV
:MainHeap 0
:HEREPTR 0
:DictPtr 0
:COMPILEBUFFER 0
:INPUTBUFFER 0
:STATE 0
:TOIN 0
:RP0 0
:RP 0
:SP0 0
:SP 0
:IP 0
= SoftHeapSize 1000
= InputBufferSize 255
= RP0Size 1000
= SP0Size 1000
= CodeBufferSize 1000

#  based on SectorForth



############## Dictionary Format
# Link Pointer | Flags+Length | Name | Code...
#  2 bytes         1 bye       Length Variable

=F_HIDDEN 0x40
=LENMASK 0x1f
=F_IMMEDIATE 0x80

# Some macros to turn soft SP into way to move data onto/off hardware stack.
# FPUSH(tos:x) saves tos:x at [SP] then sp-=2
#     Or Pushes HW(tos) to SP(tos)
M FPUSH @PUSHI SP @POPS \
        @PUSHI SP @SUB 2 @POPI SP
# FPOP puts on tos value at [SP--2]
#     Of Pops SP(tos) to HW(tos)
M FPOP @PUSHI SP @ADD 2 @DUP \
       @POPI SP \
       @PUSHS
# Swaps the two top values of [SP] and [SP-2]
M FSWP @PUSHI SP @PUSHS \
       @PUSHI SP @ADD 2 @PUSHS \
       @PUSHI SP @POPS \
       @PUSHI SP @ADD 2 @POPS
# BPUSH(tos:x) saves tos:x at [BP] then rp-=2
#    Or Pushes HW(tos) to BP(tos)
M BPUSH @PUSHI RP @POPS \
        @PUSHI RP @SUB 2 @POPI RP
# BPOP puts on tos value at [RP--2]
#    Of Pops BP(tos) to HW(tos)
M BPOP @PUSHI RP @ADD 2 @DUP \
       @POPI RP \
       @PUSHS
M FCALL @PUSH 0 @PUSH J_%0 @BPUSH @JMP %1 :J_%0

# Macro Defines a Dictionary entry, 3 required arguments "String" Label Flags (must be 0 if not used)
# First create label named "Word_%2" value is address of previous WORD/LINK
# Second redefined LINK to point to this entry for future entries.
# Next Use special macro function %STRLEN to set macro variable %%LEN == length of %1
# Save bytes Length of "String %1" plus value of flags %3
MF LINK 0
M DEFWORD :Word_%2 \
          @LINK \
          MF LINK Word_%2 \
          %STRLEN %1 \
          $$%3+%%LEN \
          %1 \
          :%2

M NEXT @JMP next
# . ( -- )        Print integer at top of stack
@DEFWORD "." PRTDOT 0
@FPOP
@PRTTOP @PRTNL
@POPNULL
#@FPUSH
@NEXT

# Major work horse create new Words
@DEFWORD ":" COLON_DEV F_IMMEDIATE
@PUSHI TIB
@CALL GetNextWord
@IF_ZERO
   @PRTLN "Error: Missing content"
   @POPNULL
@ELSE
   # Move TIB down input string, but also preserve current stack.
   @DUP @POPI TIB
   @CALL CreateHeader   # Builds dictionary Entry
#   @FCALL HERE
#   @FPOP
#   @POPI DictPtr
   @MA2V 1 STATE
   @NEXT
@ENDIF
#
# @ (addr -- x)   Fetch memory at addr
@DEFWORD "@" FETCH 0
@FPOP
@PUSHS
@FPUSH
@NEXT
#
# Every ":" needs ";" to end the compile mode.
@DEFWORD ";" SEMICOLON_DEV F_IMMEDIATE
@PUSH EXIT        # End decleration with call to exit
@CALL Compile
@MA2V 0 STATE     # End Compile Mode
@NEXT
#
# LITERAL used for saving in code list immediate data
@DEFWORD "LITERAL" LITERAL 0
@FPOP
@FPUSH
@NEXT


#
# ! ( x addr -- )    Store x at addr
@DEFWORD "!" STORE 0
@FPOP
@FPOP
@SWP
@POPS
@NEXT
#
# sp@ ( -- addr )   Get Current data stack pointer
@DEFWORD "sp@" SPFETCH 0
@PUSHI SP @ADD 2
@FPUSH
@NEXT
#
# rp@ ( -- addr)    Get current return stack pointer
@DEFWORD "rp@" RPFETCH 0
@PUSHI RP @ADD 2                        # RP is Logic Stack Pointer
@FPUSH
@NEXT
#
# -= ( X -- f )     -1 of top of stack is 0, 0 otherwise
@DEFWORD "0=" ZEROEQUALS
@FPOP
@IF_ZERO
   @PUSH -1
   @FPUSH
@ELSE
   @PUSH 0
   @FPUSH
@ENDIF
@POPNULL
@NEXT
#
# + ( x1 x2 -- n )       Add two values at top of stack
@DEFWORD "+" PLUS 0
@FPOP
@FPOP
@ADDS
@FPUSH
@NEXT
#
# nand ( x1 x2 -- n )    NAND two values at top of stack
@DEFWORD "nand" NAND 0
@FPOP
@FPOP
@ANDS
@INV
@FPUSH
@NEXT
#
# exit ( r: addr -0 )   Resume executing at address at top of return stack
@DEFWORD "exit" EXIT 0
@BPOP
@FPUSH
@NEXT
#
# Next function jumps to value at top of stack.
:next
@BPOP
@JMPS
#
#
@DEFWORD "tib" TIBVAR 0
@PUSHI TIB
@FPUSH
@NEXT
@DEFWORD "state" STATEVAR 0
@PUSHI STATE
@FPUSH
@NEXT
@DEFWORD ">in" TOINVAR 0
@PUSHI TOIN
@FPUSH
@NEXT
#
@DEFWORD "HERE" HERE 0
@PUSHI HEREPTR
@FPUSH
@NEXT

@DEFWORD "latest" LATESTVAR 0
@PUSHII LATEST
@FPUSH
@NEXT


# define some IO primitives

@DEFWORD "key" KEY
@READC TV
@PRT "String>" @PRTSI TV @PRTNL
@PUSHI TV @AND 0xff
@FPUSH
@NEXT
#
@DEFWORD "emit" EMIT 0
@FPOP
@AND 0xff
@POPI TV
@PRTS TV
@NEXT
#
@DEFWORD "WORDS" WORDS 0
@CALL DumpDictionary
@NEXT

:LATEST LATEST+2   # Initialized to last word in built in dictionary.

@DEFWORD "FNC_IMMEDIATE" FNC_IMMEDIATE 0
@FPUSH
@NEXT

####################
# Function DCol
# DCol is the execution loop used for colon defined words.
:DCol
@LocalVar WordPtr 01
#@PRTLN "Before Function" @CALL DebugStacks
#@BPUSH      # Save return address to BP Stack.
@MV2V IP WordPtr
@INC2I WordPtr
@PUSHII WordPtr
@WHILE_NEQ_A EXIT
   @PUSH DColReturn
   @BPUSH
   @JMPS
   :DColReturn
   @INC2I WordPtr
   @PUSHII WordPtr
 @ENDWHILE
 @POPNULL
#@PRTLN "After Function" @CALL DebugStacks
 @RestoreVar 01
 @JMP next

:LastBultIn

#####################
# Function CreateHeader
# Modifies 'LATEST' to point to a new Word Definiation and allocates space for it.
:CreateHeader
@PUSHRETURN
@LocalVar NameStart 01
@LocalVar NameEnd 02
@LocalVar NameLen 03
@LocalVar TmpHerePtr 04
@LocalVar Index01 05
@POPI NameEnd
@POPI NameStart
#
# Compute length
# NameLen=NameEnd - NameStart
@PUSHI NameEnd @SUBI NameStart @POPI NameLen
#
# Get Current HerePtr
@MV2V HEREPTR TmpHerePtr
#
# Store LINK at head of new Word
# Memory[HerePtr]=LATEST; HerePtr += 2
@PUSHI LATEST
@POPII TmpHerePtr
@INC2I TmpHerePtr
#
# Save Flags and Length (current flags always zero?)
@PUSHI NameLen 
@SUB 1
@POPII TmpHerePtr
@INCI TmpHerePtr
#
@ForIA2V Index01 1 NameLen
  @PUSHII NameStart @AND 0xff
  @POPII TmpHerePtr
  @INCI TmpHerePtr
  @INCI NameStart
@Next Index01
@PUSH DCol
@POPII TmpHerePtr
@INC2I TmpHerePtr
@MV2V TmpHerePtr DictPtr
#
# Old HEREPTR should have spot where the LATEST should now point to.
@PUSHI HEREPTR
@POPI LATEST
#
# Now move HEREPTR to next free memory
@MV2V TmpHerePtr HEREPTR
#
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET




  





:Main . Main
:start
@CALL init
@CALL interpreter
#
#
:error
   @PRTLN "!!"
   @JMP init
#
#
:init
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeap
#@PRT "\nBefore Setup:\n" @PUSHI MainHeap @CALL HeapListMap
@PUSHI MainHeap @PUSH SoftHeapSize
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 219" @END @ENDIF
@DUP @ADD SoftHeapSize @SWP
@CALL SetSSStack
#@PRT "\nAfter Stack Setup:\n" @PUSHI MainHeap @CALL HeapListMap
@PUSHI MainHeap @PUSH InputBufferSize
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 223" @END @ENDIF
@POPI INPUTBUFFER
@PUSHI MainHeap @PUSH RP0Size
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 226" @END @ENDIF
@POPI RP0
@PUSHI MainHeap @PUSH SP0Size
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 229" @END @ENDIF
@POPI SP0
@PUSHI MainHeap @PUSH CodeBufferSize
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 232" @END @ENDIF
@POPI COMPILEBUFFER
@MV2V COMPILEBUFFER HEREPTR
#@PRT "\nAfter Setup:\n" @PUSHI MainHeap @CALL HeapListMap
#
@PUSHI RP0 @ADD RP0Size @SUB 2 @POPI RP
@PUSHI SP0 @ADD SP0Size @SUB 2 @POPI SP
@ForIA2B TV 0 InputBufferSize
   @PUSH 0 @PUSHI TV @ADDI INPUTBUFFER @POPS
@Next TV
# Save at bottom of call stack, call to clean exit.
@PUSH ExitCode
@BPUSH
@RET
:ExitCode
@PRTNL
@PRTLN "END OF CODE:"
@END
########################################
# Function GetNextWord(instr):[NULL,(WordPtr,out-instr)]
:GetNextWord
@PUSHRETURN
@LocalVar instr 01
@LocalVar Index1 02
@LocalVar WordStart 03
@POPI instr

@PUSHII instr @AND 0xff
@WHILE_NOTZERO        #Skip any starting white-space
   @SWITCH
   @CASE " \0"
      @INCI instr
      @POPNULL
      @PUSHII instr @AND 0xff
      @CBREAK
   @CASE "(\0"      # Skip forward until ")" or 0
      @POPNULL
      @INCI instr
      @PUSHII instr @AND 0xff
      @WHILE_NOTZERO
         @IF_EQ_A ")\0"    # End of Comment
            @POPNULL
            @INCI instr
            @PUSH 0
         @ELSE
            # Anything else is part of comment.
            @POPNULL
            @INCI instr
            @PUSHII instr @AND 0xff
         @ENDIF
      @ENDWHILE
      # If we get here, then we've exited the comment and
      # instr is pointing at either a zero or whatever follows the comment.
      # If it happens to be a space, this will just continue the whitespace skipping.
      @PUSHII instr @AND 0xff
      @CBREAK
   @CDEFAULT
      # Handle cases of neither comment or space, drop out of skip whitepace loop
      @POPNULL
      @PUSH 0
      @CBREAK
   @ENDCASE
@ENDWHILE
@POPNULL
@PUSHII instr @AND 0xff
@MV2V instr WordStart
@WHILE_NOTZERO
   @IF_EQ_A " \0"     # End of word
      @POPNULL
      @PUSH 0
   @ELSE
      @IF_EQ_A 0      # End of string
         @POPNULL
         @PUSH 0
      @ELSE
         # All other characters
         @INCI instr
         @POPNULL
         @PUSHII instr @AND 0xff
      @ENDIF
   @ENDIF
@ENDWHILE
@POPNULL
# Our output will either be Null or the string from WordStart to instr
@IF_EQ_VV instr WordStart
   # empty strings means instr didn't move
   @PUSH 0
@ELSE
   # If instr[0] == space then it mid string word.
   @PUSHII instr @AND 0xff
   @IF_EQ_A " \0"
      # Space means it was word but not end of string
      @POPNULL
      @PUSHII instr    # Get the full 16 bit work so we can modify it
      @AND 0xff00
      @POPII instr     # Zero out the space so word will be valid ASCIIZ string
      @INCI instr      # Move past the 'null' inserted in WordStart String
      @PUSHI WordStart
      @PUSHI instr
   @ELSE
      @POPNULL
      # instr is already pointing at end of string, so no need to further modify
      @POPNULL
      @PUSHI WordStart
      @PUSHI instr
   @ENDIF
@ENDIF
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#
##########################################
# Function interperter()
# Main loop for core forth program.
# It might  be a good idea later to have some way to go directly
# to a start 'word' but for most interactive use, we just prompt for them.
:interpreter
@PUSHRETURN
@LocalVar Token 01
@LocalVar DictEntry 02
@LocalVar WordVal 03
@LocalVar FlagVal 04
# Zero out first word so first call to parse will always be null
@MV2V INPUTBUFFER TIB
@PUSH 0 @POPII TIB
# Start Loop
@PUSH 0
@PRT "Start of Interpreter:"
@PRTNL
@WHILE_ZERO
#    @PRT "Main Loop: " @PRTSI TIB @PRTNL
    @PUSHI TIB
    @CALL GetNextWord
    @IF_ZERO
       # Input was Null, get a new line
#       @CALL DumpDictionary
       @MV2V INPUTBUFFER TIB
       @PRT "OK? "
       @READSI TIB
       @JMP InterContinue
    @ENDIF
    # We get here only if TOS has valid token info.
    # (Tolkien, new TIB)
    @POPI TIB
    @DUP @POPI WordVal
#    @PRT "Processing: " @PRTSI WordVal @PRTNL
    :Break02
    @CALL SearchDictionary   # [ 0 | DictEntry LenFlag CodeEntry ]
    :Break03
    @IF_EQ_A 0
       # Fallback to try parsing as number
       @POPNULL
       @PUSHII WordVal @AND 0xff
       @IF_INRANGE_AB "0\0" "9\0"
          @POPNULL
          @PUSHI WordVal
          @CALL stoifirst    # Convert string to number
          @IF_EQ_AV 0 STATE
             # Handle Imedate version of number in stream.
             @PUSH FNC_IMMEDIATE  # Point to function that moves HW stack # to SP Stack
             @CALL execute
          @ELSE
             # Compiling version of number in stream
             @PUSH LITERAL
             @CALL Compile
             # TOS should have value of imediate number.
             @CALL Compile
          @ENDIF
          @JMP InterContinue
      @ELSE
          # Null Entry means unknown word, handle as error.
          @POPNULL
          @PRT "Unknown Word.(" @PRTSI WordVal @PRT ")\n"
          @MV2V INPUTBUFFER TIB
          @PUSH 0 @POPII TIB
          @JMP InterContinue
       @ENDIF
    @ELSE
       # Was a valid Word, so there should also be a FLAG and IP
       @POPI IP
       @POPI FlagVal
       @POPI DictEntry
       :Break01       
    @ENDIF
    # Here means we have a valid Entry
    @IF_EQ_AV 0 STATE
       # Immediate Mode
       @PUSHI IP
       @CALL execute
       @JMP InterContinue
    @ELSE
       # Compile Mode
       #
       # in Compile Mode, there are some Words which are always 'immediate'
       @PUSHI FlagVal
       @AND F_IMMEDIATE
       @IF_ZERO
          @POPNULL
          # Normal 'Compile'
          @PUSHI IP
          @CALL Compile
          @JMP InterContinue
       @ELSE
          @POPNULL
          # Exception, always Immediate.
          @PUSHI IP
          @CALL execute
          @JMP InterContinue
       @ENDIF
    @ENDIF
:InterContinue
@ENDWHILE
@POPNULL
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#################################################
# Function SearchDictionary(wordstr)
# Searching the Forth Dictionary for word match.
# Return is 0, for no match or [ DictEntry, LenFlag, CodeEntry ]
#                     DictEntry points to first byte of Word Def
#                     CodeEntry points to first byte past the label
:SearchDictionary
@PUSHRETURN
@LocalVar NameStart 01
@LocalVar NameLength 02
@LocalVar EntryPtr 03
@LocalVar Entry 04
@LocalVar Result 05
# By the rules of our GetNextWord parser, NameStart will be an ASCIIZ string
@POPI NameStart
@PUSHI NameStart @CALL strlen @POPI NameLength
#@POPI NameLength
#
@MV2V LATEST EntryPtr
#
@MA2V 0 Result
@PUSHI EntryPtr
@WHILE_NOTZERO
   @CALL ReadDictionary
   @POPI Entry         # Points to Dictionary object
   #
   # Check for hidden
   @PUSHI Entry @ADD 2 @PUSHS @AND F_HIDDEN  # mem[Entry+2] & F_HIDDEN
   @IF_NOTZERO
       @POPNULL
       @PUSHII Entry    # First word in strct is ptr to next entry
       @DUP             # Leave Copy of EntryPtr for next while
       @POPI EntryPtr        
       @JMP EndWhileCont
   @ENDIF
   @POPNULL
   @PUSHI Entry @ADD 2 @PUSHS @AND LENMASK  # mem[Entry+2] & LENMASK
   @IF_EQ_V NameLength      
      # words are at least same length. Do strcmp
#      @PRT "CMPing " @PUSHII NameStart @PRTHEXTOP @POPNULL @PRT " <> " @PUSHI Entry @ADD 3 @PUSHS @PRTHEXTOP @POPNULL @PRTNL
      @POPNULL
      @PUSHI Entry @ADD 3
      @PUSHI NameStart
      @PUSHI NameLength
      @CALL strncmp
      @IF_ZERO
         # Words exactly match, return the entry, leave zero on tos
         @MV2V Entry Result
         @JMP EndWhileCont         
      @ENDIF
   @ENDIF
   # Drop here means the Words aren't matching.
   @POPNULL
   @PUSHII Entry    # First word in strct is ptr to next entry
   @DUP             # Leave Copy of EntryPtr for next while
   @POPI EntryPtr   
:EndWhileCont
@ENDWHILE
@POPNULL
@IF_EQ_AV 0 Result
   @PUSH 0      # Null means did not match known words.
@ELSE
   @PUSHI Result                           # Ptr start found word.
   @PUSHI Result @ADD 2 @PUSHS @AND 0xff   # Get just the flag for mode tests
   @PUSHI Result @ADD 3 @ADDI NameLength   # Address code starts.
   @PUSHI Result
#   @PRTI Result @PRT " Vs " @PRTI COMPILEBUFFER @PRTNL
   @IF_LE_V COMPILEBUFFER
#      @PRT "Built In\n"
      @POPNULL
    @ELSE
      @POPNULL
#      @PRT "New Word\n"
      @PUSHS      
  @ENDIF
@ENDIF
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
######################################
# Function ReadDictionary(entry)
#   more of a place holder if we ever add relocation or paging to words
:ReadDictionary
@PUSHRETURN
@POPI EntryPtr
@PUSHI EntryPtr       # return unmodified
@POPRETURN
@RET

#######################################
# Function: execute
#
# We are dealing with two possible structures here.
# Either the TOS is the address where Builtin's machine code starts.
# OR its pointing to DCol and it needs the address where the Code-List starts.
:execute
@BPUSH        # Save Reuturn the RP Stack
#@CALL DebugStacks
# Whats on TOS should be address of Word code.
@IF_GE_V COMPILEBUFFER
   @PUSHS
@ENDIF
@JMPS


#######################################
# Function Compile
:Compile
@SWP                       # Move Return Address to sft
@PUSHI DictPtr             # Get where to insert.
@POPS                      # Store value at addr
@INC2I DictPtr
@RET

#######################################
# Function DebugStacks
:DebugStacks
@PUSHRETURN
@LocalVar Index1 01
@LocalVar Limit 02

@PRT "-- SP Stack --\n"
@PUSHI SP0 @ADD SP0Size @SUB 2 @POPI Limit
@ForIV2V Index1 SP Limit
   @PRT "SP["
   @PUSHI Index1 @ADD 2 @PUSHS
   @PRTHEXTOP
   @PRT "]\n"
   @POPNULL
@NextBy Index1 2

@PRT "-- RP Stack --\n"
@PUSHI RP0 @ADD RP0Size @SUB 2 @POPI Limit
@ForIV2V Index1 RP Limit
   @PRT "RP["
   @PUSHI Index1 @ADD 2 @PUSHS
   @PRTHEXTOP
   @PRT "]\n"
   @POPNULL
@NextBy Index1 2
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#######################################
# Function DumpDictionary
:DumpDictionary
@PUSHRETURN
@LocalVar Index1 01
@LocalVar NamePtr 02
@LocalVar LastByte 03
@LocalVar HoldOld 04

#@CALL DebugStacks
@MV2V LATEST Index1
@PRT "LATEST:" @PRTHEXI LATEST @PRT ":\n"
@PUSHI Index1
@WHILE_NOTZERO
   @POPNULL
   @PRT "Word ID: " @PRTHEXI Index1 @PRT " "
   @PUSHI Index1 @ADD 3
   @POPI NamePtr
   @PUSHI Index1 @ADD 2
   @PUSHS @AND LENMASK
   @ADDI Index1 @ADD 3 @POPI HoldOld
   @PUSHII HoldOld @POPI LastByte
   @PUSHII HoldOld @AND 0xff00 @POPII HoldOld   
   @PRT "'"
   @PRTSI NamePtr @PRT "' ("   
   @PUSHI LastByte @POPII HoldOld   
   @PUSHII Index1
   @PRTHEXTOP @PRTSP
   @INC2I Index1
   @PUSHII Index1
   @PRTHEXTOP @POPNULL
   @DEC2I Index1
   @PRT ")\n"
   @POPI Index1
   @PUSHI Index1
@ENDWHILE
@POPNULL
@PRTNL
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
:ENDOFCODE
. Main
