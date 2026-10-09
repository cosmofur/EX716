#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>

/* The terminal emulator exposes only these two mode bits. The initial state
   matches the ordinary cooked terminal mode assumed by the EX716 console. */
static int __ex716_tty_flags = ICANON | ECHO;

extern int __EX716_TTY_RAW(void);
extern int __EX716_TTY_COOKED(void);
extern int __EX716_TTY_ECHO(void);
extern int __EX716_TTY_NOECHO(void);

int tcgetattr(int file_descriptor, struct termios *settings) {
        if (file_descriptor != STDIN_FILENO || !settings)
                return -1;
        settings->c_iflag = 0;
        settings->c_oflag = 0;
        settings->c_cflag = 0;
        settings->c_lflag = (tcflag_t)__ex716_tty_flags;
        return 0;
}

int tcsetattr(int file_descriptor, int action,
              const struct termios *settings) {
        int flags;

        if (file_descriptor != STDIN_FILENO || action != TCSANOW || !settings)
                return -1;
        flags = (int)settings->c_lflag;
        if (flags & ~(ICANON | ECHO))
                return -1;

        if (flags & ICANON)
                __EX716_TTY_COOKED();
        else
                __EX716_TTY_RAW();
        if (flags & ECHO)
                __EX716_TTY_ECHO();
        else
                __EX716_TTY_NOECHO();
        __ex716_tty_flags = flags;
        return 0;
}

/* EX716's maximum supported integer width is 32 bits.  Hex conversion uses
   nibbles; decimal conversion uses bounded subtraction against powers of ten
   instead of invoking the comparatively expensive 32-bit divide helper once
   per digit. */
static const unsigned long __ex716_pow10[] = {
        1000000000UL, 100000000UL, 10000000UL, 1000000UL, 100000UL,
        10000UL, 1000UL, 100UL, 10UL, 1UL
};

struct __ex716_sink {
        char *destination;
        size_t size;
        FILE *stream;
        int unbounded;
        int count;
        int failed;
};

#define F_LEFT  1
#define F_PLUS  2
#define F_SPACE 4
#define F_ZERO  8
#define F_ALT   16

static void __ex716_put(struct __ex716_sink *sink, int character) {
        if (sink->count >= 32767) {
                sink->failed = 1;
                return;
        }
        if (!sink->destination) {
                if (sink->stream &&
                    fputc(character & 0xff, sink->stream) == EOF)
                        sink->failed = 1;
        } else if (sink->unbounded ||
                   (sink->size && (unsigned int)sink->count < sink->size - 1)) {
                sink->destination[sink->count] = (char)character;
        }
        ++sink->count;
}

static void __ex716_repeat(struct __ex716_sink *sink, int character, int n) {
        while (n-- > 0 && !sink->failed)
                __ex716_put(sink, character);
}

static int __ex716_number(char *buffer, unsigned long value, int base,
                          int uppercase) {
        char reverse[11];
        int digit;
        int count;
        int started;
        int i;

        count = 0;
        if (base == 16 || base == 8) {
                int shift;
                unsigned long mask;

                shift = base == 16 ? 4 : 3;
                mask = base == 16 ? 15UL : 7UL;
                do {
                        digit = (int)(value & mask);
                        reverse[count++] = (char)(digit < 10 ? '0' + digit :
                                (uppercase ? 'A' : 'a') + digit - 10);
                        value >>= shift;
                } while (value);
        } else {
                started = 0;
                for (i = 0; i < 10; ++i) {
                        digit = 0;
                        while (value >= __ex716_pow10[i]) {
                                value -= __ex716_pow10[i];
                                ++digit;
                        }
                        if (digit || started || i == 9) {
                                reverse[count++] = (char)('0' + digit);
                                started = 1;
                        }
                }
        }
        for (i = 0; i < count; ++i)
                buffer[i] = base == 10 ? reverse[i] : reverse[count - i - 1];
        buffer[count] = 0;
        return count;
}

