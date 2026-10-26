! EXEC_MACROS_SEEN
MF EXEC_MACROS_SEEN 1

# ExecCall child-exit interface.  The target must have been launched by
# ExecCall; this gateway does not return.  It leaves Status on the hardware
# stack for the resident MS 255 loader, which reloads the launcher.
=EXEC_LOADER_MS 255
=EXEC_STAGE2_RETURN_ENTRY 0x0e00
M ExecExit @PUSH %1 @FJMP EXEC_LOADER_MS EXEC_STAGE2_RETURN_ENTRY
