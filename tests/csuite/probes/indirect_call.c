static int add_one(int value) {
    return value + 1;
}

int main(void) {
    int (*operation)(int);
    operation = add_one;
    return operation(41) == 42 ? 0 : 1;
}
