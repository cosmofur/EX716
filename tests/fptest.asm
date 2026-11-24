I commonDS.mc
L softstackDS.ld
L fpmath.ld

.CODE 0


:Main
.Entry Main
@DSSInitQuick
@Locals
   @Local Index

   # 32-bit working registers
   @Local32 Register32A
   @Local32 Register32B
   @Local32 Register32C
   @Local32 Register32D

   # 16-bit working registers
   @Local RegisterA
   @Local RegisterB
   @Local RegisterC
   @Local RegisterD
   @Local RegisterE
   @Local RegisterF
   @Local RegisterG
   @Local RegisterH
   @Local RegisterI
   @Local RegisterJ
   @Local RegisterK
   
M PRTPUSH32 @PUSHII %1 @PUSHI %1 @ADD 2 @PUSHS @PRTHEXTOP @SWP @PRTHEXTOP @SWP
M PRTPUSH48 \
      @PUSHI %1 @ADD 4 @PUSHS @PRTHEXTOP @POPNULL \
      @PUSHI %1 @ADD 2 @PUSHS @PRTHEXTOP \
      @PUSHII %1 @PRTHEXTOP \
      @SWP @PUSHI %1 @ADD 4 @PUSHS
      
@PRTLN "Start of test:"


# =========================================================
# FP2S_NORMALIZE_DECIMAL(FloatIn):(FloatOut,DecExponent)
#
=FPInput Register32A
=FPOutput Register32B
=DecExpFound RegisterA
=DecExpExpt RegisterB

    @MA2V NormalizeDecTable Index

    @PUSHII Index
    @WHILE_NEQ_A 9999
       @POPNULL

       # Read FP32 input (4 bytes)
       @PUSH32II(V) Index
       @POP32I(V) FPInput

       @INC2I Index
       @INC2I Index

       # Read expected decimal exponent (2 bytes)
       @PUSHII Index
       @POPI DecExpExpt
       @INC2I Index

       @PRT "Input: "
       @PRTHEXI FPInput+2
       @PRTHEXI FPInput

       @PRT " Expected DecExp: "
       @PRTHEXI DecExpExpt

       # Normalize FP32
       @Call32(V) FP2S_NORMALIZE_DECIMAL FPInput
       @POPI DecExpFound
       @POP32I(V) FPOutput

       @PRT " Output: "
       @PRTHEXI FPOutput+2
       @PRTHEXI FPOutput

       @PRT " DecExp: "
       @PRTHEXI DecExpFound
       @PRTNL

       @PUSHII Index
    @ENDWHILE
    @POPNULL
       
       
        
        

# ==========================================================
# FP_CMP Tests
#
# Test record:
#    A (32-bit), B (32-bit), ExpectedFlags (16-bit)
#
# Expected Flags32:
#    0 = A > B
#    3 = A < B (N32Flag | C32Flag)
#    4 = A = B (Z32Flag)
#
# ==========================================================
=CmpA          Register32A
=CmpB          Register32B
=CmpExpected   RegisterA
=CmpActual     RegisterB
=CmpIndex      RegisterC
=CmpTests      RegisterD
=CmpFailures   RegisterE

   @PRTLN "--------------------------------------------"
   @PRTLN "Testing FP_CMP"

   @MA2V 0 CmpTests
   @MA2V 0 CmpFailures
   @MA2V FPCmpTestVectors Index

   @PUSHII Index
   @WHILE_NEQ_A 9999
      @POPNULL

      @INCI CmpTests

      # Read operand A
      @PUSHII Index
      @POPI CmpA
      @INC2I Index

      @PUSHII Index
      @POPI CmpA+2
      @INC2I Index

      # Read operand B
      @PUSHII Index
      @POPI CmpB
      @INC2I Index

      @PUSHII Index
      @POPI CmpB+2
      @INC2I Index

      # Read expected Flags32
      @PUSHII Index
      @POPI CmpExpected
      @INC2I Index

      # Print operands
      @PRT "Test "
      @PRTHEXI CmpTests
      @PRT " Comparing: "
      @PRTHEXI CmpA+2
      @PRTHEXI CmpA
      @PRT " vs "
      @PRTHEXI CmpB+2
      @PRTHEXI CmpB

      # Perform floating point comparison
      @Call32(VV) FP_CMP CmpA CmpB

      # Preserve flags immediately
      @MV2V Flags32 CmpActual

      # Print actual and expected flags
      @PRT " Flags: "
      @PRTHEXI CmpActual
      @PRT " Expected: "
      @PRTHEXI CmpExpected
      @PRT " "

      # Compare complete Flags32 value
      @PUSHI CmpActual
      @IF_NEQ_V CmpExpected
         @PRT "FAIL"
         @INCI CmpFailures
      @ELSE
         @PRT "Pass"
      @ENDIF
      @POPNULL

      @PRTNL

      # Fetch next record
      @PUSHII Index
   @ENDWHILE
   @POPNULL

   @PRTLN "--------------------------------------------"
   @PRTLN "FP_CMP Summary:"
   @PRT "Tests: "
   @PRTHEXI CmpTests
   @PRT " Failures: "
   @PRTHEXI CmpFailures
   @PRTNL

   @PRT "Check Stack after FP_CMP Tests: "
   @PRTNL




   @PRTLN "=== FP_MUL Tests ==="
=FP1           Register32A

   @MA2V FPMulTable Index

   @PUSHII Index
   @WHILE_NEQ_A 9999
      @POPNULL

      # Operand A
      @PRT "FP_MUL: "
      @PRTPUSH32 Index

      @PRT " * "

      # Advance to operand B.
      @PUSHI Index
      @ADD 4
      @POPI Index

      # Operand B
      @PRTPUSH32 Index

      # Stack: A_Low A_High B_Low B_High
      @CALL FP_MUL

      # Result is a 32-bit value.
      @POP32I(V) FP1

      @PRT " = "
      @PRTHEXI FP1+2
      @PRTHEXI FP1

      # Advance to expected result.
      @PUSHI Index
      @ADD 4
      @POPI Index

      @PRT " expect: "
      @PRTPUSH32 Index

      # Discard expected result from stack.
      @POPNULL
      @POPNULL

      # Advance to next record (4 bytes).
      @PUSHI Index
      @ADD 4
      @POPI Index

      @PRTNL

      # Fetch next record's first word.
      @PUSHII Index
   @ENDWHILE
   @POPNULL

# ==========================================================
# FP_DIV Tests
#
# Test record:
#    Dividend (32-bit)
#    Divisor  (32-bit)
#    Expected (32-bit)
# ==========================================================