static int __ex716_parse_number(const char **format) {
        int value;
        int digit;

        value = 0;
        while (**format >= '0' && **format <= '9') {
                digit = *(*format)++ - '0';
                if (value > 3276 || (value == 3276 && digit > 7))
                        return -1;
                value = value * 10 + digit;
        }
        return value;
}

static void __ex716_field(struct __ex716_sink *sink, const char *text,
                          int length, int width, int flags, int precision,
                          int numeric, char sign, const char *prefix) {
        int prefix_length;
        int zeroes;
        int padding;
        int i;

        prefix_length = 0;
        if (prefix)
                while (prefix[prefix_length])
                        ++prefix_length;
        zeroes = 0;
        if (numeric && precision > length)
                zeroes = precision - length;
        padding = width - length - zeroes - prefix_length - (sign != 0);
        if (padding < 0)
                padding = 0;
        if ((flags & F_ZERO) && !(flags & F_LEFT) && precision < 0 && numeric) {
                zeroes += padding;
                padding = 0;
        }
        if (!(flags & F_LEFT))
                __ex716_repeat(sink, ' ', padding);
        if (sign)
                __ex716_put(sink, sign);
        for (i = 0; i < prefix_length; ++i)
                __ex716_put(sink, prefix[i]);
        __ex716_repeat(sink, '0', zeroes);
        for (i = 0; i < length; ++i)
                __ex716_put(sink, text[i]);
        if (flags & F_LEFT)
                __ex716_repeat(sink, ' ', padding);
}

