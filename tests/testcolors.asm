I common.mc
L screen.ld

@PRTLN "Start:"
@CALL SCRcls

@PUSH 3
@CALL SCRBGColor

@ForIA2B BGColor 0 16
   @PUSHI BGColor
   @CALL SCRBGColor
   @PRT "BG:"
   @PRTI BGColor
   @PRT ":"
   @ForIA2B FGColor 0 16
      @PUSHI FGColor
      @CALL SCRFGColor      
      @PRT "FG:"
      @PRTI FGColor
      @PRT ":ABC"
   @Next FGColor
   @PRTNL
@Next BGColor
@CALL SCRreset
@PRTLN "End:"
@END
:BGColor 0
:FGColor 0
