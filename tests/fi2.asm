M TESTMAC          \
   IFNDEF A             \
   P MAC1 ;        \
   ELSEBLOCK       \
   P MAC2  ;        \
   ENDBLOCK

P Start
@TESTMAC
P Stop
$$1 99 42 0
