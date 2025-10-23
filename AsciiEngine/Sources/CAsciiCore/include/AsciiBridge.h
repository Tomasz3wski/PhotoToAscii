#pragma once

#include <stdio.h>
#include <stdint.h>
#include "arm_asm_bridge.h"

void process_image_c(
    uint8_t* pixels,
    int width,
    int height,
    int bytesPerRow
);

//process_image_arm(
//    uint8_t* pixels,
//    int width,
//    int height,
//    int bytesPerRow
//);

int run_asm_multiply(int a, int b);
