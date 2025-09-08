I common.mc
L softstack.ld
L heapmgr.ld
L random.ld
L screen.ld
L heapmgr.ld
#
# Cards

# Cards are defined as 2 hex nibbles 0-c for value and 0x-3x for suit
:FixDeck
0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c
0x10 0x11 0x12 0x13 0x14 0x15 0x16 0x17 0x18 0x19 0x1a 0x1b 0x1c
0x20 0x21 0x22 0x23 0x24 0x25 0x26 0x27 0x28 0x29 0x2a 0x2b 0x2c
0x30 0x31 0x32 0x33 0x34 0x35 0x36 0x37 0x38 0x39 0x3a 0x3b 0x3c 0x5d

:Deck
0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0
:DeckCount 0

:Pile
0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0
:PileCount 0

:MainHeap 0
:MainScore 0

# Score Keeping
=ROYAL_FLUSH 250
=STRAIGHT_FLUSH 50
=FOUR_OF_A_KIND 25
=FULL_HOUSE 9
=FLUSH 6
=STRAIGHT 4
=THREE_OF_A_KIND 3
=TWO_PAIR 2
=ONE_PAIR 1
=JACKS 1



########################################
# Function Shuffle
:Shuffle
@PUSHRETURN
@LocalVar Index01 01
@LocalVar Index02 02
#
@ForIA2B Index01 0 53
   @PUSH 0 @PUSHI Index01 @ADD Pile
   @POPS
@Next Index01
@ForIA2B Index01 0 52
   @PRT "."
   @PUSH 52 @CALL frndint
   @POPI Index02
   @PUSHI Index02 @SHL @ADD Pile @PUSHS
   @WHILE_NOTZERO
      @POPNULL
      @INCI Index02
      @IF_EQ_AV 52 Index02
          @MA2V 0 Index02
      @ENDIF
      @PUSHI Index02 @SHL @ADD Pile @PUSHS
   @ENDWHILE
   @POPNULL   
   @PUSH 1 @PUSHI Index02 @SHL @ADD Pile @POPS
   @PUSHI Index01 @SHL @ADD FixDeck @PUSHS
   @PUSHI Index02 @SHL @ADD Deck @POPS
@Next Index01
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#############################
# Function PrintCard(ID)
:PrintCard
@PUSHRETURN
@LocalVar ID 01
@LocalVar Value 02
@LocalVar Suite 03
@LocalVar StrPtr 04
@POPI ID
#
@PUSHI ID @AND 0xf @POPI Value
@PUSHI ID @SHR @SHR @SHR @SHR @AND 0xf @POPI Suite
#@PRTI Value @PRT ":" @PRTI Suite

@PRT "+-----------+" @PRTS BackRow @PRTS DownRow
@PRT "| "
@PUSHI Value @SHL @SHL @ADD CardVal @POPI StrPtr @PRTSTRI StrPtr
@PUSHI Suite @SHL @ADD CardSuites @POPI StrPtr @PRTSTRI StrPtr
@IF_EQ_AV 9 Value
   # Nothing Value 9 is card 10, extra letter for '1'
@ELSE
   @PRT " "
@ENDIF
@PRT "       |"
@PRTS BackRow @PRTS DownRow
@PRT "|           |" @PRTS BackRow  @PRTS DownRow
@PRT "|           |" @PRTS BackRow  @PRTS DownRow
@PRT "|           |" @PRTS BackRow @PRTS DownRow
@PRT "|           |" @PRTS BackRow @PRTS DownRow
@PRT "|           |" @PRTS BackRow @PRTS DownRow
@PRT "|           |" @PRTS BackRow @PRTS DownRow
@PRT "|           |" @PRTS BackRow @PRTS DownRow
@PRT "|       "
@PUSHI Value @SHL @SHL @ADD CardVal @POPI StrPtr @PRTSTRI StrPtr
@PUSHI Suite @SHL @ADD CardSuites @POPI StrPtr @PRTSTRI StrPtr
@IF_EQ_AV 9 Value
   # Nothing
   
@ELSE
   @PRT " "
