! __LIB_FIXEDPOINT_LOADED
M __LIB_FIXEDPOINT_LOADED 1
L lmath.ld
L shift16.ld

G fx_mul
G fx_div
G fx_sqr
G fx_mul2
G fx_add
G fx_sub
G fx_mag2
G fx_neg
G fx_abs
G fx_sign
G fx_cmp
G fx_from_int

#############################
# Fixed Point Utilities
#############################
#
# fx_mul(x,y): result
:fx_mul
@PUSHRETURN
   @LocalVar B0_1 01
   @LocalVar B2_3 02
   @LocalVar X1 03
   @LocalVar Y1 04
   @LocalVar Sign 05

   @POPI Y1
   @POPI X1

   @MA2V 1 Sign

   # Detect is either X1 or Y1 is negative and adjust value and sign
   @PUSHI X1
   @IF_LT_A 0
      @PUSHI Sign
      @COMP2
      @POPI Sign
      @PUSHI X1
      @COMP2
      @POPI X1
   @ENDIF
   @POPNULL
   @PUSHI Y1
   @IF_LT_A 0
      @PUSHI Sign
      @COMP2
      @POPI Sign
      @PUSHI Y1
      @COMP2
      @POPI Y1
   @ENDIF
   @POPNULL
   
   @Call(VV) MUL16x32U X1 Y1
   @POP32I(V) B0_1
   
   @PUSH B0_1
   @ADD 1
   @PUSHS

   @IF_NEQ_AV 1 Sign
      @COMP2
   @ENDIF   
   

   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET


# fx_div
# -----------------------------
# Fixed-point divide, Q8.8
# - Truncating (no rounding)
# - Saturates to ±127.996
# - Divide-by-zero returns 0 with O32Flag set
# - Normalization is internal and does NOT rescale quotient
:fx_div
@PUSHRETURN
    @LocalVar X1     01
    @LocalVar Y1     02
    @LocalVar Sign   03
    @LocalVar NUM    04
    @LocalVar NUM_H  05
    @LocalVar DEN    06
    @LocalVar DEN_H  07
    @LocalVar QUO_L  08
    @LocalVar QUO_H  09
    @LocalVar Shift  10      # normalization shift count

    ########################################################
    # Pop arguments (Y first, then X)
    ########################################################
    @POPI Y1
    @POPI X1

    ########################################################
    # Determine resulting sign
    ########################################################
    @MA2V 1 Sign

    # --- Check X1 ---
    @PUSHI X1
    @IF_LT_A 0
        @POPNULL
        @PUSHI Sign @COMP2 @POPI Sign
        @PUSHI X1 @COMP2 @POPI X1
    @ELSE
        @POPNULL
    @ENDIF

    # --- Check Y1 ---
    @PUSHI Y1
    @IF_LT_A 0
        @POPNULL
        @PUSHI Sign @COMP2 @POPI Sign
        @PUSHI Y1 @COMP2 @POPI Y1
    @ELSE
        @POPNULL
    @ENDIF


    ########################################################
    # Convert X → 32-bit NUM and apply <<8 for fixed point
    ########################################################
    @M16VTO32V X1 NUM
    @Call32(V) SHL32_8 NUM
    @POP32I(V) NUM     # NUM now 32-bit shifted X


    ########################################################
    # Convert Y → 32-bit DEN
    ########################################################
    @M16VTO32V Y1 DEN


    ########################################################
    # Zero division check
    ########################################################
    @PUSHI DEN
    @ORI   DEN_H
    @IF_ZERO
        @POPNULL
        @PUSH 0       # result
        @PUSH 0       # preserve fixed-point shape
        @RestoreVar 10        
        @RestoreVar 09
        @RestoreVar 08
        @RestoreVar 07
        @RestoreVar 06
        @RestoreVar 05
        @RestoreVar 04
        @RestoreVar 03
        @RestoreVar 02
        @RestoreVar 01
        @POPRETURN
        @RET
    @ENDIF
    @POPNULL


    ########################################################
    # ★★★ Normalize BOTH NUM and DEN
    @Call32(VV) normalize32_int NUM DEN

    @POP32I(V) DEN      # third result
    @POP32I(V) NUM      # second result
    @POPI Shift         # FIRST result = shift count (!!)


    ########################################################
    # Perform unsigned 32-bit divide
    ########################################################
    @Call32(VV) DIV32U NUM DEN

    # DIV32U returns: R_L R_H Q_L Q_H
    @POP32I(V) QUO_L   # Pop Q_L/Q_H into QUO
    @POPNULL           # discard Remainder_H
    @POPNULL           # discard Remainder_L

    ########################################################
    # Test for OverFlow, QUD_H !+0 or QUI_L > Limit(+:0x7ffff,-:0x8000)
    ########################################################
    @LocalVar Limit 11                 # Note, it legal to declair new local variable anywhere.
                                       # You don't even have to use a 'new' number like I do here.
                                       # Just avoid useing in the 'local' block
                                       # the same variable slot you used before.
                                       # Just make sure all exit paths pass though RestoreVar
    # Limit = (Sign == 1) ? 0x7fff : 0x8000
    @IF_EQ_AV 1 Sign
       @MA2V 0x7fff Limit
    @ELSE
       @MA2V 0x8000 Limit
    @ENDIF
    #
    # If QUO_H !=0 => overfor for sure
    @IF_EQ_AV 0 QUO_H
       # QUO_H =0 over if QUO_L > Limit
       @PUSHI QUO_L       
       @IF_UGT_V Limit
          @POPNULL
          @PUSHI Limit @POPI QUO_L
          @PUSHI Flags32 @OR O32Flag @POPI Flags32
       @ELSE
          @POPNULL
       @ENDIF
    @ELSE
       # QUO_H != 0, definitly overflow.
       @PUSHI Limit @POPI QUO_L
       @PUSHI Flags32 @OR O32Flag @POPI Flags32
    @ENDIF
    @RestoreVar 11

    ########################################################
    # Extract 16-bit quotient
    ########################################################
    @PUSHI QUO_L


    ########################################################
    # Apply sign to final 16-bit output
    ########################################################
    @IF_NEQ_AV 1 Sign
        @COMP2
    @ENDIF


    ########################################################
    # Cleanup
    ########################################################
    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


