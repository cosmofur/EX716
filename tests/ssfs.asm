######################################
# SSFD  Stupid Simple File System
#
# Disk: A block of addressable storage, multiple disks might be on same hardware, think 'partitions' or perhaps directories.
# but more limited than the way FAT or inode directories are defined.
# Sectors: 512 byte blocks of disk addressed by a 16 bit address (max 32MB)
# Start Sector: 512 byte, defines disk major variables
# Directory Table: fixed size table structure, 1 to 1 with number of Clusters that will fit on disk
#                  While each DT stores info about its starting sector, one could in theory calculate it
#                  just by knowing the index and the cluster size.
# Clusters: A Cluster is the smallest unit of disk space a file will consume, files also have a seperate 'file size' which
# is a 32 bit number allowing files to be anywhere between 0 and max-availabel space in size. In theory files may even cross
# disks, allowing larger than 32M files but only bare hooks are in place to impliment that. Keeping the 'Simple' in the SSFD
# 
#
# Utility functions:
#
# SSFSInitSystem(FT_SIZE,ADT_SIZE,HeapID)   : Core service initilization settingg up required tables.
# SSFSInitDisk(DiskID,StartSector)          : Opens a disk and assigns it to the ADT table.
# SSFSUnMountDisk(ActiveDisk):(0:OK >0 error) : Clears an attached disk slot for resuse.
#
#
# The Following functions still need to be writen:
# Core Functions
#  SSFSFormatDisk(DiskID, ClusterSize)
#            Formats a disk with the specified cluster size, initializing the SS and DT structures.
#  SSFSFstat(DiskID, FileName)
#            Creates a temporary FT entry for file if it exists, otherwise it returns -1
#  SSFSCreateFile(DiskID, FileName)
#            Creates a new file in the current directory table, allocating the necessary clusters.
#  SSFSDeleteFile(DiskID, FileName)
#            Deletes a file, freeing up the clusters and updating the directory table.
# File Operations
#  SSFSOpenFile(DiskID, FileName)
#            Opens a file and returns a file pointer (FP) for subsequent operations.
#  SSFSCloseFile(FP)
#            Closes an open file, updating the file table and freeing resources.
#  SSFSReadBlock(FP, Buffer)
#            Reads a 512-byte block from the file pointed to by FP into the provided buffer.
#  SSFSWriteBlock(FP, Buffer)
#            Writes a 512-byte block from the buffer to the file pointed to by FP.
#  SSFSReadLine(FP, Buffer)
#            Reads a line-feed terminated record from the file, handling block transitions.
#  SSFSWriteLine(FP, Buffer)
#            Writes a line-feed terminated record to the file, managing block and cluster transitions.
# Directory and File Management
#  SSFSListFiles(DiskID)
#            Lists all files in the current directory table.
#  SSFSChangeDirectory(DiskID, DirectoryName)
#            Changes the current directory to the specified sub-directory.
#  SSFSGetFileInfo(DiskID, FileName)
#            Retrieves information about a file, such as size and creation date.
# Utility Functions
#  SSFSSeek(FP, Position)
#            Moves the read/write pointer to the specified position within the file.
#  SSFSGetFreeSpace(DiskID)
#            Returns the amount of free space availabel on the disk.

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
########################
#      Set up Global entry points
G SSFSInitSystem
G SSFSInitDisk
G SSFSUnMountDisk
####################
I ssfsds.asm

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
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 105" @END @ENDIF
@POPI ADTTable
#
@PUSH MainHeapID
@PUSHI OFTMaxSize @PUSH OFTSizeItem @CALL MULU
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 109" @END @ENDIF
@POPI OFTTable
#
# While We allocated max sizes, we currently only have zero in use.
@ForIA2V Index1 0 ADTMaxSize
   # Zero out the first word of each entry to mark as availabel
   @PUSH 0
   @PUSHI ADTTable
   @PUSHI Index1 @PUSH ADTSizeItem @CALL MULU
   @POPS
@Next Index1

@ForIA2V Index1 0 OFTMaxSize
   # Zero out the first word of each entry to mark as availabel
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
# Function SSFSInitDisk(DiskID, StartSector):<100 == error, > 100 is ptr to ADT entry
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
# Go though the ADT table and find one that is 'availabel'
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
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 194" @END @ENDIF
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
# Now pass the ID of the ADTActive Ptr to the calling procedure, acts as Disk Ptr
@PUSHI ADTActive

