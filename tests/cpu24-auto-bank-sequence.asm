# Deterministic automatic-CS-banking regression.
#
# Each Test_N function prints its identity, skips a 2,500-byte reserved code
# region, increments the incoming stack value, and returns it.  Twenty-eight
# functions are enough to overflow the first 64 KiB CS bank (after its veneer
# reservation) while keeping the executed path and output deliberately small.
.DATA 1
I commonDS.mc
L softstack.ld

M PADDED_TEST `\
   @FUNCTION Test_%1 ; \
   :Test_%1 ; \
   @PRT "test " @PRTREF %1 @PRTNL ; \
   @JMP Test_%1_AfterPad ; \
   :Test_%1_PadStart ; \
   .ORG Test_%1_PadStart+2500 ; \
   :Test_%1_AfterPad ; \
   @SWP @ADD 1 @SWP @RET ; \
   @ENDFUNCTION \
`

:Main
.ENTRY Main
@PUSH 1
@ADM
@PUSH 1
@SSET SegDS
@PUSH 0xfff0
@PUSH 0xf000
@CALL SetSSStack

@PUSH 0
@CALL Test_1
@CALL Test_2
@CALL Test_3
@CALL Test_4
@CALL Test_5
@CALL Test_6
@CALL Test_7
@CALL Test_8
@CALL Test_9
@CALL Test_10
@CALL Test_11
@CALL Test_12
@CALL Test_13
@CALL Test_14
@CALL Test_15
@CALL Test_16
@CALL Test_17
@CALL Test_18
@CALL Test_19
@CALL Test_20
@CALL Test_21
@CALL Test_22
@CALL Test_23
@CALL Test_24
@CALL Test_25
@CALL Test_26
@CALL Test_27
@CALL Test_28

@IF_EQ_A 28
   @PRTLN "CPU24 auto-bank sequence PASS"
@ELSE
   @PRTLN "CPU24 auto-bank sequence FAIL"
@ENDIF
@POPNULL
@PUSH 0
@ADM
@END

@PADDED_TEST 1
@PADDED_TEST 2
@PADDED_TEST 3
@PADDED_TEST 4
@PADDED_TEST 5
@PADDED_TEST 6
@PADDED_TEST 7
@PADDED_TEST 8
@PADDED_TEST 9
@PADDED_TEST 10
@PADDED_TEST 11
@PADDED_TEST 12
@PADDED_TEST 13
@PADDED_TEST 14
@PADDED_TEST 15
@PADDED_TEST 16
@PADDED_TEST 17
@PADDED_TEST 18
@PADDED_TEST 19
@PADDED_TEST 20
@PADDED_TEST 21
@PADDED_TEST 22
@PADDED_TEST 23
@PADDED_TEST 24
@PADDED_TEST 25
@PADDED_TEST 26
@PADDED_TEST 27
@PADDED_TEST 28
