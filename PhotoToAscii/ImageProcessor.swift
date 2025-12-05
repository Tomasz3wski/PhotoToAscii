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
        Int32,                       // threadCount
        UnsafeMutablePointer<Double>
    ) -> UnsafeMutablePointer<CChar>?

    static func process(image: NSImage, language: String, processors: Int, targetAsciiWidth: Int) -> (String, Double)? {
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(
            data: &pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard targetAsciiWidth > 0, width >= targetAsciiWidth else { return nil }
        let blockWidth = width / targetAsciiWidth
        let blockHeight = blockWidth * 2
        guard blockWidth > 0 else { return nil }

        let frameworkName = "AsciiEngine"
        let bundleURL = Bundle.main.bundleURL
        let frameworksURL = bundleURL.appendingPathComponent("Contents/Frameworks")
        let dylibURL = frameworksURL
            .appendingPathComponent("\(frameworkName).framework")
            .appendingPathComponent("Versions/A")
            .appendingPathComponent(frameworkName)
            
        guard let handle = dlopen(dylibURL.path, RTLD_NOW) else {
            let errorMsg = String(cString: dlerror())
            return nil
        }
        defer { dlclose(handle) }

        let symbolName = (language == "C") ? "process_image_c" : "process_image_arm"
        
        guard let symbol = dlsym(handle, symbolName) else {
            return nil
        }
        
        let processFunction = unsafeBitCast(symbol, to: ProcessImageFunctionC.self)
        
        var resultTuple: (String, Double)? = nil
        
        pixelData.withUnsafeMutableBytes { rawBufferPtr in
            let pixelsPtr = rawBufferPtr.bindMemory(to: UInt8.self).baseAddress!
            
            var timeTaken: Double = 0.0
            
            let cStringPointer = processFunction(
                pixelsPtr,
                Int32(width),
                Int32(height),
                Int32(bytesPerRow),
                Int32(blockWidth),
                Int32(blockHeight),
                Int32(processors),
                &timeTaken
            )
            
            if let cPtr = cStringPointer {
                let asciiString = String(cString: cPtr)
                free(cPtr)
                resultTuple = (asciiString, timeTaken)
            }
        }
        
        return resultTuple
    }
}
