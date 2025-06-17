# Timelib provides some time functions, that should work reasonsably well both
# regardless of how fast the emulator is running (other than single step)
#
! TIMELIBSeen
M TIMELIBSeen 1
I common.mc
L lmath.ld
L mul.ld
L div.ld
:LVar01 0 0
:LVar02 0 0
:LVar03 0 0
:ClockCalib 0
G Time2Units G IsLeapYear G DaysInYear G DaysInMonth G TimeCalabrate G Sleep G SleepMilli
#
#
# First some string processing functions to turn 32 bit time in seconds, into data/time string.
##
#########################################################
# Function IsLeapYear(int:year) returns 1 or 0 if given year is leap year or not.
:IsLeapYear
@PUSHRETURN
=year Var01
@PUSHLOCALI Var01
@POPI year
#
@PUSHI year
@PUSH 4
@CALL DIVU
@POPNULL # We only want the MOD value
@IF_ZERO       # If Mod(year,4)=0
   @POPNULL
   @PUSHI year
   @PUSH 100        # Will be leap year, UNless it also a 00 year.
   @CALL DIVU
   @POPNULL
   @IF_ZERO
      @POPNULL
      @PUSH 100
      @PUSH 400
      @IF_ZERO
         @PUSH 1         # 00 years are only leap if diviable by 400
      @ELSE
         @PUSH 0
      @ENDIF
      @SWP               # Move the test result behind the mod value      
      @POPNULL
   @ELSE
      @POPNULL
      @PUSH 1       # All other that are mod(4)=0 are leap years.
   @ENDIF
@ELSE
   @POPNULL
   @PUSH 0          # Not mod(4)=0 so not a leap year.
@ENDIF
@POPLOCAL year
@POPRETURN
@RET
####################################################################
# Function DaysInYear(int:year) return int
:DaysInYear
@PUSHRETURN
@CALL IsLeapYear
@IF_ZERO
   @POPNULL
   @PUSH 365
@ELSE
   @POPNULL
   @PUSH 366
@ENDIF
@POPRETURN
@RET
####################################################################
# Function DaysInMonth(int month, int year)
###### data
:DataInMonthData
31 28 31 30 31 30 31 31 30 31 30 31
:DaysInMonth
@PUSHRETURN
=year Var01
=month Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI year
@POPI month
#
@PUSHI month
@IF_GT_A 12
   @PRT "Invalid Month (" @PRTI month @PRT ")\n"
   @POPNULL
   @PUSH -1
@ELSE
  @PUSH year
  @CALL IsLeapYear
  @IF_ZERO
     @POPNULL
     @PUSHI month @SHL
     @ADD DataInMonthData
     @PUSHS
  @ELSE
     @POPNULL
     @PUSHI month @SHL
     @ADD DataInMonthData
     @PUSHS
     @PUSHI month
     @IF_EQ_A 1   # 0=jan,1=feb...
        @POPNULL
        @ADD 1    # Leap year, add one to Feb
     @ENDIF
  @ENDIF
@ENDIF
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#####################################################################
# Function Time2Units(int32 seconds):(int year, int month, int day, int hour, int minute, int second)
# Storage
# 32 bit constants
:SecondsMinute $$$60
:SecondsHour $$$3600
:SecondsDay $$$86400

:Time2Units
=Year Var01
=Month Var02
=Day Var03
=Hour Var04
=Minute Var05
=Second Var06
=days Var07
=SecondsPtr Var08
=LResult LVar01
=LRemain LVar02
=LRemaingSecs LVar03
@PUSHRETURN
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
#
# Top will be address where 32b seconds is stored.
@POPI SecondsPtr
#
# days=seconds/SecondsDay
# Remaing Seconds= Seconds % SecondsDay
@DIVU32IVVV SecondsPtr SecondsDay LResult LRemaingSecs
@LONG2INTVV LResult Day
#
# hours = LRemainingSecs / SecondsHour, then update remaining Secs
@DIVU32VVVV LRemaingSecs SecondsHour LResult LRemaingSecs
@LONG2INTVV LResult Hour
#
# minute=LRemaingSecs / SecondsMinute then update remaining Secs
@DIVU32VVVV LRemaingSecs SecondsMinute LResult LRemaingSecs
@LONG2INTVV LResult Minute
#
# second=LRemaingSecs
@LONG2INTVV LRemaingSecs Second
#
# Now calculate Year
@MA2V 1970 Year
@PUSH 1
@WHEN
   @POPNULL
   @PUSHI Year
   @CALL DaysInYear
   @IF_ULE_V Day
      # Day = Day - DaysInYear(Year) value is at TOS
      @PUSHI Day
      @SWP
      @SUBS
      @POPI Day
      @INCI Year
      @PUSH 1
    @ELSE
      @POPNULL
      @PUSH 0 # Break Year Loop
    @ENDIF
    @DO_NOTZERO
