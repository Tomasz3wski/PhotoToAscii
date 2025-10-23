import SwiftUI

struct ContentView: View {
    
    @State private var numberOfProcessors: Int = 1
    @State private var selectedLanguage: String = "C"
    
    @State private var mainImage: NSImage?
    @State private var processedImage: NSImage?
    
    var body: some View {
        VStack {
            
            PhotoAreaView(
                loadedImage: $mainImage,
                processedImage: $processedImage)
            
            ControlsView(
                         numberOfProcessors: $numberOfProcessors,
                         selectedLanguage: $selectedLanguage,
                         loadedImage: $mainImage,
                         processedImage: $processedImage)
            
            Spacer()
        }
        .padding()
        .foregroundStyle(.primary)
    }
}

#Preview {
    ContentView()
}
