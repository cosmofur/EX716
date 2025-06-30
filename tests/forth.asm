# Set Code start at 0x7700, we're just using 16bit memory, so no long jumps needed.
I common.mc
L string.ld
L heapmgr.ld
L softstack.ld
L mul.ld
L div.ld
P Start Of forth.asm
############################################################
#  EX716 Forth
#
# Built in words: from 
#
# ----------------------------------------------

@JMP Main     # Make sure if we drop here from unexpected early jump, we still make it to Main.

# Storage

# Define the main storage variables, including the RP and SP stack pointers.
:TIB 0
:TV 0
:TV2 0
:TV3 0
:TVP TV
:MainHeap 0
:DictPtr 0
:COMPILEBUFFER 0
:INPUTBUFFER 0
:STATE 0
:TOIN 0
:RP0 0
:RP 0
:SP0 0
:SP 0
:LP0 0
:LP 0
:IP 0
:RB_LATEST 0
=HERE DictPtr     # Alias as HERE is more standard.
= SoftHeapSize 1000
= InputBufferSize 255
= RP0Size 1000
= SP0Size 1000
= LP0Size 100
= CodeBufferSize 1000
= IFTAG 1
= ELSETAG 2
= THENTAG 3
= BEGINTAG 4
= DOTAG 5

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
M FSWP \
       @PUSHI SP @ADD 2 @PUSHS \
       @PUSHI SP @ADD 4 @PUSHS \
       @PUSHI SP @ADD 2 @POPS \
       @PUSHI SP @ADD 4 @POPS
# Gets SP TOS but doesn't pop it off.
M FPEEK \
      @PUSHI SP @ADD 2 \
      @PUSHS
# Peek at SFT for SP stack
M FPEEK1 \
      @PUSHI SP @ADD 3 \
      @PUSHS      
      
# BPUSH(tos:x) saves tos:x at [BP] then rp-=2
#    Or Pushes HW(tos) to BP(tos)
M BPUSH @PUSHI RP @POPS \
        @PUSHI RP @SUB 2 @POPI RP
# BPOP puts on tos value at [RP--2]
#    Of Pops BP(tos) to HW(tos)
M BPOP @PUSHI RP @ADD 2 @DUP \
       @POPI RP \
       @PUSHS
M BPEEK \
      @PUSHI RP @ADD 2 \
      @PUSHS
# Peek at SFT for RP stack
M BPEEK1 \
      @PUSHI RP @ADD 3 \
      @PUSHS            
#
# LPUSH(tos:x) saves tos:x at [LP] then lp-=2
#    Or Pushes HW(tos) to LP(tos)
M LPUSH @PUSHI LP @POPS \
        @PUSHI LP @SUB 2 @POPI LP
# LPOP puts on tos value at [LP--2]
#    Of Pops LP(tos) to HW(tos)
M LPOP @PUSHI LP @ADD 2 @DUP \
       @POPI LP \
       @PUSHS
M LPEEK \
      @PUSHI LP @ADD 2 \
      @PUSHS       
# Peek at SFT for LP stack
M LPEEK1 \
      @PUSHI LP @ADD 3 \
      @PUSHS                   
# Macro that puts on HW Stack current HERE point (here - 2 for expected inc2i)
M GET_HERE \
  @PUSHI DictPtr @SUB 2
  
M FCALL @PUSH 0 @PUSH J_%0 @BPUSH @JMP %1 :J_%0
#


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

M FNEXT @JMP next
# . ( -- )        Print integer at top of stack
P Start of First DEFWORD {LINK}
@DEFWORD "." PRTDOT 0
@FPOP
@POPI TV
@PRTSGNI TV @PRTS FIXedSpace
#@FPUSH
@FNEXT
# Major work horse create new Words
@DEFWORD ":" COLON_DEV F_IMMEDIATE
@IF_EQ_AV 1 STATE
   @PRTLN "Error: Definition already in progress."
   @JMP ErrorReset
@ENDIF
@PUSHI TIB
@CALL GetNextWord
#@PRT "Word Starts at: " @SWP @PRTHEXTOP @SWP @PRT " Ends at: " @PRTHEXTOP @PRTNL
@IF_ZERO
   @PRTLN "Error: Missing name for definition"
   @JMP ErrorReset
@ELSE
   # Move TIB down input string, but also preserve current stack.
   @DUP @POPI TIB
   @CALL CreateHeader   # Builds dictionary Entry
   @MA2V 1 STATE
@ENDIF
@FNEXT
#
# @ (addr -- x)   Fetch memory at addr
@DEFWORD "@" FETCH 0
@FPOP
@PUSHS
@FPUSH
@FNEXT
#
# Every ":" needs ";" to end the compile mode.
@DEFWORD ";" SEMICOLON_DEV F_IMMEDIATE
@IF_EQ_AV 0 STATE
   @JMP ErrorReset
@ENDIF
@PUSH EXIT        # End decleration with call to exit
@CALL Compile
@MA2V 0 STATE     # End Compile Mode
@PRT "Compile Word Ended at Address: " @PRTHEXI DictPtr @PRTNL
@FNEXT
#
# LITERAL used for saving in code list immediate data
@DEFWORD "literal" LITERAL 0
@INC2I IP
@PUSHII IP
@FPUSH
@FNEXT


#
# ! ( x addr -- )    Store x at addr
@DEFWORD "!" STORE 0
@FPOP
@FPOP
@SWP
@POPS
@FNEXT
#
# sp@ ( -- addr )   Get Current data stack pointer
@DEFWORD "sp@" SPFETCH 0
@PUSHI SP @ADD 2
@FPUSH
@FNEXT
#
# rp@ ( -- addr)    Get current return stack pointer
@DEFWORD "rp@" RPFETCH 0
@PUSHI RP @ADD 2                        # RP is Logic Stack Pointer
@FPUSH
@FNEXT
#
# -= ( X -- f )     -1 of top of stack is 0, 0 otherwise
@DEFWORD "0=" ZEROEQUALS 0
@FPOP
@IF_ZERO
   @PUSH -1
   @FPUSH
