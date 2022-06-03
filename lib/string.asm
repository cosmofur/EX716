# String Functions
! STRING_DONE
M STRING_DONE 1
# In the function comments, %R meens this value is used by refrence (ptr) and %V means pass by value.

@JMP SkipStrLib	
# strlen returns length of string inputted.
# [ instring ]
# Return [ length ]

# Defind the Global String Labels but also some Macro Functions to simplfy use. 
G strlen
M Fstrlen @PUSH %1 @CALL strlen
G strcat
M Fstrcat @PUSH %1 @PUSH %2 @CALL strcat
G midstr
M Fmidstr @PUSH %1 @PUSH %2 @PUSH %3 @CALL midstr
G memchr
M Fmemchr @PUSH %1 @PUSHI %2 @PUSH %3 @CALL memchr
G memcmp
M FmemcmpV @PUSH %1 @PUSH %2 @PUSH %3 @CALL memcmp
M FmemcmpR @PUSH %1 @PUSH %2 @PUSHI %3 @CALL memcmp
G itos
G stoi
#
#

# strlen ( %R strptr )
#  Returns length of string
:strlen
	@POPI ls_return1
	@POPI ls_strptr
	@MC2M 0 ls_index1
:strlenloop1
	@PUSHII ls_strptr    # set c to value at index.
	@POPI ls_CVal1
	@PUSH 0x00ff         #mask out just lower order value
	@ANDI ls_CVal1
	@POPI ls_CVal1
	@PUSH 0              # Test for null character
	@CMPI ls_CVal1
	@POPNULL
	@JMPZ strlendone
	@INCI ls_strptr
	@INCI ls_index1
	@JMP strlenloop1
	:strlendone
	@PUSHI ls_index1
	@PUSHI ls_return1
	@RET
	
	
# MidStr order of paramters
#  %R instring, %R outstring, %V startindex, %V stopindex
# Copies from instring from start to stopindex to outstring.
# Outstring must already be large enough to hold result.
# Is start < len(string) or stop > len(string) then adjust to fix range
	:midstr
	@POPI ms_Return1
	@POPI ms_Index2        # Stopindex
	@POPI ms_Index1        # Starindex
	@POPI ms_OutString1
	@POPI ms_InString1
	@PUSHI ms_InString1	
	@CALL strlen        # Length on stack
	@CMPI ms_Index1
	@JLE Idx1Over
:RetIdx1Over                # Length Still on stack
	@CMPI ms_Index2
	@JLE Idx2Over
	# Neither ms_Index1 or ms_Index2 are both < len(instr)
:RetIdx2Over
	@POPNULL            # Take length off stack.
	@PUSHI ms_InString1
	@ADDI ms_Index1
	@POPI ms_Index1
	@PUSHI ms_InString1
	@ADDI ms_Index2
	@POPI ms_Index2
	@INCI ms_Index2
:midstrloop1
	@PUSHII ms_Index1
	@POPI ms_CVal1
	@PUSH 0x00ff
	@ANDI ms_CVal1
	@POPII ms_OutString1
	@INCI ms_OutString1
	@INCI ms_Index1
	@PUSHI ms_Index1	
	@CMPI ms_Index2
	@POPNULL	
	@JNZ midstrloop1
	@PUSHI ms_Return1
	@RET
# Handle cases where the start or stop index were too large for space.
:Idx1Over
	@DUP
	@POPI ms_Index1
	@JMP RetIdx1Over
:Idx2Over
	@DUP
	@POPI ms_Index2
	@JMP RetIdx2Over
## memchr ( %R strptr, %V (16b) char const, %V nbytes  )
##  returns index where char is in strptr up to max of nbytes or -1 if not found.

:memchr
	@POPI memchr_Return1   # Return vector:memchr_loop1
	@POPI memchr_nlimit
	@PUSH 0x00ff            # Mask off top 8 bits of test char
	@ANDS
	@POPI memchr_char
	@POPI memchr_strptr
	@MC2M 0 memchr_result   # Zero the resut
:memchr_loop1	
	@PUSHII memchr_strptr      # push [[prt]]
	@PUSH 0x00ff               # Mask off top 8b
	@ANDS
	@CMPI memchr_char          # CMP it to test char
	@POPNULL
	@JMPZ memchr_foundit
	@INCI memchr_strptr
	@INCI memchr_result
	@DECI memchr_nlimit
	@PUSH -1               # We keep counting down nlimit until it is -1
	@CMPI memchr_nlimit
	@POPNULL
	@JNZ memchr_loop1       # As long as it's not -1 then repeat loop
	# Failure so make result = -1 if we get here.
	@MC2M -1 memchr_result     # Fill the result register with the error return code if it wasn't found.
:memchr_foundit
	@PUSHI memchr_result        # Put offset (starting from zero) where char was fond on stack
	@PUSHI memchr_Return1
	@RET
