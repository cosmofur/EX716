I common.mc
L heapmgr.ld
L softstack.ld
L string.ld
# This is going to be a elementry editor.
# Not trying to re-create vi or ed with all its regex powers. But something more like old MSDOS edline
#
# Common variables
# Number of bytes in LineDBHeader for offsets.
=LineDBHeader 2
:Dest1 0
:CursorPtr 0
:Range1 0
:Range2 0
:Index1 0
:Index2 0
:IsNumber 0
:CommandLinePtr 0
:EditBuffer1Ptr 0
:MainHeapID 0
:CLN 0
:MaxLineNum 0
:Modified 0
:StrPtr 0
:WorkBuffer 0
:LineinfoDB 0
:LineNumber 0
:BufferSize 0
:NewSize 0
:OldSize 0
:GapSize 0
:Src1 0
:DeleteLine 0
:BottomRange 0
:TopRange 0
# Start of Code:
:Main . Main
#
# Set up the Heap for storage
# We'll assign from ENDOFCODE to 0xf000 as the 
@PUSH ENDOFCODE @PUSH 0xf000 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeapID
#
# We're propbably going to need a larger softstack than the defualt 240 bytes, so setup a 1K stack in the heap
@PUSHI MainHeapID @PUSH 0x400   # 0x400 same as 1K bytes
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Out of Memory 0001" @END @ENDIF
# On Stack is ptr to a 0x400 block, the SetSStack needs (TopAddress,BottomAddres) so do some math

@DUP @ADD 0x400 @SWP
@PRTLN "--------- Stack Set to new Range ---------"
@CALL SetSSStack
@PRT "Stack Bottom: " @PRTHEXI __SS_BOTTOM @PRT " Top: " @PRTHEXI __SS_TOP @PRT " SP: " @PRTHEXI __SS_SP @PRTNL
#
# Create some command line and edit line buffers.
@PUSHI MainHeapID @PUSH 0x100
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Out of Memory 0002:" @StackDump  @END @ENDIF
@POPI CommandLinePtr
@PUSHI MainHeapID @PUSH 0x100
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Out of Memory 0003" @END @ENDIF
@POPI EditBuffer1Ptr
#
# Now Create the initial work buffer. 
# Initially just large enough for line counter and maxused numbers
@PUSHI MainHeapID @PUSH 0x100
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Out of Memory 0004" @END @ENDIF
@POPI WorkBuffer
@MA2V 0 BufferSize
# Now create a LineinfoDB, start smallish will enlarge it when we need to.
# LineinfoDB is ptr to a simple list of memory pointers to the acutual strings that make up the lines.
# LineinfoDB[0] = active lines
# 0th word is the current count, and lines 1-MaxLineNum
@PUSHI MainHeapID @PUSH 0x100
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Out of Memory 0005" @END @ENDIF
@POPI LineinfoDB
@PUSH 0 @POPII LineinfoDB
#
@MA2V 0 MaxLineNum
#
# Set some control flags and variables
=TRUE 1
=FALSE 0
@MA2V TRUE Modified   # Set to true if anything modifies the buffer, so we can keep track of if need to save or not.
@MA2V 0 CLN     # Current Line Number

