# IF_UGE_S unsigned-boundary regression using CPU24's structureDS macros.
.DATA 1
I commonDS.mc

.ORG 0x2000
:Main
@PUSH 1
@SSET SegDS
@PUSH 1
@ADM

@PUSH 0x8000 @PUSH 1
@IF_UGE_S
  @PRT "PASS IF_UGE_S unsigned high A" @PRTNL
@ELSE
  @PRT "FAIL IF_UGE_S unsigned high A" @PRTNL
@ENDIF
@POPNULL @POPNULL

@PUSH 1 @PUSH 0x8000
@IF_UGE_S
  @PRT "FAIL IF_UGE_S unsigned high B" @PRTNL
@ELSE
  @PRT "PASS IF_UGE_S unsigned high B" @PRTNL
@ENDIF
@POPNULL @POPNULL

@PUSH 0x8000 @PUSH 0x8000
@IF_UGE_S
  @PRT "PASS IF_UGE_S equal high A" @PRTNL
@ELSE
  @PRT "FAIL IF_UGE_S equal high A" @PRTNL
@ENDIF
@POPNULL @POPNULL

@PUSH 0
@ADM
@END
