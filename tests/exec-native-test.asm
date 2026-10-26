# End-to-end ExecCall regression.  Build this and exec-target.asm as EXC01,
# then import both images into tests/DISK00.disk as EXEC-NATIVE.EXC and
# EXEC-TARGET.EXC.  The reloaded launcher verifies the child's exit status.
.DATA 1
I commonDS.mc
L softstack.ld
L heapmgr.ld
L string.ld
L mul.ld
L div.ld
L diskos.ld
L exec.ld

::ExecHeap 0
::LauncherName "EXEC-NATIVE.EXC\0"
::ExecName "EXEC-TARGET.EXC\0"
::ExecArgOne "one\0"
::ExecArgTwo "two words\0"
::ExecArgs ExecArgOne
::__       ExecArgTwo

.CODE 0
.ORG 0x7000
:Main
.ENTRY Main
@PUSH 1 @ADM
@PUSH EXEC_ARG_BLOCK+8 @ESO @PUSHS @AND EXEC_ARG_RETURNED
@IF_NOTZERO
    @POPNULL
    @PUSH EXEC_ARG_BLOCK+14 @ESO @PUSHS
    @IF_NEQ_A 0x2a
        @POPNULL
        @PRTLN "NATIVE CALL STATUS FAIL"
        @END
    @ENDIF
    @POPNULL
    @PRTLN "NATIVE CALL PASS"
    @END
@ENDIF
@POPNULL
@PUSH 0xfff0 @PUSH 0xff00 @CALL SetSSStack
@Call(AA) HeapDefineMemory 0x9000 0x6000
@POPI ExecHeap
@Call(VA) HeapNewObject ExecHeap 0x1000
@DUP @ADD 0x1000 @SWP @CALL SetSSStack
@Call(V) SetDiskHeap ExecHeap
@Call(A) FSReadHeader 0
@IF_ZERO
    @POPNULL
    @PRTLN "NATIVE EXEC FS FAIL"
    @END
@ENDIF
@POPNULL
@Call(AAAA) ExecCall ExecName 2 ExecArgs LauncherName
@PRT "NATIVE CALL ERROR " @PRTTOP @PRTNL
@POPNULL
@END

=EXEC_ARG_BLOCK 0xfe00
=EXEC_ARG_RETURNED 1
