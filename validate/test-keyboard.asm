I common.mc
# Test keyboard
@PUSH 0
@PRTLN "Type Q to quit"
@WHILE_NEQ_A 0x0051    # While not "Q"
   @POPNULL
   @READCNW CHIN
   @PUSHI CHIN
   @IF_NOTZERO
      @PRTI CHIN @PRTSP
   @ENDIF
@ENDWHILE
@END
:CHIN 0 0
