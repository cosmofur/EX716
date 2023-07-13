#
# This is a Very simple minded memory manager
# All it can do is allocate blocks of fixed size memory starting from a fixed top of memory 0xe000
# When memory is free'ed it MUST be freeded in reverse order of allocation, as anything allocated
# before the 'free'ed' block will also be lost.
#
# The real purpose of this library is to demonstrate a way to use Macro's to do a function NEW like operation.
#
# To understand this fully.
#  The first ion 4 lines are an initialization block, setting up MATtopMem to an initial 0xE000
#  Lines 5-8
#   Do the cacluation of MATopMem - Request_Siz and keep two copies of the result
#   The first copy is furter decrmented by one work (SUB 2) and using POPS at this
#   MATopMem-2 address we write a copy of the old MATopMem.
#   Lastly we both return on the stack and save the new version of MATopMem for next runs.

M MAllocA \
         ! SkipMANext @JMP %0AStore \
  	 G MATopMem \
	 :MATopMem 0 :%0AStore @MA2V 0xE000 MATopMem \
	 ENDBLOCK \      
         @PUSHI MATopMem @SUB %1 @DUP \
         @SUB 2 @PUSHI MATopMem @SWP @POPS \
	 @DUP @POPI MATopMem \
         M SkipMANext

# It required that FreeA be called After MAllocA so just do nothing if its not defined yet.
# You pass the pointer to where the MAllocA'ed memory starts.
#
# Call this with the variable that contains the lowest block you wish to Free.
# All block allocated before that block will also be 'freed' so do not interweave
# allocks and Frees out of order.
# The way this works, is it looks at the current MATopMem and at location -2 there
# should be the address of the previous MATopMem, so it copies that back.
# 
M FreeAI ! SkipMANex \
@PUSHI %1 @SUB 2 @PUSHS @POPI MATopMem \
ENDBLOCK

