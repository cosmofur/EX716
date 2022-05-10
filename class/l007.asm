# This will be our first efforts at looping.
I common.mc
#
# Looping is a critical feature of any language, and Assembly is hardly an exception.
#
# Now if you have experience with just about any high level language,
# I can almost Guarentee that your instructor drilled into you the
# belief that 'Goto' is the root of all evil. Most modern languages hide
# the fact if they support 'Goto' at all.
# This a problem, becuase in Assembly, nearly all logic is done with
# 'Goto' which we call "JMP" for Jump.
# Unlike higher level languages there are no for loops, no while
# loops, and nearly every 'if' block has 'block like' structure if YOU
# the programmer take care and keep your logic block like. With little
# help from the Language itself.
#
# I'm not cliaming that 'Goto's Arn't Evil....it just a type of evil
# you are just going to have to learn to deal with.
#
# Now looping 'forever' is not a good idea, (in most cases) so I have
# to intrduce looping with at least some way to 'exit' the loop, so we
# will also introduce some basic branching logic. We'll go into more
# details on branching later.
#
# For now we will just introduce two new macros
#
#  JMP for unconditional Jumps
#  JMPZ for jumping on zero.
#
# Our looping program will loop from 0 to 20, print the number and
# exit.
#
# Initilize our loop counter.
@PUSH 0
@POPI LoopCount
#
# Now we set a lable to where our loop will return each time.
# Please remember that labels are 'just' pointers to addresses of
# memory, and in this case the pointer is to where we will later want
# our program logic to flow to, rather than the storage of a numeric value.
:LoopStart
#
# do our loop body...in this case print the counter
@PRTI LoopCount  @PRT " "
#
# No add one to LoopCount, we could push, add, and pop it but we have
# a macro to do that for us.
@INCI LoopCount
#
# Now wen have to think about our first condition branch.
# We want to branch back to 'LoopStart' as long as it not equal to
# '20'
#
# So use a CMP (compair) function to compaire LoopStart to 20
@PUSH 20
@CMPI LoopCount
# CMP functions are very much like Subtraction, but the numeric part
# of the result is ignored, rather we only care about how the result
# affects the logic Flags.
# The CMP optcode does not affect the Stack, so that 20 was left on
# it. We do not need it right now, so get rid of it with a POPNULL
@POPNULL
# In this case we are asking
#    does subtracting 20 from LoopCount result in a Zero?
#    when that happens then LoopStart will equal 20
# Looking for the Zero flag will control how we jump
# We will ONLY jump to the label EndLoop when the Z flag is set.
@JMPZ EndLoop
# Otherwise
@JMP LoopStart
#
# So we get here only if Z flag was set.
:EndLoop
@PRTNL
@PRT "End of the loop"
@PRTNL
@END
:LoopCount 0
#
# Somethings to think about:
# Our Print out acutuall went from 0 to 19 rather than 1 to 20.
#  How would you change the code to go from 1 to 20?
# Also we kept pushing 20 then popnull'ing it.
# Could we have saved a few steps by moving those operations? Where?
