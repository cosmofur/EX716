I common.mc
@JMP Start
# Data Segment
:Val32one
$$$0x01020304
:Val16one
$0x0FF0
:Val8one
$$0xF0
b0
:R1
0
:Start
@PRT "Values: (v16)"
@MC2M Val16one R1
@PRTHEXII R1
@PRTSP
@MC2M Val8one R1
@PRT " (v8)"
@PRTHEXII R1
@PRTSP
@MC2M Val32one R1
@INCI R1
@INCI R1
@PRT " (v32)"
@PRTHEXII R1
@DECI R1
@DECI R1
@PRTHEXII R1
@PRTNL
@END

