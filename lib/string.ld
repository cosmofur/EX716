# String Functions Generation two
! STRING_DONE
M STRING_DONE 1
L div.ld
L mul.ld
L softstack.ld
L heapmgr.ld
G strlen G strcat G strcpy G strncpy G strncmp G strcmp G itos G stoi G memcpy G strstr G strfndc
G ISAlphaNum G IsAlpha G ISNumeric G strncat G stoifirst G strtok G splitstr G SplitDelete
G strUpCase G strLowCase G HexDump

#
# Some 'String' Macros
# STRSET copies %1 to memory at %2, which muse be the address where sufficent space exists.
G STRSET G STRSETI
M STRSET \
  @JMP _%0_Skip :_%0Store %1 $$0 :_%0_Skip @PUSH %2 @PUSH _%0Store @CALL strcpy
# STRSETI same as STRSET but %2 is ptr to memory rather than the address itself.
M STRSETI \
  @JMP _%0_Skip :_%0Store %1 $$0 :_%0_Skip @PUSHI %2 @PUSH _%0Store @CALL strcpy
#
# STRSTACK saves imediate data in inline storage and leaves its address on the stack.
M STRSTACK \
   @JMP _%0_Skip :_%0Store %1 $$0 :_%0_Skip @PUSH _%0Store


# Function strlen
# strlen(str_var) returns length of string
:WorkBuff "00000000" $$0       # Long enough for -32000 to +32000

#
# Function
:strlen
@PUSHRETURN
=len_strptr Var01
=len_size Var02
@PUSHLOCALI len_strptr
@PUSHLOCALI len_size
@POPI len_strptr
@MA2V 0 len_size
@PUSHII len_strptr  # First character
@AND 0x00ff
@WHILE_NOTZERO
   @POPNULL
   @INCI len_size
   @INCI len_strptr
   @PUSHII len_strptr
   @AND 0x00ff
@ENDWHILE
@POPNULL
@PUSHI len_size
@POPLOCAL len_size
@POPLOCAL len_strptr
@POPRETURN
@RET
#
#
# Function strcat(strA,strB)
# Concats strB to strA (modifies StrA which must already be large enough to handle both)
:strcat
@PUSHRETURN
=StrPtrA Var01
=StrPtrB Var02
@PUSHLOCALI StrPtrA
@PUSHLOCALI StrPtrB
@POPI StrPtrB
@POPI StrPtrA
@PUSHI StrPtrA
@CALL strlen
@ADDI StrPtrA
@POPI StrPtrA
@PUSHII StrPtrB
@AND 0x00ff
@WHILE_NOTZERO
   @POPII StrPtrA
   @INCI StrPtrA
   @INCI StrPtrB
   @PUSHII StrPtrB
   @AND 0xff
@ENDWHILE
@POPNULL
@POPLOCAL StrPtrB
@POPLOCAL StrPtrA
@POPRETURN
@RET
#
#
# function strncat(StrA,StrB,maxlen)
# Appends StrB to StrA up to either end of StrB or max of maxlen.
#         StrA must still have sufficent space for combined length of both strings.
:strncat
@PUSHRETURN
=Length Var01
=StrPtrB Var02
=StrPtrA Var03
@PUSHLOCALI StrPtrA
@PUSHLOCALI StrPtrB
@PUSHLOCALI Length
@POPI Length
@POPI StrPtrB
@POPI StrPtrA
@PUSHI StrPtrA
@CALL strlen
@ADDI StrPtrA
@POPI StrPtrA
@PUSHI Length
@IF_NOTZERO      # First make sure whole string wasn't null
  @PUSHII StrPtrB
  @AND 0x00ff
  @WHILE_NOTZERO
     @POPII StrPtrA
     @INCI StrPtrA
     @INCI StrPtrB
     @DECI Length
     @PUSHII StrPtrB   
     @AND 0xff
     @PUSHI Length
     @IF_NOTZERO      # We want to handle gravefully both Length and if src string ends early.
        @POPNULL
     @ELSE
        @POPNULL
	@POPNULL
	@PUSH 0
     @ENDIF
  @ENDWHILE
