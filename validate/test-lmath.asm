I common.mc
L lmath.ld

:Aval $$$02
:Bval $$$010
:Cval $$$00
:Dval $$$00
:APtr Aval
:BPtr Bval
:CPtr Cval

:Main . Main
@MOVE32AV $$$0x40000 Aval
@MOVE32AV $$$93 Aval
@MOVE32AV $$$10  Bval	
@MOVE32AV $$$0  Cval

@PUSH Aval @PUSH Bval @PUSH Cval @PUSH Dval @CALL DIV32U
@PRT "DIV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRT " D:" @PRT32I Dval @PRTNL
@MOVE32AV $$$90 Aval
@MOVE32AV $$$10  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @PUSH Dval @CALL DIV32
@PRT "DIV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRT " D:" @PRT32I Dval @PRTNL 
@MOVE32AV $$$105 Aval
@MOVE32AV $$$10  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @PUSH Dval @CALL DIV32U
@PRT "DIV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRT " D:" @PRT32I Dval @PRTNL
@MOVE32AV $$$15 Aval
@MOVE32AV $$$10  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @PUSH Dval @CALL DIV32U
@PRT "DIV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRT " D:" @PRT32I Dval @PRTNL 

@MOVE32AV $$$0x3100E Aval
@MOVE32AV $$$16  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @PUSH Dval @CALL DIV32U
@PRT "DIV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRT " D:" @PRT32I Dval @PRTNL 

@MOVE32AV $$$3000 Aval
@MOVE32AV $$$100  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL ADD32
@PRT "Add A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$100000 Aval
@MOVE32AV $$$-100  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL ADD32
@PRT "Add A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$10000 Aval
@MOVE32AV $$$100  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL SUB32
@PRT "Sub A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$-10 Aval
@MOVE32AV $$$100  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL SUB32
@PRT "Sub A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$0x0001 Aval
@MOVE32AV $$$32768  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @CALL RTL32
@PRT "RTL A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTL32
@PRT "RTL A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTL32
@PRT "RTL A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTL32
@PRT "RTL A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTL32
@PRT "RTL A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@PUSH Aval @PUSH Bval @CALL RTR32
@PRT "RTR A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTR32
@PRT "RTR A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTR32
@PRT "RTR A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
#@PRT32I Aval @PRT " B:" @PRT32I Bval @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTR32
@PRT "RTR A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL RTR32
@PRT "RTR A:" @PUSH Aval @CALL PRT32BIN @PRT " B:" @PUSH Bval @CALL PRT32BIN @PRTNL
@MOVE32AV $$$3000 Aval
@MOVE32AV $$$100  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @CALL CMP32
@PRT "CMP A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " Return:" @PRTTOP @POPNULL @PRTNL
@MOVE32AV $$$50 Aval
@MOVE32AV $$$150  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @CALL CMP32
@PRT "CMP A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " Return:" @PRTTOP @POPNULL @PRTNL
@MOVE32AV $$$-100 Aval
@MOVE32AV $$$-100  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @CALL CMP32
@PRT "CMP A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " Return:" @PRTTOP @POPNULL @PRTNL
@MOVE32AV $$$8 Aval
@MOVE32AV $$$4  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL AND32
@PRT "AND A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$9 Aval
@MOVE32AV $$$3  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL AND32
@PRT "AND A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$0xff000 Aval
@MOVE32AV $$$0xf001  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL AND32
@PRT "AND A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$2 Aval
@MOVE32AV $$$8  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL OR32
@PRT "OR A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$0x40000 Aval
@MOVE32AV $$$0xF000  Bval
@MOVE32AV $$$0  Cval
@PUSH Aval @PUSH Bval @PUSH Cval @CALL OR32
@PRT "OR A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRT " C:" @PRT32I Cval @PRTNL
@MOVE32AV $$$0x0 Aval
@COPY32VV Aval Bval
@PUSH Aval @PUSH Bval @CALL INV32
@PRT "INV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRTNL
@COPY32VV Bval Aval
@PUSH Aval @PUSH Bval @CALL INV32
@PRT "INV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRTNL
@MOVE32AV $$$0xf1f1f1f1 Aval
@COPY32VV Aval Bval
@PUSH Aval @PUSH Bval @CALL INV32
@PRT "INV A:" @PRT32I Aval @PRT " B:" @PRT32I Bval @PRTNL

@END
