I common.mc
# Now that we got 'Hello World' out of the way, lets look deeper in HOW the macro assembler works
# We'll do this with examples that do NOT result in running programs, but shows how we can 'put numbers'
# into the emulators memory and build up more complex commands from simple ones.
#
# To see how the output of these examples work, run the assembler with the -l and -c options
#    CPA.py l002.asm -l -c
# This will create a dump file named 'l002.a.o' that will be a hex dump of the CPU's memory
# Looking at this output file will show how numbers are stored in memory.
#
#
# Macro Language basic examples
# This in not a 'program' it does't run, but it loads some numbers into memory.
=Aval 1          # These two lines do not modify memory, but create 'labels' that have values
=Bval 2          # Namely Aval=1 and Bval=2
# This will put the 16 bit number 1 at address 0-1 and 2 at 2-3
. 0x0           # This 'dot' command sets the current 'origin' of the memory to be modified to 0
Aval            # By just putting Aval by itself, it will save at address 0 the value 1, and 0 at address 1
Bval            # Likewise, this will but 2 at address 2 and 0 at address 3
#               Numbers like this each take up 2 bytes or two address
#               A basic concept here is number like one is really a 16bit number which is two bytes long
#               The 'lower numbered' byte holds the lower valued part of the, and the higher part is in the
#               higher byte.
#               In english we read our numbers from 'Right to Left' while all other text
#               is read 'Left to Right' You may not even be aware of this, because we train our minds to
#               do the mental math of figuring out which digit in a number is 'highest' and what value it
#               has before trying to say it's name out loud.
#               Example:
#                       In English you see 5203 and say Five Thousand Two Hundred Three
#                       But HOW did you know the 5 was in the Thousands place? You had to silently
#                       (and probably not even aware of doing it) count the digits first, starting
#                       from the 3 then 0 then 2 then 5 to 'know' it was in the thousands place.
#                       Computers skip this extra step and just start counting from the 3 in the first place.
#                       For this reason, when reading though memory, a computer finds it much more efficient
#                       to read numbers 'lowest value byte first'
#                       Don't believe me, without counting the number of digits, try to read out-loud the following
#                       English number.   75413201325021
#                       Is that first 7 in the hundred million or billionth position? The hundred trillionth?
#                       Did you have to count (or put in commas) to figure it out?
#                       The 'computers' way to reading would be to start at 1 on the right, and keep summing it
#                       the next digit after multiplying it by 10 * it's position. By the time it got to the 7
#                       it would know the exact value of the number, without having to ever count or look ahead.
#
#                       A fancy term for this way of storing numbers is 'Little-endian' which just means the
#                       'little' part of a number is stored first. There are some computers that are 'Big-endian'
#                       but they are less common these days than in the past.
#
#
# Now we got the idea that 16bit words store their 'lower half' on the lower memory address. We can move on:
#
# Lets move from simple labels and number to our first Macro
#
# Define a macro to something similure
M PutAB Aval Bval
# At this 'point' no additional data has been stored in memory and wont be until we 'invoke' the macro
#
# Which we will now do.
@PutAB @PutAB
# At this point there should be 6 16  bit words in memory cells 0-12(0x0c)
#
# Macro's can be built using other macros.
M Double @PutAB 3 @PutAB
#
# Invoke it
@Double
#
# Now memory 13(0x0d)-23(0x17) should have 5 16 bit numbers 1 2 3 1 2
#
# Now building macros as just a way to save typeing is clearly useful.
# But what is MORE useful?
#   Macros that both save typing AND can handle multiple different uses.
#
# The way we get to that is allowing macros to have parameters.
# Now lets talk about macro parameters
# Parameters are sort of like labels or variables, but they specialized to each macro.
# They are named, but not like labels, rather their name references to this position after
# the Macro's name. So %1 means the first 'word' %5 means the fifth word.
# A 'word' can be any number, a label (but not a macro) or a quoted string.
#
#
# Define a new macro that uses two parameters
M Reverse %2 %1
# Call it
@Reverse 100 50
# This should store the 2 numbers in reverse order at memory locations 0x18-0x1b
#
# In lesson one we used the PRT macro and the END macro.
#
# Lets create a new macro that will use these and a parameter.
#
M GoodBye @PRT "Good Bye " @PRT %1 @END
#
# And call that Macro with
@GoodBye "To all my friends."
#
# The output of this should be "Good Bye To all my friends" end the program ending.
#
# Why don't you try some experiments, and see how you can modify memory with Macros
# try different groups of parameters and perhaps see what errors you get if you try to
# pass too many or too few parameters to a Macro.
# Another parameter to test is the %0 parameter. Try it multiple times to see if it changes
#
# Lets see why %0 works the way it does, and how we may wish to use it.
#
# %0 is dynamic numeric value, that is unique to each call of a macro.
# So every time you call a Macro, %0 will have a diffrent value
#
# Example:
M Always101 \
   @JMP SKIP%0 \
     :STORE%0 0 \
   :SKIP%0 \
     @MC2M 101 STORE%0
#
# What worth noticing here, is that the %0 is used to make the Lables SKIP%0 and STORE%0 have unique values
# So the macro can use the local storage named 'STORE%0' but it also has to 'jump' over that storage. To make
# the macro easier to read, it is split across over several lines, using the back-slash '\' to show the
# macro continues onto the next line. Every time this Macro is called, STORE%0 will represent a new and
# diffrent lable.