#
:InitDiskQuickExit
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#################################################
# Function SSFSUnMountDisk(ActiveDisk):(0:OK >0 error return)
# When a disk is no longer active, removes it from the ADT table.
:SSFSUnMountDisk
@PUSHRETURN
=ActiveDisk Var01
=Index1 Var02
=ErrorCode Var03
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
#
@POPI ActiveDisk
@MA2V 0 ErrorCode
# First delete the old 512 buffer if its valid
@PUSH MainHeapID
@PUSHI ActiveDisk @ADD ADTofsBuffer @PUSHS
@IF_NOTZERO
   @CALL HeapDeleteObject
   @IF_LT_A 100
       @PRT "Error Deleteing old disk caches."
       @MA2V 1 ErrorCode
   @ELSE
       @POPNULL
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
# Now Zero out State so it availabel again.
@PUSH 0 @PUSHI ActiveDisk @ADD ADTofsState @POPS
@PUSHI ErrorCode
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###################################################
# Function SSFSFormatDisk(HWDiskID,StartSector,DirCount,ClusterSize, DiskLabel, VirtFlag)
# Formats a Disk setting asside disk space for Directories and 
:SSFSFormatisk
@PUSHRETURN
=HWDiskID Var01
=StartSector Var02
=DirCount Var03
=ClusterSize Var04      # In unit sectors so 128 for 64K or 8 for 4K
=DiskLabel Var05
=Buffer1 Var06
=Index1 Var07
=Limit1 Var08
=Cluster Var09
=Index2 Var10
=BaseDT Var11
=DirSector Var12
=VirtFlag Var13
=EndPoint Var14
#
@PUSHLOCLAI Var01
@PUSHLOCLAI Var02
@PUSHLOCLAI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
@PUSHLOCALI Var09
@PUSHLOCALI Var10
@PUSHLOCALI Var11
@PUSHLOCALI Var12
@PUSHLOCALI Var13
@PUSHLOCALI Var14
@
#
@POPI VirtFlag
@POPI ClusterSize
@POPI DirCount
@POPI StartSector
@POPI HWDiskID
#
# Create a Buffer to work with.
@PUSHI MainHeapID
@PUSH 512
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Heap error 326" @END @ENDIF
@IF_LT_A 100
    @PRT "Error, Error allocating Start Sector Buffer"
    @JMP FormatDiskQuickExit
@ENDIF
@POPI Buffer1

# Zero out the buffer 
@PUSHI Buffer1 @PUSH 512  @CALL ZeroBuffer
#
# By Default format will mark all disks as Data Disk (2) which can be later modified by
# tools that add boot sectors or other specialized features.
# Buffer[TypeCode]=2
@PUSH 2 @PUSHI Buffer1 @ADD SSofsTypeCode @POPS
#
# Before We start writing to StartSector data, we need to determins if this is a physical disk or a virtual one.
# For physical disks, mean the entire range from StartSector to (StartSector+DirCount*ClusterSize) is valid and
# will not be overloaded with anyother Disk usage.
# For Virtual disk, then there is a 'parent' disk which we will be requesting 1 or more clusters to be used.
# The number of parent clusters will be determined by (1+DirCount*CluserSize)/ParentClusterSize
# For virtaul disks, Sector will alwasy be zero.
@IF_EQ_AV -1 VirtFlag
   #Pysical Disk, not concerned about parent clusters.
@ELSE
   # Virtaul Disk, VirtFlag == the DiskTable entry for the parent disk.
   #
   # Call procedure the allocate 1st cluster and set StartSector to 0, set EndPoint to last sector in this cluster.
   # Should also put in a test if a single cluster is smaller than DirCount*32 because if we need multiple
   # clusters to store just the Dir info, we maybe in trouble. So if the cluster size of the parent disk is
   # < whats required to hold the full directory, reject it and error saying need to request fewer dir slots.
   @PRT "Not Yet implimented" 
@ENDIF
   
#
# For non specialized disks, first sector of the DIR table will always be SS+1
# Buffer[DTFirstSector]=SS+1
@PUSHI StartSector @ADD 1
@POPI DirSector
@PUSHI DirSector
@PUSHI Buffer1 @ADD SSDTofsFirstSect @POPS @
#
# While some time in the future we may need a diffrent DIR entry size right now fixed at 32
# Buffer[SSDTofsSize]=32
@PUSH 32 @PUSHI Buffer1 @ADD SSDTofsSize @POPS
#
# Max Entries in DIR table
# Buffer[SSDTofsLength]=DirCount
@PUSHI DirCount @PUSHI Buffer1 @ADD SSDTofsLength @POPS
#
# We'll leve BootSector at zero, a diffrent tool would add a boot block later, if needed.
#
# We'll use a TimeStamp as the DiskID in the theary that we'll not create two disks at the same second.
@GETTIME   # Puts 32 bit time on top two stack.
# Buffer[DiskID]=TOS, Buffer[DiskID+2]=SFT
@PUSHI Buffer1 @ADD SSofsDiskID @POPS
@PUSHI Buffer1 @ADD SSofsDiskID @ADD 2 @POPS
#
# Now put the label on.
# It will either be null terminated string, or max 512-SSofsBootLabel
@ForIA2B Index1 SSofsBootLabel 512
   # From offset Label to end of Sector, read each byte of passed in DiskLabel
   # If reach null, then end for loop, otherwise continue to end of sector.
   @PUSHII DiskLabel @AND 0xff
   @DUP
   # Buffer[Index]=DiskLabel[0] ; DiskLabel++
   @PUSHI Biffer1 @ADDI Index1 @POPS
   @INCI DiskLabel
   @IF_ZERO
      @POPNULL
      @FORBREAK
   @ELSE
      @POPNULL
   @ENDIF
