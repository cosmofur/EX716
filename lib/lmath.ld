L string.ld
################
# lmath.ld library
#
# New update to lmath, going to change some of the nameing conventions to be more compatable
# with other libraries.
#
# New rules:
# Major functions will have the format
#   FUNC[IV][IV][IV]
#example
#   ADD32VVV      means all three arguments are the address where 32 bit values will be found/stored
#   SUB32VII      means arg 1 is address, but args 2 and 3 are pointers to indirect locations.
#   Same works for 2 argument functions
#   RTR32VI or RTL32II
#
# Provide procedures to do basic math on 32 bit numbers
#
# Functions come in two flavors
# 3 pointer functions on HW stack in order:
#  A-PTR, B-PTR, Result-PTR
# 2 pointer functions
#  A_PTR Result_PTR
#
# The PTR's point to 4 bytes of memory, Little-Endian
#
# 3 Pointer functions are:
#   ADD32, SUB32, CMP32, AND32, OR32
# 2 Pointer functions are:
#   RTR32, RTL32, INV32
#
# Helpful 32bit math macros (Note some of these 'macros' take up 25 to 30 bytes of memory, each
# time they are assembled. So if you need to call them in many diffrent places in your code. It
# might be more effient to use a function call)
# COPY32VV   Label32    Label32
# COPY32VIV  [Label]    Label          (will be deprecated)
#      New Name: COPY32IV
# MOVE32AV   $$$Number  Label
# MOVE32AVI  $$$Number  [Label32]     (will be deprecated)
#      New Name MOVE32AI
# INT2LONG   Label16    Label32        (will be deprecated)
#      New Name INT2LONGVV
# INT2LONGI  Label16    [label32]       (will be deprecated)
#      New Name INT2LONGVI
# INT2ILONG  [Label16]  label32          (will be deprecated)
#      New Name INT2LONGIV
# LONG2INT   Label32    Label16          (will be deprecated)
#      New Name LONG2INTIV
#
#
      
#
! MATH32DEFINE
M MATH32DEFINE 1
@PRTLN "Invalid Entry:"
@END
# Define the globals
G ADD32 G SUB32 G CMP32 G AND32 G OR32 G RTR32 G RTL32 G INV32
G DIV32 G DIV32U G MUL32 G i32tos G stoi32 G INT2LONG G LONG2INT
G PRT32BIN G PRT32HEX G DIV32VVVV G MUL32VVV
G ADD32VVV G SUB32VVV G CMP32VV G AND32VVV G OR32VVV G RTR32VV G RTL32VV G INV32VV
G INT2LONGVV

@JMP ENDLMATH
# Global Variables
:A_PTR 0
:AH_PTR 0
:B_PTR 0
:BH_PTR 0
:C_PTR 0
:CH_PTR 0
:ReturnAdr 0
:AltReturn 0
:Aval
:Aval_Low 0
:Aval_High 0
:Bval
:Bval_Low 0
:Bval_High 0
:Cval
:Cval_Low 0
:Cval_High 0
:Scr
:Scr_Low 0
:Scr_High 0
:FlagSave 0
# Constants 32b 1 and 0
:One_Val 1 0
:Zero_Val 0 0
M ADD32VVV @PUSH %1 @PUSH %2 @PUSH %3 @CALL ADD32VVV
M ADD32III @PUSHI %1 @PUSHI %2 @PUSHI %3 @CALL ADD32VVV
M ADD32IIV @PUSHI %1 @PUSHI %2 @PUSH %3 @CALL ADD32VVV
M ADD32IVI @PUSHI %1 @PUSH %2 @PUSHI %3 @CALL ADD32VVV
M ADD32IVV @PUSHI %1 @PUSH %2 @PUSH %3 @CALL ADD32VVV
M ADD32VII @PUSH %1 @PUSHI %2 @PUSHI %3 @CALL ADD32VVV
M ADD32VIV @PUSH %1 @PUSHI %2 @PUSH %3 @CALL ADD32VVV
M ADD32VVI @PUSH %1 @PUSH %2 @PUSHI %3 @CALL ADD32VVV


# The Nameing convention was changed, so the original explaination that was here, is now deprecated
#
# New syntax means
#      Paramters in their order
#      V - value passed is the direct address where the 32 bit value starts
#      I - value passed is a 16b pointer to where the 32 bit value starts
#      A - is used when an direct constant will be the value stored.
#
# Because the following are a mix of 16 and 32 bit values, the rules are a bit diffrence.
# For 16 bit number part
#    V means pass the lable where the data is stored
#    I points pointer that points to the data
M INT2LONGVV @PUSH %1 @PUSH %2 @CALL INT2LONGVV
M INT2LONGVI @PUSH %1 @PUSHI %2 @CALL INT2LONGVV
M INT2LONGIV @PUSHI %1 @PUSH %2 @CALL INT2LONGVV
M INT2LONGII @PUSHI %1 @PUSHI %2 @CALL INT2LONGVV
M INT2LONG @PUSH %1 @PUSH %2 @CALL INT2LONGVV


#
# V -> V
M COPY32VV \
     @PUSHI %1 @POPI %2 @PUSHI %1+2 @POPI %2+2
# V -> V_PTR
M COPY32VI \
      @PUSHI %1 @PUSH %1 @ADD 2 @PUSHS \
      @PUSHI %2 @ADD 2 @POPS \
      @PUSHI %2 @POPS
M COPY32VIV @COPY32VI %1 %2
# V_PTR -> V
M COPY32IV \
      @PUSHI %1 @PUSHS @PUSHI %1 @ADD 2 @PUSHS \
      @POPI %2+2 @POPI %2
