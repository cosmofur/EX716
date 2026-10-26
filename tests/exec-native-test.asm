# End-to-end destructive ExecFile regression. Run with a DISK00.disk containing
# EXEC-TARGET.EXC and with DiskOS initialized on heap storage.
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
::ExecName "EXEC-TARGET.EXC\0"
::ExecArgOne "one\0"
::ExecArgTwo "two words\0"
::ExecArgs ExecArgOne ExecArgTwo

.CODE 0
.ORG 0x7000
:Main
.ENTRY Main
@PUSH 1 @ADM
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
@Call(AAA) ExecFile ExecName 2 ExecArgs
@PRT "NATIVE EXEC ERROR " @PRTTOP @PRTNL
@POPNULL
@END