#
# Here we start our main program loop
@PUSH 0
@WHILE_ZERO                # d0
   @PRT "Top While (1) :" @StackDump
   @POPNULL
   @PRT "> "
   @MV2V CLN Range1
   @MV2V CLN Range2
   @READSI CommandLinePtr
   @PUSHI CommandLinePtr
   @PUSHI CommandLinePtr @CALL strlen
   @IF_ZERO                # d1
      @POPNULL   
      # No text entered, just print "?" and resume While loop
      @PRTLN "?"
   @ELSE                   # d1a
      @POPNULL   
      @MV2V CommandLinePtr CursorPtr
      @PUSHII  CursorPtr @AND 0xff   # Look at just the first character.
      @WHILE_EQ_A " \0"    # Skip past any spaces  d2
         @POPNULL
         @INCI CursorPtr
         @PUSHII  CursorPtr @AND 0xff   # Look at just the first character.
      @ENDWHILE            # d1<
      @IF_ZERO       # The line was just all spaces, so treat as empty line  # d2
         @PRTLN "?"
	 @POPNULL
      @ELSE                # d2a
         # Now look at first character and see if it a number.
         @MA2V FALSE IsNumber         
         @SWITCH           # d3
         @CASE_RANGE "0\0" "9\0"
	    @MA2V TRUE IsNumber
	    @CBREAK
         @CASE ".\0"
            @MA2V TRUE IsNumber
            @CBREAK
         @CASE "$\0"
            @MA2V TRUE IsNumber
            @CBREAK
         @CASE "^\0"
            @MA2V TRUE IsNumber
            @CBREAK
         @CDEFAULT
            @MA2V FALSE IsNumber
            @CBREAK
         @ENDCASE          # d3<
	 @POPNULL
         @PUSHI IsNumber
         @IF_NOTZERO       # d3
            @PRTLN "Detected Number:" 
            @POPNULL
            @PUSHI CursorPtr
            @CALL GetNumberPart   # Deals with 0-9 ^ $ and . returns both value and new cursor pos.
            @POPI Range1
            @MV2V Range1 Range2   # If there is no Range2 then Range2 defaults to Range1
            @POPI CursorPtr
            @PUSHII CursorPtr @AND 0xff     # Look at 'next' chracter, if ",' then its a range.
            @IF_EQ_A ",\0"         # d4
               @INCI CursorPtr
               @PUSHI CursorPtr
               @CALL GetNumberPart   # Gets second number
               @POPI Range2
               @POPI CursorPtr
            @ENDIF                 # d4a
            @PRT "Result Range1: " @PRTI Range1 @PRT " " @PRTI Range2 @PRTNL
	 @ELSE
	    @POPNULL
         @ENDIF                    # d4<
         @PUSHII CursorPtr @AND 0xff     # This should be pointing at a command letter.
         @SWITCH                # d5
         @CASE 0
            @PRTLN "Command not understood.
            @CBREAK
         @CASE "p\0"      # List command (list without line numbers)
            @PRT "Print Range " @PRTI Rang1 @PRT " " @PRTI Range2 @PRTNL
            @INCI Range2
            @ForIV2V Index1 Range1 Range2      # d6
                @PUSHI Index1 @PUSHI EditBuffer1Ptr
                @CALL FetchLine          # Get Line Number and save its text to buffer
                @PRTS EditBuffer1Ptr
                @PRTNL
            @Next Index1                       # d6<
            @CBREAK
         @CASE "n\0"      # List but also print the number numbers
            @INCI Range2
            @ForIV2V Index1 Range1 Range2      # d6
                @PUSHI Index1 @PUSHI EditBuffer1Ptr
                @CALL FetchLine          # Get Line Number and save its text to buffer
                @PRTI Index1 @PRT ": "
                @PRTS EditBuffer1Ptr
                @PRTNL
            @Next Index1                       # d6<
            @CBREAK
         @CASE "i\0"
            # Go into entry mode as 'insert' new text get put starting before CWL
            @PUSHI Range1 @PUSHI Range2
 	    @CALL ValidRange
	    @POPI Range2 @POPI Range1
	    @PUSHI Range1
            @SUB 1
            @IF_ULT_A 0      # If for some reason user tried to use negative as start range, reset to zero # d6
               @POPNULL
               @PUSH 0
            @ENDIF                             # d6<
            @CALL EntryMode
            @CBREAK
         @CASE "a\0"
            # Go into entry mode as 'append' new text get put starting at line after CWL
            @PUSHI Range1 @PUSHI Range2
 	    @CALL ValidRange
	    @POPI Range2 @POPI Range1
	    @PUSHI Range1
            @CALL EntryMode
            @CBREAK
         @CASE "t\0"
            # 't' stands for transcribe, and is the old ed name for copy a range.
            @INCI CursorPtr
            @PUSHI CursorPtr
            @CALL GetNumberPart  # Get the destination.
            @POPI Dest1
            @POPI CursorPtr
            @PUSHI Range1 @PUSHI Range2 @PUSHI Dest1
            @CALL CopyLines
            @CBREAK
         @CASE "d\0"
            # Delete a range of lines
            # In order to simplify the delete process, we need do go down from High number to Low.
            @PUSHI Range1 @PUSHI Range2
 	    @CALL ValidRange
	    @POPI Range2 @POPI Range1
            @PUSHI Range1
            @IF_UGT_V Range2                    # d6
               # Swap the order.
               @PUSHI Range2
               @SWP
               @POPI Range2
               @POPI Range1
           @ENDIF                              # d6<
           @INCI Range2
           @ForIV2V Index1 Range2 Range1       # d6
              @PUSHI Index1
              @CALL DeleteLine
           @NextBy Index1 -1                   # d6<
           @CBREAK
         @CDEFAULT
           @PRTLN "Commands:"
           @PRTLN "p - print lines, ex) 5,$p"
           @PRTLN "n - print numbered lines, ex) ^,.n"
           @PRTLN "i - insert mode, ex) 1i"
           @PRTLN "a - append mode, ex) $a"
           @PRTLN "t - Transcribe, ex 1,5t10"
           @CBREAK
         @ENDCASE                                 # d5<
	 @POPNULL
      @ENDIF               # d4<
   @ENDIF                  # d3<
   @PRT "Bottom Main If Block (1) :" @StackDump
   @PUSH 0
@ENDWHILE                  # d2<
@END

