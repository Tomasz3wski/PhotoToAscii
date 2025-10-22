import SwiftUI

struct PhotoAreaView: View {
    
    @Binding var loadedImage: NSImage?
    
    var body: some View {
        VStack{
            Text("Photo to ASCII converter")
                .font(.largeTitle)
                .padding()

            HStack{
                // Left side (input)
                VStack{
                    Text("Original Photo")
                    
                    if let image = loadedImage {
                        Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 400, height: 200)
                        .border(Color.blue, width: 3)
                        } else {
                            Rectangle()
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 400, height: 200)
                                        }
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.top)
                
                // Right side (output)
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
