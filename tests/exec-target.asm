# Target image for the native ExecCall regression.  The exit gateway is fixed
# in the loader's MS 255, so this program needs no preserved far-return pair.
.DATA 3
I commonDS.mc
I exec.mc

.CODE 2
.ORG 0x0100
:Main
.ENTRY Main
@ExecExit 0x2a
