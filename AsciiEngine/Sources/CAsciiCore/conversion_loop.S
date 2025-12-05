#if defined(__arm64__)

.section __TEXT,__text,regular,pure_instructions
.global _ascii_kernel_arm
.align 2

// -----------------------------------------------------------------------------
// PROCEDURE: _ascii_kernel_arm
//
// INPUT PARAMETERS (AAPCS64):
// x0  : uint8_t* pixels        - Pointer to source image data (RGBA)
// x1  : char* outputBuffer     - Pointer to destination buffer
// w2  : int      width         - Image width in pixels
// w3  : int      height        - Image height in pixels
// w4  : int      bytesPerRow   - Bytes per row in source image
// w5  : int      blockWidth    - Width of the sampling block
// w6  : int      blockHeight   - Height of the sampling block
// w7  : int      asciiWidth    - Number of ASCII characters per row
//
// STACK ARGUMENTS:
// [sp]    : int  asciiHeight   - Number of ASCII rows
// [sp+8]  : char* rampPtr      - Pointer to the ASCII character array
// [sp+16] : int  rampLen       - Length of the ASCII character array
//
// MODIFIED REGISTERS:
// x9-x17 (temporary), v0-v5 (NEON), v29-v31 (NEON constants)
// -----------------------------------------------------------------------------

