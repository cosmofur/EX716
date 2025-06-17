! Fat16Mod
M Fat16Mod 1
I common.mc
I fat16suport.asm
L string.ld
L heapmgr.ld
L softstack.ld
L lmath.ld
##############################################################
# Global Exports
# Group 1, main services for end users.
G initdisksys          # (heapid)   initilized memory used.
G FileOpen             # (FileName, ModeCode):FP ModeCode={"r\0" "rw" "w\0" "a\0"}
G Fseek                # (FP,Index32Ptr) Seeks within file, Note Index is ptr to 32 bit number.
G ReadBuffer           # (FP, Size, Buffer) Read into Buffer 'upto' Size bytes.
G ReadLine             # (FP, Buffer) Reads into Buffer line until terminating character (newline)
G DeleteFile           # (FP) Deletes file (TBD)
#
# Group 2, Lower level calls for utility.
G readBootRecord
G ParsePath
G FPrintFPInfo
G Sector2Cluster
G Cluster2Sector
G F32to16
G ReadSector
##############################################################


###############################################################
# Key Varaibale used by current active Disk.
:MainHeapID 0
:activeDisk -1         # This is set -1 because there a real chance first disk used might be '0'
:bytesPerSector 0
:sectorsPerCluster 0
:reservedSectors 0
:numberofFATs 0
:rootDirEntries 0
:totalSectors16 0
:FATSize16 0
:rootDirStartSector 0
:totalClusters 0
:rootDirSize 0
:rootDirSizeInSectors 0
:FATSizeInSectors 0
:dataAreaStartSector 0
:totalDataSectors 0
:clusterSize 0
:FATSizeInBytes 0
:ClusterMask 0
:LastAllocatedCluster 2
:RecordMark "\n\0"        # Default is newline could be possibly changed.
########################################################
#                    Index
#
# initdisksys(HeapID):void            sets up memory for disk requirments
# readBootRecord(HWDiskID):void    Reads Disks boot record setup variables
# ParsePath(filename,DiskID):codes takes in string Filename, returns FP or DIR info
# findEntryInDirectory(sector,Filename,DiskID):[0|(HeapCopyDir,Sector,Offset)
#                                  Searchs for String Filename in single Director.
# compareFileNames(FileZ,FileSP):[0|1]
#                                  Cmp null termed filename with Space padded version.
# str2filename(FileName):FileSP    Turns FileZ to FileSP aces, heap object returned.
# SplitPath(filepath):(array,numentries)
#                                  Turns filepath into heap array or parts of path.
# HexDump(addres,length)           Utility to hex dump block of memory. (plan to move to another library)
# FPrintFPInfo(FP)                 Utility to print a formated output from FP
# GetNextPossableSector(Sector):NextSector
#                                  Figures out what next sector is, considered FAT tables as needed.
# Sector2Cluster(sector):cluster   Returns the Cluster number for a given sector
# Cluster2Sector(cluster):sector   Returns the first sector in the named Cluster
# F32to16(In32Ptr):(sectorcount,Offset)
#                                  Avoids use of Lmath library to convert 32bit filesize into sectorcount,offset
# ReadSectorWorker(FP,LogicalSector):HWSector
#                                  Converts a logical sector into actual hardware sector number
# ReadSector(FP,Index,Buffer):int  Reads sector logicla offset Index, into predefined buffer. int < 512 means EOF
# NextClusterFromCluster(ClusterIn): Reads the FAT table for ClusterIn and returns 1st sector of Next Cluster. (or 0xfffx)
# FSeek(FP,IndexPtr):[0|1]         Searches for location within file. IndexPtr is ptr to 32 bit value.
# Read_worker2(Type,FP,Size,Buffer):[0|bytesread]
#                                  Type=1 means read Size bytes into exiting Buffer
#                                  Type=2 means reaed until NewLine (or RecordMark) into Buffer
# Readbuffer(FP,Size,Buffer):      Read Buffer of Size
# ReadLine(FP,Buffer)              Read one Line to Buffer




M CheckRequire \
  @IF_EQ_AV 0 MainHeapID \
     @PRT "Error: Heap Not defined. Run initdisksys first\n" \
     @END \
  @ENDIF


################## Fat 16 core functions
################################################################
# Function initdisksys(HeapID)
# Setups system for handeling memory requirements for FS
:initdisksys
@SWP
@POPI MainHeapID
# Zero the key varaibles so no left over from previous set.
@MA2V -1 activeDisk
@MA2V 0 bytesPerSector
@MA2V 0 sectorsPerCluster
@MA2V 0 reservedSectors
@MA2V 0 numberofFATs
@MA2V 0 rootDirEntries
@MA2V 0 totalSectors16
@MA2V 0 FATSize16                # Number of Sectors in single Fat table.
@MA2V 0 rootDirStartSector
@MA2V 0 totalClusters
@MA2V 0 FATSizeInSectors         # Size All the  FAT tables in number of Sectors.

@MA2V 0 totalDataSectors
@MA2V 0 clusterSize
@MA2V 0 FATSizeInBytes
@MA2V 2 LastAllocatedCluster     # We keep track of last place we inserted a FAT entry to reduce frags

@RET



################################################################
# Function readBootRecord(diskID)
# This will set the 'global' constants  for the current Disk.
# If multiple files on diffrent disks are open, then when ever
# the alternative disk is refrenced, another readBootRecord will be needed.
:readBootRecord
@PUSHRETURN
@LocalVar InDiskID 01
@LocalVar InBuffer 02
#
# Structures we are reading/generating from boot record:
#
#  bytesPerSector   |  sectoresPerCluster       |  reservedSectors     |
#  numberofFATs     |  rootDirEntries           |  totalSectors16      |
#  FATSize16        |                           |  totalClusters       |
#  rootDirSize      |  rootDirSizeInSectors     |  dataAreaStartSector |
#  FATSizeInSectors |  rootDirStartSector       |  totalDataSectors    |
#  clusterSize      |  FATSizeInBytes
#

@POPI InDiskID
#
@CheckRequire
#
@IF_EQ_VV InDiskID activeDisk
   # No Need to reload if its already the active disk
@ELSE
   @PUSHI MainHeapID
   @PUSH 512
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 87" @POPNULL @END @ENDIF
   @POPI InBuffer
   #
   @DISKSELI InDiskID
   @DISKSEEK 0
   @DISKREADI InBuffer
   #
   # Set the required globals from that buffer data.
   @PUSHI InBuffer @ADD BRofsbytesPerSector @PUSHS @POPI bytesPerSector
   @PUSHI InBuffer @ADD BRofssectorsPerCluster @PUSHS @AND 0xff @POPI sectorsPerCluster
   @PUSHI InBuffer @ADD BRofsreservedSectors @PUSHS @POPI reservedSectors
   @PUSHI InBuffer @ADD BRofsnumberOfFATs @PUSHS @AND 0xff @POPI numberofFATs
   @PUSHI InBuffer @ADD BRofsrootDirEntries @PUSHS @POPI rootDirEntries
   @PUSHI InBuffer @ADD BRofstotalSectors16 @PUSHS @POPI totalSectors16
   @PUSHI InBuffer @ADD BRofsFATSize16 @PUSHS @POPI FATSize16
   #
   # Calculated fields
   
   # totalClusters=(totalSectors - reservedSectors - FATSizeInSectors)/sectorsPerCluster
   @PUSHI totalSectors16 @SUBI reservedSectors @SUBI FATSizeInSectors
   @PUSHI sectorsPerCluster @CALL DIVU 
   @POPI totalClusters @POPNULL

   # rootDirSize=(rootDirEntries * 32)/bytesPerSector
   @PUSHI rootDirEntries @SHL @SHL @SHL @SHL @SHL  # X 32
   @POPI rootDirSize
   @PUSHI rootDirSize
   @PUSHI bytesPerSector @CALL DIVU @POPI rootDirSizeInSectors @POPNULL

   # dataAreaStartSector = reservedSectors+(numberofFATs*FATSize16)+rootDirSizeJ Sectors
   
   @IF_EQ_AV 2 numberofFATs
       # Most of the time, it will be '2' so just use ADD twice
       @PUSHI reservedSectors @ADDI FATSize16 @ADDI FATSize16 @ADDI rootDirSizeInSectors
   @ELSE
       # In rare case it something else, use MUL
       @PUSHI reservedSectors @ADDI FATSize16 @PUSH 2 @CALL MULU  @ADDI rootDirSizeInSectors
   @ENDIF
   @POPI dataAreaStartSector

   # FATSizeInSectors
   @PUSHI numberofFATs @PUSHI FATSize16 @CALL MULU @POPI FATSizeInSectors

   # rootDirStartSector
   
   @PUSHI FATSizeInSectors  @ADDI reservedSectors 
   @POPI rootDirStartSector



   # totalDataSectors = totalSectors16 - reservedSectors - FATSizeInSectors - rootDirSizeInSectors
   @PUSHI totalSectors16 @SUBI reservedSectors @SUBI FATSizeInSectors @SUBI rootDirSizeInSectors
   @POPI totalDataSectors

   # clusterSize = bytesPerSector * sectorsPerCluster
   @PUSHI bytesPerSector @PUSHI sectorsPerCluster @CALL MULU @POPI clusterSize

   # FATSizeInBytes = FATSize16 * bytesPerSector
   @PUSHI FATSize16 @PUSHI bytesPerSector @CALL MULU @POPI FATSizeInBytes

   #
   #
   @MV2V InDiskID activeDisk
   @PUSHI MainHeapID
   @PUSHI InBuffer
   @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 148:" @END @ENDIF
   @POPNULL
   #
   # Setup ClusterMask for IDing what sectors are part of a cluster
   @PUSHI sectorsPerCluster
   @SWITCH
      @CASE 2
         @MA2V 1 ClusterMask
         @CBREAK
      @CASE 4
         @MA2V 3 ClusterMask
         @CBREAK
      @CASE 8
         @MA2V 7 ClusterMask
         @CBREAK
      @CASE 16
         @MA2V 15 ClusterMask
         @CBREAK
      @CASE 32
         @MA2V 31 ClusterMask
         @CBREAK
      @CDEFAULT
         @MA2V 0 ClusterMask
         @CBREAK
   @ENDCASE
   @POPNULL