@Next Index1
#
# SS sector is now ready to write to the Start Sector of the Disk
@DISKSELI HWDiskID
@DISKSEEKI StartSector
@DISKWRITEI Buffer1
#
# Now we have a loop to write all the 'empty' Directory entries.
# There are 16 Dir in each Sector So DIV DirCount by 16 to get number of sectors we'll be writing.
# Limit1=DirCount >> 4 (Add 1 to allow loops to terminate after last iteration)
@PUSHI DirCount @SHR @SHR @SHR @SHR @ADD 1 @POPI Limit1
#
# The fields in the Directory table we need to set are
# State=0 For unused.
# FirstSector to Cluster for this DIR
# NextSector=-1   As until a file grows large, it will start as one cluster.
#
# clusters start = StartSector+Limit1
# If Virtual Disk, then if Cluster > EndPoint, request a new cluster from parent disk.
@PUSHI StartSector @ADDI Limit1 @POPI Cluster
@IF_EQ_AV -1 VirtFlag
  # Is physical, no need to modify Cluster
@ELSE
  @IF_EQ_VV Cluster EndPoint
     # Request New Cluster from Parent
  @ENDIF
@ENDIF
@ForIA2V Index1 0 Limit1
     # With in each DT Sector there are 16 DT's so loop to fill all entries.
     @ForIA2B Index2 0 16
             # Get the base offset of each DT entry in sector.
         @PUSH DTSizeItem @CALL MULU  @POPI BaseDT
             # Buffer[BaseDT+ofsState]=0
         @PUSH 0       # Mark State as 0
         @PUSHI Buffer1  @ADDI BaseDT @ADD DTofsState @POPS
             # Buffer[BaseDT+ofsFirstSect] = Cluster
         @PUSHI Cluster
         @PUSHI Buffer1  @ADDI BaseDT @ADD DTofsFirstSect @POPS
             # Now move Cluster up by ClusterSize for next loop
         @PUSHI Cluster @ADDI ClusterSize @POPI Cluster
         @IF_EQ_AV -1 VirtFlag
            # Is physical, no need to modify Cluster
         @ELSE
            @IF_EQ_VV Cluster EndPoint
                # Request New Cluster from Parent
            @ENDIF
         @ENDIF         
             # Last access is also same until it used and changed.
         @PUSHI Cluster
         @PUSHI Buffer1  @ADDI BaseDT @ADD DTofsLastAccessed @POPS
             # Buffer[BaseDT+ofsNextSector] = -1 to mark there no next cluster yet.
         @PUSH -1
         @PUSHI Buffer1  @ADDI BaseDT @ADD DTofsNextSector @POPS
             # Set default file size to zero
         @PUSH 0
         @PUSHI Buffer1  @ADDI BaseDT @ADD DTofsLongSize @POPS
         @PUSH 0
         @PUSHI Buffer1  @ADDI BaseDT @ADD DTofsLongSize @ADD 2 @POPS
     @Next Index2
     # Set set DirSector back when writing the SS now use it.
     @DISKSEEKI DirSector
     @DISKWRITEI Buffer1
     @INCI DirSector
 @Next Index1
#
# Clean up.
@PUSHI MainHeapID
@PUSI Buffer1
@CALL HeapDeleteObject
@IF_LT_A 100
   @PRT "Error Deleteing old disk DT Cache"
