import Foundation
#if canImport(AppKit)
import AppKit
#endif

class FilePickerUtility {
    #if os(macOS)
    static func openFilePicker(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText, .pdf, .epub]

        if panel.runModal() == .OK {
            completion(panel.url)
        } else {
            completion(nil)
        }
    }
    #endif
}
