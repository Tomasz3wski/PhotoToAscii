import SwiftUI

struct ContentView: View {
    
    @State private var numberOfProcessors: Int = 1
    @State private var selectedLanguage: String = "C"
    @State private var targetAsciiWidth: Double = 80.0

    @State private var mainImage: NSImage?
    @State private var asciiResult: String = "ASCII-Art will appear here..."
    
    @State private var processingTime: Double = 0.0

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Text("Photo to ASCII converter")
                    .font(.largeTitle)
                    .padding(.top)
                
                HStack(alignment: .top, spacing: 20) {
                    PhotoAreaView(loadedImage: $mainImage)
                    
                    ControlsView(
                        numberOfProcessors: $numberOfProcessors,
                        selectedLanguage: $selectedLanguage,
                        targetAsciiWidth: $targetAsciiWidth,
                        loadedImage: $mainImage,
                        asciiResult: $asciiResult,
                        processingTime: $processingTime
                    )
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()

            VStack(alignment: .leading) {
                HStack {
                    Text("ASCII Output:")
                        .font(.headline)
                                    
                                    
                    if processingTime > 0 {
                        Text(String(format: "Time: %.4f s", processingTime))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                ScrollView([.horizontal, .vertical]) {
                    Text(asciiResult)
                        .font(.system(size: 8, design: .monospaced))
                        .padding(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black.opacity(0.05))
                .border(Color.gray.opacity(0.5), width: 1)
                .padding([.horizontal, .bottom])
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 700, minHeight: 600)
    }
}
