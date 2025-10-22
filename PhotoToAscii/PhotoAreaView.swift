import SwiftUI

struct PhotoAreaView: View {
    var body: some View {
        VStack{
            Text("Photo to ASCII converter (aktualnie mnozenie TEST)")
                .font(.largeTitle)
                .padding()

            HStack{
                // Lewa strona (Original Photo)
                VStack{
                    Text("Original Photo")
                    
                    Rectangle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 400, height: 200)
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.top)
                
                // Prawa strona (ASCII Output)
                VStack{
                    Text("ASCII")
                    
                    Rectangle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 400, height: 200)
                }
            }
        }
        .padding()
        .foregroundStyle(.primary)
    }
}

//#Preview {
//    PhotoAreaView()
//}
