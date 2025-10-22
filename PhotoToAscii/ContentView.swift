import SwiftUI

struct ContentView: View {
    // Zmienne stanu (Single Source of Truth)
    @State private var number: Int = 1
    @State private var jezyk: String = "C" // Zmienna była nazwana 'jezyk'

    var body: some View {
        VStack {
            Text("Photo to ASCII converter")
                .font(.largeTitle)
                .padding()
            
            // Użycie wydzielonego widoku obrazów
            PhotoAreaView()
            
            // Użycie wydzielonego widoku kontrolek
            // Przekazanie zmiennych stanu za pomocą $ (Binding)
            ControlsView(numberOfProcessors: $number, selectedLanguage: $jezyk)
            
            Spacer() // Pcha wszystko do góry
        }
        .padding()
        .foregroundStyle(.primary)
    }
}

#Preview {
    ContentView()
}
