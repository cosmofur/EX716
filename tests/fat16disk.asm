I common.mc
L lmath.ld
L string.ld
#
#
# Process for opening an preparing a file for reading/writing.
#
# 1) Take a string in format [/dir[/dir...]/]filename.ext
#    In loop check each dir part and starting with the 'Root' dir
#    work way down until you get to the 'current' directory for that filename
#    Do this by Setting G_CurrentDirBase to disk location where DIR's are stored
#    Once you exausted /dirs/ do a test to see if filename.ext exists.
#    If opening for writing, create a new entry and continue.
#    If opening for reading, and filename.ext exisints, set it up as *FILE stucture.


:INT_ActiveDisk -1       # Which Disk
:INT_ActiveSector -1      # What Sector in disk
:G_FileName "12345678"
:G_FileExtension "123"
:G_FileAttributes b0
:G_FileReserved b0
:G_CreateTime10ms b0
:G_CreateDate 0
:G_LastAccessDate 0
:G_FirstClusterHigh 0
:G_LastModificationTime 0
:G_LastModiicationDate 0
:G_FirstClusterLow 0
:G_FileSize 0 0
:G_RootDirSector 0
:G_CurrentDirBase 0
:G_SectorsPerFAT 0
:G_StartOfFATs 0
:G_NumberOfFATs 0
:G_NumberOfRootFs 0
:G_SmallSectors 0  # For our use SmallSectors is same as Max Sector Count, limit to 32MB disks


#
# Set the global variabes up as global.
#
G INT_ActiveDisk
G INT_ActiveSector
G G_FileName
G G_FileExtension
G G_FileAttributes
G G_FileReserved
G G_CreateTime10ms
G G_CreateDate
G G_LastAccessDate
G G_FirstClusterHigh
G G_LastModificationTime
G G_LastModificationDate
G G_FirstClusterLow
G G_FileSize
G G_RootDirSector
G G_CurrentDirBase
G G_SectorsPerFat
G G_StartOfFATs
G G_NumberOfFATs
G G_SmallSectors

#
# Most of these functions are ment to be called directly and do not call each other.
# So we can get away with some shared local variables.
:ReturnAddr 0
:MemoryPtr 0
:DiskID 0
:Entry 0
:WordIdx 0
:Scratch1 0
:Scratch2 0
:IsRootDirFlagIRD 0
# Vars for ParseFilePath
:ReturnPFP 0
:StrInPFP 0
:StrPtrPFP 0
:StrScratch1 0 0 0 0 0 0
:StrScratch2 0 0 0 0 0 0
:FormatFileName 0 0 0 0 0 0 0
:FormatPtr 0
:IsDIRFlag 0
:DirEntryInt 0
:MemoryBuffPtr 0
# ReadFile
:RecordNumber
:FileStructure
. FileStructure+40

:TestFileName "test.txt\0"
:Main . Main
@PUSH 0
@PUSH MemBuff02

@CALL INT_ReadBootSector

@PUSH MemBuff01
@PUSH TestFileName
@CALL ParseFilePath

@END
#

# Function ParseFilePath(MemBuff, StrPtr):[<255=error code | *FILE]
# Will step though the string, and identify DIR's part and Filename Part
# Will walk the Directory entries for DIR's and the evaluate FileName Part
:ParseFilePath
@POPI ReturnPFP
@POPI StrInPFP
@POPI MemoryBuffPtr
# Null the work space strings.
@PUSH 0 @POPI StrScratch1
@PUSH 0 @POPI StrScratch2
@MV2V StrInPFP StrPtrPFP
@PUSHII StrPtrPFP @AND 0xff # Put first character on stack
# Loop until full path has been parsed.