###############################
# fx_sqr(V):V^2, fast square function.
###############################
:fx_sqr
@PUSHRETURN
   @LocalVar V1 01
   @LocalVar B0_1 02
   @LocalVar B2_3 03   

   @POPI V1
   @Call(VV) MUL16x32U V1 V1
   @POP32I(V) B0_1

#  # No need for sign check, always +

   @PUSH B0_1
   @ADD 1
   @PUSHS

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

##############################
# fx_mul2(V) (multiply by 2)
##############################
:fx_mul2
@SWP
@SHL
@SWP
@RET
##############################
# fx_add(X,Y):R
##############################
:fx_add
@PUSHRETURN      # Move return address out of way.
@ADDS            # No need for local varaibls values is on stack.
@POPRETURN
@RET
##############################
# fx_sub(X,Y):R   # R=X-Y
##############################
:fx_sub
@PUSHRETURN      # Move return address out of way.
@SUBS            # No need for local varaibls values is on stack.
@POPRETURN
@RET

##############################
# fx_mag2(X,Y):(x^2+y^2)
##############################
:fx_mag2
@PUSHRETURN
   @LocalVar X1 01
   @LocalVar Y1 02

   @POPI Y1
   @POPI X1

   @Call(V) fx_sqr X1    # Results on Stack
   @Call(V) fx_sqr Y1

   @ADDS                      # Final result

   @RestoreVar 02
   @RestoreVar 01
   @POPRETURN
@RET

############################################################
# fx_normalize32
# Input:  ( NumL NumH DenL DenH -- NumL NumH DenL DenH Shift )
# Output: normalized Num and Den such that:
#         - Highest bit of Den is in bit 31
#         - Shift = number of bits shifted
############################################################
:fx_normalize32
@PUSHRETURN
    @LocalVar N_L    01
    @LocalVar N_H    02
    @LocalVar D_L    03
    @LocalVar D_H    04
    @LocalVar Shift  05

    # Pop inputs
    @POP32I(V) D_L
    @POP32I(V) N_L

    @MA2V 0 Shift

    ########################################################
    # Zero-divisor check
    ########################################################
    @PUSHI D_L
    @ORI   D_H
    @IF_ZERO
        @POPNULL
        @PUSHI N_L   # pass through original values
        @PUSHI N_H
        @PUSHI D_L
        @PUSHI D_H
        @PUSHI 0     # Shift = 0
        @POPRETURN
    @ENDIF
    @POPNULL

    ########################################################
    # Count leading zeros in divisor
    ########################################################
    @Call32(V) CountZero32 D_L      # Count = clz( D_L | D_H )
    @POPI Shift

    ########################################################
    # Normalize numerator
    ########################################################
    @PUSHI Shift
    @Call32(V) SHL32 N_L
    @POP32I(V) N_L

    ########################################################
    # Normalize divisor
    ########################################################
    @PUSHI Shift
    @Call32(V) SHL32 D_L
    @POP32I(V) D_L

    ########################################################
    # Return results
    ########################################################
    @PUSHI N_L
    @PUSHI N_H
    @PUSHI D_L
    @PUSHI D_H
    @PUSHI Shift

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

############################################################
# CountZero16 loop: count leading zeros in Tmp (16-bit)
############################################################
:CountZero16
@PUSHRETURN
    @LocalVar Tmp   01
    @LocalVar _I    02
    @LocalVar Count 03

    @MA2V 0 Count

    @POPI Tmp
    # Loop up to 16 times but break on first MSB=1
    @ForIA2B _I 0 16

        @PUSHI Tmp
        @AND 0x8000
        @IF_NOTZERO
            @POPNULL
            @FORBREAK
        @ENDIF
        
        @POPNULL
        @PUSHI Tmp
        @SHLN 1   # Tmp << 1
        @POPI Tmp

        # Count++
        @INCI Count

    @Next _I
    @PUSHI Count
    
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01    
    @POPRETURN
