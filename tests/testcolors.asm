I common.mc
L screen.asm

@PRTLN "Start:"
@CALL SCRcls

@PUSH 3
@CALL SCRBGColor

@ForIfA2B BGColor 0 16 BGColorNext
   @PUSHI BGColor
   @CALL SCRBGColor
   @PRT "BG:"
   @PRTI BGColor
   @PRT ":"
   @ForIfA2B FGColor 0 16 FGColorNext
      @PUSHI FGColor
      @CALL SCRFGColor      
      @PRT "FG:"
      @PRTI FGColor
      @PRT ":ABC"
   @NextNamed FGColor FGColorNext
   @PRTNL
@NextNamed BGColor BGColorNext
@CALL SCRreset
@PRTLN "End:"
@END
:BGColor 0
:FGColor 0
