#include "AsciiBridge.h"
#include <stdio.h>

void process_image_c(uint8_t* pixels, int width, int height, int bytesPerRow) {
    
    printf("C: Processing %dx%d image...\n", width, height);
    
    for (int y = 0; y < height; y++) {
            uint8_t* row = pixels + (y * bytesPerRow);
            
            for (int x = 0; x < width; x++) {
                int i = x * 4;
                
                row[i + 1] = 0; // G = 0
            }
        }
     printf("C: Processing complete.\n");
}

// ASM
int run_asm_multiply(int a, int b) {
    return asm_multiply_test(a, b);
}