=FP1          Register32A
=FPExpected   Register32B
=DivFailed    RegisterA
=DivTests     RegisterC
=DivFailures  RegisterD

   @PRTLN "--------------------------------------------"
   @PRTLN "=== FP_DIV Tests ==="

   @MA2V 0 DivTests
   @MA2V 0 DivFailures
   @MA2V FPDivTable Index

   @PUSHII Index
   @WHILE_NEQ_A 9999
      @POPNULL

      @INCI DivTests
      @MA2V 0 DivFailed

      # Dividend
      @PRT "FP_DIV: "
      @PRTPUSH32 Index

      @PRT " / "

      # Advance to divisor.
      @PUSHI Index
      @ADD 4
      @POPI Index

      # Divisor
      @PRTPUSH32 Index

      # Stack: Dividend_Low Dividend_High
      #        Divisor_Low Divisor_High
      @CALL FP_DIV

      # Retrieve result.
      @POP32I(V) FP1

      @PRT " = "
      @PRTHEXI FP1+2
      @PRTHEXI FP1

      # Advance to expected result.
      @PUSHI Index
      @ADD 4
      @POPI Index

      # Read expected 32-bit value.
      @PUSHII Index
      @POPI FPExpected

      @PUSHI Index
      @ADD 2
      @PUSHS
      @POPI FPExpected+2

      @PRT " expect: "
      @PRTHEXI FPExpected+2
      @PRTHEXI FPExpected

      # Compare low word.
      @PUSHI FP1
      @IF_NEQ_V FPExpected
         @MA2V 1 DivFailed
      @ENDIF
      @POPNULL

      # Compare high word.
      @PUSHI FP1+2
      @IF_NEQ_V FPExpected+2
         @MA2V 1 DivFailed
      @ENDIF
      @POPNULL

      @PRT " "
      @PUSHI DivFailed
      @IF_EQ_A 0
         @PRT "Pass"
      @ELSE
         @PRT "FAIL"
         @INCI DivFailures
      @ENDIF
      @POPNULL

      @PRTNL

      # Advance past expected result.
      @PUSHI Index
      @ADD 4
      @POPI Index

      # Fetch next record.
      @PUSHII Index
   @ENDWHILE
   @POPNULL

   @PRTLN "--------------------------------------------"
   @PRTLN "FP_DIV Summary:"
   @PRT "Tests: "
   @PRTHEXI DivTests
   @PRT " Failures: "
   @PRTHEXI DivFailures
   @PRTNL

   @PRT "Check Stack after FP_DIV Tests: "
   @StackDump
   @PRTNL

=FP1           Register32B
=ExpAdjust     RegisterB


@MA2V PRDTable Index

@PUSHII Index
@WHILE_NEQ_A 9999
   @POPNULL

   # Product (48 bits)
   @PRT "Product: "
   @PRTPUSH48 Index

   @PRT " Mantissa: "

   # FP32_EXTRACT_PRODUCT consumes three words
   # and returns MantLow, MantHigh, ExpAdjust.
   @CALL FP32_EXTRACT_PRODUCT

   # Pop exponent adjustment first.
   @POPI ExpAdjust

   # Pop 32-bit mantissa.
   @POP32I(V) FP1

   @PRTHEXI FP1+2
   @PRTHEXI FP1

   @PRT " "
   @PRTHEXI ExpAdjust

   @PRT " vs "

   # Advance past 48-bit product.
   @PUSHI Index
   @ADD 6
   @POPI Index

   # Expected mantissa (32 bits)
   @PRTPUSH32 Index
   @POPNULL
   @POPNULL

   # Advance past expected mantissa.
   @INC2I Index
   @INC2I Index

   # Expected exponent adjustment (16 bits)
   @PRT " "
   @PUSHII Index
   @PRTTOP
   @POPNULL

   # Advance to next record.
   @INC2I Index



   @PUSHII Index
   @PRT "Next Word: "
   @PRTHEXTOP
   @PRTNL
@ENDWHILE
@POPNULL

@PRTLN "Test MUL24X24U"
=P0            RegisterB
=P1            RegisterC
=P2            RegisterD



   @MA2V MUL24X24UTable Index

   @PUSHII Index
   @WHILE_NEQ_A 9999
      @POPNULL

      @PRTPUSH32 Index
      @INC2I Index
      @INC2I Index
      @PRT " ** "
      @PRTPUSH32 Index
      @INC2I Index
      @INC2I Index      
       @PRT " = "
      @CALL MUL24X24U
      @POPI3 P2 P1 P0
      @PRTHEXI P2 @PRTHEXI P1 @PRTHEXI P0 @PRT " expect: "
      @PRTPUSH48 Index
      @PRTNL
      @POPNULL @POPNULL @POPNULL
      @PUSHI Index @ADD 6 @POPI Index
      @PUSHII Index
   @ENDWHILE
   @POPNULL
   @PRT "After MUL24X24U" @StackDump


   @PRTLN "Addition Test"

