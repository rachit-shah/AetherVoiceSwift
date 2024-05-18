import Foundation
#if os(macOS)
import AppKit
#endif

class FilePickerUtility {
    #if os(macOS)
    static func openFilePicker(completion: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText, .pdf, .epub]

        if panel.runModal() == .OK {
            completion(panel.urls)
        } else {
            completion(nil)
        }
    }
    #endif
}
