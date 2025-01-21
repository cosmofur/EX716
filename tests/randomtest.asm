I common.mc
L softstack.ld
L random.ld
# This test is to see how 'random' the random number generator is.
:Main . Main

@PRTLN "Random Tests:"
@CALL FreshSeed
@PRT "Seed: " @PRTTOP @PRTNL
@CALL rndsetseed

=NumberBuckets 10
=NumberOfTests 1000
@ForIA2B Index1 0 NumberBuckets
    @PUSHI Index1
    @PUSH 0
    @CALL SetToBucket
#    @CALL frnd16        # Call rnd16 a few times to prime the pump.
    @CALL xorshift16
    @POPNULL
@Next Index1

@ForIA2B Index1 0 NumberOfTests
   @PUSH 100
   @CALL frndint
   @PUSHI Index1
   @POPNULL
   @MA2V NumberBuckets BucketLimit
   @MA2V 0 Index2
   @WHILE_GT_V BucketLimit
       @PUSHI BucketLimit @ADD NumberBuckets @POPI BucketLimit
       @INCI Index2
   @ENDWHILE
   @POPNULL
   @PUSHI Index2
   @PUSH 1
   @CALL AddtoBucket
@Next Index1
@ForIA2B Index1 0 NumberBuckets
   @PUSHI Index1
   @CALL GetBucket
   @PRTI Index1 @PRT ":" @PRTTOP @PRTNL
   @POPNULL
   @PRTNL
@Next Index1

@END




# Function Get Random seed
:FreshSeed
@PUSHRETURN
@PRT "Hit key when ready."
@TTYNOECHO
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @READCNW UserKey
   @INCI SeedCount
   @PUSHI UserKey
@ENDWHILE
@TTYECHO
@PUSHI SeedCount @ADDI UserKey @AND 0x7ffe
@POPRETURN
@RET
:UserKey 0 0
:SeedCount 0

# Function AddtoBucket(Bucket, value)
#  Add a new value to existing bucket
:AddtoBucket
@PUSHRETURN
@POPI NewValue
@SHL
@ADD BucketTable
@DUP
@PUSHS
@ADDI NewValue
@SWP
@POPS
@POPRETURN
@RET
:NewValue 0
#
# Function SetToBucket(Bucket, value)
#   replace old value to newone in Bucket.
:SetToBucket
@PUSHRETURN
@SWP
@SHL
@ADD BucketTable
@POPS
@POPRETURN
@RET
#
# Function GetBucket(Bucket)
:GetBucket
@PUSHRETURN
@SHL
@ADD BucketTable
@PUSHS
@POPRETURN
@RET
#
#
:Index1 0
:Index2 0
:BucketLimit 0
:BucketTable
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
