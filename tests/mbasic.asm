I common.mc
L softstack.ld
L random.ld
L heapmgr.ld
L string.ld
L screen.ld

## Local Storage
:MainHeapID 0
:GlobalPC 0
:SRCBuffer 0
:SRCIndex 0
:SRCBufferCnt 0
:SRCAllocCnt 0       # Max numbers that heap has been allocated for.
:SRCMaxLines 0       # Highest line number acutually used. 0 means none are in use.
:CurrentLine 0
:CMDCurrentLine 0
# SRCIndexCnt

## Constants
=COMMANDMODE 1
=EDITCMDMODE 2
=EDITINSERTMODE 3
=CMDUNKNOWN 0
=ENDMODE 4
=CMDEDIT 1
=CMDRUN CMDEDIT+1
=CMDLIST CMDRUN+1
=CMDCONT CMDLIST+1
=CMDQUIT CMDCONT+1
=CMDPRINT CMDQUIT+1
=CMDSAVE CMDPRINT+1
=CMDLOAD CMDSAVE+1
=CMDDIR CMDLOAD+1
=CMDDELETE CMDDIR+1
=CMDRENAME CMDDELETE+1
=CMDCOPY CMDRENAME+1
=CMDCLS CMDCOPY+1
=CMDCLEAR CMDCLS+1
=CMDIF CMDCLEAR+1
=CMDTHEN CMDIF+1
=CMDELSE CMDTHEN+1
=CMDFOR CMDELSE+1
=CMDTO CMDFOR+1
=CMDNEXT CMDTO+1
=CMDINPUT CMDNEXT+1
=CMDGOTO CMDINPUT+1
=CMDGOSUB CMDGOTO+1
=CMDHELP CMDGOSUB+1
=CMDRETURN CMDHELP+1
=CMDMEM CMDRETURN+1
=CMDMAXVAL CMDMEM


#############################
# Function Init
:Init
# Defined memory between endofcode and 0xf800 as available
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory   #0
@POPI MainHeapID
#
# Expands the Soft Stack so we can use deeper recursion, about 1K should do for now.
@PUSHI MainHeapID @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1  #0
@DUP @ADD 0x400 @SWP
@CALL SetSSStack      #0
#
@CALL RunIntro
#
# Setup storage for Edit buffer.
# At start Main Index is 100 lines long
@PUSHI MainHeapID @PUSH 200
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1  #0
@POPI SRCIndex
@MA2V 0 SRCMaxLines
@MA2V 100 SRCAllocCnt      # 100 lines, 2 bytes per line
@RET
###########################################################################
# Function ErrorExit
:ErrorExit
@TTYECHO
@PRT "From Location: " @PRTHEXTOP
@POPNULL
@PRT " Error Code: " @PRTTOP
@PRTNL
@POPNULL
@END
###########################################################################
# Function RunIntro
:RunIntro

@PUSHRETURN
#
=UserKey Var01
=SeedCount Var02
=FileAttribute Var03
@PUSHLOCALI UserKey
@PUSHLOCALI SeedCount

#
@PUSH 1   # Set this to 1 if we need a random seed
@IF_NOTZERO
   @PRTLN "Start...(hit any key)"
   @TTYNOECHO
   # First When is to 'drain' and keybuffer
   @WHEN
      @READCNW UserKey
      @PUSHI UserKey
      @DO_NOTZERO
         @POPNULL
   @ENDWHEN
   @POPNULL
   @WHEN
      @READCNW UserKey
      @PUSHI UserKey
      @IF_EQ_AV 0 UserKey
      @ELSE
         @PRTSTR UserKey
      @ENDIF
      @DO_ZERO
         @POPNULL
         @INCI SeedCount
   @ENDWHEN
   @POPNULL
   @TTYECHO
   @PUSHI SeedCount @ADDI UserKey @AND 0x7fff
#   @PRT "Random Seed: " @PRTTOP @PRTNL
   @CALL rndsetseed    #0
@ENDIF
@POPNULL
@POPLOCAL SeedCount
@POPLOCAL UserKey
@POPRETURN
@RET
################################################
# Function Main
:Main . Main
#@ENABLETRACE
#@ENABLERETTRACE
@CALL Init           # 1
=InputStrPtr Var01
@PUSHLOCALI Var01
#
# Run Debug tests here
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @PUSH COMMANDMODE     # Command Mode
   @CALL CommandPrompt     # 1
   @POPI InputStrPtr
   #
   @PUSHI InputStrPtr
   @CALL HandleCommand     # 1
   @PUSHI InputStrPtr
   @CALL FreeStringMem     # 1
@ENDWHILE
@POPLOCAL Var01
@END
#################################################
# Function CommandPrompt
:CommandPrompt
@PUSHRETURN
=NewCmdLinePtr Var01
@PUSHLOCALI Var01
@SWITCH
   @CASE COMMANDMODE
     @PRT "C> "
     @CBREAK
   @CASE EDITCMDMODE
     @PRT "E> "
     @CBREAK
   @CASE EDITINSERTMODE
     @PRT "I: "
     @CBREAK
   @CDEFAULT
     @PRTLN "Unknown Mode:"
     @CBREAK
@ENDCASE
@POPNULL
@PUSHI MainHeapID
@PUSH 255
@CALL HeapNewObject  @IF_ULT_A 100 @PRT "Heap error 185" @END @ENDIF       #0
@POPI NewCmdLinePtr
@READSI NewCmdLinePtr
@PUSHI NewCmdLinePtr
@POPLOCAL Var01
@POPRETURN
@RET
#################################################
# Function HandleCommand(strbuffer)
:HandleCommand
@PUSHRETURN
=instring Var01
=CommandWord Var02
=P1 Var03
=P2 Var04
=CommandVal Var05
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@POPI instring
#
# GetNextWord(instring, mode):(CommandWord,instring)
@PUSHI instring @PUSH 1 @CALL GetNextWord
@POPI CommandWord
@POPI instring
#
# At the command mode state with allow the following commands:
# EDIT - Invokes the line editor.
# RUN - Runs current code.
# LIST (range-range) - LIST current code
# CONTINUE - Continues from last line break.
# QUIT - Quits mbasic
# PRINT (varnames[,varnames...]) - Prints a value
# SAVE FILE - To be added once we have working filesystem
# LOAD FILE - To be added once we have working filesystem
# DIR  - To be added once we have working filesystem
# DELETE File - To be added once we have working filesystem
# RENAME FILE FILE - To be added once we have working filesystem
# COPY FILE FILE - To be added once we have working filesystem
# CLS  - Clears screen for readablity.
# CLEAR - Clears memory of current code.
#
# ParseCommand(CommandWord, instring): (CommandVal)

