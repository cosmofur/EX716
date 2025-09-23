I common.mc
:Success 0
:Fail 0
:Main . Main
"@PRTLN ""--- Testing IF_GT_AV ---"""
@PUSH 50
@IF_GT_AV 20
   @INCI Success
"   @PRTLN ""PASS: IF_GT_AV"""
@ELSE
   @INCI Fail
"   @PRTLN ""FAIL: IF_GT_AV"""
@ENDIF
@POPNULL
@POPNULL
"@PRTLN ""--- Testing IF_GT_VA ---"""
@PUSH 20
@IF_GT_VA 50
   @INCI Fail
"   @PRTLN ""FAIL: IF_GT_VA"""
@ELSE
   @INCI Success
"   @PRTLN ""PASS: IF_GT_VA"""
@ENDIF
@POPNULL
@POPNULL
"@PRTLN ""--- Testing IF_GT_VV ---"""
@IF_GT_VV 50 20
   @INCI Success
"   @PRTLN ""PASS: IF_GT_VV"""
@ELSE
   @INCI Fail
"   @PRTLN ""FAIL: IF_GT_VV"""
@ENDIF
@POPNULL
"@PRTLN ""--- Testing IF_INRANGE_AB ---"""
@PUSH 50
@PUSH 20
@IF_INRANGE_AB
   @INCI Success
"   @PRTLN ""PASS: IF_INRANGE_AB"""
@ELSE
   @INCI Fail
"   @PRTLN ""FAIL: IF_INRANGE_AB"""
@ENDIF
@POPNULL
@POPNULL
"@PRTLN ""--- Testing IF_INRANGE_AV ---"""
@PUSH 50
@IF_INRANGE_AV 20
   @INCI Success
"   @PRTLN ""PASS: IF_INRANGE_AV"""
@ELSE
   @INCI Fail
"   @PRTLN ""FAIL: IF_INRANGE_AV"""
@ENDIF
@POPNULL
@POPNULL
"@PRTLN ""--- Testing IF_INRANGE_VA ---"""
@PUSH 20
@IF_INRANGE_VA 50
   @INCI Success
"   @PRTLN ""PASS: IF_INRANGE_VA"""
@ELSE
   @INCI Fail
"   @PRTLN ""FAIL: IF_INRANGE_VA"""
@ENDIF
@POPNULL
@POPNULL
"@PRTLN ""--- Testing IF_INRANGE_VV ---"""
@IF_INRANGE_VV 50 20
   @INCI Success
"   @PRTLN ""PASS: IF_INRANGE_VV"""
@ELSE
   @INCI Fail
"   @PRTLN ""FAIL: IF_INRANGE_VV"""
@ENDIF
@POPNULL
"@PRTLN ""--- Testing IF_EQ_AV ---"""
@PUSH 50
@IF_EQ_AV 20
   @INCI Fail
"   @PRTLN ""FAIL: IF_EQ_AV"""
@ELSE
   @INCI Success
"   @PRTLN ""PASS: IF_EQ_AV"""
@ENDIF
@POPNULL
@POPNULL
"@PRTLN ""--- Testing IF_LT_AV ---"""
@PUSH 50
@IF_LT_AV 20
   @INCI Fail
"   @PRTLN ""FAIL: IF_LT_AV"""
@ELSE
   @INCI Success
"   @PRTLN ""PASS: IF_LT_AV"""
@ENDIF
@POPNULL
@POPNULL
"@PRTLN ""--- Testing IF_GE_AV ---"""
@PUSH 50
@IF_GE_AV 20
   @INCI Success
"   @PRTLN ""PASS: IF_GE_AV"""
@ELSE
   @INCI Fail
"   @PRTLN ""FAIL: IF_GE_AV"""
@ENDIF
@POPNULL
@POPNULL
@END