@ENDIF
@POPNULL
@POPLOCAL Length
@POPLOCAL StrPtrB
@POPLOCAL StrPtrA
@POPRETURN
@RET

#
# Function strncpy(dest, src, length) Copies from src[0:length] to dest[0:length]
# if length>len(src) then it will only copy upto length of src.
# It DOES NOT append a null at the end of dest automaticly.
#
:strncpy
@PUSHRETURN
=Length Var01
=SrcPtr Var02
=DstPtr Var03
=Index Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@POPI Length
@POPI SrcPtr
@POPI DstPtr
# Get acutual length of src, and if < Length, change Length to len(src)
@PUSHI SrcPtr
@CALL strlen
@PUSHI Length
@IF_LT_S
   @POPNULL
   @POPI Length
@ELSE
   @POPNULL
   @POPNULL
@ENDIF
#
# Do the copy, one byte at a time.
#
@ForIA2V Index 0 Length
   @PUSHII SrcPtr
   @AND 0x00ff
   @PUSHII DstPtr
   @AND 0xff00
   @ORS
   @POPII DstPtr
   @INCI SrcPtr
   @INCI DstPtr
@Next Index
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
# Function(StrA, StrB) 
# strcpy without the 'n' just copies all of StrB into StrA
# StrA must be at least as large as the maxsize of StrB
:strcpy
@PUSHRETURN
=SrcPtr Var01
=DstPtr Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI SrcPtr
@POPI DstPtr
# Setup for first pass of while loop
@PUSHII SrcPtr
@AND 0x00ff          # Mask just the lower byte.
@WHILE_NOTZERO
   @POPII DstPtr
   @INCI DstPtr
   @INCI SrcPtr
   @PUSHII SrcPtr
   @AND 0x00ff
@ENDWHILE
@POPNULL
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
# strncmp(StrA,StrB,MaxChars)  compairs two string and returns -1,0 or 1
# based on their relationship. -1 if str1 lexicongraphically < str2
#                              +1 if str1 > str2
#                               0 if str1 == str2
:strncmp
@PUSHRETURN
=MaxLength Var01
=DstPtr Var02
=SrcPtr Var03
=Length Var04
=Index Var05
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
#
@POPI MaxLength
@POPI DstPtr
@POPI SrcPtr
# IF we just jump into the loop 0->len(SrcPtr) then
# we run into an issue with the edge case of Src=""
# In that case if Dst!="" then it will always be larger or return -1
# Otherwise an simple loop from 0 to len(src) should catch the rest
# of the options.
@PUSHI SrcPtr
@CALL strlen
@IF_ZERO
   @PUSHI DstPtr
   @CALL strlen
   @IF_NOTZERO
      @POPNULL
      @POPNULL
      @PUSH -1
      @JMP strncmpExit
      @POPRETURN
      @RET
   @ELSE
      @POPNULL  # If both are zero legnth, result is still 0
      @POPNULL
      @PUSH 0
      @JMP strncmpExit
   @ENDIF
@ENDIF
@POPI Length   # Length of Src, must be > 0
@PUSHI MaxLength
@IF_LT_V Length
  @POPI Length
@ELSE
  @POPNULL
@ENDIF
@ForIA2V Index 0 Length
   @PUSHII SrcPtr
   @AND 0xff
   @PUSHII DstPtr
   @AND 0xff
   @IF_LT_S
      # Src[index]<Dst[index]
      @POPNULL
      @POPNULL
      @PUSH -1
      @JMP strncmpExit
   @ENDIF
   @IF_GT_S
      # Src[index]>Dst[index]
      @POPNULL
      @POPNULL
      @PUSH 1
      @JMP strncmpExit
   @ENDIF
   @INCI SrcPtr
   @INCI DstPtr
   @POPNULL
   @POPNULL
@Next Index
# We only get here if both are the same
@PUSH 0
:strncmpExit
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
# 
# itos is an Integer to String function
# Function itos(StrPtr,Invalue,InBase)   Base=10 for decimal, 8 for octal or 16 for hex
# Vars

:itos
@PUSHRETURN
=Base Var01
=Invalue Var02
=StrPtr Var03
=NegFlag Var05
=RevIndex Var06
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@POPI Base
@POPI Invalue
@POPI StrPtr

