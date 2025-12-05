# PhotoToAscii Converter

**PhotoToAscii** is a high-performance macOS application designed to convert raster images into ASCII art in real-time.

The project demonstrates a hybrid programming approach, combining a modern user interface in **SwiftUI**, a memory and thread management layer in **C**, and a critical computational section optimized in **ARM64 Assembly** using **NEON (SIMD)** vector instructions.

---

## Key Features

- **Image to Text Conversion:** Processes any image file into a text-based ASCII representation.
    
- **Multithreading:** Allows the user to select the number of threads (1-64) for processing. It utilizes the `pthreads` library and a domain decomposition model (image slicing) with a lock-free architecture.
    
- **Dual Computational Engines:**
    
    - **C:** Reference implementation of the algorithm.
        
    - **ASM (ARM64):** Optimized implementation using NEON vector instructions (processing 8 pixels simultaneously).
        
- **Dynamic Scaling:** A slider allows for smooth adjustment of the output resolution (text width) while maintaining the image aspect ratio.
    
- **Dynamic Library Loading:** The `AsciiEngine` is loaded at runtime using `dlopen` and `dlsym`, ensuring a strict separation between the interface and the logic.
    
- **Performance Metrics:** Precise measurement of the algorithm's execution time (Wall Clock Time) using `clock_gettime`.
    

---

## Technologies

The project was built using the following technology stack:

- **Frontend:** Swift 5, SwiftUI (macOS App).
    
- **Middleware / Orchestration:** C (C99), POSIX Threads (`pthreads`).
    
- **Backend / Kernel:** Assembly ARM64 (AArch64), SIMD instructions (NEON).
    
- **Tools:** Xcode 15+, Clang, LLDB.
    
- **Architecture:** Apple Silicon (M1/M2/M3).
    

---

## Architecture and Algorithm

The application operates based on a specific processing pipeline:

1. **SwiftUI (UI):** Retrieves the image from the user, converts it into a bitmap (`CGImage` -> `[UInt8]`), and prepares a raw RGBA pixel buffer.
    
2. **Dynamic Loader:** Swift loads the `AsciiEngine.framework` library dynamically and retrieves a pointer to the appropriate function (`process_image_c` or `process_image_arm`).
    
3. **C Layer (Orchestration):**
    
    - Divides the image into horizontal slices based on the thread count.
        
    - Calculates memory pointer offsets for each thread.
        
    - Launches threads that perform calculations independently (no Race Conditions).
        
4. **Kernel (C or ASM):**
    
    - **Downsampling:** Divides the image into blocks (e.g., 8x16 pixels).
        
    - **Luminance:** Calculates the average brightness of a block using the perceptual formula: `Y = 0.299*R + 0.587*G + 0.114*B` _(The Assembly implementation uses fixed-point arithmetic for efficiency)_.
        
    - **Mapping:** Maps the brightness (0-255) to a character from an extended ASCII table (68 characters).
        
    - **NEON (ASM Only):** The assembly kernel loads 8 pixels with a single `ld4` instruction and performs calculations in parallel on 128-bit vector registers.
        

---

## Project Structure

Plaintext

```
PhotoToAscii/
├── PhotoToAscii/           # Swift Application Source Code (UI)
│   ├── ContentView.swift   # Main view and layout
│   ├── ControlsView.swift  # Control panel (sliders, buttons)
│   ├── PhotoAreaView.swift # Image display
│   └── ImageProcessor.swift# Logic for dylib loading and data preparation
│
└── AsciiEngine/            # Swift Package Manager Package (C + ASM)
    ├── Package.swift       # Package configuration (type: .dynamic)
    └── Sources/CAsciiCore/
        ├── include/AsciiBridge.h  # Public C interface
        ├── AsciiBridge.c          # Threading implementation and C logic
        └── conversion_loop.S      # Core algorithm implementation in ARM64 ASM
```

---

## Requirements and Installation

### Requirements

- Mac computer with an **Apple Silicon** processor (M1, M2, M3, M4).
    
    - _Note: The assembly code will not function on Intel processors._
        
- Xcode 14.0 or newer.
    
- macOS 13.0 (Ventura) or newer.
    

### Installation

1. Clone the repository:
    
    Bash
    
    ```
    git clone https://github.com/your-username/PhotoToAscii.git
    cd PhotoToAscii
    ```
    
2. Open the `PhotoToAscii.xcodeproj` file in Xcode.
    
3. Ensure the selected build target is **"My Mac"** (do not select iOS simulators).
    
4. Build and run the project (`Cmd + R`).
    

_Tip: If linker errors occur, use the option **Product -> Clean Build Folder**._

---

## Performance Testing

The application displays the algorithm execution time (in seconds) in the bottom panel of the interface.

To observe the gains from multithreading and vector instructions:

1. Load a high-resolution image (e.g., 4K).
    
2. Set the number of processors to **1** and run the conversion in **C** mode.
    
3. Change the number of processors to **8** or **16**.
    
4. Switch the language to **ARM** and compare the execution times.
    

---

## Author

**Jakub Tomaszewski** Project realized as part of the "Assembly Languages" course.

