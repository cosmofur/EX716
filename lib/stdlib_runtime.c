#include <stdlib.h>
#include <limits.h>
#include <errno.h>

/* Single-threaded EX716 runtime error indicator. */
int errno = 0;

long strtol(const char *nptr, char **endptr, int base)
{
    const char *p;
    const char *digits;
    long result;
    long cutoff;
    int cutlim;
    int negative;
    int digit;
    int any;
    int overflow;

    p = nptr;
    result = 0;
    negative = 0;
    any = 0;
    overflow = 0;

    while (*p == ' ' || (*p >= 9 && *p <= 13))
        ++p;

    if (*p == '-' || *p == '+') {
        negative = (*p == '-');
        ++p;
    }

    if (base != 0 && (base < 2 || base > 36)) {
        if (endptr)
            *endptr = (char *)nptr;
        return 0;
    }

    if ((base == 0 || base == 16) &&
        p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
        digit = p[2];
        if ((digit >= '0' && digit <= '9') ||
            (digit >= 'a' && digit <= 'f') ||
            (digit >= 'A' && digit <= 'F')) {
            p += 2;
            base = 16;
        }
    }

    if (base == 0)
        base = (*p == '0') ? 8 : 10;

    digits = p;

    /*
     * Accumulate negatively to represent LONG_MIN without overflow.
     * cutoff and cutlim describe the minimum permitted accumulator.
     */
    cutoff = negative ? LONG_MIN : -LONG_MAX;
    cutlim = (int)(-(cutoff % (long)base));
    cutoff /= (long)base;

    for (;;) {
        digit = *p;

        if (digit >= '0' && digit <= '9')
            digit -= '0';
        else if (digit >= 'a' && digit <= 'z')
            digit = digit - 'a' + 10;
        else if (digit >= 'A' && digit <= 'Z')
            digit = digit - 'A' + 10;
        else
            break;

        if (digit >= base)
            break;

        any = 1;

        if (!overflow) {
            if (result < cutoff ||
                (result == cutoff && digit > cutlim)) {
                overflow = 1;
            } else {
                result = result * (long)base - (long)digit;
            }
        }

        ++p;
    }

    if (endptr)
        *endptr = (char *)(any ? p : nptr);

    if (!any)
        return 0;

    if (overflow) {
        errno = ERANGE;
        return negative ? LONG_MIN : LONG_MAX;
    }

    return negative ? result : -result;
}
