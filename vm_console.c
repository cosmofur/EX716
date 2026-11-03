#include "vm_console.h"

#include <stdarg.h>
#include <string.h>

void vm_console_init(VMConsole *console)
{
    console->guest_mode = VM_CONSOLE_GUEST_DIRECT;
    console->guest_start = 0;
    console->guest_length = 0;
    console->guest_overflow = 0;
    console->video_suspended = 0;
}

void vm_console_set_guest_mode(VMConsole *console, VMConsoleGuestMode mode)
{
    console->guest_mode = mode;
}

static void vm_console_buffer_guest(VMConsole *console,
                                    const unsigned char *data, size_t length)
{
    size_t i;
    for (i = 0; i < length; ++i) {
        if (console->guest_length == VM_CONSOLE_GUEST_BUFFER_SIZE) {
            console->guest_start = (console->guest_start + 1u) %
                                   VM_CONSOLE_GUEST_BUFFER_SIZE;
            --console->guest_length;
            ++console->guest_overflow;
        }
        console->guest_buffer[(console->guest_start + console->guest_length) %
                              VM_CONSOLE_GUEST_BUFFER_SIZE] = data[i];
        ++console->guest_length;
    }
}

void vm_console_write(VMConsole *console, VMConsoleChannel channel,
                      const void *data, size_t length)
{
    FILE *stream;
    if (length == 0) return;
    if (channel == VM_CONSOLE_GUEST_TEXT &&
        console->guest_mode == VM_CONSOLE_GUEST_BUFFERED) {
        vm_console_buffer_guest(console, data, length);
        return;
    }
    if (channel == VM_CONSOLE_VIDEO && console->video_suspended) return;
    stream = (channel == VM_CONSOLE_HOST_DIAGNOSTIC ||
              channel == VM_CONSOLE_DEBUGGER) ? stderr : stdout;
    (void)fwrite(data, 1, length, stream);
}

void vm_console_printf(VMConsole *console, VMConsoleChannel channel,
                       const char *format, ...)
{
    char buffer[128];
    int length;
    va_list args;
    va_start(args, format);
    length = vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    if (length <= 0) return;
    if ((size_t)length >= sizeof(buffer)) length = (int)sizeof(buffer) - 1;
    vm_console_write(console, channel, buffer, (size_t)length);
}

size_t vm_console_drain_guest(VMConsole *console, void *out, size_t capacity)
{
    size_t copied = console->guest_length < capacity ? console->guest_length : capacity;
    size_t i;
    unsigned char *bytes = out;
    for (i = 0; i < copied; ++i) {
        bytes[i] = console->guest_buffer[(console->guest_start + i) %
                                         VM_CONSOLE_GUEST_BUFFER_SIZE];
    }
    console->guest_start = (console->guest_start + copied) % VM_CONSOLE_GUEST_BUFFER_SIZE;
    console->guest_length -= copied;
    return copied;
}

size_t vm_console_guest_length(const VMConsole *console)
{
    return console->guest_length;
}

void vm_console_flush_guest(VMConsole *console, FILE *stream)
{
    unsigned char buffer[256];
    size_t count;
    while ((count = vm_console_drain_guest(console, buffer, sizeof(buffer))) != 0) {
        (void)fwrite(buffer, 1, count, stream);
    }
}

unsigned long vm_console_guest_overflow(const VMConsole *console)
{
    return console->guest_overflow;
}

void vm_console_suspend_video(VMConsole *console)
{
    console->video_suspended = 1;
}

void vm_console_resume_video(VMConsole *console)
{
    console->video_suspended = 0;
}
