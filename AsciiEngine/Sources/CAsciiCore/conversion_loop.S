#if defined(__arm64__)

.section __TEXT,__text,regular,pure_instructions
.global _ascii_kernel_arm
.align 2

// -----------------------------------------------------------------------------
// void ascii_kernel_arm(...)
// -----------------------------------------------------------------------------

_ascii_kernel_arm:
    // --- Prolog ---
    sub     sp, sp, #96
    stp     x19, x20, [sp, #0]
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     x25, x26, [sp, #48]
    stp     x27, x28, [sp, #64]
    stp     x29, x30, [sp, #80]
    add     x29, sp, #80

    // --- Load arguments from stack ---
    ldr     w27, [sp, #96]      // asciiHeight
    ldr     x28, [sp, #104]     // rampPtr
    ldr     w9,  [sp, #112]     // rampLen

    // --- Map registers ---
    mov     x19, x0             // pixels (base)
    mov     x20, x1             // outputBuffer (cursor)
    mov     w21, w2             // width
    mov     w22, w3             // height
    mov     w23, w4             // bytesPerRow
    mov     w24, w5             // blockWidth
    mov     w25, w6             // blockHeight
    mov     w26, w7             // asciiWidth
    
    mov     w10, w9             // rampLen -> w10 (x10 preserved)

    // --- LOOP 1: asciiY ---
    mov     w11, wzr            // currentAsciiY = 0

loop_ascii_y:
    cmp     w11, w27
    b.ge    end_main_loops

    // --- LOOP 2: asciiX ---
    mov     w12, wzr            // currentAsciiX = 0

loop_ascii_x:
    cmp     w12, w26
    b.ge    end_row_processing

    // Clear accumulators
    mov     x13, xzr            // totalSum (64-bit)
    mov     w14, wzr            // count (32-bit)

    // --- LOOP 3: pixelYInBlock ---
    mov     w15, wzr            // py = 0

loop_block_y:
    cmp     w15, w25
    b.ge    end_block_calc

    // absY = asciiY * blockHeight + py
    madd    w17, w11, w25, w15
    
    // Check bounds Y
    cmp     w17, w22
    b.ge    next_block_y

    // rowPtr = pixels + absY * bytesPerRow
    smull   x9, w17, w23        // x9 = offset
    add     x9, x19, x9         // x9 = rowPtr

    // --- LOOP 4: pixelXInBlock ---
    mov     w16, wzr            // px = 0

loop_block_x:
    cmp     w16, w24
    b.ge    next_block_y

    // absX = asciiX * blockWidth + px
    madd    w17, w12, w24, w16

    // Check bounds X
    cmp     w17, w21
    b.ge    next_block_x

    // pixelPtr = rowPtr + absX * 4
    lsl     w17, w17, #2        // w17 = offset
    add     x17, x9, w17, uxtw  // x17 = pixelPtr

    // Load RGB
    ldrb    w0, [x17, #0]       // R
    ldrb    w1, [x17, #1]       // G
    ldrb    w2, [x17, #2]       // B

    // Grayscale: (299*R + 587*G + 114*B) / 1000
    mov     w3, #299
    mul     w0, w0, w3
    mov     w3, #587
    madd    w0, w1, w3, w0
    mov     w3, #114
    madd    w0, w2, w3, w0

    mov     w3, #1000
    udiv    w0, w0, w3

    // Add to sum
    add     x13, x13, x0
    add     w14, w14, #1

next_block_x:
    add     w16, w16, #1
    b       loop_block_x

next_block_y:
    add     w15, w15, #1
    b       loop_block_y

    // --- End Block Calc ---
end_block_calc:
    cmp     w14, #0
    beq     write_empty_char

    // Average
    uxtw    x14, w14
    udiv    x13, x13, x14

    // Map to index: index = (avg * rampLen) / 255
    mul     x0, x13, x10
    mov     x2, #255
    udiv    x0, x0, x2

    // Clamp index
    cmp     w0, w10
    b.lt    load_char
    sub     w0, w10, #1
    b       load_char

write_empty_char:
    mov     w0, #0

load_char:
    ldrb    w0, [x28, x0]       // Load char from map
    strb    w0, [x20], #1       // Store to buffer

    add     w12, w12, #1
    b       loop_ascii_x

end_row_processing:
    mov     w0, #10             // Newline
    strb    w0, [x20], #1

    add     w11, w11, #1
    b       loop_ascii_y

end_main_loops:
    mov     w0, #0              // Null terminator
    strb    w0, [x20]

    // --- Epilog ---
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
