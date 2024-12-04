######################################
# SSFD  Stupid Simple File System
#
# Disk: A block of addressable storage, multiple disks might be on same hardware, think 'partitions'
# Sectors: 512 byte blocks of disk addressed by a 16 bit address (max 32MB)
# Start Sector: 512 byte, defines disk major variables
# Directory Table: fixed size table structure, 1 to 1 with number of Clusters that will fit on disk
# Clusters:
#
! SSFSDefined
M SSFSDefined
#
#
#######
# Global Variables
:MainHeapID 0
:OFTTable 0              # Open File Table
:OFTMaxSize -1           # Max num entries allowed in OFT
:OFTInUse 0              # Count of how many are in use.
:OFTActive 0             # Pointer to OFT entry that is active.
:ADTTable 0              # Active Disk Table
:ADTMaxSize -1           # Maxx num entries allowd in ADT
:ADTInUse 0              # Count of how many are in use.
:ADTActive 0             # Porinter to ADT entry that is active
#######
# Register table
:Var01 0 :Var02 0 :Var03 0:Var04 0 :Var05 0 :Var06 0
:Var07 0 :Var08 0 :Var09 0:Var10 0 :Var11 0 :Var12 0

########################
#      Set up Global entry points
G SSFSInitSystem
G SSFSInitDisk


####################
I ssfs-ds.asm

#############################################
# Function SSFSInitSystem(FileTableSize,DiskTableSize,HeapID)
# Initilizes the Disk system, creating empty tables
# Active Disk Tables (ADT) and File Tables (OFT)
:SSFSInitSystem
@PUSHRETURN
=Index1 Var01
@PUSHLOCALI Var01
#
POPI MainHeapID
POPI ADTMaxSize
POPI OFTMaxSize
#
# We want to create two tables on OFT and one ADT
#
@PUSHI MainHeapID
@PUSHI ADTMaxSize @PUSH ADTSizeItem @CALL MULU
@CALL HeapNewObject
@POPI ADTTable
#
@PUSH MainHeapID
@PUSHI OFTMaxSize @PUSH OFTSizeItem @CALL MULU
@CALL HeapNewObject
@POPI OFTTable
#
# While We allocated max sizes, we currently only have zero in use.
@ForIA2V Index1 0 ADTMaxSize
   # Zero out the first word of each entry to mark as available
   @PUSH 0
   @PUSHI ADTTable
   @PUSHI Index1 @PUSH ADTSizeItem @CALL MULU
   @POPS
@Next Index1

@ForIA2V Index1 0 OFTMaxSize
   # Zero out the first word of each entry to mark as available
   @PUSH 0
   @PUSHI OFTTable
   @PUSHI Index1 @PUSH OFTSizeItem @CALL MULU
   @POPS
@Next Index1

MA2V 0 OFTInUse
MA2V 0 ADTInUse
@POPLOCAL Var01
@POPRETURN
@RET
##############################################
# Function SSFSInitDisk(DiskID, StartSector):(0:Success, >0 Error)
# Creates and Entry in the DT Table to open a disk.
:SSFTInitDisk
@PUSHRETURN
=InDiskID Var01               # HareWare Disk ID
=UseADTEntry Var02            # Pointer to where this disk is stored in the ADT
=Index1 Var03                 # Common Index for loops
=StartSector Var04            # Passed in, sectore on disk where SS
=LocalBuffer Var05            # 512 byte buffer for Disk IO
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
#
@POPI StartSector
@POPI InDiskID
#
@PUSHI ADTInUse
@IF_GE_V ADTMaxSize
  @POPNULL
  @PRT "Error: Too Many Disks assigned."
  @PUSH 1      # Error Code
  @JMP InitDiskQuickExit
@ENDIF
@POPNULL
@IF_EQ_AV 0 ADTTable
  # ADTTable Not initilized?
  @PRT "Error, Active Disk Table Not initilied."
  @PUSH 1
  @JMP InitDiskQuickExit
@ENDIF
#
# Go though the ADT table and find one that is 'available'
@MA2V -1 ADTActive
@ForIA2V Index1 0 ADTMaxSize
   # Find an entry that zero in first work (avaiable)
   @PUSHI ADTTable
   @PUSHI Index1 @PUSH ADTSizeItem @CALL MULU
   @PUSHS
   @IF_ZERO
      @PUSHI Index1 @PUSH ADTSizeItem @CALL MULU   
      @POPI ADTActive                           # Pointer to head of entry in table
      @FORBREAK
   @ENDIF
@Next Index1
@IF_EQ_AV -1 ADTActive
   @PRT "Error: Too Many Disks in use."
   @PUSH 1
   @JMP InitDiskQuickExit
@ENDIF
#
# ADTActive[0]=1
@PUSH 1 @PUSHI ADTActive @ADD ADTofsState @POPS
#
# Create a 512 buffer IO buffer for this Disk
@PUSHI MainHeapID
@PUSH 512
@CALL HeapNewObject
@IF_LT_A 100
    @PRT "Error, Error allocating Disk IO Buffer"
   @JMP InitDiskQuickExit
@ENDIF
@POPI LocalBuffer   # Save for use in this function.
# ADT[Buffer]=LocalBuffer
@PUSHI LocalBuffer @PUSHI ADTActive @ADD ADTofsBuffer @POPS
#
# Now save HW Disk ID and Start Sector
@PUSHI InDiskID @PUSHI ADTActive @ADD ADTofsHWDiskID @POPS
@PUSHI StartSector @PUSHI ADTActive @ADD ADTofsStartSector @POPS
#
# The rest of the informaiton we'll need for the ADT table is found in the StartSector So read it.
@DISKSELI InDislID
@DISKSEEK StartSector
@DISKREADI LocalBuffer
#
SSDTofsFirstSect
SSDTofsSize dir table entry size
SSDTofsLength number of dir table entries.
#
@PUSHI LocalBuffer @ADD SSDTofsBootLabel @PUSHS
@PUSHI ADTActive @ADD ADTofsDiskID @POPS
@PUSHI LocalBuffer @ADD SSDTofsBootLabel @ADD 2 @PUSHS
@PUSHI ADTActive @ADD ADTofsDiskID @ADD 2 @POPS
#
# If Disk is a boot disk put the Boot Sector # in ADTofsIsBoot
@PUSHII LocalBuffer
@IF_EQ_A 1          # Is Boot Disk
   @POPNULL
   @PUSHI LocalBuffer @ADD SSofsBootSector @PUSHS
@ELSE
   @POPNULL
   @PUSH 0          # Otherwise use zero to indicate it is not a boot disk
@ENDIF
@PUSHI ADTActive @ADD ADTofsIsBoot @POPS
#
:InitDiskQuickExit
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