@ENDIF
# M DebugPrint 1

? DebugPrint
@PRT " bytesPerSector = " @PRTHEXI  bytesPerSector @PRTNL
@PRT " sectorsPerCluster = " @PRTHEXI  sectorsPerCluster @PRTNL
@PRT " reservedSectors = " @PRTHEXI  reservedSectors @PRTNL
@PRT " numberofFATs = " @PRTHEXI  numberofFATs @PRTNL
@PRT " rootDirEntries = " @PRTHEXI  rootDirEntries @PRTNL
@PRT " totalSectors16 = " @PRTHEXI  totalSectors16 @PRTNL
@PRT " FATSize16 = " @PRTHEXI  FATSize16 @PRTNL
@PRT " rootDirStartSector = " @PRTHEXI  rootDirStartSector @PRTNL
@PRT " totalClusters  = " @PRTHEXI  totalClusters @PRTNL
@PRT " rootDirSize(bytes) = " @PRTHEXI  rootDirSize @PRTNL
@PRT " rootDirSizeInSectors = " @PRTHEXI  rootDirSizeInSectors  @PRTNL
@PRT " dataAreaStartSector = " @PRTHEXI  dataAreaStartSector @PRTNL
@PRT " FATSizeInSectors = " @PRTHEXI  FATSizeInSectors @PRTNL
@PRT " totalDataSectors = " @PRTHEXI  totalDataSectors @PRTNL
@PRT " clusterSize = " @PRTHEXI  clusterSize @PRTNL
@PRT " FATSizeInBytes = " @PRTHEXI  FATSizeInBytes @PRTNL
ENDBLOCK
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#######################################################
# Function ParsePath(filepath, DiskID):(FP/DIR,Code)
# This is a core function that serves several uses.
# It returns two code base on what it finds.
#  Code 1       Code 2
#  0            DIR_Cluster       If File not found but DIR part is valid
#  1            FP                Both File and DIR parts are valid and exist
#  2            DIR_CLuster       Dir Path is invalid. DIR_Cluster is how far down it got.
# 
# Functon that builds a File Pointer FP
:ParsePath
@PUSHRETURN
@LocalVar InFilePath 01
@LocalVar DiskID 02
@LocalVar currentSector 03
@LocalVar components 04
@LocalVar numComponents 05
@LocalVar Index1 06
@LocalVar Entry 07
@LocalVar FP 08
@LocalVar Index2 09
@LocalVar DirSector 10
@LocalVar EntryOffset 11
@LocalVar Code1 12
@LocalVar Code2 13
#
@POPI DiskID
@POPI InFilePath

#
@MV2V rootDirStartSector currentSector # We are starting at 'Root' Directory. But later lets allow a CWD concept.
@MA2V 0 Code2       # If we find sub-directories, Code2 will be last DIR found.
#
@PUSHI InFilePath
@CALL strUpCase      # Changes filePath to be just uppercase
@PUSHI InFilePath
@CALL SplitPath     # Split string filepath into array of string ptrs, return both number of entrys and the array
@POPI numComponents
@POPI components
@IF_EQ_AV 1 numComponents
   @MA2V 0 Code1      # There is a diffrent default if we're dealling with sub-directories.
@ELSE
   @MA2V 3 Code1
@ENDIF

# We loop though all the components of the filepath string.
# In simplest case a file in the root directory, this string will be basicly 1 unit long
# In other cases the first units found should be names of sub-directories until we get to the last entry.
# So every time we find a match, we will expect it to be name of a sub-directory and repeat but now starting
# from that point.
@ForIA2V Index1 0 numComponents
   @PUSHI currentSector
   @PUSHI components @PUSHI Index1 @SHL @ADDS @PUSHS  # put string ptr at array[index] on stack
   @PUSHI DiskID
   # fineEntryInDirectory will look for a string match in the current directory space.
   # It return 0 if no match, or it copies the Dir Entry to memory an returns Ptr to it.
   @CALL findEntryInDirectory  # (currentSector, compoents[index], diskid)
   @IF_ZERO
      @PRT "No File Exact Match: State:" @PRTI Index1 @PRT " of " @PRTI numComponents @PRTNL
      # No filename matched.
      @POPNULL
      @MA2V 0 FP
#      @MA2V 0 Code1
      @MV2V currentSector Code2 
      @FORBREAK
   @ELSE
      # The return is a pointer to an in memory version of the Directory Entry
      @POPI EntryOffset
      @POPI DirSector
      @POPI Entry
      @PUSHI Entry
      @ADD DSofsAttributes @PUSHS @AND 0xff
      # bit mask 0x10 is directory flag
      @AND 0x10
      @IF_NOTZERO
         # Is a Directory. Move down into it.
         @MA2V 0 Code1
         @PRT "Directory Name: State:" @PRTI Index1 @PRT " of " @PRTI numComponents @PRTNL         
         @POPNULL
         @PUSHI Entry  @ADD DSofsStartCluster @PUSHS
         @CALL Cluster2Sector
         @POPI currentSector
         @MV2V currentSector Code2         # This will change if chain of sub-directories.         
      @ELSE
         # Found a file. Create a new FP structure
      @PRT "File Matched: State:" @PRTI Index1 @PRT " of " @PRTI numComponents @PRTNL      
         @POPNULL
         @MA2V 1 Code1         # This means the Basic Filename part is valid.
         @PUSHI MainHeapID   @PUSH FPofsSize  @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 340:" @PRTHEXTOP @POPNULL @END @ENDIF
         @POPI FP
         @ForIA2B Index2 0 FPofsSize         # Zero out the FP structure.
            @PUSH 0
            @PUSHI FP @ADDI Index2
            @POPS
         @NextBy Index2 2
         # We need to go though the FP Structure and fill out the fields.
         # Entry is a constant that referes to Dir Structure in memory
         # We'll use these macros.
      # SetFPConst FPofsOFFSET Constant
         M SetFPConst @PUSH %2 @PUSHI FP @ADD %1 @POPS
      # SetFPEntry FPofsOFFSET ENTRY[offset]    Copies DIR[index] to matching FP[index]
         M SetFPEntry @PUSHI Entry @ADD %2 @PUSHS @PUSHI FP @ADD %1 @POPS
      # SetFPVarI FPofsOFFSET MEM[variable]     Copies Variable to matching FP[index]
         M SetFPVarI @PUSHI %2 @PUSHI FP @ADD %1 @POPS
      # SetFPSVal FPofsOFFSET                   Pops Stack TOS to FP[index]
         M SetFPSVal @PUSHI FP @ADD %1 @POPS              # This is like SetFPVarI but for TOS as value.
         #         
      # Store the current DiskID with the FP so we can do disk to disk copies
         @SetFPVarI FPofsDiskID DiskID
         #
      #  Get the size, which is 2 words
         @SetFPEntry FPofsFileSize DSofsFileSize
         @SetFPEntry FPofsFileSize+2 DSofsFileSize+2
         #
      # We have to Sector/Offset structures
      # FSSector/FSOffset are equal to 'FileSize' and are pointing to EOF
         @PUSHI Entry @ADD DSofsFileSize
         @CALL F32to16            # Split the 32bit size into Sector/Offset
         @SetFPSVal FPofsFSOffset
         @SetFPSVal FPofsFSSector
         #
      # Set HWSector to sector where read/insert would be in HW units.
         @PUSHI Entry @ADD DSofsStartCluster @PUSHS
         @CALL Cluster2Sector
      # Hardware Sector of Start of File
         @DUP
         @SetFPSVal FPofsFirstSector
      # In the begining, these are the same, HWSector changes with read/writes.         
         @SetFPSVal FPofsHWSector      
      # Logcal Startof File is 0
         @SetFPConst FPofsLogicSector 0
      # Both Logic and HW share the same Offset info, so set that to zero
         @SetFPConst FPofsOffset 0
      # Now save the Sector number and offset for this Directory Record.
         @SetFPVarI FPofsDirRecSector DirSector
         @SetFPVarI FPofsDirRecOffset EntryOffset
         # Mark the FP buffer as stale so we'll know to read it.
      @SetFPConst FPofsState -1
         #
      # For debugging print the FP infor.
      @PUSHI FP @CALL FPrintFPInfo
      @MV2V FP Code2     # IF File hadn't been found Code2 would still be zero or DIR Sector for subdirectories.
      @ENDIF
      # No longer need Entry, clean it up
      @PUSHI MainHeapID
      @PUSHI Entry
      @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 301" @END @ENDIF
      @POPNULL
      # We sort of should exit the For loop here, but if there is a case
      # where the path continued past this point, then there should be trated as an error.
      # Letting the loop continue, should trigger that sort of error.
   @ENDIF
