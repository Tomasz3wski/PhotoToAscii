#include "AsciiBridge.h"


// C
int run_c_multiply(int a, int b) {
    return a * b;
}

// ASM
int run_asm_multiply(int a, int b) {
    return asm_multiply_test(a, b);
}
