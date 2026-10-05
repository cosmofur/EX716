int main(void) {
    int values[3];
    unsigned char bytes[3];
    int *cursor;
    int left;
    int right;
    int *items[2];

    values[0] = 11;
    values[1] = 22;
    values[2] = 33;
    bytes[0] = 1;
    bytes[1] = 0xfe;
    bytes[2] = 3;
    cursor = &values[0];
    left = 111;
    right = 222;
    items[0] = &left;
    items[1] = &right;

    if (*(cursor + 2) != 33)
        return 1;
    if (values[1] + bytes[1] != 276)
        return 2;
    if (*items[0] != 111 || *items[1] != 222)
        return 3;
    return 0;
}