@PUSHI CommandWord @PUSHI instring
@CALL ParseCommand
@POPI CommandVal
# We no longer need CommandWord
@PUSHI CommandWord
@CALL FreeStringMem
#
# Some commands have 1 or 2 paramters, prep them.
@PUSHI instring @PUSH 1 @CALL GetNextWord
@POPI P1 @POPI instring # The acutual P1 (if any)
@PUSHI instring @PUSH 1 @CALL GetNextWord
@POPI P2 @POPI instring # P2 (if any)
#@PRT "Command Val: " @PRTI CommandVal @PRT " P1: " @PRTI P1 @PRT ":" @PRTSI P1 @PRT " P2: " @PRTI P2 @PRT ":" @PRTSI P2 @PRTNL

# Rather than use nested IF's or CASE we'll use index based Jmp table
# But first makes sure CommandVal is in range.
@PUSHI CommandVal
@IF_GT_A CMDMAXVAL
   # Not a valid command code
   @PRTLN "Error Command was not understood."
   @JMP ExitHandleCommand
@ENDIF
@POPNULL
@PUSHI CommandVal @SHL  # Index is by words not bytes.
@ADD CW_JumpTable
@PUSHS
@JMPS
:CW_JumpTable
# Create a list of the jump values
# Must be in the same order as the CMD Constants
#                      CMDUNKNOWN
WC_J_CMDUNKNOWN
#                      CMDEDIT
WC_J_CMDEDIT
#                      CMDRUN
WC_J_CMDRUN
#                      CMDLIST
WC_J_CMDLIST
#                      CMDCONT
WC_J_CMDCONT
#                      CMDQUIT
WC_J_CMDQUIT
#                      CMDPRINT
WC_J_CMDPRINT
#                      CMDSAVE
WC_J_CMDSAVE
#                      CMDLOAD
WC_J_CMDLOAD
#                      CMDDIR
WC_J_CMDDIR
#                      CMDDELETE
WC_J_CMDDELETE
#                      CMDRENAME
WC_J_CMDRENAME
#                      CMDCOPY
WC_J_CMDCOPY
#                      CMDCLS
WC_J_CMDCLS
#                      CMDCLEAR
WC_J_CMDCLEAR
#                      CMDIF
WC_J_CMDIF
#                      CMDTHEN
WC_J_CMDTHEN
#                      CMDELSE
WC_J_CMDELSE
#                      CMDFOR
WC_J_CMDFOR
#                      CMDTO
WC_J_CMDTO
#                      CMDNEXT
WC_J_CMDNEXT
#                      CMDINPUT
WC_J_CMDINPUT
#                      CMDGOTO
WC_J_CMDGOTO
#                      CMDGOSUB
WC_J_CMDGOSUB
#                      CMDHELP
WC_J_CMDHELP
#                      CMDRETURN
WC_J_CMDRETURN
#                      CMDMEM
WC_J_CMDMEM

#   END of Command Lookup table:
#
:WC_J_CMDUNKNOWN
@PRTLN "No such command:"
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDEDIT
@CALL TextEdit
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDRUN
@PRTLN "CMD Run:"
@MA2V 0 GlobalPC
@CALL RunBuffer
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDLIST
# P1 and P2 are string pointers, so change them into numeric values for listing ranges.
@IF_EQ_AV 0 P1
   @PUSH 0
@ELSE
   @PUSHI P1 @CALL stoifirst
@ENDIF
@IF_EQ_AV 0 P2
   @PUSH 0
@ELSE
   @PUSHI P2 @CALL stoifirst
@ENDIF
@CALL ListBuffer
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDCONT
@PRTLN "CMD Continue:"
# Notice we don't reset GlobalPC to 0 for Continue.
@CALL RunBuffer
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDQUIT
@PRTLN "CMD Quit:"
# Simple Quit
@PRT "Bye."

@END
#
:WC_J_CMDPRINT
# Print 1 or 2 parameters.
@PRTLN "CMD Print:"
@IF_EQ_AV 0 P1
   #Nothing to Print
   @PUSH 0
   @JMP  ExitHandleCommand
@ENDIF
@PUSHI P1
@CALL PrintVar
@IF_EQ_AV 0 P2
@ELSE
   @PUSH P2
   @CALL PrintVar
@ENDIF
@PRTNL
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDSAVE
@PRTLN "CMD-Save"
:WC_J_CMDLOAD
@PRTLN "CMD-Load"
:WC_J_CMDDIR
@PRTLN "CMD-Dir"
:WC_J_CMDDELETE
@PRTLN "CMD-Delete"
:WC_J_CMDRENAME
@PRTLN "CMD-Rename"
:WC_J_CMDCOPY
@PRTLN "CMD-Copy"
@PUSH 0
@PRTLN "File Commands not yet implimented."
@JMP ExitHandleCommand
#
:WC_J_CMDCLS
@PRTLN "CMD-CLS"
@CALL WinClear
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDCLEAR
# Erase the current program source buffer
@PRT "CMd-Clear"
@CALL ClearProgram
@PUSH 0
@JMP ExitHandleCommand
#
:WC_J_CMDIF
@PRTLN "CMD-CLEAR"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDTHEN
@PRT "CMD CMDTHEN"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDELSE
@PRT "CMD CMDELSE"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDFOR
@PRT "CMD CMDFOR"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDTO
@PRT "CMD CMDTO"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDNEXT
@PRT "CMD CMDNEXT"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDINPUT
@PRT "CMD CMDINPUT"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDGOTO
@PRT "CMD CMDGOTO"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDGOSUB
@PRT "CMD CMDGOSUB"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDHELP
@PRTLN "CMD CMDHELP"
@PRTLN "------Command Mode-------"
@PRTLN "CLEAR: Empty Memory"
@PRTLN "CLS: Clear screen."
@PRTLN "CONT: Continue already stopped code"
@PRTLN "EDIT: Start Editor"
@PRTLN "LIST range: List code in memory"
@PRTLN "QUIT: Exit mbasic"
@PRTLN "RUN (lable): Run current program"
@PRTLN "SAVE\LOAD\DIR\DELETERENAME: FileSystem commands"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDRETURN
@PRT "CMD CMDRETURN"
@PUSH 0
@JMP ExitHandleCommand
:WC_J_CMDMEM
@CALL MemReport
@PUSH 0
@JMP ExitHandleCommand

