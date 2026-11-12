I commonDS.mc
L softstackDS.ld
L fpmath.ld

.CODE 0


:Main
.Entry Main
@DSSInitQuick
@Locals
   @Local Index
   @Local Jndex
   @Local MantLow
   @Local MantHigh
   @Local Exponent
   @Local Sign
   @Local FPLow
   @Local FPHigh

   @PRTLN "Start of test:"

   @MA2V FPTable Index

   @PUSH 0
   @WHILE_ZERO
      @POPNULL
      @PRT "Data: " @PRTHEXI Index @PRTNL
      @PUSHII Index
      @IF_NEQ_A 9999   # End COde
         @POPI FPLow
         @INC2I Index
         @PUSHII Index
         @POPI FPHigh
         @INC2I Index
         #
         @MV2V Index Jndex       # Save for second test
         #
         @Call(VV) FP32_UNPACK FPLow FPHigh
         @POPI4 MantHigh MantLow Exponent Sign
         @PUSHII Index
         @INC2I Index
         @IF_NEQ_V Sign
            @PRTLN "Error at Sign value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @END
         @ENDIF
         @POPNULL
         @PUSHII Index
         @INC2I Index
         @IF_NEQ_V Exponent
            @PRTLN "Error at Exponent value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @END
         @ENDIF
         @POPNULL
         @PUSHII Index
         @INC2I Index
         @IF_NEQ_V MantLow
            @PRTLN "Error at MantLow value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @END
         @ENDIF
         @POPNULL
         @PUSHII Index
         @INC2I Index
         @IF_NEQ_V MantHigh
            @PRTLN "Error at MantHigh value " @PRTHEXI MantHigh @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @END
         @ENDIF
         @POPNULL
         @PRT "Unpack worked for " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
         #
         # Now test Pack
         # Jndex is back at start of unpacked test data
         @PUSHII Jndex    # Sign
         @INC2I Jndex
         @PUSHII Jndex    # Exponent
         @INC2I Jndex
         @PUSHII Jndex    # MantLow
         @INC2I Jndex
         @PUSHII Jndex    # MantHigh
         @CALL FP32_PACK
         #
         @IF_NEQ_V FPHigh
            @PRTLN "Error at PACK FPHigh value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @END
         @ENDIF
         @POPNULL
         @IF_NEQ_V FPLow
            @PRTLN "Error at PACK FPLow value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @END
         @ENDIF
         @PRT "Successfull Packed " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
         @POPNULL
         @PUSH 0
      @ELSE
         @POPNULL
         @PUSH 1
      @ENDIF
   @ENDWHILE
@EndLocals
@END




:FPTable
$$$0x0            # +0.0
0 0 0 0
$$$0x80000000     # -0.0
1 0 0 0
$$$0x3f800000     # +1.0
0 127 0 0x80
$$$0xbf800000     # -1.0
1 127 0 0x80
$$$0x3fc00000     # +1.5
0 127 0 0xc0
$$$0x40490fdb     # +3.1415927
0 128 0xfdb 0xc9
$$$0x800000       # Smallest positive normal
0 1 0 0x80
$$$0x7f7fffff     # largest positive finite normal
0 254 0xffff 0xff
$$$0x7f800000     # +infinity (not implimented)
0 255 0 0
$$$0x7fc00000     # Quiet NaN (not implimneted)
0 255 0 0x40
$$$0x007fffff     # Largest positive sub-normal
0 0 0xffff 0x7f
9999 9999         # End code
