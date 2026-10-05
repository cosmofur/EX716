int main(void) {
    int signed16;
    unsigned int unsigned16;
    long signed32;
    unsigned long unsigned32;

    signed16 = -81;
    unsigned16 = 50000U;
    signed32 = -123456L;
    unsigned32 = 0xf0000000UL;

    if (signed16 / 9 != -9 || signed16 % 9 != 0)
        return 1;
    if (unsigned16 / 100U != 500U || unsigned16 % 100U != 0U)
        return 2;
    if (123 * 10 != 1230 || 123L * 10L != 1230L)
        return 3;
    if (signed32 / 12L != -10288L || signed32 % 12L != 0L)
        return 4;
    if (unsigned32 / 16UL != 0x0f000000UL || unsigned32 % 16UL != 0UL)
        return 5;
    if ((-16 >> 2) != -4 || (unsigned32 >> 4) != 0x0f000000UL)
        return 6;
    if ((1L << 20) != 0x00100000L)
        return 7;
    return 0;
}
