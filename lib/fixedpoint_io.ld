! FIXPOINTIOSEEN
M FIXPOINTIOSEEN

I common.mc
L fixedpoint.ld

G fx_print

##############################
# fx_print(V1)
##############################
:fx_print
@PUSHRETURN
   @LocalVar V1 01
   @LocalVar Sign 02
   @LocalVar IPart 03
   @LocalVar FPart 04
   @LocalVar Temp32 05
   @LocalVar Temp32High 06

   @POPI V1
# Extract Sign
   @MA2V 1 Sign
   @PUSHI V1
   @IF_LT_A 0
      @PRT "-"
      @COMP2        # Invert V1
      @PUSHI Sign   @COMP2  @POPI Sign
   @ENDIF
   @POPI V1
# Get Integer Part
   @PUSHI V1
   @SHRN 8
   @POPI IPart
   @PRTI IPart
# Get Fraction Part
   @PRT "."
   @PUSHI V1
   @AND 0xff
   @POPI FPart
# Frac_decimal = (FPart *10000) / 256
   @Call(Av) MUL16x32U 10000 FPart
   @POP32I(v) Temp32

   ########################################################
   # Divide by 256 = right shift 8 bits
   # Temp32 = Temp32 >> 8
   ########################################################
   @Call32(v) SHR32_8 Temp32
   @POP32I(v) Temp32

   ########################################################
   # Print 4-digit decimal
   ########################################################
   @PUSHI Temp32
   @CALL prt_uint4


   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
   @POPRETURN
 @RET
 #############################
 # prt_uint4 helper function, prints zero padded integr.
 #############################
 :prt_uint4
@PUSHRETURN
   @LocalVar N 01

   @POPI N

   @Call(vA) DIVU N 1000 @PRTTOP @POPNULL @POPI N
   @Call(vA) DIVU N 100  @PRTTOP @POPNULL @POPI N
   @Call(vA) DIVU N 10   @PRTTOP @POPNULL @PRTTOP
   @POPNULL

   @RestoreVar 01
   @POPRETURN
 @RET

ENDBLOCK