@Next Index1
# clean up the components array.
@PUSHI components
@PUSHI MainHeapID
@CALL SplitDelete
@PUSHI Code2
@PUSHI Code1


@RestoreVar 13
@RestoreVar 12
@RestoreVar 11
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
###############################################################
# Function findEntryInDirectory(currentSector,FileName, DiskID) [Entry, Sector, Offset] | 0 for EOL
# Scans the current clusters directory entries for matching FileName/Dir
# Does NOT decend into any sub-directories. But will return match if 'filename' is a DIR name.
:findEntryInDirectory
@PUSHRETURN
@LocalVar currentSector 01     #
@LocalVar FileName 02
@LocalVar InDiskID 03
@LocalVar SectorCnt 04
@LocalVar StartSector 05
@LocalVar Buffer 06
@LocalVar Entry 07
@LocalVar EntryOffset 08
@LocalVar ActSector 09
@LocalVar RetDirCopy 10
@LocalVar IsRoot 11
@LocalVar FNAttribute 12
@LocalVar ReturnCode 13
@LocalVar ResultOffset 14
#
#
@POPI InDiskID
@POPI FileName
@POPI currentSector
#
@MA2V 0 EntryOffset
##@PRTLN "Buffer: " @PUSHI MainHeapID @CALL HeapListMap
@PUSHI MainHeapID
@PUSH 512
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 297" @POPNULL @END @ENDIF
@POPI Buffer
#
@PUSHI InDiskID
@CALL readBootRecord
#
@MV2V currentSector StartSector
@MA2V 0 SectorCnt        # This matters with Sub-Dir's as we keep track of clusters
#
# Before We start Loop, get the first sector.
#
@PUSHI StartSector @POPI ActSector
@DISKSEEKI ActSector
@DISKREADI Buffer
#
# We have a couple of ending condtions for FileName server.
# And they can very if we are in the Root directory vs a sub-directory So set IsRoot for if ActSector < dataArea
@PUSHI ActSector
@IF_LT_V dataAreaStartSector
   @MA2V 1 IsRoot
@ELSE
   @MA2V 0 IsRoot
@ENDIF
@POPNULL
#
#
   # We have two loops,
   #  Outer is reading sectors until we have none left in this Dir
   #  Inner on is testing each DIR entry in the current sector.
   # Our exit contions are:
   #    We reach an END of DIR mark.   Exit 1
   #    We find a Filename/DIR match   Exit 2
   #    We ran out of valid Sectors    Exit 3
   #    
   #         If root dir, thats limited by 'rootDirEntries'
   #         If non-root, we're looking for a FAT entry that > 0xfff0
@MA2V 0 ReturnCode
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @MA2V 0 EntryOffset
   @PUSHI EntryOffset
   @WHILE_LT_V bytesPerSector
      @POPNULL
      @PUSHI EntryOffset      
      @ADDI Buffer
      @POPI Entry                # Entry points to the 32 byte 'field' inside sector for DIR Entry
      @PUSHI Entry @ADD DSofsAttributes @PUSHS @AND 0xff        # Get Attribute Byte.
      @POPI FNAttribute
      @IF_EQ_AV 0 FNAttribute
         # End of Directory List
         @MA2V 1 ReturnCode                   # Reached end of DIR listing without a match.
         @MV2V bytesPerSector EntryOffset     # Break the inner while loop
      @ELSE
        @PUSHI FNAttribute @AND 0x8
        @IF_NOTZERO
           @POPNULL               # Is a DISK Lable, skip it.
        @ELSE
           @POPNULL
           @PUSHI FNAttribute @AND 0x0f
           @IF_NOTZERO
              @POPNULL            # Is a long filename entry, skip it.
           @ELSE
              @POPNULL
              # Its a basic FileName, so lets run tests.
              @PUSHI FileName
              @PUSHI Entry @ADD DSofsFilename
              @CALL compareFileNames
              @IF_ZERO
                 @POPNULL
                 # Exact File match 
                 # Creata a new buffer to be a copy of the entry.
                 @MA2V 2 ReturnCode                   # Found a valid match
                 @MV2V EntryOffset ResultOffset
                 @MV2V bytesPerSector EntryOffset     # Break the inner while loop
              @ELSE
                 # FileNames do not match, skip to next one.
                 @POPNULL
              @ENDIF
           @ENDIF
        @ENDIF
      @ENDIF
      @IF_EQ_AV 0 ReturnCode
          @PUSHI EntryOffset @ADD 32 @POPI EntryOffset      # Move to next entry in buffer,also breaks inner while.
      @ENDIF
      @PUSHI EntryOffset
   @ENDWHILE
   @POPNULL
   #
   # If ReturnCode is still zero, then we had no match, and end of DIR lists wasn't in that buffer.
   #
   @IF_EQ_AV 0 ReturnCode
     # Need to try the next Sector. But getting next sector is diffrent for Root vs Sub-Directory
     @IF_EQ_AV 0 IsRoot
        @INCI SectorCnt
        @IF_EQ_AV 0 ClusterMask      # We need this option for 'odd' sized Clusters that are not Mul of 2
           @PUSHI SectorCnt @PUSHI sectorsPerCluster
           @CALL DIVU
           @POPNULL   # We only want the MOD value
        @ELSE
           @PUSHI SectorCnt @ANDI ClusterMask
        @ENDIF
        @IF_ZERO
           # If MOD or Mask == 0 then time for new Fat table entry
           @POPNULL
           # Create a temporary FAT buffer
           @PUSHI MainHeapID
           @PUSHI bytesPerSector
           @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1340" @POPNULL @END @ENDIF
           @POPI FatBuffer
           @PUSHI SearchSector @SUB 1 # We need to reverse the INC because we need ClusterID of previous Sector
           @CALL Sector2Cluster
           @POPI CurrentCluster
           @PUSHI CurrentCluster
           @SHR @SHR @SHR @SHR @SHR @SHR @SHR @SHR # >> 8 or /256
           @ADDI reservedSectors
           @POPI FatSector
           @DISKSEEKI FatSector
           @DISKREADI FatBuffer
           # have in mem right Fat Sector, now find index within sector
           @PUSHI CurrentCluster @SHL
        @ENDIF
      @IF_EQ_AV 512 bytesPerSector
         # We'll nearly always be dealing with 512 byte sectors
         @AND 0x1ff
      @ELSE
         # On the rare chance it's not, this will handle those cases.
         @PUSHI bytesPerSector
         @CALL MULU
         @POPNULL        # We only need the MOD value
      @ENDIF
      @POPI FatOffset
      @PUSHI FatBuffer @ADDI FatOffset
      @PUSHS            # Save result on Stack
      # Now clear out the unneeded FAT buffer
      @PUSHI MainHeapID
      @PUSHI FatBuffer
      @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1370: " @PRTTOP @END @ENDIF
      @POPNULL
      # It is a subdirectory so use the FAT tables to find next cluster.
      @PUSHI ActSector @CALL GetNextPossableSector
      @IF_UGE_A 0xfff0        # This code means end of Cluster chain.
         @POPNULL
         @MA2V 3 ReturnCode        # End of valid sectors.
      @ELSE
         @POPI ActSector            # Just read the next valid sector.
         @DISKSEEKI ActSector
         @DISKREADI Buffer
      @ENDIF
      @ELSE
        # It is the ROOT directory, so we continue until ActSector - rootDirStartSector < rootDirSizeInSectors
        @INCI ActSector
        @PUSHI ActSector @SUBI rootDirStartSector
        @IF_LT_V rootDirSizeInSectors
            # Still a valid Sector
            @DISKSEEKI ActSector
            @DISKREADI Buffer
        @ELSE
            @MA2V 3 ReturnCode         # Reached end of Root DIR
        @ENDIF
        @POPNULL
     @ENDIF
   @ENDIF
   @PUSHI ReturnCode                   # If this is still zero, then continue the search.
@ENDWHILE
@POPNULL
@IF_EQ_AV 2 ReturnCode
    @PUSHI MainHeapID
    @PUSH DSofsSize
    @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 436" @POPNULL @END @ENDIF
    @POPI RetDirCopy
    @PUSHI RetDirCopy @PUSHI Entry @PUSH DSofsSize
    @CALL memcpy
    @PUSHI RetDirCopy @PUSH 32 @CALL HexDump    
@ENDIF

#
# Reached the End, Clean up buffer.
@PUSHI MainHeapID
@PUSHI Buffer
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 368" @POPNULL @END @ENDIF
@POPNULL
# Now we have two types of return results
# Zero by itself means 'no match'
# Otherwise we return 3 words
#        RetDirCopy     Heap Copy of Dir Entry Data
#        ActSector      What disk sector the Entry is in.
#        EntryOffset    Where in that sector it is.
@IF_EQ_AV 2 ReturnCode
    # Valid FileName
    @PUSHI RetDirCopy
    @PUSHI ActSector
    @PUSHI ResultOffset
@ELSE
    @PUSH 0
@ENDIF

@RestoreVar 14
@RestoreVar 13
@RestoreVar 12
@RestoreVar 11
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#####################################################
# Function compareFileNames(FileZ1, FileSP1)
# Compares  Files looking for a match
# inbound FileZ1 is null terminated string
# inbound FileSP1 is a space filled 11 byte string.
:compareFileNames
@PUSHRETURN
@LocalVar FileZ1 01
@LocalVar FileSP1 02
@LocalVar FileSP2 03
@LocalVar Index1 04
@LocalVar Heapinfo 05
@POPI FileSP1
@POPI FileZ1
@PUSHI FileZ1
@CALL str2filename

