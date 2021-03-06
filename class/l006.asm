# Now lets talk a moment about 'variables'
#
I common.mc
#
# It would be very easy to mistake the Assembler concept of 'Lables'
#  as being the same as High level languages concept of variables. But
#  they are diffrent.
# In some (older) high level languages there is support for a variable
# type called 'pointers' They are less popular in some newer high
# level languages because they make the programer work harder in
# keeping track of where data is stored.
# If you have any experience with such a language (like C) then it may
# surprize you that Assember lables are much closer to being pointers
# than they are to being variables.
# The key concept is that when you use a lable, in most cases it
# 'value' is the address WHERE some data is stored (like a pointer)
# rather than the value that is stored AT that address.
# Thus even the most elemntal variable in Assember is a pointer.
#
# So lets start with some examples
#
# This simple PUSH saves the ADDRESS VarOne to the stack. Not that
#value Stored at VarOne
@PUSH VarOne
#
# Use this Alternative version, PUSHI, to copy a value rather than an
# address to the stack.
# First get rid of the less than usefull VarOne Address with a POP to
#nowhere.
@POPNULL
# Then but the 'value' onto the stack.
@PUSHI VarTwo
#
# You can then do an operation on the value. Like adding 1 to it.
@ADD 1
#
# The value is still on the stack, so we need to save it to a variable
# with POPI
@POPI VarTwo
#
# This sequence of Pushing a variable onto the stack, adding one,
# happens so frequently that common.mc provides two convience macros
# to handle this in one command.
# It is the INCI macro and takes a lable as a paramter.
@INCI VarTwo
#
# There is also a subtract one version called DECI
@DECI VarTwo
#
# Now lets print out some results.
@PRT "Output: Var1 = "
@PRTI VarOne
@PRT " Var2 = "
@PRTI VarTwo
@PRTNL
@END

:VarOne 0
:VarTwo 0

