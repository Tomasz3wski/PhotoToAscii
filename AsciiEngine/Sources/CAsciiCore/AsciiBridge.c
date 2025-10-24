#include "AsciiBridge.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

static const char *asciiRamp = "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`'. ";
static const int rampLength = 68;

static inline uint8_t grayscale(uint8_t r, uint8_t g, uint8_t b) {
    // (299*R + 587*G + 114*B) / 1000
    uint32_t temp = (uint32_t)r * 299 + (uint32_t)g * 587 + (uint32_t)b * 114;
    return (uint8_t)(temp / 1000);
}

char* process_image_c(
    uint8_t* pixels,
    int width,
    int height,
    int bytesPerRow,
    int blockWidth,
    int blockHeight
) {
    printf("C: Generating ASCII-art from %dx%d image...\n", width, height);

    int asciiArtWidth = width / blockWidth;
    int asciiArtHeight = height / blockHeight;

    size_t outputSize = (size_t)(asciiArtWidth + 1) * asciiArtHeight + 1;
    char* outputString = (char*)malloc(outputSize);
    
    if (!outputString) {
        fprintf(stderr, "C: ERROR — could not allocate memory for output string!\n");
        return NULL;
    }
    char* outPtr = outputString;

    //TODO: timeStart
    for (int asciiY = 0; asciiY < asciiArtHeight; asciiY++) {
        for (int asciiX = 0; asciiX < asciiArtWidth; asciiX++) {
            
            double totalGrayscaleSum = 0.0;
            int pixelCountInBlock = 0;

            for (int pixelYInBlock = 0; pixelYInBlock < blockHeight; pixelYInBlock++) {
                
                int sourcePixelY = asciiY * blockHeight + pixelYInBlock;
                if (sourcePixelY >= height) continue;

                uint8_t* pixelRow = pixels + sourcePixelY * bytesPerRow;

                for (int pixelXInBlock = 0; pixelXInBlock < blockWidth; pixelXInBlock++) {
                    
                    int sourcePixelX = asciiX * blockWidth + pixelXInBlock;
                    if (sourcePixelX >= width) continue;

                    uint8_t* pixelPtr = pixelRow + sourcePixelX * 4;
                    
                    uint8_t grayValue = grayscale(pixelPtr[0], pixelPtr[1], pixelPtr[2]);
                    totalGrayscaleSum += grayValue;
                    pixelCountInBlock++;
                }
            }
            
            double averageGrayscale = 0.0;
            if (pixelCountInBlock > 0) {
                 averageGrayscale = totalGrayscaleSum / pixelCountInBlock;
            }
            
            int rampIndex = (int)((averageGrayscale / 255.0) * (rampLength - 1));
            
            *outPtr = asciiRamp[rampIndex];
            outPtr++;
        }
        
        *outPtr = '\n';
        outPtr++;
    }

    *outPtr = '\0'; // terminator null
    
    //TODO: timeEnd

    printf("C: ASCII-art generated in memory (%dx%d chars)\n", asciiArtWidth, asciiArtHeight);
    fflush(stdout);
    
    return outputString;
}
