I common.mc
:Success 0
:Fail 0
=LOWVAL 10
=HIGHVAL 100
=ZERO 0
=NOTZERO 1
:LOWVAR 10
:HIGHVAR 100
:ZEROVAR 0
:NOTZEROVAR 1
:Main . Main
    # ------------------------------------------
:TEST_IF_ZERO_PASS
    @PUSH ZERO
    @IF_ZERO
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ZERO"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ZERO_FAIL
    @PUSH NOTZERO
    @IF_ZERO
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ZERO"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTZERO_PASS
    @PUSH NOTZERO
    @IF_NOTZERO
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTZERO"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTZERO_FAIL
    @PUSH ZERO
    @IF_NOTZERO
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTZERO"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_EQ_S_PASS
    @PUSH LOWVAL
    @PUSH LOWVAL
    @IF_EQ_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_EQ_S_FAIL
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_EQ_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_EQ_A_PASS
    @PUSH HIGHVAL
    @IF_EQ_A HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_A HIGHVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_EQ_A_FAIL
    @PUSH LOWVAL
    @IF_EQ_A HIGHVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_A HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_EQ_V_PASS
    @PUSHI HIGHVAR
    @IF_EQ_V HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_V HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_EQ_V_FAIL
    @PUSHI HIGHVAR
    @IF_EQ_V LOWVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_V LOWVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_EQ_VV_PASS
    @IF_EQ_VV HIGHVAR HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_VV HIGHVAR HIGHVAR"
    @ENDIF
    # ------------------------------------------
:TEST_IF_EQ_VV_FAIL
    @IF_EQ_VV HIGHVAR LOWVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_VV HIGHVAR LOWVAR"
    @ELSE
        @INCI Success
    @ENDIF
    # ------------------------------------------
:TEST_IF_EQ_VA_PASS
    @IF_EQ_VA HIGHVAR HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_VA HIGHVAR HIGHVAL"
    @ENDIF
    # ------------------------------------------
:TEST_IF_EQ_VA_FAIL
    @IF_EQ_VA HIGHVAR LOWVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_VA HIGHVAR LOWVAL"
    @ELSE
        @INCI Success
    @ENDIF
    # ------------------------------------------
:TEST_IF_EQ_AV_PASS
    @IF_EQ_AV LOWVAL LOWVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_AV LOWVAL LOWVAR"
    @ENDIF
    # ------------------------------------------
:TEST_IF_EQ_AV_FAIL
    @IF_EQ_AV LOWVAL HIGHVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_EQ_AV LOWVAL HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    # ------------------------------------------