#
# strcat(str1,str2) result is str2 is appened to str1. str1 must already be large enough for results allong with null at end.
#
:strcat
	@POPI scat_return1
	@POPI scat_str2_in
	@POPI scat_str1_in
	# Index1 will be ptr to write point of str1
	# Index2 will be ptr to read point of str2
	@MM2M scat_str2_in scat_index2
	# Get length of str1
	@PUSH scat_str1_in
	@CALL strlen
	@PUSHI scat_str1_in
	@ADDS  # Add length to start pos of str1 to get indert point.
	@SUB 1
	@POPI scat_index1
:strcat_loop1
	@PUSHII scat_index2
	@PUSH 0x00ff
	@ANDS
	@CMP 0
	@POPII scat_index1
	@JMPZ strcat_exitloop1
	@INCI scat_index1
	@INCI scat_index2
	@JMP strcat_loop1
:strcat_exitloop1
	@PUSHI scat_return1
	@RET

#
# strncat(str1,str2,maxn)
#
:strncat
	@POPI scat_return1
	@POPI scat_max
	@POPI scat_str2_in
	@POPI scat_str1_in
	@MM2M scat_str2_in scat_index2
	@PUSH scat_str1_in
	@CALL strlen
	@PUSHI scat_str1_in
	@ADDS
	@POPI scat_index1
:strncat_loop1
	@PUSHII scat_index2
	@PUSH 0
	@CMPI scat_max
	@POPNULL
	@JMPZ strncat_exitloop1
	@DECI scat_max
	@PUSH 0x00ff
	@ANDS
	@CMP 0
	@POPII scat_index1
	@JMPZ strncat_exitloop1
	@INCI scat_index1
	@INCI scat_index2
	@JMP strncat_loop1
:strncat_exitloop1
	@PUSHI scat_return1
	@RET
# memcmp ( %R str1, %R str2, %V length)
#   compair two strings, (subtract str1 - str2, returns)
#   +1 if remainder is positive (str1 > str2)
#    0 if they are the same (up to length limit)
#   -1 if remainder is negative (str1 < str2)
:memcmp
       @POPI mcmp_return1
       @POPI mcmp_length1       
       @POPI mcmp_str2
       @POPI mcmp_str1
       @Fstrlen mcmp_str1   # Test to make sure total length test is < len(str1) and < len(str2)
       @CMPI mcmp_length1
       @JLT mcmp_s1notlt
:mcmp_s2testlgth
       @POPNULL             # str1 len is fine, get rid of unneeded len
       @Fstrlen mcmp_str2
       @CMPI mcmp_length1
       @JLT mcmp_s2notlt
       @POPNULL             # str2 len if fine, get rid of unneeded len
       @JMP mcmp_nextp
:mcmp_s1notlt               # Jump here if len of str1 is < mcp_length1
       @POPI mcmp_length1
       @JMP mcmp_s2testlgth
:mcmp_s2notlt               # Jump here if len of str2 is < mcp_length1
       @POPI mcmp_length1
:mcmp_nextp
       @MC2M 0 mcmp_index1
:mcmp_loop1
       @PUSHI mcmp_index1
       @CMPI mcmp_length1
       @POPNULL             # Unlike Subtraction, CMP ops leave the Original value on stack, junk it when done.
       @JMPZ mcmp_length_exit     # Test end with index == max length
       @PUSHII mcmp_str1
       @PUSH 0x00ff	          # Mask out the lower 8 bits.
       @ANDS
       @PUSHII mcmp_str2
       @PUSH 0x00ff
       @ANDS       
       @CMPS       
       @JMPZ mcmp_continue        # Matching so far, continue
       @JMPN mcmp_s2gts1          # str2 > str1       
       # otherwise str1 > str2
       @POPNULL
       @POPNULL
       @PUSH -1
       @PUSHI mcmp_return1
       @RET
:mcmp_s2gts1                      # Not same ans s2 is > s1
       @POPNULL
       @POPNULL
       @PUSH 1
       @PUSHI mcmp_return1
       @RET
:mcmp_continue
       @POPNULL
       @POPNULL
       @INCI mcmp_str1
       @INCI mcmp_str2
       @INCI mcmp_index1
       @JMP mcmp_loop1
:mcmp_length_exit
# If we reach here, then for at least length character, both strings are the same.
       @PUSH 0
       @PUSHI mcmp_return1
       @RET

#
# stoi string to integer.
# On Stack STRPTR.
#
:stoi
@POPI siReturn1 @POPI siStrPtr @PUSHI siStrPtr
@CALL strlen @POPI siLength       # Set siLength to length of string.
@MC2M 0 siResult @MC2M 1 siMulti  # Zero out result and set initial multiplier to 1
:siMainLoop
# While siLength != 0
  @PUSHI siLength @CMP 0 @JMPZ siEndLoop
  # Note we did not POPNULL after pushing siLength so it is still there.
  @ADDI siStrPtr    # Add in siStrPtr so TOS is pointer to an siLength index of string.
  @POPS             #  @StrPtr[siLength]
  @SUB 0x30         # ASCII code to number subtract 0x30
  @PUSHI siMulti    # Multiply by index^10 
  @CALL MUL  
  @ADDI siResult @PUSHI siResult   # Result = str[index]*siMulti + Result
  @PUSH 10 @PUSH siMulti @CALL MUL # siMulti = siMulti*10
  @POPI siMulti
  @DECI siLength
