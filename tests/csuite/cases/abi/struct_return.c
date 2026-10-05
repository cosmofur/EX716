struct Pair {
    int left;
    long right;
};

int inspect(struct Pair p) {
    return p.left + (p.right == 0x12345678L) - 8;
}

struct Pair make_pair(int left, long right) {
    struct Pair p;
    p.left = left;
    p.right = right;
    return p;
}

int main(void) {
    struct Pair p;
    p = make_pair(7, 0x12345678L);
    if (p.left != 7 || p.right != 0x12345678L)
        return 1;
    if (inspect(p) != 0)
        return 2;
    return 0;
}
