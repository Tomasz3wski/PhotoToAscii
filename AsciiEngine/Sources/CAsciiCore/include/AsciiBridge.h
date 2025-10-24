#pragma once

#include <stdio.h>
#include <stdint.h>
#include "arm_asm_bridge.h"

char* process_image_c(
    uint8_t* pixels,
    int width,
    int height,
    int bytesPerRow,
    int blockWidth,
    int blockHeight
);


//int run_asm_multiply(int a, int b);
