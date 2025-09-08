! SSFS_SEEN
M SSFS_SEEN 1
I common.mc
L string.ld
L mul.ld
L heapmgr.ld

:MainHeapID 0
:DiskTable 0
:ActiveDisks 0
:CurrentDisk -1
:FileHandleTable 0
:FHTActive 0
=FHTMaxOpen 10                    # The max number of files open at once.
=SectorSize 512

#
# DiskTable Structure
=DTofsDiskID 0                   # Offset DiskID
=DTofs1stDE DTofsDiskID+2        # Offset first DE sector #
=DTofsNumDE DTofs1stDE+2         # Offset Number DE entries
=DTofs1stDC DTofsNumDE+2         # Offset first DC sector
=DTofsSizeDC DTofss1stDC+2       # Offset In sectors size of DC on disk.
=DTofsStatus DTofsSizeDC+2       # Status word for disk.
=DiskTableItemSize DTofsStatus+2 # size of DiskTable entry

# The SSFS is a real dumb FS for quick and dirty testing, it will be replaced with a typical FAT16 later.
#
# Unlike FAT or newer File systems, there not FAT table or inode table or really any table defining the disk layout.
# Rather there are three objects
# Start Sector(SS): Defines the 'geomatry' of the current disk as well as all the constants related to it.
# Directory Entries (DE): There is a one to one relationship of DE's to total disk space.
#                         The more DE's the smaller the min size of Clusters can be.
#                         DE's keep track is its matching Cluster is in use, and what is physical size vs used sizes are.
#                         DE's can be chained to create larger files.
# Data Cluster (DC): has no meta data, and is just a mapping of a range of disk sectors storing data. DC's sizes are fixed,
#                    but the matching DE will have a 'used size' field that can allow a range of sizes.
#
# Start Sector(SS) Structure
# Bytes
=SSofsStateCode 0              # 0-1       State Code: (0: Unformated,
                               #   1: 'Physical' disk, 2: Sub-Directory, 3: Read Only, 4: Other)
=SSofs1stDE SSofsStateCode+2   # 2-3       First DE sector
=SSofsNumDE SSofs1stDE+2       # 4-5       Number of DE's on Disk
=SSofs1stDC SSofsNumDE+2       # 6-7       Sector of first DC
=SSofsSizeDC SSofs1stDC+2      # 8-9       Size in Sectors of this disks's DC
=SSofsVers   SSofsSizeDC+2     # A-B       Version Number
=SSofsBootID SSofsVers+2       # C-D       Boot Code: (0: Data only, 1: Boot block on disk) follow codes only read if '1'
=SSofsBootBlock SSofsBootID+2  # E-F       ID of DE for boot block
=SSofsBootLoad SSofsBootBlock+2 # 10-11     Address to load
=SSofsBootSize SSofsBootLoad+2 # 12-13     Number of blocks to read as boot block data
=SSofsBootRun SSofsBootSize    # 14-15     Address to Run when boot block is loaded.
=SSofsDiskName SSofsBootRun+2  # -ff       Free Form string/Disk ID/Name
# 
#
# Open Files are tracked with a numeric File Handle
# The filehandle pointer to a table which keeps track of individual file info.
=FTofsState 0                  # State Code: (0:Close/free,1:OpenRW,2:OpenRO,3:OpenRnd)
=FTofsType FTofsState+2        # File Type (0: Binary, 1: Text, 2: Directory, 3: Link, 4: Script, 5-N Exec#)
=FTofsSize FTofsSType+2        # 4 Byte Size
=FTofs1stSector FTofsSize+4    # Sector where File starts
=FTofsCurSect FTofs1stSector+2 # Current Sector of lastest Read/Write 0 means none yet accessed
=FTofsInSect FTofsCurSect+2    # Offset within the latest sector for partial read/writes.
=FTItemSize FTofsInSect+2     # Size of a record of the Filehandle table.

