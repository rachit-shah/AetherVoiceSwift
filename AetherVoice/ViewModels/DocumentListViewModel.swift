import Combine
import Foundation
import PDFKit
import UniformTypeIdentifiers

class DocumentListViewModel: ObservableObject {
    @Published var documents: [AppDocument] = []
    var synthesizerDict: [TTSService: SpeechSynthesizerProtocol] = [TTSService: SpeechSynthesizerProtocol]()
    private let persistenceController = PersistenceController.shared

    init() async {
        fetchDocuments()
        await initializeAllSynthesizers()
    }
    
    func saveDocument(_ appDocument: AppDocument) {
        persistenceController.saveDocument(appDocument)
        fetchDocuments()  // Refresh the documents list
    }

    func fetchDocuments() {
        documents = persistenceController.fetchDocuments()
    }
    
    func initializeAllSynthesizers() async {
        var tasks: [Task<(), Never>] = []

        for ttsService in TTSService.allCases {
            let task = Task {
                await self.initializeSynthesizer(ttsService: ttsService)
            }
            tasks.append(task)
        }

        // Wait for all tasks to complete
        for task in tasks {
            await task.value
        }
    }
    
    func initializeSynthesizer(ttsService: TTSService) async {
        let speechSynthesizer: SpeechSynthesizerProtocol
        switch ttsService {
            case .local:
                speechSynthesizer = LocalSpeechSynthesizer()
                self.synthesizerDict[ttsService] = speechSynthesizer
            case .amazonPolly:
                do {
                    guard let cognitoIdentityId = AmazonPollySynthesizer.getCognitoIdentityFromKeychain()
                    else {
                        throw SynthesizerError.userError("Need to set Identity pool id in the AWS configuration to use Polly synthesizer. Change to a different synthesizer in reader settings or set the appropriate config in the Settings menu.")
                    }
                    speechSynthesizer = try await AmazonPollySynthesizer(cognitoIdentityId: cognitoIdentityId)
                    self.synthesizerDict[ttsService] = speechSynthesizer
                } catch {
                    print("Error initializing AmazonPollySynthesizer: \(error)")
                }
            case .googleCloud:
                do {
                    guard let gcpApiKey = GoogleCloudSynthesizer.getGcpApiKeyFromKeychain()
                    else {
                        throw SynthesizerError.userError("Need to set GCP Api Key in the GCP configuration to use Google Cloud synthesizer. Change to a different synthesizer in reader settings or set the appropriate config in the Settings menu.")
                    }
                    speechSynthesizer = try GoogleCloudSynthesizer(gcpApiKey: gcpApiKey)
                    self.synthesizerDict[ttsService] = speechSynthesizer
                } catch {
                    print("Error initializing GoogleCloudSynthesizer: \(error)")
                }
            case .microsoftAzure:
                do {
                    let (azureRegion, azureApiKey)  = MicrosoftAzureSynthesizer.getAzureSettingsFromKeychain()
                    if (azureRegion == nil || azureApiKey == nil) {
                        throw SynthesizerError.userError("Need to set Azure Resource Key in the Azure configuration to use Microsoft Azure synthesizer. Change to a different synthesizer in reader settings or set the appropriate config in the Settings menu.")
                    }
                    speechSynthesizer = try MicrosoftAzureSynthesizer(azureRegion: azureRegion!, azureApiKey: azureApiKey!)
                    self.synthesizerDict[ttsService] = speechSynthesizer
                } catch {
                    print("Error initializing MicrosoftAzureSynthesizer: \(error)")
                }
        }
    }
    
    #if os(macOS)
    func uploadDocument() {
        FilePickerUtility.openFilePicker { urls in
            urls?.forEach { url in
                // Call processDocument to handle the file
                self.processDocument(at: url)
            }
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