@WHILE_NOTZERO
    @PRT "Top of Path Parce While:" @StackDump
    @MA2V 0 IsDIRFlag    # Turn true is pattern is expected to be DIR

    @PUSH FormatFileName
    @PUSH StrPtrPFP
    @CALL INT_FileFormat   #Format user filename to 8.3 space filled format.
    @ADDI StrPtrPFP
    @POPI StrPtrPFP        # Add in length of string found.

    @PRT "FileName: " @PRTS FormatFileName @PRTNL
    :Break2
    @POPNULL
    @MA2V 0 DirEntryInt
    @PUSH 0
    #
    @WHILE_ZERO
        @POPNULL
        @PRT "\nTop of Match Strings While:" @StackDump
        @PUSHI MemoryBuffPtr   # Storage
        @PUSH 0                # Disk ID 0
	@PUSHI DirEntryInt     # Directory Sector start
	@PRT "\nBefore Sector Read:" @StackDump
	@CALL INT_ReadDIREntry
	@PRT "\nSector Read Return: " @StackDump
        @PUSH FormatFileName
	@PUSH G_FileName
	@PUSH 11
	@CALL strncmp
	@PRT "\nLooking for: "
	@PUSH FormatFileName
	@CALL PrintFileName
	@PRT " vs "
	@PUSH G_FileName
        @CALL PrintFileName
	@IF_ZERO
	   @PRT " MATCH FOUND." @StackDump
	   :BreakS
	   @POPNULL
	   @PUSH 1
	@ELSE
	   @PRT " No Match."
	   @POPNULL
	   @INCI DirEntryInt
	   @PUSH 0
	@ENDIF
     @ENDWHILE
     @PRT "Bottom of Outer While:" @StackDump     
@ENDWHILE
@PUSHI ReturnPFP
@END

:PrintFileName
@SWP
@ForIA2B PFNIdx 0 11
   @DUP @ADDI PFNIdx @PUSHS @AND 0xff
   @POPI PFNCharB
   @PRTS PFNCharB
@Next PFNIdx
@POPNULL
@RET
:PFNIdx 0
:PFNCharB 0

        

# Function INT_ReadDIREntry(MemoryPtr, DiskID, CurrentDirBase, Entry, IsRootDirFlag)
# Reads the file dir strucutre
:INT_ReadDIREntry
@POPI ReturnAddr
@POPI IsRootDirFlag
@POPI Entry
@POPI CurrentDirBase
@POPI DiskID
@POPI MemoryPtr

@PUSHI IsRootDirFlag
@IF_NOTZERO   #Is Root DIR
   @MV2V CurrentDirBase RootDirStartSector
   @PUSHI RootDirStartSector @PUSHI G_SectorsPerCluster @CALL MUL
   @POPI RootDirStartSector
   @PUSHI Entry 

    if IsRootDirFlag:
        # Calculate the starting Sector of the Root Directory
        root_dir_start_Sector = CurrentDirBase

        # Calculate the absolute sector number of the Root Directory
        root_dir_start_sector = root_dir_start_Sector * SectorsPerSector

        # Calculate the offset within the sector
        entry_offset = Entry * DirectoryEntrySize

        # Read the directory entry from the Root Directory
        read_from_disk(MemoryPtr, DiskID, root_dir_start_sector, entry_offset)
    else:
        # Calculate the starting cluster of the Sub-Directory
        sub_directory_start_cluster = CurrentDirBase

        # Traverse the cluster chain to find the Sub-Directory Sector
        sub_directory_Sector = find_sub_directory_Sector(sub_directory_start_cluster, Entry)

        if sub_directory_Sector is not None:
            # Calculate the absolute sector number of the Sub-Directory Sector
            sub_directory_sector = sub_directory_Sector * SectorsPerSector

            # Calculate the offset within the sector
            entry_offset = Entry * DirectoryEntrySize

            # Read the directory entry from the Sub-Directory Sector
            read_from_disk(MemoryPtr, DiskID, sub_directory_sector, entry_offset)
        else:
            # Entry not found in the Sub-Directory
            # Handle error or return None as needed

def find_sub_directory_Sector(start_cluster, entry):
    # Implement logic to traverse the cluster chain of the Sub-Directory
    # to find the Sector containing the directory entry at the specified index
    # You need to use the FAT entries to follow the cluster chain

    # Return the Sector number or None if the entry is not found

def read_from_disk(MemoryPtr, DiskID, sector, offset):
    # Implement a function to read data from the disk at the specified sector and offset
    # and store it in the MemoryPtr buffer


# Function INT_ReadDIREntry(MemoryPtr,DiskID,Entry, IsRootDirFlag)
# MemoryPtr points to a 512 byte buffer to hold the Disk Sector of the DIR strucutre.
# All the key values extracted will be saved global G_ variables, which should be
# copied off quickly.
:INT_ReadDIREntry
@POPI IsRootDirFlag
@POPI ReturnAddr
@POPI Entry
@POPI DiskID
@POPI MemoryPtr

@IF_EQ_VV INT_ActiveDisk DiskID
# No change.
@ELSE
   @DISKSELI DiskID
   @MA2V -1 INT_ActiveSector  # If we changed disk, then active Sector is not longer valid
   @MV2V DiskID INT_ActiveDisk