int __ex716_vformat(char *destination, size_t size, int unbounded,
                    FILE *stream, const char *format, va_list arguments) {
        struct __ex716_sink sink;
        char digits[12];
        const char *text;
        const char *prefix;
        char sign;
        int flags;
        int width;
        int precision;
        int length;
        int conversion;
        int modifier;
        int value;
        int signed_value;
        unsigned int unsigned_value;
        unsigned long wide_value;
        long signed_long;
        int base;

        sink.destination = destination;
        sink.size = size;
        sink.stream = stream;
        sink.unbounded = unbounded;
        sink.count = 0;
        sink.failed = 0;
        while (*format && !sink.failed) {
                if (*format != '%') {
                        __ex716_put(&sink, (unsigned char)*format++);
                        continue;
                }
                ++format;
                if (*format == '%') {
                        ++format;
                        __ex716_put(&sink, '%');
                        continue;
                }

                flags = 0;
                for (;;) {
                        if (*format == '-') flags |= F_LEFT;
                        else if (*format == '+') flags |= F_PLUS;
                        else if (*format == ' ') flags |= F_SPACE;
                        else if (*format == '0') flags |= F_ZERO;
                        else if (*format == '#') flags |= F_ALT;
                        else break;
                        ++format;
                }
                if (*format == '*') {
                        width = va_arg(arguments, int);
                        ++format;
                        if (width < 0) {
                                if (width == -32768) goto unsupported;
                                flags |= F_LEFT;
                                width = -width;
                        }
                } else {
                        width = __ex716_parse_number(&format);
                        if (width < 0) goto unsupported;
                }
                precision = -1;
                if (*format == '.') {
                        ++format;
                        if (*format == '*') {
                                precision = va_arg(arguments, int);
                                ++format;
                                if (precision < 0) precision = -1;
                        } else {
                                precision = __ex716_parse_number(&format);
                                if (precision < 0) goto unsupported;
                        }
                }

                modifier = 0;
                if (*format == 'h') {
                        modifier = 1;
                        ++format;
                        if (*format == 'h') {
                                modifier = 2;
                                ++format;
                        }
                } else if (*format == 'l') {
                        modifier = 3;
                        ++format;
                        if (*format == 'l')
                                goto unsupported; /* future long-long ABI stub */
                } else if (*format == 'z' || *format == 't') {
                        modifier = 4;
                        ++format;
                } else if (*format == 'j' || *format == 'L') {
                        goto unsupported; /* future width/type stubs */
                }

                conversion = (unsigned char)*format++;
                text = digits;
                prefix = NULL;
                sign = 0;
                switch (conversion) {
                case 'd':
                case 'i':
                        if (modifier == 3) {
                                signed_long = va_arg(arguments, long);
                                signed_value = signed_long < 0;
                                wide_value = (unsigned long)signed_long;
                                if (signed_value) wide_value = 0UL - wide_value;
                        } else {
                                value = va_arg(arguments, int);
                                if (modifier == 1) value = (short)value;
                                if (modifier == 2) value = (signed char)value;
                                signed_value = value < 0;
                                unsigned_value = (unsigned int)value;
                                wide_value = signed_value ?
                                        (unsigned long)(0U - unsigned_value) :
                                        (unsigned long)unsigned_value;
                        }
                        if (signed_value) sign = '-';
                        else if (flags & F_PLUS) sign = '+';
                        else if (flags & F_SPACE) sign = ' ';
                        length = __ex716_number(digits, wide_value, 10, 0);
                        if (precision == 0 && length == 1 && digits[0] == '0')
                                length = 0;
                        __ex716_field(&sink, text, length, width, flags,
                                      precision, 1, sign, NULL);
                        break;
                case 'u':
                case 'o':
                case 'x':
                case 'X':
                        if (modifier == 3)
                                wide_value = va_arg(arguments, unsigned long);
                        else {
                                unsigned_value = va_arg(arguments, unsigned int);
                                if (modifier == 1) unsigned_value = (unsigned short)unsigned_value;
                                if (modifier == 2) unsigned_value = (unsigned char)unsigned_value;
                                wide_value = (unsigned long)unsigned_value;
                        }
                        base = conversion == 'o' ? 8 :
                               (conversion == 'x' || conversion == 'X') ? 16 : 10;
                        length = __ex716_number(digits, wide_value, base,
                                                conversion == 'X');
                        if (precision == 0 && length == 1 && digits[0] == '0')
                                length = 0;
                        if ((flags & F_ALT) && base == 16 && wide_value) {
                                prefix = conversion == 'X' ? "0X" : "0x";
                        } else if ((flags & F_ALT) && base == 8) {
                                if (!length) {
                                        digits[0] = '0';
                                        digits[1] = 0;
                                        length = 1;
                                } else if (digits[0] != '0' && precision <= length) {
                                        prefix = "0";
                                }
                        }
                        __ex716_field(&sink, text, length, width, flags,
                                      precision, 1, 0, prefix);
                        break;
                case 'p':
                        if (modifier) goto unsupported;
                        wide_value = (unsigned long)(unsigned int)
                                     va_arg(arguments, void *);
                        length = __ex716_number(digits, wide_value, 16, 0);
                        __ex716_field(&sink, digits, length, width, flags,
                                      precision, 1, 0, "0x");
                        break;
                case 'c':
                        if (modifier) goto unsupported;
                        digits[0] = (char)(va_arg(arguments, int) & 0xff);
                        __ex716_field(&sink, digits, 1, width, flags, -1,
                                      0, 0, NULL);
                        break;
                case 's':
                        if (modifier) goto unsupported;
                        text = va_arg(arguments, char *);
                        if (!text) text = "(null)";
                        length = 0;
                        while (text[length] && (precision < 0 || length < precision))
                                ++length;
                        __ex716_field(&sink, text, length, width,
                                      flags & F_LEFT, -1, 0, 0, NULL);
                        break;
                case 'f': case 'F': case 'e': case 'E':
                case 'g': case 'G': case 'a': case 'A':
                        goto unsupported; /* future floating-point formatting stub */
                default:
                        goto unsupported;
                }
        }

        if (sink.destination && (sink.unbounded || sink.size))
                sink.destination[sink.unbounded ||
                                 (unsigned int)sink.count < sink.size ?
                                 sink.count : sink.size - 1] = 0;
        return sink.failed ? -1 : sink.count;

unsupported:
        if (sink.destination && (sink.unbounded || sink.size))
                sink.destination[sink.unbounded ||
                                 (unsigned int)sink.count < sink.size ?
                                 sink.count : sink.size - 1] = 0;
        return -1;
}