:ExitHandleCommand
# Now Clean up P1 and P2
@PUSHI P1
@CALL FreeStringMem
@PUSHI P2
@CALL FreeStringMem
#@PRT "Exit HandleCommand: " @PRTSI instring @PRTNL
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
####################################
# Function FreeStringMem
#   Clears the Heap Object if its defined for Prompt
#   Basicly a HeapDeleteObject with some error checking.
:FreeStringMem
@SWP
@IF_NOTZERO
   @PUSHI MainHeapID
   @SWP
   @CALL HeapDeleteObject @IF_NOTZERO @PRT "Error Clearing Memory: Code:" @PRTTOP @PRTNL @ENDIF
    @IF_NOTZERO
       @PRT "Error Clearing Memory: Code: " @PRTTOP @PRTNL
    @ENDIF
   @POPNULL
@ELSE
   @POPNULL
@ENDIF
@RET
#######################################
# Function GetNextWord(instring, mode):(new-instring, Word)
# Reads first word in instring and parses it depending onthe mode.
#  Mode=1 means space/eol seperated first word.
:GetNextWord
@PUSHRETURN
=inString Var01
=inMode Var02
=newword Var03
=index1 Var04
=Wordlen Var05
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
#
@POPI inMode
@POPI inString
# Test for End of string
@PUSHII inString @AND 0xff
@IF_ZERO
   # Empty String
   @POPNULL
   @PUSHI inString @PUSH 0
@ELSE
   @POPNULL
   @PUSHI inMode
   @SWITCH
   @CASE 1
     @POPNULL
     # Space or EOF seperates words.
     # First skip header whitespace
     @PUSHI inString
     @CALL SkipWhite
     @POPI inString
     # Now find end of current word.
     @PUSHI inString
     @CALL SkipUntilWhite
     @SUBI inString         # Result is len(word)
     @POPI Wordlen
     @PUSHI MainHeapID
     @PUSHI Wordlen @ADD 1       # The extra bytes for the EOS null
     @CALL HeapNewObject   @IF_ULT_A 100 @PRT "Heap error 547" @END @ENDIF      #0
     @POPI newword
     @ForIA2V index1 0 Wordlen
        @PUSHI inString
        @ADDI index1
        @PUSHS @AND 0xff
        @PUSHI newword
        @ADDI index1
        @POPS
     @Next index1
     @PUSHI inString
     @ADDI Wordlen
     @CALL SkipWhite
     @POPI inString
     @PUSHI inString
     @PUSHI newword
     @PUSH 0      # For clearing CASE
     @CBREAK
   @CASE 2
     @POPNULL
     # Parse stopping at any seperator character in set
     # Two Character seperators "!=" "<=" ">="
     # Single Character "(" ")" "+" "-" "*" "/" "," "=" "!" ">" "<" '\"'
     @PUSHI inString
     @CALL SkipWhite
     @POPI inString
     @MV2V inString index1
     @MA2V 0 Wordlen
     @PUSHII index1
     # Test first for 2 character codes
     @IF_EQ_A "!=" @MA2V 2 Wordlen @ENDIF
     @IF_EQ_A "<=" @MA2V 2 Wordlen @ENDIF
     @IF_EQ_A ">=" @MA2V 2 Wordlen @ENDIF
     @POPNULL
     @IF_EQ_AV 0 Wordlen
         # Wasn't a 2 character, test for 1 char symbols
         @PUSHI SymbolList
         @PUSHII index1 @AND 0xff
         @CALL strfndc
         @IF_NOTZERO
             # One of the symbols matched, word length is 1
             @MA2V 1 Wordlen
         @ENDIF
         @POPNULL
         @IF_EQ_AV 0 Wordlen
            # Wordlen still zero means not 1 or 2 character symbol.
            # Remaining possiblilites are Numbers, Keywords or strings.
            # We only want the length so we can treat numbers or keywords as the same.
            @PUSHII index1
            @WHILE_NOTZERO
                @SWITCH
                # Handle Numbers and Letters
                @CASE_RANGE "0\0" "9\0"
                    @INCI Wordlen
                    @CBREAK
                @CASE_RANGE "a\0" "z\0"
                    @INCI Wordlen
                    @CBREAK
                @CASE_RANGE "A\0" "Z\0"
                    @INCI Wordlen
                    @CBREAK
                # While we don't yet have floating point allow "."'s
                @CASE ".\0"
                    @INCI Wordlen
                    @CBREAK
                @CASE 34  # ASCII code for quote
                    # Handled quoted text as single 'word'
                    @INCI index1    # Skip past that quote
                    @PUSHI index1 @ADDI Wordlen @PUSHS @AND 0xff
                    @WHILE_NOTZERO
                       @INCI Wordlen
                       @IF_EQ_A 34  # ASCII Code for quote
                          @POPNULL
                          @PUSH 0       # Zero will terminate inner while loop, and single outer loop to end.
                       @ENDIF
                       @PUSHI index1 @ADDI Wordlen @PUSHS @AND 0xff
                    @ENDWHILE
                    @MA2V 0 inMode     # Since its free now, use inmode to mark this as quoted txt
                    @CBREAK
                @CDEFAULT
                    @PRT "Un-expected Character in line: ASCII Code: " @PRTTOP @PRTNL
                    @POPNULL
                    @PUSH 0          # Error terminats the outter loop
                    @CBREAK
                @ENDCASE
                @IF_NOTZERO
                   # Only fetch next character in index1 if TOS is not zero
                   @PUSHI index1 @ADDI Wordlen @PUSHS @AND 0xff
                @ENDIF
            @ENDWHILE
         @ENDIF          # This was the test about if not 1 or 2 letter symbol
      @ENDIF
      # Now create a new small string sized for the word.
      @PUSHI MainHeapID
      @PUSHI Wordlen @ADD 1       # The extra bytes for the EOS null
      @CALL HeapNewObject  @IF_ULT_A 100 @PRT "Heap error 642" @END @ENDIF       #0
      @POPI newword
      @ForIA2V index1 0 Wordlen
         @PUSHI inString
         @ADDI index1
         @PUSHS @AND 0xff
         @PUSHI newword
         @ADDI index1
         @POPS
      @Next index1
      @PUSHI inString
      @ADDI Wordlen
      @CALL SkipWhite
      @POPI inString
      @PUSHI newword
      @IF_EQ_AV 0 inMode
          # It was quoted test
      @ELSE
          # Change non quoted text to uppercase
          @PRTLN "GetNextWord Mode 2 Call UpCase"
          @CALL StrSetUpCase
      @ENDIF
      @PUSHI inString
      @CBREAK
   @CDEFAULT
      @PRTLN "Unexpected Character: " @PRTTOP @PRTNL
      @CBREAK
   @ENDCASE
   @POPNULL