@ENDIF
#
# We find the Disk Sector by 'Entry/32'
# We find the entry in the Sector by Entry & 0x1f
#
@PUSHI Entry @RTR @RTR @RTR @RTR @RTR @ADDI G_CurrentDirBase
@IF_EQ_V INT_ActiveSector
# No Change
   @POPNULL
@ELSE
   @POPI INT_ActiveSector
   @PRT "Reading New Sector: " @PRTHEXI INT_ActiveSector
   @PUSHI IsRootDirFlag
   @IF_NOTZERO
      # Root Directories don't have to deal with Clusters, just add Offset to Base
      @DISKSEEKI INT_ActiveSector
      @DISKREADI MemoryPtr
   @ELSE
      @PUSHI INT_ActiveSector
      
@ENDIF
# Now Mod(Entry,32) will be which 32byte segment of Sector is current.
@PUSHI Entry @AND 0x0f
# Multiple that by 32 bytes to get of offset in the Disk Sector
@RTL @RTL @RTL @RTL @RTL
@ADDI MemoryPtr
# Now copy the 32 bytes that start there and put in the Global Variables
@ForIA2B WordIdx 0 16
   @DUP @ADDI WordIdx @ADDI WordIdx @PUSHS
   @PUSH G_FileName @ADDI WordIdx @ADDI WordIdx
   @POPS
@Next WordIdx
@POPNULL
@PUSHI ReturnAddr
@RET
#
#
#
# Function INT_ReadBootSector(MemoryPtr,DiskID)
:INT_ReadBootSector
@POPI ReturnAddr
@POPI MemoryPtr
@POPI DiskID
# If we're reading the BootSector its a good idea to make sure the global
# values about the disk are also updated.
@MV2V DiskID INT_ActiveDisk
@MA2V -1 INT_ActiveSector
@DISKSELI DiskID
@DISKSEEK 0
@DISKREADI MemoryPtr
# Fields we care about at this Point.
#
# BIOS Parameter Sector Fields
=BIOSSectorPerCluster 0x0d
=BIOSReservedSectors 0x0e
=BIOSNumberOfRootFs 0x0f
=BIOSNumberOfFATS 0x10
=BIOSSmallSectors 0x13
=BIOSSectorsPerFAT 0x16
#
# There are other BIOS Parameters that affect 'real' disks and should be confirmed
# to make sure the disk is 'valid' but we'll be foolishly trusting for now.

@PUSHI MemoryPtr
#
@DUP @ADD BIOSSectorPerCluster @PUSHS @AND 0ff
@POPI G_SectorsPerCluster
#
@DUP @ADD BIOSReservedSectors @PUSHS @AND 0xff
@POPI G_StartOfFATs
#
@DUMP @ADD BIOSNumberOfRootFs @PUSHS @AND 0xff
@POPI G_NumberOfRootFs
#
@DUP @ADD BIOSNumberOfFATS @PUSHS @AND 0xff
@POPI G_NumberOfFATs
#
@DUP @ADD BIOSSmallSectors @PUSHS
@POPI G_SmallSectors                   # as we are sticking to 'old' fat16, this is total number of sectors.
#
@DUP @ADD BIOSSectorsPerFAT @PUSHS
@POPI G_SectorsPerFAT
#
# We use the above to calculate the first sector of the Root Directory
@PUSHI G_SectorsPerFAT @PUSHI G_NumberOfFATs @CALL MUL
@ADDI G_StartOfFATs
@DUP @POPI G_CurrentDirBase @POPI G_RootDirSector
#