@ELSE
   @PUSH 0
   @FPUSH
@ENDIF
@POPNULL
@FNEXT
#
# + ( x1 x2 -- n )       Add two values at top of stack
@DEFWORD "+" PLUS 0
@FPOP
@FPOP
@ADDS
@FPUSH
@FNEXT
# - ( x1 x2 -- n )       Add two values at top of stack
@DEFWORD "-" SUBTRACT 0
@FPOP
@FPOP
@SWP
@SUBS
@FPUSH
@FNEXT
# * ( x1 x2 -- n )
@DEFWORD "*" MULTI 0
@FPOP
@FPOP
@CALL MUL
@FPUSH
@FNEXT
# / ( x1 x2 -- n )
@DEFWORD "/" DIVIDE 0
@FPOP
@FPOP
@SWP
@CALL DIV
@SWP @POPNULL
@FPUSH
@FNEXT
# mod ( x1 x2 -- n )
@DEFWORD "mod" MULTI 0
@FPOP
@FPOP
@SWP
@CALL DIV
@POPNULL
@FPUSH
@FNEXT
#
# */ (a b c - (a*b)/c)
@DEFWORD "*/" MULDIVFUNC 0
@FPOP        # stack (c)
@FPOP        # stack (b c)
@FPOP        # stack (a b c)
@CALL MUL    # stack (a*b c)
@SWP         # stack (c a*b)
@CALL DIV    # stack (Result Remainder) wrong order
@SWP         # Reverse order or result and remainder so stack is right.
@FPUSH
@FPUSH
@FNEXT
#
# /mod ( a b - r q)
@DEFWORD "/mod" DIVANDMODFUNC 0
@FPOP
@FPOP
@SWP
@CALL DIV
@SWP
@FPUSH
@FPUSH
@FNEXT
#
# min (a b - r)
@DEFWORD "min" MINFUNC 0
@FPOP
@FPOP
@IF_LT_S
   @POPNULL
@ELSE
   @SWP
   @POPNULL
@ENDIF
@FPUSH
@FNEXT
#
# max (a b - r)
@DEFWORD "max" MAXFUNC 0
@FPOP
@FPOP
@IF_GT_S
   @POPNULL
@ELSE
   @SWP
   @POPNULL
@ENDIF
@FPUSH
@FNEXT
#
# abs ( x -- n )
@DEFWORD "abs" ABSFUNC 0
@FPOP
@DUP
@PUSH 0x8000
@ANDS
@IF_NOTZERO
   @POPNULL
   @COMP2
@ELSE
   @POPNULL
@ENDIF
@FPUSH
@FNEXT
#
# and (x1 x2 -- n) AND two values
@DEFWORD "and" ANDFUNC 0
@FPOP
@FPOP
@ANDS
@FPUSH
@FNEXT
#
# nand ( x1 x2 -- n )    NAND two values at top of stack
@DEFWORD "nand" NANDFUNC 0
@FPOP
@FPOP
@ANDS
@INV
@FPUSH
@FNEXT
# or ( x1 x2 -- n ) OR two values
@DEFWORD "or" ORFUNC 0
@FPOP
@FPOP
@ORS
@FPUSH
@FNEXT
#
# nor (x1 x2 -- n) NOR two values
@DEFWORD "nor" NORFUNC 0
@FPOP
@FPOP
@ORS
@INV
@FPUSH
@FNEXT
#
# xor (x1 x2 -- n) XOR two values
@DEFWORD "xor" XORFUNC 0
@FPOP
@FPOP
@XORS
@FPUSH
@FNEXT
#
# invert (x -- ~x)
@DEFWORD "invert" INVERTFUNC 0
@FPOP
@INV
@FPUSH
@FNEXT
#
# exit ( r: addr -0 )   Resume executing at address at top of return stack
@DEFWORD "exit" EXIT 0
@BPOP
@FPUSH
@FNEXT
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
@FNEXT
@DEFWORD "state" STATEVAR 0
@PUSHI STATE
@FPUSH
@FNEXT
@DEFWORD ">in" TOINVAR 0
@PUSHI TOIN
@FPUSH
@FNEXT
#
@DEFWORD "here" HEREWORD 0
@PUSHI DictPtr
@FPUSH
@FNEXT

@DEFWORD "latest" LATESTVAR 0
@PUSHI LATEST
@FPUSH
@FNEXT


# define some IO primitives