@MA2V 0x3000 WorkBuff   # Preload Workbuf with zero and nulls
@MA2V 0 WorkBuff+2
@MA2V 0 WorkBuff+4
@MA2V 0 NegFlag
@PUSHI Invalue
@IF_LT_A 0
   # Is Negative
   @MA2V 1 NegFlag
   @COMP2 @POPI Invalue   # Invale = abs(Invale)
@ELSE
   @POPNULL
@ENDIF
@MA2V WorkBuff RevIndex
:isMainLoop
@PUSHI Invalue
@IF_GT_A 0
   @PUSHI Base
   @CALL DIV
   @POPI Invalue    # Invalue=Invalue/Base, remainder on stack
   @AND 0xf         # Bases larger than 16 unsupported
   @ADD 0x30
   @IF_GT_A 0x39
      # Hex number jump to Letters A-F
      @ADD 0x7      # 'A' is 0x41 so add 7 to 0x3A to make it 0x41
   @ENDIF
   @POPII RevIndex
   @INCI RevIndex
   @JMP isMainLoop
@ENDIF
@POPNULL
@IF_EQ_AV 0 Invalue   #Handle the zero case
   @PUSH "0\0"
   @POPII StrPtr
@ENDIF
@IF_EQ_VA NegFlag 1
   @PUSH "-" $$0     # Push '-' to result
   @POPII StrPtr
   @INCI StrPtr
@ENDIF
:ReverseLoop
@PUSHI RevIndex
@IF_GT_A WorkBuff
   @POPNULL
   @DECI RevIndex
   @PUSHII RevIndex
   @POPII StrPtr
   @PUSH 0
   @POPII RevIndex
   @INCI StrPtr
   @JMP ReverseLoop
@ENDIF
@POPNULL
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
# stoi, reverse of itos, takes text version of number and returns integer.
# Function stoi(string)
# Vars

:stoi
@PUSHRETURN
#
=StrPtr Var01
=NegFlag Var02
=Base Var03
=Invalue Var04
=Multiplier Var05
=Length Var06
#
@PUSHLOCALI StrPtr
@PUSHLOCALI NegFlag
@PUSHLOCALI Base
@PUSHLOCALI Invalue
@PUSHLOCALI Multiplier
@PUSHLOCALI Length

#

@POPI StrPtr
@MA2V 0 NegFlag
@MA2V 10 Base     # Default Base is ten
@MA2V 0 Invalue
@MA2V 1 Multiplier
@PUSHI StrPtr @CALL strlen @POPI Length
@PUSHII StrPtr @AND 0xff
@IF_EQ_A "-\0"      # Negative Sige in ASCII code
   @POPNULL
   @MA2V 1 NegFlag
   @INCI StrPtr
   @DECI Length
@ELSE
   @POPNULL
@ENDIF
@PUSHI Length
@IF_GT_A 2
   @POPNULL
   # There no point of looking for 0x type codes if length is less 3
   @PUSHII StrPtr   @AND 0xff
   @IF_EQ_A 0x0030  # Is first character a '0'?
      @POPNULL
      @INCI StrPtr
      @PUSHII StrPtr @AND 0xff   # Get second character like for 0xHHHH
      @SWITCH
         @CASE "x\0"      # Lower case 'x' for hex
            @MA2V 16 Base
            @INCI StrPtr
	    @DEC2I Length
            @CBREAK
         @CASE "o\0"      # Lower case 'o' for octal
            @MA2V 8 Base
            @INCI StrPtr
	    @DEC2I Length
            @CBREAK
         @CASE "b\0"     # Lower case 'b' for binary
            @MA2V 2 Base
            @INCI StrPtr
	    @DEC2I Length
            @CBREAK
         @CDEFAULT
            @MA2V 10 Base # This is for cases where the first character was zero but net ment to indicate Base
            @DECI StrPtr
            @CBREAK
      @ENDCASE
   @ENDIF