@ENDIF
@PRT " |" @PRTS BackRow @PRTS DownRow
@PRT "+-----------+" @PRTS BackRow @PRTS DownRow
@PRTNL
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
:CardVal "A\0  " "2\0  " "3\0  " "4\0  " "5\0  " "6\0  " "7\0  " "8\0  " "9\0  " "10\0 " "J\0  " "Q\0  " "K\0  " "X\0  "
:CardSuites "D\0" "H\0" "S\0" "C\0" "X\0"
#
#
##########################
# PrintDeck
:PrintDeck
@PUSHRETURN
@LocalVar Index01 01
@LocalVar XPOS 02
@LocalVar YPOS 03
@LocalVar ZPOS 04
#
@MA2V 0 XPOS
@MA2V 0 YPOS
@MA2V 0 ZPOS
@CALL WinClear
@ForIA2B Index01 0 52
   @PUSHI XPOS @PUSHI YPOS @CALL WinCursor
   @PUSHI Index01 @SHL @ADD Deck @PUSHS
   @CALL PrintCard
#   @PUSHI XPOS @ADD 2 @PUSHI YPOS @ADD 3 @CALL WinCursor
#   @PUSHI Index01 @SHL @ADD Deck @PUSHS @PRTTOP @POPNULL
   
   @PUSHI XPOS @ADD 5
   @PUSHI WinWidth @SUB 15
   @IF_GT_S
      @POPNULL
      @POPNULL
      @INC2I ZPOS      
      @MV2V ZPOS XPOS
      @PUSHI YPOS @SUB 5  @POPI YPOS
   @ELSE
      @POPNULL
      @POPI XPOS
      @INCI YPOS
   @ENDIF
 @Next Index01
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
 
#
:Main . Main
# Refresh random seed
@GETTIME @POPNULL @CALL rndsetseed
#
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeap
@MA2V 0 MainScore
@CALL PokerSlots
@END

#############################
# Function PokerSlots
:PokerSlots
@PUSHRETURN
@LocalVar TablePtr 01
@LocalVar WastePtr 02
@LocalVar PullListPtr 03
@LocalVar Index01 04
@LocalVar DrawCard 05

@PUSHI MainHeap @PUSH 10
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Erro 184" @END @ENDIF
@POPI TablePtr
@PUSHI MainHeap @PUSH 10
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Erro 184" @END @ENDIF
@POPI PullListPtr
@PUSHI MainHeap @PUSH 104
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Erro 187" @END @ENDIF
@POPI WastePtr

@ForIA2B Index01 0 5
   @PUSH 0 @PUSHI Index01 @SHL @ADDI TablePtr @POPS
   @PUSH 0 @PUSHI Index01 @SHL @ADDI PullListPtr @POPS
@Next Index01
@ForIA2B Index01 0 52
   @PUSH -1 @PUSHI Index01 @SHL @ADDI WastePtr @POPS
@Next Index01

@MA2V 0 DrawCard
@CALL Shuffle
@PUSH 0
@WHILE_ZERO
   @ForIA2B Index01 0 5
      @PUSHI DrawCard @SHL @ADD Deck @PUSHS
      @INCI DrawCard
      @IF_EQ_AV 51 DrawCard
         # Draw Deck empty, reshuffle
         @CALL Shuffle
         @MA2V 0 DrawCard
      @ENDIF
      @PUSHI Index01 @SHL @ADDI TablePtr @POPS
      @PUSH 0 @PUSHI Index01 @SHL @ADDI PullListPtr @POPS
   @Next Index01
   @PUSHI TablePtr @PUSHI PullListPtr @PUSH 0 @CALL PSDisplay
   @IF_EQ_A 1
      @POPNULL
      @PUSH 1
   @ELSE
      @POPNULL
      @PUSH 0
      # Replace any Drawn cards and reshow the new hand.
      @ForIA2B Index01 0 5
          @PUSHI Index01 @SHL @ADDI PullListPtr @PUSHS
          @IF_EQ_A 0
             # Do Nothing
          @ELSE
             @PUSH 0 @PUSHI Index01 @SHL @ADDI PullListPtr @POPS  # Zero it out.
             @PUSHI DrawCard @SHL @ADD Deck @PUSHS
             @INCI DrawCard
             @IF_EQ_AV 51 DrawCard
               # Draw Deck empty, reshuffle
               @CALL Shuffle
               @MA2V 0 DrawCard
             @ENDIF
             @PUSHI Index01 @SHL @ADDI TablePtr @POPS
          @ENDIF
          @POPNULL
      @Next Index01
      :Debug01
      # Now Score the hand.
      @PUSHI TablePtr @PUSHI PullListPtr @PUSH 1 @CALL PSDisplay @POPNULL
      @PUSHI TablePtr
      @CALL PSScore
      @ADDI MainScore @POPI MainScore
      @PUSH 0
      @READC Index01
      @IF_EQ_AV "q\0" Index01
         @PUSH 1
      @ELSE
         @PUSH 0
      @ENDIF
   @ENDIF