:TEST_IF_LT_S_PASS
    @PUSH LOWVAL
    @PUSH HIGHVAL
    @IF_LT_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LT_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_LT_S_FAIL
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_LT_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LT_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_LT_A_PASS
    @PUSH LOWVAL
    @IF_LT_A HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LT_A LOWVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_LT_A_FAIL
    @PUSH HIGHVAL
    @IF_LT_A LOWVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LT_A HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_LT_V_PASS
    @PUSH LOWVAL
    @IF_LT_V HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LT_V LOWVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_LT_V_FAIL
    @PUSH HIGHVAL
    @IF_LT_V LOWVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LT_V HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_LE_S_PASS
    @PUSH LOWVAL
    @PUSH HIGHVAL    
    @IF_LE_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LE_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_LE_S_FAIL
    @PUSH LOWVAL
    @PUSH HIGHVAL
    @SWP
    @IF_LE_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LE_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_LE_A_PASS
    @PUSH LOWVAL
    @IF_LE_A HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LE_A LOWVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_LE_A_FAIL
    @PUSH HIGHVAL
    @IF_LE_A LOWVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LE_A HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_LE_V_PASS
    @PUSH LOWVAL
    @IF_LE_V HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LE_V LOWVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_LE_V_FAIL
    @PUSH HIGHVAL
    @IF_LE_V LOWVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_LE_V HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GE_S_PASS
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_GE_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GE_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_GE_S_FAIL
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @SWP
    @IF_GE_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GE_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_GE_A_PASS
    @PUSH HIGHVAL
    @IF_GE_A LOWVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GE_A LOWVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GE_A_FAIL
    @PUSH LOWVAL
    @IF_GE_A HIGHVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GE_A LOWVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GE_V_PASS
    @PUSH HIGHVAL
    @IF_GE_V LOWVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GE_V LOWVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GE_V_FAIL
    @PUSH LOWVAL
    @IF_GE_V HIGHVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GE_V HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GT_S_PASS
    @SWP
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_GT_S 
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GT_S "
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_GT_S_FAIL
    @PUSH LOWVAL
    @PUSH HIGHVAL
    @IF_GT_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GT_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_GT_A_PASS
    @PUSH HIGHVAL
    @IF_GT_A LOWVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GT_A LOWVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GT_A_FAIL
    @PUSH LOWVAL
    @IF_GT_A HIGHVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GT_A HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GT_V_PASS
    @PUSH HIGHVAL
    @IF_GT_V LOWVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GT_V LOWVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_GT_V_FAIL
    @PUSH LOWVAL
    @IF_GT_V HIGHVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_GT_V HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_AB_PASS
    @PUSH LOWVAL @ADD 1
    @IF_INRANGE_AB LOWVAL HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_AB LOWVAL HIGHVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_AB_FAIL
    @PUSH HIGHVAL @ADD 1
    @IF_INRANGE_AB LOWVAL HIGHVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_AB LOWVAL HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_AV_PASS
    @PUSH LOWVAL @ADD 1
    @IF_INRANGE_AV LOWVAL HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_AV LOWVAL HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_AV_FAIL
    @PUSH HIGHVAL @ADD 1
    @IF_INRANGE_AV LOWVAL HIGHVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_AV LOWVAL HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_VA_PASS
    @PUSH LOWVAL @ADD 1
    @IF_INRANGE_VA LOWVAR HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_VA LOWVAR HIGHVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_VA_FAIL
    @PUSH HIGHVAL @ADD 1
    @IF_INRANGE_VA LOWVAR HIGHVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_VA LOWVAR HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_VV_PASS
    @PUSH LOWVAL @ADD 1
    @IF_INRANGE_VV LOWVAR HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_VV LOWVAR HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_INRANGE_VV_FAIL
    @PUSH HIGHVAL @ADD 1
    @IF_INRANGE_VV LOWVAR HIGHVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_INRANGE_VV LOWVAR HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGT_V_PASS
    @PUSH HIGHVAL
    @IF_UGT_V LOWVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGT_V HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGT_V_FAIL
    @PUSH LOWVAL
    @IF_UGT_V HIGHVAR
        @INCI Fail            
        @DEBUGTOGGLE
        @PRTTOP @PRT " Should NOT be higher than " @PRTI HIGHVAR
        @StackDump @PRTLN "FAIL     @IF_UGT_V LOWVAR"    
    @ELSE
        @INCI Success    
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGE_V_PASS
    @PUSH HIGHVAL
    @IF_UGE_V HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGE_V HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGE_V_FAIL
    @PUSH HIGHVAL
    @IF_UGE_V LOWVAR    
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGE_V HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGT_A_PASS
    @PUSH HIGHVAL
    @IF_UGT_A LOWVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGT_A LOWVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGT_A_FAIL
    @PUSH LOWVAL
    @IF_UGT_A HIGHVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGT_A LOWVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGE_A_PASS
    @PUSH HIGHVAL
    @IF_UGE_A HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGE_A HIGHVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGE_A_FAIL
    @PUSH LOWVAL
    @IF_UGE_A HIGHVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGE_A HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGT_S_PASS
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_UGT_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGT_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGT_S_FAIL
    @PUSH LOWVAL
    @PUSH HIGHVAL
    @IF_UGT_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGT_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGE_S_PASS
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_UGE_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGE_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_UGE_S_FAIL
    @PUSH LOWVAL
    @PUSH HIGHVAL
    @IF_UGE_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_UGE_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULE_V_PASS
    @PUSH HIGHVAL
    @IF_ULE_V HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULE_V HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULE_V_FAIL
    @PUSH HIGHVAL
    @IF_ULE_V LOWVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULE_V HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULT_V_PASS
    @PUSH LOWVAL
    @IF_ULT_V HIGHVAR
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULT_V HIGHVAR"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULT_V_FAIL
    @PUSH HIGHVAL
    @IF_ULT_V LOWVAR
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULT_V HIGHVAR"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULE_A_PASS
    @PUSH LOWVAL
    @IF_ULE_A HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULE_A HIGHVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULE_A_FAIL
    @PUSH HIGHVAL
    @IF_ULE_A LOWVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULE_A LOWVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULT_A_PASS
    @PUSH LOWVAL
    @IF_ULT_A HIGHVAL
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULT_A HIGHVAL"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULT_A_FAIL
    @PUSH HIGHVAL
    @IF_ULT_A LOWVAL
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULT_A HIGHVAL"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULE_S_PASS
    @PUSH LOWVAL
    @PUSH HIGHVAL
    @IF_ULE_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULE_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULE_S_FAIL
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_ULE_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULE_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULT_S_PASS
    @PUSH LOWVAL
    @PUSH HIGHVAL
    @IF_ULT_S
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULT_S"
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_ULT_S_FAIL
    @PUSH HIGHVAL
    @PUSH LOWVAL
    @IF_ULT_S
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ULT_S"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    @POPNULL
    # ------------------------------------------