#
# Function GetNumberPart(StringPtr)
# Returns number at start of string, also knows about symbols "^.$+-"
# ^ means first line
# . means current line
# $ means last line
# +### or -### means relative to current line
:GetNumberPart
@PUSHRETURN
@PUSHLOCALI StrPtr
@PUSHLOCALI Index1
#
@POPI StrPtr
#
@PUSHII StrPtr
@AND 0xff
@SWITCH
@CASE "^\0"
   @PUSH 1
   @CBREAK
@CASE "$\0"
   @PUSHI MaxLineNum
   @CBREAK
@CASE ".\0"
   @PUSHI CLN
   @CBREAK
@CASE "+\0"
   @INCI StrPtr
   @PUSHI StrPtr
   @CALL stoi
   @ADDI CLN
   @CBREAK
@CASE "-\0"
   @INCI StrPtr
   @PUSHI StrPtr
   @CALL stoi
   @PUSHI CLN
   @SWP
   @SUBS
   @CBREAK
@CASE_RANGE "0\0" "9\0"
   @PUSHI StrPtr
   @INCI StrPtr
   @PUSH 0
   @WHILE_ZERO
      @POPNULL
      @PUSHII StrPtr @AND 0xff
      @IF_GE_A "0\0"
         @IF_LE_A "9\0"
            @POPNULL
            @INCI StrPtr
            @PUSH 0
         @ELSE
            @POPNULL
            @PUSH 1
         @ENDIF
      @ELSE
         @POPNULL
         @PUSH 1
      @ENDIF
   @ENDWHILE
   @POPNULL
   @PUSHII StrPtr @POPI Index1
   @PUSH 0 @POPII StrPtr    # Tempoarly zero the next letter
   @CALL stoi               # get the numerical value
   @PUSHI Index1 @POPII StrPtr # Put the letter back
   :Break1
   @CBREAK
@CDEFAULT
   @PRTLN "Error invalid range:" @PRTS StrPtr @PRTNL
   @PUSH 0
   @CBREAK
@ENDCASE
:Break2
@POPLOCAL Index1
@POPLOCAL StrPtr
@POPRETURN
@RET
#
# Function FetchLine(linenum, EditBuffer) returns string at Line Number
# linenum must be greater than 0, and EditBuffer must point to at least 256 bytes of storage.
:FetchLine
@PUSHRETURN
@PUSHLOCALI LineNumber
@PUSHLOCALI EditBuffer1Ptr
@POPI EditBuffer1Ptr
@POPI LineNumber
@PUSHII LineinfoDB
@IF_ULT_V LineNumber
   @PRT "Line Number: " @PRTI LineNumber @PRT " is not valid. Max lines are: " @PRTTOP @PRTNL
   @POPNULL
@ELSE
   @POPNULL
   # call strncpy(EditBuffer1Ptr,LinePtr)
   @PUSHI EditBuffer1Ptr 
   @PUSHI LineinfoDB
   # LineNumber*2 for words rather than bytes
   @ADDI LineNumber @ADDI LineNumber # word data at LineinfoDB[index]
   @ADD LineDBHeader                 # Header 
   @PUSHS                            # TOS is ptr to line data.
   @PUSH 0xff                        # Max characters a line can have
   @CALL strncpy
@ENDIF
@POPLOCAL EditBuffer1Ptr
@POPLOCAL LineNumber
@POPRETURN
@RET
#
# Function CopyLines(Range1,Range2,LineNumber)
# Copies the lines from start to stop. Creating New lines and inserting them in the right spot of the line list.
:CopyLines
@PUSHRETURN
@POPNULL @POPNULL @POPNULL
@POPRETURN
@RET
# Function EntryMode(Range1)
:EntryMode
@PUSHRETURN
@PUSHLOCALI Range1
@PUSHLOCALI CommandLinePtr
@PUSHLOCALI Index1
#
@POPI Range1
#
@PUSH 0
@WHILE_ZERO
  @POPNULL
  @PRT "I:" @PRTI Range1 @PRT " > "
  @READSI CommandLinePtr
  @PUSHII CommandLinePtr  #not not masking with 0xff here. 
  @IF_EQ_A ".\0"
    # If "." by itself then end of entry mode.
    @PUSH 1    # end the while loop.
  @ELSE
    # Open a one line space at location Range1
    @PUSHI LineinfoDB
    @PUSHI Range1
    @PUSH 1
    @CALL InsertDBGap @IF_ULT_A 100 @PRT "Out of Memory 0008" @END @ENDIF @POPI LineinfoDB
    # Save address of new linedb entry
    @PUSHI LineinfoDB @ADDI Range1 @ADDI Range1 @ADD LineDBHeader @POPI Index1   
    # Create a new Heap Object with size of CommandLine
    @PUSHI CommandLinePtr
    @CALL strlen
    @PUSHI MainHeapID
    @SWP
    @CALL HeapNewObject @IF_ULT_A 100 @PRT "Out of Memory 0008" @END @ENDIF
    @POPII Index1   # While location of new object at current LineDB entry
    # Now copy the text content of CommandLinePtr into the Object
    @PUSHI CommandLinePtr
    @PUSHII Index1
    @PUSH 0xff                # Max characters a line 
    @CALL strncpy
    @PUSH 0
  @ENDIF