@POPI FileSP2
@MV2V FileSP2 Heapinfo
@PUSH 0
@ForIA2B Index1 0 11
   @PUSHII FileSP1 @AND 0xff
   @PUSHII FileSP2 @AND 0xff
   @CMPS
   @IF_ZFLAG
   @ELSE
      @POPNULL @POPNULL
      @POPNULL
      @PUSH 1
      @FORBREAK
   @ENDIF
   @POPNULL @POPNULL
   @INCI FileSP1
   @INCI FileSP2
@Next Index1

# The Result of 1 or zero will be TOS
@PUSHI MainHeapID @PUSHI Heapinfo
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 440: " @PRTTOP @END @ENDIF


@POPNULL
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


#####################################################
# Function str2filename(FilePart):Heap Object 12 byte space padded FileName format
# Turns ASCIIZ string into space padded fixed 12 byte string (12th byte is zero)
:str2filename
@PUSHRETURN
@LocalVar FilePart 01
@LocalVar OutputStr 02
@LocalVar Index1 03
#
@POPI FilePart
#
@PUSHI MainHeapID
@PUSH 12
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 462" @POPNULL @END @ENDIF
@POPI OutputStr
#
@MA2V 0 Index1
@PUSHI Index1
# There's a few layers to this loop so to explain.
# Will loop over the fixed lenth of the 8.3 or 11 character space
# If index < 8, we will copy InFilePart changing to spaces when we hit either '.' or null
# else  skip forward if on '.' and repeat same logic about spaces for the Extention part.
@PUSHII FilePart @AND 0xff
@IF_EQ_A "/\0"
   @INCI FilePart
@ENDIF
@POPNULL
@WHILE_LT_A 11
   @IF_ULT_A 8         # Deal with FILE part
      @PUSHII FilePart @AND 0xff
      @IF_EQ_A ".\0"      # File part terminates on '.' or null or length
         @POPNULL
         @PUSH 0          # Set it to zero so space padding will fill out rest of File Part
      @ENDIF
      @IF_ZERO
         @POPNULL
         @PUSH " \0"
      @ELSE
         @INCI FilePart
      @ENDIF
      @PUSHI OutputStr
      @ADDI Index1
      @POPS               # This also effectivly pops off the TOS character.
   @ELSE
      @PUSHII  FilePart @AND 0xff 
      @IF_EQ_A ".\0"      # File Part had been terminated by '.' so inc.
         @POPNULL
         @INCI FilePart   # Move past the '.'
         @SUB 1           # Because we are not moving, don't move insert point either.
         # Skip rest of block, because there no reason to save '.' anywhere.
      @ELSE
         @IF_ZERO           # Ext part only terminates on null or length
            @POPNULL
            @PUSH " \0"
         @ELSE
            @INCI FilePart
         @ENDIF
         @PUSHI OutputStr
         @ADDI Index1
         @POPS
      @ENDIF
   @ENDIF
   @ADD 1
   @POPI Index1
   @PUSHI Index1
@ENDWHILE
@POPNULL
@PUSHI OutputStr
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

      

   

#####################################################
# Function SplitPath(filepath):(outarray, numentries)
# Split a possible multi directory path "Foo\Bar\Kat" into pointer array of strings
:Divider "/\0"
:SplitPath
@PUSHRETURN
@LocalVar InFilePath 01
@POPI InFilePath

#
@PUSHI InFilePath
@PUSH Divider
@PUSHI MainHeapID
@CALL splitstr

@RestoreVar 01
@POPRETURN
@RET
   
#################################################
# Function HexDump(address, length)
# Hex Dump debug function. 
:HexDump
@PUSHRETURN
@LocalVar Start 01
@LocalVar Length 02
@LocalVar Index01 03
@LocalVar ColumnCnt 04

@POPI Length
@POPI Start
@PRTLN "ADDR:-0-1-2-3 -4-5-6-7 -8-9-A-B -C-D-E-F"
@MV2V Start Index01
#
@PUSHI Index01
M NibbleHexS @ADD "0\0" @IF_GT_A "9\0" @ADD 7 @ENDIF @PRTCHS
@WHILE_NOTZERO
   @POPNULL
   @PRTHEXI Index01 @PRT ":"
   @MA2V 0 ColumnCnt
   @PUSHI ColumnCnt                   # (
   @WHILE_ULT_A 16
      @POPNULL                        # )
      @PUSHI Index01 @ADDI ColumnCnt @PUSHS @AND 0xff
      @DUP                            # 
      @SHR @SHR @SHR @SHR  # >> 4
      #
      @NibbleHexS
      @POPNULL
      @AND 0x0f
      @NibbleHexS
      @POPNULL
      #
      @PUSHI ColumnCnt
      @SWITCH
      @CASE 3
         @PRTSP
         @CBREAK
      @CASE 7
         @PRTSP
         @CBREAK
      @CASE 11
         @PRTSP
         @CBREAK
      @CDEFAULT
         @CBREAK
      @ENDCASE
      @ADD 1 @POPI ColumnCnt      
      @PUSHI ColumnCnt
   @ENDWHILE
   @POPNULL
   @PRT "    "
   @MA2V 0 ColumnCnt
   @PUSHI ColumnCnt
   @WHILE_ULT_A 16
        @POPNULL
        @PUSHI Index01 @ADDI ColumnCnt @PUSHS @AND 0xff
        @IF_GE_A "0\0"
           @IF_LE_A "z\0"
               @PRTCHS
               @POPNULL
               @PUSH 0
           @ELSE
               @PRT "+"
           @ENDIF
        @ELSE
           @PRT "-"
        @ENDIF
        @POPNULL
        @INCI ColumnCnt
        @PUSHI ColumnCnt
   @ENDWHILE
   @POPNULL
   @PRTNL
   @PUSHI Index01 @ADD 16 @POPI Index01
   @PUSHI Start @ADDI Length
   @IF_LE_V Index01
      # Time to exit loop
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL
      @PUSH 1
   @ENDIF
@ENDWHILE
@POPNULL
#@DEBUGTOGGLE
#
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#######################################################
# Function FPrintFPInfo
# Prints table of FP fields
:FPrintFPInfo
@PUSHRETURN
@LocalVar InFP 01
@POPI InFP

@PRT "--------------------------------------------------------\n"
@PRT "|         File Pointer: " @PRTHEXI InFP @PRT "\t\t\t\t|\n"
@PRT "--------------------------------------------------------\n"
@PRT "| FPofsFileSize: " @PUSHI InFP @ADD FPofsFileSize @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t\t|\n"
@PRT "| FPofsFSSector: " @PUSHI InFP @ADD FPofsFSSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsFSOffset: " @PUSHI InFP @ADD FPofsFSOffset @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsFirstSector: " @PUSHI InFP @ADD FPofsFirstSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsDirRecSector: " @PUSHI InFP @ADD FPofsDirRecSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsDirRecOffset: " @PUSHI InFP @ADD FPofsDirRecOffset @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsHWSector: " @PUSHI InFP @ADD FPofsHWSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsLogicSector: " @PUSHI InFP @ADD FPofsLogicSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsOffset: " @PUSHI InFP @ADD FPofsOffset @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsDiskID: " @PUSHI InFP @ADD FPofsDiskID @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t\t|\n"
@PRT "| FPofsState: " @PUSHI InFP @ADD FPofsState @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t\t|\n"
@PRT "|-------------------------------------------------------|\n"
@RestoreVar 01
@POPRETURN
@RET


####################################################
# Function GetNextPossableSector(InSector)
# Use logic about sectors and Fat table to return next sector.
:GetNextPossableSector
@PUSHRETURN
@LocalVar InSector 01
@LocalVar TempBuffer 02
@LocalVar SpotInCluster 03
@POPI InSector
#
@PUSHI sectorsPerCluster
@CASE 2
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0x1
    @POPI SpotInCluster
   
@CASE 4
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0x3
    @POPI SpotInCluster
    @CBREAK
@CASE 8
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0x7
    @POPI SpotInCluster
    @CBREAK
@CASE 16
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0xf
    @POPI SpotInCluster
    @CBREAK
@CDEFAULT
    @POPNULL
    @PUSHI InSector
    @PUSHI sectorsPerCluster
    @CALL DIVU
    @POPNULL
    @POPI SpotInCluster
    @CBREAK
@ENDCASE
@IF_EQ_AV 0 SpotInCluster
    # Try to Fetch FAT Table entry.
    @PUSHI InSector
    @CALL Sector2Cluster         # This will turn InSector into its matching Cluster Number
    @CALL Cluster2Sector         # This will check the FAT table and return the new Cluster for next 1st Sector
@ELSE
    # For cases where we are still inside the range of sectors in a cluster, so just jump to next sector.
    @PUSHI InSector
    @ADD 1
@ENDIF
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

  


####################################################
# Function Sector2Cluster(sectorid):cluster
# Identifies the Cluster a given sector falls in (rounding down)
:Sector2Cluster
@PUSHRETURN
@LocalVar SectorIn 01
@POPI SectorIn

