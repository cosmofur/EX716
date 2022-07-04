# Lets go through the core instructions as they are provided by common.mc
#
# The Data Movement group. This is the instrucions that data or memory around
# In more tradional computers this would be called the Load or Move group.
# But in our case the hardware stack, TOS (Top of Stack) and sometimes
# SFT (Second From Top) play an important roll in nearly all data movement.
#
# Opcodes are in familys. Each item in the family has a common base name
# followed by a optional code, which identifies mode of the second parameter
# If there one.
# The Base Name, uses the second paramter as an immediate value. That is 16 bit
# number that follows the base name will be used directly, with no other memory
# refrences.
# If the Base Name is followed by an 'I' it means 'Indirect' and the 16 bit value
# that follows inte optcode will be a reference to a memory location, the what
# ever value is stored at that memory location will be either used or modifie
# by the rules of the Base Name.
# If the Base Name is followed by an 'II' it means 'double indirect' and the 16
# bit value that follows, will instead point to a memory location...and THAT memory
# location will also be a pointer to third 16 bit value which will be what the
# Base Name function will operatate with.
# Lastly if the Base Name if followed by an 'S' it means 'Stack' and in these cases
# there will NOT be any 16 bit value following the optcode and it will instead operatate
# on the values stored in the stack.
#
# In summery
#   ' ' nothing, means work on immediate data.
#   'I' means indirect.
#   'II' means double indirect.
#   'S' means stack.
#
# For many operations, the command will be manipulating two numbers. One will be the TOS and
# if you want to think of the operations algebraicly would be the 'A' value, and the number
# found by the rules above would be the 'B' value.
# In the case of the 'S' or stack operations, the 'A' value will be the SFT and B will TOS.
#
# Now lets go though the core familys of instucitons that follow these rules.
#
# PUSH 0, PUSHI Variable, PUSHII Index, PUSHS
# 
#  The PUSH family puts values onto the stack and moves the current TOS down the stack.
#
# POPI Variable, POPII Index, POPS
#
#   the POP family moves a value from the stack A and stores it in the memory location B
#   In the case of the 'S' stack, A will be SFT and B will be TOS.
#   Note there is no 'Base' POP by itself, because 'POPNULL' does the equivlent.
#
# CMP 0, CMPI Variable, CMPII Index, CMPS
#
#   The CMP function is the way you set the logical flags when compairing two values.
#   It is mathamaticly the same as a subtraction, but the numeric part of the result
#   is discarded. When mentally expressinging the compair operation, you can use the
#   phrase "What Flags would be set if I subtract A from B"
#   It is also notworty that CMP does not POP off the value on the stack. It is left
#   unchanged. Just the flags are modified.
#
# ADD 1, ADDI Variable, ADDII Index, ADDS
#
#   The ADD functions replace the current TOS with the result of adding A + B
#   In the case of the 'S' or stack version, BOTH TOS and SFT are replaces with the result.
#
# SUB 123, SUBI Variable, SUBII Index, SUBS
#
#   The SUB functions replace the current TOS with the reuslt of B - A (take A from B)
#   In the case of the stack version, BOTH TOS and SFT are replaces with the result.
#
# OR 0x7f, ORI Variable, ORII Index, ORS
#
#   The OR functions replaces the current TOS with the result of A | B
#   In the case of the stack version, BOTH TOS and SFT are replaces with the result.
#
# AND 0x7f, ANDI Variable, ANDII Index, ANDS
#
#   The AND functions replaces the current TOS with the result of A & B
#   In the case of the stack version, BOTH TOS and SFT are replaces with the result.
#
##
##
# The next family of operations are the JUMP group, they control where the execution will go next.
# The majority of the JMP group uses the 16 bit number that follows as the destination of the JUMP
# if the required conditions are met. There is one important exception, well cover next.
#
# JMP Lable
#
#   Jumps unconditionally to the address of Lable.
#
# JMPZ Lable
#
#   Used for the equal '==' test.
#   Jumps only if the Z flag is set. Otherwise goes to the next instruction in order.
#
# JMPN Lable
#
#   The N flag is set when the last arthimatic (or CMP) operation resulted in
#   the high bit of the result being set. Remember CMP and SUB are same as B-A, order matters.
#   Jumps only if the N flag is set. Otherwise goes to the next instruction in order.
#
# JMPC Lable
#
#   The Carry bit is used mostly when dealing with 32 bit math. But also plays a roll as the
#   'extra bit' storage when dealing with the Bit Rotation commands bellow.
#   Jumps only if the C flag is set. Otherwise goes to the next instruction in order.
#
# JMPO Lable
#
#   The OverFlow bit main roll is when dealing with 32 bit math.
#   Jumps only if the Z flag is set. Otherwise goes to the next instruction in order.
#
# The exception: JMPI 
#
#  JMPI command is critical when returning from functions or any place where the address
#  you are jumping to, is being calculated or stored in data.
#  Always jumps to the address stored AT the address the 16 bit lable points to.
#
##
##
# 
#  The next family is the Bitwise rotation group.
#  These are operations that modify order of the TOS bits.
#
# RRTC
#   RRTC stands for Rotate Right Through Carry
#      This means bits shift 1 bit downward towards the lowest valued bit. (0 th bit)
#      that lowest bit is copied to the Carry Flag, just at the same time, the current
#      carry flag value is used to 'fill' in the now empty highest bit.
#      Repeating RRTC will eventuly return to the original number after 16 rotations.
#
# RLTC
#   RLTC stands for Rotate Left Through Carry
#      This means the bits shift 1 bit upwards toward the highst valued bit. (15th bit)
#      That high bit is copied to the Carry Flag, just at the same time, the current
#      carry flag value is used to 'fill' in the now empty lowest bit.
#
# RTR
#   RTR stand for Rotate Right
#      The bits will shift 1 bit downwards towards the lowest valued bit.
#      That lowest bit will also be copied to the Carry Flag. BUT whatever value
#      the carry flag previously held will be lost.
#      Repeating RTR will eventully result in a zero value.
#      RTR are also usefull as a divide by 2 function.
#
# RTL
#   RTL stand for Rotate Left
#      The bits will shift 1 bit upwards towards the highest valued bit.
#      That high bit will also be copied to the Carry Flag. BUT whatever value
#      the carry flag previously held will be lost.
#      Repeating RTL will eventully result in a zero value.
#      RTL are also usefull as a multiply by 2 function.
#
##
##
# The last famuly, is really just the leftovers, they are all single purpose funcitons.
#
# CAST
#   CAST is the Output function, its purpose is to write a value to output devices.
#   In the emulator, it also plays the roll as a sort of 'OS' access, ending the program
#   and providing a number of simple text output functions.
#
# POLL
#   POLL is the Input function, its purpose is the read values from input devices.
#   In the emulator is provides some base inbound IO
#
# NOP
#   NOP means No Operation, and that's what it does...nothing, in theory you could use
#   it for timing events as NOP's take a fixed amount of time to execute.
#
# DUP
#   DUP duplicates the TOS so both it and SFT have same value and the previous SFT is now deeper in the stack.
#
# SWP
#   SWP swaps the current TOS and SFT, especially usefull when about to do a CMP or SUB and A and B order is wrong.
#
# FCLR
#   Clears all the Flags. Usefull if you are about to do a RRTC and don't want an unexpected Carry bit in
#
# FSAV
#   Pushes the 4 bit flag register onto the Stack (as a zero padded 16 bit number)
#   Usefull if you want to save the flag state before jumping to a subrouten
#
# FLOD
#   Pops the TOS and saves the lowest 4 bits to the flag register. Usefull for restoring the flags after FSAV
#   