@DEFWORD "key" KEY 0
@READC TV
@PRT "String>" @PRTSI TV @PRTNL
@PUSHI TV @AND 0xff
@FPUSH
@FNEXT
#
@DEFWORD "emit" EMIT 0
@FPOP
@AND 0xff
@POPI TV
@PRTS TV
@FNEXT
#
@DEFWORD "cr" CROUT 0
@PRTNL
@FNEXT
#
@DEFWORD "SPACES" SPACEOUT 0
# Using PRTS rather PRTSP to save a 2 bytes on repeated use.`
@PRTS FIXedSpace
@FNEXT
:FIXedSpace " \0"
#
@DEFWORD "words" WORDS 0
@PUSH 1
@CALL DumpDictionary
@FNEXT
#
@DEFWORD "words+" WORDSPLUS 0
@PUSH 0
@CALL DumpDictionary
@FNEXT
#
@DEFWORD "drop" DROP 0
@INC2I SP
@FNEXT
#
@DEFWORD "dup" DUPFUNC 0
@PUSHI SP @ADD 2 @PUSHS
@FPUSH
@FNEXT
#
@DEFWORD "swap" SWAP 0
@FSWP
@FNEXT
#
@DEFWORD "over" OVER 0
@PUSHI SP @ADD 4 @PUSHS
@FPUSH
@FNEXT
#
@DEFWORD "rot" ROT 0
# (a b c) -> (b c a)
@FPOP @POPI TV
@FPOP @POPI TV2
@FPOP @POPI TV3
@PUSHI TV2 @FPUSH
@PUSHI TV @FPUSH
@PUSHI TV3 @FPUSH
@FNEXT
#
@DEFWORD "nip" NIP 0
@FPOP
@FPOP @POPNULL
@FPUSH
@FNEXT
#
@DEFWORD "tuck" TUCK 0
# ( a b ) => (a b a)
@FPOP @POPI TV # T1=a
@FPOP @POPI TV2 # T2=b
@PUSHI TV @FPUSH
@PUSHI TV2 @FPUSH
@PUSHI TV @FPUSH
@FNEXT
#
@DEFWORD "+!" INCMEM 0
@FPOP      #  [ val ]
@FPOP      #  [ address val]
@POPI TV   #  [val] TV(address)
@ADDII TV  #  [memval+val] TV(address)
@POPII TV  #  mem(TV)=result
@FNEXT
#
@DEFWORD "negate" NEGATE 0
# 2s compliment negative
@FPOP
@COMP2
@FPUSH
@FNEXT
#
@DEFWORD "=" EQUAL 0
@FPOP
@FPOP
@IF_EQ_S
  @POPNULL @POPNULL
  @PUSH -1
@ELSE
  @POPNULL @POPNULL
  @PUSH 0
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "<>" NOTEQUAL 0
@FPOP
@FPOP
@IF_EQ_S
  @POPNULL @POPNULL
  @PUSH 0
@ELSE
  @POPNULL @POPNULL
  @PUSH -1
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "0<>" NOTZERO 0
@FPOP
@IF_NOTZERO
   @POPNULL
   @PUSH -1
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "<" LESSTHAN 0
@FPOP
@FPOP
@SWP
@IF_LT_S
  @POPNULL @POPNULL
  @PUSH -1
@ELSE
  @POPNULL @POPNULL
  @PUSH 0
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "<=" LESSTHANEQUAL 0
@FPOP
@FPOP
@SWP
@IF_LE_S
  @POPNULL @POPNULL
  @PUSH -1
@ELSE
  @POPNULL @POPNULL
  @PUSH 0
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD ">" GREATETHAN 0
@FPOP
@FPOP
@SWP
@IF_GT_S
  @POPNULL @POPNULL
  @PUSH -1
@ELSE
  @POPNULL @POPNULL
  @PUSH 0
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD ">=" GREATETHANEQUAL 0
@FPOP
@FPOP
@SWP
@IF_GT_S
  @POPNULL @POPNULL
  @PUSH -1
@ELSE
  @POPNULL @POPNULL
  @PUSH 0
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "U<" UNSIGNLESSTHAN 0
@FPOP
@FPOP
@SWP
@IF_ULT_S
  @POPNULL @POPNULL
  @PUSH -1
@ELSE
  @POPNULL @POPNULL
  @PUSH 0
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "0<" LESSZERO 0
@FPOP
@IF_ZERO
   @POPNULL
   @PUSH 0
@ELSE
   @IF_GT_A 0
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL
      @PUSH -1
   @ENDIF
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "0>" GREATERZERO 0
@FPOP
@IF_ZERO
   @POPNULL
   @PUSH 0
@ELSE
   @IF_GT_A 0
      @POPNULL
      @PUSH -1
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDIF
@FPUSH
@FNEXT
#
@DEFWORD "?dup" DUPFUNC 0
@FPOP
@DUP
@FPUSH
@FPUSH
@FNEXT
#
@DEFWORD ".s" DumpStack 0
@CALL DebugStacks
@FNEXT
#
#############
# Start of Logical operations.

@DEFWORD "0branch" ZBRANCH 0
@FPOP                   # Pop TOS as condition
@IF_ZERO
   @POPNULL             # TOS is zero.
   @INC2I IP
   @PUSHII IP           # Get address of THEN/ELSE
   @POPI IP             # JMP there.
@ELSE
   @POPNULL            # Non Zero on TOS
   @INC2I IP           # Skip past the THEN ELSE jmp and continue.
@ENDIF
@FNEXT
#
#
@DEFWORD "branch" BRANCH 0
@INC2I IP
@PUSHII IP
@POPI IP
@FNEXT

@DEFWORD "debug" FNC_DEBUG 0
@DEBUGTOGGLE
@FNEXT



#
# IF Logic
@DEFWORD "if" IF_COMPILE F_IMMEDIATE
#:IF_COMPILE
@PUSH ZBRANCH   #  emit opcode
@CALL Compile
@PUSHI DictPtr  #  save address of placeholder 
@LPUSH          #  push to logic stack 
@PUSH IFTAG     #  Tag the Logic Stack entry as an IFTAG    
@LPUSH          #
@INC2I DictPtr  #   reserve space for jump target
@FNEXT
#
# ELSE Logic
@DEFWORD "else" ELSE_COMPILE F_IMMEDIATE
#:ELSE_COMPILE
@LPOP                #( get old IF TAG)
@IF_EQ_A IFTAG
  @POPNULL
  @PUSHI DictPtr      @ADD 2 
  @LPOP              # Get old IF ADDRESS
  @POPS              #( patch IF's ZBRANCH to skip over ELSE )
  @PUSH BRANCH         #( emit unconditional jump )
  @CALL Compile  
  @PUSHI DictPtr       #( save new jump placeholder for THEN )
  @LPUSH
  @PUSH ELSETAG
  @LPUSH  
  @INC2I DictPtr       # Save a space for the Address to be pasted.
@ELSE
  @PRTLN "Error: Unclosed Logic, expected IF Block 002"
  @JMP ErrorReset
