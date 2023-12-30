import Combine
import Foundation
import PDFKit
import UniformTypeIdentifiers

class DocumentListViewModel: ObservableObject {
    @Published var documents: [AppDocument] = []
    private let persistenceController = PersistenceController.shared

    init() {
        fetchDocuments()
    }
    
    func saveDocument(_ appDocument: AppDocument) {
        persistenceController.saveDocument(appDocument)
        fetchDocuments()  // Refresh the documents list
    }

    func fetchDocuments() {
        documents = persistenceController.fetchDocuments()
    }
    
    #if os(macOS)
    func uploadDocument() {
        FilePickerUtility.openFilePicker { url in
            guard let url = url else { return }

            // Call processDocument to handle the file
            self.processDocument(at: url)
        }
    }
    #endif
    
    func processDocument(at url: URL) {
        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
            case "txt":
                processPlainTextDocument(at: url)
            case "pdf":
                processPDFDocument(at: url)
            // Add cases for "epub", "docx", etc.
            default:
                print("Unsupported file type")
        }
    }

    func processPlainTextDocument(at url: URL) {
        if let contents = try? String(contentsOf: url) {
            let newDocument = AppDocument(title: url.lastPathComponent, content: contents)
            saveDocument(newDocument)
        }
    }

    private func processPDFDocument(at url: URL) {
        // Handle PDF files
        if let pdfDocument = PDFDocument(url: url) {
            // Extract text from the PDF or handle it as needed
        }
    }

    private func processEPUBDocument(at url: URL) {
        // Handle EPUB files
        // This will likely require a third-party library
    }
}
