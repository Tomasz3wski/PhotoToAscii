import SwiftUI

struct ControlsView: View {
    
    @Binding var numberOfProcessors: Int
    @Binding var selectedLanguage: String
    
    @Binding var loadedImage: NSImage?
    
    let options = [1, 2, 4, 8, 16, 32, 64]
    
    var body: some View {
        VStack {
            HStack {
                Button("Load Photo") {
                    ImageLoader.load { newImage in
                        if let newImage = newImage {
                            self.loadedImage = newImage
                        }
                    }
                }
                .padding()
                .foregroundStyle(.blue)
                
                Spacer()
                
                Picker("Number of processors", selection: $numberOfProcessors) {
                    ForEach(options, id: \.self) { opcja in
                        Text("\(opcja)")
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                Picker("Choose language", selection: $selectedLanguage) {
                    Text("C").tag("C")
                    Text("ARM").tag("ARM")
                }
                .pickerStyle(.segmented)
                
                //TODO: Text("Time: ")
            }
            .padding(.horizontal)
            
            Button("Start") {
                // TODO: start processing
            }
            .foregroundStyle(.red)
        }
    }
}