M COPY32IVV @COPY32IV %1 %2
# V_PTR -> V_PTR
M COPY32II \
      @PUSHI %1 @PUSHS @PUSHI %1 @ADD 2 @PUSHS \
      @PUSHI %2 @ADD 2 @POPS \
      @PUSHI %2 @POPS
M COPY32IVIV @COPY32II %1 %2


# We call the 'Constant' to V 'MOVE's rathar than COPY since it requires
# diffrent logic to handle a fixed constants which are first being defined in this same
# macro and normally that source number will not be directly refrenced again.
# these 'MOVE's are less efficent than COPY's
#  MOVE32AV is the ruff 32bit equivalent of @MA2V
M MOVE32AV @JMP %0SkipOver :%0C1 $$$%1 \
           :%0SkipOver @PUSHI %0C1 @PUSH %2 @POPS \
	   @PUSHI %0C1+2 @PUSH %2+2 @POPS

M MOVE32AI @JMP %0SkipF :%0C1 $$$%1 \
           :%0SkipF @PUSHI %0C1 @PUSHI %2 @POPS \
	   @PUSHI %0C1+2 @PUSHI %2 @ADD 2 @POPS
M MOVE32AVI @MOVE32AI %1 %2

#
# Common 16to32 bit functions for common operations.
#
# These are functions which take one 16 bit number and one 32 bit acumulator and
# lets you do the most common functions to them. 
#
# Pattern is take 16 %1 turn into 32 bit %0LW1 and then apply function of 
M ADDWLAV @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @ADD32VVV %2 %0LW1 %2
M ADDWLIV @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @ADD32VVV %2 %0LW1 %2
M ADDWLAI @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @ADD32IVI %2 %0LW1 %2
M ADDWLII @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @ADD32IVI %2 %0LW1 %2
#########
M SUBWLAV @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @SUB32VVV %2 %0LW1 %2
M SUBWLIV @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @SUB32VVV %2 %0LW1 %2
M SUBWLAI @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @SUB32IVI %2 %0LW1 %2
M SUBWLII @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @SUB32IVI %2 %0LW1 %2
###################
M MULWLAV @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @MUL32VVV %2 %0LW1 %2
M MULWLIV @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @MUL32VVV %2 %0LW1 %2
M MULWLAI @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @MUL32IVI %2 %0LW1 %2
M MULWLII @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @MUL32IVI %2 %0LW1 %2
####################
# The DIVision requires 3 parameters 1 Word and 2 Longs, Extra long is for remainder, and must be of type 'V' rather than 'I'
# Which just means the remainder must point directly to address of unique 32 store, not a pointer.
M DIVWLAV @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @DIV32VVVV %2 %0LW1 %2 %3
M DIVWLIV @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @DIV32VVVV %2 %0LW1 %2 %3
M DIVWLAI @JMP %0JMP \
         :%0W1 %1 :%0LW1 0 0 \
         :%0JMP @INT2LONG %0W1 %0LW1 \
         @DIV32IVIV %2 %0LW1 %2 %3
M DIVWLII @JMP %0JMP :%0LW1 0 0 \
          :%0JMP @INT2LONG %1 %0LW1 \
          @DIV32IVIV %2 %0LW1 %2 %3
          





# Function ADD32VVV(A_Var,B_Var,C_Var)
#  ADD(A,B,C)  Modifies C, removes all from Stack
:ADD32         # Note that 32 bit math does NOT set any flags so we can't directly use it for 64 bit math.
:ADD32VVV
@POPI ReturnAdr
@POPI C_PTR
@POPI B_PTR    
@POPI A_PTR
@PUSHII A_PTR     # Fetch low part of A from ptr
@POPI Aval_Low
@PUSHI A_PTR
@ADD 2
@PUSHS            # Fetch high part of A from ptr
@POPI Aval_High
@PUSHII B_PTR     # Fetch low part of B from ptr
@POPI Bval_Low
@PUSHI B_PTR
@ADD 2
@PUSHS            # Fetch high part of B from ptr
@POPI Bval_High
@PUSHI Aval_Low    # Start the Math A on stack
@PUSHI Bval_Low
@ADDS
@POPII C_PTR       # Save the Low results to Low C
@PUSHI Aval_High   # Whether or not there was carry, push High A on stack
@JMPNC ADD32NoCarry
@PUSH 1     # There was a Carry, so add one
@ADDS
:ADD32NoCarry
@PUSHI Bval_High
@ADDS       # High part results on stack.
@INC2I C_PTR      # Move C_PTR to High Part of C
@POPII C_PTR     # Save A+B High to C High
@PUSHI ReturnAdr
@RET
#
M SUB32VVV @PUSH %1 @PUSH %2 @PUSH %3 @CALL SUB32VVV
M SUB32III @PUSHI %1 @PUSHI %2 @PUSHI %3 @CALL SUB32VVV
M SUB32IIV @PUSHI %1 @PUSHI %2 @PUSH %3 @CALL SUB32VVV
M SUB32IVI @PUSHI %1 @PUSH %2 @PUSHI %3 @CALL SUB32VVV
M SUB32IVV @PUSHI %1 @PUSH %2 @PUSH %3 @CALL SUB32VVV
M SUB32VII @PUSH %1 @PUSHI %2 @PUSHI %3 @CALL SUB32VVV
M SUB32VIV @PUSH %1 @PUSHI %2 @PUSH %3 @CALL SUB32VVV
M SUB32VVI @PUSH %1 @PUSH %2 @PUSHI %3 @CALL SUB32VVV
# Function SUB
# SUB(A,B,C)  Modfies C, pops all from stack
:SUB32
:SUB32VVV
@POPI ReturnAdr
@POPI C_PTR
@POPI B_PTR
@POPI A_PTR
@PUSHII A_PTR @PUSHII B_PTR          # Put low part on stack
@INC2I B_PTR @INC2I A_PTR # We do the inc2 here to avoid messing up flags
@SUBS
@POPII C_PTR
@JMPNC SNoBorrow
# Case for Borrow
  @PUSHII A_PTR
  @PUSHII B_PTR
  @SUBS
  @SUB 1      # Barrow bit from High A  
  @INC2I C_PTR            # C wasn't inc2 because we still needed it for the POP
  @POPII C_PTR
  @JMP SPastNoBorrow