@ENDIF
@FNEXT
#
# THEN Logic
@DEFWORD "then" THEN_COMPILE F_IMMEDIATE
#:THEN_COMPILE
@LPOP         # Get tag
@IF_EQ_A ELSETAG
   @POPNULL
   @PUSHI DictPtr @SUB 2
   # Fetch the current location
   @LPOP           # Get the reserved spot in ELSE block
   @POPS
@ELSE
   @IF_EQ_A IFTAG
      @POPNULL   
      @PUSHI DictPtr @SUB 2
      # Fetch the current location
      @LPOP            # Get the reserved spot in IF block
      @POPS
   @ELSE
      @POPNULL
      @PRT "Error Unclosed Logic, expected IF Block 001"
      @JMP ErrorReset
   @ENDIF
@ENDIF
@FNEXT
#
# BEGIN ... UNTIL loop
@DEFWORD "begin" BEGIN_COMPILE F_IMMEDIATE
@PUSHI DictPtr @SUB 2
@LPUSH
@PUSH BEGINTAG
@LPUSH
@FNEXT
#
@DEFWORD "until" UNTIL_COMPILE F_IMMEDIATE
@LPOP
@IF_EQ_A BEGINTAG
   @POPNULL
   @PUSH ZBRANCH
   @CALL Compile
   @LPOP
   @CALL Compile
@ELSE
   @PRTLN "Error: UNTIL without matching BEGIN"
   @JMP ErrorReset
@ENDIF
@FNEXT
#
# AGAIN is like UNTIL but without the conditional test.
@DEFWORD "again" AGAIN_COMPILE F_IMMEDIATE
@LPOP
@IF_EQ_A BEGINTAG
   @POPNULL
   @PUSH BRANCH
   @CALL Compile
   @LPOP
   @CALL Compile
@ELSE
   @PRTLN "Error: AGAIN without matching BEGIN"
   @JMP ErrorReset
@ENDIF
@FNEXT
#
#
@DEFWORD "do_runtime" DO_RUNTIME 0
@FPOP
@IF_EQ_A DOTAG
   @POPNULL
   @FPOP    # Jmp Address
   @FPOP    # Limit
   @PRT " Limit:" @PRTHEXTOP
   @FPOP    # Start
   @PRT " Start:" @PRTHEXTOP @PRTNL
   # Now move to LP Stack
   @LPUSH 
   @LPUSH 
   @LPUSH 
   @PUSH DOTAG @LPUSH  # TAG
@ELSE
   @PRTLN "Error: Do Until not closed properly"
   @JMP ErrorReset
@ENDIF

@FNEXT


#
#
@DEFWORD "do" DO_COMPILE F_IMMEDIATE  # ( start limit -- )
@LocalVar PatchLocation 01

# Compile in LITERAL <LOOP_TOP> with 0 as LOOP_TOP placeholder
@PUSH LITERAL @CALL Compile
# Record where the Zero was saved in memory
@PUSHI DictPtr @POPI PatchLocation
# Now save at that place a zero placeholder
@PUSH 0 @CALL Compile       # PlaceHolder Value, patch when we know where 'here is

# Tag has to be top of SP stack.
@PUSH LITERAL @CALL Compile
@PUSH DOTAG @CALL Compile
# Make first run of loop call the DO_RUNTIME to initilize the LS data
@PUSH DO_RUNTIME @CALL Compile

# Now insert <LOOP_TOP> where we put placeholder
@PUSHI DictPtr @SUB 2 @POPII PatchLocation   # DictPtr is Compile time HERE -2 for INC2 later

@RestoreVar 01
@FNEXT

#
@DEFWORD "loop" LOOP_COMPILE 0
@LocalVar StartVar 01
@LocalVar LimitVar 02
@LocalVar StartAddress 03
@LPOP
@IF_EQ_A DOTAG
   # Drop Though
@ELSE
   @PRTLN "Error: LOOP without matching DO"
   @JMP ErrorReset
@ENDIF
@POPNULL    # No longer need tag
# Move Values to HW Stack
@LPOP  @POPI StartAddress # Sae
@LPOP  @POPI LimitVar     # Save Limit
@LPOP  @POPI StartVar     # Save Start


@INCI StartVar

@IF_EQ_VV StartVar LimitVar
   # Loop is finished, just drop to exit.
@ELSE
   # Now recreate the LS entries for next loop
   
   @PUSHI StartVar @LPUSH
   @PUSHI LimitVar @LPUSH
   @PUSHI StartAddress @LPUSH      # Push StartAddress   
   @PUSH DOTAG @LPUSH
   @MV2V StartAddress IP          # Do the Jmp back to StartAddress
   :Break01
@ENDIF
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@FNEXT
#
@DEFWORD "i" I_WORD 0
@PUSHI LP @ADD 8 @PUSHS
@FPUSH
@FNEXT
#
@DEFWORD "j" J_WORD 0
@PUSHI LP @ADD 16 @PUSHS
@FPUSH
@FNEXT
#
@DEFWORD "k" K_WORD 0
@PUSHI LP @ADD 24 @PUSHS
@FPUSH
@FNEXT
#

   
#
@DEFWORD "see" SEEWORDS F_IMMEDIATE
@IF_EQ_AV 1 STATE
   @PRTLN "Error: Can't SEE words while defining a new one."
   @JMP ErrorReset
@ENDIF
@PUSHI TIB
@CALL GetNextWord
@IF_ZERO
   @PRTLN "Error: Missing Word."
   @JMP ErrorReset
@ELSE
   # Word Found
   @POPI TIB
   @CALL SearchDictionary
   @IF_EQ_A 0
      @PRTLN "Word not found in dictionary."
      @MV2V INPUTBUFFER TIB
      @PUSH 0 @POPII TIB
   @ELSE   
      @StackDump
      @POPNULL @POPNULL
      @CALL DumpWord
   @ENDIF
