# Timelib provides some time functions, that should work reasonsably well both
# regardless of how fast the emulator is running (other than single step)
#
! __LIB_TIMETOOL_LOADED
M __LIB_TIMETOOL_LOADED 1
M SIZESINCECOMMENT timetool.ld
I timetool.ref
L lmath.ld
I lmath.md
L mul.ld
L div.ld
:ClockCalib 0 0   # 32 bit Calibration value
G Time2Units G IsLeapYear G DaysInYear G DaysInMonth G TimeCalabrate G Sleep G SleepMilli
# --- External dependencies (not defined in this file) ---
#  DIVU

#
#
# First some string processing functions to turn 32 bit time in seconds, into data/time string.
##
#########################################################
# Function IsLeapYear(int:year) returns 1 or 0 if given year is leap year or not.
@FUNCTION IsLeapYear
:IsLeapYear
@PUSHRETURN
@Locals
@Local year
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
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
####################################################################
# Function DaysInYear(int:year) return int
@FUNCTION DaysInYear
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
@ENDFUNCTION
####################################################################
# Function DaysInMonth(int month, int year)
###### data
@FUNCTION DaysInMonth
:DataInMonthData
31 28 31 30 31 30 31 31 30 31 30 31
:DaysInMonth
@PUSHRETURN
@Locals
@Local year
@Local month
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
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#####################################################################
# Function Time2Units(int32Ptr seconds):(int year, int month, int day, int hour, int minute, int second)
# Storage
# 32 bit constants
@FUNCTION Time2Units
:SecondsMinute $$$60
:SecondsHour $$$3600
:SecondsDay $$$86400

:Time2Units
@PUSHRETURN
@Locals
@Local Year @LocalVar Month 02 @LocalVar Day 03 @LocalVar Hour 04
@Local Minute @LocalVar Second 06 @LocalVar days 07 @LocalVar SecondsPtr 08
@Local LResult @LocalVar LResultHW 10 @LocalVar LRemain 11 @LocalVar LRemainHW 12
@Local LRemaingSecs @LocalVar LRemaingSecHW 14

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
      # Day = Day - DaysInMonth (Value is at TOS)
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
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
###################################################################################
# Function TimeCalabrate():int OpsPerUnit
#     Goal is to calculate NOS per 1/256th of second
# We'll need some 32 bit numbers
#
@FUNCTION TimeCalabrate
:TimeCalabrate
@PUSHRETURN
@Locals
@Local StartTime
@Local CurTime
@Local Index01

@MA2V 0 ClockCalib       # Zero out 32 bit clock calibration
@MA2V 0 ClockCalib+2

# FIrst make sure we are at a 'safe' starting point for time timese. (not too close to a roll over)
@LOOP
   @GETTIME
   @POPNULL    # discard high word.
   @IF_UGE_A 0xfffc
      @POPNULL
      @PUSH 0
   @ELSE
      @POPI CurTime
      @PUSH 1  # Break Loop
   @ENDIF
@UNTIL_NOTZERO
@POPNULL
@MV2V CurTime StartTime
#@PRT "Now: "
#@PRTI CurTime
#@PRT ":"

# Now poll until StartTime != GETTIME to make sure we're at start of a given second
@LOOP
   @GETTIME      # 2 Words on stack
   @POPNULL      # 1 Word on Stack
#   @PRTTOP  @PRT " .. "
   @IF_EQ_V StartTime
      @POPNULL   # 0 words on stack
      @PUSH 1    # 1 word on stack
   @ELSE
      @POPNULL   # 0 words on stack
      @PUSH 0    # 1 word on stack
   @ENDIF
@UNTIL_NOTZERO   # Still 1 word on stack
@POPNULL         # 0 words on stack
#
# Now count how long it takes to get to the next second flip
@INC2I CurTime  # Count until 2 seconds pass.
#@PRT "Looking for: " @PRTI CurTime @PRTNL
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   @GETTIME
   @POPNULL
   @IF_NEQ_V CurTime
      @POPNULL   
      @INCI ClockCalib
      @IF_EQ_AV 0 ClockCalib
         # Rolled over so inc high word
         @INCI ClockCalib+2
      @ENDIF
      @PUSH 1
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@POPNULL
# Now ClockCalib is 32 bit work with total count for 2 seconds, SHR to make it sutable for 1 second.
@CLC    # Clear Carry
# We want our ClockCalib about equal to 1 millsec so div by 1024

@ForIA2B Index01 0 10
  @PUSHI  ClockCalib+2        # High Word
  @RRTC  @POPI  ClockCalib+2
  @PUSHI ClockCalib
  @SHR @POPI ClockCalib     # Low Word
@Next Index01
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

################################################################
## The Sleep Functions are only aproximations. Not exact times.
#################################################################
# Sleep(seconds) Sleep in seconds
@FUNCTION Sleep
:Sleep
@PUSHRETURN
@Locals
@Local Count
@Local Limit
#

@POPI Count
# Check if we need to calabrate
@IF_EQ_AV 0 ClockCalib
#   @PRT "Clock not yet Calabrated....Please wait."
   @CALL TimeCalabrate
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
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
##################################################################
# SleepMilli(MilliSeconds) Sleep for number of millisecond
@FUNCTION SleepMilli
:SleepMilli
@PUSHRETURN
@Locals
@Local Index1
@Local Index2
@Local Index3
@Local Count
#
@POPI Count
@IF_EQ_AV 0 ClockCalib
#   @PRT "Clock not yet Calabrated....Please wait."
   @CALL TimeCalabrate
@ENDIF
@POPNULL
#
@ForIA2V Index1 0 Count
   @ForIA2V Index2 -1 ClockCalib+2   # if Highword is 0, still loop once.
     @ForIA2V Index3 0 ClockCalib       # Lowword does most of the work.
       # Do Nothing
     @Next Index3
   @Next Index2
@Next Index1
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
@SIZESINCE
ENDBLOCK