:SNoBorrow
  @PUSHII A_PTR @PUSHII B_PTR
  @INC2I C_PTR            # C wasn't inc2 because we still needed it for the POP
  @SUBS
  @POPII C_PTR
:SPastNoBorrow
@PUSHI ReturnAdr
@RET
#
M CMP32VV @PUSH %1 @PUSH %2 @CALL CMP32VV
M CMP32VI @PUSH %1 @PUSHI %2 @CALL CMP32VV
M CMP32IV @PUSHI %2 @PUSH %2 @CALL CMP32VV
M CMP32II @PUSHI %1 @PUSHI %2 @CALL CMP32VV
#
# Function CMP32VV(A_Var, B_Var)
# CMP32(A,B) Pops A and B from stack, replaces with -1,0,1
:CMP32
:CMP32VV
@POPI C32Return
@PUSH C32Result
@CALL SUB32   # We are Using SUB32 to Subtract A - B > Temp Result
#  Test if High Worked Highest Bit is set, if so, it's negative.

@PUSHI C32Result+2
@AND 0x8000
@IF_NOTZERO      # Sign bit is set
   @POPNULL 
   @PUSH 0 @CMP 1 @POPNULL   # Force the N flag to be set.
   @PUSH -1
   @JMP C32END
@ENDIF
@POPNULL
@PUSHI C32Result+2 
@IF_ZERO  # High word is zero
   @POPNULL
   @PUSHI C32Result
   @IF_ZERO  # Low Word is also zero
      @POPNULL
      @PUSH 0
      @JMP C32END
   @ENDIF
@ENDIF
@POPNULL
# IF neigher Zero or Negative, must be positive.
@PUSH 1 @CMP 0 # Do this for force flags to be nutral
:C32END
@PUSHI C32Return
@RET
:C32Return 0
:C32Result 0 0
#
M RTR32VV @PUSH %1 @PUSH %2 @CALL RTR32VV
M RTR32VI @PUSH %1 @PUSHI %2 @CALL RTR32VV
M RTR32IV @PUSHI %1 @PUSH %2 @CALL RTR32VV
M RTR32II @PUSHI %1 @PUSHI %2 @CALL RTR32VV
# Function RTR32
# RTR32 Rotate Right 32 bit version 2 Parms ptr to A and Return to B
# Call RTR32(A,B)Rotats A saves to B
:RTR32
:RTR32VV
@POPI ReturnAdr
@POPI B_PTR
@POPI A_PTR

# High Byte
@PUSHI A_PTR @ADD 2 @PUSHS
@FCLR
@RTR
@FSAV @POPI FlagSave     # Save any Carry bit
@PUSHI B_PTR @ADD 2 @POPS
# Low Byte
@PUSHII A_PTR
@PUSHI FlagSave @FLOD    # Restore Carry Bit
@RRTC
@POPII B_PTR
@PUSHI ReturnAdr
@RET
#
M INV32VV @PUSH %1 @PUSH %2 @CALL INV32VV
M INV32VI @PUSH %1 @PUSHI %2 @CALL INV32VV
M INV32IV @PUSHI %1 @PUSH %2 @CALL INV32VV
M INV32II @PUSHI %1 @PUSHI %2 @CALL INV32VV
# Invert Bits
# Function INV32(A_Var,B_Var)
# INV32(A,B) Inverts A saves to B
:INV32
:INV32VV
@POPI IVReturnAdr
@POPI IV32Bval
@POPI IV32Aval
@PUSHI IV32Aval
@PUSHS @INV @PUSHI IV32Bval @POPS  # Note modification is to where Aval points to, not Aval itself.
@PUSHI IV32Aval @ADD 2
@PUSHS @INV @PUSHI IV32Bval @ADD 2 @POPS
@PUSHI IVReturnAdr
@RET
:IVReturnAdr 0
:IV32Aval 0
:IV32Bval 0

M RTL32VV @PUSH %1 @PUSH %2 @CALL RTL32VV
M RTL32VI @PUSH %1 @PUSHI %2 @CALL RTL32VV
M RTL32IV @PUSHI %1 @PUSH %2 @CALL RTL32VV
M RTL32II @PUSHI %1 @PUSHI %2 @CALL RTL32VV
# Function RTL32(Var_A,Var_B)
# RTL32 Rotate Left RTL32(A,B) rotates A saves to B
:RTL32
:RTL32VV
@POPI ReturnAdr
@POPI B_PTR
@POPI A_PTR
@PUSHI A_PTR @ADD 2    # We precalc the High Part of A to avoid the Add 2 when Carry Flag is set.
#@PUSH 1 @CMP 0 @POPNULL    # Clear Carry
@FCLR
@PUSHII A_PTR              # Do the Low Part of A
@RTL
@POPII B_PTR
# The address of High-A is still on stack, fetch it now.
@PUSHS
@RLTC
@PUSHI B_PTR @ADD 2 @POPS
@PUSHI ReturnAdr
@RET