=FP1           Register32A
=FP2           Register32B
=FPR           Register32C
=FPExp         Register32D

   @MA2V AdditionTable Index

   @PUSHII Index
   @WHILE_NEQ_A 9999
       @POPNULL
       @PUSHII Index
       @POPI FP1
       @INC2I Index
       @PUSHII Index
       @POPI FP1+2
       @INC2I Index
       @PUSHII Index
       @POPI FP2
       @INC2I Index
       @PUSHII Index
       @POPI FP2+2
       @INC2I Index
       @PUSHII Index
       @POPI FPExp
       @INC2I Index
       @PUSHII Index
       @POPI FPExp+2
       @INC2I Index
       

       @PRT "Adding: " @PRTHEXI FP1+2 @PRTHEXI FP1 @PRT " + " @PRTHEXI FP2+2 @PRTHEXI FP2 @PRT " = "

       @Call32(VV) FP_ADD FP1 FP2
       @POP32I(V) FPR

       @PRTHEXI FPR+2 @PRTHEXI FPR @PRT " vs "

       @PRTHEXI FPExp+2 @PRTHEXI FPExp @PRT " "

       @Call32(VV) CMP32U FPR FPExp
       @IF32_EQ
          @PRT "Pass"
       @ELSE
          @PRT "Fail"
       @ENDIF
       @PRTNL

       @PUSHII Index
   @ENDWHILE
   @POPNULL
   @PRT "After Addition " @StackDump
   @PRTLN "--------------------------------------------"
   @PRTLN "Subtraction Test"

   @MA2V SubtractionTable Index
   @PUSHII Index
   @WHILE_NEQ_A 9999
       @POPNULL
       @PUSHII Index
       @POPI FP1
       @INC2I Index
       @PUSHII Index
       @POPI FP1+2
       @INC2I Index
       @PUSHII Index
       @POPI FP2
       @INC2I Index
       @PUSHII Index
       @POPI FP2+2
       @INC2I Index
       @PUSHII Index
       @POPI FPExp
       @INC2I Index
       @PUSHII Index
       @POPI FPExp+2
       @INC2I Index
       

       @PRT "Subtracting: " @PRTHEXI FP1+2 @PRTHEXI FP1 @PRT " - " @PRTHEXI FP2+2 @PRTHEXI FP2 @PRT " = "

       @Call32(VV) FP_SUB FP1 FP2
       @POP32I(V) FPR

       @PRTHEXI FPR+2 @PRTHEXI FPR @PRT " vs "

       @PRTHEXI FPExp+2 @PRTHEXI FPExp @PRT " "

       @Call32(VV) CMP32U FPR FPExp
       @IF32_EQ
          @PRT "Pass"
       @ELSE
          @PRT "Fail"
       @ENDIF
       @PRTNL

       @PUSHII Index
   @ENDWHILE
   @POPNULL
   @PRT "After Subtraction" @StackDump
       

   @PRTLN "Testing SHIFT_RIGHT_JAM32"



   @MA2V JamTestVectors Index

   @PUSHII Index
   @WHILE_NEQ_A 9999
      @POPNULL
      @PRT "Test " @PRTHEXI Index @PRTSP
      @PUSHII Index      
      @INC2I Index
      @PUSHII Index
      @INC2I Index
      @PRT "Testing: "
      @PRTHEXTOP @SWP @PRTHEXTOP @SWP
      @PUSHII Index
      @INC2I Index
      @CALL SHIFT_RIGHT_JAM32
      @PRT " Result "       @PRTHEXTOP      @POPNULL      @PRTHEXTOP       @POPNULL
      @PUSHII Index
      @INC2I Index
      @PUSHII Index
      @INC2I Index
      @PRT " Vs: " @PRTHEXTOP @SWP @PRTHEXTOP @PRTNL
      @POPNULL @POPNULL
      @PUSHII Index
   @ENDWHILE
   @POPNULL
   @PRTNL
   @PRT "Check Stack after SHIFT_RIGHT_JAM32 Tests: " @StackDump

   # ==========================================================
   # FP32_NORMALIZE tests
   #
   # Record:
   #   Sign, Exponent, MantLow, MantHigh
   #   ExpectedSign, ExpectedExponent, ExpectedLow, ExpectedHigh
   #
   # All fields are 16-bit words.
   # ==========================================================
=NormSign      RegisterB
=NormTests     RegisterC
=NormFailures  RegisterD
=NormExponent  RegisterE
=NormLow       RegisterF
=NormHigh      RegisterG
=NormSign      RegisterH
=ExpectedSign  RegisterI
=ExpectedExponent RegisterJ
=ExpectedLow   Register32A
=ExpectedHigh  Register32A+2



   @PRTLN "Testing FP32_NORMALIZE"

   @MA2V 0 NormTests
   @MA2V 0 NormFailures
   @MA2V NormalizeTestVectors Index

   @PUSHII Index
   @WHILE_NEQ_A 9999
      @POPNULL

      @INCI NormTests

      # Read four input words and advance table pointer
      @PUSHII Index
      @POPI NormSign
      @INC2I Index

      @PUSHII Index
      @POPI NormExponent
      @INC2I Index

      @PUSHII Index
      @POPI NormLow
      @INC2I Index

      @PUSHII Index
      @POPI NormHigh
      @INC2I Index

      # Call the normalizer
      @PUSHI4 NormSign NormExponent NormLow NormHigh
      @CALL FP32_NORMALIZE

      # Return order: Sign, Exponent, Low, High
      @POPI4 NormHigh NormLow NormExponent NormSign

      # Read expected output
      @PUSHII Index
      @POPI ExpectedSign
      @INC2I Index

      @PUSHII Index
      @POPI ExpectedExponent
      @INC2I Index

      @PUSHII Index
      @POPI ExpectedLow
      @INC2I Index

      @PUSHII Index
      @POPI ExpectedHigh
      @INC2I Index

      # Display actual and expected results
      @PRT "Test " @PRTHEXI NormTests
      @PRT " Actual: "
      @PRTHEXI NormSign
      @PRTHEXI NormExponent
      @PRTHEXI NormHigh
      @PRTHEXI NormLow

      @PRT " Expected: "
      @PRTHEXI ExpectedSign
      @PRTHEXI ExpectedExponent
      @PRTHEXI ExpectedHigh
      @PRTHEXI ExpectedLow
      @PRTNL

      # Compare each returned word
      @PUSHI NormSign
      @IF_NEQ_V ExpectedSign
         @PRTLN "  FAIL: Sign"
         @INCI NormFailures
      @ENDIF
      @POPNULL

      @PUSHI NormExponent
      @IF_NEQ_V ExpectedExponent
         @PRTLN "  FAIL: Exponent"
         @INCI NormFailures
      @ENDIF
      @POPNULL

      @PUSHI NormLow
      @IF_NEQ_V ExpectedLow
         @PRTLN "  FAIL: MantLow"
         @INCI NormFailures
      @ENDIF
      @POPNULL

      @PUSHI NormHigh
      @IF_NEQ_V ExpectedHigh
         @PRTLN "  FAIL: MantHigh"
         @INCI NormFailures
      @ENDIF
      @POPNULL

      @PUSHII Index
   @ENDWHILE
   @POPNULL

   @PRT "After FP32_NORMALIZE" @StackDump

   @PRTLN "FP32_NORMALIZE summary:"
   @PRT "Tests: " @PRTHEXI NormTests
   @PRT " Word mismatches: " @PRTHEXI NormFailures
   @PRTNL
   @PRTNL

=FPLow        RegisterB
=FPHigh       RegisterC
=Jndex        RegisterD
=MantLow      RegisterE
=MantHigh     RegisterF
=Expoent      RegisterG
=Sign         RegisterH

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
            @CALL DetailPrint
            @END
         @ENDIF
         @POPNULL
         @PUSHII Index
         @INC2I Index
         @IF_NEQ_V Exponent
            @PRTLN "Error at Exponent value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @CALL DetailPrint            
            @END
         @ENDIF
         @POPNULL
         @PUSHII Index
         @INC2I Index
         @IF_NEQ_V MantLow
            @PRTLN "Error at MantLow value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @CALL DetailPrint            
            @END
         @ENDIF
         @POPNULL
         @PUSHII Index
         @INC2I Index
         @IF_NEQ_V MantHigh
            @PRTLN "Error at MantHigh value " @PRTHEXI MantHigh @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @CALL DetailPrint            
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
            @CALL DetailPrint            
            @END
         @ENDIF
         @POPNULL
         @IF_NEQ_V FPLow
            @PRTLN "Error at PACK FPLow value " @PRTHEXI FPHigh @PRTHEXI FPLow @PRTNL
            @CALL DetailPrint            
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
   @POPNULL
   @PRTLN "End of run." @StackDump