@ENDWHILE
#
@POPLOCAL Index1
@POPLOCAL CommandLinePtr
@POPLOCAL Range1
@POPRETURN
@RET



#
#
# Function InsertDBGap(LineinfoDB,LineNumber, GapSize):LineInfoDb
#
# Note: LineNumber and GapSize are given in 'lines' not bytes.
# Address of LineNumber is LineinfoDB+LineinfoHeader+2*LineNumber
# 
# word:LineinfoDB[0] count of active lines
# word:LineinfoDB[1] total count of lines
# If GapSize*2+LineinfoDB[0] > LineinfoDB[1], then enlarge LineinfoDB
# Loop index from top of LineDB-GapSize down to LineNumber
#     Move Line[index+gapsize]  to  Line[index]
# 
:InsertDBGap
@PUSHRETURN
@PUSHLOCALI LineinfoDB
@PUSHLOCALI LineNumber
@PUSHLOCALI GapSize
@PUSHLOCALI Index1
@PUSHLOCALI OldSize
@PUSHLOCALI TopRange
@PUSHLOCALI BottomRange
#
@POPI GapSize
@POPI LineNumber
@POPI LineinfoDB
#
# Test if GapSize+LineinfoDB[0] > sizeof(LineinfoDB)
@PUSHI GapSize
@ADDII LineinfoDB    # Location where size of current active linedb is stored.
@RTL                 # turn into bytes
@ADD LineDBHeader    # TOS is total size of 'used' linedb
#
# Check if we have run out of space for LineinfoDB yet.
#
@PUSHI MainHeapID @PUSHI LineinfoDB @CALL GetObjectRealSize
 

@ADD LineDBHeader @POPI OldSize @PUSHI OldSize
#
@IF_UGT_S
   # Resize LineinfoDB, add extra 256 bytes
   # Order for Resize is (HeaID, Object, NewSize)
   @PUSHI MainHeapID
   @PUSHI LineinfoDB
   @PUSHI OldSize @ADD 0x100
   @CALL HeapResizeObject @IF_ULT_A 100 @PRT "Out of Memory 0007" @END @ENDIF @POPI LineinfoDB
@ELSE
   @POPNULL
   @POPNULL
@ENDIF
#
# We're going to  loop Index from Total Lines down to LineNumber+Gap
# Then copy db[index-Gap] to db[index]
@PUSHII LineinfoDB     # Keep track these are in lines, not bytes
@ADDI GapSize 
@POPI TopRange
#
@PUSHI LineNumber
@ADDI GapSize
@POPI BottomRange
#
# Turn Ranges into Bytes/Addresses
@PUSHI TopRange @RTL @ADDI LineinfoDB @ADD LineDBHeader @POPI TopRange
@PUSHI BottomRange @RTL @ADDI LineinfoDB @ADD LineDBHeader @POPI BottomRange
#
@ForIV2V Index1 TopRange BottomRange
   @PUSHI Index1 @SUBI GapSize @PUSHS
   @POPII Index1
@NextBy Index1 -2     # Step down by 16 bit words
@PUSHI LineinfoDB
@POPLOCAL BottomRange
@POPLOCAL TopRange
@POPLOCAL OldSize
@POPLOCAL Index1
@POPLOCAL GapSize
@POPLOCAL LineNumber
@POPLOCAL LineinfoDB
@POPRETURN
@PRT "End of LineinfoDB:" @PRTHEXTOP @PRTNL
@RET


#
# Function ValidRange(Range1,Range2):[Range1,Range2]
:ValidRange
@PUSHRETURN
@PUSHLOCALI Range1
@PUSHLOCALI Range2
@POPI Range2
@POPI Range1
@PUSHI Range1
@IF_ULT_A 1	       
   @MA2V 1 Range1
@ELSE
   @IF_UGT_V MaxLineNum
      @MV2V MaxLineNum Range1
   @ENDIF
@ENDIF
@POPNULL
@PUSHI Range2
@IF_ULT_A 1
   @MA2V 1 Range2
@ELSE
   @IF_UGT_V MaxLineNum
      @MV2V MaxLineNum Range2
   @ENDIF   
@ENDIF
@POPNULL
@PUSHI Range1
@PUSHI Range2
@POPLOCAL Range2
@POPLOCAL Range1
@POPRETURN
@RET
:ENDOFCODE
