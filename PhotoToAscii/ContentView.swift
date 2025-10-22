import SwiftUI

struct ContentView: View {
    
    @State private var numberOfProcessors: Int = 1
    @State private var selectedLanguage: String = "C"
    
    @State private var mainImage: NSImage?
    
    var body: some View {
        VStack {
            
            PhotoAreaView(loadedImage: $mainImage)
            
            ControlsView(numberOfProcessors: $numberOfProcessors, selectedLanguage: $selectedLanguage, loadedImage: $mainImage)
            
            Spacer()
        }
        .padding()
        .foregroundStyle(.primary)
    }
}

#Preview {
    ContentView()
}
