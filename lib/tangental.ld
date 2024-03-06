# This is Integer version of the SIN and COS Tangental functions multiplied by 1000 at a resoltion of 4.5 degrees
# That is we have 80 entries in our SIN table and can calculate both SIN and COS directly from this table.
L div.ld
! SeenTangental
M SeenTangental 1
G SIND
G SINR
G COSD
G COSR
:SINTable

#   2   3   4   5   6   7   8   9   10  11  12  13  14  15
0   17  35  52  70  87  105 122 139 156 174 191 208 225 242
259 276 292 309 326 342 358 375 391 407 423 438 454 469 485
500 515 530 545 559 574 588 602 616 629 643 656 669 682 695
707 719 731 743 755 766 777 788 799 809 819 829 839 848 857
866 875 883 891 899 906 914 921 927 934 940 946 951 956 961 
966 970 974 978 982 985 988 990 993 995 996 998 999 999 1000
#
#
# Degree functions. integer 0-359 as input
#
# Sin in degrees
:SIND
@SWP
@IF_GT_A 360
  @PUSH 360       # If Number is not in range, get its 360 MOD
  @CALL DIV
  @POPNULL
@ENDIF
@SWITCH
@CASE_RANGE 0 89
   @MA2V 1 SINDIR
   @MA2V 1 SINRST
   @CBREAK
@CASE_RANGE 90 179
   @MA2V -1 SINDIR 
   @MA2V 1 SINRST
   @SUB 90
   @CBREAK
@CASE_RANGE 180 269
   @MA2V 1 SINDIR
   @MA2V -1 SINRST
   @SUB 180
   @CBREAK   
@CASE_RANGE 270 359
   @MA2V -1 SINDIR 
   @MA2V -1 SINRST
   @SUB 270
   @CBREAK
@CDEFAULT
   @PRT "Transidental Function Error, Invalid range: " @PRTTOP
   @END
   @CBREAK
@ENDCASE
@RTL              # *2
@IF_EQ_VA SINDIR -1
   @PUSH SINTable   # Get Value starting from bottom table looking backwards
   @ADD 178
   @SWP
   @SUBS
   @PUSHS
@ELSE
   @ADD SINTable    # Get Value starting from top and adding forward
   @PUSHS
@ENDIF
@IF_EQ_VA SINRST -1
   @POPNULL
   @COMP2   # Negative
@ENDIF
   
@SWP              # Put Return Address back on top
@RET
:SINDIR 0
:SINRST 0
#
# Cos in degrees
:COSD
@SWP
@ADD 90           # COS is 90 degrees offset from SIN
@CALL SIND
@SWP              # Put Return Address back on top
@RET
#

# Now the Radians version. In these cases is Radions*1000 
#
# SINR in Radians
:SINR
@SWP
@IF_GT_A 6282
  @PUSH 6281       # If Number is not in range, get its 6282 MOD
  @CALL DIV
  @POPNULL
@ENDIF
@PUSH           # Radians / 78 fit neatly into a 0-79 table
@CALL DIV
@SWP @POPNULL     # Don't need MOD
@RTL
@ADD SINTable
@PUSHS            # Value we want *1000
@SWP              # Put Return Address back on top
@RET
# Cos in Radians
:COSR
@SWP
@ADD 1570         # when radians*1000, 1570 is about == to 90 degrees
@CALL SINR
@SWP              # Put Return Address back on top
@RET
#
#
#
# Arctan2(X,Y) 
:ARCTAN2
@POPI ReturnAT2
@POPI YInputAT2
@POPI XInputAT2
@MA2V 0 ResultAT2
@MA2V 0 XOLDAT2
@MA2V 0 YOLDAT2
@ForIA2B IndexAT2 0 10
    @PUSHI YInputAT2
    @IF_NOTZERO
       @RTR           # Y >> 1
       @ADDI ResultAT2
       @POPI ResultAT2
       @MV2V XInputAT2 XOLDAT2
       @PUSHI XInputAT2
       @PUSHI YOLDAT2 @RTR
       @SUBS
       @POPI XInputAT2   # X=X - (Y_old >> 1)
       @MV2V YInputAT2 YOLDAT2
       @PUSHI YInputAT2
       @PUSHI XInputAT2 @RTR
       @ADDS              # Y = Y + (X_old >> 1)
    @ENDIF
@Next IndexAT2
@PUSHI ResultAT2
@PUSHI ReturnAT2
@RET
:ReturnAT2 0
:YInputAT2 0
:XInputAT2 0
:XOLDAT2 0
:YOLDAT2 0
:ResultAT2 0
:IndexAT2 0
ENDBLOCK
