L string.ld
################
# lmath.ld library
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
# COPY32VIV  [Label]    Label
# MOVE32AV   $$$Number  Label
# MOVE32AVI  $$$Number  [Label32]
# INT2LONG   Label16    Label32
# INT2LONGI  Label16    [label32]
# INT2ILONG  [Label16]  label32
# LONG2INT   Label32    Label16
#
#
# When dealing with 32I numbers, your dealing with not an elemetry object but a structure of 4 bytes
# For most procedures you are passing ont he stack a 16b pointer to the address where the 4 bytes start
# But when passing data from one sub-routine to another, you may run into the cases where the value
# you have on hand, is just a pointer, where the POINTER to the 4 byte number is stored.
# So COPY32VV means copy values at PTR to PTR
#    COPY32VIV means copy values at PTR to PTR->PTR
#    COPY32IVV means copy values at PTR->PTR to PTR
#    COPY32IVIV means copy values aat PTR->PTR to PTR->PTR
#
# Read this to mean 'V' by itself means %n is the 16b number that is the addresss of the structure
#                   'IV' means %n is ptr to a diffrent 16b number that is the address of the struct.

# Copy is for copying the 4 bytes of a 32b word from one pointer to another
# Passed in parameters are the labels/pointers to the first word of the 32b numbers
#
# V -> V
M COPY32VV \
     @PUSHI %1 @POPI %2 @PUSHI %1+2 @POPI %2+2
# V -> V_PTR
M COPY32VIV \
      @PUSHI %1 @PUSH %1 @ADD 2 @PUSHS \
      @PUSHI %2 @ADD 2 @POPS \
      @PUSHI %2 @POPS
# V_PTR -> V
M COPY32IVV \
      @PUSHI %1 @PUSHS @PUSHI %1 @ADD 2 @PUSHS \
      @POPI %2+2 @POPI %2
# V_PTR -> V_PTR
M COPY32IVIV \
      @PUSHI %1 @PUSHS @PUSHI %1 @ADD 2 @PUSHS \
      @PUSHI %2 @ADD 2 @POPS \
      @PUSHI %2 @POPS
      
# We call the 'Constant' to V 'MOVE's rathar than COPY since it requires
# diffrent logic to handle a fixed constants which are first being defined in this same
# macro and normally that source number will not be directly refrenced again.
# these 'MOVE's are less efficent than COPY's
#  MOVE32AV is the ruff 32bit equivalent of @MA2V
M MOVE32AV @JMP %0SkipOver :%0C1 $$$%1 \
           :%0SkipOver @PUSHI %0C1 @PUSH %2 @POPS \
	   @PUSHI %0C1+2 @PUSH %2+2 @POPS


M MOVE32AVI @JMP %0SkipF :%0C1 $$$%1 \
           :%0SkipF @PUSHI %0C1 @PUSHI %2 @POPS \
	   @PUSHI %0C1+2 @PUSHI %2 @ADD 2 @POPS
# The INT2LONG macro takes a Label to 16b data and saves it as a 32b (zeroed high word) Label
#  %1 is ptr to 16b data, %2 is ptr to 32b data
# Started life as a macro, now its a function, with macro like calling.
M INT2LONG \
    @PUSH %1 @PUSH %2 @CALL INT2LONG
# This is for when the src value is a pointer to a 16b number
M INTI2LONG \
    @PUSHI %1 @PUSH %2 @CALL INT2LONG
# Started life as a macro, now its a function, with macro like calling.
M INT2LONGI \
    @PUSH %1 @PUSHI %2 @CALL INT2LONG
# Lastly we have the case where both the src and dst are pointers
M INTI2LONGI \
    @PUSHI %1 @PUSHI %2 @CALL INT2LONG
    

# LONG2INT trucates the lower word in 32b data to 16b.But conider possibity of negative values
# %1 is ptr to 32b data and %2 is ptr to 16b data (Does effect flags)
# It started life as a macro, now its a function.

M LONG2INT @PUSH %1 @PUSH %2 @CALL LONG2INT