int printf(const char *format, ...) {
        va_list arguments;
        int result;

        va_start(arguments, format);
        result = __ex716_vformat(NULL, 0, 0, stdout, format, arguments);
        va_end(arguments);
        return result;
}

int snprintf(char *destination, size_t size, const char *format, ...) {
        va_list arguments;
        int result;

        va_start(arguments, format);
        result = __ex716_vformat(destination, size, 0, NULL, format, arguments);
        va_end(arguments);
        return result;
}

int vprintf(const char *format, va_list arguments) {
        return __ex716_vformat(NULL, 0, 0, stdout, format, arguments);
}

int vfprintf(FILE *stream, const char *format, va_list arguments) {
        if (!stream)
                return EOF;
        return __ex716_vformat(NULL, 0, 0, stream, format, arguments);
}

int vsprintf(char *destination, const char *format, va_list arguments) {
        return __ex716_vformat(destination, 0, 1, NULL, format, arguments);
}

int vsnprintf(char *destination, size_t size, const char *format,
              va_list arguments) {
        return __ex716_vformat(destination, size, 0, NULL, format, arguments);
}

int fprintf(FILE *stream, const char *format, ...) {
        va_list arguments;
        int result;

        va_start(arguments, format);
        result = vfprintf(stream, format, arguments);
        va_end(arguments);
        return result;
}

int sprintf(char *destination, const char *format, ...) {
        va_list arguments;
        int result;

        va_start(arguments, format);
        result = vsprintf(destination, format, arguments);
        va_end(arguments);
        return result;
}

/* Streams are deliberately unbuffered. The public FILE type stays opaque;
   console streams are static while DiskOS streams own a heap object. */
struct __ex716_FILE {
        int kind;
        int eof;
        int error;
        int pushback;
        int readable;
        int writable;
        int append;
        void *disk_file;
};

#define __EX716_STREAM_INPUT  0
#define __EX716_STREAM_OUTPUT 1
#define __EX716_STREAM_ERROR  2
#define __EX716_STREAM_DISK   3

#define __EX716_MODE_RO 0x6f72
#define __EX716_MODE_WO 0x6f77
#define __EX716_MODE_RW 0x7772
#define __EX716_MODE_WP 0x2b77
#define __EX716_MODE_AP 0x2b61

static FILE __ex716_stdin_object = {__EX716_STREAM_INPUT, 0, 0, -1};
static FILE __ex716_stdout_object = {__EX716_STREAM_OUTPUT, 0, 0, -1};
static FILE __ex716_stderr_object = {__EX716_STREAM_ERROR, 0, 0, -1};
FILE *stdin = &__ex716_stdin_object;
FILE *stdout = &__ex716_stdout_object;
FILE *stderr = &__ex716_stderr_object;

extern int __EX716_INPUT_STATUS;
extern int __EX716_DISK_INIT(void);
extern void *__EX716_DISK_OPEN(const char *name, int mode);
extern int __EX716_DISK_CLOSE(void *file);
extern unsigned int __EX716_DISK_READ(void *file, void *buffer,
                                      unsigned int count);
extern unsigned int __EX716_DISK_WRITE(void *file, const void *buffer,
                                       unsigned int count);
extern int __EX716_DISK_TRUNCATE(void *file);
extern int __EX716_DISK_REWIND(void *file);
extern int __EX716_DISK_APPEND(void *file);
static int __ex716_disk_ready;

extern int __EX716_GETCHAR_RAW(void);

int getchar(void) {
        return fgetc(stdin);
}

int fgetc(FILE *stream) {
        int character;
        unsigned char byte;

        if (!stream || (stream->kind != __EX716_STREAM_INPUT &&
                        (stream->kind != __EX716_STREAM_DISK ||
                         !stream->readable))) {
                if (stream) stream->error = 1;
                return EOF;
        }
        if (stream->pushback >= 0) {
                character = stream->pushback;
                stream->pushback = -1;
                return character;
        }
        if (stream->kind == __EX716_STREAM_DISK) {
                if (__EX716_DISK_READ(stream->disk_file, &byte, 1) != 1) {
                        stream->eof = 1;
                        return EOF;
                }
                return byte;
        }
        character = __EX716_GETCHAR_RAW();
        if (character == EOF) {
                if (__EX716_INPUT_STATUS == 3)
                        stream->error = 1;
                else
                        stream->eof = 1;
                return EOF;
        }
        return character & 0xff;
}

