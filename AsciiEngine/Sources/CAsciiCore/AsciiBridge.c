#include "AsciiBridge.h"

// Implementacja C: Czyste mnożenie
int run_c_multiply(int a, int b) {
    return a * b;
}

// Implementacja Mostu: Wywołanie Asemblera
int run_asm_multiply(int a, int b) {
    // Wywołanie funkcji z Asemblera
    return asm_multiply_test(a, b);
}