@END

:DetailPrint
@PRTLN "More Data:"
@PRT "Index: " @PRTHEXI Index @PRTNL
@PRT "Jndex: " @PRTHEXI Jndex @PRTNL
@PRT "MantLow: " @PRTHEXI MantLow @PRTNL
@PRT "MantHigh: " @PRTHEXI MantHigh @PRTNL
@PRT "Exponent: " @PRTHEXI Exponent @PRTNL
@PRT "Sign: " @PRTHEXI Sign @PRTNL
@PRT "FPLow: " @PRTHEXI FPLow @PRTNL
@PRT "FPHigh: " @PRTHEXI FPHigh @PRTNL
@StackDump
@RET
@EndLocals



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
$$$0xff800000     # -infinity
1 255 0x0000 0x0000
$$$0x807fffff     # largest negative subnormal (magnitude)
1 0 0xffff 0x007f
$$$0x00000001     # smallest positive subnormal
0 0 0x0001 0x0000
$$$0x7f800001     # positive signaling NaN
0 255 0x0001 0x0000
$$$0xffc12345     # negative quiet NaN with payload
1 255 0x2345 0x0041



9999 9999         # End code

:JamTestVectors
   $$$0x00000000  0   $$$0x00000000
   $$$0x12345678  0   $$$0x12345678
   $$$0x00000002  1   $$$0x00000001
   $$$0x00000003  1   $$$0x00000001
   $$$0x00000005  1   $$$0x00000003
   $$$0x00000008  2   $$$0x00000002
   $$$0x00000009  2   $$$0x00000003
   $$$0x00000007  2   $$$0x00000001
   $$$0x80000000  1   $$$0x40000000
   $$$0xffffffff  1   $$$0x7fffffff
   $$$0x12345678  4   $$$0x01234567
   $$$0x12345670  4   $$$0x01234567
   $$$0x80000000  31  $$$0x00000001
   $$$0x7fffffff  31  $$$0x00000001
   $$$0xffffffff  32  $$$0x00000001
   $$$0x80000000  32  $$$0x00000001
   $$$0x00000000  32  $$$0x00000000
   $$$0x00000001  33  $$$0x00000001
   9999 9999 9999
   

:NormalizeTestVectors

   # 1. Positive zero
   0 0 0x0000 0x0000
   0 0 0x0000 0x0000

   # 2. Negative zero
   1 0 0x0000 0x0000
   1 0 0x0000 0x0000

   # 3. Positive 1.0, already normalized
   0 0 0x0000 0x0400
   0 127 0x0000 0x0080

   # 4. Negative 1.0, already normalized
   1 0 0x0000 0x0400
   1 127 0x0000 0x0080

   # 5. Positive 1.5, already normalized
   0 0 0x0000 0x0600
   0 127 0x0000 0x00c0

   # 6. Carry bit set, normalize to 2.0
   0 0 0x0000 0x0800
   0 128 0x0000 0x0080

   # 7. Left normalization, exponent adjustment
   0 1 0x0000 0x0200
   0 127 0x0000 0x0080

   # 8. Largest finite positive number
   0 127 0xfff8 0x07ff
   0 254 0xffff 0x00ff

   # 9. Positive exponent overflow
   0 128 0x0000 0x0400
   0 255 0x0000 0x0000

   # 10. Negative exponent overflow
   1 128 0x0000 0x0400
   1 255 0x0000 0x0000

   # 11. Smallest positive normal
   0 -126 0x0000 0x0400
   0 1 0x0000 0x0080

   # 12. Largest positive subnormal
   0 -126 0xfff8 0x03ff
   0 0 0xffff 0x007f

   # 13. Smallest positive subnormal
   0 -126 0x0008 0x0000
   0 0 0x0001 0x0000

   # 14. Subnormal rounds up to smallest normal
   0 -126 0xfffc 0x03ff
   0 1 0x0000 0x0080

   # 15. Tie to even, retained fraction even
   0 0 0x0004 0x0400
   0 127 0x0000 0x0080

   # 16. Tie to even, retained fraction odd
   0 0 0x000c 0x0400
   0 127 0x0002 0x0080

   # 17. Round upward because sticky bit set
   0 0 0x0005 0x0400
   0 127 0x0001 0x0080

   # 18. Rounding carry into next exponent
   0 0 0xfffc 0x07ff
   0 128 0x0000 0x0080

   # 19. Underflow below half minimum subnormal
   0 -150 0x0000 0x0200
   0 0 0x0000 0x0000

   # 20. Underflow tie, rounds to even zero
   0 -150 0x0000 0x0400
   0 0 0x0000 0x0000

   # 21. Underflow with sticky, rounds to subnormal
   0 -150 0x0001 0x0400
   0 0 0x0001 0x0000

   # End of table
   9999

