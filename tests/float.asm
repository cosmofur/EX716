I common.mc
L lmath.ld


# This is the begining of a Floating Point Library
# It is heavly based on the original Microsoft 8K basic
#
# Common Register/Variables
:FACC $$$0     # 32 byte storage
#
# Public Functions
#
#  FloatSIN FloatCOS FloatTAN FloatEXP 
#  FloatABS FloatSGN FloatINT FloatSQR
#  FloatNEG Str2Float Float2Str
#  FloatADD FloatSUB FloatMUL FloatDIV



# Utility Funcitons
# FloatNormalize FloatSignProd FloatGetSignExp
# FloatRestoreSign FloatTestOUFlow FloatTest
# FlatExponent
# Macro to multiply by 10, faster than libary MUL
M MUL10S @SHL @DUP @SHL @SHL @ADDS
# Same for 32 bit math...though the overhead for the calls might make using the MUL32 function worth considering.
:LOC32AVAR 0 0
:LOC32BVAR 0 0
M MUL32x10 @PUSHI %1 @PUSH LOC32AVAR @CALL RTL32 \
          @PUSH LOC32AVAR @PUSH LOC32BVAR @CALL RTL32 \
          @PUSH LOC32BVAR @PUSH LOC32BVAR @CALL RTL32 \
          @PUSH LOC32AVAR @PUSH LOC32BVAR @PUSHI %2 @CALL ADD32

#
# Str2Float(string, floatptr)
# Convert ASCII string to 32 bit Floating Point value
# Valid invlude Scientifice Notation NNN.NNNNE+NN
# Temrinated by any non-numeric char
:Str2Float
   @PUSHRETURN
   # Define and preserve local variables
   =S2F.Sign Val01
   =S2F.ValuePtr Val02
   =S2F.Index1 Val03
   =S2F.PowerPtr Val04
   


:Main . Main
@PUSH InputString
@CALL Str2Float
@END
:InputString "1.2"
