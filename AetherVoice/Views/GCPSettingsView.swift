import SwiftUI

struct GCPSettingsView: View {
    @ObservedObject var listViewModel: DocumentListViewModel
    @State private var gcpApiKey: String = ""
    @State private var isEditing = false
    var costPerMillionCharacters: [String: Double] = [
        "Journey": 0,
        "News": 16,
        "Standard": 4,
        "Studio": 160,
        "Wavenet": 16,
        "Polyglot": 16,
        "Neural2": 16
    ]

    var body: some View {
        Form {
            Section(header: Text("GCP API Key")) {
                Text("The GCP API Key acts like a password to access your GCP account's Text-to-Speech API. Don't share it with anyone. The value will be securely stored in your keychain upon entering it.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Link("See Setup Instructions", destination: URL(string: "https://github.com/rachit-shah/AetherVoice#setup-google-cloud")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                if isEditing {
                    TextField("GCP API Key", text: $gcpApiKey)
                } else {
                    Text(maskedID)
                }
                
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task {
                            await saveToKeychain(gcpApiKey)
                        }
                    }
                    isEditing.toggle()
                }

                Button("Delete", role: .destructive) {
                    deleteFromKeychain()
                    gcpApiKey = ""
                }
            }
            Section(header: Text("Estimated Bill in your GCP account")) {
                Text("This estimate is based on the number of characters processed by each engine type and their respective costs as per GCP Text-to-Speech pricing. Note: This doesn't factor in any free-tier benefits you might have remaining.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                Link("Learn more about GCP Text-to-Speech Pricing", destination: URL(string: "https://cloud.google.com/text-to-speech/pricing")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                Text(printCharactersProcessed())
                Text("Estimated Cost: $\(calculateEstimatedCost())")
            }
        }
        .navigationTitle("Google Cloud Text To Speech Settings")
        .padding()
        .onAppear {
            loadFromKeychain()
        }
    }
    
    private func printCharactersProcessed() -> String {
        var printStr = "Characters Processed By Voice Type (Estimated cost per million characters in braces as of Jan 2024):"
        let charactersProcessedDict = GoogleCloudSynthesizer.getCharactersProcessed()
        for (_, ele) in charactersProcessedDict.enumerated() {
            printStr += "\n - \(ele.key) - \(ele.value) ($\(costPerMillionCharacters[ele.key, default: 0]))"
        }
        return printStr
    }
    
    private func calculateEstimatedCost() -> String {
        var totalCost: Double = 0.0
        let charactersProcessedDict = GoogleCloudSynthesizer.getCharactersProcessed()
        for (_, ele) in charactersProcessedDict.enumerated() {
            let engine = ele.key
            totalCost += Double(ele.value) / 1_000_000 * costPerMillionCharacters[engine, default: 0]
        }
        return String(totalCost)
    }

    private var maskedID: String {
        !gcpApiKey.isEmpty ? "●●●●●●" : "Not Set"
    }

    private func saveToKeychain(_ id: String) async {
        let result = KeychainWrapper.save(key: "GCP_API_KEY", data: Data(id.utf8))
        if result == false {
            print("Failed saving gcpApiKey in keychain.")
        } else {
            await listViewModel.initializeSynthesizer(ttsService: .googleCloud)
        }
    }

    private func loadFromKeychain() {
        if let idData = KeychainWrapper.load(key: "GCP_API_KEY"),
           let idString = String(data: idData, encoding: .utf8) {
            gcpApiKey = idString
        }
    }
    
    private func deleteFromKeychain() {
        let result = KeychainWrapper.delete(key: "GCP_API_KEY")
        if result == false {
            print("Failed deleting gcpApiKey from keychain.")
        } else {
            listViewModel.synthesizerDict[.googleCloud] = nil
        }
    }
}

