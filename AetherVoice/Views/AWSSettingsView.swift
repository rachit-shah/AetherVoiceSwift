import SwiftUI

struct AWSSettingsView: View {
    @ObservedObject var listViewModel: DocumentListViewModel
    @State var identityPoolID: String = ""
    @State var isEditing = false
    
    var costPerMillionCharacters: [String: Double] = [
        "standard": 4,
        "neural": 16,
        "long-form": 100,
    ]

    var body: some View {
        Form {
            Section(header: Text("AWS Cognito Identity Pool ID")) {
                Text("The Identity Pool ID acts like a password to access your AWS account's Polly resources. Don't share it with anyone. The value will be securely stored in your keychain upon entering it.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Link("See Setup Instructions", destination: URL(string: "https://github.com/rachit-shah/AetherVoiceSwift#setup-amazon-polly")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                if isEditing {
                    TextField("Identity Pool ID", text: $identityPoolID)
                } else {
                    Text(maskedID)
                }
                
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task {
                            await saveToKeychain(identityPoolID)
                        }
                    }
                    isEditing.toggle()
                }

                Button("Delete", role: .destructive) {
                    deleteFromKeychain()
                    identityPoolID = ""
                }
            }
            Section(header: Text("Estimated Bill in your AWS account")) {
                Text("This estimate is based on the number of characters processed by each engine type and their respective costs as per Amazon Polly pricing. Note: This doesn't factor in any free-tier benefits you might have remaining.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                Link("Learn more about Polly Pricing", destination: URL(string: "https://aws.amazon.com/polly/pricing/")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                Text(printCharactersProcessed())
                Text("Estimated Cost: $\(calculateEstimatedCost())")
            }
        }
        .navigationTitle("Amazon Polly Setting")
        .padding()
        .onAppear {
            loadFromKeychain()
        }
    }
    
    private func printCharactersProcessed() -> String {
        var printStr = "Characters Processed By Voice Type (Estimated cost per million characters in braces as of Jan 2024):"
        let charactersProcessedDict = AmazonPollySynthesizer.getCharactersProcessed()
        for (_, ele) in charactersProcessedDict.enumerated() {
            printStr += "\n - \(ele.key) - \(ele.value) ($\(costPerMillionCharacters[ele.key, default: 0]))"
        }
        return printStr
    }
    
    private func calculateEstimatedCost() -> String {
        var totalCost: Double = 0.0
        let charactersProcessedDict = AmazonPollySynthesizer.getCharactersProcessed()
        for (_, ele) in charactersProcessedDict.enumerated() {
            let engine = ele.key
            totalCost += Double(ele.value) / 1_000_000 * costPerMillionCharacters[engine, default: 0]
        }
        return String(totalCost)
    }

    private var maskedID: String {
        !identityPoolID.isEmpty ? "●●●●●●" : "Not Set"
    }

    private func saveToKeychain(_ id: String) async {
        let result = KeychainWrapper.save(key: "COGNITO_IDENTITY_POOL_ID", data: Data(id.utf8))
        if result == false {
            print("Failed saving pool id in keychain.")
        } else {
            await listViewModel.initializeSynthesizer(ttsService: .amazonPolly)
        }
    }

    private func loadFromKeychain() {
        if let idData = KeychainWrapper.load(key: "COGNITO_IDENTITY_POOL_ID"),
           let idString = String(data: idData, encoding: .utf8) {
            identityPoolID = idString
        }
    }
    
    private func deleteFromKeychain() {
        let result = KeychainWrapper.delete(key: "COGNITO_IDENTITY_POOL_ID")
        if result == false {
            print("Failed deleting pool id from keychain.")
        } else {
            listViewModel.synthesizerDict[.amazonPolly] = nil
        }
    }
}