@ENDIF   # EOS block.
#@PRT "Exit GetNextWord: " @PRTSI inString @PRT " Mode: " @PRTI inMode @PRTNL
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#####################################################
# Function StrSetUpCase(instring)
#      Changes inplace a string to uppercase. Does not create a new string.
:StrSetUpCase
@PUSHRETURN
=instring Var01
=quoteflag Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI instring
@MA2V 0 quoteflag   # Set to 1 when we are within a quoted string
#
@PUSHII instring @AND 0xff
@WHILE_NOTZERO
   @IF_EQ_A 34     # Ascii code for quote
       @PUSHI quoteflag
       @INV
       @POPI quoteflag
   @ENDIF
   @IF_EQ_AV 0 quoteflag     # Means we are not inside quoted text.
      @IF_GE_A "a\0"
	  @IF_LE_A "z\0"
	     @SUB 32    # Turn single letter to uppercase
	     @PUSHII instring @AND 0xff00    # Now Fetch the upper letter.
	     @ORS                            # Merge back now uppercase lower letter.
	     @POPII instring
	  @ENDIF
      @ENDIF
   @ENDIF
   @INCI instring
   @PUSHII instring @AND 0xff
@ENDWHILE
@POPNULL
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

#####################################################
# Function SkipWhite(instring):outstring
:SkipWhite
@PUSHRETURN
=instring Var01
=outstring Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI instring
#
@MV2V instring outstring
@PUSHI outstring
@CALL IsWhiteSpace
@IF_EQ_A 2        # Handle EOS case
@ELSE
   @WHILE_NOTZERO
      @POPNULL
      @INCI outstring
      @PUSHI outstring
      @CALL IsWhiteSpace
      @IF_EQ_A 2 @POPNULL @PUSH 0 @ENDIF # Handle EOS case
   @ENDWHILE
@ENDIF
@POPNULL
@PUSHI outstring
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#####################################################
# Function SkipUntilWhite(instring):outstring
:SkipUntilWhite
@PUSHRETURN
=instring Var01
=outstring Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI instring
#
@MV2V instring outstring
@PUSHI outstring
@CALL IsWhiteSpace
@WHILE_ZERO
   @POPNULL
   @INCI outstring
   @PUSHI outstring
   @CALL IsWhiteSpace
@ENDWHILE
@POPNULL
@PUSHI outstring
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
######################################################
# Function IsWhiteSpace(instring):(0|1)
# Return 0:false or 1:true or 2 if EOS
:IsWhiteSpace
@PUSHRETURN
=Var01 instring
@PUSHLOCALI Var01
@PUSHS
@AND 0xff
@SWITCH
@CASE " \0"
   @POPNULL   @PUSH 1   @CBREAK
@CASE "\t\0"
   @POPNULL   @PUSH 1   @CBREAK
@CASE "\n\0"
   @POPNULL   @PUSH 1   @CBREAK
@CASE 0
   @POPNULL   @PUSH 2   @CBREAK
@CDEFAULT
   @POPNULL   @PUSH 0   @CBREAK
@ENDCASE
@POPLOCAL Var01
@POPRETURN
@RET

###########################################
# Function ParseCommand(CommandWord, instring):(CmdValue)
# Takes current instring, finds keyword in first word, non destructive of instring
# (This makes that the full 'command line' is still available for later processing.
#   Find
:ParseCommand
@PUSHRETURN
=instring Var01
=substring Var02
=wordlen Var03
=matchfound Var04
=CmdValue Var05
=CmdWord Var06
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@POPI instring
@POPI CmdWord

#@PRT "Entry ParseCommand: " @PRTSI CmdWord  @PRTNL
@PUSHI CmdWord
@CALL StrSetUpCase     # StrSetUpCase modifies CmdWord inplace, no return value
#
@MA2V 0 matchfound
@MA2V KeyTable substring
#@INC2I substring       # Move it to point at start of string
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   @INC2I substring       # Move it to point at start of string
   @PUSHI CmdWord @PUSHI substring
   @DUP
   @CALL strlen
   @POPI wordlen
   @CALL strcmp
   @IF_ZERO
      @POPNULL
      # Match found, get index value
      @PUSHI substring
      @SUB 2
      @PUSHS
      @POPI matchfound
      @PUSH 0
   @ELSE
      @POPNULL
      # Match not found, inc substring by length of string
      @PUSHI wordlen
      @ADDI substring
      @ADD 1    # For the null at end of string.
      @POPI substring
      @PUSHII substring
      @IF_NOTZERO  # test if at end of KeyTable
         @POPNULL
         @PUSH 1
      @ELSE
         @POPNULL
         @PUSH 0
      @ENDIF
   @ENDIF
@ENDWHILE
@POPNULL
# matchfound will have code value of keyword, or 0 if none matched.
@MV2V matchfound CmdValue
@PUSHI matchfound
#@PRT "Exit ParseCommand: " @PRTSI instring @PRT " CmdValue: " @PRTI CmdValue @PRTNL
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
#
:KeyTable
CMDEDIT "EDIT\0"
CMDRUN  "RUN\0"
CMDLIST "LIST\0"
CMDCONT "CONT\0"
CMDQUIT "QUIT\0"
CMDPRINT "PRINT\0"
CMDSAVE "SAVE\0"
CMDLOAD "LOAD\0"
CMDDIR  "DIR\0"
CMDDELETE "DELETE\0"
CMDRENAME "RENAME\0"
CMDCOPY "COPY\0"
CMDCLS "CLS\0"
CMDCLEAR "CLEAR\0"
CMDIF "IF\0"
CMDTHEN "THEN\0"
CMDELSE "ELSE\0"
CMDFOR "FOR\0"
CMDTO "TO\0"
CMDNEXT "NEXT\0"
CMDINPUT "INPUT\0"
CMDGOTO "GOTO\0"
CMDGOSUB "GOSUB\0"
CMDHELP "HELP\0"
CMDHELP "?\0"
CMDRETURN "RETURN\0"
CMDMEM "MEM\0"
# End of list
0 0
#
#
##############################################
# Function TextEdit
:TextEdit
@PUSHRETURN
=InputLinePtr Var01
=InputMode Var02
=RangeStart Var04
=RangeStop Var05
=LineDest Var06
=Index1 Var07
=Offset1 Var08
=LineStringPtr Var09
=SaveInput Var10
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
@PUSHLOCALI Var09
@PUSHLOCALI Var10
#
@PRTLN "Text Editor"
@MA2V EDITCMDMODE InputMode       # EditCMD Mode
@MA2V 0 CurrentLine
@WHILE_NEQ_AV ENDMODE InputMode         # Repeat until ENDMODE comOPOPmand
   # Get line from Keyboard
   @IF_EQ_AV 0 CurrentLine
      @PRT "():"
   @ELSE
      @PUSHI CurrentLine @ADD 1 @PRTTOP @PRT ":" @POPNULL
   @ENDIF
   @PUSHI InputMode
   @CALL CommandPrompt
   @POPI InputLinePtr
   @MV2V InputLinePtr SaveInput
   #
   @IF_EQ_AV EDITCMDMODE InputMode
      # Current in basic editor cmd mode.
      @PUSHI InputLinePtr
      # GetEditRange(instring):(RangeStart,RangeStop,outstring)
      @CALL GetEditRange        # parces cmd line for optional pattern match or numbers(possible a range)
      @POPI InputLinePtr
      @POPI RangeStop
      @POPI RangeStart
      @PUSHI RangeStop
      @IF_GT_A 0
         @SUB 1
         @POPI CurrentLine
      @ELSE
         @POPNULL
      @ENDIF
