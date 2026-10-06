#include <stdarg.h>

static int add_one(int value) { return value + 1; }
static int subtract_one(int value) { return value - 1; }
static long add_wide(long left, int right) { return left + right; }

static int apply(int (*operation)(int), int value) {
    return operation(value);
}

static int sum(int count, ...) {
    va_list arguments;
    int result = 0;

    va_start(arguments, count);
    while (count--)
        result += va_arg(arguments, int);
    va_end(arguments);
    return result;
}

int main(void) {
    int (*operation)(int);
    long (*wide_operation)(long, int);
    int (*variadic_operation)(int, ...);
    int selector = 1;

    operation = selector ? add_one : subtract_one;
    if (operation(41) != 42 || apply(operation, 9) != 10)
        return 1;
    selector = 0;
    operation = selector ? add_one : subtract_one;
    if (operation(41) != 40)
        return 2;
    wide_operation = add_wide;
    if (wide_operation(100000L, 23) != 100023L)
        return 3;
    variadic_operation = sum;
    if (variadic_operation(3, 7, 11, 13) != 31)
        return 4;
    return 0;
}
