# Project Euler sample projects.
# See the web site for Project Euler to find ideas for simple test programs:
#
# Multiples of 3 or 5
#
#If we list all the natural numbers below 10 that are multiples of 3 or 5, we get 3, 5, 6 and 9. The sum of these multiples is 23.
#
# Find the sum of all the multiples of 3 or 5 below 1000.
I common.mc
L lmath.ld
# While the indexs are all small enough for 16b numbers the result is too large and we have to use 32b math for
# the sum

#
# My first thought was the question is asking about finding efficent ways to do 'MOD'
# But MOD functions are variations of the DIV, and even with a bit slicing efficent
# DIV function, it will take at least 16 looped steps to do every MOD test. So the
# Most efficent way of testing 1000 number for MOD 3 and MOD 5 would add at least
# 16,000 additional loops to the procedure.
# So once I realized that looking for a 'tricky' way to solving the issue, I noticed that
# the 'simplest' way is more efficent.
# So We're just going to use 3 counters, 1 for one to 1000, one for each rotation of 3, and one for rotations of 5
#
:Index1 0
:Count3 0
:Count5 0
:SumCount 0 0
:LongTemp 0
:AddFlag 0
#
# Start of Code
:main  . main
@MC2M 2 Count3   # We're going to use negative count from 2 down to 0 for each of the rotations
@MC2M 4 Count5
@MOVE32AVI $$$0 SumCount
@MOVE32AVI $$$0 LongTemp
@ForIA2B Index1 1 1000
   @INTI2LONG Index1 LongTemp
   @MC2M 1 AddFlag
   @PUSHI Count3
   @IF_ZERO
      @MC2M 3 Count3    # Rotate it back to top
      @MC2M 0 AddFlag
   @ENDIF
   @POPNULL
   @PUSHI Count5
   @IF_ZERO
      @MC2M 5 Count5    # Rotate it back to top
      @MC2M 0 AddFlag
   @ENDIF
   @POPNULL
   @PUSHI AddFlag
   @IF_ZERO   
      @PUSH LongTemp @PUSH SumCount @PUSH SumCount @CALL ADD32
   @ENDIF
   @POPNULL
   @DECI Count3
   @DECI Count5
@Next Index1
@PRT "Result of SumCount is:"
@PRT32I SumCount
@END


