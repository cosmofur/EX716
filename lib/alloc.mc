#
# This is a Very simple minded memory manager
# All it can do is allocate blocks of fixed size memory starting from a fixed top of memory 0xe000
# When memory is free'ed it MUST be freeded in reverse order of allocation, as anything allocated
# before the 'free'ed' block will also be lost.
#
# The real purpose of this libary is to demostrate a way to use Macro's to do a function like operation.
#
M MAllocA \
         ! SkipMANext @JMP %0AStore \
  	 G MATopMem \
	 :MATopMem 0 :%0AStore @MC2M 0xE000 MATopMem \
	 ENDBLOCK \
      @PUSH %1 @SUBI MATopMem @DUP @POPI MATopMem \
      @DECI MATopMem \
      M SkipMANext

# It required that FreeA be called After MAllocA so just do nothing if its not defined yet.
# You pass the pointer to where the MAllocA'ed memory starts.
M FreeAI ! SkipMANex  @MM2M %1 MATopMem ENDBLOCK