:AdditionTable
$$$0x40A00000 $$$0x40A00000 $$$0x41200000  # 5 + 5
$$$0x40A00000 $$$0x00000000 $$$0x40A00000  # 5 + 0
$$$0x00000000 $$$0x40A00000 $$$0x40A00000  # 0 + 5
$$$0x40A00000 $$$0xC0A00000 $$$0x00000000  # 5 + (-5)
$$$0x40A00000 $$$0xC0000000 $$$0x40400000  # 5 + (-2)
$$$0xC0A00000 $$$0xC0000000 $$$0xC0E00000  # -5 + (-2)
$$$0x3F800000 $$$0x3F000000 $$$0x3FC00000  # 1 + 0.5
$$$0x3F800000 $$$0x3E800000 $$$0x3FA00000  # 1 + 0.25
$$$0x42C80000 $$$0x41C80000 $$$0x42FA0000  # 100 + 25
$$$0x3F800000 $$$0xBF800000 $$$0x00000000  # 1 + (-1)
$$$0x80000000 $$$0x80000000 $$$0x80000000  # -0 + -0
$$$0x3F800000 $$$0x00000001 $$$0x3F800000  # 1 + smallest subnormal
$$$0x3f800000 $$$0x33800000 $$$0x3f800000
$$$0x3f800001 $$$0x33800000 $$$0x3f800002

    # Extended binary32 test cases (round-to-nearest, ties-to-even)

    # --- Signed zeros ---
    $$$0x00000000 $$$0x80000000 $$$0x00000000  # +0 and -0
    $$$0x80000000 $$$0x00000000 $$$0x00000000  # -0 and +0
    $$$0x80000000 $$$0x80000000 $$$0x80000000  # -0 and -0
    $$$0x00000000 $$$0x00000000 $$$0x00000000  # +0 and +0

    # --- Cancellation and sign ---
    $$$0x3f800000 $$$0xbf800000 $$$0x00000000  # 1 and -1
    $$$0xbf800000 $$$0x3f800000 $$$0x00000000  # -1 and 1
    $$$0x7f7fffff $$$0xff7fffff $$$0x00000000  # maximum finite cancellation
    $$$0x00800000 $$$0x80800000 $$$0x00000000  # minimum normals cancel
    $$$0x00000001 $$$0x80000001 $$$0x00000000  # minimum subnormals cancel
    $$$0x3f800001 $$$0xbf800000 $$$0x34000000  # one ULP difference
    $$$0x3f800000 $$$0xbf800001 $$$0xb4000000  # negative one ULP difference

    # --- Subnormal and normal boundary ---
    $$$0x00000001 $$$0x00000001 $$$0x00000002  # smallest subnormal plus itself
    $$$0x007fffff $$$0x00000001 $$$0x00800000  # largest subnormal plus minimum subnormal
    $$$0x007fffff $$$0x007fffff $$$0x00fffffe  # largest subnormal doubled
    $$$0x00800000 $$$0x00000001 $$$0x00800001  # minimum normal plus minimum subnormal
    $$$0x00800000 $$$0x807fffff $$$0x00000001  # minimum normal minus largest subnormal
    $$$0x00800001 $$$0x80800000 $$$0x00000001  # normal difference of one subnormal
    $$$0x00400000 $$$0x00400000 $$$0x00800000  # two half-minimum normals
    $$$0x80000001 $$$0x80000001 $$$0x80000002  # negative subnormal addition
    $$$0x00800000 $$$0x80000001 $$$0x007fffff  # minimum normal minus minimum subnormal

    # --- Rounding and tie-to-even ---
    $$$0x3f800000 $$$0x33800000 $$$0x3f800000  # 1 plus half ULP ties down
    $$$0x3f800001 $$$0x33800000 $$$0x3f800002  # odd LSB plus half ULP ties up
    $$$0x3f800002 $$$0x33800000 $$$0x3f800002  # even LSB plus half ULP ties down
    $$$0x3f800003 $$$0x33800000 $$$0x3f800004  # odd LSB plus half ULP ties up
    $$$0x3f800000 $$$0x33800001 $$$0x3f800001  # just above half ULP
    $$$0x3f800000 $$$0x337fffff $$$0x3f800000  # just below half ULP
    $$$0xbf800000 $$$0xb3800000 $$$0xbf800000  # negative tie
    $$$0xbf800001 $$$0xb3800000 $$$0xbf800002  # negative odd tie
    $$$0x3f800000 $$$0x34000000 $$$0x3f800001  # exactly one ULP
    $$$0x3f800000 $$$0x00000001 $$$0x3f800000  # huge exponent difference
    $$$0x3f800001 $$$0x00000001 $$$0x3f800001  # tiny addend to odd LSB
    $$$0x3f800000 $$$0x33000000 $$$0x3f800000  # quarter ULP
    $$$0x3f800000 $$$0x33c00000 $$$0x3f800001  # three-quarter ULP

    # --- Exponent and significand boundaries ---
    $$$0x3fffffff $$$0x33800000 $$$0x40000000  # carry across 2 boundary
    $$$0x3f7fffff $$$0x33800000 $$$0x3f800000  # below 1 plus half ULP
    $$$0x3f7fffff $$$0x33000000 $$$0x3f800000  # below 1 plus quarter ULP
    $$$0x3f800000 $$$0x3f800000 $$$0x40000000  # 1 plus 1
    $$$0x3f000000 $$$0x3f000000 $$$0x3f800000  # half plus half

    # OPTIONAL (requires infinity handling):
    # $$$0x7f000000 $$$0x7f000000 $$$0x7f800000

    $$$0x7f7fffff $$$0x00000001 $$$0x7f7fffff  # maximum finite plus tiny

    # OPTIONAL (requires infinity handling):
    # $$$0x7f7fffff $$$0x7f7fffff $$$0x7f800000
    # $$$0xff7fffff $$$0xff7fffff $$$0xff800000

    $$$0x4b800000 $$$0x3f800000 $$$0x4b800000  # 2^24 plus 1 tie
    $$$0x4b800001 $$$0x3f800000 $$$0x4b800002  # 2^24+2 plus 1 tie
    $$$0x4b7fffff $$$0x3f800000 $$$0x4b800000  # 2^24-1 plus 1
    $$$0x7e800000 $$$0x3f800000 $$$0x7e800000  # large exponent gap

    # --- Mixed signs and alignment ---
    $$$0x3f800000 $$$0xbf000000 $$$0x3f000000  # 1 plus -0.5
    $$$0x3f000000 $$$0xbf800000 $$$0xbf000000  # 0.5 plus -1
    $$$0x3f800000 $$$0xbeffffff $$$0x3f000000  # 1 plus near -0.5
    $$$0x3f800001 $$$0xbf800000 $$$0x34000000  # near cancellation
    $$$0x3f800000 $$$0xbf7fffff $$$0x33800000  # near cancellation below 1
    $$$0x00800000 $$$0x80000001 $$$0x007fffff  # normal plus negative min subnormal
    $$$0x3f800000 $$$0x80800000 $$$0x3f800000  # 1 plus negative minimum normal

9999 9999 9999


