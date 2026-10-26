# Assembly and ARG1 regression for the native EXC01 exec library.
.DATA 1
I commonDS.mc
L softstack.ld
L heapmgr.ld
L string.ld
L mul.ld
L div.ld
L diskos.ld
L exec.ld

::ArgOne "one\0"
::ArgTwo "two words\0"
::DemoName "DEMO.EXC\0"
::ArgVector ArgOne
::__        ArgTwo

.CODE 0
.ORG 0x7000
:Main
.ENTRY Main
@Call(AAA) ExecBuildArgBlock DemoName 2 ArgVector
@IF_ZERO
    @POPNULL
    @PRT "EXC ARG1 FAIL size=0 magic=" @PRTHEXI ExecArgWork @PRT " argc=" @PRTI ExecArgWork+6 @PRTNL
@ELSE
    @POPNULL
    @IF_NEQ_AV 0x5241 ExecArgWork
        @PRT "EXC ARG1 FAIL magic=" @PRTHEXI ExecArgWork @PRT " argc=" @PRTI ExecArgWork+6 @PRTNL
    @ELSE
        @IF_NEQ_AV 3 ExecArgWork+6
            @PRT "EXC ARG1 FAIL magic=" @PRTHEXI ExecArgWork @PRT " argc=" @PRTI ExecArgWork+6 @PRTNL
        @ELSE
            @PRTLN "EXC ARG1 PASS"
        @ENDIF
    @ENDIF
@ENDIF
@END
