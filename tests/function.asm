I common.mc
L screen.ld
L random.ld
L softstack.ld
L heapmgr.ld
#
# Global Vars
#
# Heap and stacks
:MainHeapID 0
:CodeStackID 0
:CodeStack 0 0 0
:DataStackID 0
:DataStack 0 0 0
#
# Var and Code spaces
:CommandPtr 0
:Acum32ptr Acum32   # ptr to 32 bit acumulator
:Acum32 0 0
:StateFlag 0
:TERMALPHA "(+-*/ \t)\0"
:SEPALPHA ",\n\0"

#
#
# Function Init
:Init
   @PUSH 0xff00          # Declair most of the memory from ENDOFCODE to ff00 as heap
   @SUB ENDOFCODE
   @PUSH ENDOFCODE
   @CALL HeapDefineMemory
   @POPI MainHeapID
   # Now Define First SoftStack
   @PUSHI MainHeapID
   @PUSH 0x400       # 1K for Code Stack, allowd '500' deep values
   @CALL HeapNewObject
   @POPI CodeStackID
   @SetSSStackIS CodeStackID 0x400
   @SaveSSStackA CodeStack
   @PUSH 0x400       # 1K for Data Stack
   @CALL HeapNewObject
   @POPI DataStackID
   @SetSSStackIS DataStackID 0x400
   @SaveSSStackA DataStack
   @SaveSSStackA DataStack
   # The Code stack will be the 'default' stack for funciton.
   @RestoreSSStackA CodeStack
   #
   # Add initilization of global variables here.
   @RET
#
# Function SkipWhiteSpace(instringptr):length
# Skip White Space
# Returns int16 ptr to the first non-whitespace character.
:SkipWhteSpace
@PUSHRETURN
=Index1 Var01       # Can I reused Index1? or does it have to be unique?
@PUSHLOCALI Index1
@POPI Index1
@MV2V Index1 StartIdx   # Save this for later math
@PUSHII Index1 @AND 0xff
@WHILE_NOTZERO
   @SWITCH
   # If its a space or linefeed or tab, just move Index1 forward 1 character
   @CASE " \0"
      @POPNULL
      @INCI Index1
      @PUSHII Index1 @AND 0xff
      @CBREAK
   @CASE "\n\0"
      @POPNULL
      @INCI Index1
      @PUSHII Index1 @AND 0xff
      @CBREAK
   @CDEFAULT
      @POPNULL
      @PUSH 0      # Index1 is pointing at first non-white charactr (or end) so break while
      @CBREAK
   @ENDCASE
@ENDWHILE
@POPNULL
#
@PUSHI Index1   # Save result on return stack.
#
@POPLOCAL Index1
@POPRETURN
@RET
#
#
# State Flag meaning
#
# State      : Meaning
# 0          : At begining of process
#
# Function ParseWord(InString):(TolkenID, ValuePtr, CharsConsumed)
:ParseWord
@PUSHRETURN
=Consumed Var01
=InStringPtr Var02
=StateFlag Var03
#
@PUSHLOCAL Consumed
@PUSHLOCAL InStringPtr
@PUSHLOCAL StateFlag
#
@POPI InStringPtr
#
@MA2V 0 Consumed
# Skip the white space, count characters and save to Consumed.
# Point InStringPtr to first non-white text.
@PUSHI InStringPtr
@CALL SkipWhileSpace
@DUP                    # TOS is ptr to first non-white text
@SUBI InStringPtr       # Turn into character count
@POPI Consumed          # Save that to Consumed
@POPI InStringPtr       # Move InStringPtr to new start.
#
# States
=InitialState 0
=IsAlpha 1
@MA2V InitialState StateFlag       # This is 'initial' state.
#
@PUSHII InStringPtr @AND 0xff    # Look at first character
@WHILE_NOTZERO
   # We'll loop until end of string or some other exit condiiton is met.
   #
   # Test to see if its a letter for variable names (or functions)
   @SWITCH
      @CASE_RANGE "A\0" "Z\0"
          @MA2V IsAlpha StateFlag
          