@ENDWHILE
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
###########################################
# Function PSScore(TablePtr)
:PSScore
@PUSHRETURN
@LocalVar TablePtr 01
@LocalVar Index01 02
@LocalVar FaceCountPtr 03
@LocalVar SuitCountsPtr 04
@LocalVar ValuesPtr 05
@LocalVar SuitePtr 06
@LocalVar IsFlush 07
@LocalVar Index02 08
@LocalVar IsStraight 09
@LocalVar Pairs 10
@LocalVar Triples 11
@LocalVar Quads 12
@LocalVar Score 13
@LocalVar HighCard 14
@LocalVar IsRoyal 15
#
@POPI TablePtr
# Declair space for local arrays
@PUSHI MainHeap @PUSH 26 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 250" @END @ENDIF
@POPI FaceCountPtr
@PUSHI MainHeap @PUSH 8 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 252" @END @ENDIF
@POPI SuitCountsPtr
@PUSHI MainHeap  @PUSH 10 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 252" @END @ENDIF
@POPI ValuesPtr
@PUSHI MainHeap  @PUSH 10 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 252" @END @ENDIF
@POPI SuitePtr

# Zero Out tables

@MA2V 0 HighCard
@ForIA2B Index01 0 5
   @PUSH 0  @PUSHI Index01 @SHL @ADDI ValuesPtr @POPS
   @PUSH 0  @PUSHI Index01 @SHL @ADDI SuitePtr @POPS
@Next Index01
@ForIA2B Index01 0 13
   @PUSH 0 @PUSHI Index01 @SHL @ADDI FaceCountPtr @POPS
@Next Index01
@ForIA2B Index01 0 4
   @PUSH 0 @PUSHI Index01 @SHL @ADDI SuitCountsPtr @POPS
@Next Index01
   
@ForIA2B Index01 0 5
   # values[i] = (TablePtr[i]) & 0xf
      # Result=TablePtr[i] & 0xf
   @PUSHI Index01 @SHL @ADDI TablePtr @PUSHS @AND 0xf
      # If Result > HighCard: HighCard=Result
   @IF_GT_V HighCard
      @DUP @POPI HighCard
   @ENDIF
   #  ValuesPtr[Index01]=Result
   @PUSHI Index01 @SHL @ADDI ValuesPtr @POPS
   # suite[i] = (TablePtr[i} >> 4) & 0xf
      # Result=TablePtr[Index01]
   @PUSHI Index01 @SHL @ADDI TablePtr @PUSHS
      # Result >> 4 & 0xf
   @SHR @SHR @SHR @SHR @AND 0xf
      # suits[Index01]=Result
   @PUSHI Index01 @SHL @ADDI SuitePtr @POPS   
   # FaceCounts[values[i]]++
       # Result=ValuePtr[Index]
   @PUSHI Index01 @SHL @ADDI ValuesPtr 
       # Result=FaceCount[Result]
   @PUSHS @SHL @ADDI FaceCountPtr @DUP
       # NewResult=Result+1
   @PUSHS @ADD 1
       # FaceCount[Result]=NewResult
   @SWP @POPS
   # SuteCounts[suite[Index01]]++
       # Result=SuitePtr[Index01]
   @PUSHI Index01 @SHL @ADDI SuitCountsPtr
       # Result=SuiteCount[Result]
   @PUSHS @SHL @ADDI SuitCountsPtr @DUP
       # NewResult=Result+1
   @PUSHS @ADD 1
       # SuitCounts[Result]NewResult
   @SWP @POPS