# We need some basic string functions that work with 32b numbers
# So we need to create i32tos
# Locals
:isReturn1 0
:isBase 0 0
:isA32Ptr 0         # Pointer in mem where the original A32 was stored.
:isResultPtr 0
:isStrPtr 0         # Used as pointer/index of isWorkBuff
:isWorkBuff "000000000000"
:isNegFlag 0
:isRevIndex 0
:isZero 0 0
:isOne 0 0
# Following are 32bit buffers that act as variables, but we have to deal with both high and low words
:isA32 0 0
:IsLocalR1 0 0
# Function i32tos(str_var,base_var,A_var)
# Start of procedure
:i32tos
@POPI isReturn1
@POPI isA32Ptr          # Address of input A32
@POPI isBase              # Pointer to Base(8,10,16)
@POPI isStrPtr
# Put a '0' glph in first slot of WorkBuff
@MA2V 0x3000 isWorkBuff   # WorkBuff is empty string (11 bytes) for max 32b size
@MA2V 0 isWorkBuff+2      # +/- -2,147,483,648 to 2,147,483,647
@MA2V 0 isWorkBuff+4
@MA2V 0 isWorkBuff+6
@MA2V 0 isWorkBuff+8
@MA2V 0 isWorkBuff+10
@MOVE32AV $$$0 isZero     # Constants we need for inverting 2scompt
@MOVE32AV $$$1 isOne#
# Save working copy of number
#
@COPY32IVV isA32Ptr isA32
#@MA2V isWorkBuff isStrPtr    # Set string ptr to WorkBuff[0]
#
# Test for Negative
@MA2V 0 isNegFlag

@PUSH isA32 @PUSH isZero @CALL CMP32 @POPNULL  # If A-0 < 0
@IF_EQ_A -1
  @MA2V 1 isNegFlag
  # Need invert with addtion for 2s comp
  @PUSH isA32 @PUSH isA32 @CALL INV32   # Invert Bits
  @PUSH isOne @PUSH isA32 @PUSH isA32 @CALL ADD32  # Add 1 for 2comp
@ENDIF

@MA2V isWorkBuff isRevIndex   #First Left to right, then reverse later.
                              #Helpfull because this way highbyte in words
			      #naturually add null to end of string

# Setup first While Test, while until isA32 == 0
@PUSH isA32
@PUSH isZero
@CALL CMP32
@WHILE_NOTZERO
   @POPNULL
   @PUSH isA32
   @PUSH isBase
   @PUSH IsLocalR1          # Remander
   @PUSH isA32              # Result
   @CALL DIV32
   @PUSHI IsLocalR1         # We only allow remainders that are <=16 so lower word of R1 should work.
   @AND 0x0f                # Just to make sure, we mask out any artifacts with lower nibble
   @ADD 0x30                # Turn Remainder to ASCII
   # IF the digit is > 9 then add 7 to makes it A-F for hex.
   @IF_GT_A 0x3A                # A=0x30-0x40 B=0x3A
      @IF_EQ_AV 0x10 isBase
         @ADD 0x07
      @ENDIF
   @ENDIF
   @POPII isRevIndex        # save the ASCII code
   @INCI isRevIndex
   @PUSH isA32
   @PUSH isZero        #  CMP's are B-A or tos - sftos for flags
   @CALL CMP32            # This will return 0, -1 or 1 as result
@ENDWHILE
@POPNULL
# At this point isWorkBuff will have in reverse order the ASCII number, max 11 digits.
#
@IF_EQ_AV 1 isNegFlag
   @PUSH 0x2d    # Ascii for '-'
   @POPII isStrPtr       # isStrPtr was passed in as needs to be pointer to suffient sized buffer.
   @INCI isStrPtr
@ENDIF
@DECI isRevIndex         # Last insert put RevIndex one past end of string.
# While Count Backworkd from isRevIndex to isWorkBuff
@PUSHI isRevIndex @SUB isWorkBuff
@WHILE_NOTZERO
  @POPNULL
  @PUSHII isRevIndex
  @POPII isStrPtr
  @PUSH 0
  @POPII isRevIndex      # After copying to stack we zero out, so next loop lowers byte will be blanked
  @INCI isStrPtr
  @DECI isRevIndex
  @PUSHI isRevIndex @SUB isWorkBuff
@ENDWHILE
@POPNULL
@PUSHI isReturn1
@RET
#
# Funtion stoi32(str_var, A_Var)
# stoi32 takes a stringptr and turns it into a 32 bit Ineger
# stoi32(string, ptrto32)
:stoi32
@POPI ReturnSI
@POPI IResultPtrSI
@POPI StrPtrSI
@MA2V 0 NegFlagSI
@MOVE32AV 10 BaseSI
@MOVE32AV 0 InvalueSI
@MOVE32AV 1 MultiplierSI
@PUSHI StrPtrSI @CALL strlen @POPI LengthSI
@PUSHII StrPtrSI @AND 0xff
@IF_EQ_A "-\0"
   @POPNULL
   @MA2V 1 NegFlagSI
   @INCI StrPtrSI
   @DECI LengthSI
@ELSE
   @POPNULL
@ENDIF
@PUSHI LengthSI
@IF_GT_A 2
   @POPNULL    # if Length > 2 we can test for '0x' or '0o' or '0b'
   @PUSHII StrPtrSI @AND 0xff
   @IF_EQ_A "0\0"
      @POPNULL
      @INCI StrPtrSI
      @PUSHII StrPtrSI @AND 0xff
      @SWITCH
         @CASE "x\0"
            @MOVE32AV 16 BaseSI
	    @INCI StrPtrSI
	    @DEC2I LengthSI
	    @CBREAK
	 @CASE "o\0"
            @MOVE32AV 8 BaseSI
	    @INCI StrPtrSI
	    @DEC2I LengthSI
	    @CBREAK
	 @CASE "b\0"
            @MOVE32AV 2 BaseSI
	    @INCI StrPtrSI
	    @DEC2I LengthSI
	    @CBREAK
	 @CDEFAULT
            @MOVE32AV 10 BaseSI
	    @DECI StrPtrSI
	    @CBREAK
      @ENDCASE
   @ENDIF