@RET

############################################################
# CountZero32: count leading zeros in a 32-bit unsigned integer
# Input:  ( Low High -- )
# Output: ( Count )
############################################################
:CountZero32
@PUSHRETURN
    @LocalVar Low    01
    @LocalVar High   02
    @LocalVar Count  03

    @POP32I(V) Low       # Low in 01/02, High in 02/03 depending on layout

    # If High ≠ 0 > just CLZ16(High)
    @PUSHI High
    @IF_NEQ_A 0
        @POPNULL
        @Call(V) CountZero16 High
        @POPI Count
    @ELSE
        @POPNULL

        # High == 0 → Count = 16 + CountZero16(Low)
        @Call(V) CountZero16 Low
        @POPI Count

        @PUSHI Count
        @ADD 16
        @POPI Count
    @ENDIF

    @PUSHI Count
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

############################################################
# normalize32_int(NUM, DEN) → shift  newNUM  newDEN
#
# Integer-only normalizer.
# Finds MSB of DEN, computes left-shift amount so that
# DEN’s MSB ends up at bit 31, then shifts NUM and DEN.
#
# Returns (bottom→top stack order):
#     shift
#     newNUM_L
#     newNUM_H
#     newDEN_L
#     newDEN_H
############################################################

:normalize32_int
@PUSHRETURN
    @LocalVar NUM_L   01
    @LocalVar NUM_H   02
    @LocalVar DEN_L   03
    @LocalVar DEN_H   04
    @LocalVar Shift   05
    @LocalVar Pos_DEN 06
    @LocalVar Pos_NUM 07

    ########################################################
    # Pop inputs: DEN first, then NUM
    ########################################################
    @POP32I(V) DEN_L
    @POP32I(V) NUM_L

    @PUSHI DEN_L
    @ORI DEN_H
    @IF_ZERO
       @POPNULL
       @MA2V 0 Shift
       @JMP norm32ret
    @ENDIF
    @POPNULL

    # Pos_DEV=31-CountZero32(DEN)
    @Call32(V) CountZero32 DEN_L
    @POPI Pos_DEN

    # Pos_NUM=31-CountZero32(NUM)
    @Call32(V) CountZero32 NUM_L
    @POPI Pos_NUM

    @PUSHI Pos_DEN
    @IF_GT_V Pos_NUM
        @POPNULL
        @PUSHI Pos_NUM
    @ENDIF
    @POPI Shift

    @PUSH32I(V) NUM_L @PUSHI Shift @CALL SHL32
    @POP32I(V) NUM_L
    @PUSH32I(V) DEN_L @PUSHI Shift @CALL SHL32    
    @POP32I(V) DEN_L

:norm32ret
    @PUSHI Shift    
    @PUSH32I(V) NUM_L
    @PUSH32I(V) DEN_L

    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#################################################
# fx_neg(x): -x
#################################################
:fx_neg
@SWP      # Save Return
@PUSH 0   # Subtract TOS from 0
@SWP
@SUBS
@SWP      # Move Return to TOS
@RET


#################################################
# fx_abs(x): -x if x<0 else x
# Saturates at 0x7fff for input of 0x8000
################################################
:fx_abs
@SWP     # Save Return Address
@IF_LT_A 0
   @IF_EQ_A 0x8000
      @POPNULL
      @PUSH 0x7fff
   @ELSE
      @CALL fx_neg
   @ENDIF
@ENDIF
@SWP     # Restore Return Address
@RET

###############################################
# fx_sign(x): -1, 0, +1  Returns plain integers
###############################################
:fx_sign
@SWP          # Preserve the Return address
@IF_NOTZERO   # If was zero, we just return that.
   @DUP
   @AND 0x8000
   @IF_NOTZERO
      # Negative
      @POPNULL
      @PUSH -1
   @ELSE
      # Positive
      @POPNULL
      @PUSH 1
   @ENDIF
@ENDIF
@SWP           # Restore the Return
@RET
#################################################
# fx_cmp(a,b):-1,0,1 if a<b or a=b or a>b
#################################################
:fx_cmp
@PUSHRETURN
@SUBS            # cmp is same as fx_sign of the SUB result.
@CALL fx_sign
@POPRETURN
@RET
#################################################
# fx_from_int(x): Q8.8 with -128<= x <=127
#################################################
:fx_from_int
@SWP
@SHLN 8    # Shift Integer to high byte, zeros low
@SWP
@RET
###############################################
# fx_clamp(x,min,max): min if x<min | max if x>max
###############################################
:fx_clamp
@PUSHRETURN
    @LocalVar X1  01
    @LocalVar Min 02
    @LocalVar Max 03

    @POPI Max
    @POPI Min
    @POPI X1

   @PUSHI X1
   @IF_LT_V Min
      @POPNULL
      @PUSHI Min
   @ENDIF
   @IF_GT_V Max
      @POPNULL
      @PUSHI Max
   @ENDIF

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
   @POPRETURN
 @RET
 
   
ENDBLOCK