# FirstDataSector = reservedSectors+(2*FATSize)+rootDirSizeInSectors
# NewClusterID = ( SectorIn - FirstDataSector) >> 2) + 2
@PUSHI FATSize16 @SHL               
@ADDI rootDirSizeInSectors          
@ADDI reservedSectors                # == FirstDataSector
@PUSHI SectorIn
@SWP @SUBS                           # (SectorID - FirstDatSector)
@SHR @SHR                            # /2
@ADD 2                               # Clusters start at 2 in FAT16
@RestoreVar 01
@POPRETURN
@RET

####################################################
# Function Cluster2Sector(clusterid)
# Given a particular Cluster number, returns the first sector in that cluster.
# Assumes 'current disk'
:Cluster2Sector
@PUSHRETURN
@LocalVar InClusterID 01
@POPI InClusterID
@DEC2I InClusterID         # Skip 2 because cluster 0 and 1 are not part of table
@PUSHI InClusterID
@SHL @SHL                  # X 2
@ADDI dataAreaStartSector
@RestoreVar 01
@POPRETURN
@RET

####################################################
# Function F32to16(In32Ptr):[sectorcount,Offset]
# Takes a ptr to a 32 bit FileSize/FilePostion and returns what sectorcount, offset as two 16 bit numbers
:F32to16
@PUSHRETURN
@LocalVar In32Ptr 01
@LocalVar OutSectCount 02
@LocalVar OutOffset 03
@LocalVar In32PtrHigh 04

@DUP
@POPI In32Ptr
#
@ADD 2 @POPI In32PtrHigh
#
# Get the lowest 9 bit (0-511) offset.
@PUSHII In32Ptr
@AND 0x1ff
@POPI OutOffset
#
@PUSHII In32Ptr @POPI F36LWLB
@PUSHII In32PtrHigh @POPI F36HWLB
#
# The 15 bits that start at F32LWHB and go through F32HWLB need to be shifted Right one bit
@PUSHI F36LWHB
@SHR
@POPI OutSectCount
# This 16th bit comes from what was the 1st bit on F36HWHB
@PUSHI F36HWHB @AND 0x1
@IF_NOTZERO
   @POPNULL
   @PUSH 0x8000           # Set Just the highest bit.
   @ORI OutSectCount
   @POPI OutSectCount
@ELSE
   @POPNULL
@ENDIF
# Now return both values.
@PUSHI OutSectCount
@PUSHI OutOffset
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

# Field Formated Stroage to allow 8 bit 'shifts'
:F36LWLB $$0
:F36LWHB $$0
:F36HWLB $$0
:F36HWHB $$0



###############################################
# Function ReadSectorWorker1(FP,LogicIndex):HWSector
# Support function that does some of the 'hard' work
# of figuring out what HW sector maps to a given LogicalSector
:ReadSectorWorker1
@PUSHRETURN
@LocalVar FP 01
@LocalVar LogicIndex 02
@LocalVar SearchPoint 03      # Location in file in Logical Sectors
@LocalVar SearchSector 04     # Location in file in HW Sectors
@LocalVar SearchOffset 05     # Offset in range 0-511 of with in sector of interest
@LocalVar FatBuffer 06
@LocalVar FatSector 07
@LocalVar FatOffset 08
@LocalVar CurrentCluster 09
#
@POPI LogicIndex
@POPI FP
#
# Get in File where we last read data from.
@PUSHI FP @ADD FPofsHWSector @PUSHS
@POPI SearchSector                # In HW Sector Units
@PUSHI FP @ADD FPofsOffset @PUSHS
@POPI SearchOffset
@PUSHI FP @ADD FPofsLogicSector @PUSHS
@POPI SearchPoint

 
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   #
   @IF_EQ_VV LogicIndex SearchPoint
      # Match Found
      @PUSH 0
   @ELSE
      @INCI SearchPoint
      @INCI SearchSector
      # Test to see if we've rolled over to next cluster.
      @IF_EQ_AV 0 ClusterMask
          # Handle the rare case where ClusterMask is not a simple number.
          @PUSHI SearchPoint @PUSHI sectorsPerCluster
          @CALL DIVU
          @POPNULL
      @ELSE
          @PUSHI SearchPoint @ANDI ClusterMask
      @ENDIF
      @IF_EQ_A 0
         # We've stepped though all the sectors in a given cluster, check FAT for next cluster ID
         @POPNULL
         @PUSHI SearchSector     # We may have to dec this so it points to previous FAT.
         @SUB 1
         @CALL Sector2Cluster
         @CALL NextClusterFromCluster  # Does the work of searching the FAT table for next sector.
         @POPI SearchSector
      @ELSE
         # Still in Cluster, just move to next sector.
         @POPNULL
      @ENDIF
      @PUSH 1        # Continue Loop
   @ENDIF
@ENDWHILE
@POPNULL
@PUSHI SearchSector
#
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


#################################################
# Function ReadSector(FP,Index,BufferPtr):AcutalSize(<512 means EOF)
# Reads a full 512 byte sector from file FP based on Index.
# Index is Logical Index, 0 to number sectors in file, not HW sector.
:ReadSector
@PUSHRETURN
@LocalVar FP 01
@LocalVar InIndex 02
@LocalVar OutBuffer 03
@LocalVar Temp1 04        # Short lived value
@LocalVar SearchSector 05
@LocalVar FileSizeSectors 06
@LocalVar FileRemainder 07
#
@POPI OutBuffer         # Points to 512 bytes to write the buffer
@POPI InIndex           # Logical index within the file
@POPI FP                # File Pointer
# First see if Index is even in range
@PUSHI FP @ADD FPofsFileSize
@CALL F32to16           # takes 32 bit number pointed at, into 2 16 values
@POPI FileRemainder
@POPI FileSizeSectors
@PRT "Requesting LSector: " @PRTHEXI InIndex @PRT " Disk FileSize: " @PRTHEXI FileSizeSectors @PRTNL
@IF_EQ_AV 0 FileRemainder
   # File Ends in natural sector boundry.
@ELSE
   # If Remainder>0 then we count it as an additional FileSizeSectors
   @INCI FileSizeSectors
@ENDIF
# Do some tests to make sure PF even valid
@PUSH 1                       # If none of the fail tests work, then leave 1 on stack
@IF_EQ_AV 0 FileSizeSectors
   @IF_EQ_AV 0 FileRemainder
       # File is empty, just return with 0
       @POPNULL
       @PUSH 0
   @ENDIF
@ENDIF
@PUSHI InIndex
@IF_GT_V FileSizeSectors
#   @PRT "InIndex is too large\n"
#   @PRT "InIndex: " @PRTHEXI InIndex @PRT " FileSectors: " @PRTHEXI FileSizeSectors @PRTNL
   @POPNULL
   @POPNULL              # Also get rid of that 'fall through 1'
   @PUSH 0
   @JMP ReadSectorQuickExit   
@ELSE
   @POPNULL
@ENDIF
#
@IF_ZERO
   @POPNULL
   @PRT "Not Valid FP\n"
   # FP not valid or empty, skip tests and just return 0
   #
   @PUSH 0
   @JMP ReadSectorQuickExit
@ELSE
   @POPNULL      # Get Rid of that 1 flag.
@ENDIF
#
# Now we have a valid InIndex and FP, start the process of reading data.
# ReadSectorWorker1 figures out HW Sector from Logical Sector number.
@PUSHI FP @PUSHI InIndex @CALL ReadSectorWorker1
@POPI SearchSector
#@PRT "Logic Sector: " @PRTHEXI InIndex @PRT " = HW: " @PRTHEXI SearchSector @PRTNL
@PUSHI FP @ADD FPofsDiskID @PUSHS        # Get FP.DiskID
@POPI Temp1
@DISKSELI Temp1
@DISKSEEKI SearchSector
@DISKREADI OutBuffer                        # Load disk sector to Buffer.
@PUSHI SearchSector
@PUSHI FP @ADD FPofsHWSector @POPS
@PUSHI InIndex @ADD 1
@PUSHI FP @ADD FPofsLogicSector @POPS
# We will drop here, whether or not we changed our current sector number
@IF_EQ_VV InIndex FileSizeSectors
   # Means we're on the last sector, which may not be a full 512 bytes long, so zero out buffer that over size
   @ForIV2A Temp1 FileRemainder 512
      @PUSHI OutBuffer @ADDI Temp1
      @DUP
      @PUSHS
      @AND 0xff
      @SWP
      @POPS
   @Next Temp1
   @PUSHI FileRemainder
@ELSE
   @PUSH 512            # All other cases its a full sector.
@ENDIF
:ReadSectorQuickExit
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
############################################
# Function NextClusterFromCluster(ClusterIn)
# Gien a Cluster number, query the FAT table for the next cluster.
:NextClusterFromCluster
@PUSHRETURN
@LocalVar ClusterIN 01
@LocalVar ByteOffset 02
@LocalVar sectorOffsetInFAT 03
@LocalVar offsetInSector 04
@LocalVar Temp1 05
@LocalVar FATBuffer 06
#
@POPI ClusterIN
#
#
@PUSHI ClusterIN
@SHL    # Fat entires are 2 bytes long  (may need to sub 2)
@POPI ByteOffset
#
@PUSHI ByteOffset
@PUSHI bytesPerSector
@CALL DIVU            # Div returns both // and %
@POPI sectorOffsetInFAT
@POPI offsetInSector
#
#
@PUSHI sectorOffsetInFAT
@ADDI reservedSectors
@POPI Temp1
@DISKSEEKI Temp1
# Create buffer
@PUSHI MainHeapID
@PUSHI bytesPerSector
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1267" @POPNULL @END @ENDIF
@POPI FATBuffer
#
@DISKREADI FATBuffer
#
@PUSHI FATBuffer
@ADDI offsetInSector
@PUSHS           # Result on stack
@IF_UGT_A 0xfff0
@ELSE
   @CALL Cluster2Sector
