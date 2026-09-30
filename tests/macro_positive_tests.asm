P "Test 01: macro argument substitution"
P "Expected: A=ONE B=TWO"
M SHOW P A=%1 B=%2 ;
@SHOW ONE TWO

P "Test 02: quoted argument preservation"
P "Expected: HELLO WORLD"
M SAY P %1 ;
@SAY "HELLO WORLD"

P "Test 03: bracket and grouping preservation"
P "Expected: [ABC] (ABC) <ABC> X[ABC]Y"
M SHOW P [%1] (%1) <%1> X[%1]Y ;
@SHOW ABC

P "Test 04: macro tail handling"
P "Expected: ONE, then TWO"
M A P ONE ;
@A ; P TWO

P "Test 05: nested macro stack frames"
P "Expected: TOP differs from BELOW; BELOW equals RESTORED"
M SHOWW %S `P TOP=%V ; P BELOW=%W ; %P` ;
M OUTER %S `@SHOWW ; P RESTORED=%V ; %P` ;
@OUTER

P "Test 06: unique macro invocation IDs"
P "Expected: three different ID values"
M TAG P ID=%0 ;
@TAG
@TAG
@TAG

P "Test 07: skipped nested conditional block"
P "Expected: GOOD only"
? 0
? 1
P BAD
ENDBLOCK
ENDBLOCK
P GOOD

P "Test 08: inline skipped conditional tail"
P "Expected: GOOD only"
? 0 P BAD ; ENDBLOCK ; P GOOD

P "Test 09: STRLEN/LEN inside macro"
P "Expected: LEN=5"
M SL %STRLEN %1 P LEN=%LEN ;
@SL "ABCDE"

P "Test 10: deferred nested macro with percent function"
P "Expected: INNER, then LEN=3"
M INNER P INNER ;
M OUTER %STRLEN "ABC" `@INNER ; P LEN=%LEN` ;
@OUTER

P "Test 11: percent-function macro value"
P "Expected: 52"
M LO %AND %1 0xff ;
=VAL @LO 0x1234
P {VAL}

P "Test 12: stack frame survives nested body macro"
P "Expected: ENTER equals LEAVE, with BODY between them"
M BODY P BODY ;
M WRAP %S `P ENTER=%V ; @BODY ; P LEAVE=%V ; %P` ;
@WRAP

P "Test 13: macro argument with comma-like/bracket syntax"
P "Expected: ARG=A[B,C]"
M SHOWARG P ARG=%1 ;
@SHOWARG A[B,C]

P "Test 14: macro call inside macro tail"
P "Expected: FIRST, SECOND, THIRD"
M FIRST P FIRST ;
M SECOND P SECOND ;
@FIRST ; @SECOND ; P THIRD

P "Test 15: macro definition skipped by inline false conditional"
P "Expected: AFTER only"
? 0 M HIDDEN P BAD ; ENDBLOCK ; P AFTER


=PUSH 1
=CastEnd 99
=CAST 42
$$PUSH CastEnd $$CAST 0
