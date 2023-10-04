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
:INT_ActiveBlock -1      # What Block in disk
:INT_DirListStart -1     # First Block of current DIR structure.
:G_FileName "12345678"
:G_FileExtension "123"
:G_FileAttributes b0
:G_FileReserved b0
:G_CreateTime10ms b0
:G_CreateDate 0
:G_LastAccessDate 0
:G_FirstClusterHigh 0
:G_LastModificationTime 0
:G_LastModificationDate 0
:G_FirstClusterLow 0
:G_FileSize 0 0
:G_RootDirBlock 0
:G_CurrentDirBase 0
:G_SectorsPerFat 0
:G_NumberOfFats 0
:G_FatStartSector 0
#
# Set the global variabes up as global.
#
G INT_ActiveDisk
G INT_ActiveBlock
G G_FileExtension G G_FileAttributes G G_FileReserved
G G_CreateTime10ms G G_CreateDate G G_LastAccess
G G_FirstClusterHigh G G_LastModificationTime
G G_LastModificationDate G G_FirstClusterLow
G G_FileSize G G_RootDirBlock G G_CurrentDirBase 0
G G_SectorsPerFat G G_NumberOfFats G G_FatStartSector
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
# Vars for ParseFilePath
:ReturnPFP 0
:StrInPFP 0
:StrPtrPFP 0
:StrScratch1 0 0 0 0 0 0
:StrScratch2 0 0 0 0 0 0
:FormatFileName 0 0 0 0 0 0
:FormatPtr 0
:IsDIRFlag 0
:DirEntryInt 0
# ReadFile
:RecordNumber
:FileStructure
. FileStructure+40

:TestFileName "test.txt\0"
:Main . Main
@PUSH 0
@PUSH MemBuff02

@CALL INT_ReadBootSector

@PUSH TestFileName
@CALL ParseFilePath

@END
#

# Function ParseFilePath(StrPtr):[<255=error code | *FILE]
# Will step though the string, and identify DIR's part and Filename Part
# Will walk the Directory entries for DIR's and the evaluate FileName Part
:ParseFilePath
@POPI ReturnPFP
@POPI StrInPFP
# Null the work space strings.
@PUSH 0 @POPI StrScratch1
@PUSH 0 @POPI StrScratch2
@MV2V StrInPFP StrPtrPFP
@PUSHII StrPtrPFP @AND 0xff # Put first character on stack
# Loop until full path has been parsed.
@WHILE_NOTZERO
    @MA2V 0 IsDIRFlag    # Turn true is pattern is expected to be DIR
    @ForIA2B FormatPtr 0 11 # Fill 8.3 Formated fileename with spaces.
       @PUSH " \0"
       @PUSH FormatPtr
       @ADD FormatFileName
       @POPS
    @Next FormatPtr
    @MA2V FormatFileName FormatPtr    # Set Pointer to start of filename buffer
    @WHILE_NOTZERO     # Same test as outer loop.
       @IF_EQ_A "/\0"   # If First character is '/' then skip it.
          @POPNULL # End of block
	  @PUSH 0
	  @MA2V 1 IsDIRFlag# If it ends in a '/' it better be a DIR
       @ELSE
          @IF_EQ_A ".\0"   # When we see the '.' move the Pointer to Extenion part
	     @PUSH FormatFileName
	     @ADD 8
	     @POPI FormatPtr
	     # We don't save the '.' just skip forward now.
	  @ELSE
             @OR 0x2000     # Replace 0 in high byte with space hex20
             @POPII FormatPtr
             @INCI FormatPtr
	  @ENDIF
        @ENDIF
	@POPNULL
	@INCI StrPtrPFP
	@PUSHII StrPtrPFP @AND 0xff   # Get next character
     @ENDWHILE
     @POPNULL
     @MA2V 0 DirEntryInt
     @PUSH 0
     @WHILE_ZERO
        @PUSH MemBuff01
        @PUSH 0          # Disk ID 0
	@PUSH DirEntryInt
	@CALL INT_ReadDIREntry
        @PUSH FormatFileName
	@PUSH G_FileName
	@PUSH 11
	@CALL strncmp
	@PRT "String Compair Filenames " @PRTS G_FileName @PRT " and " @PRTS FormatFileName @PRT " is :" @PRTTOP
	@IF_ZERO
	   @POPNULL
	   @PUSH 1
	@ENDIF
     @ENDWHILE
@ENDWHILE
@END
	

        




# Function INT_ReadDIREntry(MemoryPtr,DiskID,Entry)
# MemoryPtr points to a 512 byte buffer to hold the Disk Block of the DIR strucutre.
# All the key values extracted will be saved global G_ variables, which should be
# copied off quickly.
:INT_ReadDIREntry
@POPI ReturnAddr
@POPI MemoryPtr
@POPI DiskID
@POPI Entry
@IF_EQ_VV INT_ActiveDisk DiskID
# No change.
@ELSE
   @DISKSELI DiskID
   @MA2V -1 INT_ActiveBlock  # If we changed disk, then active block is not longer valid
   @MV2V DiskID INT_ActiveDisk
@ENDIF
#
# We find the Disk Block by 'Entry/32'
# We find the entry in the block by Mod(Entry,32)
#
@PUSHI Entry @RTR @RTR @RTR @RTR @RTR
@IF_EQ_V INT_ActiveBlock
# No Change
@ELSE
   @POPI INT_ActiveBlock
   @ADDI G_CurrentDirBase
   @DISKSEEKI INT_ActiveBlock
   @DISKREADI MemoryPtr
@ENDIF
# Now Mod(Entry,32) will be which 32byte segment of block is current.
@PUSHI Entry @AND 0x0f
# Multiple that by 32 bytes to get of offset in the Disk block
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
# This will set the G_RootDirBlock to the Root Directory based on the Boot Sector
:INT_ReadBootSector
@POPI ReturnAddr
@POPI MemoryPtr
@POPI DiskID
# If we're reading the BootSector ist a good idea to make sure the global
# values about the disk are also updated.
@MV2V DiskID INT_ActiveDisk
@MA2V -1 INT_ActiveBlock
@DISKSELI DiskID
@DISKSEEK 0
@DISKREADI MemoryPtr
# Fields we care about at this Point.
#
# Get from Boot structure the reserved_sectors + number_of_fasts*sectors_per_fat
#
@PUSHI MemoryPtr
@DUP @ADD 14          # Offset of Reserved Sectors
@PUSHS @AND 0xff      # Byte Value
@POPI Scratch1
#
@DUP @ADD 15          # Number of FATs
@PUSHS @AND 0xff      # Byte Value
#
@DUP @ADD 20          # Sectors per FAT
@PUSHS
#
@CALL MUL
@ADDI Scratch1       # Result is now Root Dir Sector
@POPI G_CurrentDirBase
#
@DUP @ADD 20         # Where the FAT tables start
@PUSHS
@POPI G_SectorsPerFat
#
@DUP @ADD 15
@PUSHS
@POPI G_NumberOfFats # How many fat table records.
#
# We have to calculate the FatStartSector as its not given on its own.
@DUP 14
@PUSHS @AND 0xff     # number Reserved Sectors
@PUSHI G_NumberOfFats
@PUSHI G_SectorsPerFat
@CALL MUL            # FatStartSector=Reserved+NumberOfFats*SectorsPerFat
@POPI G_FatStartSector
@POPNULL
@PUSHI ReturnAddr
@RET
#
#
:INT_CreateFileRecord(MemoryPtr)
# Copies the current Global varaibale to a FileStructure which will be used to manage that file.
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