int fputc(int character, FILE *stream) {
        unsigned char byte;

        if (stream && stream->kind == __EX716_STREAM_DISK) {
                if (!stream->writable) {
                        stream->error = 1;
                        return EOF;
                }
                byte = (unsigned char)character;
                if (stream->append)
                        __EX716_DISK_APPEND(stream->disk_file);
                if (__EX716_DISK_WRITE(stream->disk_file, &byte, 1) != 1) {
                        stream->error = 1;
                        return EOF;
                }
                return byte;
        }
        if (!stream || (stream->kind != __EX716_STREAM_OUTPUT &&
                        stream->kind != __EX716_STREAM_ERROR)) {
                if (stream) stream->error = 1;
                return EOF;
        }
        character &= 0xff;
        if (putchar(character) == EOF) {
                stream->error = 1;
                return EOF;
        }
        return character;
}

int getc(FILE *stream) {
        return fgetc(stream);
}

int putc(int character, FILE *stream) {
        return fputc(character, stream);
}

int fputs(const char *string, FILE *stream) {
        int result;

        if (!string || !stream ||
            (stream->kind != __EX716_STREAM_OUTPUT &&
             stream->kind != __EX716_STREAM_ERROR &&
             (stream->kind != __EX716_STREAM_DISK || !stream->writable))) {
                if (stream) stream->error = 1;
                return EOF;
        }
        result = fprintf(stream, "%s", string);
        if (result < 0) stream->error = 1;
        return result;
}

int puts(const char *string) {
        if (!string || fputs(string, stdout) == EOF ||
            fputc('\n', stdout) == EOF)
                return EOF;
        return 0;
}

char *fgets(char *string, int count, FILE *stream) {
        int character;
        int used;

        if (!string || count <= 0 || !stream ||
            (stream->kind != __EX716_STREAM_INPUT &&
             (stream->kind != __EX716_STREAM_DISK || !stream->readable))) {
                if (stream)
                        stream->error = 1;
                return NULL;
        }
        used = 0;
        while (used < count - 1) {
                character = fgetc(stream);
                if (character == EOF) {
                        if (!used) return NULL;
                        break;
                }
                string[used++] = (char)character;
                if (character == '\n') break;
        }
        string[used] = 0;
        return string;
}

int feof(FILE *stream) {
        return stream ? stream->eof : 0;
}

int ferror(FILE *stream) {
        return stream ? stream->error : 0;
}

void clearerr(FILE *stream) {
        if (stream) {
                stream->eof = 0;
                stream->error = 0;
        }
}

int ungetc(int character, FILE *stream) {
        if (character == EOF || !stream ||
            (stream->kind != __EX716_STREAM_INPUT &&
             (stream->kind != __EX716_STREAM_DISK || !stream->readable)) ||
            stream->pushback >= 0)
                return EOF;
        stream->pushback = character & 0xff;
        stream->eof = 0;
        return stream->pushback;
}

int fflush(FILE *stream) {
        if (!stream || stream->kind == __EX716_STREAM_OUTPUT ||
            stream->kind == __EX716_STREAM_ERROR ||
            stream->kind == __EX716_STREAM_DISK)
                return 0;
        return EOF;
}