:SubtractionTable
$$$0x40A00000 $$$0x40000000 $$$0x40400000  # 5 - 2 = 3
$$$0x40A00000 $$$0xC0000000 $$$0x40E00000  # 5 - (-2) = 7
$$$0xC0A00000 $$$0x40000000 $$$0xC0E00000  # -5 - 2 = -7
$$$0x40A00000 $$$0x40A00000 $$$0x00000000  # 5 - 5 = 0
$$$0x00000000 $$$0x40A00000 $$$0xC0A00000  # 0 - 5 = -5
$$$0x80000000 $$$0x00000000 $$$0x80000000  # -0 - +0 = -0
$$$0x3F800000 $$$0x33800000 $$$0x3F7FFFFF  # 1 - half ULP
$$$0x3F800001 $$$0x33800000 $$$0x3F800000  # Tie rounds to even

    # Extended binary32 test cases (round-to-nearest, ties-to-even)

    # --- Signed zeros ---
    $$$0x00000000 $$$0x00000000 $$$0x00000000  # +0 minus +0
    $$$0x00000000 $$$0x80000000 $$$0x00000000  # +0 minus -0
    $$$0x80000000 $$$0x00000000 $$$0x80000000  # -0 minus +0
    $$$0x80000000 $$$0x80000000 $$$0x00000000  # -0 minus -0

    # --- Cancellation and signs ---
    $$$0x3f800000 $$$0x3f800000 $$$0x00000000  # 1 minus 1
    $$$0xbf800000 $$$0xbf800000 $$$0x00000000  # -1 minus -1
    $$$0x7f7fffff $$$0x7f7fffff $$$0x00000000  # max finite minus itself
    $$$0x3f800001 $$$0x3f800000 $$$0x34000000  # positive one ULP
    $$$0x3f800000 $$$0x3f800001 $$$0xb4000000  # negative one ULP
    $$$0x3f800000 $$$0xbf800000 $$$0x40000000  # 1 minus -1
    $$$0xbf800000 $$$0x3f800000 $$$0xc0000000  # -1 minus 1
    $$$0x00800000 $$$0x00800000 $$$0x00000000  # min normal minus itself
    $$$0x00000001 $$$0x00000001 $$$0x00000000  # min subnormal minus itself

    # --- Subnormal and normal boundary ---
    $$$0x00800000 $$$0x00000001 $$$0x007fffff  # min normal minus min subnormal
    $$$0x00800000 $$$0x007fffff $$$0x00000001  # min normal minus max subnormal
    $$$0x00800001 $$$0x00800000 $$$0x00000001  # normal difference one subnormal
    $$$0x007fffff $$$0x00000001 $$$0x007ffffe  # max subnormal minus min subnormal
    $$$0x00000001 $$$0x00000002 $$$0x80000001  # min subnormal minus two subnormals
    $$$0x80000001 $$$0x00000001 $$$0x80000002  # negative subnormal minus positive
    $$$0x00800000 $$$0x80000001 $$$0x00800001  # min normal minus negative min subnormal
    $$$0x00400000 $$$0x80400000 $$$0x00800000  # half normal minus negative half normal
    $$$0x00000001 $$$0x00800000 $$$0x807fffff  # tiny minus normal

    # --- Rounding and tie-to-even ---
    $$$0x3f800000 $$$0x33800000 $$$0x3f7fffff  # 1 minus half ULP (exact predecessor)
    $$$0x3f800001 $$$0x33800000 $$$0x3f800000  # odd LSB minus half ULP ties even
    $$$0x3f800002 $$$0x33800000 $$$0x3f800002  # even LSB minus half ULP ties even
    $$$0x3f800003 $$$0x33800000 $$$0x3f800002  # odd LSB minus half ULP ties even
    $$$0x3f800000 $$$0x33800001 $$$0x3f7fffff  # just over half ULP below 1
    $$$0x3f800000 $$$0x337fffff $$$0x3f7fffff  # just under half ULP below 1
    $$$0x3f800000 $$$0xb3800000 $$$0x3f800000  # subtract negative half ULP ties down
    $$$0x3f800001 $$$0xb3800000 $$$0x3f800002  # subtract negative half ULP ties up
    $$$0xbf800000 $$$0x33800000 $$$0xbf800000  # negative one minus half ULP
    $$$0xbf800001 $$$0x33800000 $$$0xbf800002  # negative odd LSB minus half ULP
    $$$0x4b800000 $$$0x3f800000 $$$0x4b7fffff  # 2^24 minus 1
    $$$0x4b800001 $$$0x3f800000 $$$0x4b800000  # 2^24+2 minus 1 tie

    # --- Exponent and significand boundaries ---
    $$$0x40000000 $$$0x3f800000 $$$0x3f800000  # 2 minus 1
    $$$0x3f800000 $$$0x3f7fffff $$$0x33800000  # 1 minus predecessor
    $$$0x3f800000 $$$0x3f800001 $$$0xb4000000  # 1 minus successor

    # OPTIONAL (requires infinity handling):
    # $$$0x7f7fffff $$$0xff7fffff $$$0x7f800000
    # $$$0xff7fffff $$$0x7f7fffff $$$0xff800000

    $$$0x7f7fffff $$$0x00000001 $$$0x7f7fffff  # max finite minus min subnormal
    $$$0x7f000000 $$$0xff000000 $$$0x7f800000  # large opposite signs
    $$$0x3f800000 $$$0x00000001 $$$0x3f800000  # 1 minus min subnormal
    $$$0x00000001 $$$0x3f800000 $$$0xbf800000  # min subnormal minus 1
    $$$0x3f800000 $$$0x00800000 $$$0x3f800000  # 1 minus min normal
    $$$0x3f800000 $$$0x3f000000 $$$0x3f000000  # 1 minus half
    $$$0x3f000000 $$$0x3f800000 $$$0xbf000000  # half minus 1

9999 9999 9999
:MUL24X24UTable
$$$0x000000 $$$0xFFFFFF 0x0000 0x0000 0x0000 # 0000 0000 0000
$$$0x000001 $$$0xFFFFFF 0xFFFF 0x00FF 0x0000 # 0000 00FF FFFF
$$$0x000100 $$$0x000100 0x0000 0x0001 0x0000 # 0000 0001 0000
$$$0x00FFFF $$$0x00FFFF 0x0001 0xFFFE 0x0000 # 0000 FFFE 0001
$$$0x800000 $$$0x800000 0x0000 0x0000 0x4000 # 4000 0000 0000
$$$0x800000 $$$0xFFFFFF 0x0000 0xFF80 0x7FFF # 7FFF FF80 0000
$$$0xFFFFFF $$$0xFFFFFF 0x0001 0xFE00 0xFFFF # FFFF FE00 0001
$$$0x000001 $$$0x000001 0x0001 0x0000 0x0000 # 0000 0000 0001
$$$0x000001 $$$0x800000 0x0000 0x0080 0x0000 # 0000 0080 0000
$$$0x010000 $$$0x010000 0x0000 0x0000 0x0001 # 0001 0000 0000
$$$0xFFFFFF $$$0x000001 0xFFFF 0x00FF 0x0000 # 0000 00FF FFFF
$$$0xFFFFFF $$$0x000100 0xFF00 0xFFFF 0x0000 # 0000 FFFF FF00
$$$0xFFFFFF $$$0xFFFFFF 0x0001 0xFE00 0xFFFF # FFFF FE00 0001
9999 9999 9999



:PRDTable
0x0000 0x0000 0x4000 $$$0x04000000 0 # 400000000000
0x0000 0xFF80 0x7FFF $$$0x07FFFFF8 0 # 7FFFFF800000
0x0000 0x0000 0x8000 $$$0x04000000 1 # 800000000000
0x0001 0xFE00 0xFFFF $$$0x07FFFFF1 1 # FFFFFE000001
0x0001 0x0000 0x4000 $$$0x04000001 0 # 400000000001
0x0001 0x0000 0x8000 $$$0x04000001 1 # 800000000001
9999 9999 9999 9999 9999 


:FPMulTable
# A            B            Expected
$$$0x3F800000 $$$0x3F800000 $$$0x3F800000 # 1.0 * 1.0
$$$0x40000000 $$$0x40400000 $$$0x40C00000 # 2.0 * 3.0
$$$0xC0000000 $$$0x40400000 $$$0xC0C00000 # -2.0 * 3.0
$$$0x3FC00000 $$$0x3FC00000 $$$0x40100000 # 1.5 * 1.5
$$$0x3F000000 $$$0x3F000000 $$$0x3E800000 # 0.5 * 0.5
$$$0xBF800000 $$$0xBF800000 $$$0x3F800000 # -1.0 * -1.0
$$$0x40400000 $$$0x3F000000 $$$0x3FC00000 # 3.0 * 0.5
$$$0x3F800000 $$$0x00000000 $$$0x00000000 # 1.0 * 0.0
$$$0xBF800000 $$$0x00000000 $$$0x80000000 # -1.0 * 0.0
$$$0x00000000 $$$0xBF800000 $$$0x80000000 # 0.0 * -1.0
# Rounding and precision
$$$0x3F800001 $$$0x3F800001 $$$0x3F800002 # (1+ULP)^2, rounding
$$$0x3FFFFFFF $$$0x3FFFFFFF $$$0x407FFFFE # Near 2.0 squared
$$$0x3F7FFFFF $$$0x3F7FFFFF $$$0x3F7FFFFE # Just below 1.0 squared

# Exponent boundaries
$$$0x7F7FFFFF $$$0x40000000 $$$0x7F800000 # Overflow to +infinity
$$$0x7F7FFFFF $$$0x3F000000 $$$0x7EFFFFFF # Largest finite / 2
$$$0x00800000 $$$0x3F800000 $$$0x00800000 # Smallest normal * 1

# Underflow and subnormal results
$$$0x00800000 $$$0x3F000000 $$$0x00400000 # Normal -> subnormal
$$$0x00000001 $$$0x3F800000 $$$0x00000001 # Smallest subnormal * 1
$$$0x007FFFFF $$$0x40000000 $$$0x00FFFFFE # Largest subnormal * 2
$$$0x00800000 $$$0x00800000 $$$0x00000000 # Underflow to zero
# Smallest subnormal * 1E32
0x0001 0x0000  0xC5AE 0x749D  0xC5AE 0x2A1D

# 1E32 * Smallest subnormal
0xC5AE 0x749D  0x0001 0x0000  0xC5AE 0x2A1D

# Smallest subnormal * Smallest subnormal
0x0001 0x0000  0x0001 0x0000  0x0000 0x0000

# Smallest subnormal * 0.5 (round to even)
0x0001 0x0000  0x0000 0x3F00  0x0000 0x0000

# Three times smallest subnormal * 0.5 (round to even)
0x0003 0x0000  0x0000 0x3F00  0x0002 0x0000
9999


# ==========================================================
# FP_CMP Test Vectors
#
# A               B               Expected Flags32
#
# Flags:
#    Less    = 3 (N | C)
#    Equal   = 4 (Z)
#    Greater = 0
# ==========================================================

:FPCmpTestVectors

   # --- Positive numbers ---
   $$$0x3F800000 $$$0x40000000 3  # 1 < 2
   $$$0x40000000 $$$0x3F800000 0  # 2 > 1
   $$$0x3F800000 $$$0x3F800000 4  # 1 = 1
   $$$0x40A00000 $$$0x41200000 3  # 5 < 10
   $$$0x41200000 $$$0x40A00000 0  # 10 > 5
   $$$0x41200000 $$$0x41200000 4  # 10 = 10

   # --- Negative numbers ---
   $$$0xBF800000 $$$0xC0000000 0  # -1 > -2
   $$$0xC0000000 $$$0xBF800000 3  # -2 < -1
   $$$0xBF800000 $$$0xBF800000 4  # -1 = -1
   $$$0xC0A00000 $$$0xC1200000 0  # -5 > -10
   $$$0xC1200000 $$$0xC0A00000 3  # -10 < -5
   $$$0xC1200000 $$$0xC1200000 4  # -10 = -10

   # --- Opposite signs ---
   $$$0xBF800000 $$$0x3F800000 3  # -1 < +1
   $$$0x3F800000 $$$0xBF800000 0  # +1 > -1
   $$$0xC0A00000 $$$0x40A00000 3  # -5 < +5
   $$$0x40A00000 $$$0xC0A00000 0  # +5 > -5
   $$$0xC1200000 $$$0x3F800000 3  # -10 < +1
   $$$0x3F800000 $$$0xC1200000 0  # +1 > -10

   # --- Signed zero ---
   $$$0x00000000 $$$0x00000000 4  # +0 = +0
   $$$0x80000000 $$$0x80000000 4  # -0 = -0
   $$$0x00000000 $$$0x80000000 4  # +0 = -0
   $$$0x80000000 $$$0x00000000 4  # -0 = +0

   # --- Zero versus positive ---
   $$$0x00000000 $$$0x3F800000 3  # +0 < +1
   $$$0x3F800000 $$$0x00000000 0  # +1 > +0
   $$$0x80000000 $$$0x3F800000 3  # -0 < +1
   $$$0x3F800000 $$$0x80000000 0  # +1 > -0

   # --- Zero versus negative ---
   $$$0x00000000 $$$0xBF800000 0  # +0 > -1
   $$$0xBF800000 $$$0x00000000 3  # -1 < +0
   $$$0x80000000 $$$0xBF800000 0  # -0 > -1
   $$$0xBF800000 $$$0x80000000 3  # -1 < -0

   # --- Equal magnitudes, opposite signs ---
   $$$0x40400000 $$$0xC0400000 0  # +3 > -3
   $$$0xC0400000 $$$0x40400000 3  # -3 < +3

   # --- Same exponent, different mantissa ---
   $$$0x3F800000 $$$0x3F800001 3  # 1 < next float
   $$$0x3F800001 $$$0x3F800000 0  # next float > 1
   $$$0xBF800000 $$$0xBF800001 0  # -1 > next negative
   $$$0xBF800001 $$$0xBF800000 3  # next negative < -1

   # --- Exponent boundaries ---
   $$$0x3FFFFFFF $$$0x40000000 3  # Just below 2 < 2
   $$$0x40000000 $$$0x3FFFFFFF 0  # 2 > just below 2
   $$$0xBFFFFFFF $$$0xC0000000 0  # Negative ordering
   $$$0xC0000000 $$$0xBFFFFFFF 3  # Reverse negative ordering

   # --- Subnormal numbers ---
   $$$0x00000001 $$$0x00000002 3  # Smallest subnormal < next
   $$$0x00000002 $$$0x00000001 0
   $$$0x80000001 $$$0x80000002 0
   $$$0x80000002 $$$0x80000001 3
   $$$0x00000000 $$$0x00000001 3
   $$$0x80000001 $$$0x00000000 3
   $$$0x00000000 $$$0x80000001 0
   $$$0x00000001 $$$0x80000001 0

   # --- Subnormal / normal boundary ---
   $$$0x007FFFFF $$$0x00800000 3
   $$$0x00800000 $$$0x007FFFFF 0
   $$$0x807FFFFF $$$0x80800000 0
   $$$0x80800000 $$$0x807FFFFF 3

   # --- Largest finite values ---
   $$$0x7F7FFFFF $$$0x3F800000 0
   $$$0x3F800000 $$$0x7F7FFFFF 3
   $$$0xFF7FFFFF $$$0xBF800000 3
   $$$0xBF800000 $$$0xFF7FFFFF 0
   $$$0xFF7FFFFF $$$0x7F7FFFFF 3
   $$$0x7F7FFFFF $$$0xFF7FFFFF 0

   # --- Equality across exponent ranges ---
   $$$0x00000001 $$$0x00000001 4
   $$$0x00800000 $$$0x00800000 4
   $$$0x3F800000 $$$0x3F800000 4
   $$$0x7F7FFFFF $$$0x7F7FFFFF 4
   $$$0xFF7FFFFF $$$0xFF7FFFFF 4

   # End of table
   9999 9999 9999
