#ifndef VM_CONSOLE_H
#define VM_CONSOLE_H

#include <stddef.h>
#include <stdio.h>

#define VM_CONSOLE_GUEST_BUFFER_SIZE 8192u

typedef enum {
    VM_CONSOLE_GUEST_TEXT,
    VM_CONSOLE_HOST_DIAGNOSTIC,
    VM_CONSOLE_VIDEO,
    VM_CONSOLE_DEBUGGER
} VMConsoleChannel;

typedef enum {
    VM_CONSOLE_GUEST_DIRECT,
    VM_CONSOLE_GUEST_BUFFERED
} VMConsoleGuestMode;

typedef struct {
    VMConsoleGuestMode guest_mode;
    unsigned char guest_buffer[VM_CONSOLE_GUEST_BUFFER_SIZE];
    size_t guest_start;
    size_t guest_length;
    unsigned long guest_overflow;
    int video_suspended;
} VMConsole;

void vm_console_init(VMConsole *console);
void vm_console_set_guest_mode(VMConsole *console, VMConsoleGuestMode mode);
void vm_console_write(VMConsole *console, VMConsoleChannel channel,
                      const void *data, size_t length);
void vm_console_printf(VMConsole *console, VMConsoleChannel channel,
                       const char *format, ...);
size_t vm_console_drain_guest(VMConsole *console, void *out, size_t capacity);
size_t vm_console_guest_length(const VMConsole *console);
void vm_console_flush_guest(VMConsole *console, FILE *stream);
unsigned long vm_console_guest_overflow(const VMConsole *console);
void vm_console_suspend_video(VMConsole *console);
void vm_console_resume_video(VMConsole *console);

#endif