#
#
# DS has a lot of the same fields at FT because this is where it is copied from.
# Directory Structure.
=DSofsState 0                     # State Code (0:unused, 1: inuse, 2: Protected)
=DSofsType DSofsState+2           # Type (0:Binary, 1:Text, 2:Directory, 3: Link 4: Script, 5-N Exec#)
=DSofsSize DSofsType+2            # 4 Byte Size
=DSofs1stSector DSofsSize+4       # Sector where File starts
=DSofsCurSect DSofs1stSector+2    # Current Sector where latest Read/Write, 0 means none yet accessed
=DSofsInSect DSofsCurSect+2       # Offset within the latest sector for partial read/writes
=DSofsFName DSofsInSect+2         # Start of filename 16-31
=DSItemSize 32                    # We use fixed 32 as its easy to multiply/divide by 32 with 5 RTLs/RTRs



# Open File Table structure (OFTS):
# First Directory Entry # :
# Current Directory Entry #: 
# Size of File: 4bytes (# FileBlocks, # bytes used in last block)
# Last Sector: int
# Last Offset: int
#
###############################################
# Function InitDisk(disknumber, Sector, HeapID)
# Reads boot sector to get disk gemoetry and base info.
:InitDisk
@PUSHRETURN
=indisknumber Var01
=inSector Var02
=inHeapID Var03
=InBuffer1 Var04
=Index01 Var05
=Temp1 Var06
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@POPI inHeapID
@POPI inSector
@POPI indisknumber
#
# First use of InitDisk should be passed a Heap Object.
# Additional calls to InitDisk should use that same Heap Object
# or 'zero' as shortcut for existing heap object.
@IF_EQ_AV 0 MainHeapID
   # No Heap yet declaired. Make sure what was passed wasn't also zero.
   @MV2V inHeapID MainHeapID
   @IF_EQ_AV 0 MainHeapID
      @PRTLN "Disk Open error, no valid heap storage created."
      @END
   @ENDIF
@ELSE
   # A previous call passed a Heap object, make sure additional calls
   # use that same object, or zero as a shortcut for it.
   @IF_EQ_VV inHeapID MainHeapID
      # It's find to reused the existing mainheapid
   @ELSE
      @IF_EQ_AV 0 inHeapID
         # we allow 0 for inHeapID to mean use existing already defined heap.
      @ELSE
         # Not good, can now switch heaps until all disks are closed.
         @PRTLN "Error in Disk Initilization, miss match in heap storage."
         @END
      @ENDIF
   @ENDIF
@ENDIF
#
# We might have more than one disk open, so search the disk table to see if this disk has already been used.
@IF_EQ_AV 0 DiskTable
   # Disk table not yet defined, create it.
   @PUSHI MainHeapID
   @PUSHI DiskTableItemSize
   @CALL HeapNewObject
   @POPI DiskTable
   @MA2V 1 ActiveDisks
   @PUSHI DistTable @ADD indisknumber
   @PUSHI indisknumer @ADD 1  # To avoid a storing a disk number of zero
   
@ENDIF

@MV2V ActiveDisks Index01
@MA2V -1 Temp1            # if unchanged then -1 means no match found
@WHILE_NEQ_AV 0 Index01   # Count backwords to zero
   @PUSHI DiskTable
   @PUSHI Index01 @PUSH DiskTabItemSize @CALL MULU
   @ADD DRofsDiskID @PUSHS @SUB 1       # we don't store zero for disk # but need to cmp to zero
   @IF_EQ_V indisknumber
       # Found match break while with 1 on stack
       @POPNULL
       @MV2V Index01 Temp1    # Save result
       @MA2V 0 Index01
   @ELSE
       @POPNULL
       @DECI Index01
   @ENDIF
@ENDWHILE
#
@IF_EQ_AV -1 Temp1
   # First time seen this disk. Expand DiskTable by one
   # Call HeapResizeObject(heapid,object, newsize)
   @PUSHI MainHeapID           # HeapID
   @PUSHI DiskTable            # ObjectID
   @INCI ActiveDisk
   @PUSHI ActiveDisk @PUSH DiskTableItemSize
   @CALL MULU                  # New size
   @CALL HeapResizeObject
   @IF_LT_A 100
       @PRT "Error Allocating memory for Disk Table."
       @END
   @ENDIF
   @POPI DiskTable             # Re-assigne the DiskTable to the new object.
   @MV2V ActiveDisk Temp1