@ENDWHEN
# At end of this loop Day should be just the remaining days in current year
#
@MA2V 1 Month
@WHEN
   @PUSHI Month
   @PUSHI Year
   @CALL DaysInMonth
   @IF_ULT_V Day
      # Day = Day - DaysInMonth (value is at TOS)
      @PUSHI Day
      @SWP
      @SUBS
      @POPI Day
      @INCI Month
      @PUSH 1
    @ELSE
      @POPNULL
      @PUSH 0   # Break Month Loop
    @ENDIF
    @DO_NOTZERO
@ENDWHEN
@DECI Day
@PUSHI Year
@PUSHI Month
@PUSHI Day
@PUSHI Hour
@PUSHI Minute
@PUSHI Second
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###################################################################################
# Function TimeCalabrate():int OpsPerUnit
#     Goal is to calculate NOS per 1/256th of second
# We'll need some 32 bit numbers
:LCount
:LowWord 0
:HighWord 0
:LSum 0 0
:LRemainder 0 0
#
:TimeCalabrate
@PUSHRETURN
=Index1 Var01
=Sec256th Var02
=StartTime Var03
=TargetTime Var04
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@MA2V 0 HighWord
@MA2V 0 LowWord
#
# GETTIME returns two 16b words, we only care about the lower one
# BUT we have to worry about if the count is close to an overflow
# as we will be using a delta between being and end times and don't
# want the begin to be higher than the end.
@PUSH 1
@LOOP
  @POPNULL
  @GETTIME  
  @POPNULL
  @IF_UGT_A 0xfff7     # We're < 8 seconds from roll over, loop until roll over finished.     
     @POPNULL
     @POPNULL         # Need to get rid of the Poll Cmd as well
     @PUSH 0
  @ELSE
     @SWP
     @POPNULL         # Result is above Poll cmd
  @ENDIF
@UNTIL_NOTZERO
@POPI StartTime
#
# Now find the bottom 'edge' of the second counter
# We do this by repeativly getting the time, until value is not same as first query.
#
@PUSH 1
@LOOP
   @POPNULL
   @GETTIME @POPNULL
   @IF_EQ_V StartTime
      @POPNULL
      @POPNULL
      @PUSH 0
   @ELSE
      @POPI StartTime
      @POPNULL
      @PUSH 1
   @ENDIF
@UNTIL_NOTZERO
@POPNULL
@PUSHI StartTime @ADD 1 @POPI TargetTime
# Now we count, as this might be a large number, we use 32 bit math
# BUT we don't want the overhead of the Libary, so we'll do it the old way.
#
# Also to avoid hidden instructions and time waste, we'll use the 'old' way
# of looping, not using the Structured macros as they might change timeing.
# Note I'm also avoiding Macro defined opcodes that are more than just code optcodes. 
#
@GETTIME @POPI LRemainder+2
@POPI LRemainder
:CountLoop                              # cycles
   @ForIA2B Index1 0 1000
      @NOP
   @Next Index1
   @GETTIME @POPNULL                    # 3 +  1
   @SWP @POPNULL                        # 2
   @CMPI TargetTime                     # 3
   @POPNULL
   @JMPZ EndCountLoop                   # 3
   #
   @PUSHI LowWord                       # 3
   @ADD 1                               # 3
   @POPI LowWord                        # 3
   @JMPC CarryTooHigh                   # 3
   @JMP CountLoop
:CarryTooHigh
   @PUSHI HighWord                      # 1 in (0xffff - sub(above time) 3
   @ADD 1                               # 3
   @POPI HighWord                       # 3
   @JMP CountLoop                       # 3
:EndCountLoop
@POPNULL
#                          Total Cycles = Count*22+(Count/22)*12)
# LCount is same as combined Low and HighWords
@GETTIME @POPI LRemainder+2
@POPI LRemainder
#
# This should be a 16b number for all but GHZ computers.
@LONG2INTVV LCount ClockCalib
#
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
################################################################
## The Sleep Functions are only aproximations. Not exact times.
#################################################################
# Sleep(seconds) Sleep in seconds
:Sleep
@PUSHRETURN
=Index1 Var01
=Count Var02
=Index2 Var03
=Limit Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
#
@POPI Count
# Check if we need to calabrate
@IF_EQ_AV 0 ClockCalib
   @PRT "Clock not yet Calabrated....Please wait."
   @CALL TimeCalabrate
   @POPNULL
@ENDIF
#
@ForIA2V Index1 0 Count
   @ForIA2V Index2 0 ClockCalib
      @ForIA2B Limit 0 1000
        @NOP
      @Next Limit
   @Next Index2
@Next Index1
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
##################################################################
# SleepMilli(MilliSeconds) Sleep for number of millisecond
:SleepMilli
@PUSHRETURN
=Index1 Var01
=Count Var02
=Index2 Var03
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
#
@POPI Count
@IF_EQ_AV 0 ClockCalib
   @PRT "Clock not yet Calabrated....Please wait."
   @CALL TimeCalabrate
   @POPNULL
@ENDIF
#
@ForIA2V Index1 0 Count
   @ForIA2V Index2 0 ClockCalib
   @Next Index2
@Next Index1
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET





