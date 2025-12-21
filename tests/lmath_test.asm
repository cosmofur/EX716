I common.mc
L softstack.ld
L lmath.ld


# The $$$ notation means the following is a 32 bit value.
# It is only valid when the 32 bit value is going to be inserted into memory
# a the assemblers current insertion point.
# It an not be used as a constant directly or as part of any operation
:AVar $$$1
:BVar $$$100000
:RVar $$$0
:RemVar $$$0
:ExpectVar $$$0
:ExpectRemVar $$$0
:FlagResult 0
:TwoVar $$$2
:ThreeVar $$$3
:Index01 0
:RowIndex 0
:StrPtr "                                " 0 0

M Get32WordAt @PUSHI %1 @PUSHS @POPI %2 \
              @PUSHI %1 @ADD 2 @PUSHS @POPI %2+2

:Main . Main
@PRTLN "Start, Flags: OZNC"






@MA2V 0 Index01
@ForIA2B Index01 0 31
   @PUSHI Index01
   @SHL @DUP @SHLN 3 @ADDS @ADD DivideTable @POPI RowIndex

   @Get32WordAt RowIndex AVar
   @INC2I RowIndex    @INC2I RowIndex
   @Get32WordAt RowIndex BVar
   @INC2I RowIndex    @INC2I RowIndex
   @Get32WordAt RowIndex ExpectVar
   @INC2I RowIndex    @INC2I RowIndex   
   @Get32WordAt RowIndex ExpectRemVar
   @INCI RowIndex
   @PUSHII RowIndex @POPI FlagResult

#   @PRT "Testing: A: " @PRT32HEXI AVar @PRT " Divided by :" @PRT32HEXI BVar @PRTNL


   @Call32(vv) DIV32S AVar BVar
   @POP32I(v) RemVar
   @POP32I(v) RVar

   @PRT "Divide: " @PRT32HEXI AVar @PRT "/" @PRT32HEXI BVar @PRT " = " @PRT32HEXI RVar @PRT " remainder: " @PRT32HEXI RemVar
#   @PRT " Vs  "
#   @PRT32HEXI ExpectVar @PRT " and " @PRT32HEXI ExpectRemVar
#   @PRT " Flags: " @PRTHEXI Flags32 @PRT " vs " @PRTHEXI FlagResult
   @Call32(vv) CMP32U RVar ExpectVar
   @IF32_EQ
      @Call32(vv) CMP32U RemVar ExpectRemVar
      @IF32_EQ
          @PRT " OK "
      @ENDIF
   @ENDIF
   @PRTNL
@Next Index01
@END
   

@Call32(AA) DIV32U $$$0x80000001 $$$0x80000000 @POP32I(v) BVar @POP32I(v) AVar    # 65536 / 32768 = 2, rem=0
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "0x80000001/80000000 = 1 / 1"




@PUSH32(A) $$$0x8000 @CALL SHL32_1 @POP32I(v) AVar
@PRT " 0x8000 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00000002 Flag --OZNC:" @PRTBINI Flags32 @PRTNL
@PUSH32(A) $$$0x8fff @CALL SHL32_1 @POP32I(v) AVar
@PRT " 0x8fff Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00000002 Flag --OZNC:" @PRTBINI Flags32 @PRTNL
@END
# Test 1: Shift 0x00000001 left by 1
@Call32(A) SHL32_1 $$$0x00000001
@POP32I(v) AVar
@PRT "Input 0x00000001 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00000002 Flag --OZNC:" @PRTBINI Flags32 @PRTNL

# Test 1: Shift 0x00000001 left by 1
@Call32(A) SHL32_1 $$$0x00018fff
@POP32I(v) AVar
@PRT "Input 0x00018fff Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00000002 Flag --OZNC:" @PRTBINI Flags32 @PRTNL


# Test 1: 0x00000005 - 0x00000003 = 0x00000002, Carry=1
@Call32(AA) SUB32U $$$0x00000005 $$$0x00000003
@POP32I(v) AVar
@PRT "Input 0x00000005 - 0x00000003 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00000002 Flag" @PRTBINI Flags32 @PRTNL

# Test 2: 0x00000003 - 0x00000005 = borrow, result 0xFFFFFFFE, Carry=0
@Call32(AA) SUB32U $$$0x00000003 $$$0x00000005
@POP32I(v) AVar
@PRT "Input 0x00000003 - 0x00000005 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0xFFFFFFFE Flag" @PRTBINI Flags32 @PRTNL

# Test 3: 0x00010000 - 0x00000001 = 0x0000FFFF, Carry=1
@Call32(AA) SUB32U $$$0x00010000 $$$0x00000001
@POP32I(v) AVar
@PRT "Input 0x00010000 - 0x00000001 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x0000FFFF Flag" @PRTBINI Flags32 @PRTNL

# Test 4: 0xFFFFFFFF - 0x00000001 = 0xFFFFFFFE, Carry=1
@Call32(AA) SUB32U $$$0xFFFFFFFF $$$0x00000001
@POP32I(v) AVar
@PRT "Input 0xFFFFFFFF - 0x00000001 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0xFFFFFFFE Flag" @PRTBINI Flags32 @PRTNL

# Test 5: 0x00000000 - 0x00000001 = borrow, result 0xFFFFFFFF, Carry=0
@Call32(AA) SUB32U $$$0x00000000 $$$0x00000001
@POP32I(v) AVar
@PRT "Input 0x00000000 - 0x00000001 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0xFFFFFFFF Flag" @PRTBINI Flags32 @PRTNL

@END



# Test 2: Shift 0x00008000 left by 1
@Call32(A) SHL32_1 $$$0x00008000
@POP32I(v) AVar
@PRT "Input 0x00008000 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00010000 Flag --OZNC:" @PRTBINI Flags32 @PRTNL

# Test 3: Shift 0x80000000 left by 1
@Call32(A) SHL32_1 $$$0x80000000
@POP32I(v) AVar
@PRT "Input 0x80000000 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00000000 Flag --OZNC:" @PRTBINI Flags32 @PRTNL

# Test 4: Shift 0xFFFFFFFF left by 1
@Call32(A) SHL32_1 $$$0xFFFFFFFF
@POP32I(v) AVar
@PRT "Input 0xFFFFFFFF Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0xFFFFFFFE Flag --OZNC:" @PRTBINI Flags32 @PRTNL

# Test 5: Shift 0x00000000 left by 1
@Call32(A) SHL32_1 $$$0x00000000
@POP32I(v) AVar
@PRT "Input 0x00000000 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x00000000 Flag --OZNC:" @PRTBINI Flags32 @PRTNL
@END

@Call32(A) SHL32_1 $$$0x00000001 @POP32I(v) AVar
@PRT "Input 0x00000001 Output: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Expected 0x0000002 Flag --OZNC:" @PRTBINI Flags32 @PRTNL


@Call32(AA) DIV32U $$$0x80000001 $$$0x80000000 @POP32I(v) BVar @POP32I(v) AVar    # 65536 / 32768 = 2, rem=0
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "0x80000001/80000000 = 1 / 1"
@END



@Call32(AA) DIV32U $$$0x06 $$$0x03 @POP32I(v) BVar @POP32I(v) AVar    # 65536 / 32768 = 2, rem=0
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 65536 / 32768 = 2, rem=0" @PRTNL
@Call32(AA) DIV32U $$$0x80000001 $$$0x80000000 @POP32I(v) BVar @POP32I(v) AVar    # 65536 / 32768 = 2, rem=0
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 65536 / 32768 = 2, rem=0" @PRTNL


@END

#@Call32(AA) DIV32U $$$0x10020 $$$0x8000 @POP32I(v) BVar @POP32I(v) AVar
@Call32(AA) DIV32U $$$0x00010000 $$$0x00008000 @POP32I(v) BVar @POP32I(v) AVar    # 65536 / 32768 = 2, rem=0
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 65536 / 32768 = 2, rem=0" @PRTNL


# --- Exact powers of two ---
#@Call32(AA) DIV32U $$$0x00008000 $$$0x00008000 @POP32I(v) BVar @POP32I(v) AVar    # equal operands = 1, rem=0
#@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# equal operands = 1, rem=0" @PRTNL
@Call32(AA) DIV32U $$$0x00008001 $$$0x00008000 @POP32I(v) BVar @POP32I(v) AVar    # off-by-one remainder = 1
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# off-by-one remainder = 1" @PRTNL
# --- Simple decimal-like values ---
#@Call32(AA) DIV32U $$$0x00000064 $$$0x0000000a @POP32I(v) BVar @POP32I(v) AVar    # 100 / 10 = 10, rem=0
#@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 100 / 10 = 10, rem=0" @PRTNL
@Call32(AA) DIV32U $$$0x00000069 $$$0x0000000a @POP32I(v) BVar @POP32I(v) AVar    # 105 / 10 = 10, rem=5
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 105 / 10 = 10, rem=5" @PRTNL
# --- Large ratios (upper word active) ---
#@Call32(AA) DIV32U $$$0x00100000 $$$0x00000100 @POP32I(v) BVar @POP32I(v) AVar    # 1048576 / 256 = 4096, rem=0
#@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 1048576 / 256 = 4096, rem=0" @PRTNL
#@Call32(AA) DIV32U $$$0x80000000 $$$0x00008000 @POP32I(v) BVar @POP32I(v) AVar    # large / small, expect big quotient
#@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# large / small, expect big quotient" @PRTNL
@Call32(AA) DIV32U $$$0xffffffff $$$0x0000ffff @POP32I(v) BVar @POP32I(v) AVar    # all-bits dividend
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# all-bits dividend" @PRTNL

# --- Boundary behavior ---
#@Call32(AA) DIV32U $$$0x00000001 $$$0x00000002 @POP32I(v) BVar @POP32I(v) AVar    # 1/2 = 0, rem=1
#@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 1/2 = 0, rem=1" @PRTNL
#@Call32(AA) DIV32U $$$0x00000000 $$$0x00008000 @POP32I(v) BVar @POP32I(v) AVar    # 0/x = 0, rem=0
#@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# 0/x = 0, rem=0" @PRTNL
@Call32(AA) DIV32U $$$0x00000010 $$$0x00000001 @POP32I(v) BVar @POP32I(v) AVar    # x/1 = x
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# x/1 = x" @PRTNL
@Call32(AA) DIV32U $$$0xffffffff $$$0xffffffff @POP32I(v) BVar @POP32I(v) AVar    # identical max values = 1, rem=0
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# identical max values = 1, rem=0" @PRTNL

# --- Extreme upper bits ---
#@Call32(AA) DIV32U $$$0x80000000 $$$0x80000000 @POP32I(v) BVar @POP32I(v) AVar    # top bit divide equal = 1
#@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# top bit divide equal = 1" @PRTNL
@Call32(AA) DIV32U $$$0x80000001 $$$0x80000000 @POP32I(v) BVar @POP32I(v) AVar    # remainder=1
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# remainder=1" @PRTNL
@Call32(AA) DIV32U $$$0xffffffff $$$0x80000000 @POP32I(v) BVar @POP32I(v) AVar    # expect quotient=1, remainder=0x7FFFFFFF
@PRT "Result: " @PRTHEXI AVar+2 @PRTHEXI AVar @PRT " Remainder: " @PRTHEXI BVar+2 @PRTHEXI BVar @PRT "# expect quotient=1, remainder=0x7FFFFFFF" @PRTNL


#@Call32(AA) MUL32S $$$8000 $$$8000   @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # max 16-bit × 16-bit
#@Call32(AA) MUL32S $$$8001 $$$8001   @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # max 16-bit × 16-bit
#@Call32(AA) MUL32S $$$0xffff $$$0xffff   @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # max 16-bit × 16-bit
@END

#@Call(AA) MUL16x32U 40000 40000             @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL

@Call32(AA) MUL32S $$$32767 $$$32767   @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # max 16-bit × 16-bit

@Call32(AA) MUL32S $$$-1 $$$200000     @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL
@Call32(AA) MUL32S $$$0xffff1234 $$$1  @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL


@Call32(AA) MUL32S $$$65535 $$$65535   @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # unsigned wrap
@Call32(AA) MUL32S $$$-20000 $$$20001  @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # negative × positive
@Call32(AA) MUL32S $$$-30000 $$$-30000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # neg × neg = pos
@Call32(AA) MUL32S $$$100000 $$$-600000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL  # large mixed signs
@Call32(AA) MUL32S $$$0x7fffffff $$$2  @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # signed overflow
@Call32(AA) MUL32S $$$0x80000000 $$$2  @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL   # negative overflow
@Call32(AA) MUL32S $$$0x12345678 $$$0x10 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL # left-shift behavior
@Call32(AA) MUL32S $$$0xffffffff $$$0xffffffff @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTSP @PRT32 AVar @PRTNL # -1 × -1


@END

@PRT "At Start:\n A:" @PRT32 AVar
@PRT "\nB:" @PRT32 BVar


@PRTLN "\nTest Adds"
@PUSHI AVar @PUSHI AVar+2
@PUSHI BVar @PUSHI BVar+2
@CALL ADD32S
@POPI RVar+2
@POPI RVar
@PRT32 RVar
@PRTLN "\nTest Subs"
@Call(vvvv) SUB32S AVar AVar+2 BVar BVar+2
@POPI RVar+2
@POPI RVar
@PRT32 RVar
#
@PRTLN "\nTest Mul"
@PUSHI AVar @PUSHI AVar+2
@PUSHI BVar @PUSHI BVar+2
@CALL MUL32S
@POPI RVar+2
@POPI RVar
@PRT32 RVar
#
@PRTLN "\nCMP EQUAL (1,1)"
@Call(vvvv) CMP32S AVar AVar+2 AVar AVar+2
@CALL DumpFlags
@PRTLN "Cmp Less (1,2)"
@Call(vvvv) CMP32S AVar AVar+2 TwoVar TwoVar+2
@CALL DumpFlags
@PRTLN "Cmp Greater(2,1)"
@Call(vvvv) CMP32S TwoVar TwoVar+2 AVar AVar+2 
@CALL DumpFlags
#
@PRTLN "Macro Tests"
@PRTLN "CMP (1,1)
@Call(vvvv) CMP32S AVar AVar+2 AVar AVar+2
@CALL MacTests
@PRTLN "Cmp Less (1,2)"
@Call(vvvv) CMP32S AVar AVar+2 TwoVar TwoVar+2
@CALL MacTests
@PRTLN "Cmp Greater(2,1)"
@Call(vvvv) CMP32S TwoVar TwoVar+2 AVar AVar+2
@CALL MacTests

@PRTLN "Seconday Function Tests:"

@PRTLN "\nTest AND/OR/XOR/NOT"
@PUSHI AVar @PUSHI AVar+2
@PUSHI BVar @PUSHI BVar+2
@CALL AND32
@POPI RVar+2 @POPI RVar
@PRT "AND: " @PRT32 RVar @PRTNL

@PUSHI AVar @PUSHI AVar+2
@PUSHI BVar @PUSHI BVar+2
@CALL OR32
@POPI RVar+2 @POPI RVar
@PRT "OR: " @PRT32 RVar @PRTNL

@PUSHI ThreeVar @PUSHI ThreeVar+2
@PUSHI AVar @PUSHI AVar+2
@CALL XOR32
@POPI RVar+2 @POPI RVar
@PRT "XOR: " @PRT32 RVar @PRTNL

@PUSHI AVar @PUSHI AVar+2
@CALL INV32
@POPI RVar+2 @POPI RVar
@PRT "INV A: " @PRT32 RVar @PRTNL

@PUSHI AVar @PUSHI AVar+2
@CALL COMP232
@POPI RVar+2 @POPI RVar
@PRT "COMP232 A: " @PRT32 RVar @PRTNL


@END

:MacTests
@PRT "Flags32 = " @PRTI Flags32 @PRTNL
@IF32_GT   @PRT " > " @ENDIF
@IF32_EQ   @PRT " = " @ENDIF
@IF32_NE   @PRT " != " @ENDIF
@IF32_LE   @PRT " <= " @ENDIF
@IF32_LT   @PRT " < " @ENDIF
@IF32_GE   @PRT " >= " @ENDIF
@PRTNL
@RET




:DumpFlags
@PRT "Flags: "
@PUSHI Flags32 @AND Z32Flag @POPNULL
@IF_NOTZF
   @PRT "Z"
@ENDIF
@PUSHI Flags32 @AND O32Flag @POPNULL
@IF_NOTZF
   @PRT "O"
@ENDIF
@PUSHI Flags32 @AND C32Flag @POPNULL
@IF_NOTZF
   @PRT "C"
@ENDIF
@PUSHI Flags32 @AND N32Flag @POPNULL
@IF_NOTZF
   @PRT "N"
@ENDIF
@PRTNL
@RET


:MulTests
@PUSHRETURN

@ForIA2B Index2 2 3
   @PUSHI Index2 @SHL @SHL @SHL @ADD MulTable+16
   @POPI Index1
   @PRT "Math-Table: " @PRTHEXI Index1
   @PRT " Var A: " @Call(v) Print32At Index1
   @PUSHII Index1
   @INC2I Index1
   @PUSHII Index1
   @INC2I Index1
   @PRT " Var B: " @Call(v) Print32At Index1
   @PUSHII Index1
   @INC2I Index1
   @PUSHII Index1
   @PRT "\nBefore Call to MUL32S" @StackDump
   @CALL MUL32S
   @POPI RVar+2
   @POPI RVar
   @PRT " Test: " @PRTI Index2 @PRT " = " @PRT32 RVar @PRTNL
@Next Index2

@POPRETURN
@RET
:Print32At
@PUSHRETURN
@LocalVar InPtr 01
@POPI InPtr
@PUSHII InPtr
@INC2I InPtr
@PUSHII InPtr
@PRT32S InPtr
@RestoreVar 01
@POPRETURN
@RET


:Index1 0
:Index2 0
:MulTable
##$$$0x4660
##$$$0x20002
$$$0x4660
$$$3
$$$65537
$$$34464
$$$65535
$$$65535
$$$305419896
$$$2
$$$-1
$$$2

@PRTLN "UnSigned"
@ForIA2B AVar -10 10
   @ForIA2B BVar -10 10
       @PRTI AVar @PRT "," @PRTI BVar @PRTSP
       @PUSHI AVar
       @IF_UGT_V BVar  @PRT "> " @ENDIF
       @IF_UGE_V BVar  @PRT ">= " @ENDIF
       @IF_ULT_V BVar  @PRT "< " @ENDIF
       @IF_ULE_V BVar  @PRT "<= " @ENDIF
       @PRT ". "
       @POPNULL
   @NextBy BVar 2
   @PRTNL
@NextBy AVar 2

@PRTNL

@PRTLN "Signed"
@ForIA2B AVar -10 10
   @ForIA2B BVar -10 10
       @PRTSGNI AVar @PRT "," @PRTSGNI BVar @PRTSP
       @PUSHI AVar
       @IF_GT_V BVar  @PRT "> " @ENDIF
       @IF_GE_V BVar  @PRT ">= " @ENDIF
       @IF_LT_V BVar  @PRT "< " @ENDIF
       @IF_LE_V BVar  @PRT "<= " @ENDIF
       @PRT ". "
       @POPNULL
   @NextBy BVar 2
   @PRTNL
@NextBy AVar 2
@END
@Call32(AA) SUB32U $$$0 $$$0 @POP32I(v) AVar                   @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$1 $$$0 @POP32I(v) AVar                   @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$2 $$$1 @POP32I(v) AVar                   @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$1 $$$2 @POP32I(v) AVar                   @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0xffff $$$1 @POP32I(v) AVar              @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x10000 $$$1 @POP32I(v) AVar             @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x10000 $$$0x10001 @POP32I(v) AVar       @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x20000 $$$0x10001 @POP32I(v) AVar       @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x80000000 $$$0x00000001 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x00000000 $$$0x00000001 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x00000000 $$$0x00010000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x00010000 $$$0x00000000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x10000000 $$$0x08000000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x10000000 $$$0x10000000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x00008000 $$$0x00007FFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x7FFFFFFF $$$0xFFFFFFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0xFFFFFFFF $$$0x00000001 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0xFFFFFFFF $$$0xFFFFFFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x80000000 $$$0xFFFFFFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x00010000 $$$0x0000FFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x01000000 $$$0x0000FFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x00000001 $$$0xFFFFFFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0xFFFFFFFF $$$0x7FFFFFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x7FFFFFFF $$$0x80000000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x80000000 $$$0x7FFFFFFF @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x80008000 $$$0x7FFF8000 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@Call32(AA) SUB32U $$$0x0000FFFF $$$0xFFFF0001 @POP32I(v) AVar @PRTHEXI AVar+2 @PRTHEXI AVar @PRTNL
@END
@PRTLN "Tests of 32 bit Logic Flags and CMP32U"

@Call32(AA) CMP32U $$$0xffffffff $$$0x00000001 @PRT "CMP: $$$0xffffffff $$$0x00000001 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0x00000000 $$$0xffffffff @PRT "CMP: $$$0x00000000 $$$0xffffffff = " @PRTBINI Flags32 @PRTNL


@Call32(AA) CMP32U $$$0x7fffffff $$$0x80000000 @PRT "CMP: $$$0x7fffffff $$$0x80000000 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0x80000000 $$$0xffffffff @PRT "CMP: $$$0x80000000 $$$0xffffffff = " @PRTBINI Flags32 @PRTNL


@Call32(AA) CMP32U $$$0 $$$0 @PRT "CMP: $$$0 $$$0 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$1 $$$0 @PRT "CMP: $$$1 $$$0 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0 $$$1 @PRT "CMP: $$$0 $$$1 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$1 $$$1 @PRT "CMP: $$$1 $$$1 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$2 $$$1 @PRT "CMP: $$$2 $$$1 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$1 $$$2 @PRT "CMP: $$$1 $$$2 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0x7fffffff $$$0x00000001 @PRT "CMP: $$$0x7fffffff $$$0x00000001 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0x80000000 $$$0x7fffffff @PRT "CMP: $$$0x80000000 $$$0x7fffffff = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0xffffffff $$$0xffffffff @PRT "CMP: $$$0xffffffff $$$0xffffffff = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0xffffffff $$$0x80000000 @PRT "CMP: $$$0xffffffff $$$0x80000000 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0x00008000 $$$0x00007fff @PRT "CMP: $$$0x00008000 $$$0x00007fff = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32U $$$0x00007fff $$$0x00008000 @PRT "CMP: $$$0x00007fff $$$0x00008000 = " @PRTBINI Flags32 @PRTNL

@PRTLN "Tests of 32 bit Logic Flags and CMP32S"

@Call32(AA) CMP32S $$$0xffffffff $$$0x00000001 @PRT "CMP: $$$0xffffffff $$$0x00000001 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0x00000000 $$$0xffffffff @PRT "CMP: $$$0x00000000 $$$0xffffffff = " @PRTBINI Flags32 @PRTNL


@Call32(AA) CMP32S $$$0x7fffffff $$$0x80000000 @PRT "CMP: $$$0x7fffffff $$$0x80000000 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0x80000000 $$$0xffffffff @PRT "CMP: $$$0x80000000 $$$0xffffffff = " @PRTBINI Flags32 @PRTNL


@Call32(AA) CMP32S $$$0 $$$0 @PRT "CMP: $$$0 $$$0 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$1 $$$0 @PRT "CMP: $$$1 $$$0 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0 $$$1 @PRT "CMP: $$$0 $$$1 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$1 $$$1 @PRT "CMP: $$$1 $$$1 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$2 $$$1 @PRT "CMP: $$$2 $$$1 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$1 $$$2 @PRT "CMP: $$$1 $$$2 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0x7fffffff $$$0x00000001 @PRT "CMP: $$$0x7fffffff $$$0x00000001 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0x80000000 $$$0x7fffffff @PRT "CMP: $$$0x80000000 $$$0x7fffffff = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0xffffffff $$$0xffffffff @PRT "CMP: $$$0xffffffff $$$0xffffffff = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0xffffffff $$$0x80000000 @PRT "CMP: $$$0xffffffff $$$0x80000000 = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0x00008000 $$$0x00007fff @PRT "CMP: $$$0x00008000 $$$0x00007fff = " @PRTBINI Flags32 @PRTNL
@Call32(AA) CMP32S $$$0x00007fff $$$0x00008000 @PRT "CMP: $$$0x00007fff $$$0x00008000 = " @PRTBINI Flags32 @PRTNL
@END

@STRSTACK "0b1000" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "0x123" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "-0x123" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "0o1230" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "0o-1230" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "12300" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "-12300" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "123000" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@STRSTACK "-123000" @CALL stoi32 @POP32I(v) AVar @PRT32HEXI AVar @PRTNL
@END


@PUSH StrPtr @PUSH32(A) $$$123 @PUSH 10 @CALL i32tos @PRTSTR StrPtr @PRTNL
@PUSH StrPtr @PUSH32(A) $$$-123 @PUSH 10 @CALL i32tos @PRTSTR StrPtr @PRTNL
@PUSH StrPtr @PUSH32(A) $$$123000 @PUSH 10 @CALL i32tos @PRTSTR StrPtr @PRTNL
@PUSH StrPtr @PUSH32(A) $$$-123000 @PUSH 10 @CALL i32tos @PRTSTR StrPtr @PRTNL
@PUSH StrPtr @PUSH32(A) $$$1230000 @PUSH 10 @CALL i32tos @PRTSTR StrPtr @PRTNL
@PUSH StrPtr @PUSH32(A) $$$-1230000 @PUSH 10 @CALL i32tos @PRTSTR StrPtr @PRTNL
@PUSH StrPtr @PUSH32(A) $$$00 @PUSH 10 @CALL i32tos @PRTSTR StrPtr @PRTNL
@END


:DivideTable
$$$0x80000001  $$$0x80000000  $$$1           $$$1           0
$$$0xffffffff  $$$0x80000000  $$$1           $$$0x7fffffff    0
$$$0x80000000  $$$2           $$$0x40000000  $$$0           0
$$$0xffffffff  $$$2           $$$0x7fffffff    $$$1           0
$$$0xffffffff  $$$3           $$$0x55555555  $$$0           0    # 1431655765 * 3 = FFFFFFFF
# Basic sanity checks
$$$0xffffffff  $$$0xffffffff  $$$1           $$$0           0
$$$0           $$$1           $$$0           $$$0           0    # 0 / 1 = 0
$$$1           $$$1           $$$1           $$$0           0    # equal numbers
$$$10          $$$2           $$$5           $$$0           0    # exact divide
$$$100         $$$10          $$$10          $$$0           0    # 100 / 10 = 10
$$$101         $$$10          $$$10          $$$1           0    # remainder 1
$$$15          $$$4           $$$3           $$$3           0    # 15/4 = 3 rem 3

# Edge of zero and one
$$$1           $$$2           $$$0           $$$1           0    # less than divisor
$$$0           $$$2           $$$0           $$$0           4   # zero dividend
$$$1           $$$0           $$$0           $$$0           0    # divide by zero

# Powers of two (shift-based tests)
$$$8           $$$2           $$$4           $$$0           0
$$$8           $$$4           $$$2           $$$0           0
$$$8           $$$8           $$$1           $$$0           0
$$$9           $$$8           $$$1           $$$1           0
$$$16          $$$8           $$$2           $$$0           0
$$$255         $$$16          $$$15          $$$15          0
$$$256         $$$16          $$$16          $$$0           0
$$$257         $$$16          $$$16          $$$1           0

# Large unsigned region
$$$0xffff      $$$2           $$$0x7fff        $$$1           0    # half of max 16-bit
$$$0x10000     $$$0x10        $$$0x1000      $$$0           0
$$$0xffffffff  $$$1           $$$0xffffffff  $$$0           0

# Divide by small odd numbers (for remainder correctness)
$$$100         $$$3           $$$33          $$$1           0
$$$255         $$$5           $$$51          $$$0           0
$$$256         $$$5           $$$51          $$$1           0
$$$1024        $$$7           $$$146         $$$2           0
$$$99999       $$$97          $$$1030        $$$89          0

# Divide by zero guard
$$$12345       $$$0           $$$0           $$$0           0    # divide-by-zero flag expected

$$$-1 $$$-1 $$$-1 $$$-1 0                                                    # Marks end of loop