@Next Index01
#
# Check for Flush
@MA2V 0 IsFlush
@ForIA2B Index01 0 4
   @PUSHI Index01 @SHL @ADDI SuitePtr @PUSHS
   @IF_EQ_A 5
      @MA2V 1 IsFlush
   @ENDIF
   @POPNULL
@Next Index01
#
# Check for Straight
@MA2V 0 IsStraight
@ForIA2B Index01 0 8
   @PUSH 0xff
   @ForIA2B Index02 0 5
      @PUSHI Index02 @SHL @ADDI FaceCountPtr @PUSHS
      @ANDS
   @Next Index02
   @IF_NOTZERO
      @MA2V 1 IsStraight
   @ENDIF
   @POPNULL
@Next Index01
#
# Check for Ace-Low Straight (A-2-3-4-5)
@PUSH 0xff
@PUSH 0 @ADDI FaceCountPtr @PUSHS
@ANDS
@PUSH 2 @ADDI FaceCountPtr @PUSHS
@ANDS
@PUSH 4 @ADDI FaceCountPtr @PUSHS
@ANDS
@PUSH 6 @ADDI FaceCountPtr @PUSHS
@ANDS
@PUSH 8 @ADDI FaceCountPtr @PUSHS
@ANDS      
@IF_NOTZERO
   @MA2V 1 IsStraight
@ENDIF
@POPNULL
#
# Check for Royal Flush
@MA2V 0 IsRoyal
@IF_EQ_AV 1 IsFlush
   @PUSH 0xff
   @PUSH 0 @SHL @ADDI FaceCountPtr @PUSHS
   @ANDS
   @PUSH 18 @SHL @ADDI FaceCountPtr @PUSHS   
   @ANDS
   @PUSH 20 @SHL @ADDI FaceCountPtr @PUSHS
   @ANDS
   @PUSH 22 @SHL @ADDI FaceCountPtr @PUSHS
   @ANDS
   @PUSH 24 @SHL @ADDI FaceCountPtr @PUSHS   
   @ANDS
   @IF_NOTZERO
      @MA2V 1 IsRoyal
   @ENDIF
   @POPNULL
@ENDIF
   
   
#
# Count Pairs, Triples and SQuads
@MA2V 0 Pairs
@MA2V 0 Triples
@MA2V 0 Quads
@ForIA2B Index01 0 13
   @PUSHI Index01 @SHL @ADDI FaceCountPtr @PUSHS
   @SWITCH
   @CASE 2
      @INCI Pairs
      @CBREAK
   @CASE 3
      @INCI Triples
      @CBREAK
   @CASE 4
      @INCI Quads
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
@Next Index01
#
# Score Sums
@MA2V 0 Score
@PUSHI IsFlush @ANDI IsStraight
@IF_NOTZERO
   @PUSHI Score @ADD STRAIGHT_FLUSH @POPI Score
@ENDIF
@POPNULL
@IF_EQ_AV 1 Quads  @PUSHI Score @ADD FOUR_OF_A_KIND  @POPI Score  @ENDIF
@PUSHI Triples @ANDI Pairs
@IF_NOTZERO
   @PUSHI Score @ADD FULL_HOUSE @POPI Score
@ENDIF
@POPNULL
@IF_EQ_AV 1 IsRoyal @PRT "\nRoyal Flush\n" @PUSHI Score @ADD ROYAL_FLUSH  @POPI Score @JMP BreakScore  @ENDIF
@IF_EQ_AV 1 Quads  @PRT "\nFour of a kind\n" @PUSHI Score @ADD FOUR_OF_A_KIND  @POPI Score @JMP BreakScore  @ENDIF
@IF_EQ_AV 1 IsFlush  @PRT "\nFlush\n" @PUSHI Score @ADD FLUSH  @POPI Score  @JMP BreakScore @ENDIF
@IF_EQ_AV 1 IsStraight  @PRT "\nStraight\n" @PUSHI Score @ADD FLUSH  @POPI Score @JMP BreakScore  @ENDIF
@IF_EQ_AV 1 Triples @PRT "\nThree of a kind\n" @PUSHI Score @ADD THREE_OF_A_KIND  @POPI Score @JMP BreakScore  @ENDIF
@IF_EQ_AV 2 Pairs @PRT "\nTwo Pairs\n" @PUSHI Score @ADD TWO_PAIR  @POPI Score @JMP BreakScore  @ENDIF
@IF_EQ_AV 1 Pairs @PRT "\nOne Pair\n" @PUSHI Score @ADD ONE_PAIR  @POPI Score @JMP BreakScore  @ENDIF
@MV2V HighCard Score
@PRT "High Card: " @PUSHI HighCard @SHL @ADD CardVal @POPI HighCard @PRTSTRI HighCard @PRTNL
:BreakScore
@PUSHI MainHeap @PUSHI FaceCountPtr @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error: 408" @PRTTOP @ENDIF
@POPNULL
@PUSHI MainHeap @PUSHI SuitCountsPtr @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error: 409 " @PRTTOP @ENDIF
@POPNULL
@PUSHI MainHeap @PUSHI ValuesPtr @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error: 410" @PRTTOP @ENDIF
@POPNULL
@PUSHI MainHeap @PUSHI SuitePtr @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error: 411" @PRTTOP @ENDIF
@POPNULL