@ENDIF
@POPNULL
@PUSHI LengthSI
@WHILE_NOTZERO
   @POPNULL
   @DECI LengthSI
   @PUSHI StrPtrSI @ADDI LengthSI 
   @PUSHS  @AND 0xff   
   @SUB "0\0"
   @PUSHI BaseSI   # We can only do this because we know Bases is in range 2-16, odd bases over 16 would cause problems.
   @IF_EQ_A 16
      @POPNULL
      @IF_GE_A 10
         @SUB 7
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF

   @POPI B16CHARSI      # Turn the 16 bit on stack to 32 bit in storage.
   @INT2LONGVV B16CHARSI B32CHARSI
   # ( CharOrd, Multiplier, Result)
   @PUSH B32CHARSI @PUSH MultiplierSI @PUSH L32RegSI
   @CALL MUL32   
   @PUSH InvalueSI @PUSH L32RegSI @PUSH InvalueSI
   @CALL ADD32
   @PUSH BaseSI @PUSH MultiplierSI @PUSH MultiplierSI
   @CALL MUL32
   @PUSHI LengthSI
@ENDWHILE
@POPNULL
@COPY32VIV InvalueSI IResultPtrSI
@PUSHI NegFlagSI
@IF_NOTZERO
    # Invert and add 1 for 2s comp
    @PUSHI IResultPtrSI @PUSH InvalueSI
    @CALL INV32
    @INT2LONG $$$1 L32RegSI
    @PUSH InvalueSI
    @PUSH L32RegSI
    @PUSH L32RegSI
    @CALL ADD32
    @COPY32VIV L32RegSI IResultPtrSI
@ELSE
   @POPNULL
@ENDIF
@PUSHI ReturnSI
@RET

	    

:ReturnSI 0
:IResultPtrSI 0 0
:StrPtrSI 0
:NegFlagSI 0
:BaseSI 0 0
:InvalueSI 0 0
:MultiplierSI 0 0
:LengthSI 0
:B16CHARSI 0
:B32CHARSI 0 0
:L32RegSI 0 0

M AND32VVV @PUSH %1 @PUSH %2 @PUSH %3 @CALL AND32VVV
M AND32III @PUSHI %1 @PUSHI %2 @PUSHI %3 @CALL AND32VVV
M AND32IIV @PUSHI %1 @PUSHI %2 @PUSH %3 @CALL AND32VVV
M AND32IVI @PUSHI %1 @PUSH %2 @PUSHI %3 @CALL AND32VVV
M AND32IVV @PUSHI %1 @PUSH %2 @PUSH %3 @CALL AND32VVV
M AND32VII @PUSH %1 @PUSHI %2 @PUSHI %3 @CALL AND32VVV
M AND32VIV @PUSH %1 @PUSHI %2 @PUSH %3 @CALL AND32VVV
M AND32VVI @PUSH %1 @PUSH %2 @PUSHI %3 @CALL AND32VVV


# Function AND32(A_Var,B_Var,C_Var)
# AND function AND bits in A and B and returns result to C. A&B not modified.
:AND32
:AND32VVV
@POPI ReturnAdr
@POPI ADC_PTR       # Return Result
@INC2I ADC_PTR       # Set C to the High part of itself
@POPI ADB_PTR    
@POPI ADA_PTR
@PUSHII ADA_PTR     #Put on Stack low works of A and B
@PUSHII ADB_PTR
@PUSHI ADA_PTR @ADD 2 @PUSHS  # Put On Stack High A
@PUSHI ADB_PTR @ADD 2 @PUSHS  # Put On Stack High B
@ANDS @POPII ADC_PTR          # Save High Parts ANDed to High C
@DEC2I ADC_PTR
@ANDS @POPII ADC_PTR          # Save Low Parts ANDed to Low C
@PUSHI ReturnAdr
@RET
:ADA_PTR 0 0
:ADB_PTR 0 0
:ADC_PTR 0 0

M OR32VVV @PUSH %1 @PUSH %2 @PUSH %3 @CALL OR32VVV
M OR32III @PUSHI %1 @PUSHI %2 @PUSHI %3 @CALL OR32VVV
M OR32IIV @PUSHI %1 @PUSHI %2 @PUSH %3 @CALL OR32VVV
M OR32IVI @PUSHI %1 @PUSH %2 @PUSHI %3 @CALL OR32VVV
M OR32IVV @PUSHI %1 @PUSH %2 @PUSH %3 @CALL OR32VVV
M OR32VII @PUSH %1 @PUSHI %2 @PUSHI %3 @CALL OR32VVV
M OR32VIV @PUSH %1 @PUSHI %2 @PUSH %3 @CALL OR32VVV
M OR32VVI @PUSH %1 @PUSH %2 @PUSHI %3 @CALL OR32VVV
# OR function ORs bits in A and B and returns result to C. A&B not modified.
# Function OR32(A_Var,B_Var, C_Var)
:OR32
:OR32VVV
@POPI ReturnAdr
@POPI ORC_PTR       # Return Result
@INC2I ORC_PTR       # Set C to the High part of itself
@POPI ORB_PTR    
@POPI ORA_PTR
@PUSHII ORA_PTR     #Put on Stack low works of A and B
@PUSHII ORB_PTR
@PUSHI ORA_PTR @ADD 2 @PUSHS  # Put On Stack High A
@PUSHI ORB_PTR @ADD 2 @PUSHS  # Put On Stack High B
@ORS @POPII ORC_PTR          # Save High Parts ORed to High C
@DEC2I ORC_PTR
@ORS @POPII ORC_PTR          # Save Low Parts ORed to Low C
@PUSHI ReturnAdr
@RET
:ORA_PTR 0 0
:ORB_PTR 0 0
:ORC_PTR 0 0

