import SwiftUI
import UniformTypeIdentifiers

enum ImageLoader {

    static func load(completion: @escaping (NSImage?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.image]

        panel.begin { response in
            if response == .OK, let url = panel.url {
                let image = NSImage(contentsOf: url)
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
