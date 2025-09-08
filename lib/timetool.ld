# Timelib provides some time functions, that should work reasonsably well both
# regardless of how fast the emulator is running (other than single step)
#
! TIMELIBSeen
M TIMELIBSeen 1
I common.mc
L lmath.ld
I lmath.md
L mul.ld
L div.ld
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
@LocalVar year 01
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
@RestoreVar 01
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
@LocalVar year 01
@LovalVar month 02
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
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#####################################################################
# Function Time2Units(int32Ptr seconds):(int year, int month, int day, int hour, int minute, int second)
# Storage
# 32 bit constants
:SecondsMinute $$$60
:SecondsHour $$$3600
:SecondsDay $$$86400

:Time2Units
@PUSHRETURN
@LocalVar Year 01 @LocalVar Month 02 @LocalVar Day 03 @LocalVar Hour 04
@LocalVar Minute 05 @LocalVar Second 06 @LocalVar days 07 @LocalVar SecondsPtr 08
@LocalVar LResult 09 @LocalVar LResultHW 10 @LocalVar LRemain 11 @LocalVar LRemainHW 12
@LocalVar LRemaingSec 13 @LocalVar LRemaingSecHW 14

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
@RestoreVar 14 @RestoreVar 13 @RestoreVar 12 @RestoreVar 11 @RestoreVar 10
@RestoreVar 09 @RestoreVar 08 @RestoreVar 07 @RestoreVar 06 @RestoreVar 05
@RestoreVar 04 @RestoreVar 03 @RestoreVar 02 @RestoreVar 01
@POPRETURN
@RET
###################################################################################
# Function TimeCalabrate():int OpsPerUnit
#     Goal is to calculate NOS per 1/256th of second
# We'll need some 32 bit numbers
#
:TimeCalabrate
@PUSHRETURN
@LocalVar Index1 01 @LocalVar Sec256th 02 @LocalVar StartTime 03 @LocalVar TargetTime 04
@LocalVar LCount 05 @LocalVar HighWord 06 @LocalVar LSum 07 @LocalVar LSumHV 08
@LocalVar LRemainder 09 @LocalVar LRemainderHV 10
#
@MA2V 0 HighWord
@MA2V 0 LowWord
@MA2V 1 ClockCalib
#
# GETTIME returns two 16b words, we only care about the lower one
# BUT we have to worry about if the count is close to an overflow
# as we will be using a delta between being and end times and don't
# want the begin to be higher than the end.
@PUSH 1
@LOOP
  @POPNULL
  @GETTIME @POPNULL
  @IF_UGT_A 0xfffc     # We're < 3 seconds from roll over, loop until roll over finished.
     @POPNULL
     @PUSH 0
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
      @PUSH 0
   @ELSE
      @POPI StartTime
      @PUSH 1
   @ENDIF
@UNTIL_NOTZERO
@POPNULL
@PUSHI StartTime @ADD 2 @POPI TargetTime
@MA2V 0 LRemainder
@MA2V 0 LRemainder+2

#  Loop until time has moved forward two seconds.
@PUSH 0
@WHILE_LT_V TargetTime
   @POPNULL
   @IF_EQ_AV 0xffff LRemainder     # Lower Word of counter
      @MA2V 0 LRemainder
      @INCI LRemainder+2           # Add one to upper 32 bit count
   @ELSE
      @INCI LRemainder
   @ENDIF
   @GETTIME @POPNULL
@ENDWHILE
@POPNULL
@PUSHI LRemainder                 # Most cases this will be < 64K
@RSH
@POPI ClockCalib
#
@RestoreVar 10 @RestoreVar 09 @RestoreVar 08 @RestoreVar 07 @RestoreVar 06
@RestoreVar 05 @RestoreVar 04 @RestoreVar 03 @RestoreVar 02 @RestoreVar 01
@POPRETURN
@RET
################################################################
## The Sleep Functions are only aproximations. Not exact times.
#################################################################
# Sleep(seconds) Sleep in seconds
:Sleep
@PUSHRETURN
@LocalVar Count 01
@LocalVar Limit 02
#
@POPI Count
# Check if we need to calabrate
@IF_EQ_AV 0 ClockCalib
   @PRT "Clock not yet Calabrated....Please wait."
   @CALL TimeCalabrate
   @PRT "Cal: " @PRTHEXTOP @POPNULL   
@ENDIF
#
@GETTIME
@POPNULL   # Get rid of the high word for now
@ADDI Count
@POPI Limit     # Note if current time is > 0xffff - Count, then it will wrap around to smaller number.
#
# Do not try to single step here, logic only works if time will eventuly be exactly Limit.
# Single stepsing or debugging will make the count be too slow.
@GETTIME @POPNULL
@WHILE_NEQ_V Limit    @POPNULL   @GETTIME @POPNULL @ENDWHILE
@POPNULL
@RestoreVar 02
@RestoreVar 01
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
M SIZESINCECOMMENT timetool.ld
@SIZESINCE
ENDBLOCK