# End of i32tos

# Division (both Unsigned and signed) are the only functions that have 4 paramters. So the macros are a bit more complex
M DIVU32VVVV @PUSH %1 @PUSH %2 @PUSH %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32VVVI @PUSH %1 @PUSH %2 @PUSH %3 @PUSHI %4 @CALL DIVU32VVVV
M DIVU32VVIV @PUSH %1 @PUSH %2 @PUSHI %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32VVII @PUSH %1 @PUSH %2 @PUSHI %3 @PUSHI %4 @CALL DIVU32VVVV
M DIVU32VIVV @PUSH %1 @PUSHI %2 @PUSH %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32VIVI @PUSH %1 @PUSHI %2 @PUSH %3 @PUSHI %4 @CALL DIVU32VVVV
M DIVU32VIIV @PUSH %1 @PUSHI %2 @PUSHI %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32VIII @PUSH %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @CALL DIVU32VVVV
M DIVU32IVVV @PUSHI %1 @PUSH %2 @PUSH %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32IVVI @PUSHI %1 @PUSH %2 @PUSH %3 @PUSHI %4 @CALL DIVU32VVVV
M DIVU32IVIV @PUSHI %1 @PUSH %2 @PUSHI %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32IVII @PUSHI %1 @PUSH %2 @PUSHI %3 @PUSHI %4 @CALL DIVU32VVVV
M DIVU32IIVV @PUSHI %1 @PUSHI %2 @PUSH %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32IIVI @PUSHI %1 @PUSHI %2 @PUSH %3 @PUSHI %4 @CALL DIVU32VVVV
M DIVU32IIIV @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSH %4 @CALL DIVU32VVVV
M DIVU32IIII @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @CALL DIVU32VVVV

# Function Unsided DIV
# Division for 32 Bit
# DIVU(A_Ptr,B_Ptr,%Result,%Remainder)
:LocalA 0 0
:LocalB 0 0 
:DIV32U
:DIVU32VVVV
@POPI DUReturn
@POPI DUResult
@POPI DUReturnRemain
@POPI DUB_ValPtr
@POPI DUA_ValPtr
@COPY32IVV DUA_ValPtr LocalA
@COPY32IVV DUB_ValPtr LocalB
@MOVE32AV $$$0 DUZero
@MOVE32AV $$$1 DUOne
@CMP32VV DUB_ValPtr DUZero
@IF_ZERO
   @PRTLN "Divide by Zero Error:"
   @POPNULL
   @PUSH 0 @PUSH 0
   @PUSHI DUReturn
   @RET
@ENDIF
@POPNULL
@MOVE32AV $$$0 DUQVal
@MOVE32AV $$$0 DURemainder
@MOVE32AV $$$0x80000000 DUMask

@ForIA2B DUIndex 0 32
   @RTL32VV DURemainder DURemainder  # Remainder << 1
   @AND32VIV DUMask DUA_ValPtr DUTemp1
   @CMP32VV DUTemp1 DUZero
   @IF_NOTZERO
      @POPNULL
      # DURemainder[bit32-Index]=DUA_ValPtr[bit32-Index]
      @OR32VVV DUOne DURemainder DURemainder
   @ELSE
      @POPNULL
   @ENDIF
   @CMP32VV DURemainder LocalB 
   @IF_EQ_A -1
      @POPNULL
   @ELSE      
      @SUB32VVV DURemainder LocalB DURemainder
      @OR32VVV DUQVal DUMask DUQVal
      @POPNULL

   @ENDIF
   @RTR32VV DUMask DUMask
@Next DUIndex
@COPY32VIV DURemainder DUResult
@COPY32VIV DUQVal  DUReturnRemain
@PUSHI DUReturn
@RET
# Local DIV variables
:DUReturn 0
:DUB_ValPtr 0
:DUA_ValPtr 0
:DUIndex 0
:DUReturnRemain 0 0
:DUResult 0 0
:DUZero 0 0
:DUOne 0 0
:DUQVal 0 0
:DURemainder 0 0
:DUMask 0 0
:DUTemp1 0 0
:DUMASKPtr DUMask

# Division (both Unsigned and signed) are the only functions that have 4 paramters. So the macros are a bit more complex
M DIV32VVVV @PUSH %1 @PUSH %2 @PUSH %3 @PUSH %4 @CALL DIV32VVVV
M DIV32VVVI @PUSH %1 @PUSH %2 @PUSH %3 @PUSHI %4 @CALL DIV32VVVV
M DIV32VVIV @PUSH %1 @PUSH %2 @PUSHI %3 @PUSH %4 @CALL DIV32VVVV
M DIV32VVII @PUSH %1 @PUSH %2 @PUSHI %3 @PUSHI %4 @CALL DIV32VVVV
M DIV32VIVV @PUSH %1 @PUSHI %2 @PUSH %3 @PUSH %4 @CALL DIV32VVVV
M DIV32VIVI @PUSH %1 @PUSHI %2 @PUSH %3 @PUSHI %4 @CALL DIV32VVVV
M DIV32VIIV @PUSH %1 @PUSHI %2 @PUSHI %3 @PUSH %4 @CALL DIV32VVVV
M DIV32VIII @PUSH %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @CALL DIV32VVVV
M DIV32IVVV @PUSHI %1 @PUSH %2 @PUSH %3 @PUSH %4 @CALL DIV32VVVV
M DIV32IVVI @PUSHI %1 @PUSH %2 @PUSH %3 @PUSHI %4 @CALL DIV32VVVV
M DIV32IVIV @PUSHI %1 @PUSH %2 @PUSHI %3 @PUSH %4 @CALL DIV32VVVV
M DIV32IVII @PUSHI %1 @PUSH %2 @PUSHI %3 @PUSHI %4 @CALL DIV32VVVV
M DIV32IIVV @PUSHI %1 @PUSHI %2 @PUSH %3 @PUSH %4 @CALL DIV32VVVV
M DIV32IIVI @PUSHI %1 @PUSHI %2 @PUSH %3 @PUSHI %4 @CALL DIV32VVVV
M DIV32IIIV @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSH %4 @CALL DIV32VVVV
M DIV32IIII @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @CALL DIV32VVVV