_ascii_kernel_arm:
    // --- Prologue ---
    // Save callee-saved registers (x19-x28) and Frame Pointer / Link Register.
    // Allocate 96 bytes on the stack.
    sub     sp, sp, #96
    stp     x19, x20, [sp, #0]
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     x25, x26, [sp, #48]
    stp     x27, x28, [sp, #64]
    stp     x29, x30, [sp, #80]
    add     x29, sp, #80

    // --- Load arguments from stack ---
    // Arguments 0-7 are in registers. Arguments 8+ are on the stack.
    ldr     w27, [sp, #96]      // arg 8: asciiHeight (int)
    ldr     x28, [sp, #104]     // arg 9: rampPtr (pointer)
    ldr     w9,  [sp, #112]     // arg 10: rampLen (int)

    // --- Map variables to callee-saved registers ---
    mov     x19, x0             // pixels base pointer
    mov     x20, x1             // output buffer pointer (current cursor)
    mov     w21, w2             // width
    mov     w22, w3             // height
    mov     w23, w4             // bytesPerRow
    mov     w24, w5             // blockWidth
    mov     w25, w6             // blockHeight
    mov     w26, w7             // asciiWidth
    mov     w10, w9             // rampLen (moved to safe register w10)

    // --- Prepare NEON Constants (Grayscale Weights) ---
    // Formula: (R*299 + G*587 + B*114) / 1000
    // Load weights into vector registers. 'dup' replicates the value across the vector.
    mov     w9, #299
    dup     v30.8h, w9          // v30 = [299, 299, ... x8] (16-bit elements)
    mov     w9, #587
    dup     v31.8h, w9          // v31 = [587, 587, ... x8]
    mov     w9, #114
    dup     v29.8h, w9          // v29 = [114, 114, ... x8]

    // --- LOOP 1: asciiY (Rows of text) ---
    mov     w11, wzr            // currentAsciiY = 0

loop_ascii_y:
    cmp     w11, w27            // if (currentAsciiY >= asciiHeight)
    b.ge    end_main_loops      // break

    // --- LOOP 2: asciiX (Columns of text) ---
    mov     w12, wzr            // currentAsciiX = 0

loop_ascii_x:
    cmp     w12, w26            // if (currentAsciiX >= asciiWidth)
    b.ge    end_row_processing  // break (end of row)

    // Reset block accumulators
    mov     x13, xzr            // totalGrayscaleSum (64-bit to avoid overflow)
    mov     w14, wzr            // pixelCountInBlock (32-bit)

    // --- LOOP 3: pixelYInBlock (Rows inside the block) ---
    mov     w15, wzr            // py = 0

loop_block_y:
    cmp     w15, w25            // if (py >= blockHeight)
    b.ge    end_block_calc      // break

    // Calculate absolute Y: absY = asciiY * blockHeight + py
    madd    w17, w11, w25, w15
    
    // Check Y bounds
    cmp     w17, w22
    b.ge    next_block_y

    // Calculate Row Pointer: rowPtr = pixels + absY * bytesPerRow
    smull   x9, w17, w23        // x9 = absY * bytesPerRow (signed multiply long)
    add     x9, x19, x9         // x9 = rowPtr

    // --- LOOP 4: pixelXInBlock (Pixels inside the row) ---
    mov     w16, wzr            // px = 0

loop_block_x:
    cmp     w16, w24            // if (px >= blockWidth)
    b.ge    next_block_y        // break

    // -------------------------------------------------------------
    // NEON VECTORIZATION CHECK
    // We check if we can process 8 pixels at once.
    // Conditions:
    // 1. At least 8 pixels remaining in the block.
    // 2. At least 8 pixels remaining in the image width.
    // -------------------------------------------------------------
    
    // Calculate absX = asciiX * blockWidth + px
    madd    w17, w12, w24, w16
    
    // Check block condition: (px + 8 <= blockWidth)
    add     w8, w16, #8
    cmp     w8, w24
    b.gt    scalar_fallback     // Not enough pixels -> Use scalar

    // Check image boundary condition: (absX + 8 <= width)
    add     w8, w17, #8
    cmp     w8, w21
    b.gt    scalar_fallback     // Near image edge -> Use scalar

    // === NEON VECTOR BLOCK ===
    // 1. Calculate pixel address
    lsl     w8, w17, #2         // offset = absX * 4 (RGBA)
    add     x8, x9, w8, uxtw    // x8 = pixelPtr

    // 2. Load 8 pixels (32 bytes) and de-interleave channels
    // v0=R, v1=G, v2=B, v3=A (A is ignored)
    ld4     {v0.8b, v1.8b, v2.8b, v3.8b}, [x8]

    // 3. Promote 8-bit to 16-bit to prevent overflow during multiplication
    ushll   v0.8h, v0.8b, #0    // R (16-bit)
    ushll   v1.8h, v1.8b, #0    // G (16-bit)
    ushll   v2.8h, v2.8b, #0    // B (16-bit)

    // 4. Multiply and Accumulate: Sum = R*299 + G*587 + B*114
    // R * 299 (Result is 32-bit, so we split into low/high halves)
    umull   v4.4s, v0.4h, v30.4h    // Multiply Low half
    umull2  v5.4s, v0.8h, v30.8h    // Multiply High half
    
    // + G * 587
    umlal   v4.4s, v1.4h, v31.4h    // Accumulate Low
    umlal2  v5.4s, v1.8h, v31.8h    // Accumulate High

    // + B * 114
    umlal   v4.4s, v2.4h, v29.4h
    umlal2  v5.4s, v2.8h, v29.8h

    // Now v4 and v5 contain the weighted sums for 8 pixels.
    // Sum them horizontally.
    add     v4.4s, v4.4s, v5.4s     // Combine halves
    uaddlv  d4, v4.4s               // Sum all 4 elements to a 64-bit scalar

    // Move result from NEON to General Purpose register
    fmov    x8, d4                  // x8 = Weighted sum of 8 pixels

    // Divide by 1000 (Integer division)
    mov     x4, #1000
    udiv    x8, x8, x4              // x8 = Sum of grayscale values for these 8 pixels

    // Update accumulators
    add     x13, x13, x8            // totalSum += chunkSum
    add     w14, w14, #8            // count += 8

    // Advance loop counter
    add     w16, w16, #8            // px += 8
    b       loop_block_x            // Continue loop

scalar_fallback:
    // === SCALAR BLOCK (Fallback for remaining pixels) ===
    // Calculate pixel address: pixelPtr = rowPtr + absX * 4
    lsl     w8, w17, #2
    add     x8, x9, w8, uxtw

    // Load RGB values individually
    ldrb    w0, [x8, #0]        // R
    ldrb    w1, [x8, #1]        // G
    ldrb    w2, [x8, #2]        // B

    // Grayscale Formula: (299*R + 587*G + 114*B) / 1000
    mov     w3, #299
    mul     w0, w0, w3          // w0 = R * 299
    mov     w3, #587
    madd    w0, w1, w3, w0      // w0 += G * 587
    mov     w3, #114
    madd    w0, w2, w3, w0      // w0 += B * 114

    mov     w3, #1000
    udiv    w0, w0, w3          // w0 = grayscale value (0-255)

    // Add to accumulators
    add     x13, x13, x0        // totalSum += val
    add     w14, w14, #1        // count++

    // Next pixel
    add     w16, w16, #1        // px++
    b       loop_block_x

next_block_y:
    add     w15, w15, #1        // py++
    b       loop_block_y

    // --- End Block Calculation ---
end_block_calc:
    // Avoid division by zero
    cmp     w14, #0
    beq     write_empty_char

    // Calculate Average: average = totalSum / count
    uxtw    x14, w14            // Promote count to 64-bit
    udiv    x13, x13, x14       // x13 = averageGrayscale

    // Map to Character Index: index = (avg * rampLen) / 255
    mul     x0, x13, x10        // x0 = avg * rampLen
    mov     x2, #255
    udiv    x0, x0, x2          // x0 = index

    // Clamp index to prevent buffer overflow (max index = rampLen - 1)
    cmp     w0, w10
    b.lt    load_char
    sub     w0, w10, #1         // index = rampLen - 1
    b       load_char

write_empty_char:
    mov     w0, #0              // Default to index 0

load_char:
    // Load character from ramp: char = ramp[index]
    ldrb    w0, [x28, x0]       // Load char
    
    // Store character to output buffer and increment pointer
    strb    w0, [x20], #1       // *outputBuffer++ = char

    add     w12, w12, #1        // next asciiX
    b       loop_ascii_x

end_row_processing:
    // End of row: append newline character
    mov     w0, #10             // '\n'
    strb    w0, [x20], #1

    add     w11, w11, #1        // next asciiY
    b       loop_ascii_y

end_main_loops:

    // --- Epilogue ---
    // Restore registers and deallocate stack
    ldp     x19, x20, [sp, #0]
    ldp     x21, x22, [sp, #16]
    ldp     x23, x24, [sp, #32]
    ldp     x25, x26, [sp, #48]
    ldp     x27, x28, [sp, #64]
    ldp     x29, x30, [sp, #80]
    add     sp, sp, #96
    ret

#else
.section __TEXT,__text,regular,pure_instructions
.global _ascii_kernel_arm
_ascii_kernel_arm:
    ret
#endif
