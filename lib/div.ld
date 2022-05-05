# Input: Stack RET, Divident, Divisor
# Requires common.mc
$$JMP $DIVINIT
G DIV
:DIV
$$POPI $RETURN
$$POPI $Numor
$$POPI $Dsor
@MC2M 0 $NEGFLAG
# Test for Negative Numbers and set NEGFLAG if just one is negative. 
$$PUSH 0
$$CMPI $Numor
$$POPI $UNUSED
$$JMPN $NOTNEG1
# Invert NegFlag
$$PUSHI $NEGFLAG
$$INV $NEGFLAG
$$POPI $NEGFLAG
# Do Abs(Numor)
$$PUSHI $Numor
$$INV $Numor
$$ADD 1
$$POPI $Numor
:NOTNEG1
# Now for Dsor
$$PUSH 0
$$CMPI $Dsor
$$POPI $UNUSED
$$JMPN $NOTNEG2
# Invert NegFlag
$$PUSHI $NEGFLAG
$$INV $NEGFLAG
$$POPI $NEGFLAG
# Do Abs(Dsor)
$$PUSHI $Dsor
$$INV $Dsor
$$ADD 1
$$POPI $Dsor
:NOTNEG2
@MC2M 0 $Result
# First we need to 'align' Numor and Dsor
@MM2M $Dsor $TDsor
# While Dsor < $Numor : Dsor = Dsor << 1
$$PUSHI $Dsor
:ALIGNLOOP
$$CMPI $Numor
$$RTL
$$JMPN $ALIGNLOOP
:ENDALIGN
$$POPI $Dsor
# Do Until Loop while  Dsor >= Tsor
:DOLOOP1
# Result << 1
  $$PUSHI $Result
  $$RTL
  $$POPI $Result
# If Numor >= $Dsor
  $$PUSHI $Numor
  $$CMPI $Dsor
  $$POPI $UNUSED
  $$JMPN $NOTIF
   # Numor = Numor - Dsor
     $$PUSHI $Numor
     $$SUBI $Dsor
     $$POPI $Numor
     $$PUSHI $Result
     $$OR 1
     $$POPI $Result
:NOTIF
  $$PUSHI $Dsor
  $$RTR
  $$POPI $Dsor
# Until ( Dsor >= TDsor)   
  $$PUSHI $Dsor
  $$CMPI $TDsor
  $$POPI $UNUSED
  @JGE $DOLOOP1
# End of until Loop, Result has answer Numor has remainder
$$PUSHI $Numor
$$PUSH 0
$$CMPI $NEGFLAG
$$POPI $UNUSED
$$JMPZ $NOTNEG
$$PUSHI $Result
$$INV $Result
$$ADD 1
$$POPI $Result
:NOTNEG
$$PUSHI $Result
$$PUSHI $RETURN
@RET
b0
b0
:RETURN
0
:Numor
0
:Dsor
0
:TDsor
0
:NEGFLAG
0
:Result
0
:UNUSED
0
:DIVINIT
