#include <stdarg.h>
#include <stdio.h>

extern void itos(char *destination, int value, int base);
extern void i32tos(char *destination, long value, int base);

int __ex716_vformat(char *destination, size_t size, const char *format,
                    va_list arguments) {
        char digits[12];
        const char *text;
        int count;
        int character;
        int conversion;
        int long_value;
        int failed;
        int value;
        unsigned int unsigned_value;
        long wide_value;

        count = 0;
        failed = 0;
        while (*format) {
                text = NULL;
                long_value = 0;
                if (*format != '%') {
                        character = (unsigned char)*format++;
                } else {
                        ++format;
                        if (*format == '%') {
                                ++format;
                                character = '%';
                        } else {
                                if (*format == 'l') {
                                        long_value = 1;
                                        ++format;
                                }
                                conversion = (unsigned char)*format++;
                                switch (conversion) {
                                case 'd':
                                case 'i':
                                        if (long_value) {
                                                i32tos(digits,
                                                       va_arg(arguments, long),
                                                       10);
                                        } else {
                                                value = va_arg(arguments, int);
                                                if (value == -32768)
                                                        i32tos(digits,
                                                               (long)value, 10);
                                                else
                                                        itos(digits, value, 10);
                                        }
                                        text = digits;
                                        break;
                                case 'u':
                                case 'x':
                                case 'X':
                                        if (long_value)
                                                return -1;
                                        unsigned_value =
                                                va_arg(arguments, unsigned int);
                                        wide_value = (long)unsigned_value;
                                        i32tos(digits, wide_value,
                                               conversion == 'u' ? 10 : 16);
                                        text = digits;
                                        break;
                                case 'c':
                                        if (long_value)
                                                return -1;
                                        character = va_arg(arguments, int) & 0xff;
                                        break;
                                case 's':
                                        if (long_value)
                                                return -1;
                                        text = va_arg(arguments, char *);
                                        if (!text)
                                                text = "(null)";
                                        break;
                                default:
                                        return -1;
                                }
                        }
                }

                if (text) {
                        while (*text) {
                                character = (unsigned char)*text++;
                                if (count >= 32767) {
                                        failed = 1;
                                        break;
                                }
                                if (!destination) {
                                        if (putchar(character) == EOF) {
                                                failed = 1;
                                                break;
                                        }
                                } else if (size && (unsigned int)count < size - 1) {
                                        destination[count] = (char)character;
                                }
                                ++count;
                        }
                } else if (!failed) {
                        if (count >= 32767) {
                                failed = 1;
                        } else {
                                if (!destination) {
                                        if (putchar(character) == EOF)
                                                failed = 1;
                                } else if (size && (unsigned int)count < size - 1) {
                                        destination[count] = (char)character;
                                }
                                ++count;
                        }
                }
                if (failed)
                        break;
        }

        if (destination && size)
                destination[(unsigned int)count < size ? count : size - 1] = 0;
        return failed ? -1 : count;
}

int printf(const char *format, ...) {
        va_list arguments;
        int result;

        va_start(arguments, format);
        result = __ex716_vformat(NULL, 0, format, arguments);
        va_end(arguments);
        return result;
}

int snprintf(char *destination, size_t size, const char *format, ...) {
        va_list arguments;
        int result;

        va_start(arguments, format);
        result = __ex716_vformat(destination, size, format, arguments);
        va_end(arguments);
        return result;
}