@ENDIF
@POPNULL
@PUSHI Length
@WHILE_NOTZERO
   @DECI Length
   @POPNULL
   @PUSHI StrPtr @ADDI Length @PUSHS @AND 0xff  # Fetches StrPtr[Length]
   @SUB "0\0"
   @IF_EQ_VA Base 16  # Are we dealign with Hex numbers?
      @POPNULL
      @IF_GE_A 10    # Was it > 10
         @SUB 7 # In which case we need to deail with the ASCII gab between '9' and 'A' down by 7
      @ENDIF
   @ENDIF
   @PUSHI Multiplier
   @CALL MULU
   @ADDI Invalue @POPI Invalue   # Invalue = str[index]*Multiplier + Invalue
   @PUSHI Base @PUSHI Multiplier @CALL MULU @POPI Multiplier # Multiplier *= Base
   @PUSHI Length
@ENDWHILE
@POPNULL
@PUSHI Invalue
@PUSHI NegFlag
@IF_NOTZERO
   @POPNULL
   @COMP2
@ELSE
   @POPNULL
@ENDIF
@POPLOCAL Length
@POPLOCAL Multiplier
@POPLOCAL Invalue
@POPLOCAL Base
@POPLOCAL NegFlag
@POPLOCAL StrPtr
@POPRETURN
@RET
#
#
# Function stoifirst(strptr) is very  much like stoi but does not require the string to terminat on a null
# Which in practical data processing is most of the cases where numbers are enbeded into text.
:stoifirst
@PUSHRETURN
=StrPtrA Var01
=StrPtrB Var02
=SrcPtr Var03
=DstPtr Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04

@POPI StrPtrA
# Move StrPtrA until nul, or '-' or '+' or digit
@MA2V 0 StrPtrB      # Mark this so we know if none found
@MA2V 0 DstPtr       # Will hold final result
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   @PUSHII StrPtrA @AND 0xff
   @IF_EQ_A "-\0"
      @PUSH 1
#      @INCI StrPtrA
   @ELSE
      @IF_EQ_A "+\0"
         @PUSH 1
         @INCI StrPtrA         
      @ELSE
         @IF_GE_A "0\0"
            @IF_LE_A "9\0"
               @PUSH 1
            @ENDIF
         @ELSE
            @IF_EQ_A 0
               @PRT "Warning: String did not countain any digits"
               @PUSH 0               
            @ENDIF
            
         @ENDIF
      @ENDIF
   @ENDIF
   @IF_EQ_A 1
      @MV2V StrPtrA StrPtrB # Save start position of number
      @PUSH 0   # Exit While Loop
   @ELSE
      @POPNULL
      @INCI StrPtrA
      @PUSH 1   # Continue While Loop
   @ENDIF
@ENDWHILE
@POPNULL
@IF_EQ_AV 0 StrPtrB
   # No numbers found in string. Return zero
   @PRT "Warning: String did not countain any digits"
@ELSE
   @INCI StrPtrA # If first character had been + or - this will skip it.
   @POPNULL
   @PUSHII StrPtrA @AND 0xff
   @WHILE_NOTZERO
      @IF_GE_A "0\0"
          @IF_LE_A "9\0"
             @POPNULL
             @PUSH 0  # Was a digit, continue
          @ENDIF
      @ENDIF
      @IF_EQ_A 0
         #Digit found just continue.
         @INCI StrPtrA
         @POPNULL
         @PUSHII StrPtrA @AND 0xff
      @ELSE
         @POPNULL
         @PUSH 0
         #Non Digit found, or end of number found.
      @ENDIF
   @ENDWHILE
   # Save what ever word was at StrPtrA and replace will Null
   @POPNULL
   @PUSHII StrPtrA @POPI SrcPtr
   @PUSH 0 @POPII StrPtrA
   @PUSHI StrPtrB
   @CALL stoi
   @POPI DstPtr
   @PUSHI SrcPtr @POPII StrPtrA # Restore where we Null'ed         
@ENDIF
@POPNULL
@PUSHI DstPtr     # Result
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
#
# Function strcmp is just an alternative for strncmp with a super sized 'n'
:strcmp
@PUSHRETURN
@PUSH 0x7fff
@CALL strncmp
@POPRETURN
@RET
#
# Function memcpy(dest,src,size) Copies size bytes from src to dest
# 
:memcpy
@PUSHRETURN
=DstPtr Var01
=SrcPtr Var02
=Length Var03
=Index01 Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
#
@POPI Length
@POPI SrcPtr
@POPI DstPtr