@ENDIF
#
@PUSHI MainHeapID @PUSHI FATBuffer
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1308: " @PRTTOP @END @ENDIF
@POPNULL

#
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#################################################
# Function Fseek(FP,IndexPtr)
# Moves the next 'insert/read' point, IndexPtr is ptr to 32 bit integer.
# Returns 0 on error or trying to seek past end of file.
:Fseek
@PUSHRETURN
@LocalVar FP 01
@LocalVar IndexPtr 02
@LocalVar TargOffset 03
@LocalVar TargSector 04
@LocalVar FileOffset 05
@LocalVar FileSizeSect 06
#
@POPI IndexPtr
#
# Get the requested location in file
@PUSHI IndexPtr
@CALL F32to16
@POPI TargOffset
@POPI TargSector
# Get real size of file
@PUSHI FP @ADD FPofsFileSize @PUSHS
@CALL F32to16           # takes 32 bit number pointed at, into 2 16 values
@POPI FileOffset
@POPI FileSizeSect
#
# Test that location is within file size
@PUSHI TargSector
@IF_GT_V FileSizeSect
   # Target is beyond the end of File.
   @POPNULL
   @PUSH 0
   @JMP FSeekExit
@ENDIF
@POPNULL
@IF_EQ_VV FileSizeSect TargSector
   # The case when both sector counts are equal, we need to check the offsets.
   @PUSHI TargOffset
   @IF_GT_V FileOffset
      # Targe is beyond end of file.
      @POPNULL
      @PUSH 0
      @JMP FSeekExit
   @ENDIF
   # Here means it's on last block , but not yet used every byte.
   @POPNULL
@ENDIF
#
# Save the new target values.
@PUSHI TargSector
@PUSHI FP @ADD FPofsHWSector @POPS
@PUSHI TargOffset
@PUSHI FP @ADD FPofsOffset @POPS
@PUSH 1           # Setting this to 'not 0' means successfull.
:FSeekExit
# Exit function
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
   


#################################################
# Function Read_worker2(WorkerType,FP,Size,Buffer)
# This worker will support both the readblock and readline code
# There will just be diffrent front ends on them.
# WorkerType 1 = Size based buffer
# WorkerType 2 = Newline or RecordMark fields.
#
:Read_worker2
@PUSHRETURN
@LocalVar WType 01
@LocalVar FP 02
@LocalVar InSize 03
@LocalVar OutBuffer 04
@LocalVar ReadBuffer 05
@LocalVar TotalRead 06  # Total Bytes read for cmp to InSize
@LocalVar RBIndex 07   # Sector byte index from start to 512
#
@POPI OutBuffer
@POPI InSize
@POPI FP
@POPI WType
@PUSH 0 @PUSHI OutBuffer @POPS   # Null the OutBuffer
#
# First question, is the current buffer stale, or can we use it as is?
@PUSHI FP @ADD FPofsState @PUSHS
@IF_EQ_A -1
   # Data is stale, read cluster into FP.Buffer
   @POPNULL
   # ReadSector(FP,FP.CurrentSector,FP.Buffer)
   @PUSHI FP
   @PUSHI FP @ADD FPofsLogicSector @PUSHS
   @PUSHI FP @ADD FPofsBuffer      # Note Buffer is IN FP so its no need for PUSHS
#   @PUSH -1 @PUSHI FP @ADD FPofsLogicSector @POPS   # Break old Logic Sector to force read.
   @CALL ReadSector
   @POPNULL # Not testing for EOF because it won't make a diffrence.
   @PUSHI FP @ADD FPofsLogicSector @PUSHS
   @PUSHI FP @ADD FPofsState @POPS   # Over write State with current LogicSector
@ELSE
   @POPNULL
@ENDIF
#
# Setup initial read/write locations.
@PUSHI FP @ADD FPofsBuffer
@POPI ReadBuffer
@MA2V 0 TotalRead
@PUSHI FP @ADD FPofsOffset @PUSHS
@POPI RBIndex
#
# To Read buffers we'll be reading blocks in the destination buffer until one of the End conditions are met.
# The WType will control the end conditions.
@PUSH 0
@WHILE_ZERO
   @POPNULL
   # We have a few ways to determin EOR, and exit when any of them are true.
   @PUSHI WType
   @SWITCH
   @CASE 1      # Size Based
      @PUSHI TotalRead
      @IF_GE_V InSize
         @POPNULL
         @PUSH 1      # End of loop
      @ELSE
         @POPNULL
         @PUSH 0      # Continue so far.
      @ENDIF
      @CBREAK
   @CASE 2      # Records with seperator character (newline)
     @PUSHI ReadBuffer @ADDI RBIndex @PUSHS @AND 0xff
     @IF_EQ_V RecordMark
         @POPNULL
         @PUSH 1      # Reached end of record, exist while loop.
     @ELSE
         @POPNULL
         @PUSH 0
     @ENDIF
     @CBREAK
   @CDEFAULT
     @PRT "Not a valid worker flag. (1435)" @END
     @CBREAK
   @ENDCASE
   @SWP
   @POPNULL
   @IF_ZERO
      # Not yet End of Record, so write byte and check if we need to go to a new sector.
      @POPNULL
      @PUSHI ReadBuffer @ADDI RBIndex @PUSHS @AND 0xff
      @PUSHI OutBuffer @ADDI TotalRead @POPS
      @INCI TotalRead
      @INCI RBIndex
      # Test if we need to read next block.
      @PUSHI RBIndex
      @IF_GE_A 0x1ff
         :Debug01
         @POPNULL
         # Get Next Sector (FP,LogicSector,Buffer)
         @PUSHI FP
         @PUSHI FP @ADD FPofsLogicSector @PUSHS @ADD 1  # Move to next logical sector.
#         @PRT "Read Next Sector: " @PRTHEXTOP @PRTNL
#         @PUSHI FP @ADD FPofsLogicSector @POPS
#         @PUSHI FP @ADD FPofsLogicSector @PUSHS
         @PUSHI FP @ADD FPofsBuffer
         @CALL ReadSector
         @IF_ZERO
            @POPNULL
            # Reached end of File exit loop.
            @PUSH 2
         @ELSE
            @POPNULL
            @MA2V 0 RBIndex     # reset 0-512
            @PUSH 0             # Still in loop
         @ENDIF
      @ELSE
         @POPNULL
         @PUSH 0
      @ENDIF
   @ELSE
#      @PRT "End of Record: " @PRTHEXI RBIndex @PRTSP @StackDump @PRTNL
      # Reached End of Record.
      # Handle case were End of record and End of Sector are the same:
#      @PRT "EOR: " @PRTHEXI RBIndex @StackDump
      @POPNULL
      @PUSHI RBIndex
      @IF_GE_A 0x1ff
         @IF_EQ_AV 2 WType
            # Handle odd case where last character in full Sector is also RecordMark
            @POPNULL
            @PUSHI ReadBuffer @ADDI RBIndex @PUSHS @AND 0xff
            @IF_EQ_V RecordMark
               @POPNULL
               @PUSH 1  # Reached of line, exit while loop
               @MA2V 0 RBIndex
               # Mark the old readbuffer as stale
               @PUSH -1
               @PUSHI FP @ADD FPofsState @POPS
            @ELSE
               @POPNULL
               # OK so its not that odd case, so just check for normal EOF logic
               @POPNULL
               @PUSHI FP         
               @PUSHI FP @ADD FPofsLogicSector @PUSHS @ADD 1  # Move to next logical sector.
               @PUSHI FP @ADD FPofsLogicSector @POPS
               @PUSHI FP @ADD FPofsLogicSector @PUSHS
               @PUSHI FP @ADD FPofsBuffer
               @CALL ReadSector   # This is just to test if we reached EOF
               @MA2V 0 RBIndex   # Reset to zero for next read.
               @IF_ZERO
                  @POPNULL
                  @PUSH 2    # Reached real EOF.. last line is not terminated with RecordMark
               @ELSE
                  @POPNULL
               @ENDIF
            @ENDIF
         @ELSE
            # This is nearly identical to the block above but for WorkerType 1.
            # Due to the way the IF's are nested its not trivial to reused same code. Cost is about 50 bytes.
            @POPNULL
            @PUSHI FP         
            @PUSHI FP @ADD FPofsLogicSector @PUSHS @ADD 1  # Move to next logical sector.
            @PUSHI FP @ADD FPofsLogicSector @POPS
            @PUSHI FP @ADD FPofsLogicSector @PUSHS
            @PUSHI FP @ADD FPofsBuffer
            @CALL ReadSector   # This is just to test if we reached EOF
            @MA2V 0 RBIndex   # Reset to zero for next read.         
            @IF_ZERO
               @POPNULL
               @PUSH 2  # Reached EOF and End of Sector as same time.
            @ELSE
               @POPNULL
               @PUSH 1  # Reach end of block, but not end of fie.
            @ENDIF
         @ENDIF
      @ELSE
         # We Reached an End of block, not consider if we have to skip past the EOL mark.         
         @IF_EQ_AV 2 WType
            # This will move cursor past the RecordMark Character.
            @INCI RBIndex
         @ENDIF            
      @ENDIF      
   @ENDIF