#      @PRT "CMD: " @PRTSI InputLinePtr @PRT " Range " @PRTI RangeStart @PRT " - " @PRTI RangeStop @PRTNL      
      #
      @IF_EQ_AV 0 InputLinePtr    # Return zero here if line wasn't parceable
         @PRT "?\n"
      @ELSE
         @PUSHII InputLinePtr @AND 0xff     # Get First litter in remainder of line.
	 @SWITCH
	 @CASE "q\0"
	     # Quit Editor command.
	     @POPNULL   # Renove Key 
	     @MA2V ENDMODE InputMode   # Put Exit code for while loop on stack
             @CBREAK
	 @CASE "a\0"
	     # Enter Insert Mode at CurrentLine
	     @POPNULL
	     @MA2V EDITINSERTMODE InputMode
	     @IF_EQ_AV 0 RangeStart
	     @ELSE
	         @PRT "Append At : " @PRTI CurrentLine @PRT "( . to end )\n"
	         @MV2V RangeStart CurrentLine
             @ENDIF
	     @PUSH 1
	     @CBREAK
	 @CASE "i\0"
	     # Enter InsertMode at CurrentLine-1 (if valid)
             @POPNULL
             @MA2V EDITINSERTMODE InputMode
	     @IF_EQ_AV 0 CurrentLine
	        # Line 0 insert is same as append.
                @MA2V EDITINSERTMODE InputMode
	     @ELSE
	        @PRT "Insert At : " @PRTI CurrentLine @PRT "( . to end )\n"
		@DECI CurrentLine
                @MA2V EDITINSERTMODE InputMode
             @ENDIF
	     @CBREAK
	 @CASE "p\0"
	    #Print Range
            @POPNULL    # Just remove Key, we'll remain in CMDMODE
	    @IF_EQ_AV 0 RangeStart
	       # No Range given, print currentline + 10, set currentline to end of listing.
	       @PUSHI CurrentLine
               @PUSHI CurrentLine @ADD 10
	       @CALL PrintLines
	       @PUSHI CurrentLine @ADD 10
	       @POPI CurrentLine
            @ELSE
               # Range Given.
#               @PRT "Function PrintLines"
               @PUSHI RangeStart @SUB 1
	       @PUSHI RangeStop
	       @CALL PrintLines
	       @MV2V RangeStop CurrentLine
	    @ENDIF
	    @CBREAK
	 @CASE "d\0"
	    #Delete Range
            @POPNULL    # Just remove Key, we'll remain in CMDMODE
	    @IF_EQ_AV 0 RangeStart
	       # No Range given, delete just current line
	       @PUSHI CurrentLine
	       @PUSHI CurrentLine @ADD 1
	       @CALL DeleteLines
            @ELSE
	       # Range Given.
	       @PUSHI RangeStart
	       @PUSHI RangeStop
	       @CALL DeleteLines
            @ENDIF
	    @CBREAK
         @CASE "c\0"
            # Copy Range to target
            @POPNULL    # Just remove Key, we'll remain in CMDMODE
            @IF_EQ_AV 0 RangeStart
               # No Range given, tell user error
               @PRTLN "Need to specify src lines"
            @ELSE
               @PUSHI InputLinePtr @ADD 1     # To get past the key-letter
               @CALL stoifirst
               @POPI LineDest
               @IF_EQ_AV 0 LineDest     # No dest, then user current line number.
                  @MV2V CurrentLine LineDest
               @ENDIF
               @MA2V 0 Offset1
               @ForIV2V Index1 RangeStart RangeStop
                  @PUSHI Index1
                  @ADDI Offset1
                  @CALL GetEditLine # Returns tempoary Heap String object of Lenght of the line.
                  @POPI LineStringPtr
                  @PUSHI LineDest
                  @ADDI Index1
                  @PUSHI LineStringPtr
                  @CALL InsertEditLine
                  @PUSHI LineDest
                  @IF_LT_V RangeStart
                     @INCI Offset1   # If destination < RangeStart, then the insert would have incremnted the index of
                                     # all the lines bellow that insertion point, Offset1 keeps track of that movement.
                  @ENDIF
                  @PUSHI MainHeapID
                  @PUSHI LineStringPtr
                  # Get rid of temporary string.
                  @CALL HeapDeleteObject @IF_NOTZERO @PRT "Error Clearing Memory: Code:" @PRTTOP @PRTNL @ENDIF
                  @POPNULL
               @Next Index1
            @ENDIF
            @CBREAK
         @CASE "h\0" 
             @POPNULL   # Just remove Key, we'll remain in CMDMODE
             @PRTLN "HELP---"
             @PRTLN "range[,range]CMD[dest]"
             @PRTLN "range = { Line Number | /text/ } text will search from current line number down."
             @PRTLN "a: Append Mode (insert after current line number)"
             @PRTLN "c: Copy range of lines to destination"
             @PRTLN "d: Delete range of lines"
             @PRTLN "i: Insert Mode (insert above current line number)"
             @PRTLN "p: Print range of lines"
             @PRTLN "q: quit back to cmd mode."
             @PRTNL
             @CBREAK
         @CASE "m\0"
            @CALL MemReport
            @CBREAK
	 @CDEFAULT
            @PRT "( " @PRTSI InputLinePtr @PRT " )" @PRTTOP 
	    @PRTLN "Command Not Understood"
            @PRTLN "Try h for help."
	    @CBREAK
	 @ENDCASE
      @ENDIF
   @ELSE
      @IF_EQ_AV EDITINSERTMODE InputMode
         # Handle Insert Mode