# Default is to copy from 0 to length
# but if DstPtr falls in range srcptr to srcptr+length, then use reverse copy.
@IF_EQ_AV 0 Length
   # zero length? Just exit.
@ELSE
   @IF_EQ_VV SrcPtr DstPtr
       # Src == Dst, just exit.
   @ELSE
       # And logic test requires nesting two IF blocks
       @PUSH 1     # Default is loop forward
       @PUSHI DstPtr
       @IF_GT_V SrcPtr
          # dstptr > strptr
          @PUSHI SrcPtr
          @ADDI Length
          @IF_LT_S
             # AND dstptr < (srcptr+length)
             @POPNULL @POPNULL @POPNULL
             @PUSH 0   # Reverse Order
          @ELSE
             @POPNULL @POPNULL
          @ENDIF
       @ELSE
          @POPNULL
       @ENDIF
       #
       @IF_NOTZERO
         @ForIA2V Index01 0 Length
             @PUSHI DstPtr @ADDI Index01 @PUSHS @AND 0xff00
             @PUSHI SrcPtr @ADDI Index01 @PUSHS @AND 0xff
             @ORS
             @PUSHI DstPtr @ADDI Index01 @POPS
         @Next Index01
         @POPNULL
       @ELSE
         # Reverse order.
         @ForIV2A Index01 Length 0
             @PUSHI DstPtr @ADDI Index01 @PUSHS @AND 0xff00
             @PUSHI SrcPtr @ADDI Index01 @PUSHS @AND 0xff
             @ORS
             @PUSHI DstPtr @ADDI Index01 @POPS
         @NextBy Index01 -1
         @POPNULL
       @ENDIF
   @ENDIF
@ENDIF
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
# strchr(string,word) finds character (lower 8 bits) from word in string, returns pointer to occurance, 0 is not found
:strchr
@PUSHRETURN
=Invalue Var01
=DstPtr Var02
=StrPtr Var03
@PUSHLOCALI StrPtr
@PUSHLOCALI DstPtr
@PUSHLOCALI Invalue
@ADD 0xff             # We only care about the low order byte
@POPI Invalue
@POPI StrPtr
@MA2V 0 DstPtr        # Set Dst to zero so if not found it will be null
@PUSHII StrPtr
@AND 0xff
@WHILE_NOTZERO
   @IF_EQ_V Invalue   # Found match, point DST to it, and drop out of while 'early'
      @POPNULL
      @MV2V StrPtr DstPtr
      @JMP BreakWhile
   @ENDIF
   @POPNULL
   @INCI StrPtr
   @PUSHII StrPtr
   @AND 0xff
@ENDWHILE
@POPNULL
:BreakWhile
@PUSHI DstPtr
@POPLOCAL StrPtr
@POPLOCAL DstPtr
@POPLOCAL Invalue
@POPRETURN
@RET
#
# strrchr(string,word) Returns pointer to 'last' instance of character in string, null it not found.
:strrchr
@PUSHRETURN
=Invalue Var01
=StrPtr Var02
=DstPtr Var03
@PUSHLOCALI Invalue
@PUSHLOCALI StrPtr
@PUSHLOCALI DstPtr
@ADD 0xff
@POPI Invalue
@POPI StrPtr
@MA2V 0 DstPtr
@MV2V StrPtr StrPtrA    #Backup StrPtr for finding end case
@PUSHI StrPtr
@CALL strlen            #Move StrPtr to the end of the string.
@ADDI StrPtr
@POPI StrPtr
@PUSHI StrPtrA          #Put the orginal start of String on stack and loop back to it
@WHILE_NEQ_A StrPtr
   @PUSHII StrPtr
   @AND 0xff
   @IF_EQ_V Invalue     # Found match, point DST to it, and drop out of while 'early'
      @POPNULL
      @MV2V StrPtr DstPtr
      @JMP BreakWhileRev
   @ENDIF
   @POPNULL   
   @DECI StrPtr