@ENDIF
@FNEXT
#
#
@DEFWORD ">r" TOR_WORD 0
@FPOP
@BPUSH
@FNEXT
#
#
@DEFWORD "r>" RFROM_WORD 0
@BPOP
@FPUSH
@FNEXT
#
#
@DEFWORD "r@" RFETCH_WORD 0
@BPEEK
@FPUSH
@RET
##############################
@DEFWORD "printstring" PRINTSTRING 0
@LocalVar Length 01
@LocalVar OldLast 02
@LocalVar OldLocation 03
@INC2I IP
@PUSHII IP
@POPI Length
@INC2I IP
@PUSHI IP @ADDI Length
@POPI OldLocation
@PUSHII OldLocation @POPI OldLast  # Save what was the High Byte of the last word in string.
@PUSHI OldLast @AND 0xff00
@POPII OldLocation
@PRTSTRI IP         # This will print the now null terminated string.
@PUSHI OldLast @POPII OldLocation   # Restore it
@PUSHI IP @ADDI Length @SUB 1
@POPI IP
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@FNEXT


@DEFWORD ".\"" DOTQUOTE_COMPILE F_IMMEDIATE
@LocalVar Index1 01
@LocalVar StartI 02
@LocalVar StopI 03
@PUSHI TIB
@CALL GetNextString
@IF_ZERO
   @PRTLN "Error Can not print empty string."   
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
   @JMP ErrorReset
@ENDIF
@POPI StopI
@POPI StartI
@MV2V StopI TIB

# String Print function will have in memory
# DOStringPrint LEN text

@PUSH PRINTSTRING
@CALL Compile
@PUSHI StopI @SUBI StartI @SUB 1
@CALL Compile
@ForIV2V Index1 StartI StopI
   @PUSHII Index1 @AND 0xff
   @CALL CompileByte
@Next Index1
@MV2V StopI TIB
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@FNEXT

@DEFWORD "do_marker" DO_MARKER_RUNTIME 0
  @LocalVar MarkerPtr 01

  @PUSHI IP
  @POPI MarkerPtr
  @INC2I MarkerPtr
  @PUSHII MarkerPtr @POPI LATEST
  @INC2I MarkerPtr
  @PUSHII MarkerPtr @POPI HERE
  @PUSHI IP @ADD 4 @POPI IP
  @RestoreVar 01
  @FNEXT
@DEFWORD "marker" DEF_MARKER F_IMMEDIATE
  @LocalVar OldHere 01
  @LocalVar XT 02
  @IF_EQ_AV 1 STATE
     @PRTLN "Error: Definition already in progress."
     @JMP ErrorReset
  @ENDIF
  @PUSHI TIB @CALL GetNextWord
  @IF_ZERO
     @POPNULL  
     @PRTLN "Error: Missing name for definition"
     @JMP ErrorReset
  @ELSE
    # Move TIB down input string, but also preserve current stack.
    @DUP @POPI TIB
    @CALL CreateHeader   # Builds dictionary Entry
    @PUSH DO_MARKER_RUNTIME
    @CALL Compile
    @MV2V HERE OldHere
    @PUSHI LATEST
    @CALL Compile       # Does Compile modify HERE? If so we may need to save it first.
    @PUSHI OldHere
    @CALL Compile
    @PUSH EXIT
    @CALL Compile
  @ENDIF
  @RestoreVar 02
  @RestoreVar 01
  @FNEXT

#
#
#

:LATEST LATEST+2   # Initialized to last word in built in dictionary.

@DEFWORD "FNC_IMMEDIATE" FNC_IMMEDIATE 0
@FPUSH
@FNEXT
####################
# Function DCol
# DCol is the execution loop used for colon defined words.
:DCol
@LocalVar MyIP 01
#
@PUSHII IP
#@DUP @PUSH DumpString @CALL DumpFindName @IF_ZERO @POPNULL @PRT "DATA:" @PRTHEXTOP @POPNULL @ELSE @PRTSTR DumpString @POPNULL @PRTNL @ENDIF
#@PUSHI IP @PUSH 32
#@PRT "Hexdump: " @PRTHEXI IP @PRTNL
#@CALL HexDump
@WHILE_NEQ_A EXIT
   @IF_GT_V COMPILEBUFFER
      # It a call to another DCOL, Preserve IP as it will have unique one for that call.
      @MV2V IP MyIP      
      @CALL execute
      @MV2V MyIP IP
   @ELSE
#@DUP @PUSH DumpString @CALL DumpFindName @IF_ZERO @POPNULL @PRT "DATA:" @PRTHEXTOP @POPNULL @ELSE @PRTSTR DumpString @POPNULL @PRTNL @ENDIF
      @CALL execute
   @ENDIF   
   @INC2I IP
   @PUSHII IP
@ENDWHILE
@POPNULL
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
#@PUSHI NameEnd @SUBI NameStart @POPI NameLen
@PUSHI NameStart @CALL strlen @POPI NameLen
#
# Get Current HerePtr
@MV2V DictPtr TmpHerePtr
#
# Store LINK at head of new Word
# Memory[HerePtr]=LATEST; HerePtr += 2
@PUSHI LATEST
@CALL Compile
#
# Save Flags and Length (current flags always zero?)
@PUSHI NameLen 
#@SUB 1
@POPII DictPtr
@INCI DictPtr
#
@ForIA2V Index01 0 NameLen
  @PUSHII NameStart @AND 0xff
  @POPII DictPtr
  @INCI DictPtr
  @INCI NameStart