#
! MATH32DEFINE
M MATH32DEFINE 1
# Define the globals
G ADD32
G SUB32
G CMP32
G AND32
G OR32
G RTR32
G RTL32
G INV32
G DIV32
G DIV32U
G MUL32
G i32tos
G stoi32
G INT2LONG
G LONG2INT
G PRT32BIN
G PRT32HEX

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
# Constants 32b 1 and 0
:One_Val 1 0
:Zero_Val 0 0
#
#  ADD(A,B,C)  Modifies C, removes all from Stack
:ADD32         # Note that 32 bit math does NOT set any flags so we can't directly use it for 64 bit math.
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
# SUB(A,B,C)  Modfies C, pops all from stack
:SUB32
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
# CMP32(A,B) Pops A and B from stack, replaces with -1,0,1
:CMP32
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
# RTR32 Rotate Right 32 bit version 2 Parms ptr to A and Return to C
# Call RTR32(A,B) Rotats A saves to B
:RTR32
@POPI ReturnAdr
@POPI B_PTR
@POPI A_PTR
@PUSHI B_PTR @ADD 2        # Preset the High B address to keep the Add 2 from resetting carry
@PUSH 1 @CMP 0 @POPNULL    # Clear Carry
@PUSHI A_PTR @ADD 2 @PUSHS
@RTR
@SWP @POPS      # Swap order so we can POPS the High A rotate value to the precalced High B address
                # We do this out of order sequnce to preserve the Carry Flag from the High A rotation.
@PUSHII A_PTR
@RRTC
@POPII B_PTR
@PUSHI ReturnAdr
@RET
#
# Invert Bits
# INV32(A,B) Inverts A saves to B
:INV32
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
#
# RTL32 Rotate Left RTL32(A,B) rotates A saves to B
:RTL32
@POPI ReturnAdr
@POPI B_PTR
@POPI A_PTR
@PUSHI A_PTR @ADD 2    # We precalc the High Part of A to avoid the Add 2 when Carry Flag is set.
@PUSH 1 @CMP 0 @POPNULL    # Clear Carry
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
# Start of procedure
:i32tos
@POPI isReturn1
@POPI isStrPtr
@POPI isBase              # Pointer to Base(8,10,16)
@POPI isA32Ptr          # Address of input A32
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

@PUSH isZero @PUSH isA32 @CALL CMP32 @POPNULL
@JMPNZ isNotNeg
  @MA2V 1 isNegFlag
  # Need invert with addtion for 2s comp
  @PUSH isA32 @PUSH isA32 @CALL INV32   # Invert Bits
  @PUSH isOne @PUSH isA32 @PUSH isA32 @CALL ADD32  # Add 1 for 2comp
:isNotNeg
@MA2V isWorkBuff isRevIndex   #First Left to right, then reverse later.
                              #Helpfull because this way highbyte in words
			      #naturually add null to end of string
:isMainLoop
   # Cmp work value to 0
   @PUSH isA32
   @PUSH isZero        #  CMP's are B-A or tos - sftos for flags
   @CALL CMP32            # This will return 0, -1 or 1 as result
   @POPNULL
   @JMPZ EndMainLoop
   @PUSH isA32
   @PUSH isBase
   @PUSH IsLocalR1           # Remander
   @PUSH isA32           # Result
   @CALL DIV32
   @PUSHI IsLocalR1         # We only allow remainders that are <=16 so lower word of R1 should work.
   @AND 0x0f                # Just to make sure, we mask out any artifacts with lower nibble
   @ADD 0x30                # Turn Remainder to ASCII
   @CMP 0x3A                # A=0x30-0x40 B=0x3A
   @JLT isNotHex            # IF B>39 add 7 to move to letters to A-F
       @ADD 0x07
   :isNotHex
   @POPII isRevIndex        # save the ASCII code
   @INCI isRevIndex
   @JMP isMainLoop
:EndMainLoop
# At this point isWorkBuff will have in reverse order the ASCII number, max 11 digits.
#
@PUSH 0 @CMPI isNegFlag @POPNULL
@JMPZ isGoReverseDigits
   # Else NEG flag set, so insert '-'
   @PUSH 0x2d    # Ascii for '-'
   @POPII isStrPtr       # isStrPtr was passed in as needs to be pointer to suffient sized buffer.
   @INCI isStrPtr

:isGoReverseDigits
@DECI isRevIndex         # Last insert put RevIndex one past end of string.
:isGoReverseLoop
  # while isRevIndex > isWorkBuff
  @PUSHI isRevIndex
  @CMP isWorkBuff @POPNULL   # A=isRevIndex B=isWorkBuff
  @JLT isExitReverseLoop     # If A<B ExitLoop
  @PUSHII isRevIndex
  @POPII isStrPtr
  @PUSH 0
  @POPII isRevIndex      # After copying to stack we zero out, so next loop lowers byte will be blanked
  @INCI isStrPtr
  @DECI isRevIndex
  @JMP isGoReverseLoop
:isExitReverseLoop
  @PUSHI isReturn1
  @RET
