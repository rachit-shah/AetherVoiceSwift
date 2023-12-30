import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var identityPoolID: String = ""
    @State private var isEditing = false

    var body: some View {
        Form {
            Section(header: Text("AWS Configuration")) {
                Text("The Identity Pool ID acts like a password to access your AWS account's Polly resources. Don't share it with anyone. The value will be securely stored in your keychain upon entering it.")
                    .font(.caption)
                    .foregroundColor(.gray)
                if isEditing {
                    TextField("Identity Pool ID", text: $identityPoolID)
                } else {
                    Text(maskedID)
                }
                
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveToKeychain(identityPoolID)
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
                Text("Characters Processed: \n - Standard - \(AmazonPollySynthesizer.getCharactersProcessed()["standard", default: 0]) \n - Neural - \(AmazonPollySynthesizer.getCharactersProcessed()["neural", default: 0]) \n - Long-form - \(AmazonPollySynthesizer.getCharactersProcessed()["long-form", default: 0])")
                Text("Estimated Cost: \(calculateEstimatedCost())")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadFromKeychain()
        }
    }
    
    private func calculateEstimatedCost() -> String {
        let costPerMillionCharactersStandard = 4.00 // Example rate for standard
        let costPerMillionCharactersNeural = 16.00 // Example rate for neural
        let costPerMillionCharactersLongForm = 100.00 // Example rate for long-form
        let charactersProcessed = AmazonPollySynthesizer.getCharactersProcessed()
        let cost = Double(charactersProcessed["standard", default: 0]) / 1_000_000 * costPerMillionCharactersStandard + Double(charactersProcessed["neural", default: 0]) / 1_000_000 * costPerMillionCharactersNeural + Double(charactersProcessed["long-form", default: 0]) / 1_000_000 * costPerMillionCharactersLongForm

        return String(cost)
    }

    private var maskedID: String {
        !identityPoolID.isEmpty ? "●●●●●●" : "Not Set"
    }

    private func saveToKeychain(_ id: String) {
        let result = KeychainWrapper.save(key: "COGNITO_IDENTITY_POOL_ID", data: Data(id.utf8))
        if result == false {
            print("Failed saving pool id in keychain.")
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
        }
    }
}
