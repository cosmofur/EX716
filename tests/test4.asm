I common.mc
L string.ld

:Main . Main
@MA2V 0 CVAL
@MA2V 0 MVAL
@PRTLN "Mini 4 Function Calculator:"
@PRTLN "q to quit.:"
:Loop
@PRT   "| " @PRTI CVAL @PRTNL
@PRTLN "-----------------------"
@PRT ">"
@READS InputString
@MA2V InputString MemPtr   # Moving Address of InputStirng to MemPtr

@PUSHI MemPtr
@CALL ISNumeric
@IF_NOTZERO
   @POPNULL
   @PUSHI MemPtr
   @CALL stoifirst   
   @POPI AVAL
   @PUSHI MemPtr
   @CALL ISNumeric
   @WHILE_NOTZERO
      @POPNULL
      @INCI MemPtr
      @PUSHI MemPtr
      @CALL ISNumeric 
   @ENDWHILE
   @POPNULL
   @MA2V 0 Mode
   @PUSHII MemPtr @AND 0xff
   @WHILE_EQ_A " \0"   #Skip spaces if any
      @POPNULL
      @INCI MemPtr
      @PUSHII MemPtr @AND 0xff
   @ENDWHILE
   @SWITCH
      @CASE "+\0"
         @MA2V 1 Mode
         @CBREAK
      @CASE "-\0"
         @MA2V 2 Mode
         @CBREAK
      @CASE "*\0"
         @MA2V 3 Mode
         @CBREAK
      @CASE "/\0"
         @MA2V 4 Mode
         @CBREAK
      @CASE "=\0"
         @MA2V 5 Mode
         @CBREAK
      @CDEFAULT
          @POPNULL
          @PRTLN "Not Valid Operator"
          @JMP Loop
          @CBREAK
   @ENDCASE
   @INCI MemPtr
   @PUSHII MemPtr @AND 0xff   
   @WHILE_EQ_A " \0"   #Skip spaces if any
      @POPNULL
      @INCI MemPtr
      @PUSHII MemPtr @AND 0xff
   @ENDWHILE
   @POPNULL
   @PUSHI MemPtr
   @CALL ISNumeric
   @WHILE_ZERO
      @POPNULL
      @PUSHII MemPtr @AND 0xff
      @IF_ZERO
         @POPNULL
         @PRTLN "No Second Number"
         @JMP Loop
      @ENDIF
      @POPNULL
      @INCI MemPtr
      @CALL ISNumeric
   @ENDWHILE
   @POPNULL
   @PUSHI MemPtr
   @CALL stoifirst
   @POPI BVAL
   @PUSHI Mode   
   @SWITCH
   @CASE 1
      @PUSHI AVAL @ADDI BVAL @POPI CVAL
      @CBREAK
   @CASE 2
      @PUSHI AVAL @SUBI BVAL @POPI CVAL
      @CBREAK
   @CASE 3
      @PUSHI AVAL @PUSHI BVAL @CALL MUL @POPI CVAL
      @CBREAK
   @CASE 4
      @PUSHI AVAL @PUSHI BVAL @CALL DIV @POPI CVAL @POPNULL  # Extra pop is for MOD val      
      @CBREAK
   @CASE 5
      @IF_EQ_VV AVAL BVAL
         @MA2V 1 CVAL
      @ELSE
         @MA2V 0 CVAL
      @ENDIF
      @CBREAK
   @CDEFAULT
      @PRT "Unexpected Mode"
      @POPNULL
      @JMP Loop
      @CBREAK
   @ENDCASE
   @POPNULL   #END of Functional Part
@ELSE
   # Start of Command Part
   @POPNULL
   @PUSHI InputString @AND 0xff
   @SWITCH
   @CASE "Q\0"
      @PRTLN "End"
      @END
      @CBREAK
   @CASE "q\0"
      @PRTLN "End"
      @END
      @CBREAK
   @CASE "c\0"
      @MA2V 0 CVAL
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
@ENDIF
@JMP Loop
@END


:CMDCODE
0
:AVAL
0
:BVAL
0
:CVAL
0
:MVAL
0
:MemPtr 0
:Mode 0
:InputString "                               "
