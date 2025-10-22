import SwiftUI

struct ControlsView: View {
    // Binding do zmiennych stanu, które są trzymane w ExampleView
    @Binding var numberOfProcessors: Int
    @Binding var selectedLanguage: String
    
    let options = [1, 2, 4, 8, 16, 32, 64]

    var body: some View {
        HStack {
            Button("Load Photo") {
                // TODO: otwieranie przegladarki plikow
            }
            .padding()
            .foregroundStyle(.blue)
            
            Spacer()
            
            // Picker dla liczby procesorów
            Picker("Number of processors", selection: $numberOfProcessors) {
                ForEach(options, id: \.self) { opcja in
                    Text("\(opcja)")
                }
            }
            .pickerStyle(.menu)
            
            Spacer()
            
            // Picker dla wyboru implementacji (C/ARM)
            Picker("Choose language", selection: $selectedLanguage) {
                Text("C").tag("C")
                Text("ARM").tag("ARM")
            }
            .pickerStyle(.segmented)
            
            Text("Time: ")
        }
        .padding(.horizontal)
        
        Button("Start") {
            // TODO: start processing
        }
        .foregroundStyle(.red)
    }
    
    
}
