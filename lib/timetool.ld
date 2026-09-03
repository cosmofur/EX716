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
@Call(VA) DIVU year 4
@POPNULL # We only want the MOD value
@IF_ZERO       # If Mod(year,4)=0
   @POPNULL
   @Call(VA) DIVU year 100
   @POPNULL
   @IF_ZERO
      @POPNULL
      @Call(VA) DIVU year 400
      @POPNULL
      @IF_ZERO
         @POPNULL
         @PUSH 1         # 00 years are only leap if diviable by 400
      @ELSE
         @POPNULL
         @PUSH 0
      @ENDIF
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
  @POPNULL
  @Call(V) IsLeapYear year
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
:SecondsHour   $$$3600
:SecondsDay    $$$86400

:Time2Units
@PUSHRETURN
@Locals

@Local Year
@Local Month
@Local Day
@Local Hour
@Local Minute
@Local Second

@Local SecondsPtr
@Local DaysInPeriod
@Local DaysInEpoch16

@Local32 LDaysSinceEpoch
@Local32 LRemainingSecs
@Local32 LResult

   #
   # Input is pointer to a 32-bit epoch-seconds value.
   #
   @POPI SecondsPtr

   #

   ############################################################
   # Split seconds into complete days and time within the day.
   ############################################################

   @Call32(PV) DIV32U SecondsPtr SecondsDay
   @POP32I(VV) LDaysSinceEpoch LRemainingSecs
   @M32VTO16V LDaysSinceEpoch DaysInEpoch16   # Safe to use 16 bit math

   #
   # Hours
   #
   @Call32(VV) DIV32U LRemainingSecs SecondsHour
   @POP32I(VV) LResult LRemainingSecs
   @M32VTO16V LResult Hour

   #
   # Minutes
   #
   @Call32(VV) DIV32U LRemainingSecs SecondsMinute
   @POP32I(VV) LResult LRemainingSecs
   @M32VTO16V LResult Minute

   #
   # Seconds
   #
   @M32VTO16V LRemainingSecs Second

   ############################################################
   # Determine year.
   #
   # DaysInEpoch16 remains zero-based.
   ############################################################

   @MA2V 1970 Year

   @Call(V) DaysInYear Year

   @WHILE_LT_V DaysInEpoch16
      @PUSHI DaysInEpoch16
      @SWP
      @SUBS
      @POPI DaysInEpoch16
      @INCI Year
      @Call(V) DaysInYear Year
   @ENDWHILE
   @POPNULL
   ############################################################
   # Determine month.
   #
   # DaysInEpoch16 is now the zero-based day within Year.
   ############################################################

   @MA2V 1 Month

   @Call(VV) DaysInMonth Month Year
   @WHILE_LT_V DaysInEpoch16
      @PUSHI DaysInEpoch16
      @SWP
      @SUBS
      @POPI DaysInEpoch16
      @INCI Month
      @Call(VV) DaysInMonth Month Year
   @ENDWHILE
   @POPNULL
   #
   # Remaining value is zero-based day within month.
   #
   @MV2V DaysInEpoch16 Day
   @INCI Day

   ############################################################
   # Return six 16-bit values.
   ############################################################

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
# Function TimeCalabrate():void()
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
@Local32 Junk1

@MA2V 0 ClockCalib       # Zero out 32 bit clock calibration
@MA2V 0 ClockCalib+2

# FIrst make sure we are at a 'safe' starting point for time times. (not too close to a roll over)
@LOOP
   @GETTIME
   @POPNULL    # discard high word.
   @IF_UGE_A 0xfffa
      @POPNULL
      @PUSH 0
   @ELSE
      @POPI CurTime
      @PUSH 1  # Break Loop
   @ENDIF
@UNTIL_NOTZERO
@POPNULL
@MV2V CurTime StartTime

# Now poll until StartTime != GETTIME to make sure we're at start of a given second
@LOOP
   @GETTIME      # 2 Words on stack
   @POPNULL      # 1 Word on Stack
   @IF_EQ_V StartTime
      @POPNULL   # 0 words on stack
      @PUSH 1    # 1 word on stack
   @ELSE
      @POPI CurTime
      @PUSH 0    # 1 word on stack
   @ENDIF
@UNTIL_NOTZERO   # Still 1 word on stack
@POPNULL         # 0 words on stack
#
# Now count how long it takes to get to the next 4 second flip
@PUSHI CurTime @ADD 4 @POPI CurTime

@MA2V 256 Junk1
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   @ForIA2V Index01 0 Junk1
   @Next Index01

   @PUSHI ClockCalib
   @ADD 0x100
   @POPI ClockCalib
   @IF_EQ_AV 0 ClockCalib
       # Rolled over so inc high word
       @INCI ClockCalib+2
   @ENDIF
   @GETTIME
   @POPNULL
   @IF_NEQ_V CurTime
      @POPNULL
      @PUSH 1
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@POPNULL
@Call32(VA) DIV32U ClockCalib $$$4000
@POP32I(V) ClockCalib
@POPNULL @POPNULL
@PRT "Time Calibration: " @PRT32I ClockCalib @PRTNL
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
@Local Count
@Local Index1
@Local Index2
@Local32 DelayCount
@Local32 ModifiedCal
#
@POPI Count
@IF_EQ_AV 0 ClockCalib
   @CALL TimeCalabrate
@ENDIF

@MV2V ClockCalib ModifiedCal
@MV2V ClockCalib+2 ModifiedCal+2
#
@MV2V ModifiedCal DelayCount
@MV2V ModifiedCal+2 DelayCount+2

@PUSHI ModifiedCal+2
@IF_NOTZERO
  # Very fast computer, does > 65000 instructions a millisecond
  @MA2V 0xffff ModifiedCal
  @MA2V 0 ModifiedCal+2
@ENDIF
@POPNULL

@ForIA2V Index1 0 Count
   @ForIA2V Index2 0 ModifiedCal   # Treat as 16 bit number, ignore upper word
   @Next Index2
@Next Index1
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
@SIZESINCE
ENDBLOCK
