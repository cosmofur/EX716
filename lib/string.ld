# String Functions
! STRING_DONE
L mul.ld
L div.ld
M STRING_DONE 1
# In the function comments, %R meens this value is used by refrence (ptr) and %V means pass by value.

@JMP SkipStrLib	
# strlen returns length of string inputted.
# [ instring ]
# Return [ length ]

# Defind the Global String Labels but also some Macro Functions to simplfy use. 
G strlen G strcat G midstr G memchr G memcmp G itos G stoi G strfndc G strucase

M Fstrlen @PUSH %1 @CALL strlen
M Fstrcat @PUSH %1 @PUSH %2 @CALL strcat
M Fmidstr @PUSH %1 @PUSH %2 @PUSH %3 @CALL midstr
M Fmemchr @PUSH %1 @PUSHI %2 @PUSH %3 @CALL memchr
M FmemcmpV @PUSH %1 @PUSH %2 @PUSH %3 @CALL memcmp
M FmemcmpR @PUSH %1 @PUSH %2 @PUSHI %3 @CALL memcmp
#
#

# strlen ( %R strptr )
#  Returns length of string
:len_return1 0
:len_strptr 0
:len_char 0
:len_index1 0
:strlen
	@POPI len_return1
	@POPI len_strptr
	@MC2M 0 len_index1
:strlenloop1
	@PUSHII len_strptr    # set c to value at index.
	@POPI len_char
	@PUSH 0x00ff         #mask out just lower order value
	@ANDI len_char
	@POPI len_char
	@PUSH 0              # Test for null character
	@CMPI len_char
	@POPNULL
	@JMPZ strlendone
	@INCI len_strptr
	@INCI len_index1
	@JMP strlenloop1
	:strlendone
	@PUSHI len_index1
	@PUSHI len_return1
	@RET
	
	
# MidStr order of paramters
#  %R instring, %R outstring, %V startindex, %V stopindex
# Copies from instring from start to stopindex to outstring.
# Outstring must already be large enough to hold result.
# Is start < len(string) or stop > len(string) then adjust to fix range
:ms_Index1 0
:ms_Index2 0
:ms_Return1 0	
:ms_InString1 0
:ms_OutString1 0
:ms_CVal1 0
:midstr
	@POPI ms_Return1
	@POPI ms_Index2        # Stopindex
	@POPI ms_Index1        # Starindex
	@POPI ms_OutString1
	@POPI ms_InString1
	@PUSHI ms_InString1	
	@CALL strlen        # Length on stack
	@CMPI ms_Index1
	@JLT Idx1Over       # A=Strlen B=ms_Index if A < B Jmp Over
:RetIdx1Over                # Length Still on stack
	@CMPI ms_Index2
	@JLT Idx2Over       # A=StrLen, B=msIndex2, if B>=A Jmp Over
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
:memchr_nlimit 0
:memchr_char 0
:memchr_strptr 0
:memchr_result 0
:memchr_Return1 0
#
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
:scat_return1 0
:scat_str1_in 0
:scat_str2_in 0
:scat_index1 0
:scat_index2 0
:scat_max 0
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
:mcmp_return1 0
:mcmp_length1 0
:mcmp_str1 0
:mcmp_str2 0
:mcmp_index1
:memcmp
       @POPI mcmp_return1
       @POPI mcmp_length1       
       @POPI mcmp_str2
       @POPI mcmp_str1
       @Fstrlen mcmp_str1   # Test to make sure total length test is < len(str1) and < len(str2)
       @CMPI mcmp_length1
       @JLT mcmp_s1notlt    # A=strlen B=length1, if B>A Jmp NotLt
:mcmp_s2testlgth
       @POPNULL             # str1 len is fine, get rid of unneeded len
       @Fstrlen mcmp_str2
       @CMPI mcmp_length1
       @JLT mcmp_s2notlt    # A=strlen, B=length1, if B>A Jmp NotLT
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
       @PUSHII mcmp_str2
       @PUSH 0x00ff	          # Mask out the lower 8 bits.
       @ANDS
       @PUSHII mcmp_str1
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
@POPI siReturn1 @DUP @POPI siStrPtr
@CALL strlen @POPI siLength       # Set siLength to length of string.
@MC2M 0 siResult @MC2M 1 siMulti  # Zero out result and set initial multiplier to 1
@MC2M 0 siNegFlag                 # zero for possitive numbers	
:siMainLoop
# While siLength != 0
  @PUSHI siLength @CMP 0 @POPNULL @JMPZ siEndLoop	
  @DECI siLength @PUSHI siLength   # Size is 1 to N but Index is 0 to N-1
  @ADDI siStrPtr    # Add in siStrPtr so TOS is pointer to an siLength index of string.
  @PUSHS            #  @StrPtr[siLength]
  @AND 0xff	    #  Only care about 8 bit character there.
  @CMP "-" b0       #  Look for Negative Flag
  @JNZ SiNormal
     # If '-' seen.
     @MC2M 1 siNegFlag
     @JMP siMainLoop
  :SiNormal
  @SUB 0x30         # Subtrack ascii '0'
  @PUSHI siMulti    # Multiply by index^10 
  @CALL MUL
  @ADDI siResult @POPI siResult   # Result = str[index]*siMulti + Result
  @PUSH 10 @PUSHI siMulti @CALL MUL # siMulti = siMulti*10
  @POPI siMulti
