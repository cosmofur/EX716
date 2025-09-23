I common.mc
# =========================================================
# Macro Expander Test
# Exercises:
#   - %STRLEN / %LEN stack behavior
#   - %REPEAT / %ENDR expansion
#   - Nested %REPEAT
# =========================================================

# --- %STRLEN / %LEN stack test ---
M TESTLEN \
    %STRLEN "foo" \
    %STRLEN "abcdef" \
    @PUSH %%LEN \
    @PUSH %%LEN \
    @PRT "\nA)" @PRTTOP @POPNULL \
    @PRT "\nB)" @PRTTOP @POPNULL
    

# --- %REPEAT test (simple) ---
M TESTREP \
    %REPEAT 3 \
        @PUSH 1 \
    %ENDR \
    @PRT "\n1:" @PRTTOP @POPNULL \
    @PRT "\n2:" @PRTTOP @POPNULL \
    @PRT "\n3:" @PRTTOP @POPNULL \
    @PRTNL
    
# --- Nested %REPEAT test ---
M TESTNEST \
    %REPEAT 2 \
        @PUSH 1 \
        %REPEAT 2 \
            @PUSH 2 \
        %ENDR \
    %ENDR \
    @PRT "After Nested storage" @StackDump
:Main . Main    
P Tests for macros
P TESTLEN
@TESTLEN
P TESTREP
@TESTREP
P TESTNEST
@TESTNEST
@PRTNL
@END