#
# The Signed DIV32 just calls the unsigned one but keeps track if the result should be signed.
# Function DIV32(AVal_ptr, BVal_ptr, Result_ptr, Remainder_ptr)
:DIV32
:DIV32VVVV
@POPI DSReturn
@POPI DSRemain1
@POPI DSResult
@POPI DSBVal
@POPI DSAVal
@MOVE32AV $$$0 DSZero
@MOVE32AV $$$1 DSOne
@MA2V 0 DSNegative
# IF A or/and B are negative invert the Negative flag
@PUSHI DSAVal @PUSH DSZero @CALL CMP32
@IF_LT_A 0
   # Is Negative, reverse NegFlag and comp2 A var
   @PUSHI DSNegative @INV @POPI DSNegative
   @PUSHI DSAVal @PUSHI DSAVal @CALL INV32
   @PUSHI DSAVal @PUSH DSOne @PUSHI DSAVal @CALL ADD32
@ENDIF
@POPNULL
@PUSHI DSBVal @PUSH DSZero @CALL CMP32
@IF_LT_A 0
   # Is Negative, reverse NegFlag and comp2 B var
   @PUSHI DSNegative @INV @POPI DSNegative
   @PUSHI DSBVal @PUSHI DSBVal @CALL INV32
   @PUSHI DSBVal @PUSH DSOne @PUSHI DSBVal @CALL ADD32   
@ENDIF
@POPNULL

@DIVU32IIII DSAVal DSBVal DSResult DSRemain1

#@PUSHI DSAVal
#@PUSHI DSBVal
#@PUSHI DSResult
#@PUSHI DSRemain1
#@CALL DIV32U
@PUSHI DSNegative
@IF_NOTZERO
   @PUSHI DSResult @PUSHI DSResult @CALL INV32
   @PUSHI DSResult @PUSH DSOne @PUSHI DSResult @CALL ADD32
@ENDIF
@POPNULL
@PUSHI DSReturn
@RET
:DSReturn 0
:DSRemain1 0
:DSResult 0
:DSBVal 0
:DSAVal 0
:DSZero $$$0
:DSOne $$$1
:DSNegative 0




# Function INT2LONG(A_Var, B_Var)
# INT2LONG function(A,B)
#   A=Ptr to 16b data, B=Ptr to 32b destination
:INT2LONG
:INT2LONGVV
  @POPI I2LReturn
  @POPI I2LB
  @POPI I2LA
  @PUSHII I2LA @AND 0x8000 # Test if 16b was Negative
  @IF_NOTZERO   # Neg bit was set
     @POPNULL
     @PUSHII I2LA
     @POPII I2LB
     @INC2I I2LB
     @PUSH 0xffff @POPII I2LB
  @ELSE         # Zero, Neg Bit was not set
     @POPNULL
     @PUSHII I2LA
     @POPII I2LB
     @INC2I I2LB
     @PUSH 0 @POPII I2LB
  @ENDIF
     @PUSHI I2LReturn
     @RET
:I2LA 0
:I2LB 0
:I2LReturn 0

M MUL32VVV @PUSH %1 @PUSH %2 @PUSH %3 @CALL MUL32VVV
M MUL32III @PUSHI %1 @PUSHI %2 @PUSHI %3 @CALL MUL32VVV
M MUL32IIV @PUSHI %1 @PUSHI %2 @PUSH %3 @CALL MUL32VVV
M MUL32IVI @PUSHI %1 @PUSH %2 @PUSHI %3 @CALL MUL32VVV
M MUL32IVV @PUSHI %1 @PUSH %2 @PUSH %3 @CALL MUL32VVV
M MUL32VII @PUSH %1 @PUSHI %2 @PUSHI %3 @CALL MUL32VVV
M MUL32VIV @PUSH %1 @PUSHI %2 @PUSH %3 @CALL MUL32VVV
M MUL32VVI @PUSH %1 @PUSH %2 @PUSHI %3 @CALL MUL32VVV

