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
# While SRCReadCH != SRCChar loop
:SRCMainLoop
@PUSHI SRCReadCH @CMPI SRCChar @POPNULL     # ? SRCReadChr == SRCChar
@JMPZ SRCExitMainLoop
@PUSHI SRCLimit @CMP 0 @POPNULL              # ? SRCLimit == 0
@JMPZ SRCExitMainLoop
   @READC SRCReadCH
   # While it true that READC will sometimes return specail characters as multi byte
   # For our purposes we will only consider the lower ascii characters
   @PUSHI SRCReadCH @AND 0xff @POPI SRCReadCH
   @PUSHI SRCStrPtr # StrPtr is already a pointer, so we just pass its value
   @PUSH SRCReadCH  # Is local storage so we pass it's address turning into pointer
   @CALL strcat
   @DECI SRCLimit   # Count down to zero to prevent infinit loop if ch never seen.
@JMP SRCMainLoop
:SRCExitMainLoop
@PUSHI SRCReturn
@RET
:SRCReturn 0
:SRCLimit 0
:SRCChar 0
:SRCStrPtr 0
:SRCReadCH 0 0  # Note we reserver 4 bytes ReadCH because READC might return small strings
:SkipToEnd
ENDBLOCK
