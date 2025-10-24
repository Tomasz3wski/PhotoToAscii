import SwiftUI

struct PhotoAreaView: View {
    
    @Binding var loadedImage: NSImage?
    
    var body: some View {
        VStack{
            Text("Original Photo")
                .font(.caption)
                .padding(.bottom, 2)
            
            if let image = loadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 200) 
                    .border(Color.blue, width: 3)
            } else {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 300, height: 200)
                    .overlay(Text("Load a photo...").foregroundColor(.gray))
            }
        }
    }
}