@Next Index01
@PUSH DCol             # First Word in Compiled code is DCol
@CALL Compile
#
# TmpHerePtr should have location or begining of word. Fill it with OLD LATEST
@MV2V LATEST RB_LATEST     # Save old Latest for possible ROLL Back
@MV2V TmpHerePtr LATEST    # Now mark that an new LATEST
#
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
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 570" @END @ENDIF
@DUP @ADD SoftHeapSize @SWP
@CALL SetSSStack
#@PRT "\nAfter Stack Setup:\n" @PUSHI MainHeap @CALL HeapListMap
@PUSHI MainHeap @PUSH InputBufferSize
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 575" @END @ENDIF
@POPI INPUTBUFFER
@PUSHI MainHeap @PUSH RP0Size
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 578" @END @ENDIF
@POPI RP0
@PUSHI MainHeap @PUSH SP0Size
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 581" @END @ENDIF
@POPI SP0
@PUSHI MainHeap @PUSH LP0Size
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 584" @END @ENDIF
@POPI LP0
@PUSHI MainHeap @PUSH CodeBufferSize
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 586" @END @ENDIF
@POPI COMPILEBUFFER
@MV2V COMPILEBUFFER DictPtr
#@PRT "\nAfter Setup:\n" @PUSHI MainHeap @CALL HeapListMap
#
@PUSHI RP0 @ADD RP0Size @SUB 2 @POPI RP
@PUSHI SP0 @ADD SP0Size @SUB 2 @POPI SP
@PUSHI LP0 @ADD LP0Size @SUB 2 @POPI LP
@ForIA2B TV 0 InputBufferSize
   @PUSH 0 @PUSHI TV @ADDI INPUTBUFFER @POPS
@Next TV
@MV2V LATEST RB_LATEST       # Setup for Roll Back on errors.
# Save at bottom of call stack, call to clean exit.
@PUSH ExitCode
@BPUSH
@RET
#####################

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
@LocalVar TermCode 04
@POPI instr

@MA2V 1 TermCode   # Term Code records if word seperator is 0:'whitespace' or 1:'EOL'
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
   @SWITCH
   @CASE " \0"        # Space end of word
      @POPNULL
      @PUSH 0
      @MA2V 0 TermCode
      @CBREAK
   @CASE 0x0a        # Newline
      @POPNULL
      @PUSH 0
      @MA2V 0 TermCode      
      @CBREAK
   @CASE 0           # Null
      @POPNULL
      @PUSH 0
      @CBREAK
   @CDEFAULT
      # All other characters
      @INCI instr
      @POPNULL
      @PUSHII instr @AND 0xff
      @CBREAK
   @ENDCASE
@ENDWHILE
@POPNULL
# Our output will either be Null or the string from WordStart to instr
@IF_EQ_VV instr WordStart
   # empty strings means instr didn't move
   @PUSH 0
@ELSE
   @IF_EQ_AV 0 TermCode         # WhiteSpace
      @PUSHII instr    # Get the full 16 bit work so we can modify it
      @AND 0xff00
      @POPII instr     # Zero out the space so word will be valid ASCIIZ string
      @INCI instr      # Move past the 'null' inserted in WordStart String
      @PUSHI WordStart
      @PUSHI instr
   @ELSE
      # TermCode=1 means end of line
      @PUSHI WordStart
      @PUSHI instr
   @ENDIF
@ENDIF
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#
##########################################
# Function interpreter()
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
    @PUSHI TIB
    @CALL GetNextWord
    @IF_ZERO
       # Input was Null, get a new line
       @POPNULL
       @MV2V INPUTBUFFER TIB
       @IF_EQ_AV 0 STATE
          @PRT "OK "
       @ENDIF
       @READSI TIB
       @JMP InterContinue
    @ENDIF
    # We get here only if TOS has valid token info.
    # (Tolkien, new TIB)
    @POPI TIB
    @PUSHI TIB @SUBI INPUTBUFFER @POPI TOIN   # Where in input buffer we're currently
    @DUP @POPI WordVal
    @CALL SearchDictionary   # [ 0 | DictEntry LenFlag CodeEntry ]
    @IF_EQ_A 0
       # Fallback to try parsing as number
       @POPNULL
       @PUSHII WordVal @AND 0xff
       @IF_EQ_A "-\0"
          @POPNULL
          @PUSH 0
       @ELSE
          @IF_INRANGE_AB "0\0" "9\0"
              @POPNULL
              @PUSH 0
          @ELSE
              @POPNULL          
              @PUSH 1
          @ENDIF
       @ENDIF
       @IF_ZERO
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
#          @IF_GE_V COMPILEBUFFER
#             @PUSHS
#          @ENDIF
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
#   @PUSHI Result
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
@LocalVar EntryPtr 01
@POPI EntryPtr
@PUSHI EntryPtr       # return unmodified
@RestoreVar 01
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
# Whats on TOS should be address of Word code.
@IF_GE_V COMPILEBUFFER
   @POPI IP
   @PUSHII IP
#@ELSE
#   @PRT "Built in Word: " @PRTHEXTOP @PRTNL
@ENDIF
@IF_EQ_A DCol
    @INC2I IP
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
# Function CompileByte
:CompileByte
@SWP
@AND 0xff                     # Make sure paramater is just byte
@PUSHII DictPtr @AND 0xff00   # Save the old Highbyte of word
@ORS                          # Combine with new byte
@PUSHI DictPtr
@POPS
@INCI DictPtr             # Inc only by one byte rather than 2
@RET


#######################################
# Function DebugStacks
:DebugStacks
@PUSHRETURN
@LocalVar Index1 01
@LocalVar Limit 02
@LocalVar Base 03
@LocalVar Top 04
@PRT "-- SP Stack --\n"

@MV2V SP0 Base
@PUSHI SP0 @ADD SP0Size @SUB 2 @POPI Top

@PUSHI SP
@IF_GT_V Top
   @PRTLN "SP Stack OverFlow:"
