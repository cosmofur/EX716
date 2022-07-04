# More Jumps
I common.mc
#
# Before we created a simple loop
# Now we'll do some more 'complex' jmps and conditionals
#
# First lets start with some values
# SmallVal = 15 which fits in the 'lower byte' of a 16 bit number
# Medval = 321  which takes up two bytes, but is 'small' in scale to the larger byte
# Large = 45321 which takes up a larger part of both lower and upper bytes.
#
@PUSH 15
@POPI SmallVal
@PUSH 321
@POPI Medval
@PUSH 45321
@POPI Large
#
# We are going to do a series of CMPs and JMP's based on these values
#
# Test if one number is larger than another.
# For convience when its easy to think of the first number on the stack as being 'A'
# and the second number we compair it to, as bing 'B'
# 
# CMPI can be read, set flags as if you Subtraced A from B
#  321 - 15 = 306  so we would not expect any flags to be set.
#
@PUSHI SmallVal
@CMPI Medval
@POPNULL                  # Do this after any CMP, unless you expect to CMP with the same A value again.
@JMPZ T1NotExpected       # 321 does not equal 15, so we would not expect the Z flag to be set
@JMPN T1NotExpected       # 321 - 15 is not negative to the Negative flag should not be set
@JMPO T1NotExpected       # 321 - 15 does not require any sort of 'borrow' so no overflow should happen.
@JMP  T1AltB              # So we know that A is less than B.
:T1NotExpected
@PRTLN "Do not expect to see this. 01"
@JMP TestT2
:T1AltB
@PRTI SmallVal
@PRT " is less than "
@PRTI Medval
@PRTNL
:TestT2
@PUSHI Medval
@CMPI SmallVal
# This time is going to be 15 - 321 which is a negative -306
@POPNULL
@JMPZ T2NotExpected       # 321 does not equal 15, so we would not expect the Z flag to be set
@JMPN T2AgtB              # 15 - 321  IS Negative, so we expect to do this JMP
@JMPO T2NotExpected       # 321 - 15 does not require any sort of 'borrow' so no overflow should happen.
:T2NotExpected
@PRTLN "Do not expect to see this. 02"
@JMP TestT3
:T2AgtB
@PRTI Medval
@PRT " is larger than "
@PRTI SmallVal
@PRTNL
:TestT3
# Now we will test for equality
@PUSHI Medval
@CMPI Medval
@POPNULL
@JMPZ T3AeqB
@JMPN T3NotExpected
@JMPO T3NotExpected
:T3NotExpected
@PRTLN "Do not expect to see this. 03"
@JMP TestT4
:T3AeqB
@PRTI Medval
@PRT " is equal to "
@PRTI Medval
@PRTNL
:TestT4
# This time we'll be looking for an OverFlow
# which is something that happens when we add numbers too big to fit into 16 bits.
@PUSHI Large
@ADDI Large
# To trigger the Overflow we are doing an ADD rather than a CMP
# We added 45321 + 45321 which is normally 90642 but that larger than 16 bite can hold
# This will trigger the Overflow flag.
#
# Because the result may be interesting. Lets print it before we POPNULL it.
@PRT "Result of Large Add is:"
@PRTTOP
@PRTNL
@POPNULL
@JMPZ T4NotExpected
@JMPN T4NotExpected
@JMPO T4TooLarge
:T4NotExpected
@PRTLN "Do not expect to see this. 04"
@JMP TestT5
:T4TooLarge
@PRTI Large
@PRT " when added to "
@PRTI Large
@PRT " results in an overflow."
@PRTNL
:TestT5
# Another type of overflow can happen when we subtract, also known as a Borrow.
# What is happening here, is we subtracted two numbers so large that we needed to
# borrow an extra digit from a virtual 16 number to the 'left' of the actual numbers.
#
@PUSHI Large
@ADD 100       # we are adding 100 to the 'A' verison of large to they are not equal.
@SUBI Large
# Again it might be intersting to see the result, so print it before POPNULL
@PRT "Result of Large Subtract is:"
@PRTTOP
@PRTNL
@POPNULL
@JMPZ T5NotExpected
@JMPO T5Borrow
@JMPN T5NotExpected
:T5NotExpected
@PRTLN "Do not expect to see this. 05"
@JMP LastLine
:T5Borrow
@PRTI Large
@PRT " +100, when subtracted from "
@PRTI Large
@PRT " Caused a Borrow"
@PRTNL
:LastLine
@PRTLN "End of tests."
@END
:SmallVal 0
:Medval 0
:Large 0
#
# Because 'Borrow' is not as obvious thing as OverFlow, lets talk about it.
# In our example we subtracted 45421 from 45321 and got a 16b value of 20989
# What we normall would expect would be a -100
# Lets write these out in binary
# 45321 = Binary 1011 0001 0000 1001
# 45421 = Binary 1011 0001 0110 1101
# -----------------------------------------Old School Long Subtraction.
#                1111 1111 1001 1100 == 65436 which in 2's Comp math is -100
#
# To explain why -100 == 65436 would require a full explanation of how 2's comp math works.
# We will get to that later, but the quick thing to note is the highest bit (on the left) is
# set to 1, which can be considered the 'sign bit'
# If you zero that bit the remaining 15 bits would be equal to 32668.
# The highest number 15 bits can host is 32767.Subtract 32767 and 32668 and we get 101 which
# gives you a good hint on how negative -100 is stored.
#