#         @PRT "EDIT: " @PRTSI InputLinePtr @PRT " Range " @PRTI RangeStart @PRT " - " @PRTI RangeStop @PRTNL
	 @PUSHII InputLinePtr
	 @IF_EQ_A ".\0"        #Note we didn't 'AND 0xff' so only tue if . on line by itself.
           @POPNULL
           @PRTLN "End Input Mode."
           @MA2V EDITCMDMODE InputMode
         @ELSE
           @POPNULL
           @PUSHI CurrentLine
           @CALL InsertIndexSpace
           @PUSHI CurrentLine
           @PUSHI InputLinePtr
           @CALL InsertEditLine
           @PUSHI CurrentLine
           @ADD 1
           @IF_GT_V SRCMaxLines
              @DUP
              @POPI SRCMaxLines
           @ENDIF
           @POPI CurrentLine           
         @ENDIF
      @ELSE
         # Somehow InputMode became invalid, move back to CMDMODE
         @PRTLN "Unknown Cmd Mode"
         @MA2V EDITCMDMODE InputMode
      @ENDIF
   @ENDIF
   @PUSHI MainHeapID
# We maybe modifying InputLinePtr so return to original for deleteing object.
   @PUSHI SaveInput
   @CALL HeapDeleteObject
   @IF_NOTZERO
       @PRT "Error Clearing Memory: Code:" @PRTTOP @PRTNL
   @ENDIF
   @POPNULL
# Get rid of temporary string.
@ENDWHILE
@POPLOCAL Var10
@POPLOCAL Var09
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#####################################
# Function GetEditRange(instring):(RangeStart,RangeStop,outstring)
# Parse begining ofr instring for possible number/pattern range
# Format ###[,###] or /pat/[,/pat] or mix of both.
# Logic:
# Will run this test twice to support 'Start' and 'Stop' range
# If first character of remaining string is '/' it will look
# for a string match.
# If first character is '0-9' or '$' or '.' it will be a line number
# Otherwise return the original string unchanged.
#
:LastSearch 0     # If line with just '/' then repeat last search, if any.
:GetEditRange
@PUSHRETURN
=instring Var01
=linestring Var02
=VarIndex Var03
=Index1 Var04
=IsRepeat Var05
=OutStart Var06
=OutStop Var07

#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
#
@POPI instring
#@PRT "Start Edit Range:" @StackDump
# Default values for range will always be current line
@MV2V CurrentLine OutStart
@MV2V CurrentLine OutStop
#
@MA2V 0 IsRepeat
@ForIA2B VarIndex 0 2        # Loop 0 and 1, 2 is exit.
   # Test if first character is '/'
   @PUSHII instring @AND 0xff
   @IF_EQ_A "/\0"
       @PRT "Doing Itteration: " @PRTI VarIndex @StackDump
       # Handle Text search.
       @POPNULL
       @INCI instring
       @PUSHII instring @AND 0xff
       @IF_ZERO    #this is the case where line is '/' by itself
          @IF_EQ_AV 0 LastSearch
             # Trying to repeat last search...but there was no LastSearch.
             @PRTLN "No previous search to repeat"
             @PUSH 0 @PUSH 0 @PUSHI instring # Skip out of the search.
             @JMP GERFastExit
          @ELSE
             # There was a valid last search, use it.
             @MA2V 1 IsRepeat
             @PRTLN "Repeat Search: " @PRTSI LastSearch             
          @ENDIF
       @ELSE
          # Start of a new search.
          # First delete any older LastSeach to save memory.
          @IF_EQ_AV 0 LastSearch
              # Do nothing.
          @ELSE
              @PUSHI MainHeapID
              @PUSHI LastSearch
              @CALL HeapDeleteObject @IF_NOTZERO @PRT "Error Clearing Memory: Code:" @PRTTOP @PRTNL @ENDIF
              @POPNULL
          @ENDIF
          # Search for the ending '/'
          @MV2V instring Index1
          @INCI Index1
          @PUSH 0
          @WHILE_ZERO
             @POPNULL
             @PUSHII Index1 @AND 0xff
             @IF_ZERO
                # End of String before finding '/'
                @INCI Index1 # we later expect there to be 2'/'s so simulate the second.
                @PUSH 1
             @ELSE
                @IF_EQ_A "/\0"
                 # Found the ending '/'
                  @PUSH 1
                @ELSE
                  # Part of the Search String.
                  @INCI Index1
                  @PUSH 0
                @ENDIF
             @ENDIF
          @ENDWHILE
          # Lenth of the new Search String will be Index1-instring
          @PUSHI MainHeapID
          @PUSHI Index1
          @SUBI instring
          @CALL HeapNewObject  @IF_ULT_A 100 @PRT "Heap error 1238" @END @ENDIF
          @POPI LastSearch
          # Now Copy instring[1:length] to LastSearch
          @PUSHI LastSearch        # Destination
          @PUSHI instring   # Start right after the '/'
          @PUSHI Index1
          @SUBI instring
          @SUB 2                   # Lenth of string (subtract the '/'s)
          @CALL strncpy
       @ENDIF
       # At this point LastSearch will have the correct Search Pattern
       #
       # Now we do the search
       #
       @PUSH 0
       @MV2V CurrentLine Index1
       @IF_EQ_AV 1 IsRepeat
          # This is to make sure that when calling for a repeated search, it starts at the next line.
          @INCI Index1     # Is a repeat search so start at next line.
          @IF_EQ_VV Index1 SRCMaxLines
             @MA2V 0 Index1        # Roll back to top line
          @ENDIF
       @ENDIF
       # This While loop will cycle though entire buffer, exiting on match or full buffer tested.
       @WHILE_ZERO
          @POPNULL
          @PUSHI Index1
          @CALL GetEditLine
          :Debug01
          @POPI linestring
          @PUSHI LastSearch
          @PUSHI linestring          
#          @PRTSI linestring @PRT " vs " @PRTSI LastSearch          
          @CALL strstr       # Returns 0 if no match
