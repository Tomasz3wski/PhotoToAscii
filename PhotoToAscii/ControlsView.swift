import SwiftUI

struct ControlsView: View {
    
    @Binding var numberOfProcessors: Int
    @Binding var selectedLanguage: String
    
    //image
    @Binding var loadedImage: NSImage?
    @Binding var processedImage: NSImage?
    
    let options = [1, 2, 4, 8, 16, 32, 64]
    
    var body: some View {
        VStack {
            HStack {
                Button("Load Photo") {
                    ImageLoader.load { newImage in
                        if let newImage = newImage {
                            self.loadedImage = newImage
                            self.processedImage = nil
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
                startProcessing()
            }
            .foregroundStyle(.red)
        }
    }
    
    private func startProcessing() {
            guard let imageToProcess = loadedImage else {
                print("No image loaded")
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                let resultImage = ImageProcessor.process(
                    image: imageToProcess,
                    language: selectedLanguage,
                    processors: numberOfProcessors
                )
                
                DispatchQueue.main.async {
                    self.processedImage = resultImage
                }
            }
        }
    }