# MUL32(multiplierA, multiplierB, Result) pointers to 32b data
:MUL32
:MUL32VVV
@POPI MReturn
@POPI MResultPtr
@POPI MMPtr
@POPI NNPtr
@PUSHII MMPtr @POPI MMLocal
@PUSHI MMPtr @ADD 2 @PUSHS @POPI MMLocal+2
@PUSHII NNPtr @POPI NNLocal
@PUSHI NNPtr @ADD 2 @PUSHS @POPI NNLocal+2
@MOVE32AV $$$0 M_ANS
@MA2V 0 M_NEGFLAG
@MOVE32AV $$$0 M_ZERO
@MOVE32AV $$$1 M_ONE
@PUSH M_ZERO @PUSH MMLocal @CALL CMP32 @POPNULL
@JGT M1NotNeg   # A=Zero B=MM if B>A jmp NotNeg
@PUSHI M_NEGFLAG @INV @POPI M_NEGFLAG  # Flip NEGFlag
# Invert and add 1 to convert negative to possitive value for calculation
@PUSHI MMLocal @INV @POPI MMLocal
@PUSHI MMLocal+2 @INV @POPI MMLocal+2
@PUSH MMLocal @PUSH M_ONE @PUSH MMLocal @CALL ADD32
:M1NotNeg
@PUSH M_ZERO @PUSH NNLocal @CALL CMP32 @POPNULL
@JGT M2NotNeg  # A=Zero B=NN if B > A Jmp NotNeg
@PUSHI M_NEGFLAG @INV @POPI M_NEGFLAG  # Flip NEGFlag
# Invert and add 1 to convert negative to possitive value for calculation
@PUSHI NNLocal @INV @POPI NNLocal
@PUSHI NNLocal+2 @INV @POPI NNLocal+2
@PUSH NNLocal @PUSH M_ONE @PUSH NNLocal @CALL ADD32
:M2NotNeg
:M_WHILE1
   @PUSH M_ZERO @PUSH MMLocal @CALL CMP32 @POPNULL
   @JMPZ M_ENDWHILE
   # if M & 0x1; then ANS=ANS+NN
   @PUSH MMLocal @PUSH M_ONE @PUSH M_TEMP @CALL AND32
   @PUSH M_TEMP @PUSH M_ONE @CALL CMP32 @POPNULL
   @JMPNZ M_ENDIF1
      # ANS = ANS + N
      @PUSH M_ANS @PUSH NNLocal @PUSH M_ANS @CALL ADD32
:M_ENDIF1
   # N = N << 1
   @PUSH NNLocal @PUSH NNLocal @CALL RTL32
   # MM / 2 | MM >> 1
   @PUSH MMLocal @PUSH MMLocal @CALL RTR32
@JMP M_WHILE1
:M_ENDWHILE
@PUSH 0 @CMPI M_NEGFLAG @POPNULL
@JMPZ M_NOTNEG
# Or Is Negative
@PUSHI M_ANS @INV @POPI M_ANS
@PUSHI M_ANS+2 @INV @POPI M_ANS+2
@PUSH M_ONE @PUSH M_ANS @PUSH M_ANS @CALL ADD32
:M_NOTNEG
# Put M_ANS into return location
@PUSHI M_ANS @POPII MResultPtr
@PUSHI M_ANS+2 @PUSHI MResultPtr @ADD 2 @POPS
@PUSHI MReturn
@RET
:MReturn 0
:MResultPtr 0
:M_NEGFLAG 0
:MMPtr 0
:NNPtr 0
:MMLocal 0 0
:NNLocal 0 0
:M_TEMP 0 0
:M_ANS 0 0
:M_ZERO $$$0
:M_ONE $$$1

M LONG2INTVV @PUSH %1 @PUSH %2 @CALL LONG2INTVV
M LONG2INTVI @PUSHI %1 @PUSH %2 @CALL LONG2INTVV
M LONG2INTIV @PUSH %1 @PUSHI %2 @CALL LONG2INTVV
M LONG2INTII @PUSHI %1 @PUSHI %2 @CALL LONG2INTVV

# Function LONG2INT(Var_A, Var_B) A==always 32, B=Always 16
# LONG2INT funciton(A,B) a 32b(A) into a 16b(B) with some for negative values
:LONG2INT
:LONG2INTVV
   @POPI L2IReturn
   @POPI L2IB
   @POPI L2IA
   @PUSHII L2IA
   @POPII L2IB     # Copy the lower word from A to B
   @INC2I L2IA     # Point to high word of A
   @PUSHII L2IA
   @AND 0x8000 @POPNULL
   @JMPZ L2INotNeg
      # If negative 2's comp the value.
      @PUSHII L2IA
      @PUSHI L2IA @ADD 2
      @PUSHS
      @POPI L2IM1+2  # Fetch 'local' copy of the 32b A value
      @POPI L2IM1
      @PUSH L2IM1    # Invert value of A
      @PUSH L2IM1
      @CALL INV32
      @PUSH L2IM1
      @PUSH L2IOne
      @PUSH L2IM1
      @CALL ADD32    # Add one to invert (long version of COMP2)
      @PUSHI L2IM1   # Get lower word of 2cmp'ed A
      @COMP2         # Convert just this 16v to negative
      @POPI  L2IB
   :L2INotNeg
   @PUSHI L2IReturn
   @RET
:L2IReturn 0
:L2IA 0
:L2IB 0
:L2IOne $$$01
:L2IM1 0 0

M PRT32HEXV @PUSH %1 @CALL PRT32HEX
M PRT32HEXI @PUSHI %1 @CALL PRT32HEX
# Some debug print tools
# Function PRT32HEXV
# Print32Hex(ptr)
:PRT32HEX
:PRT32HEXV
@POPI PHReturn
@DUP
@ADD 2
@PUSHS
@POPI PDHold
@PRTHEXI PDHold
@PUSHS
@POPI PDHold
@PRTHEXI PDHold
@PUSHI PHReturn
@RET
# Print32Bin(ptr)
:PRT32BIN
@POPI PHReturn
@DUP
@ADD 2
@PUSHS
@POPI PDHold
@PRTBINI PDHold
@PUSHS
@POPI PDHold
@PRTBINI PDHold
@PUSHI PHReturn
@RET
:PHReturn 0
:PDHold 0





:DDivideByZero
@PRT "ERROR DIV by Zero"
@PUSHI DReturn          # Attempt to return, but really should exit
@RET
:DReturn 0
:DIndex 0
:DDenomPtr 0
:DNumerPtr 0
:DLocalDenom 0 0
:DLocalNumer 0 0
:DZero32 0 0
:DOne32 $$$01
:DNEGFLAG 0
:DRemainder 0 0
:DReverseBit 0 0
:DResultHold 0 0
:DRemReturnPtr 0
:ENDLMATH
ENDBLOCK