@PUSHI Score
@PRT "Score: " @PRTI Score
#
#
@RestoreVar 15
@RestoreVar 14
@RestoreVar 13
@RestoreVar 12
@RestoreVar 11
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





   



###########################################
# Function PSDisplay(TablePtr, PullListPtr, Mode)
:PSDisplay
@PUSHRETURN
@LocalVar TablePtr 01
@LocalVar PullListPtr 02
@LocalVar Index01 03
@LocalVar KeyIn 04
@LocalVar Abort 05
@LocalVar Mode 06
#
@POPI Mode      # 0 = get input, !0 means just display
@POPI PullListPtr
@POPI TablePtr
#
@MA2V 0 Abort
@WHILE_EQ_AV 0 Abort
   @CALL WinClear
   @PUSH WinWidth @SHR @SUB 5 @PUSH 1 @CALL WinCursor
   @PRT "Score: " @PRTI MainScore
   @ForIA2B Index01 0 5
      @PUSHI Index01 @SHL @ADDI PullListPtr @PUSHS
      @IF_EQ_A 0
         @POPNULL
         @PUSHI Index01 @SHL @ADDI TablePtr @PUSHS
      @ELSE
         @POPNULL
         @PUSH 0x4d    # Hide Card         
      @ENDIF
      @PUSHI Index01 @PUSH 10 @CALL MULU
      @DUP
      @ADD 5
      @PUSH 10
      @CALL WinCursor
      @PUSHI Index01 @ADD 1 @PRTTOP @POPNULL
      @PUSH 11
      @CALL WinCursor
      @CALL PrintCard
   @Next Index01
   @PUSH 1 @PUSH 1 @CALL WinCursor
   @PRT "Current Score: "
   @PUSHI TablePtr @CALL PSScore @POPNULL
   @IF_EQ_AV 0 Mode
      @PUSH 10 @PUSH 23 @CALL WinCursor @PRT ">"
      @PUSH 1
      @WHILE_NOTZERO
         @POPNULL
         @READC KeyIn
         @PUSHI KeyIn @AND 0xff
         @SWITCH
         @CASE_RANGE "1\0" "5\0"
            @SUB "1\0" @SHL
            @ADDI PullListPtr
            @DUP
            @PUSHS
            @IF_ZERO
               @POPNULL
               @PUSH -1
            @ELSE
               @POPNULL
               @PUSH 0
            @ENDIF
            @SWP
            @POPS
            @PUSH 0
            @CBREAK
         @CASE "q\0"
            @POPNULL
            @PUSH 0
            @MA2V 1 Abort
            @CBREAK
         @CASE " \0"
            @POPNULL
            @PUSH 0
            @MA2V 2 Abort      
            @CBREAK
         @CDEFAULT
            @IF_NOTZERO
               @PRTTOP
               @PRT "?"
            @ENDIF
            @POPNULL
            @PUSH 1
            @CBREAK
         @ENDCASE
      @ENDWHILE
      @POPNULL
   @ELSE
      @MA2V 2 Abort      
   @ENDIF   
@ENDWHILE
@POPNULL

@PUSHI Abort
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
   









#   ################

:BackRow "\b\b\b\b\b\b\b\b\b\b\b\b\b\0"
:DownRow "\e[B\0"



:ENDOFCODE