@ENDWHILE
:BreakWhileRev
@PUSHI DstPtr
@POPLOCAL DstPtr
@POPLOCAL StrPtr
@POPLOCAL Invalue
@POPRETURN
@RET
#
# strstr(string,substring) Return pointer in string, where substring can be found. NULL if no match
# Extra Local Variables
:strstr
@PUSHRETURN
=ssStrA Var01
=ssStrB Var02
=ssMaxLength Var03
=ssIndex Var04
=ssLength Var05
=ssDstPtr Var06
@PUSHLOCALI ssStrA
@PUSHLOCALI ssStrB
@PUSHLOCALI ssMaxLength
@PUSHLOCALI ssIndex
@PUSHLOCALI ssLength
@PUSHLOCALI ssDstPtr
#
@POPI ssStrB         # SrtB is the SubString
@POPI ssStrA         # StrA is the Source String
@PUSHI ssStrB
@CALL strlen
@PUSHI ssStrA
@CALL strlen
@IF_LT_S       # len(StringB) is < len(StringA)
   @POPI ssMaxLength      # Full length of source string
   @POPI ssLength         # Length of SubString
   @MV2V ssStrA ssIndex  # Index will be pointer In String we Start Search.
   @PUSHI ssStrA @ADDI ssMaxLength @SUBI ssLength  # We only need to search max of MaxLength-Length
   @POPI ssDstPtr         # Loop will either find match or continue until Index==DstPtr
   @PUSHI ssIndex
   @WHILE_NEQ_V ssDstPtr
      @POPNULL
      @PUSHI ssIndex @PUSHI ssStrB @PUSHI ssLength
      @CALL strncmp
      @IF_ZERO          # There was a match, return the Index
         @POPNULL
	 @PUSHI ssIndex
	 @JMP Endstrstr
      @ENDIF
      @POPNULL
      @INCI ssIndex
      @PUSHI ssIndex
    @ENDWHILE
    # No Math if it falls here.
    @POPNULL
    @PUSH 0
@ELSE
    # pattern was larger than string, if it falls here.
    @POPNULL @POPNULL
    @PUSH 0
@ENDIF
:Endstrstr
@POPLOCAL ssDstPtr
@POPLOCAL ssLength
@POPLOCAL ssIndex
@POPLOCAL ssMaxLength
@POPLOCAL ssStrB
@POPLOCAL ssStrA
@POPRETURN
@RET


###########
#
# Function ISAlphaNum(String):T|F
# Return T|F if first char in string is in set [A-Za-z0-9_]
:ISAlphaNum
@PUSHRETURN
@PUSHS
@AND 0xff
@SWITCH
@CASE_RANGE "a\0" "z\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "A\0" "Z\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "0\0" "9\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "_\0"
   @PUSH 1
   @CBREAK
@CDEFAULT
   @PUSH 0
   @CBREAK
@ENDCASE
@SWP
@POPNULL
@POPRETURN
@RET
#
# Function IsAlpha(string):T|F
# Return T|F if first char in string is in set [A-Za-z]
:ISAlpha
@PUSHRETURN
@PUSHS
@AND 0xff
@SWITCH
@CASE_RANGE "a\0" "z\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "A\0" "Z\0"
   @PUSH 1
   @CBREAK
@CDEFAULT
   @PUSH 0
   @CBREAK
@ENDCASE
@SWP
@POPNULL
@POPRETURN
@RET

#
# Function ISNumeric(String):T|F
# Return T|F if first char in string is in set [0-9]
:ISNumeric
@PUSHRETURN
@PUSHS
@AND 0xff
@SWITCH
@CASE_RANGE "0\0" "9\0"
   @PUSH 1
   @CBREAK
@CDEFAULT
   @PUSH 0
   @CBREAK
@ENDCASE
@SWP
@POPNULL
@POPRETURN
@RET

# strfndc searchs string for single character returns ptr to that character
# (strstr but with character constant on stack)
:sfReturn 0
:ShortString 0 0
:strfndc
@POPI sfReturn       # We're not using PUSHRETURN to preserve flags
@POPI ShortString
@PUSH ShortString
@CALL strstr
@PUSHI sfReturn
@RET

