I common.mc
I alloc.mc

@PRTLN "Request 100b of storage"
@MAllocA 100
@POPI Start1
@PRT "Store starts at "
@PRTI Start1
@PRTNL
@PRTLN "Request 500b of storage"
@MAllocA 500
@POPI Start2
@PRT "Store starts at "
@PRTI Start2
@PRTNL
@END
:Start1 0
:Start2 0


