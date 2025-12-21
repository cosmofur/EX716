I common.mc
L screen.ld
L lmath.ld
L shift16.ld
L fixedpoint.ld
L fixedpoint_io.ld

#############################
# We need some 'fixed point' math operations.
# While we'll use the 32 math libary, the results here are all 16b
# 8 bit value and 8 bit power.


# Macro to DIV3U with normailzation  
M DIV32U_norm \
     @Call32(vv) normalize32_int %1 %2 \
     @POPNULL \               # Get Rid of unneeded shift info.
     @CALL DIV32U

G fx_escape G CountZero16 G CountZero32 
   
   


##############################
# fx_escape(MAG): Boolen 1 or 0
#############################
:fx_escape
@SWP
@IF_GT_A 1024
   @POPNULL
   @PUSH 1
@ELSE
   @POPNULL
   @PUSH 0
@ENDIF
@SWP
@RET
   
   
   
###############################
# mandelbrotCode(X0,Y0,max_iter):Iter
###############################
:mandelbrotCode
@PUSHRETURN
   @LocalVar max_iter 01
   @LocalVar X1 02
   @LocalVar Y1 03
   @LocalVar Iteration 04
   @LocalVar X2 05
   @LocalVar Y2 06
   @LocalVar X0 07
   @LocalVar Y0 08

   @POPI max_iter
   @POPI Y0
   @POPI X0


   @MA2V 0 X1
   @MA2V 0 Y1
   @MA2V 0 Iteration
   
   @PUSHI Iteration
   @WHILE_LT_V max_iter
      @POPNULL
      
      @Call(v) fx_sqr X1
      @POPI X2
      @Call(v) fx_sqr Y1
      @POPI Y2

      @PUSHI X2 @ADDI Y2              # even faster than fx_add
      @CALL fx_escape
      @IF_ZERO
         @POPNULL
         @Call(vv) fx_mul X1 Y1  # X1*Y1
         @CALL fx_mul2           # *2
         @ADDI Y0                     # + Y0
         @POPI Y1
         
         @PUSHI X2
         @SUBI Y2
         @ADDI X0
         @POPI X1
         @INCI Iteration
         @PUSHI Iteration            # Continue until max_iter or escape.
      @ELSE
         @POPNULL      
         @PUSHI Iteration                    # Break While
         @JMP FoundEscape
      @ENDIF

   @ENDWHILE
   @POPNULL
   @PUSHI max_iter    # We end here only if we his max_iter, return max_iter
#
#
   :FoundEscape       # We skip here if escape, and value already on stack.

   @RestoreVar 08
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
   @POPRETURN
@RET


#######################################
# MandelBrotDriver()
#######################################
:MandelBrotDriver
@PUSHRETURN
   @LocalVar Width 01
   @LocalVar Height 02
   @LocalVar Max_Iter 03
   @LocalVar XMin 04
   @LocalVar XMax 05
   @LocalVar YMin 06
   @LocalVar YMax 07
   @LocalVar X_Step 08
   @LocalVar Y_Step 09
   @LocalVar Row 10
   @LocalVar Col 11
   @LocalVar Y0 12
   @LocalVar X0 13
   @LocalVar I2fx1 14
   @LocalVar I2fx2 15   