# strtok(InString, Delim) searchs string and replaces delim(s) with null
# keeps an internal pointer so when string is null it will continue from
# where it last left off. When original string is complete, will also return null
:int_sptr 0
:strtok
@PUSHRETURN
=FoundFlag Var01
=InString Var02
=Delim Var03
=Index1 Var04
=TolkenHead Var05
=DelimCurse Var06
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@POPI Delim
@POPI InString
@IF_EQ_AV 0 InString   # If Null, try to continue to use old int_sptr
   @MV2V int_sptr InString
@ENDIF
#
@PUSHII InString @AND 0xff

@IF_ZERO
   # No more tolkens left to parse.
   # just leave the zero as the return value of NULL
@ELSE
   @MV2V InString TolkenHead
   @WHILE_NOTZERO
       @MA2V 0 FoundFlag
       @MA2V 0 Index1
       @MV2V Delim DelimCurse  # Set Cursor to loop though Delim
       @PUSHII DelimCurse @AND 0xff
       @WHILE_NOTZERO
           @IF_EQ_S
               # Found, replace with null and end loop
               @POPNULL    # Pops off DelimCurse, but leaves Instring[x]
               @PUSHII InString @AND 0xff00
               @POPII InString
               @PUSH 0
               @MA2V 1 FoundFlag
            @ELSE
               @POPNULL
               @INCI DelimCurse
            @ENDIF
            @PUSHII DelimCurse @AND 0xff    # Will exit inner loop when DelimCurse -> null            
        @ENDWHILE
        @POPNULL     # Pops off the 0 that terminate while
        @POPNULL     # Pop off Instring[x]
        @IF_EQ_AV 0 FoundFlag
           # Did not find match, try next character
           @INCI InString
           @PUSHII InString @AND 0xff  # continue while (unless InString[x]==null)
        @ELSE
           # Found match. So end the outer while loop.
           @INCI InString        # Move to the null.           
           @PUSH 0
        @ENDIF
   @ENDWHILE
   @POPNULL   # Pops off zero that ended while.
   @POPNULL
   @PUSHI TolkenHead    # We return the TolkenHead
   @MV2V InString int_sptr   # Save for future calls with InString of NULL
@ENDIF
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#
# This string split returns from an input string a HeapManager array of strings
# Function splitstr(instring,splitlist,heapid):(heaparray,size_array)
:splitstr
@PUSHRETURN
=instring Var01
=splitlist Var02
=HeapIn Var03
=SSCount Var04
=Index1 Var05
=Index2 Var06
=SplitLen Var07
=NewArray Var08

@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
#
@POPI HeapIn
@POPI splitlist
@POPI instring
#
# First figure out how many substrings will be needed to be created.
@PUSHI splitlist @CALL strlen @POPI SplitLen  # SplitLen=length(splitlist)
@MA2V 0 SSCount
@PUSHI instring
@CALL strlen
@ForIupA2S Index1 0     # A2S means 0 to current value on stack, which is poped off at the start.
   @PUSHI instring
   @ADDI Index1
   @PUSHS @AND 0xff
   @ForIupA2V Index2 0 SplitLen
      @PUSHI splitlist
      @ADDI Index2
      @PUSHS @AND 0xff
      @IF_EQ_S
         @INCI SSCount       # If  == then SSCOunt++
      @ENDIF
      @POPNULL
   @Next Index2
   @POPNULL
@Next Index1
# Have to consider what to do if the deliminator is also the first character as that would make
# the first substring a null lenth string. Better to drop it.
@ForIupA2V Index2 0 SplitLen
   @PUSHII instring @AND 0xff
   @PUSHI splitlist
   @ADDI Index2
   @PUSHS @AND 0xff      # Just look at 1st character.
   @IF_EQ_S
      # Match, so move start of instring past the split character.
      @INCI instring   # This will make instring start at first non split character.
      @POPNULL @POPNULL
      @DECI Index2     # We do this as we're not seeing if next instring is also a split character.
      @DECI SSCount    # If this happens then our SSCount will be off.
   @ELSE
      @POPNULL @POPNULL        # Remove the failed match characters
   @ENDIF