@POPNULL
@PUSHI ReturnAddr
@RET
#
#
:INT_CreateFileRecord(MemoryPtr)
# Function Copies the current Global varaibale to a FileStructure which will be used to manage that file.
:INT_CreateFileRecord
@POPI ReturnAddr
@POPI MemoryPtr
# The file Structure has most of the important DIR structure elements as well as a 32b location
# cursor for keeping track of the latest read/write location in the file.
#
@PUSHI G_FileName @PUSHI MemoryPtr @POPS
@PUSHI G_FileName+2 @PUSHI MemoryPtr @ADD 2 @POPS
@PUSHI G_FileName+2 @PUSHI MemoryPtr @ADD 4 @POPS
@PUSHI G_FileName+2 @PUSHI MemoryPtr @ADD 6 @POPS
#
@PUSHI G_FileExtension @PUSHI MemoryPtr @ADD 8 @POPS  # Odd format do handly 3 byte structure
@PUSHI G_FileExtension+1 @PUSHI MemoryPtr @ADD 9 @POPS
#
@PUSHI G_FileAttributes @AND 0xff @PUSHI MemoryPtr @ADD 11 @POPS
#
@PUSHI G_FileReserved @AND 0xff @PUSHI MemoryPtr @ADD 12 @POPS
#
@PUSHI G_CreateTime10ms @AND 0xff @PUSHI MemoryPtr @ADD 13 @POPS
#
@PUSHI G_CreateDate @PUSHI MemoryPtr @ADD 14 @POPS
#
@PUSHI G_LastAccessDate @PUSHI MemoryPtr @ADD 16 @POPS
#
@PUSHI G_FirstClusterHigh @PUSHI MemoryPtr @ADD 18 @POPS
#
@PUSHI G_LastModificationTime @PUSHI MemoryPtr @ADD 20 @POPS
#
@PUSHI G_LastModificationDate @PUSHI MemoryPtr @ADD 22 @POPS
#
@PUSHI G_FirstClusterLow @PUSHI MemoryPtr @ADD 24 @POPS
#
@PUSHI G_FileSize @PUSHI MemoryPtr @ADD 26 @POPS
@PUSHI G_FileSize+2 @PUSHI MemoryPtr @ADD 28 @POPS
#
# At location offset 30 will be the last Record Cursor
@PUSH 0 @PUSHI MemoryPtr @ADD 30 @POPS
# Location offset 32 will be the last Record Partial Cursor byte offset
@PUSH 0  @PUSHI MemoryPtr @ADD 32 @POPS
# Location offset 34 will be the last read 
@PUSH 0  @PUSHI MemoryPtr @ADD 32 @POPS
#
# 
@PUSHI ReturnAddr
@RET

# Function INT_FileFormat(InFileStrPtr,OutFormatedFilePtr[12 byte buffer])
# ReForamats /filename[/filename] strings into space filled "FILENAME.EXT" format.
# Returns [ Len of InString Used ]
#
:INT_FileFormat
@POPI ReturnFF
@POPI InStrPtrFF
@POPI OutStrPtrFF
# Fill Output string will all spaces
@ForIA2B IndexFF 0 11
   @PUSH " \0"
   @PUSHI OutStrPtrFF @ADD IndexFF
   @POPS
@Next IndexFF
@MA2V 0 LenCountFF
@PUSHII InStrPtrFF @AND 0xff
@IF_EQ_A "/\0"      # Handle case of string starting with "/"
   @INCI InStrPtrFF
   @INCI LenCountFF
@ENDIF
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   @PUSHII InStrPtrFF @AND 0xff
   @SWITCH
   @CASE "/\0"          # Handle '/', end filename scan
      @INCI InStrPtrFF
      @INCI LenCountFF
      @PUSH 0     # Break the While Loop
      @CBREAK
   @CASE ".\0"          # Handle '.', continue scan
      @POPNULL
      @INCI InStrPtrFF
      @INCI LenCountFF
      @PUSH 1
      @CBREAK
   @CASE 0              # Handle EOS, end scan
      @PUSH 0
      @CBREAK
   @CDEFAULT
      @AND 0xdf   # Change Lowercase to Uppercase
      @OR "\0 "   # Replace the null with a space
      @POPII OutStrPtrFF
      @INCI InStrPtrFF
      @INCI LenCountFF
      @INCI OutStrPtrFF
      @PUSH 1
   @CBREAK
   @ENDCASE
@ENDWHILE
@POPNULL
@PUSHI LenCountFF
@PUSHI ReturnFF
@RET
:ReturnFF 0
:InStrPtrFF 0
:OutStrPtrFF 0
:LenCountFF 0
#
# Function INT_FindFileName(FileInStr, DirStart, DiskID, MemoryStore)
#
:INT_FindFileName
@POPI ReturnFFN
@POPI MemStFFN
@POPI DiskIDFFN
@POPI DirStart
@POPI FileInFFN
@IF_EQ_VV DirStart G_RootDirSector   # Set Flag because some rules are diffrent for ROOT dir
   @MA2V 1 IsRootFFN
@ELSE
   @MA2V 0 IsRootFFN