@ENDWHILE
@IF_EQ_A 2
   # Exit is with EOF use 0 for return
   POPNULL
   @PUSH 0
@ELSE
   # Else return is total number of bytes read.
   @POPNULL
   @PUSHI TotalRead @ADD 1
@ENDIF

   
# Whatever the current RBIndex is the new FP.CurrentOffset
@PUSHI RBIndex
@PUSHI FP @ADD FPofsOffset @POPS
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
################################################
# Function ReadBuffer(FP,Size,Buffer)
# Reads user defined (max 16bit 64K size) Block date into buffer from current insertion point
:ReadBuffer
@PUSHRETURN
@LocalVar FP 01
@LocalVar Size 02
@LocalVar Buffer 03
#
@POPI Buffer
@POPI Size
@POPI FP
@PUSH 1
@PUSHI FP
@PUSHI Size
@PUSHI Buffer
@CALL Read_worker2
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
################################################
# Function ReadLine(FP,Buffer)
# Reads one line ending with newline to buffer.
:ReadLine
@PUSHRETURN
@LocalVar FP 01
@LocalVar Buffer 02
#
@POPI Buffer
@POPI FP
@PUSH 2
@PUSHI FP
@PUSHI 0
@PUSHI Buffer
@CALL Read_worker2
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
################################################
# Function DeleteFile(FP):SuccessCode
# Not yet implmented.
:DeleteFile
:DeleteFileFP
@PRT "Not yet implimented.\n"
@PUSH 0
@SWP
@RET
################################################
# Function FileOpen(Filename, ModeCode):FP
# Mode == "r" "rw" "w" "a" Read,ReadWrite,Write Must be 2 bytes long.
# Will open existing file, or create new file
# Returns a FP.
#
:FileOpen
@PUSHRETURN
@LocalVar FileName 01
@LocalVar ModeCode 02
@LocalVar FP 03
@LocalVar WorkDir 04
@LocalVar DirOffset 05
@LocalVar DirSector 06
@LocalVar DirBuffer 07
@LocalVar SpaceFileName 08
@LocalVar PathStat 09
@LocalVar Index1 10

#
@POPI ModeCode
@POPI FileName
#
@DISKSELI activeDisk
@PUSHI FileName @PUSHI activeDisk
@CALL ParsePath
@POPI PathStat
@POPI FP           # FP will be 0 or DIR info, if path is not to valid filename.
#
# Our logic rules are:
# FP exists already:
#    Mode "rw" "r"   Set FP.(Current[Sector,Offset]=0)
#    Mode "a"        Set FP.(Current[Sector,Offset]=EOF)
#    Mode "w"        Delete old file, create newone.
# FP does not exist
#    Mode "r"        Error can't read non-existing file.
#    Otherwise Create new FP
#
@IF_EQ_AV 1 PathStat   # Code 1 mean valid Filename for FP.
   @IF_EQ_AV "w\0" ModeCode
      # File exists, "w" means delete old file and replace.
      @PUSHI FP
      @CALL DeleteFileFP
      @PUSHI FileName
      @PUSHI ModeCode
      @CALL FileOpen  # Yes we are calling this function recurivly
   @ELSE
      @IF_EQ_AV "a\0" ModeCode
         # Append of existing file, move FP.Current to EOF
         @PUSHI FP @ADD FPofsFileSize
         @CALL F32to16     # Converts the 32 bit file size into 'logical sector' and 'offset'
         @PUSHI FP @ADD FPofsOffset @POPS
         @PUSHI FP @ADD FPofsHWSector @POPS
      @ENDIF
      # Reach here then FP is good File with offset to right position.
   @ENDIF
@ELSE
   # ParsePath did not find a filename, but it may have found a directory.
   @IF_EQ_AV 2 PathStat    # Code 2 means the filename was not just not fount, it wasn't even valid
      @MA2V -1 FP          # Return -1 as error code for invalud Filename
   @ELSE
      # Here means we have a valid directory and filename, so need to create a FP
      @MV2V FP WorkDir
      @PUSHI WorkDir
      @CALL FindAvailDir    # Returns (DirSector,DirOffset) or 0 for error.
      @IF_EQ_A -1
         # -1 means we ran out of space or DIR was full.
         @POPNULL
         @POPNULL
         @PRT "Error, can not allocate new Directory Entry on Disk for: " @PRTSI FileName @PRTNL
         @MA2V -1 FP
      @ELSE
         # Found a directory, build a DIR entry there and make a FP to it.
         @POPI DirOffset
         @POPI DirSector
         # Need to create a new DIR entry and FP
         #
         # First create a buffer for the DIR entry
         @PUSHI MainHeapID
         @PUSH 512
         @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1627" @POPNULL @END @ENDIF
         @POPI DirBuffer
         # Fetch the current DirBuffer
         @DISKSEEKI DirSector
         @DISKREADI DirBuffer
         #
         # Now modify the DirBuffer and write it back.
         @PUSHI FileName
         @CALL str2filename  # Convert FileName into its space padded format.
         @POPI SpaceFileName
         #
         @ForIA2B Index1 0 11
             @PUSHI SpaceFileName @ADDI Index1 @PUSHS @AND 0xff   # Get Character from Src
             @PUSHI DirBuffer  @ADDI DirOffset @ADDI Index1 @AND 0xff00  # Get Word from Dest, mask high byte
             @ORS      # Combine them.
             @PUSHI DirBuffer @ADDI DirOffset @ADDI Index1 @POPS
         @Next Index1
         # No longer need the space padded filename, so clear its memory.
         @PUSHI MainHeapID @PUSHI SpaceFileName
         @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1646: " @PRTTOP @END @ENDIF
         @POPNULL
         # We assume this is a normal file, so give it just a 0x20 (archive bit set) attribute
         @PUSH 0x20
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsAttributes @PUSHS @AND 0xff00
         @ORS
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsAttributes @POPS
         #
         # We'll just use 0 for time and date info for now.
         @PUSH 0
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsCreateTime @POPS
         @PUSH 0
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsCreateDate @POPS
         @PUSH 0
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsWriteTime @POPS
         @PUSH 0
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsWriteDate @POPS
         #
         @CALL FindFreeCluster    # searches FAT entries returns first free one.         
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsStartCluster @POPS
         # StartHigh is always 0 in this FAT16
         @PUSH 0
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsStartHigh @POPS
         #
         # Set FileSize to 0 0 (zero both FileSize and FileSize+2)
         @PUSHI DirBuffer @ADDI DirOffset @ADD DSofsFileSize
         @DUP @PUSH 0 @SWP
         @POPS
         @ADD 2 @PUSH 0 @SWP
         @POPS
         #
         # Now Write the DirBuffer with its updates to where it was.
         @DISKSEEKI DirSector
         @DISKWRITEI DirBuffer
         #
         # Now we need to create a new FP
         @PUSHI MainHeapID
         @PUSH FPofsSize
         @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 236:" @PRTHEXTOP @POPNULL @END @ENDIF
         @POPI FP
         @ForIA2B Index1 0 FPofsSize         # Zero out the FP structure.
            @PUSH 0
            @PUSHI FP @ADDI Index1
            @POPS
         @NextBy Index1 2
         # Fill in FP fields

         @PUSHI DirBuffer @ADD DSofsFileSize @PUSHS @PUSHI FP @ADD FPofsSize @POPS
         @PUSHI DirBuffer @ADD DSofsFileSize+2 @PUSHS @PUSHI FP @ADD FPofsSize+2 @POPS
         
         

         @PUSHI activeDisk @PUSHI FP @ADD FPofsDiskID @POPS


         @PUSHI DirBuffer @ADD DirOffset @ADD DSofsStartCluster @PUSHS @DUP
         @PUSHI FP @ADD FPofsHWSector @POPS
         @PUSHI FP @ADD FPofsFirstSector @POPS
         @PUSH 0  @PUSHI FP @ADD FPofsOffset @POPS
         @PUSH 0  @PUSHI FP @ADD FPofsLogicSector @POPS
         @PUSH -1 @PUSHI FP @ADD FPofsState @POPS
         #
         # We no longer need DirBuffer
         @PUSHI MainHeapID
         @PUSHI DirBuffer
         @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1704" @END @ENDIF
         #
      @ENDIF
   @ENDIF
@ENDIF
@PUSHI FP
#
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

##############################################
# Function FindAvailDir(InSector)
# Searches the Dir Structure, and finds first one that is empty/available
:FindAvailDir
@PUSHRETURN
@LocalVar InSector 01
@LocalVar Index1 02
@LocalVar Index2 03
@LocalVar SectorData 04
@LocalVar Temp1 05
@LocalVar Result1 06
@LocalVar Result2 07
@LocalVar CurrentCluster 08
@LocalVar Sector 09
@LocalVar NewCluster 10

#
@POPI InSector
#
@PUSHI MainHeapID
@PUSH 512
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1736" @POPNULL @END @ENDIF
@POPI SectorData
#
# We have diffrent loops for Root vs Sub-Directory
@PUSHI InSector
@IF_LT_V dataAreaStartSector
   @POPNULL
   # Its a Root DIR so all the sectors will be sequential and not involve the FAT table.
   @ForIA2V Index1 0 rootDirSizeInSectors
       @PUSHI Index1 @ADDI InSector @POPI Temp1
       @DISKSEEKI Temp1
       @DISKREADI SectorData
       @MA2V 0 Result2
       @ForIA2B Index2 0 512          
          @PUSHI SectorData @ADDI Index2 @PUSHS @AND 0xff
