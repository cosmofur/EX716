# Project Euler sample projects.
# Largest palindrome product
# Submit

#
# Problem 4
# A palindromic number reads the same both ways. The largest palindrome made from the product of two 2-digit numbers is 9009 = 91 × 99.
# 
# Find the largest palindrome made from the product of two 3-digit numbers.

I common.mc
L lmath.ld
L string.ld
#
#
# Our range numbers are between 100 and 999
# The most 'CPU' intense part is the 32b int to string which then needs to be scanned from both sides
# to test if its a palindrome.
#
# Some speed ups... we'll keep track of a 'max' found palindrome and skip the string conversion for anything
# less than that. We'll also do our loop backwares from 999 to 100 since that will more likely find the MaxV
# value earlier in the sequence.

# Storage
:MaxV $$$0
:Irange 0
:Jrange 0
:Krange 0
:Shead 0
:Stail 0
:CharVal1 0
:CharVal2 0
:Value $$$0
:Aval $$$000
:Bval $$$000
:String "       "  # 999x999 = 6 digts so string should never be > 7 characters.
:TestFlag 0
:StringSize 0
:StringHalfSize 0
:Base 0

:main . main
@MOVE32AV $0 MaxV      # MaxV=0
@MC2M 10 Base          # String output is base 10
@ForIA2B Irange 99 10
   @INTI2LONG Irange Aval
   @ForIA2B Jrange 99 10
       @INTI2LONG Jrange Bval
       # We're doing 32bit math again, so have to use the librarys
       @PUSH Aval @PUSH Bval @PUSH Value
       @CALL MUL32           # value = i*j
#       @PRT "For I,J:(" @PRT32I Aval @PRT "," @PRT32I Bval @PRT ") = " @PRTI Value @PRT " Mval:" @PRTI MaxV @PRT " CMP: "       
       @PUSH Value
       @PUSH MaxV
       @CALL CMP32         # +1 if Max>Value so Skip to next
       @CMP 1
#       @PRTTOP @PRTNL
       @POPNULL
       @JMPZ DontBother
	   @PUSH Value @PUSH 10 @PUSH String  # Convert to String
	   @CALL i32tos
#	   @PRT "String: " @PRTS String
	   @PUSH String
	   @CALL strlen
	   @DUP
	   @POPI StringSize        # We'll need the size
	   @RTR
	   @POPI StringHalfSize    # Also caluculate 1/2 string size while we're here.
	   @MC2M 0 Krange          # We will be lookng at the head and tail of the
	   @MC2M 0 Shead           # String at the same time, to look for equivalent values
	   @MM2M StringSize Stail
	   @DECI Stail
	   @PUSHI StringHalfSize
	   @MC2M 0 TestFlag        # Set to 1 if its not a pd
	   @WHILE_NOTZERO          # While loop as countdown from StringHalfSize
#	        @PRT "Index: " @PRTI Shead @PRT " To " @PRTI Stail @PRTNL
	        @POPNULL
	   	@PUSH String       # Get the Head Character of string
                @ADDI Shead
		@PUSHS
		@AND 0xff          # We only care about the 8bit character.
		@POPI CharVal1
		@PUSH String       # Same for the tail
		@ADDI Stail
		@PUSHS
		@AND 0xff
		@POPI CharVal2
	        @INCI Shead
		@DECI Stail
		@DECI StringHalfSize
#		@PRT "CH: " @PRTI CharVal1 @PRT " - CH:" @PRTI CharVal2 @PRTNL
		@PUSHI CharVal1    # Now compare CharVal1 to CharVal2 
		@CMPI CharVal2
		@POPNULL
		@JMPZ StillGood    # If they are the same, continue testing.
		    @MC2M 1 TestFlag
		    @BREAK         # Break out of While Loop
		:StillGood
		@PUSHI StringHalfSize
            @ENDWHILE
#	    @PRT "AfterWhile: " @StackDump
	    @PUSHI TestFlag
	    @IF_ZERO
	       # We have a PD and We only get here if MaxV was already smaller than Value.
	       @COPY32VV Value MaxV
	    @ELSE
	       @POPNULL
	    @ENDIF
       :DontBother  # For Skipping past string part when it clear it not max pd
#       @StackDump
    @NextBy Jrange -1
@NextBy Irange -1
@PRT "Result: " @PRT32I MaxV
@END

