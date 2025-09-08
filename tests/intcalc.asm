I common.mc
L lmath.ld
L screen.ld


:AVal 0 0
:BVal 0 0
:MVal 0 0
:DisplayLine "0\0               "  # 16 bytes, zero at start
:CharIn 0 0                        # 4 bytes to allow special characters
:CharPtr CharIn
:FixedZero "0\0"                   # Used when Display needs to be started new.
:QuitFlag 0



#Function DisRefresh
# Refresh the display.
:DisRefresh
#@CALL WinClear
#@PUSH 1 @PUSH 1 @CALL WinCursor
@PRTLN " +----------------+"
@PRTLN " | ############## |"
@PRTLN " +----------------+"
@PRTLN " | M | R | C | cE |"
@PRTLN " +----------------+"
@PRTLN " | 7 | 8 | 9 | -  |"
@PRTLN " +----------------+"
@PRTLN " | 4 | 5 | 6 | +  |"
@PRTLN " +----------------+"
@PRTLN " | 1 | 2 | 3 | *  |"
@PRTLN " +----------------+"
@PRTLN " |   | 0 |   | /  |"
@PRTLN " +----------------+"
@CALL DisplayUpdate
@RET



# Function DisplayInput
:DisplayUpdate
#@CALL WinHideCursor
#@PUSH 3
#@PUSH 11
#@PUSH DisplayLine
#@CALL strlen
#@SUBS
#@CALL WinCursor
@PRT "--->: "
@PRTS DisplayLine
@PRTNL
#@CALL WinShowCursor
@RET

# Function initcalc
:initcalc
@CALL WinResize
@CALL WinClear
@MOVE32AV $$$0 AVal
@MOVE32AV $$$0 BVal
@MOVE32AV $$$0 MVal
@MA2V 0 QuitFlag
@MA2V "0\0" DisplayLine # Set Display Line to 0
@TTYNOECHO
@MA2V 0 CharIn
@CALL DisRefresh
@RET



# Function KeyRead
:KeyRead
@MA2V 0 QuitFlag
@PUSHI QuitFlag
@WHILE_ZERO
   @POPNULL
   @PRT "\nT:" @StackDump
   @MA2V 0 CharIn
   @MA2V 0 CharIn+2
   @READC CharIn
   @PUSHI CharIn
   @SWITCH
      @CASE_RANGE "0\0" "9\0"
          @PUSH DisplayLine
          @CALL strlen
          @IF_LT_A 9
              @POPNULL
              @PUSH DisplayLine
              @PUSH FixedZero
              @CALL strcmp
              @IF_NOTZERO
                 @POPNULL
                 @PRT "Before: " @PRTS DisplayLine @PRTNL
                 @PUSH DisplayLine
                 @PUSH CharIn
                 @PUSH 10
                 @PRT "\nncat : " @StackDump
                 @CALL strncat
                 @POPNULL
                 @PRT "\n!0: " @StackDump
                 @PRT "After: " @PRTS DisplayLine @PRTNL
              @ELSE
                 @POPNULL
                 @PRT "Before: " @PRTS DisplayLine @PRTNL
                 @PUSH DisplayLine
                 @PUSH CharIn
                 @CALL strcpy
                 @PRT "\n=0: " @StackDump
                 @PRT "After: " @PRTS DisplayLine @PRTNL
              @ENDIF
              @CALL DisRefresh
          @ELSE
             @PRT "\nOverFlow\n"
             @POPNULL
          @ENDIF
          @CBREAK
       @CASE "E\0"
          @PUSH DisplayLine
          @PUSH FixedZero
          @CALL strcpy
          @CALL DisRefresh
          @PRT "\nE-CMD: " @StackDump
          @CBREAK
       @CASE "q\0"
          @MA2V 1 QuitFlag
          @PRT "\nQ-CMD: " @StackDump
          @CBREAK
       @CASE "+\0"
       :Break1
          @PUSH DisplayLine
          @PUSH BVal
          @CALL stoi32
          @ADD32VVV AVal BVal AVal
          @PUSH DisplayLine
          @PUSH AVal
          @CALL i32tos
          @CALL DisRefresh
          @PRT "\nADD-CMD: " @StackDump
          @CBREAK
       @CASE "-\0"
          @PUSH DisplayLine
          @PUSH BVal
          @CALL stoi32
          @SUB32VVV AVal BVal AVal
          @PUSH DisplayLine
          @PUSH AVal
          @CALL i32tos
          @CALL DisRefresh
          @PRT "\nSUB-CMD: " @StackDump
          @CBREAK
       @CDEFAULT
          @PRT "Invalid Code: " @PRTI CharIn @PRTNL
          @CBREAK
   @ENDCASE
   @POPNULL
   @PUSHI QuitFlag
   @PRT "\nB: " @StackDump
@ENDWHILE
@TTYECHO
@POPNULL
@RET


:Main . Main
@CALL initcalc
@CALL DisRefresh
@CALL KeyRead
@END
