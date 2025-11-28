#include "AsciiBridge.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <pthread.h>
#include <time.h>

static const char *asciiRamp = "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`'. ";
static const int rampLength = 68;

static inline uint8_t grayscale(uint8_t r, uint8_t g, uint8_t b) {
    uint32_t temp = (uint32_t)r * 299 + (uint32_t)g * 587 + (uint32_t)b * 114;
    return (uint8_t)(temp / 1000);
}

extern void ascii_kernel_arm(
    uint8_t* pixels,
    char* outputBuffer,
    int width,
    int height,
    int bytesPerRow,
    int blockWidth,
    int blockHeight,
    int asciiWidth,
    int asciiHeight,
    const char* rampPtr,
    int rampLen
);

typedef struct {
    int threadID;
    uint8_t* pixelsStart;
    char* outputStart;

    int width;
    int height;
    int bytesPerRow;
    int blockWidth;
    int blockHeight;

    int asciiArtWidth;
    int asciiArtHeight;
} ThreadData;

void* thread_worker_c(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    char* outPtr = data->outputStart;

    
    for (int asciiY = 0; asciiY < data->asciiArtHeight; asciiY++) {
        for (int asciiX = 0; asciiX < data->asciiArtWidth; asciiX++) {
            
            double totalGrayscaleSum = 0.0;
            int pixelCountInBlock = 0;

            for (int pixelYInBlock = 0; pixelYInBlock < data->blockHeight; pixelYInBlock++) {
                
                int sourcePixelY = asciiY * data->blockHeight + pixelYInBlock;
                if (sourcePixelY >= data->height) continue;

                uint8_t* pixelRow = data->pixelsStart + sourcePixelY * data->bytesPerRow;

                for (int pixelXInBlock = 0; pixelXInBlock < data->blockWidth; pixelXInBlock++) {
                    
                    int sourcePixelX = asciiX * data->blockWidth + pixelXInBlock;
                    if (sourcePixelX >= data->width) continue;

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
    return NULL;
}

void* thread_worker_arm(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    
    ascii_kernel_arm(
        data->pixelsStart,
        data->outputStart,
        data->width,
        data->height,
        data->bytesPerRow,
        data->blockWidth,
        data->blockHeight,
        data->asciiArtWidth,
        data->asciiArtHeight,
        asciiRamp,
        rampLength
    );
    
    return NULL;
}


char* run_multithreaded_processing(
    uint8_t* pixels, int width, int height, int bytesPerRow,
    int blockWidth, int blockHeight, int threadCount,
    void* (*worker_func)(void*),
    const char* label
) {
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    int asciiArtWidth = width / blockWidth;
    int asciiArtHeight = height / blockHeight;
    size_t outputSize = (size_t)(asciiArtWidth + 1) * asciiArtHeight + 1;
    
    char* outputString = (char*)malloc(outputSize);
    if (!outputString) return NULL;

    if (threadCount < 1) threadCount = 1;
    if (threadCount > asciiArtHeight) threadCount = asciiArtHeight;

    printf("%s: Starting processing on %d threads...\n", label, threadCount);

    pthread_t threads[threadCount];
    ThreadData threadData[threadCount];

    int rowsPerThread = asciiArtHeight / threadCount;
    int remainingRows = asciiArtHeight % threadCount;
    int currentStartRow = 0;

    for (int i = 0; i < threadCount; i++) {
        int rowsForThisThread = rowsPerThread + (i < remainingRows ? 1 : 0);
        
        threadData[i].threadID = i;
        threadData[i].width = width;
        threadData[i].height = rowsForThisThread * blockHeight;
        threadData[i].bytesPerRow = bytesPerRow;
        threadData[i].blockWidth = blockWidth;
        threadData[i].blockHeight = blockHeight;
        threadData[i].asciiArtWidth = asciiArtWidth;
        threadData[i].asciiArtHeight = rowsForThisThread;

        size_t pixelOffset = (size_t)currentStartRow * blockHeight * bytesPerRow;
        threadData[i].pixelsStart = pixels + pixelOffset;

        size_t outputOffset = (size_t)currentStartRow * (asciiArtWidth + 1);
        threadData[i].outputStart = outputString + outputOffset;

        pthread_create(&threads[i], NULL, worker_func, &threadData[i]);

        currentStartRow += rowsForThisThread;
    }

    for (int i = 0; i < threadCount; i++) {
        pthread_join(threads[i], NULL);
    }

    outputString[outputSize - 1] = '\0';

    clock_gettime(CLOCK_MONOTONIC, &end);
    double time_taken = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;

    printf("%s: Finished in %.6f seconds.\n", label, time_taken);
    fflush(stdout);

    return outputString;
}


__attribute__((visibility("default")))
char* process_image_c(uint8_t* p, int w, int h, int bpr, int bw, int bh, int tc) {
    return run_multithreaded_processing(p, w, h, bpr, bw, bh, tc, thread_worker_c, "C (Multi)");
}

__attribute__((visibility("default")))
char* process_image_arm(uint8_t* p, int w, int h, int bpr, int bw, int bh, int tc) {
    return run_multithreaded_processing(p, w, h, bpr, bw, bh, tc, thread_worker_arm, "ARM (Multi)");
}
