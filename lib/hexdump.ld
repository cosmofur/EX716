! __LIB_HEXDUMP_LOADED
M __LIB_HEXDUMP_LOADED 1

:HexBuf 0 0
:ASCIIBuf 0 0 0 0 0 0 0 0 0 0
I hexdump.ref

G HexDump
G NibbleToHexChar

#--------------------------------------------------
# HexDump(MemStart, MemLength, Mode)
# Mode: 0 = WORD, 1 = BYTE
#--------------------------------------------------
@FUNCTION HexDump
:HexDump
@PUSHRETURN
@LocalVar Index1    01
@LocalVar MemStart  02
@LocalVar MemLength 03
@LocalVar Column    04
@LocalVar MemStop   05
@LocalVar Mode      06

   #--------------------------------------------
   # Load parameters
   #--------------------------------------------
   @POPI Mode
   @POPI MemLength
   @POPI MemStart

   # MemStop = MemStart + MemLength
   @PUSHI MemStart
   @ADDI MemLength
   @POPI MemStop

   @MA2V 0 Column

   #==================================================
   # WORD MODE (16-bit)
   #==================================================
   @IF_EQ_AV 0 Mode
      #--------------------------------------------
      # Print initial address header
      #--------------------------------------------
      @PRTHEXI MemStart @PRT ": "


      # Ensure MemStop parity matches MemStart
      # if ((MemStart ^ MemStop) & 1) != 0 → MemStop--
      @PUSHI MemStart
      @XORI MemStop
      @AND 0x1
      @IF_NOTZERO
         @DECI MemStop
      @ENDIF
      @POPNULL

      @ForIV2V Index1 MemStart MemStop

         @PUSHII Index1        # read 16-bit word
         @PRTHEXTOP
         @POPNULL
         @PRTSP

         @INCI Column
         @PUSHI Column @AND 0x7
         @IF_ZERO
            @PRTNL
            @PRTHEXI Index1 @ADDI 2 @PRT ": "
            @MA2V 0 Column
         @ENDIF
         @POPNULL

      @NextBy Index1 2

   #==================================================
   # BYTE MODE (8-bit)
   #==================================================
   @ELSE
      @PRTLN "\n      -0 -1 -2 -3 -4 -5 -6 -7 -8 -9 -A -B -C -D -E -F"
     #--------------------------------------------
     # Print initial address header
     #--------------------------------------------
     @PRTHEXI MemStart @PRT ": "
     
      @ForIV2V Index1 MemStart MemStop

         @PUSHII Index1
         @AND 0xff           # Only lower byte this loop
         @IF_INRANGE_AB 0x20 0x7e
             @DUP
             @PUSH ASCIIBuf @ADDI Column
             @POPS
         @ELSE
             @PUSH "_\0"
             @PUSH ASCIIBuf @ADDI Column
             @POPS
         @ENDIF
         @PUSH HexBuf          # pointer to temp buffer
         @CALL ByteToHexStr
         @PUSH 0x20 @PUSH HexBuf+2 @POPS
         @PRTS HexBuf


         @INCI Column
         @PUSHI Column @AND 0xF
         @IF_ZERO
            @PRT "   "
            @PRTS ASCIIBuf
            @PRTNL
            @MA2V 0 ASCIIBuf
            @PUSHI Index1 @ADD 1
            @IF_NEQ_V MemStop
               @PRTHEXI Index1 @PRT ": "
            @ENDIF
            @POPNULL
            @MA2V 0 Column
         @ENDIF
         @POPNULL

      @Next Index1
      

   @ENDIF
   @PRT "   "
   @PRTS ASCIIBuf
   @PRTNL

@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
@ENDFUNCTION

#--------------------------------------------
# NibbleToHexChar(nibble) -> ASCII in TOS
#--------------------------------------------
@FUNCTION NibbleToHexChar
:NibbleToHexChar
@PUSHRETURN
   # input nibble in TOS
   @IF_ULE_A 9       # <= 9
      @ADD  "0\0"
   @ELSE
      @ADD 0x41-10
   @ENDIF
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------------
# ByteToHexStr(Byte, StrPtr)
#--------------------------------------------
@FUNCTION ByteToHexStr
:ByteToHexStr
@PUSHRETURN
@LocalVar Byte   01
@LocalVar StrPtr 02

   @POPI StrPtr
   @POPI Byte

   # High nibble
   @PUSHI Byte
   @SHR4
   @AND 0xF
   @CALL NibbleToHexChar
   @PUSHI StrPtr @POPS      # store char

   # Low nibble
   @PUSHI Byte
   @AND 0xF
   @CALL NibbleToHexChar
   @PUSHI StrPtr @ADD 1  @POPS

   # Null terminator
   @PUSHI 0
   @PUSHI StrPtr @ADD 2 @POPS

   @RestoreVar 02
   @RestoreVar 01
   

@POPRETURN
@RET
@ENDFUNCTION
ENDBLOCK