#          @PRT " = " @PRTTOP
           :Debug02
          @IF_ZERO
              @POPNULL
              @INCI Index1
              @IF_EQ_VV Index1 CurrentLine  # This means search wrapped around all lines.
                 @PUSH 2                   # 2 Will means full search, no match.
              @ELSE
                 @PUSHI Index1
                 @IF_GE_V SRCMaxLines
                    @POPNULL
                    @MA2V 0 Index1        # Roll back to top line
                    @PRTLN "Reached EOF Search rolling up to top."
                 @ELSE
                    @POPNULL
                 @ENDIF
              @PUSH 0      # Continue the loop for next line.
              @ENDIF              
           @ELSE
              # strstr > 0 so there was a match, make this the new CurrentLine
              @PUSH 1          # 1 means found item and exit.
           @ENDIF
       @ENDWHILE
       @IF_EQ_A 2
          @PRTLN "No Match"
       @ELSE
          @MV2V Index1 CurrentLine
       @ENDIF
       @IF_EQ_AV 0 VarIndex
          @MV2V CurrentLine OutStart
       @ELSE
          @MV2V CurrentLine OutStop
       @ENDIF
   @ELSE
       # Test now if first character is one of the following
       # 0-9 '$' or '.' or '^'
       @IF_EQ_A ".\0"
          @POPNULL
          @PUSH 1
          @INCI instring
       @ENDIF   # Code 1 means Current Line
       @IF_EQ_A "$\0"
          @POPNULL
          @PUSH 2
          @INCI instring
       @ENDIF   # Code 2 means Last Line
       @IF_EQ_A ".\0"
          @POPNULL
          @PUSH 3
          @INCI instring
       @ENDIF
       @IF_GE_A "0\0"
          @IF_LE_A "9\0"
              @POPNULL @PUSH 4
          @ENDIF
       @ENDIF
       # TOS will be # 1-3 or we we've reach end of the range info.
       @SWITCH
       @CASE 1
          # Was . so range is CurrentLine
          @IF_EQ_AV 0 VarIndex
             @MV2V CurrentLine OutStart
             @MV2V OutStart OutStop
             @PUSHII instring @AND 0xff
             @IF_EQ_A ",\0"
                @INCI instring # Setup for second range value if any.
             @ENDIF
             @POPNULL
          @ELSE
             @MV2V CurrentLine OutStop
          @ENDIF
          # Leaves 1 on stack
          @CBREAK
       @CASE 2
          # Was $ so range is SRCMaxLines
          @IF_EQ_AV 0 VarIndex
             @MV2V SRCMaxLines OutStart
             @MV2V OutStart OutStop
             @PUSHII instring @AND 0xff
             @IF_EQ_A ",\0"
                @INCI instring # Setup for second range value if any.
             @ENDIF
             @POPNULL
          @ELSE
             @MV2V SRCMaxLines OutStop
          @ENDIF
          # Leaves 2 on stack
          @CBREAK
       @CASE 3
          # Start at first line. (basicly same as 1)
          @IF_EQ_AV 0 VarIndex
             @MA2V 1 OutStart
             @MV2V OutStart OutStop
             @IF_EQ_A ",\0"
                @INCI instring # Setup for second range value if any.
             @ENDIF
             @POPNULL
          @ELSE
             @MA2V 1 OutStop
          @ENDIF
          @CBREAK
       @CASE 4
          # It was a number.
          @PUSHI instring
          @CALL stoifirst
          @PUSHI instring
          @CALL FirstNonDigit
          @POPI instring
          @IF_EQ_AV 0 VarIndex          
             @POPI OutStart
             @MV2V OutStart OutStop    # Cases when only one number given.
             @PUSHII instring @AND 0xff
             @IF_EQ_A ",\0"
                @INCI instring # Setup for second range value if any.
             @ENDIF
             @POPNULL
          @ELSE
             @POPI OutStop             
          @ENDIF
          @CBREAK
        @CDEFAULT
          # No need to modify instring.
          @CBREAK
     @ENDCASE
   @ENDIF
   @POPNULL
@Next VarIndex
@PUSHI OutStart @PUSHI OutStop @PUSHI instring
#@PRT "Range : " @PRTI OutStart @PRT " to " @PRTI OutStop @PRTNL
:GERFastExit     #This exit point is for the error cases
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


########################################
# Function FirstNonDigit(instring):outstring
# Searches forward instring for first non-digit number returns pointer to that character.
:FirstNonDigit
@PUSHRETURN
=instring Var01
@PUSHLOCALI Var01
@POPI instring
@PUSHII instring @AND 0xff
@WHILE_NOTZERO
   @IF_GE_A "0\0"
      @IF_LE_A "9\0"
          @POPNULL
          @INCI instring
          @PUSHII instring @AND 0xff
      @ELSE
          @POPNULL
          @PUSH 0
      @ENDIF
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@POPNULL
@PUSHI instring
@POPLOCAL Var01
@POPRETURN
@RET
########################################
# Function PrintLines(start,stop)
:PrintLines
@PUSHRETURN
=StartLine Var01
=StopLine Var02
=Index1 Var03
=StringLine Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@POPI StopLine
@POPI StartLine
#@PRT "Start Print Lines:" @StackDump
@PUSHI StopLine
@IF_UGE_V SRCMaxLines
   @MV2V SRCMaxLines StopLine
@ENDIF
@POPNULL
#
@ForIV2V Index1 StartLine StopLine
    @PUSHI Index1
    @CALL GetEditLine
    @POPI StringLine    
    @PUSHI Index1 @ADD 1 @PRTTOP @POPNULL # Print Index1+1 (so lines appear to start at 1 not zero)
    @PRT ": " @PRTSI StringLine @PRTNL
    @PUSHI MainHeapID
    @PUSHI StringLine
    @CALL HeapDeleteObject @IF_NOTZERO @PRT "Error Clearing Memory: Code:" @PRTTOP @PRTNL @ENDIF
    @POPNULL
@Next Index1
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
#@PRT "Stop Print Lines:" @StackDump
@POPRETURN
@RET

########################################
# Function DeleteLines(start,stop)
:DeleteLines
@PUSHRETURN
=StartLine Var01
=StopLine Var02
=Index1 Var03
=StringLine Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@POPI StopLine
@POPI StartLine
#
@PRT "List Lines " @PRTI StartLine @PRT " To " @PRTI StopLine @PRTNL
@ForIV2V Index1 StartLine StopLine
    @PUSHI Index1
    @CALL GetEditLine
    @POPI StringLine
    @PRTI Index1 @PRT ": " @PRTSI StringLine @PRTNL
@Next Index1
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

