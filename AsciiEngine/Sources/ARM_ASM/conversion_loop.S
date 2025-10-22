// Funkcja: int asm_multiply_test(int a, int b)
// a w X0, b w X1 (dla argumentów)
// Wynik wraca w X0

.globl _asm_multiply_test
.p2align 3

_asm_multiply_test:
    // Mnożenie wartości w X0 (a) i X1 (b). Wynik w X0.
    mul x0, x0, x1
    ret
