################
# Fat16 Support
# Define Fat16 Structures here.
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
=DSofsfilename       DSofsStart         # 8 bytes
=DSofsextension      DSofsStart+0x8     # 3 bytes
=DSofsattributes     DSofsStart+0xb     # 1 byte
=DSofsreserved       DSofsStart+0xc     # 2 bytes
=DSofsCentSecond     DSofsStart+0xd     # 1 byte
=DSofstime           DSofsStart+0xe     # 2 bytes
=DSofsdate           DSofsStart+0x10    # 2 bytes
=DSofsstartCluster   DSofsStart+0x1a    # 2 bytes
=DSofsfileSize       DSofsStart+0x1c    # 4 bytes
=DSofsSize           DSofsStart+0x20    # 32 bytes per record
#############################################################################
#         File Pointer Structure
#struct FilePointer {
#    uint16_t currentCluster;  // Current cluster
#    uint32_t currentSize;     // Current size of the file
#    uint8_t buffer[512];      // Buffer for partial writes
#    uint16_t bufferSize;      // Size of the buffer used
#    uint8_t diskID;           // Identifier for the disk (0 for Disk 1, 1 for Disk 2, etc.)
#};
=FPofscurrentCluster 0                              # 2 bytes
=FPofscurrentSize         FPofscurrentCluster+2     # 4 bytes
=FPofsbuffer              FPofscurrentSize+4        # 512 bytes
=FPofsbufferSize          FPofsbuffer+512           # 2 byte
=FPofsdiskID              FPofsbufferSize+2         # 1 byte
=FPofsSize                FPofsdiskID+2             # 0 bytes