:TEST_IF_NEG_PASS
    @PUSH LOWVAL @SUB HIGHVAL
    @IF_NEG
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NEG"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NEG_FAIL
    @PUSH HIGHVAL @SUB LOWVAL
    @IF_NEG
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NEG"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ZFLAG_PASS
    @PUSH LOWVAL
    @CMP LOWVAL
    @IF_ZFLAG
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ZFLAG"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_ZFLAG_FAIL
    @PUSH LOWVAL
    @CMP HIGHVAL
    @IF_ZFLAG
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_ZFLAG"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTZF_PASS
    @PUSH LOWVAL
    @CMP HIGHVAL
    @IF_NOTZF
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTZF"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTZF_FAIL
    @PUSH LOWVAL
    @CMP LOWVAL
    @IF_NOTZF
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTZF"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_POS_PASS
    @PUSH LOWVAL
    @CMP 0
    @IF_POS
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_POS"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_POS_FAIL
    @PUSH LOWVAL
    @SUB HIGHVAL
    @IF_POS
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_POS"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------    a
:TEST_IF_OVERFLOW_PASS
    @PUSH 0x7fff
    @ADD 1
    @IF_OVERFLOW
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_OVERFLOW"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_OVERFLOW_FAIL
    @PUSH 1
    @ADD 1
    @IF_OVERFLOW
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_OVERFLOW"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTOVER_PASS
    @PUSH 100
    @ADD 10
    @IF_NOTOVER
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTOVER"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTOVER_FAIL
    @PUSH 0x100
    @ADD 0x100
    @IF_NOTOVER
        @INCI Success    
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTOVER"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_CARRY_PASS
    @PUSH LOWVAL
    @SUB HIGHVAL
    @IF_CARRY
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_CARRY"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_CARRY_FAIL
   @PUSH HIGHVAL
   @SUB LOWVAL
    @IF_CARRY
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_CARRY"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTCARRY_PASS
    @PUSH HIGHVAL
    @SUB LOWVAL
    @IF_NOTCARRY
        @INCI Success
    @ELSE
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTCARRY"
    @ENDIF
    @POPNULL
    # ------------------------------------------
:TEST_IF_NOTCARRY_FAIL
    @PUSH LOWVAL
    @SUB HIGHVAL
    @IF_NOTCARRY
        @INCI Fail
        @StackDump @PRTLN "FAIL     @IF_NOTCARRY"
    @ELSE
        @INCI Success
    @ENDIF
    @POPNULL
    # Final result
    @PRT "Success:" @PRTI Success
    @PRT "Fail:" @PRTI Fail
    @END
