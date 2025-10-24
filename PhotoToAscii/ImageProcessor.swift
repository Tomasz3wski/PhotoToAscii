import AppKit
import CAsciiCore //package

enum ImageProcessor {

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
        
        print("Swift: Processing with \(blockWidth)x\(blockHeight)px block per character.")

        var resultString: String? = nil
        
        pixelData.withUnsafeMutableBytes { rawBufferPtr in
            let pixelsPtr = rawBufferPtr.bindMemory(to: UInt8.self).baseAddress!
            
            var cStringPointer: UnsafeMutablePointer<CChar>? = nil
            
            if language == "C" {
                cStringPointer = process_image_c(
                    pixelsPtr,
                    Int32(width),
                    Int32(height),
                    Int32(bytesPerRow),
                    Int32(blockWidth),
                    Int32(blockHeight)
                )
            } else {
                //ARM
                print("ARM wip, using C fallback")
                cStringPointer = process_image_c(
                    pixelsPtr,
                    Int32(width),
                    Int32(height),
                    Int32(bytesPerRow),
                    Int32(blockWidth),
                    Int32(blockHeight)
                )
            }
            
            if let cPtr = cStringPointer {
                resultString = String(cString: cPtr)
                free(cPtr)
            } else {
                resultString = "Error: C function returned NULL pointer (check memory allocation)."
            }
        }

        return resultString
    }
}
