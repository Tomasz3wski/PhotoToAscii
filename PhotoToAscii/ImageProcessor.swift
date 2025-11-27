import AppKit
import Darwin

enum ImageProcessor {

    typealias ProcessImageFunctionC = @convention(c) (
            UnsafeMutablePointer<UInt8>, // pixels
            Int32,                       // width
            Int32,                       // height
            Int32,                       // bytesPerRow
            Int32,                       // blockWidth
            Int32                        // blockHeight
        ) -> UnsafeMutablePointer<CChar>?
    
    
    
    static func process(image: NSImage, language: String, processors: Int, targetAsciiWidth: Int) -> String? {
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to get CGImage")
            return "Error: Failed to get CGImage"
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = 8
        let bytesPerPixel = 4 // RGBA
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("Failed to create CGContext")
            return "Error: Failed to create CGContext"
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard targetAsciiWidth > 0, width >= targetAsciiWidth else {
             return "Error: Image width (\(width)px) is smaller than target ASCII width (\(targetAsciiWidth) chars)."
        }
        
        let blockWidth = width / targetAsciiWidth
        let blockHeight = blockWidth * 2
        
        guard blockWidth > 0, blockHeight > 0 else {
            return "Error: Image is too small for target width of \(targetAsciiWidth) chars (block size is 0)."
        }
        
        let frameworkName = "AsciiEngine"
                
                // dll
                let bundleURL = Bundle.main.bundleURL
                let frameworksURL = bundleURL.appendingPathComponent("Contents/Frameworks")
                let dylibURL = frameworksURL
                    .appendingPathComponent("\(frameworkName).framework")
                    .appendingPathComponent("Versions/A")
                    .appendingPathComponent(frameworkName)
                    
                let dylibPath = dylibURL.path
                
                guard let handle = dlopen(dylibPath, RTLD_NOW) else {
                    let errorMsg = String(cString: dlerror())
                    print("DLOPEN ERROR: \(errorMsg)")
                    print("Tried path: \(dylibPath)")
                    return "Error loading dylib: \(errorMsg)"
                }
                defer { dlclose(handle) }

                let symbolName = (language == "C") ? "process_image_c" : "process_image_arm"
                
                guard let symbol = dlsym(handle, symbolName) else {
                    return "Error: Symbol '\(symbolName)' not found in dylib."
                }
                
                let processFunction = unsafeBitCast(symbol, to: ProcessImageFunctionC.self)
                
                var resultString: String? = nil
                
                pixelData.withUnsafeMutableBytes { rawBufferPtr in
                    let pixelsPtr = rawBufferPtr.bindMemory(to: UInt8.self).baseAddress!
                    
                    let cStringPointer = processFunction(
                        pixelsPtr,
                        Int32(width),
                        Int32(height),
                        Int32(bytesPerRow),
                        Int32(blockWidth),
                        Int32(blockHeight)
                    )
                    
                    if let cPtr = cStringPointer {
                        resultString = String(cString: cPtr)
                        free(cPtr) 
                    }
                }
                
                return resultString
            }
        }
