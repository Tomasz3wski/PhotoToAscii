import AppKit
import CAsciiCore //package

enum ImageProcessor {

    static func process(image: NSImage, language: String, processors: Int) -> NSImage? {
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to get CGImage")
            return nil
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
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        pixelData.withUnsafeMutableBytes { rawBufferPtr in
            let pixelsPtr = rawBufferPtr.bindMemory(to: UInt8.self).baseAddress!
            
            if language == "C" {
                process_image_c(pixelsPtr, Int32(width), Int32(height), Int32(bytesPerRow))
            } else {
                //process_image_arm(pixelsPtr, Int32(width), Int32(height), Int32(bytesPerRow))
                print("wip")
            }
        }

        guard let newCGImage = context.makeImage() else {
            print("Failed to create new CGImage from modified context")
            return nil
        }

        let newNSImage = NSImage(cgImage: newCGImage, size: NSSize(width: width, height: height))
        return newNSImage
    }
}
