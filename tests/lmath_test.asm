I common.mc
L softstack.ld
L heapmgr.ld
L div.ld
L mul.ld
L lmath.ld
M Load32BinTestRow \
   @M32P2V %1 %2 \
   @PUSHI %1 @ADD 4 @POPI %1 \
   @M32P2V %1 %3 \
   @PUSHI %1 @ADD 4 @POPI %1 \
   @M32P2V %1 %4 \
   @PUSHI %1 @ADD 4 @POPI %1


:Main . Main
@Locals
   @Local32 V1
   @Local32 V2
   @Local32 V3
   @Local32 Rem_Low   
   @Local Index
   @Local Ptr
@PRTLN "Test 32 bit Math Library"
@PRTLN "------------------------"
@PRTNL
@PRTLN "Test 32 Bit assignments"
@PRT "ADD32 Tests(" @PRTI addTestData @PRT ")" @PRTNL
@MA2V addTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 addTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " + " @PRT32HEXI V2
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) ADD32 V1 V2
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index
############################
@PRT "SUB32 Tests(" @PRTI subTestData @PRT ")" @PRTNL
@MA2V subTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 subTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " - " @PRT32HEXI V2
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) SUB32 V1 V2
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index
############################
@PRT "MUL32U Tests(" @PRTI mulTestData @PRT ")" @PRTNL
@MA2V mulTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 mulTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT "|" @PRT32HEXI V1 @PRT " * " @PRT32HEXI V2 @PRT "|"
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) MUL32U V1 V2
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index
############################
@PRT "DIV32U Tests(" @PRTI divTestData @PRT ")" @PRTNL
@MA2V divTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 divTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT "|" @PRT32HEXI V1 @PRT " / " @PRT32HEXI V2 @PRT "|"
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) DIV32U V1 V2
   @POP32I(VV) V3 Rem_Low
   @PRT " Got: " @PRT32HEXI V3 @PRT " Remain: " @PRT32HEXI Rem_Low  @PRTNL
@Next Index

############################
@PRT "MUL32U Tests(" @PRTI mulTestData @PRT ")" @PRTNL
@MA2V mulSignedTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 mulSignedTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " * " @PRT32HEXI V2
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) MUL32S V1 V2
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index
############################
@PRT "DIV32S Tests(" @PRTI divSignedTestData @PRT ")" @PRTNL
@MA2V divSignedTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 divSignedTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " / " @PRT32HEXI V2
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) DIV32S V1 V2
   @POP32I(VV) V3 Rem_Low
   @PRT " Got: " @PRT32HEXI V3 @PRT " Remain: " @PRT32HEXI Rem_Low @PRTNL
@Next Index

############################
@PRT "COMP232 Tests(" @PRTI comp2TestData @PRT ")" @PRTNL
@MA2V comp2TestData Ptr
@INC2I Ptr
@ForIA2V Index 0 comp2TestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " Comp2"
   @PRT " = " @PRT32HEXI V3   
   @Call32(V) COMP232 V1
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index

############################
@PRT "AND32 Tests(" @PRTI andTestData @PRT ")" @PRTNL
@MA2V andTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 andTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " & " @PRT32HEXI V2
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) AND32 V1 V2
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index

############################
@PRT "OR32 Tests(" @PRTI orTestData @PRT ")" @PRTNL
@MA2V orTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 orTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " | " @PRT32HEXI V2
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) OR32 V1 V2
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index

############################
@PRT "XOR32 Tests(" @PRTI xorTestData @PRT ")" @PRTNL
@MA2V xorTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 xorTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " xor " @PRT32HEXI V2
   @PRT " = " @PRT32HEXI V3   
   @Call32(VV) XOR32 V1 V2
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index

############################
@PRT "INV32 Tests(" @PRTI invTestData @PRT ")" @PRTNL
@MA2V invTestData Ptr
@INC2I Ptr
@ForIA2V Index 0 invTestData
   @Load32BinTestRow Ptr V1 V2 V3
   @PRT32HEXI V1 @PRT " ! "
   @PRT " = " @PRT32HEXI V3   
   @Call32(V) INV32 V1
   @POP32I(V) V3
   @PRT " Got: " @PRT32HEXI V3 @PRTNL
