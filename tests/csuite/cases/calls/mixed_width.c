int add16(int left, int right) {
    return left + right;
}

long add32(long left, long right) {
    return left + right;
}

long relay(int small, long wide) {
    return add32(add16(small, 3), wide);
}

int main(void) {
    if (add16(20, 22) != 42)
        return 1;
    if (relay(7, 0x12340000L) != 0x1234000aL)
        return 2;
    return 0;
}