#   @CALL WinResize
   @CALL WinClear
   @CALL ColorReset

   @MV2V WinWidth Width
   @MV2V WinHeight Height

  # Over Ride Width and Height for faster testing.
  @MA2V 40 Width
  @MA2V 20 Height

   @MA2V 32 Max_Iter

   @MA2V 0xfe00 XMin   
   @MA2V 0x100 XMax  
   @MA2V 0xfecd YMin    
   @MA2V 0x132  YMax  



   @PUSHI XMax @SUBI XMin   # X_Step = (XMax-XMin)/Width
   @POPI I2fx1
   @PUSHI Width @SHLN 8
   @POPI I2fx2              # Convert Integer to fx
   @Call(vv) fx_div I2fx1 I2fx2
   @POPI X_Step

   @PUSHI YMax @SUBI YMin
   @PUSHI Height @SHLN 8 @CALL fx_div
   @POPI Y_Step

   @PRT "XMin:" @Call(v) fx_print XMin @PRT " YMin:" @Call(v) fx_print YMin @PRTNL
   @PRT "XMax:" @Call(v) fx_print XMax @PRT " YMin:" @Call(v) fx_print YMax @PRTNL   
   @PRT "X_Step:" @Call(v) fx_print X_Step  @PRT " Y_Step:" @Call(v) fx_print Y_Step @PRTNL 

   
   @ForIA2V Row 0 Height        # Stops at and not execute when Row==Height
      @PUSHI Row @SHLN 8 @Call(v) fx_mul Y_Step
      @ADDI YMin
      @POPI Y0

      @ForIA2V Col 0 Width
          @PUSHI Col @SHLN 8 @Call(v) fx_mul X_Step
          @ADDI XMin
          @POPI X0
          @Call(vvv) mandelbrotCode X0 Y0 Max_Iter
          @IF_EQ_V Max_Iter
             @Call(A) ColorFGSet 0
             @PRT "."
          @ELSE
             @AND 0xf
             @SHL
             @AND 0xff
             @PUSH 0xff @SWP
             @SUBS
             @CALL ColorFGSet           
             @PRT "#"
          @ENDIF
      @Next Col
      @PRTNL
   @Next Row
   @CALL ColorReset   
   @RestoreVar 15
   @RestoreVar 14
   @RestoreVar 13    
   @RestoreVar 12
   @RestoreVar 11
   @RestoreVar 10   
   @RestoreVar 09
   @RestoreVar 08   
   @RestoreVar 07   
   @RestoreVar 06   
   @RestoreVar 05   
   @RestoreVar 04   
   @RestoreVar 03   
   @RestoreVar 02
   @RestoreVar 01
   @POPRETURN
@RET




:TestDivSweep
@PUSHRETURN
   @LocalVar A1 01
   @LocalVar B1 02
   @LocalVar I1 03

#   @MA2V 0x100 A1    # == FX 1.0
#   @MA2V 0xA00 B1    # == FX 10.0
    @MA2V 0x100 B1    # == FX 1.0
    @MA2V 1 A1        # == FX 1/256

   @ForIA2B I1 0 64
      @PRTI I1 @PRT ") "
      @Call(v) fx_print B1
      @PRT " / "
      @Call(v) fx_print A1

      @PRT " = Q:"
      @Call(vv) fx_div B1 A1
      @CALL fx_print
      @PRTNL

#      @PUSHI A1 @ADD 0x500 @POPI A1  # 5<<8 0x500
       @PUSHI A1 @ADD 1 @POPI A1  # 1 << 8 == 1/256th in FX format.
   @Next I1
   
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
   @POPRETURN
@RET

:Main . Main
@CALL MandelBrotDriver
@END



M TestFxDiv @PUSH %1 @CALL fx_print \
            @PRT " / "              \
            @PUSH %2 @CALL fx_print \
            @PRT " = "              \
            @PUSH %1 @PUSH %2 @CALL fx_div \
            @PRT "Q:" @CALL fx_print @PRTNL
            
#@PUSH 256 @CALL fx_print
#@PRT " / "
#@PUSH 64 @CALL fx_print
#@PRT " = "
#@PUSH 256 @PUSH 64 @CALL fx_div
#@CALL fx_print
#@PRTNL