#
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
   @POPNULL    #If Legnth < 3 then must be decimal
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
   @PUSHI BaseSI   # We can only do this because we know Bases is in range 2-16
   @IF_EQ_A 16
      @POPNULL
      @IF_GE_A 10
         @SUB 7
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF
   @POPI B16CHARSI      # Turn the 16 bit on stack to 32 bit in storage.
   @INTI2LONG B16CHARSI B32CHARSI
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

# AND function AND bits in A and B and returns result to C. A&B not modified.
:AND32
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

# OR function ORs bits in A and B and returns result to C. A&B not modified.
:OR32
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

# Division for 32 Bit
# DIVU(A,B,%Result,%Remainder)
:LocalA 0 0
:LocalB 0 0 
:DIV32U
@POPI DUReturn
@POPI DUResult
@POPI DUReturnRemain
@POPI DUB_ValPtr
@POPI DUA_ValPtr
@COPY32IVV DUA_ValPtr LocalA
@COPY32IVV DUB_ValPtr LocalB
@MOVE32AV $$$0 DUZero
@MOVE32AV $$$1 DUOne
@MOVE32AV $$$0 DUQVal
@MOVE32AV $$$0 DURemainder
@MOVE32AV $$$0x80000000 DUMask
@PUSHI DUB_ValPtr @PUSH DUZero @CALL CMP32   # Worth noting CMP32 pops off A&B and leaves just -1,0,1 on stack
@IF_ZERO
   @PRTLN "Divide by Zero Error:"
   @POPNULL
   @PUSH 0 @PUSH 0
   @PUSHI DUReturn
   @RET
@ENDIF
@POPNULL
@ForIA2B DUIndex 0 32
   @PUSH DURemainder @PUSH DURemainder @CALL RTL32  # RTL32(A,B) B = A<<1, Pops both A&B off
   @PUSH DUMask @PUSHI DUA_ValPtr @PUSH DUTemp1 @CALL AND32 # AND32(A,B,C) C=A & B, pops all off.
   @PUSH DUTemp1 @PUSH DUZero @CALL CMP32
   @IF_NOTZERO
      @POPNULL
      # DURemainder[bit16-Index]=DUA_ValPtr[bit16-Index]
      @PUSH DUOne @PUSH DURemainder @PUSH DURemainder @CALL OR32
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI DUB_ValPtr
   @PUSH DURemainder   
:BreakHere
   @CALL CMP32
   @IF_EQ_A 1
      @POPNULL
   @ELSE
      @PUSH DURemainder @PUSHI DUB_ValPtr @PUSH DURemainder @CALL SUB32 # Remain=Remain-B
      @PUSH DUQVal @PUSH DUMask @PUSH DUQVal @CALL OR32 # QVal=QVal | Mask   
      @POPNULL
   @ENDIF
   @PUSH DUMask @PUSH DUMask @CALL RTR32  # Mask = Mask >> 1
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


#
# The Signed DIV32 just calls the unsigned one but keeps track if the result should be signed.
#
:DIV32
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
@PUSHI DSAVal
@PUSHI DSBVal
@PUSHI DSResult
@PUSHI DSRemain1
@CALL DIV32U
@PUSHI DSNegative
@IF_NOTZERO
   @PUSHI DSResult @PUSHI DSResult @CALL INV32
   @PUSHI DSResult @PUSH DSOne @PUSHI DSResult @CALL ADD32
@ENDIF
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





# INT2LONG function(A,B)
#   A=Ptr to 16b data, B=Ptr to 32b destination
:INT2LONG
  @POPI I2LReturn
  @POPI I2LB
  @POPI I2LA
  @PUSHI I2LA @AND 0x8000 @POPNULL # Test if 16b was Negative
  @JMPZ I2LNotNeg
     @PUSHI I2LA
     @POPII I2LB
     @INC2I I2LB
     @PUSH 0xffff @POPII I2LB
     @JMP I2LEnd
  :I2LNotNeg
     @PUSHI I2LA
     @POPII I2LB
     @INC2I I2LB
     @PUSH 0 @POPII I2LB
  :I2LEnd
     @PUSHI I2LReturn
     @RET
:I2LA 0
:I2LB 0
:I2LReturn 0

# MUL32(multiplierA, multiplierB, Result) pointers to 32b data
:MUL32
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

   


# LONG2INT funciton(A,B) a 32b(A) into a 16b(B) with some for negative values
:LONG2INT
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

# Some debug print tools
# Print32Hex(ptr)
:PRT32HEX
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