@JMP siMainLoop
:siEndLoop
# If Negative flag set
@PUSHI siNegFlag @CMP 0 @POPNULL
@JMPZ siNotNegative
   @PUSHI siResult
   @COMP2
   @POPI siResult
:siNotNegative
@PUSHI siResult
@PUSHI siReturn1
@RET
:siReturn1 0
:siResult 0
:siMulti 0
:siLength 0
:siStrPtr 0
:siNegFlag 0

# Now integer to string
# On stack, StrPtr, InValue, Base
# Push params StrPtr (of at least 6 characters length to support "65535" b0
# Then the integer value
:isReturn1 0
:isBase 0
:isInvalue 0
:isStrPtr 0
:isWorkBuff 0 0 0 0 0 0 0 0
:isNegFlag 0
:isWorkVal 0
:isRevIndex 0
#
:itos
@POPI isReturn1
@POPI isBase
@POPI isInvalue
@POPI isStrPtr
#a Fill workBuff with spaces for now
@MC2M 0x3000 isWorkBuff   # We preload first digit as zero, as this lets us skip the zero test later.
@MC2M 0x0 isWorkBuff+2    # We haven't used this too often but this sort of simple math is allowed
@MC2M 0x0 isWorkBuff+4    # But only for lables and there can't be a space around the '+' (or '-')
#
@MM2M isInvalue isWorkVal
# Handle Negatives
@MC2M 0 isNegFlag
@PUSH 0 @CMPI isWorkVal @POPNULL
@JLT isNotNeg        # A=0 B=WorkVal if B < A JMP NotNeg
  # Is negative
  @MC2M 1 isNegFlag
  @PUSH 1 @PUSHI isWorkVal @SUBS @INV @POPI isWorkVal   # isWorkVal=abs(isWorkVal)
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
  @JLE isNotHex     # A=x30+Val B=0x39, if B<=A not hex
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
  @JLE isExitReverseLoop # A=RevIndex B=WorkBuff, if B<=A exit loop
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
#
# strfndc Finds first instance of characer in string
# %R instring %V 16b code to match, will be masked.
:fnd_return1 0
:fnd_strptr 0
:strfndc
      @POPI fnd_return1
      @POPI fnd_strptr
      @AND 0xff    # Only care about lower order byte
:strfndloop1
      @PUSHII fnd_strptr
      @AND 0xff
      @CMP 0            #First check if end of string
      @JMPZ strfndNoMatch
      @CMPS             # We left the character to find on stack, so we can cmp now.
      @POPNULL      
      @JMPZ strfndMatch
      @INCI fnd_strptr
      @JMP strfndloop1
:strfndNoMatch
      @POPNULL          # Get rid of search character
      @PUSH -1          # No match mean -1
      @JMP strfndReturn
:strfndMatch
      @POPNULL          # Get rid of search character
      @PUSHI fnd_strptr
:strfndReturn
      @PUSHI fnd_return1
      @RET
#
# strucase replace lowercase letters with uppercase ones.
# strucase(string)
:ucs_len 0
:ucs_index 0
:ucs_char1 0
:ucs_strptr 0
:strucase
      @SWP    # save the return address
      @DUP    # First get length of string
      @CALL strlen
      @POPI ucs_len
      @POPI ucs_strptr
      @ForIA2V ucs_index 0 ucs_len
      	 @PUSHI ucs_strptr
	 @ADDI ucs_index
	 @PUSHS
	 @DUP  #Save full word to preserver upper byte
	 @AND 0xff00
	 @SWP  # Now handle the lowerbyte
	 @AND 0xff
	 @CMP "a" b0
	 @JLT ucs_NotAlpha # A=char B='a' if A < B, Jmp NotAlpha
	 @CMP "z" b0
	 @JGT ucs_NotAlpha # A=Char B='Z' if A > B, Jmp notAlpha
	 @AND 0xdf         # Mask the bits from lower to uppercase in ASCII code
	 :ucs_NotAlpha
	 @ORS              # Or together lower and upper bytes
	 @PUSHI ucs_strptr # Return the reformated upper/lower bytes back to strptr
	 @ADDI ucs_index
	 @POPS
      @Next ucs_index
      @RET
ENDBLOCK
:SkipStrLib

