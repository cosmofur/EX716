I common.mc
L sqrt.ld
L random.ld
L mul.ld
L div.ld

:Main . Main

=Index1 Var01
=Total Var02
=SquareSum Var03
=Count Var04
=Mean Var05
=High Var06
=Low Var07
@MA2V 0 Total
@MA2V 0 SquareSum
@MA2V 0 Count
@MA2V 0 High
@MA2V 255 Low
@PUSH 5 @CALL rndsetseed

# Test 1000 random number draws.
@ForIA2B Index1 0 500
    @CALL rnd16 @AND 255         # We limit values to range 0-255
    @IF_GT_V High
       @DUP @POPI High
    @ENDIF
    @IF_LT_V Low
       @DUP @POPI Low
    @ENDIF
    @DUP
    @ADDI Total @POPI Total
    @DUP
    @CALL MULU
    @ADDI SquareSum @POPI SquareSum
    @INCI Count
@Next Index1
@PRT "Low Value: " @PRTI Low
@PRT "\nHigh Value: " @PRTI High @PRTNL
@PUSHI Total
@PUSHI Count
@CALL DIVU
@PRT "Mean: " @PRTTOP @PRTNL   # Total/Count = Mean
@POPI Mean
@POPNULL           # We don't need remainder. (DIVU returns both remainder and result of DIV)
@PUSHI SquareSum @PUSHI Count  # Square of Sums/Count
@CALL DIVU
@SWP @POPNULL      # Get rid of remainder.
@PUSHI Mean
@DUP
@CALL MULU         # Mean*Mean
@SWP
@SUBS              # Square of Sum/Count - Mean**2
@CALL SQRT         # Square Root
@PRT "Variance: " @PRTTOP @PRTNL
@POPNULL
@END
