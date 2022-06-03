# Now lets move from the Macro system to writing a program that does 'something'
# In this case it's going to add some numbers.
#
# I should mention that we nearly will always 'Include' the 'common.mc' file which contains many
# of the core macros and defined values used by the Assembler. So we nealry always start with:
I common.mc
#
# So we're going to use our 'first' Opcodes
# The OPT Codes will be
#   ADDS
#   PUSH
# Also we are also going to introduce a new MACRO called PRTTOP
#
# PUSH will move a number onto the hardware stack.
#
#  Now what is a 'stack'
# Envision the stack as an neat pile of dishes, each plate can hold one 16 bit number, and you can only
# see the number of the top most plate. To see the second top most, you have take the top one off (called Popping)
# and discard or use the previous top plate somewhere other than the stack.
# We call the act of putting a new plate on top of the stack 'PUSH'ing and taking plates off 'POP'ing
# There opt codes based on the same names.
#
# Let start by pushing a number onto the stack.
#   
@PUSH 102
#
# Now you may notice that @PUSH is a 'macro' but its a real simple macro. Much simpler than
# ones like 'PRT' or 'END' because it just a direct translation of the 8 bit number that is the
# internal value of the machine opcode for PUSH. This number happens to be '1'
# There are a few reasons we use a Macro rather than the Number '1'
# First is readability. its much easier to read 'PUSH' than '1' and remember what it does to the Computer.
# Second if we 'just' used a '1' then it would have been stored as a 16bit number, but opcodes have to be
# 8 bit number. So we would have had to use a lowercase 'b' to identify it as an 8 bit '1' or 'b1'
# That would have been even harder to remember so the included file 'common.mc' (look near top line of this program)
# already has macros for all the basic opcodes the CPU recognizes.
#
# And another one.
@PUSH 505
#
# At his point the top of the stack would be 505 with the 102 plate hidden behind it. 
#
# Lets do something to those numbers on the stack, namely add them together.
#
@ADDS
# Note there no parameter to this opcode., but like 'PUSH' it has a simple numeric value of '14'
#
# At this point the Stack will already have the result of 505 + 102 which is 607.
#
# We can confirm this with the special Print Macro named 'PRTTOP' which will print the value of the top
# of the stack, without modifying the stack.
@PRT "Result = "
@PRTTOP
@PRTNL
#
# The value 607 is still on the stack and we can continue to use it.
#
@PUSH 375
@ADDS
#
# And print this result:
#
@PRT "Then Add 375 to get:"
@PRTTOP
@PRTNL
#
#
# That should be enough to get the gist. Try adding different numbers.
#
@END