@Next Index2
#
@IF_EQ_AV 0 SSCount
   # Just one long string, no sub strings.
   @INCI SSCount
@ENDIF
#

#
#
# Create an array of SSCount*2 in length
@PUSHI HeapIn
@PUSHI SSCount @ADD 1 @SHL
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error, while creating split string list." @END @ENDIF
@POPI NewArray
# Make sure the END of Heap Marker is set to 0
@PUSH 0
@PUSHI SSCount @ADD 1 @SHL @ADDI NewArray
@POPS
#
# Now use the strtolk function to split and copy the strings into their array location
@PUSH 1
@MA2V 0 Index1       # This will be array index.
@PUSHI instring
@PUSHI splitlist
@CALL strtok
# Save where the next instring will be for next loop
@WHILE_NOTZERO
    @IF_NOTZERO
       # Create a new heap string of len first token
       @POPI Index2
       @PUSHI HeapIn
       @PUSHI Index2
       @CALL strlen @ADD 1     # extra space for null termination
       @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1065, while creating split string list." @END @ENDIF       
       @PUSHI NewArray @ADDI Index1
       @POPS               # Array[Index1] == ^newstring
       # Now copy the old Index2 tolk into the newstring space
       @PUSHI NewArray @ADDI Index1 @PUSHS
       @PUSHI Index2
       @CALL strcpy
       #
       # Now inc for next entry.
       @INC2I Index1
       @PUSH 0
       @PUSHI splitlist
       @CALL strtok
    @ENDIF
@ENDWHILE
@POPNULL
:Debug05
@PUSH 0 @PUSHI NewArray @PUSHI SSCount @SHL @ADDS @POPS
@PUSHI NewArray
@PUSHI SSCount
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###############################################
# Function SplitDeltete(object,heapid)
# Deletes the object which is a list created by splitstr
# (object is an null terminated array of pointers to heap strings)
:SplitDelete
@PUSHRETURN
=Object Var01
=HeapID Var02
=Index1 Var03
=HeapLen Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
#
@POPI HeapID
@POPI Object
#
@MA2V 0 Index1
@PUSHI Index1 @SHL @ADDI Object
@PUSHS
@WHILE_NOTZERO
   @PUSHI HeapID
   @SWP
   @CALL HeapDeleteObject @IF_GT_A 0 @PRT "Error Deleteing Heap Object: " @PRTTOP @ENDIF
   @POPNULL
   @INCI Index1
   @PUSHI Index1 @SHL @ADDI Object @PUSHS
@ENDWHILE
@POPNULL
@PUSHI HeapID
@PUSHI Object
@CALL HeapDeleteObject @IF_GT_A 0 @PRT "Error Deleteing Heap Object: " @PRTTOP @ENDIF
@POPNULL
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###################################################
# Function strUpCase(instring)
# Changes all lowercase letters instring to uppercase
:strUpCase
@PUSHRETURN
=instring Var01
=Index1 Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI instring
@PUSHI instring
@CALL strlen
@WHILE_NOTZERO
   @PUSHII instring
   @AND 0xff
   @IF_GE_A "a\0"
      @IF_LE_A "z\0"
         @SUB 32
      @ENDIF
   @ENDIF
   @PUSHII instring
   @AND 0xff00
   @ADDS
   @POPII instring
   @INCI instring
   @SUB 1
@ENDWHILE
@POPNULL
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###################################################
# Function strLowCase(instring)
# Changes all Uppercase letters instring to lowercase
:strLowCase
@PUSHRETURN
=instring Var01
=Index1 Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI instring
@PUSHI instring
@CALL strlen
@WHILE_NOTZERO
   @PUSHII instring
   @AND 0xff
   @IF_GE_A "A\0"
      @IF_LE_A "Z\0"
         @ADD 32
      @ENDIF
   @ENDIF
   @PUSHII instring
   @AND 0xff00
   @ADDS
   @POPII instring
   @INCI instring
   @SUB 1
@ENDWHILE
@POPNULL
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

? HEXDUMP
# We only include this code if HEXDUMP is defined, otherwise we save space by not using it.
G HexDump
@RET


ENDBLOCK