#          @PRT " Offset: " @PRTHEXI Index2 @PRT " is : " @PRTHEXTOP @PRTNL
          @MA2V 0 Temp1
          @IF_ZERO @MA2V 1 Temp1 @ENDIF
          @IF_EQ_A 0xff @MA2V 1 Temp1 @ENDIF
          @IF_EQ_AV 1 Temp1      # ZERO OR FF
             @POPNULL   # True
             @PUSHI InSector @ADDI Index1 @POPI Result1
             @JMP FADExit
          @ELSE
             # False
             @POPNULL
          @ENDIF
          @PUSHI Result2 @ADD 32 @POPI Result2
       @NextBy Index2 32
   @Next Index1
   # Error exit case, return -1
   @MA2V -1 Result1
   @MA2V -1 Result2
   @JMP FADExit
   @END
@ENDIF
@POPNULL
# Here means we are doing a Sub-Directory and may need to use the FAT tables.
@PUSHI InSector
@CALL Sector2Cluster
@POPI CurrentCluster
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @PUSHI CurrentCluster
   @CALL Cluster2Sector
   @POPI Sector
   @ForIA2V Index1 0 sectorsPerCluster
       @PUSHI Sector @ADDI Index1 @POPI Temp1  # Temp1=Sector+Index1
       @DISKSEEKI Temp1       
       @DISKREADI SectorData
       @MA2V 0 Result2
       @ForIA2B Index2 0 512
           @PUSHI SectorData @ADDI Index2 @PUSHS @AND 0xff  # SectorData[Index2] &0xff
           @IF_ZERO
               @POPI Result1
               @JMP FADExit
           @ENDIF
           @POPNULL
           @PUSHI Result2 @ADD 32 @POPI Result2
       @NextBy Index2 32
   @Next Index1
   @PUSHI Sector @ADDI sectorsPerCluster
   @CALL GetNextPossableSector
   @IF_UGE_A 0xfff0
      # End of Cluster Chain. Unlike ROOT directories grow as needed.
      @CALL FindFreeCluster
      @IF_ZERO
          @PRT "Disk FAT table is full. No space left for new files"
          @END
      @ENDIF
      @POPI NewCluster
      @PUSHI CurrentCluster @PUSHI NewCluster
      @CALL StoreFat
      @PUSHI NewCluster @PUSH 0xffff
      @CALL StoreFat
      @MV2V NewCluster CurrentCluster
   @ELSE
      @POPI Sector
   @ENDIF
   @PUSH 0
@ENDWHILE
@POPNULL
# Set result to -1,-1 since there are no matches.
@MA2V -1 Result1
@MA2V -1 Result2
:FADExit
:Debug02
# We always end here for the exit
@PUSHI MainHeapID
@PUSHI SectorData
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1732" @END @ENDIF
@POPNULL
@PUSHI Result1
@PUSHI Result2
#
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
########################################################
# Function FindFreeCluster
# Wil l search FAT tables of current disk to find a free cluster.
:FindFreeCluster
@PUSHRETURN
#
@LocalVar StepNByVal 01
@LocalVar MaxCluster 02
@LocalVar FatBuffer 03
@LocalVar Cluster 04
@LocalVar FatSector 05
@LocalVar FatEntry 06
#@PRT "1:" @StackDump
#
@PUSHI MainHeapID
@PUSHI bytesPerSector
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1880" @POPNULL @END @ENDIF
@POPI FatBuffer
#
@PUSHI bytesPerSector @SHR @POPI StepNByVal
@PUSHI totalDataSectors @PUSHI sectorsPerCluster
@CALL DIVU @SWP @POPNULL
@POPI MaxCluster
#@PRT "2:" @StackDump
@ForIV2V Cluster LastAllocatedCluster MaxCluster
    # FatSector = (( Cluster / 2 ) / bytesPerSector) + reservedSectors
    @PUSHI Cluster @SHR   # Cluster / 2
    @PUSHI bytesPerSector
    @CALL DIVU @SWP @POPNULL
    @ADDI reservedSectors
    @POPI FatSector
    @DISKSEEKI FatSector
    @DISKREADI FatBuffer
    @ForIA2V FatEntry 0 bytesPerSector
       @PUSHI FatBuffer @ADDI FatEntry @PUSHS
       @IF_ZERO
         @POPNULL
#@PRT "3:" @StackDump         
         # LastAllocatedCluster = (FateSector - reservedSectors) * ( bytsPerSector / 2) + (FatEntry / 2)
         @PUSHI FatSector @SUBI reservedSectors # (FatSector - reservedSectors)
         @PUSHI bytesPerSector @SHR   # (bytesPerSector / 2)
         @CALL MULU
         @PUSHI FatEntry @SHR         # FatEntry / 2
         @ADDS
         @POPI LastAllocatedCluster
         @PUSHI LastAllocatedCluster
         @JMP ExitFindFreeCluster
       @ENDIF
       @POPNULL
    @NextBy FatEntry 2
@NextByI Cluster StepNByVal
# No Free Entry found, but we also want to wrap around to beginng before decalairing no match.
#@PRT "4:" @StackDump         
@ForIA2V Cluster 0 LastAllocatedCluster
    # FatSector = (( Cluster / 2 ) / bytesPerSector) + reservedSectors
    @PUSHI Cluster @SHR   # Cluster / 2
    @PUSHI bytesPerSector
    @CALL DIVU @SWP @POPNULL
    @ADDI reservedSectors
    @POPI FatSector
    @DISKSEEKI FatSector
    @DISKREADI FatBuffer   
    @ForIA2V FatEntry 0 bytesPerSector
       @PUSHI FatBuffer @ADDI FatEntry @PUSHS
       @IF_ZERO
         @POPNULL
         # LastAllocatedCluster = (FateSector - reservedSectors) * ( bytsPerSector / 2) + (FatEntry / 2)
         @PUSHI FatSector @SUBI reservedSectors # (FatSector - reservedSectors)
         @PUSHI bytesPerSector @SHR   # (bytesPerSector / 2)
         @CALL MULU
         @PUSHI FatEntry @SHR         # FatEntry / 2
         @ADDS
         @POPI LastAllocatedCluster
         @PUSHI LastAllocatedCluster
         @JMP ExitFindFreeCluster
       @ENDIF
    @NextBy FatEntry 2
@NextByI Cluster StepNByVal
@PUSH 0          # Bad Exit, no Free FAT entry found
:ExitFindFreeCluster
# Result is on stack, common exit.
@PUSHI MainHeapID
@PUSHI FatBuffer
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1942" @END @ENDIF
@POPNULL
#@PRT "5:" @StackDump         
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET



#########################################################
# Function FetchFat(Cluster):Value
# Fetches Cluster item from FAT table.
:FetchFat
@PUSHRETURN
@LocalVar Cluster 01
@LocalVar ByteOffset 02
@LocalVar sectorOffsetInFAT 03
@LocalVar offsetInSector 04
@LocalVar Temp1 05

#
@POPI Cluster
#
@IF_EQ_AV -1 SavedFatBuffer
   @PUSHI MainHeapID
   @PUSH 512
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1965" @POPNULL @END @ENDIF
   @POPI SavedFatBuffer
@ENDIF
@IF_EQ_VV Cluster LastFatBuffer
    @PUSHI Cluster
    @SHL
    @POPI ByteOffset
    @PUSHI ByteOffset
    @PUSHI bytesPerSector
    @CALL DIVU
    @POPI sectorOffsetInFAT
    @POPI offsetInSector
@ELSE
    @PUSHI Cluster
    @SHL
    @POPI ByteOffset
    @PUSHI ByteOffset
    @PUSHI bytesPerSector
    @CALL DIVU
    @POPI sectorOffsetInFAT
    @POPI offsetInSector
    @PUSHI sectorOffsetInFAT
    @ADDI reservedSectors
    @POPI Temp1
    @DISKSEEKI Temp1
    @DISKREADI SavedFatBuffer
@ENDIF
@MV2V Cluster LastFatBuffer
@PUSHI SavedFatBuffer
@ADDI offsetInSector
@PUSHS
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
:SavedFatBuffer -1
:LastFatBuffer -1
###################################################
# Function StoreFat(Cluster,Value)
# Saves Cluster# at 
:StoreFat
@PUSHRETURN
@LocalVar Cluster 01
@LocalVar Value 02
@LocalVar ByteOffset 03
@LocalVar sectorOffsetInFAT 04
@LocalVar offsetInSector 05
#
@POPI Value
@POPI Cluster
@IF_EQ_AV -1 SavedFatBuffer
     # Its normal to do a FetchFat before doing a StoreFat
     @PUSHI Cluster
     @CALL FetchFat
@ENDIF
@PUSHI Cluster
@SHL
@POPI ByteOffset
@PUSHI ByteOffset
@PUSHI bytesPerSector
@CALL DIVU
@POPI sectorOffsetInFAT
@POPI offsetInSector
@PUSHI Value
@PUSHI SavedFatBuffer
@ADDI offsetInSector
@POPS
# Its normal to delete the SavedFatBuffer after a write
@PUSHI MainHeapID
@PUSHI SavedFatBuffer
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 2044" @END @ENDIF
@MA2V -1 LastFatBuffer      # Mark it as freed
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

