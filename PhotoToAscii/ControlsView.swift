import SwiftUI
import CAsciiCore

struct ControlsView: View {
    
    @Binding var numberOfProcessors: Int
    @Binding var selectedLanguage: String
    @Binding var targetAsciiWidth: Double
    
    @Binding var loadedImage: NSImage?
    @Binding var asciiResult: String

    let options = [1, 2, 4, 8, 16, 32, 64]
    
    //range
    let minAsciiWidth: Double = 60.0
    let maxAsciiWidth: Double = 120.0
    
    var body: some View {
        Form {
            Section {
                Button("Load Photo") {
                    ImageLoader.load { newImage in
                        if let newImage = newImage {
                            self.loadedImage = newImage
                            self.asciiResult = "Ready to process new image."
                        }
                    }
                }
                .foregroundStyle(.blue)
                
                Picker("Processors:", selection: $numberOfProcessors) {
                    ForEach(options, id: \.self) { opcja in
                        Text("\(opcja)").tag(opcja)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Language:", selection: $selectedLanguage) {
                    Text("C").tag("C")
                    Text("ARM").tag("ARM")
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("ASCII Output Width: \(Int(targetAsciiWidth)) chars")
                        .font(.caption)
                    Slider(value: $targetAsciiWidth, in: minAsciiWidth...maxAsciiWidth, step: 10.0) {
                        Text("Width")
                    } minimumValueLabel: {
                        Text("\(Int(minAsciiWidth))")
                    } maximumValueLabel: {
                        Text("\(Int(maxAsciiWidth))")
                    }
                }
            }
            
            Section {
                Button("Start Conversion") {
                    startProcessing()
                }
                .font(.headline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(minWidth: 300)
    }
    
    private func startProcessing() {
        guard let imageToProcess = loadedImage else {
            self.asciiResult = "Error: No photo loaded. Please load a photo first."
            return
        }
        
        self.asciiResult = "Processing, please wait..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ImageProcessor.process(
                image: imageToProcess,
                language: selectedLanguage,
                processors: numberOfProcessors,
                targetAsciiWidth: Int(targetAsciiWidth)
            )
            
            DispatchQueue.main.async {
                self.asciiResult = result ?? "Error: Processing failed and returned nil."
            }
        }
    }
}