@JMP siMainLoop
:siEndLoop
@POPNULL
@PUSHI siResult
@PUSHI siReturn1
@RET
:siReturn1 0
:siResult 0
:siMulti 0
:siLength 0
:siStrPtr 0

# Now integer to string
# On stack, StrPtr, InValue, Base
# Push params StrPtr (of at least 6 characters length to support "65535" b0
# Then the integer value
:itos
@POPI isReturn1
@POPI isBase
@POPI isInvalue
@POPI isStrPtr
# Fill workBuff with spaces for now
@MC2M 0x3000 isWorkBuff   # We preload first digit as zero, as this lets us skip the zero test later.
@MC2M 0x0 isWorkBuff+2    # We haven't used this too often but this sort of simple math is allowed
@MC2M 0x0 isWorkBuff+4    # But only for lables and there can't be a space around the '+' (or '-')
#
@MM2M isInvalue isWorkVal
# Handle Negatives
@MC2M 0 isNegFlag
@PUSH 0 @CMPI isWorkVal @POPNULL
@JGE isNotNeg        # JGE means last cmp was NOT 'N' and NOT 'Z'
  # Is negative
  @MC2M 1 isNegFlag
  @PUSHI isWorkVal @COMP2 @POPI isWorkVal   # isWorkVal=abs(isWorkVal)
:isNotNeg
@MC2M isWorkBuff isRevIndex      # We'll first go left to right, so index starts at zero. We'll reverse it later.
# While WorkVal > 0
:isMainLoop
@PUSHI isWorkVal
@CMP 0 @POPNULL
@JMPZ EndWhileLoop
  @PUSHI isWorkVal
  @PUSHI isBase
  @CALL DIV    # Value / 10 get both result and remainder
  @POPI isWorkVal   # isWorkVal=INT(isWorkVal/base)
  @AND 0x0f         # We only handle cases were bases are <=16  
  @ADD 0x30         # TOS is digit value so add 0x30 to turn it ASCII
  @CMP 0x39         # Now worry about Hex which means jump to Letters is val > 9
  @JGT isNotHex     # Only hex numbers could be over 0x39 so map them to A-F
     @ADD  0x7      # "A" is 0x41 so add  to turn 0x3A to 0x41
  :isNotHex
  @POPII isRevIndex  # Saves ASCII
  @INCI isRevIndex
  @JMP isMainLoop
:EndWhileLoop
# At this point isWorkBuff will have in reverse order the ASCII number. Max of 5 digits.
#
# Check if Sign flag was set.
@PUSH 0 @CMPI isNegFlag @POPNULL
@JMPZ isGoReverseDigits
# Else add Neg flag
  @PUSH 0x2d   # 2d == "-" Insert it as first character of return string
  @POPII isStrPtr
  @INCI isStrPtr
:isGoReverseDigits
@DECI isRevIndex    # RevIndex will be once past the end of string so pull it back
:isReverseLoop
# While isRevIndex > isWorkBuff
  @PUSHI isRevIndex
  @CMP isWorkBuff      # note WorkBuff is a lable location, not a variable
  @POPNULL
  @JGT isExitReverseLoop
  @PUSHII isRevIndex
  @POPII isStrPtr
  @PUSH 0
  @POPII isRevIndex     # After copying we zero out the character so in next loop only the 'lower' byte will count
  @INCI isStrPtr
  @DECI isRevIndex
  @JMP isReverseLoop
:isExitReverseLoop
  @PUSHI isReturn1
  @RET
:isReturn1 0
:isBase 0
:isInvalue 0
:isStrPtr 0
:isWorkBuff 0 0 0 0 0 0 0 0
:isNegFlag 0
:isWorkVal 0
:isRevIndex 0

:ls_index1 0
:ls_strptr 0
:ls_CVal1 0
:ls_return1 0		
:ms_Index1 0
:ms_Index2 0
:ms_Return1 0	
:ms_InString1 0
:ms_OutString1 0
:ms_CVal1 0
:memchr_nlimit 0
:memchr_char 0
:memchr_strptr 0
:memchr_result 0
:memchr_Return1 0
:scat_return1 0
:scat_str1_in 0
:scat_str2_in 0
:scat_index1 0
:scat_index2 0
:scat_max 0
:mcmp_return1 0
:mcmp_length1 0
:mcmp_str1 0
:mcmp_str2 0
:mcmp_index1

ENDBLOCK
:SkipStrLib