@Next Index



@END
:addTestData
5
$$$0        $$$0        $$$0
$$$1        $$$1        $$$2
$$$0xffff   $$$1        $$$0x10000
$$$0xffffffff $$$1      $$$0
$$$0x80000000 $$$0x80000000 $$$0

:mulTestData
6
$$$0        $$$1234     $$$0
$$$1        $$$1234     $$$1234
$$$2        $$$3        $$$6
$$$0xffff   $$$2        $$$0x1fffe
$$$0x10000  $$$0x10000  $$$0
$$$0xffffffff $$$2      $$$0xfffffffe

:divTestData
6
$$$0        $$$1        $$$0
$$$1        $$$1        $$$1
$$$10       $$$2        $$$5
$$$10       $$$3        $$$3
$$$0x10000  $$$0x10     $$$0x1000
$$$0xffffffff $$$0xffff $$$0x10001

:subTestData
4
$$$0x1000  $$$1        $$$0xfff
$$$0       $$$1        $$$0xffffffff
$$$0x1000  $$$0x10000  $$$0xffff1000
$$$0xffff  $$$1        $$$0xfffe

:mulSignedTestData
6
$$$2        $$$3        $$$6
$$$-2       $$$3        $$$-6
$$$2        $$$-3       $$$-6
$$$-2       $$$-3       $$$6
$$$-1       $$$1        $$$-1
$$$-1       $$$-1       $$$1


:divSignedTestData
8
$$$6        $$$3        $$$2
$$$-6       $$$3        $$$-2
$$$6        $$$-3       $$$-2
$$$-6       $$$-3       $$$2
$$$7        $$$3        $$$2
$$$-7       $$$3        $$$-2
$$$7     $$$-3     $$$-2
$$$-7    $$$-3     $$$2


:comp2TestData
5
$$$0x00000000 $$$0 $$$0x00000000
$$$0x00000001 $$$0 $$$0xffffffff
$$$0xffffffff $$$0 $$$0x00000001
$$$0x80000000 $$$0 $$$0x80000000
$$$0x7fffffff $$$0 $$$0x80000001

:andTestData
6
$$$0x00000000  $$$0x00000000  $$$0x00000000
$$$0xffffffff  $$$0x00000000  $$$0x00000000
$$$0xffffffff  $$$0xffffffff  $$$0xffffffff
$$$0xaaaaaaaa  $$$0x55555555  $$$0x00000000
$$$0x12345678  $$$0x00ff00ff  $$$0x00340078
$$$0x80000001  $$$0x7fffffff  $$$0x00000001

:orTestData
6
$$$0x00000000  $$$0x00000000  $$$0x00000000
$$$0xffffffff  $$$0x00000000  $$$0xffffffff
$$$0xaaaaaaaa  $$$0x55555555  $$$0xffffffff
$$$0x12345678  $$$0x00ff00ff  $$$0x12ff56ff
$$$0x80000000  $$$0x00000001  $$$0x80000001
$$$0x0000ffff  $$$0xffff0000  $$$0xffffffff

:xorTestData
6
$$$0x00000000  $$$0x00000000  $$$0x00000000
$$$0xffffffff  $$$0x00000000  $$$0xffffffff
$$$0xffffffff  $$$0xffffffff  $$$0x00000000
$$$0xaaaaaaaa  $$$0x55555555  $$$0xffffffff
$$$0x12345678  $$$0x00ff00ff  $$$0x12cb5687
$$$0x80000001  $$$0x7fffffff  $$$0xffffffff

:invTestData
6
$$$0x00000000 $$$0  $$$0xffffffff
$$$0xffffffff $$$0  $$$0x00000000
$$$0xaaaaaaaa $$$0  $$$0x55555555
$$$0x55555555 $$$0 $$$0xaaaaaaaa
$$$0x12345678 $$$0 $$$0xedcba987
$$$0x80000001 $$$0 $$$0x7ffffffe