@TestFxDiv 256 64
@TestFxDiv 256 128
@TestFxDiv 128 256
@TestFxDiv 100 25
@TestFxDiv 25 100
@TestFxDiv -256 64
@TestFxDiv 256 -64
@TestFxDiv -256 -64
@TestFxDiv -128 256
@TestFxDiv 128 -256
@TestFxDiv 64 256
@TestFxDiv 32 256
@TestFxDiv 16 256
@TestFxDiv 256 300
@TestFxDiv 300 256
@TestFxDiv 1 256
@TestFxDiv 2 256
@TestFxDiv 3 256
@TestFxDiv 1 512
@TestFxDiv 1 1024
@TestFxDiv 30000 100
@TestFxDiv 30000 300
@TestFxDiv 30000 1000
@TestFxDiv -30000 300
@TestFxDiv 30000 -300
@TestFxDiv -30000 -300
@TestFxDiv -1024 300
@TestFxDiv 1024 -300
@TestFxDiv 32767 1
@TestFxDiv -32768 1
@TestFxDiv 32767 255
@TestFxDiv 255 32767
@TestFxDiv 1024 3
@TestFxDiv 100 0
@TestFxDiv -100 0
@TestFxDiv 0 0
@END


@PRTLN "Expect 1/(3/256) to fail: Should be 85.3333"
@Call(AA) fx_div 0x100 0x3
@CALL fx_print  @PRTNL
@StackDump
@PRTLN "Expect 1/(4/256) to work: Should be 64.0000"
@Call(AA) fx_div 0x100 0x4
@PRTHEXTOP @PRTSP
@CALL fx_print @PRTNL
@StackDump
@END

@PRT "Flags32: " @PRTI Flags32 @PRTNL
@PRT "CMP 0x10000 vs 0x18000"@Call32(AA) CMP32U $$$0x10000 $$$0x18000 @PRTNL
@PRT "Flags32: " @PRTI Flags32 @PRTNL
@PRT "CMP 0x20000 vs 0x18000"@Call32(AA) CMP32U $$$0x20000 $$$0x18000 @PRTNL
@PRT "Flags32: " @PRTI Flags32 @PRTNL
@PRT "CMP 0x18000 vs 0x18000"@Call32(AA) CMP32U $$$0x18000 $$$0x18000 @PRTNL
@PRT "Flags32: " @PRTI Flags32 @PRTNL
@PRT "CMP 0x17fff vs 0x18000"@Call32(AA) CMP32U $$$0x17fff $$$0x18000 @PRTNL
@PRT "Flags32: " @PRTI Flags32 @PRTNL
@END




#@CALL TestDivSweep

@END


@END
@CALL MandelBrotDriver
@END





:Testfx_mul
=X1 256 =Y1 256 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 512 =Y1 768 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 128 =Y1 128 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 64 =Y1 64 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 384 =Y1 384 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 512 =Y1 -256 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 -256 =Y1 -256 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 -512 =Y1 768 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 -384 =Y1 -512 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 768 =Y1 768 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 1024 =Y1 1024 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 1024 =Y1 -1024 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 256 =Y1 768 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 768 =Y1 256 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 256 =Y1 256 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 -128 =Y1 128 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 -128 =Y1 -128 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 256 =Y1 0 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 -315 =Y1 192 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL
=X1 315 =Y1 -192 @Call(AA) fx_mul X1 Y1 @PRT "X: " @PUSH X1 @CALL fx_print  @PRT " Y:" @PUSH Y1 @CALL fx_print  @PRT " = " @POPI TR @Call(v) fx_print TR @PRTNL

@END
@PUSH32(A) $$$0x80000000 @PUSH 8 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x80000000 @PUSH 16 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x80000000 @PUSH 24 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x80000000 @PUSH 32 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x80000000 @PUSH 5 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x80000000 @PUSH 12 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x80000000 @PUSH 19 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x80000000 @PUSH 25 @PRT "0x80000000 SHR By:" @PRTTOP @PRTSP @CALL SHR32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@END


@PUSH32(A) $$$0x1 @PUSH 4 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x1 @PUSH 7 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x1 @PUSH 8 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x1 @PUSH 11 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32 @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x1 @PUSH 15 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32 @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x1 @PUSH 16 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x1 @PUSH 20 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@PUSH32(A) $$$0x1 @PUSH 31 @PRT "1 SHL By:" @PRTTOP @PRTSP @CALL SHL32  @PRT32HEXS @POPNULL @POPNULL @PRTNL
@END




:TR 0 0
:Index1 0
:A1 0
:B1 0

   