###########################################
# Function GetEditLine(linenum)
:GetEditLine
@PUSHRETURN
=linenum Var01
=TempObject Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
#
@IF_UGT_V SRCMaxLines
   @PRTTOP @PRT " is not a valid line number"
   @POPNULL
   @PUSH BlankLine
@ELSE
   # Get line string pointer
   @POPI linenum
   @PUSHI linenum @SHL
   @ADDI SRCIndex
   @PUSHS
   @DUP
   @POPI TempObject
@ENDIF

@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
:BlankLine 0 0

###################################
# Function InsertEditLine(linenum, instring)
:InsertEditLine
@PUSHRETURN
=linenum Var01
=instring Var02
=acutualsize Var03
=Index01 Var04
=Index02 Var05
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@POPI instring
@POPI linenum
#
@PUSHI linenum
@IF_UGT_V SRCAllocCnt
   # Line number if > allocated lines.
   # First make sure the line number is 'reasonable'
   @ADD 100
   @IF_UGT_V SRCAllocCnt
       # User ented some number > 100 lines past End of buffer.
       @PRT "Are you sure " @PRTI linenum @PRT " is where you want to insert text?"
       @PRT "Please enter lower numbered lines first to allocate space."
       @POPNULL
       @PUSH -1
   @ELSE
       @POPNULL @PUSHI linenum
       # Allocate new space for lines past current end
       @PUSHI MainHeapID @PUSHI SRCIndex
       @PUSHI SRCAllocCnt @ADD 200
       @CALL HeapResizeObject
       @PUSHI SRCAllocCnt @ADD 100 @POPI Index01
       @ForIV2V Index02 SRCAllocCnt Index01
           # Fill new space with 0's
           @PUSH 0
           @PUSHI SRCIndex @ADDI Index02 @ADDI Index02
           @POPS
       @Next Index02
   @ENDIF
@ENDIF
# IF block exits with -1 on error, else still has linenum at TOS
@IF_EQ_A -1
   @POPNULL
@ELSE
   # Check to see if we need to delete old string at this index.
   @SHL @ADDI SRCIndex
   @POPI Index01   # Is address where ptr to string will be saved.   
   @PUSHII Index01
   @IF_ZERO
      @POPNULL      # index not allocated to line string.
   @ELSE
      # Index was allocated to line string, so delete heap of that string.
      @PUSHI MainHeapID
      @SWP
      @CALL HeapDeleteObject @IF_NOTZERO @PRT "Error Clearing Memory: Code:" @PRTTOP @PRTNL @ENDIF
   @ENDIF
   # Now create new empty string for Index01
   @PUSHI MainHeapID
   @PUSHI instring
   @CALL strlen @ADD 2     # add a few bytes for padding around new string.
   @CALL HeapNewObject     @IF_ULT_A 100 @PRT "Heap error 1603" @END @ENDIF
   @POPII Index01           # Save pointer at spot
   # Now copy instring to that new space.
   @PUSHII Index01
   @PUSHI instring
   @CALL strcpy
   # Now if linenum is a new high mark for used line, move the high mark.
   @PUSHI linenum
   @IF_GT_V SRCMaxLines
      @POPI SRCMaxLines
   @ELSE
      @POPNULL
   @ENDIF
@ENDIF
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#############################################
# Function InsertIndexSpace(currentline)
# Moves and expands Index List to make currentline available
:InsertIndexSpace
@PUSHRETURN
=CurrentLine Var01
=Index01 Var02
=Index02 Var03
=MaxLines Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@POPI CurrentLine
@INCI SRCMaxLines
@PUSHI SRCAllocCnt
@IF_LE_V CurrentLine
    # Allocated space for  SRCIndex is too small expand it by 25 lines.
    @ADD 25
    @POPI MaxLines
    @PUSHI MainHeapID
    @PUSHI SRCIndex
    @PUSHI MaxLines @SHL
    @CALL HeapResizeObject @IF_LT_A 100 @PRTLN "Failed to resize Index." @END @ENDIF
    @POPI SRCIndex
    @MV2V MaxLines SRCAllocCnt
@ENDIF
# SRCMaxLines should always be smaller than SRCAllocCnt and >= CurrentLine
@ForIV2V Index01 SRCMaxLines CurrentLine
   # Copy from SRCMaxLines downto CurrentLine
   @PUSHI SRCIndex
   @ADDI Index01
   @ADD 1 @SHL
   @PUSHS        # Val of mem[i+1]
   @PUSHI SRCIndex
   @ADDI Index01 @SHL
   @POPS         # pop to mem[i]
@NextBy Index01 -1
@POPNULL
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
######################################
# Function MemReport
# Called to print how memory is being used.
:MemReport
@PRTLN "Memory Info:"
@PUSHI MainHeapID
@CALL HeapListMap
@PRTLN "-------------------------"
@PRT "Current Line: " @PRTI CurrentLine
@PRT " SRCMaxLines: " @PRTI SRCMaxLines
@PRT "\n---------------------------"
@ForIA2V Index1 0 SRCMaxLines
   @PRTNL            
   @PUSHI Index1 @ADD 1 @PRTTOP @PRT ":" @POPNULL
   @PUSHI SRCIndex @ADDI Index1 @ADDI Index1 @PUSHS @PRTHEXTOP @PRT ":" @POPI LineDest
   @PRTSI LineDest
@Next Index1
@PRT "\n___________________________\n"
@StackDump
@RET

####################################
# Function ListBuffer
# Command Mode list Buffer function
:ListBuffer
@PUSHRETURN
=RangeStart Var01
=RangeStop Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI RangeStop
@POPI RangeStart
@IF_EQ_AV 0 RangeStart
   @PUSHI CMDCurrentLine
   @PUSHI CMDCurrentLine @ADD 10
   @CALL PrintLines
   @PUSHI CMDCurrentLine @ADD 10
   @POPI CMDCurrentLine
@ELSE
   @PUSHI RangeStart
   @IF_GE_V SRCMaxLines
       @POPNULL
       @PUSHI SRCMaxLines
   @ENDIF   
   @SUB 1
   @PUSHI RangeStop
   @IF_GE_V SRCMaxLines
       @POPNULL
       @PUSHI SRCMaxLines
   @ENDIF
   @IF_GT_S
      @SWP
   @ENDIF
   @CALL PrintLines
   @MV2V RangeStop CMDCurrentLine
@ENDIF
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
:RunBuffer
@RET
:PrintVar
@RET
:ClearProgram
@RET
:SymbolList
@RET
:ENDOFCODE
. Main