static int __ex716_mode(const char *mode, int *disk_mode,
                        int *readable, int *writable, int *append,
                        int *truncate) {
        int plus;
        int binary;
        int i;

        if (!mode || !mode[0] ||
            (mode[0] != 'r' && mode[0] != 'w' && mode[0] != 'a'))
                return 0;
        plus = 0;
        binary = 0;
        for (i = 1; mode[i]; ++i) {
                if (mode[i] == '+' && !plus)
                        plus = 1;
                else if (mode[i] == 'b' && !binary)
                        binary = 1;
                else
                        return 0;
        }
        *append = mode[0] == 'a';
        *truncate = mode[0] == 'w';
        *readable = mode[0] == 'r' || plus;
        *writable = mode[0] != 'r' || plus;
        if (mode[0] == 'r')
                *disk_mode = plus ? __EX716_MODE_RW : __EX716_MODE_RO;
        else if (mode[0] == 'w')
                *disk_mode = plus ? __EX716_MODE_AP : __EX716_MODE_WO;
        else
                *disk_mode = plus ? __EX716_MODE_AP : __EX716_MODE_WP;
        return 1;
}

FILE *fopen(const char *filename, const char *mode) {
        FILE *stream;
        void *disk_file;
        int disk_mode;
        int readable;
        int writable;
        int append;
        int truncate;

        if (!filename || !__ex716_mode(mode, &disk_mode, &readable,
                                      &writable, &append, &truncate))
                return NULL;
        if (!__ex716_disk_ready) {
                if (__EX716_DISK_INIT() != 1)
                        return NULL;
                __ex716_disk_ready = 1;
        }
        disk_file = __EX716_DISK_OPEN(filename, disk_mode);
        if (!disk_file)
                return NULL;
        if (truncate) {
                if (__EX716_DISK_TRUNCATE(disk_file) != 1) {
                        __EX716_DISK_CLOSE(disk_file);
                        return NULL;
                }
        } else if (append && readable) {
                /* C a+ starts reading at the beginning but appends writes. */
                if (__EX716_DISK_REWIND(disk_file) != 1) {
                        __EX716_DISK_CLOSE(disk_file);
                        return NULL;
                }
        }
        stream = (FILE *)malloc(sizeof(*stream));
        if (!stream) {
                __EX716_DISK_CLOSE(disk_file);
                return NULL;
        }
        stream->kind = __EX716_STREAM_DISK;
        stream->eof = 0;
        stream->error = 0;
        stream->pushback = -1;
        stream->readable = readable;
        stream->writable = writable;
        stream->append = append;
        stream->disk_file = disk_file;
        return stream;
}

int fclose(FILE *stream) {
        int result;

        if (!stream || stream->kind != __EX716_STREAM_DISK)
                return EOF;
        result = __EX716_DISK_CLOSE(stream->disk_file);
        stream->disk_file = NULL;
        free(stream);
        return result == 1 ? 0 : EOF;
}

size_t fread(void *destination, size_t size, size_t count, FILE *stream) {
        unsigned int requested;
        unsigned int actual;
        unsigned char *bytes;

        if (!size || !count)
                return 0;
        if (!destination || !stream || stream->kind != __EX716_STREAM_DISK ||
            !stream->readable) {
                if (stream) stream->error = 1;
                return 0;
        }
        if (count && size > ((size_t)-1) / count) {
                stream->error = 1;
                return 0;
        }
        requested = size * count;
        bytes = (unsigned char *)destination;
        actual = 0;
        if (stream->pushback >= 0) {
                bytes[actual++] = (unsigned char)stream->pushback;
                stream->pushback = -1;
        }
        if (actual < requested)
                actual += (unsigned int)__EX716_DISK_READ(
                        stream->disk_file, bytes + actual, requested - actual);
        if (actual < requested)
                stream->eof = 1;
        return actual / size;
}

size_t fwrite(const void *source, size_t size, size_t count, FILE *stream) {
        unsigned int requested;
        unsigned int actual;

        if (!size || !count)
                return 0;
        if (!source || !stream || stream->kind != __EX716_STREAM_DISK ||
            !stream->writable) {
                if (stream) stream->error = 1;
                return 0;
        }
        if (count && size > ((size_t)-1) / count) {
                stream->error = 1;
                return 0;
        }
        requested = size * count;
        if (stream->append)
                __EX716_DISK_APPEND(stream->disk_file);
        actual = (unsigned int)__EX716_DISK_WRITE(
                stream->disk_file, source, requested);
        if (actual < requested)
                stream->error = 1;
        return actual / size;
}
