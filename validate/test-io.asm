# Test IO library
I common.mc
L io.ld
:Main . Main	
@PRT "Enter Test until '.':"
@PUSH String @PUSH "." b0 @PUSH 20
@CALL StrReadToChar
@PRT "X-"
@PRTS String @PRTLN "-X"
@END
:String "                 "