@ENDIF
# Temp1 should be pointing at the index of the space for this disk in DiskTable
#
# Turn it into the CurrentDisk Ptr
@PUSHI Temp1 @PUSH DiskTableItemSize @CALL MULU
@ADDI DiskTable
@POPI CurrentDisk
#
# Now read the current disks Start sector to fill in the disk info data.
@DISKSELI indisknumber
#
# Read in start sector of disk.
@PUSHI MainHeapID
@PUSH SectorSize
@CALL HeapNewObject
@POPI InBuffer1
#
@DISKSEEKI inSector
@DISKREADI InBuffer1
#
# InBuffer1 has the Disk info, copy that into DiskTable based on CurrentDisk
#         Src Value                              Copy To
@PUSHI indisknumber @ADD 1                       @PUSHI CurrentDisk @ADD DTofsDiskID @POPS
@PUSHI InBuffer1 @ADD SSofs1stDE    @PUSHS       @PUSHI CurrentDisk @ADD DTofs1stDE  @POPS
@PUSHI InBuffer1 @ADD SSofsNumDE    @PUSHS       @PUSHI CurrentDisk @ADD DTofsNumDE  @POPS
@PUSHI InBuffer1 @ADD SSofs1stDC    @PUSHS       @PUSHI CurrentDisk @ADD DTofs1stDC  @POPS
@PUSHI InBuffer1 @ADD SSofsSizeDC   @PUSHS       @PUSHI CurrentDisk @ADD DTofsSizeDC @POPS
@PUSHI InBuffer1 @ADD SSofsStatusDC @PUSHS       @PUSHI CurrentDisk @ADD DTofsStatus @POPS
# Initilizatoin of DiskTable is complete, clean up heap.
@PUSHI MainHeapID @PUSHI InBuffer @CALL HeapDeleteObject
#
# Create and zero out a basic FileHandle Table if not yet defined.
@IF_EQ_AV 0 FileHandleTable
    # No filetable yet, create it.
    @PUSHI MainHeapID
    @PUSH FTItemSize    
    @PUSHI FHTMaxOpen
    @CALL MULU
    @CALL HeapNewObject
    @POPI FileHandleTable
    @ForIA2B Index1 0 FHTMaxOpen
       @PUSH 0                  # Zero Value for first word in record
       @PUSHI Index1 @PUSH FTItemSize @CALL MULU
       @ADDI FileHandleTable    # Address of word
       @POPS
    @Next Index1
@ENDIF       
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

###############################################
# Function FindFileName("Filename", StartSector)
# Searches Directory for Filename, return -1 if none found or index in Dir table
:FindFileName
@PUSHRETURN
=Index1 Var01
=CurSect Var02
=StartSect Var03
=inFileName Var04
=CurBuffer1 Var05
=InSecOffset Var06
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@POPI StartSect
@POPI inFileName
#
# Default is an error exit
@PUSH -1   # Error Exit
#
@IF_EQ_AV -1 CurrentDisk
   @PRT "No Disk has been selected or initilized."
@ELSE
   @DISKSELI CurrentDisk
   @DISKSEEKI StartSect
   @PUSHI MainHeapID
   @PUSH SectorSize
   @CALL HeapNewObject
   @IF_LT_A 100
      @PRTLN "Error failed to allocate space for disk buffer."
      @PUSH -1  # Error Exit
   @ELSE
      @POPI CurBuffer1
      @DISKREADI CurBuffer1
      @MA2V 0 Index1
      @MA2V 0 InSecOffset
      @MV2V StartSect CurSect
      @PUSH 0
      @WHILE_ZERO
         @POPNULL
         @IF_EQ_AV 
         
   



   



