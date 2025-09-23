\ minimal-ans-tests.fth
\ Basic ANS Forth validation: stack ops, arithmetic, conditionals, loops, definition, execution

CR .( Starting minimal ANS Forth validation... ) CR

: TEST ( -- ) CR ." TEST: " ;
: REPORT ( f -- ) IF ." PASS" ELSE ." FAIL" THEN CR ;

\ ------------------------------
TEST ." Stack Ops: 1 2 SWAP = 1" CR
: test-swap
  1 2 SWAP 2 = IF 1 = REPORT ELSE DROP DROP 0 REPORT THEN ;
test-swap

TEST ." DUP/OVER/ROT = 3 4 3" CR
: test-stack
  3 4 OVER = SWAP DROP SWAP = ROT DROP DROP 2 = AND REPORT ;
test-stack

\ ------------------------------
TEST ." Arithmetic: 3 4 + = 7" CR
: test-add 3 4 + 7 = REPORT ; test-add

TEST ." Arithmetic: 5 2 * = 10" CR
: test-mul 5 2 * 10 = REPORT ; test-mul

TEST ." Arithmetic: 11 3 / = 3" CR
: test-div 11 3 / 3 = REPORT ; test-div

TEST ." Arithmetic: 13 5 MOD = 3" CR
: test-mod 13 5 MOD 3 = REPORT ; test-mod

\ ------------------------------
TEST ." Conditionals: -1 IF -> PASS" CR
: test-iftrue -1 IF 1 REPORT ELSE 0 REPORT THEN ; test-iftrue

TEST ." Conditionals: 0 IF -> FAIL" CR
: test-iffalse 0 IF 0 REPORT ELSE 1 REPORT THEN ; test-iffalse

\ ------------------------------
TEST ." Loops: DO LOOP" CR
: test-loop
  0
  0 DO I + LOOP
  10 = REPORT ;
test-loop

TEST ." Loops: 3 0 DO I + LOOP = 3" CR
: test-loop2
  0
  3 0 DO I + LOOP
  3 = REPORT ;
test-loop2

\ ------------------------------
TEST ." Definitions + EXECUTE" CR
: square ( n -- n*n ) DUP * ;
: test-execute
  ' square >R
  5 R> EXECUTE
  25 = REPORT ;
test-execute

\ ------------------------------
TEST ." Nesting: IF inside DO LOOP" CR
: test-nested
  0
  5 0 DO I 3 = IF 1 + THEN LOOP
  1 = REPORT ;
test-nested

CR .( All tests complete. ) CR
