I common.mc
L mul.ld

# Do a tight loop for time tests

@PRTLN "Start"
@ForIA2B II 0 100
   @ForIA2B JJ 0 250
# Put the test OPT Code here
#
@NOP
@Next JJ
@Next II
@PRTLN "End"
@END
:II 0
:JJ 0
