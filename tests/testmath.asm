I common.mc
L lmath.asm
@PRT "Test Math"
# Some helpful macros

#
#
@MOVE32AV 5 VA32
@MOVE32AV 2 VB32
@MOVE32AV 0 VC32


# Setup D to be > 0xffff
@PUSH VA32
@PUSH VB32
@CALL DIV32

@POPI VC32
@COPY32VV VC32 VD32
@POPI VC32
@COPY32VV VC32 VE32
@PRT "VA:" @PRT32I VA32 @PRT " / " @PRT32I VB32
@PRT " = "
@PRT32I VD32 @PRT " and " @PRT32I VE32
@END

# Now set VA to something that will start bellow D and cross over.
@MOVE32AV 50000 VA32
@MOVE32AV 550 VB32


@ForIfA2B ICount 0 5000 FLoop1
@PUSH VA32
@PUSH VB32	
@PUSH VA32
@CALL ADD32
@PRT "Function ADD to Self: " @PRT32I VA32 @PRTNL
@NextNamed ICount FLoop1



@END


:ICount 0






# Fixed 32b numbers
:Zero32 0 0
:One32 $$$1
:Two32 $$$2
:Ten32 $$$10
:N10032 $$$-100
#
# Work variables
:VA32 0 0
:VB32 0 0
:VC32 0 0
:VD32 0 0
:VE32 0 0