@ENDIF
:FormatDiskQuickExit
@POPLOCAL Var12
@POPLOCAL Var11
@POPLOCAL Var10
@POPLOCAL Var09
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
######################################################
# Function SSFSFstat(ADiskID, FileName)
# Queries the current ADiskID and returns a pointer to FT
# But only if the File exists, otherwise it returns -1
:SSFSFstat
@PUSHRETURN
=InADiskID Var01
=InFileName Var02
=ADTEntryPtr Var04
=DTMatch Var05
=DTWorkingSector Var06
=DTIndex1 Var07
=DRInsideIdx Var08
=ADTCurHWDisk Var09
=ADTBuffer Var10
=DTMaxSec Var11
#
@POPI InFileName
@POPI ADiskID
#
@PUSHI ADiskID
@CALL ReadADTIndex
@POPI ADTEntryPtr     #Heap Object remember to delete it later.
#
# We do not keep all the DT entries in memory, so well need a way to loop though
# the disk DT entries, dealing with when we need to fetch additional Sectors.
@MA2V -1 DTMatch          # -1 in end means nothing matched.
@MA2V 0 DTIndex
#
# Get from the ATD values we need to search the right Directory Table.
#
# DTWoorking to DTMaxSec is the range of sectors the DT consumes.
@PUSHI ADTEntryPtr @ADD ADTofsDTstart @PUSHS
@POPI @DTWorkingSector
@PUSHI ADTEntryPtr @ADD ADTofsDTstop @PUSHS
@POPI DTMaxSec
#
# Get the Current HW Disk ID, get the acutual HW ID not the ADT index.
@PUSHI ADTEntryPtr @ADD ADTofsHWDiskID @PUSHS
@POPI ADTCurHWDisk
#
# Get the Disk's reserved Buffer
@PUSHI ADTEntryPtr @ADD ADTofsBuffer @PUSHS
@POPI ADTBuffer
#
#
# Loop though the DT looking for FileName Matches. While DTIndex1 < Max
# Read in new sector when finsh current one.
@MA2V 0 DRInsideIdx
@PUSHI DRWorkingSector @PUSHI DRMaxSec
@IF_LE_S
   @POPNULL @POPNULL
   @PUSH 1
@ELSE
   @POPNULL @POPNULL
   @PUSH 0
@ENDIF
@WHILE_NOTZERO
   # Read in current DT Table Sector.
   @DISKSELI ADTCurHWDisk
   @DISKSEEKI DTWorkingSector
   @DISKREADI ADTBuffer
   # Loop though the Directory Entries in the current sector looking for Filename match.
   @ForIA2V DRInsideIdx 0 16   # 32 bytes per DT 512 bytes per sector.
      # First test if the DT entry is in use.
      @DRInsideIdx @SHL @SHL @SHL @SHL @SHL   # *32
      @ADDI ADTBuffer
      @PUSHS @AND 1         # We only care about bit 0,
      @IF_NOTZERO
         @POPNULL
         # DT is in use, so check filenames.
         @PUSHI ADTBuffer @ADD DTofsFileName
         @DUP
         @CALL strlen           # Get the length of the DT filename.
         @PUSHI InFileName
         @CALL strlen
         @IF_EQ_S               # We'll only both strcmp if both or same length
            @POPNULL @POPNULL
            @PUSHI InFileName
            @CALL strcmp
            @IF_ZERO            # Same Filename
                 # Found that there is a filename that matches, now check to see if it is already open in FT
                 
         
    



  
  

##############################################
# Function ReadADTIndex(ADTIndex, Index1):Buffer
# Given an Index in the DT will return a buffer pointing at the ADT data.
# If the Index is invalid the Buffer will be empty and all zeros
:ReadDTIndex
@PUSHRETURN
=InADTIndex Var01
=InIndex1 Var02
=OutBuffer Var03
=ADTPtr Var04
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
#
@POPI InIndex1
@POPI InDiskID
#
# Create a Heap Object to hold the ADT
@PUSHI MainHeapID
@PUSH ADTSizeItem
@CALL HeapNewObect @IF_ULT_A 100 @PRT "Heap error 599" @END @ENDIF
@IF_LT_A 100
   @PRT "Error Could not allocate Space for temporary buffer"
   @END
@ENDIF
@POPI OutBuffer
# 
# Get a pointer to the ADT Table entry for Index1
@PUSHI InIndex1 @PUSH ADTSizeItem @CALL MULU @ADDI ADTTable
@POPI ADTPtr
#
PUSHI OutBuffer
@PUSHI ADTPtr
@PUSH ADTSizeItem
@CALL memcpy
#
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET






##############################################
# Function ZeroBuffer(BuffID,Size)
# Zero Out the Buffer to avoid old data.
:ZeroBuffer
@PUSHRETURN
=Buffer1 Var01
=BSize Var02
=Index1 Var03
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@SHR @SHL @POPI BSize   # Round to nearest even size
@POPI Buffer1
@ForIA2B Index1 0 512
   # Buffer1[Index]=0
   @PUSH 0
   @PUSHI Index1
   @PUSHI Buffer1 @ADDS
   @POPS
@NextBy Index1 2
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET






######################################################
# Function SSFSCreateFile(DiskID, FileName)
# Creates a TF entry, even if it didn't yet exist.
:SSFSCreateFile