@ELSE
   @IF_LT_V Base
      @PRTLN "SP Stack Underflow:"
   @ELSE
      @ForIV2V Index1 SP Top
         @PRT "SP["
         @PUSHI Index1 @ADD 2 @PUSHS
         @PRTHEXTOP
         @PRT "]\n"
         @POPNULL
      @NextBy Index1 2
   @ENDIF
@ENDIF
@POPNULL
@PRT "-- RP Stack --\n"
@MV2V RP0 Base
@PUSHI RP0 @ADD RP0Size @SUB 2 @POPI Top
@PRT "Range: " @PRTHEXI RP @PRT " - " @PRTHEXI Top @PRTNL
@PUSHI RP
@IF_GT_V Top
   @PRTLN "RP Stack OverFlow:"
@ELSE
   @IF_LT_V Base
      @PRTLN "RP Stack Underflow:"
   @ELSE
      @ForIV2V Index1 RP Top
         @PRT "RP["
         @PUSHI Index1 @ADD 2 @PUSHS
         @PRTHEXTOP
         @PRT "]\n"
         @POPNULL
      @NextBy Index1 2
   @ENDIF
@ENDIF
@POPNULL
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET



#######################################
# Function DumpDictionary
:DumpDictionary
  @PUSHRETURN
  @LocalVar Index1 01      # Word header address
  @LocalVar StrLen 02      # Length of string part
  @LocalVar LastByte 03    # Saved byte past string
  @LocalVar LastAddr 04    # Address of byte past string
  @LocalVar StrStart 05    # Start of string
  @LocalVar FlagInfo 06    # Flags and length byte
  @LocalVar Code1 07       # Code address
  @LocalVar Compact 08     # Set to 1 to print just the word names.  0 for full table.
  @LocalVar WidthCnt 09
  
  @POPI Compact            
  @IF_EQ_AV 0 Compact
     @PRT " Addr   Code   Flg  Name\n"
     @PRT "------  ------ ---- ----------------\n"
  @ENDIF

  @MA2V 0 WidthCnt
  @MV2V LATEST Index1
  @PUSHI Index1
  @WHILE_NOTZERO
    @POPNULL

    # Extract flag byte
    @PUSHI Index1 @ADD 2 @PUSHS @AND 0xff @POPI FlagInfo
    @PUSHI FlagInfo @AND LENMASK @POPI StrLen

    # Find byte just past the string
    @PUSHI StrLen @ADDI Index1 @ADD 2 @POPI LastAddr
    @PUSHII LastAddr @POPI LastByte
    @PUSHII LastAddr @AND 0x00ff @POPII LastAddr  # Null it out

    # Find start of string
    @PUSHI Index1 @ADD 3 @POPI StrStart

    # Extract Code Pointer
    @PUSHI Index1 @ADD StrLen @ADD 3 @POPI Code1
    @IF_EQ_AV 0 Compact
       # Print Word Address
       @PRTHEXI Index1 @PRT "    "

       # Print Code Address
       @PRTHEXI Code1 @PRT "   "

       # Print Immediate Flag
       @PRT " "
       @PUSHI FlagInfo @AND 0x80
       @IF_NOTZERO
         @PRT "I"
       @ELSE
         @PRT " "
       @ENDIF
       @POPNULL
       @PUSH FlagInfo @AND 0x40
       @IF_NOTZERO
           @PRT "H"
       @ELSE
          @PRT " "
       @ENDIF
       @POPNULL
       @PRT "  "
    @ENDIF
    # Print Word Name
    @PRTSI StrStart
    @IF_EQ_AV 0 Compact
       @PRT "\n"
    @ELSE
       @PRT " "
       @PUSHI StrStart @CALL strlen @ADDI WidthCnt
       @IF_GT_A 70
           @POPNULL
           @PRT "\n"
           @MA2V 0 WidthCnt
       @ELSE
           @POPI WidthCnt
       @ENDIF
    @ENDIF
    @PUSHI LastByte @POPII LastAddr

    # Move to next word
    @PUSHII Index1 @POPI Index1
    @PUSHI Index1
  @ENDWHILE

  @POPNULL
  @PRTNL
  
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

########################################
# Function DumpFindName(ID,StrPtr)
:DumpFindName
@PUSHRETURN
@LocalVar NameStart 01
@LocalVar NameLength 02
@LocalVar MatchID 03
@LocalVar EntryPtr 04
@LocalVar StrPtr 05
@LocalVar Entry 06
@LocalVar Result 07
@POPI StrPtr
@POPI MatchID
#
@MA2V -1 Result
@MV2V LATEST EntryPtr
@WHILE_EQ_AV -1 Result
   @PUSHI EntryPtr
   @CALL ReadDictionary
   @POPI Entry
   @IF_EQ_AV 0 Entry
       # Break While loop at end
       @MA2V 0 Result   
   @ELSE
       @PUSH 0
       @IF_EQ_VV Entry MatchID
          @POPNULL
          @PUSH 1
       @ELSE
          @PUSHI Entry @ADD 2 @PUSHS @AND LENMASK @ADDI Entry @ADD 3
          @IF_EQ_V MatchID
              @POPNULL
              @POPNULL
              @PUSH 1
          @ELSE
              @POPNULL              
          @ENDIF          
       @ENDIF
       @IF_NOTZERO
          # Did Match
          @POPNULL
#          @PRT "Match at: " @PRTHEXI MatchID @PRT " EP:" @PRTHEXI EntryPtr @PRTNL
          @PUSHI StrPtr            # Dst String
          @PUSHI Entry @ADD 3
          @PUSHI Entry @ADD 2 @PUSHS @AND LENMASK  # Length
          @CALL strncpy
          @MV2V Entry Result

       @ELSE
          @POPNULL
          # Didn't match
          @PUSHII Entry    # First word in strct is ptr to next entry
          @POPI EntryPtr          
       @ENDIF
   @ENDIF
