#ifndef AsciiBridge_h
#define AsciiBridge_h

#include <stdio.h>
#include "arm_asm_bridge.h"

// Funkcja C: Implementacja mnożenia
int run_c_multiply(int a, int b);

// Funkcja Mostu: Wywołanie Asemblera
int run_asm_multiply(int a, int b);

#endif /* AsciiBridge_h */
