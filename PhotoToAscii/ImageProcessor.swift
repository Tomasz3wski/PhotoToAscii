import Foundation
import AppKit
import Darwin

enum ImageProcessor {

    typealias ProcessImageFunctionC = @convention(c) (
        UnsafeMutablePointer<UInt8>, // pixels
        Int32,                       // width
        Int32,                       // height
        Int32,                       // bytesPerRow
        Int32,                       // blockWidth
        Int32,                       // blockHeight
        Int32                        // threadCount
    ) -> UnsafeMutablePointer<CChar>?

    static func process(image: NSImage, language: String, processors: Int, targetAsciiWidth: Int) -> String? {
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return "Error: No CGImage"
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(
            data: &pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return "Error: Context creation failed" }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard targetAsciiWidth > 0, width >= targetAsciiWidth else { return "Error: Target width issue" }
        let blockWidth = width / targetAsciiWidth
        let blockHeight = blockWidth * 2
        guard blockWidth > 0 else { return "Error: Block size 0" }

        let frameworkName = "AsciiEngine"
        let bundleURL = Bundle.main.bundleURL
        let frameworksURL = bundleURL.appendingPathComponent("Contents/Frameworks")
        let dylibURL = frameworksURL
            .appendingPathComponent("\(frameworkName).framework")
            .appendingPathComponent("Versions/A")
            .appendingPathComponent(frameworkName)
            
        guard let handle = dlopen(dylibURL.path, RTLD_NOW) else {
            let errorMsg = String(cString: dlerror())
            return "Error loading dylib: \(errorMsg)"
        }
        defer { dlclose(handle) }

        let symbolName = (language == "C") ? "process_image_c" : "process_image_arm"
        
        guard let symbol = dlsym(handle, symbolName) else {
            return "Error: Symbol '\(symbolName)' not found."
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
                Int32(blockHeight),
                Int32(processors)
            )
            
            if let cPtr = cStringPointer {
                resultString = String(cString: cPtr)
                free(cPtr)
            }
        }
        
        return resultString
    }
}
