#include "vm_console.h"

#include <stdarg.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

static void vm_console_video_viewport(VMConsole *console)
{
    struct winsize size;
    memset(&size, 0, sizeof(size));
    if (ioctl(fileno(stdout), TIOCGWINSZ, &size) == 0) {
        console->video_rows = size.ws_row;
        console->video_columns = size.ws_col;
        console->video_pixel_width = size.ws_xpixel;
        console->video_pixel_height = size.ws_ypixel;
    }
}

void vm_console_init(VMConsole *console)
{
    console->guest_mode = VM_CONSOLE_GUEST_DIRECT;
    console->guest_start = 0;
    console->guest_length = 0;
    console->guest_overflow = 0;
    console->video_suspended = 0;
    console->video_display_active = 0;
    console->video_saved_guest_mode = VM_CONSOLE_GUEST_DIRECT;
    console->video_owns_guest_buffer = 0;
    console->video_frames = 0;
    console->video_rows = 0;
    console->video_columns = 0;
    console->video_pixel_width = 0;
    console->video_pixel_height = 0;
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

void vm_console_flush_video(void)
{
    (void)fflush(stdout);
}

int vm_console_video_display_start(VMConsole *console)
{
    if (console->video_display_active) return VM_CONSOLE_VIDEO_DISPLAY_OK;
    if (!isatty(fileno(stdout))) return VM_CONSOLE_VIDEO_DISPLAY_NOT_TTY;
    vm_console_video_viewport(console);
    console->video_saved_guest_mode = console->guest_mode;
    console->video_owns_guest_buffer =
        console->guest_mode == VM_CONSOLE_GUEST_DIRECT;
    if (console->video_owns_guest_buffer)
        vm_console_set_guest_mode(console, VM_CONSOLE_GUEST_BUFFERED);
    /* Save the caller's normal cursor, then establish a deterministic origin.
     * CUP home is intentionally used instead of assuming SIXEL preserves its
     * cursor position; Windows Terminal visibly supports this sequence. */
    vm_console_write(console, VM_CONSOLE_VIDEO, "\033[s\033[H", 6);
    vm_console_flush_video();
    console->video_display_active = 1;
    console->video_frames = 0;
    return VM_CONSOLE_VIDEO_DISPLAY_OK;
}

int vm_console_video_display_prepare(VMConsole *console, unsigned pixel_width,
                                     unsigned pixel_height)
{
    if (!console->video_display_active) return VM_CONSOLE_VIDEO_DISPLAY_OK;
    vm_console_video_viewport(console);
    /* Pixel dimensions are optional in many pty implementations. When they
     * are available, reject frames that would necessarily exceed the viewport
     * rather than unexpectedly scrolling normal-screen history. */
    if ((console->video_pixel_width != 0 &&
         pixel_width > console->video_pixel_width) ||
        (console->video_pixel_height != 0 &&
         pixel_height > console->video_pixel_height))
        return VM_CONSOLE_VIDEO_DISPLAY_TOO_SMALL;
    if (console->video_frames != 0)
        vm_console_write(console, VM_CONSOLE_VIDEO, "\033[H", 3);
    ++console->video_frames;
    return VM_CONSOLE_VIDEO_DISPLAY_OK;
}

void vm_console_video_display_stop(VMConsole *console)
{
    if (!console->video_display_active) return;
    /* Restore the normal-screen cursor saved at start. Guest text emitted
     * while active is released only after display ownership ends. */
    vm_console_write(console, VM_CONSOLE_VIDEO, "\033[u", 3);
    vm_console_flush_video();
    console->video_display_active = 0;
    if (console->video_owns_guest_buffer) {
        vm_console_set_guest_mode(console, VM_CONSOLE_GUEST_DIRECT);
        vm_console_flush_guest(console, stdout);
        (void)fflush(stdout);
    }
    console->video_owns_guest_buffer = 0;
}
