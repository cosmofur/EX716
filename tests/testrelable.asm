I common.mc
L softstack.ld
# Want to test if I can reuse lables with diffrent values as a way to define local variables.
#
# The idea can I use the =lable var notation to have 'local' variables in diffrent functions
# in the same file, and most importably reuse the same lables, with with diffrent values
# Effecticly meaning a labled variable will have a scope that allows the lable itself to
# be reused in diffrent sections of the file.
#
#
#
:Func01
=Cat Var01
=Dog Var02
=Cow Var03
@PUSHRETURN
@PUSHLOCALI Cat
@PUSHLOCALI Dog
@PUSHLOCALI Cow
@MA2V 0x0101 Cat
@MA2V 0x0102 Dog
@MA2V 0x0103 Cow
@PRTLN "Func01 Expect 101,102,103 at addreses 100,200,300"
@PRT "Func01 Vals: " @PRTHEXI Cat @PRTSP @PRTHEXI Dog @PRTSP @PRTHEXI Cow @PRTNL
@PRT "Func01 Addr: " @PRTREF Cat @PRTSP @PRTREF Dog @PRTSP @PRTREF Cow @PRTNL
@POPLOCAL Cow
@POPLOCAL Dog
@POPLOCAL Cat
@POPRETURN
@RET
#
:Func02
=Cat Var02
=Dog Var03
=Cow Var01
@PUSHRETURN
@PUSHLOCALI Cat
@PUSHLOCALI Dog
@PUSHLOCALI Cow
@MA2V 0x0201 Cat
@MA2V 0x0202 Dog
@MA2V 0x0203 Cow
@PRTLN "Func01 Expect 201,202,203 at addreses 200,300,100"
@PRT "Func02 Vals:" @PRTHEXI Cat @PRTSP @PRTHEXI Dog @PRTSP @PRTHEXI Cow @PRTNL
@PRT "Func02 Addr:" @PRTREF Cat @PRTSP @PRTREF Dog @PRTSP @PRTREF Cow @PRTNL
@POPLOCAL Cow
@POPLOCAL Dog
@POPLOCAL Cat
@POPRETURN
@RET
#
:Func03
=Cat Var03
=Dog Var01
=Cow Var02
@PUSHRETURN
@PUSHLOCALI Cat
@PUSHLOCALI Dog
@PUSHLOCALI Cow
@MA2V 0x0301 Cat
@MA2V 0x0302 Dog
@MA2V 0x0303 Cow
@PRTLN "Func03 Expect 301,302,303 at addreses 300,100,200"
@PRT "Func03 Vals:" @PRTHEXI Cat @PRTSP @PRTHEXI Dog @PRTSP @PRTHEXI Cow @PRTNL
@PRT "Func03 Addr:" @PRTREF Cat @PRTSP @PRTREF Dog @PRTSP @PRTREF Cow @PRTNL
@POPLOCAL Cow
@POPLOCAL Dog
@POPLOCAL Cat
@POPRETURN
@RET
#
:Func04
=Cat Var01
=Dog Var02
=Cow Var03
@PUSHRETURN
@PUSHLOCALI Cat
@PUSHLOCALI Dog
@PUSHLOCALI Cow
@MA2V 0x0401 Cat
@MA2V 0x0402 Dog
@MA2V 0x0403 Cow
@PRTLN "Func03 Expect 401,402,403 at addreses 100,200,300"
@PRT "Func04 Vals:" @PRTHEXI Cat @PRTSP @PRTHEXI Dog @PRTSP @PRTHEXI Cow @PRTNL
@PRT "Func04 Refs:" @PRTREF Cat @PRTSP @PRTREF Dog @PRTSP @PRTREF Cow @PRTNL
@PRTLN "Func04 Call Func01"
@CALL Func01
@PRT "Func04 Vals:" @PRTHEXI Cat @PRTSP @PRTHEXI Dog @PRTSP @PRTHEXI Cow @PRTNL
@PRT "Func04 Refs:" @PRTREF Cat @PRTSP @PRTREF Dog @PRTSP @PRTREF Cow @PRTNL
@PRTLN "Func04 Call Func02"
@CALL Func02
@PRT "Func04 Vals:" @PRTHEXI Cat @PRTSP @PRTHEXI Dog @PRTSP @PRTHEXI Cow @PRTNL
@PRT "Func04 Refs:" @PRTREF Cat @PRTSP @PRTREF Dog @PRTSP @PRTREF Cow @PRTNL
@PRTLN "Func04 Call Func03"
@CALL Func03
@PRT "Func04 Vals:" @PRTHEXI Cat @PRTSP @PRTHEXI Dog @PRTSP @PRTHEXI Cow @PRTNL
@PRT "Func04 Refs:" @PRTREF Cat @PRTSP @PRTREF Dog @PRTSP @PRTREF Cow @PRTNL
@POPLOCAL Cow
@POPLOCAL Dog
@POPLOCAL Cat
@POPRETURN
@RET
#
:Main . Main
@CALL Func01
@CALL Func02
@CALL Func03
@CALL Func04
@END

