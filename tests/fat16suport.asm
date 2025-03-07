################
# Fat16 Support
# Define Fat16 Structures here.
M LocalVar = %1 Var%2 @PUSHLOCALI Var%2
M RestoreVar @POPLOCAL Var%1
#  struct BootRecord {
#     uint8_t jumpInstruction[3]; // Jump instruction
#     char filesystemName[8];      // OEM Name
#     uint16_t bytesPerSector;      // Bytes per sector
#     uint8_t sectorsPerCluster;    // Sectors per cluster
#     uint16_t reservedSectors;     // Reserved sectors
#     uint8_t numberOfFATs;         // Number of FATs
#     uint16_t rootDirEntries;      // Number of root directory entries
#     uint16_t totalSectors16;      // Total sectors (if < 65536)
#     uint8_t mediaDescriptor;      // Media descriptor
#     uint16_t FATSize16;           // Size of each FAT
#     uint16_t sectorsPerTrack;     // Sectors per track
#     uint16_t numberOfHeads;       // Number of heads
#     uint32_t hiddenSectors;       // Hidden sectors
#     uint32_t totalSectors32;      // Total sectors (if > 65536)
#     // Additional fields for FAT32 can be ignored
# };
########### Boot Record, Offsets from start buffer.
=BRofsjumpInstruction 0                              # 3 bytes
=BRofsfilesystemName        BRofsjumpInstruction+3   # 8 Bytes
=BRofsbytesPerSector        BRofsfilesystemName+8    # 2 bytes
=BRofssectorsPerCluster     BRofsbytesPerSector+2    # 1 bytes
=BRofsreservedSectors       BRofssectorsPerCluster+1 # 2 bytes
=BRofsnumberOfFATs          BRofsreservedSectors+2   # 1 bytes
=BRofsrootDirEntries        BRofsnumberOfFATs+1      # 2 bytes
=BRofstotalSectors16        BRofsrootDirEntries+2    # 2 bytes
=BRofsmediaDescriptor       BRofstotalSectors16+2    # 1 byte
=BRofsFATSize16             BRofsmediaDescriptor+1   # 2 bytes
=BRofssectorsPerTrack       BRofsFATSize16+2         # 2 bytes
=BRofsnumberOfHeads         BRofssectorsPerTrack+2   # 2 bytes
=BRofshiddenSectors         BRofsnumberOfHeads+2     # 4 bytes
=BRofstotalSectors32        BRofshiddenSectors+2     # 4 bytes
=BRofsSize                  BRofstotalSectors32      # 0 bytes
###########################################################################
#           Directory Structure
# struct RootDirectoryEntry {
#     char filename[8];        // File name
#     char extension[3];       // File extension
#     uint8_t attributes;      // File attributes
#     uint16_t reserved;       // Reserved
#     uint16_t time;           // Time created
#     uint16_t date;           // Date created
#     uint16_t startCluster;   // Starting cluster
#     uint32_t fileSize;       // File size
# };
=DSofsStart 0
=DSofsFilename       0x0         # 8 bytes
=DSofsExtension      0x8         # 3 bytes
=DSofsAttributes     0x0b        # 1 byte
=DSofsCreateTime     0x0d        # 2 bytes
=DSofsCreateDate     0x10        # 2 bytes
=DSofsAccessDate     0x12        # 2 bytes
=DSofsWriteTime      0x16        # 2 bytes
=DSofsWriteDate      0x18        # 2 bytes
=DSofsStartCluster   0x1A        # 2 bytes (low word, extended disks also use high wod at 0x14)
=DSofsStartHigh      0x14        # 2 bytes
=DSofsFileSize       0x1c        # 4 bytes (32 bit file size)
=DSofsSize           0x20        # Record size is 32 bytes
#############################################################################
#         File Pointer Structure
=FPofsFileSize          0       # To save time we also keep track of filesize as sector count and offset
=FPofsFSSector          4       # equal to bits 10-26 in FileSize (shifted right 9 times) (Alway ^'s to EOF)
=FPofsFSOffset          6       # equal to bits 0-9 of FileSize (0-511, whole sectors will be '0')
=FPofsFirstSector       8       # First HW sector in File. (For returning to begining of file)
=FPofsDirRecSector      10      # HW Sector of Directory Entry
=FPofsDirRecOffset      12      # Offset in sector for Dir Entry
=FPofsHWSector          14      # HW Sector ID of current Read/Insert point. (anywhere on disk)
=FPofsLogicSector       16      # Logical Sector ID Read/Insert Point (Relative to filesize)
=FPofsOffset            18      # Offset with the current HW/Logival Sector where Read/Insert point is.
=FPofsDiskID            20      # HW Disk ID
=FPofsState             22      # -1 means 'stale' so Buffer will not be trusted without re-read.
=FPofsBuffer            24
=FPofsSize              FPofsBuffer+514