# ==========================================================
# FP_DIV Test Vectors
#
# Dividend     Divisor      Expected
# ==========================================================
:FPDivTable

# Basic division
$$$0x3F800000 $$$0x3F800000 $$$0x3F800000 # 1 / 1 = 1
$$$0x40C00000 $$$0x40400000 $$$0x40000000 # 6 / 3 = 2
$$$0x40400000 $$$0x40000000 $$$0x3FC00000 # 3 / 2 = 1.5
$$$0x41200000 $$$0x40800000 $$$0x40200000 # 10 / 4 = 2.5
$$$0x40E00000 $$$0x40000000 $$$0x40600000 # 7 / 2 = 3.5

# Powers of two
$$$0x3F800000 $$$0x40000000 $$$0x3F000000 # 1 / 2 = 0.5
$$$0x3F800000 $$$0x40800000 $$$0x3E800000 # 1 / 4 = 0.25
$$$0x40800000 $$$0x3F800000 $$$0x40800000 # 4 / 1 = 4
$$$0x40000000 $$$0x3F000000 $$$0x40800000 # 2 / 0.5 = 4

# Quotient normalization
$$$0x3F800000 $$$0x3FC00000 $$$0x3F2AAAAB # 1 / 1.5
$$$0x3FC00000 $$$0x3F800000 $$$0x3FC00000 # 1.5 / 1
$$$0x3FC00000 $$$0x3FC00000 $$$0x3F800000 # 1.5 / 1.5
$$$0x3F000000 $$$0x3F800000 $$$0x3F000000 # 0.5 / 1

# Repeating binary fractions and rounding
$$$0x3F800000 $$$0x40400000 $$$0x3EAAAAAB # 1 / 3
$$$0x40000000 $$$0x40400000 $$$0x3F2AAAAB # 2 / 3
$$$0x40400000 $$$0x40A00000 $$$0x3F19999A # 3 / 5
$$$0x3F800000 $$$0x40A00000 $$$0x3E4CCCCD # 1 / 5

# Signed operands
$$$0xC0C00000 $$$0x40400000 $$$0xC0000000 # -6 / 3 = -2
$$$0x40C00000 $$$0xC0400000 $$$0xC0000000 # 6 / -3 = -2
$$$0xC0C00000 $$$0xC0400000 $$$0x40000000 # -6 / -3 = 2
$$$0xBF800000 $$$0x3F800000 $$$0xBF800000 # -1 / 1 = -1

# Zero numerator
$$$0x00000000 $$$0x40400000 $$$0x00000000 # +0 / 3 = +0
$$$0x80000000 $$$0x40400000 $$$0x80000000 # -0 / 3 = -0
$$$0x00000000 $$$0xC0400000 $$$0x80000000 # +0 / -3 = -0

# Division by zero (signed infinity)
$$$0x3F800000 $$$0x00000000 $$$0x7F800000 # 1 / +0 = +Inf
$$$0xBF800000 $$$0x00000000 $$$0xFF800000 # -1 / +0 = -Inf
$$$0x3F800000 $$$0x80000000 $$$0xFF800000 # 1 / -0 = -Inf

# Exponent boundaries
$$$0x00800000 $$$0x3F800000 $$$0x00800000 # Min normal / 1
$$$0x7F7FFFFF $$$0x3F800000 $$$0x7F7FFFFF # Max finite / 1
$$$0x7F7FFFFF $$$0x3F000000 $$$0x7F800000 # Overflow

# End of table
9999

:NormalizeDecTable
# Low    High    Expected decimal exponent
0x0000 0x3F80     0     # 1.0
0x0000 0x4120     1     # 10.0
0x0000 0x42C8     2     # 100.0
0xCCCD 0x3DCC    -1     # 0.1
0x0000 0x3F00    -1     # 0.5
0x0FDB 0x4049     0     # Pi
0xE400 0x4640     4     # 12345.0
0xBC20 0x4CBE     8     # 1E8
0xFFFF 0x3F7F    -1     # Just below 1
0x0001 0x4120     1     # Just above 10
0x0000 0x0080   -38     # Smallest normal
0xFFFF 0x007F   -38     # Largest subnormal
0x0001 0x0000   -45     # Smallest subnormal
0xFFFF 0x7F7F    38     # Largest finite FP32
9999
