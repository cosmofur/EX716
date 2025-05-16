# Set Code start at 0x7700, we're just using 16bit memory, so no long jumps needed.
I common.mc
L string.ld
L heapmgr.ld
L softstack.ld


@JMP Main     # Make sure if we drop here from unexpected early jump, we still make it to Main.

# Storage

# Define the main storage variables, including the RP and SP stack pointers.
:TIB 0
:TV 0
:MainHeap 0
:HERE 0
:COMPILEBUFFER 0
:INPUTBUFFER 0
:STATE 0
:TOIN 0
:RP0 0
:RP 0
:SP0 0
:SP 0
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
#
# @ (addr -- x)   Fetch memory at addr
# Start the built in words at 0x200

@DEFWORD "@" FETCH 0
@FPOP
@PUSHS
@FPUSH
@NEXT

#
# ! ( x addr -- )    Store x at addr
@DEFWORD "!" STORE 0
@FPOP
@FPOP
@POPS
@NEXT
#
# sp@ ( -- addr )   Get Current data stack pointer
@DEFWORD "sp@" SPFETCH 0
@PUSHI SP
@FPUSH
@NEXT
#
# rp@ ( -- addr)    Get current return stack pointer
@DEFWORD "rp@" RPFETCH 0
@PUSHI RP                             # RP is Logic Stack Pointer
@BPUSH
@NEXT
#
# -= ( X -- f )     -1 of top of stack is 0, 0 otherwise
@DEFWORD "0=" ZEROEQUALS
@FPOP                 # I think there more efficient ways of doing this.
@FPOP
@IF_EQ_S
   @FPUSH
   @FPUSH
   @PUSH 0
@ELSE
   @FPUSH
   @FPUSH
   @PUSH -1
@ENDIF
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






@DEFWORD "latest" LATESTVAR 0
@PUSHII LATEST
@FPUSH
@NEXT


# define some IO primitives

@DEFWORD "key" KEY
@READC TV
@PUSHI TV
@NEXT
#
@DEFWORD "emit" EMIT 0
@AND 0xff
@POPI TV
@PRTSI TV
@NEXT

:LATEST LATEST+2   # Initialized to last word in built in dictionary.

@DEFWORD "FNC_IMMEDIATE" FNC_IMMEDIATE 0
@FPUSH
@NEXT








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
@PRT "\nBefore Setup:\n" @PUSHI MainHeap @CALL HeapListMap
@PUSHI MainHeap @PUSH SoftHeapSize
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 219" @END @ENDIF
@DUP @ADD SoftHeapSize @SWP
@CALL SetSSStack
@PRT "\nAfter Stack Setup:\n" @PUSHI MainHeap @CALL HeapListMap
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
@MV2V COMPILEBUFFER HERE
@PRT "\nAfter Setup:\n" @PUSHI MainHeap @CALL HeapListMap
#
@PUSHI RP0 @ADD RP0Size @SUB 2 @POPI RP
@PUSHI SP0 @ADD SP0Size @SUB 2 @POPI SP
@ForIA2B TV 0 InputBufferSize
   @PUSH 0 @PUSHI TV @ADDI INPUTBUFFER @POPS
@Next TV
:Break02
@RET
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
   @IF_EQ_A " \0"
      @INCI instr
      @POPNULL
      @PUSHII instr @AND 0xff
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
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
@LocalVar Entry 02
@LocalVar WordVal 03
@LocalVar FlagVal 04

# Zero out first word so first call to parse will always be null
:Break01
@MV2V INPUTBUFFER TIB
@PUSH 0 @POPII TIB
# Start Loop
@PUSH 0
@WHILE_ZERO
    @PRT "Main Loop: " @PRTSI TIB @PRTNL
    @PUSHI TIB
    @CALL GetNextWord
    @IF_ZERO
       # Input was Null, get a new line
       @MV2V INPUTBUFFER TIB
       @PRT "OK? "
       @READSI TIB
       @JMP InterContinue
    @ENDIF
    # We get here only if TOS has valid token info.
    # (Tolkien, new TIB)
    @POPI TIB
    @DUP @POPI WordVal
    @CALL SearchDictionary
    @POPI Entry
    @IF_EQ_AV 0 Entry
       # Fallback to try parsing as number
       @PUSHII WordVal @AND 0xff
       @IF_INRANGE_AB "0\0" "9\0"
          @POPNULL
          @PUSHI WordVal
          @CALL stoifirst    # Convert string to number
          @PUSH FNC_IMMEDIATE  # Point to function that moves HW stack # to SP Stack
          @CALL execute
          @JMP InterContinue
       @ELSE
          # Null Entry means unknown word, handle as error.
          @POPNULL
          @PUSH "Unknown Word.(" @PRTSI WordVal @PRT ")\n"
          @MV2V INPUTBUFFER TIB
          @PUSH 0 @POPII TIB
          @JMP InterContinue
       @ENDIF
    @ELSE
       # Was a valid Word, so there should also be a FLAG
       @POPI FlagVal
    @ENDIF
    # Here means we have a valid Entry
    # address is the execution address for that word
    # flag controls is that word has the F_IMMEDIATE bit set which means
    # that even when in compile state, you execute immediately.
    @PUSHI FlagVal
    @AND F_IMMEDIATE
    @IF_ZERO
       @POPNULL
       @IF_EQ_AV 0 STATE
          # State == 0 so do immediate exec
          @PUSHI Entry
          @CALL execute
          @JMP InterContinue
       @ELSE
          # TOS will have execution address
          @PUSHI Entry
          @CALL Compile
          @JMP InterContinue
       @ENDIF
   @ELSE
       @POPNULL
       # TOS will have execution address
       @PUSHI Entry
       @CALL execute
       @JMP InterContinue
   @ENDIF
:InterContinue
@ENDWHILE
@POPNULL
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#################################################
# Function SearchDictionary(wordstr)
# Searching the Forth Dictionary for word match.
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
      @PRT "CMPing " @PUSHII NameStart @PRTHEXTOP @POPNULL @PRT " <> " @PUSHI Entry @ADD 3 @PUSHS @PRTHEXTOP @POPNULL @PRTNL
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
   @PUSHI Result @ADD 2 @PUSHS @AND 0xff   # Get just the flag for mode tests   
   @PUSHI Result @ADD 2 @ADD NameLength    # Address code starts.
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
:execute
@BPUSH        # Save Reuturn the RP Stack
@PRT "Exec: " @PRTHEXTOP
@CALL DebugStacks
# Whats on TOS should be address of Word code.
@JMPS


#######################################
# Function Compile
:Compile
@FPOP
@PUSHI HERE                # Get value of HERE (i.e., compile address)
@SWP                       # Stack = [addr, value]
@POPS                      # Store value at addr
@INC2I HERE
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

:ENDOFCODE
. Main