@ENDWHILE
@IF_EQ_AV 0 Result
   # No Match
   @PUSHI MatchID
   @PUSH 0
@ELSE
   @PUSHI Result
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

########################################
# Function GetNextString
:GetNextString
@PUSHRETURN
@LocalVar instr 01
@LocalVar StartIndex 02
@POPI instr
@MV2V instr StartIndex
#
@WHEN      # I don't use WHEN loops alot but they are basicly   1
           # While Loops where the condition is spread out over
           # a block of logic and leave 0 or 1 on the stack.
   @PUSHII instr @AND 0xff
   @IF_EQ_A 0                                                # 2
      # End of String, leave the zero on TOS
   @ELSE
      @IF_EQ_A 34   # Double Quote character Code
          @POPNULL
          @PUSH 0
      @ELSE
          @IF_EQ_A 92   # Back Slash
             # Allows some commonb \ codes
             @INCI instr
             @POPNULL
             @PUSHII instr @AND 0xff
             @SWITCH
             @CASE "n\0"
                @POPNULL
                @PUSH 0xa      # Newline
                @CBREAK
             @CASE "t\0"
                @POPNULL
                @PUSH 7        # Tab
                @CBREAK
             @CASE "r\0"
                @POPNULL
                @PUSH 13       # CR
                @CBREAK
             @CASE "b\0"       # BackSpace
                @POPNULL
                @PUSH 8
                @CBREAK
             @CASE "0\n"       # Null
                @POPNULL
                @PUSH 0
                @CBREAK
             @CDEFAULT
                # Just let any quoted character remain.
                @CBREAK
             @ENDCASE
          @ENDIF
      @ENDIF
   @ENDIF
@DO_NOTZERO
   @POPNULL
   @INCI instr
#   @PUSHII instr
@ENDWHEN
@POPNULL
@IF_EQ_VV instr StartIndex
   # Null String instr remained the same.
   @PUSH 0
@ELSE
   @PUSHII instr
   @AND 0xff00    # Zero out the 'space' or existing null again.
   @IF_NOTZERO    # not yet end of line, so turn 'space' into null
      @POPII instr
      @INCI instr # Prep instr for next word in input.
   @ELSE   
      @POPII instr
   @ENDIF
   @PUSHI StartIndex     # This will be begining of string.
   @PUSHI instr
@ENDIF
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

########################################
# Function ErrorReset
:ErrorReset
#
# Reset all major globals to get system stable to last known good state.
@PUSHI RP0 @ADD RP0Size @SUB 2 @POPI RP
@PUSHI SP0 @ADD SP0Size @SUB 2 @POPI SP
@PUSHI LP0 @ADD LP0Size @SUB 2 @POPI LP
@ForIA2B TV 0 InputBufferSize
   @PUSH 0 @PUSHI TV @ADDI INPUTBUFFER @POPS
@Next TV
# Zero out first word so first call to parse will always be null
@MV2V INPUTBUFFER TIB
@PUSH 0 @POPII TIB
@MA2V 0 TOIN
@MA2V 0 STATE
@MV2V RB_LATEST LATEST
@JMP interpreter



########################################
# Function DumpWord
# Pass ID (address) of word, creates 'dissasembly'
:DumpWord
@PUSHRETURN
@LocalVar TMPWP 01
@LocalVar ZIDX 02
@LocalVar TMPIP 03
@DUP
@POPI TMPWP
@PUSHI TMPWP @ADD 3 @AND LENMASK @ADDI TMPWP @ADD 3 @POPI TMPIP
@IF_LT_V COMPILEBUFFER
   @PUSH DumpString
   @CALL DumpFindName
   @IF_ZERO
      @POPNULL
      @PRT "Not A valid Word:"
   @ELSE
      @PRTS DumpString @PRTNL
      @POPNULL
   @ENDIF
@ELSE
   @POPNULL
   @PUSHII TMPIP
   @WHILE_NEQ_A EXIT
      # Zero out old string
      @ForIA2B ZIDX 0 18
         @PUSH 0
         @PUSH DumpString @ADDI ZIDX
         @POPS
      @Next ZIDX            
      @PUSH DumpString
      @CALL DumpFindName
      @PRTHEXI TMPIP @PRT ":"              
      @IF_ZERO
         @POPNULL
         @PRT "Data:" @PRTHEXTOP @PRTNL
         @POPNULL
      @ELSE
         @PRTS DumpString @PRTNL
         @POPNULL
      @ENDIF
      @INC2I TMPIP
      @PUSHII TMPIP
   @ENDWHILE
   @POPNULL
   @PRTHEXI TMPIP @PRT " EXIT\n"
@ENDIF
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
:DumpString 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
#####################################
# HexDump(start,length) prints in words hex from start to length
#
:HexDump
@PUSHRETURN
@LocalVar Index1 01
@LocalVar MemStart 02
@LocalVar MemLength 03
@LocalVar Column 04
@LocalVar OffSet 05
@LocalVar StrPtr 06
@LocalVar StrPtr2 07
@LocalVar StrPtr3 08
@LocalVar MemStop 09
@LocalVar ValSpot 10
#
@POPI MemLength
@POPI MemStart
#
# Header

@PUSHI MemStart @ADDI MemLength @ADD 1 @POPI MemStop
@MA2V 0 Column
@PRTHEXI MemStart @PRT ": "
@ForIupV2V Index1 MemStart MemStop
   @PUSHII Index1
   @PRTHEXTOP
   @POPNULL
   @PRTSP
   @INCI Column
   @PUSHI Column @AND 0x7
   @IF_ZERO
      @PRTNL
      @PRTHEXI Index1 @PRT ": "
      @MA2V 0 Column
   @ENDIF
   @POPNULL
@NextBy Index1 2
@PRTNL

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
:ENDOFCODE
. Main
