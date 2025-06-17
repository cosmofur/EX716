# Some Helpfull IO funcitions.
! IOLIB_DONE
L string.ld
M IOLIB_DONE 1

G StrReadToChar
@JMP SkipToEnd     # Protects from start of code running in library space
#
# StrReadToChar (StringPtr, Character as word, Length Limit)
# Reads from IO a string that ends with unique character rather than normal newline
#
:StrReadToChar
@POPI SRCReturn
@POPI SRCLimit
@POPI SRCChar
@POPI SRCStrPtr
@MA2V 0 SRCReadCH
@PUSH 0 @POPII SRCStrPtr   # Initilize StrPtr to empty string
@PUSH SRCLimit
@WHILE_NOTZERO
   @SUB 1 @POPI SRCLimit
   @READC SRCReadCH
   @PUSHI SRCReadCH @AND 0xff @POPI SRCReadCH
   @PUSHI SRCStrPtr
   @PUSHI SRCReadCH
   @CALL strcat
   @PUSHI SRCLimit
   @IF_EQ_VV SRCReadCH SRCChar
      @POPNULL
      @PUSH 0
   @ELSE
      @IF_EQ_AV 0 SRCLimit
          @POPNULL
          @PUSH 0
      @ENDIF
   @ENDIF
@ENDWHILE
@POPNULL
@PUSHI SRCReturn
@RET
:SRCReturn 0
:SRCLimit 0
:SRCChar 0
:SRCStrPtr 0
:SRCReadCH 0 0  # Note we reserver 4 bytes ReadCH because READC might return small strings
:SkipToEnd
ENDBLOCK