@ENDIF
@MA2V 0 RecIDXFFN
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @PUSH MemStFFN
   @PUSHI DiskIDFFN
   @PUSHI RecIDXFFN
   @CALL INT_ReadDIREntry
   #
   @PUSHI FileInFFN
   @PUSHI G_FileName
   @PUSH 11
   @CALL strncmp       # Compair the Filename in Sector with search string
   @IF_ZERO
      # Filename Match Found.
      @PUSH 1
   @ELSE
      @PUSH 0
      @IF_EQ_V G_FirstClusterLow    # We only handle small disks so only use first cluster low
         # End of Dir List, and didn't find match.
	 @PUSH 2    # Code 2 is Not-Found result
      @ELSE
          @PUSHI G_FileName @AND 0xff  #Look at first character.
	  @IF_EQ_A 0x00
	     # Another way End Of DIR is marked.
	     @POPNULL @POPNULL
	     @PUSH 2
	  @ELSE
             @POPNULL
	  @ENDIF
      @ENDIF
   @ENDIF
   @INCI RecIDXFFN
@ENDWHILE
@IF_EQ_A 1
   @PRTS G_FileName @PRTNL " found."
@ELSE
   @IF_EQ_A 2
      @PRT "No Matching File"
   @ENDIF
@ENDIF
@PUSHI ReturnFFN
@RET
   


#
#
# Function INT_ReadFileRecord(MemeoryPtr, FileStructure, RecordNumber)
# Reads the File pointed to by FileStructure's RecordNumber and store it in MemoryPtr
:INT_ReadFileRecord
@POPI ReturnAddr
@POPI RecordNumber
@POPI FileStructure
@POPI MemoryPtr

# If RecordNumber == FS.LastSectorCursor 

# Get fat_offset=(FirstCluster - 2) * 2
@PUSHI FileStructure @ADD 18 @PUSHS
@SUB 2
@RTL
@PRT "Unfinished"
@END

:MemBuff01
. MemBuff01+512
:MemBuff02
. MemBuff02+512
0 0 0


. Main




#struct dir_entry {
#  uint8_t filename[8];
#  uint8_t file_extension[3];
#  uint8_t file_attributes;
#  uint8_t reserved;
#  uint8_t create_time_10ms;
#  uint16_t create_date;
#  uint16_t last_access_date;
#  uint16_t first_cluster_high;
#  uint16_t last_modification_time;
#  uint16_t last_modification_date;
#  uint16_t first_cluster_low;
# uint32_t file_size;
#};
#
# Boot Sector structures
# Offset | Size | Description
#------- | ---- | -----------
#  0     | 3 | Jump instruction (usually `EB 3C 90`)
#  3     | 8 | OEM name
#  11    | 2 | Bytes per sector
#  13    | 1 | Sectors per cluster
#  14    | 1 | Reserved sectors
#  15    | 1 | Number of FATs
#  16    | 2 | Root directory entries
#  18    | 2 | Total sectors (16-bit)
#  20    | 2 | Sectors per FAT
#  22    | 2 | Hidden sectors
#  24    | 2 | Drive number
#  26    | 1 | Extended boot signature (usually `0x29`)
#  27    | 1 | Volume serial number
#  28    | 12 | Volume label
#  40    | 8 | File system type (usually `FAT16`)
#  48    | 446 | Bootstrap code
# 510    | 2 | End of sector marker (usually `0xAA55`)
#
# From example DISK01
# 0xb    :  00,02    Word: Bytes Per Sector (512=0x0200) 
# 0xd    :  04       Byte: Sectors Per Cluster
# 0xe    :  04,00    Word: Reserved Sectors ( 4 ) G_BIOSReservedSectors
# 0x10   :  02       Byte: Number of FAT tables (2)
# 0x11   :  00,02    Word: Max Entries in ROOT Dir (512)
# 0x13   :  00,80    Word: Number Sectors (0x8000)
# 0x15   :  f8       Byte: Media Type        N.A.
# 0x16   :  20,00    Word: Sectors Per FAT (0x20)
# 0x18   :  20,00    Word: Sectors Per Track N.A. (0x20)
# 0x1A   :  02,00    Word: Number of Heads N.A. (0x2)
# 0x1C   :  0,0,0,0  DWord: Hidden Sectors. N.A. ($$$00)
#
# From this we can determin the values we should be calculating
# G_FatStartSector = Reserved Sectors + 1
# G_RootDirSector = Reserved Sectors + (Number of FAT Tables) * ( Sectors Per FAT )
#       0x44     = 4                +      2                 *   0x20
