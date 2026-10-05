! __LIB_EX716_MEMMOVE_LOADED
M __LIB_EX716_MEMMOVE_LOADED 1
P Loading ex716_memmove.ld

# Explicit-label overlap-safe byte copy for compiler-generated aggregates.
# Arguments are destination, source, and byte count, in that order.
# This is intentionally independent of the structured For/If macros.

G EX716_MEMMOVE

@FUNCTION EX716_MEMMOVE
:EX716_MEMMOVE
@PUSHRETURN
@Locals
   @Local DstPtr
   @Local SrcPtr
   @Local Length
   @Local Index01
   
   @POPI Length
   @POPI SrcPtr
   @POPI DstPtr

   @PUSHI Length
   @IF_NOTZERO
   # If destination is above source, copy from the end downward.
       @PUSHI DstPtr
       @PUSHI SrcPtr
       @IF_LE_S          #          EX716_MEMMOVE_FORWARD
          @POPNULL @POPNULL
          @MA2V 0 Index01
          @PUSHI Length
          @WHILE_NOTZERO
            @POPNULL
            @PUSHI DstPtr @ADDI Index01 @PUSHS @AND 0xff00
            @PUSHI SrcPtr @ADDI Index01 @PUSHS @AND 0xff
            @ORS
            @PUSHI DstPtr @ADDI Index01 @POPS
            @INCI Index01
            @DECI Length
            @PUSHI Length
          @ENDWHILE
          @POPNULL
       @ELSE   #                      MEMMOVE_REVERSE
          @POPNULL @POPNULL
          @PUSHI Length
          @WHILE_NOTZERO
             @SUB 1
             @POPI Length
             @PUSHI DstPtr @ADDI Length @PUSHS @AND 0xff00
             @PUSHI SrcPtr @ADDI Length @PUSHS @AND 0xff
             @ORS
             @PUSHI DstPtr @ADDI Length @POPS
             @PUSHI Length
          @ENDWHILE
          @POPNULL
       @ENDIF
   @ENDIF
   # Discard the original length probe used by the outer IF_NOTZERO.
   @POPNULL
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
