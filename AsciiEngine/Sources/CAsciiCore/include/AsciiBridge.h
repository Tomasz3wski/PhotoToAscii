#pragma once

#include <stdio.h>
#include <stdint.h>

char* process_image_c(
    uint8_t* pixels,
    int width,
    int height,
    int bytesPerRow,
    int blockWidth,
    int blockHeight
);

char* process_image_arm(
    uint8_t* pixels,
    int width,
    int height,
    int bytesPerRow,
    int blockWidth,
    int blockHeight
);
