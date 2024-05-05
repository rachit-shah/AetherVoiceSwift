import SwiftUI

struct AzureSettingsView: View {
    @ObservedObject var listViewModel: DocumentListViewModel
    @State private var azureApiKey: String = ""
    @State private var azureApiRegion: String = "northcentralus"
    @State private var isEditing = false
    var costPerMillionCharacters: [String: Double] = [
        "Neural": 15,
        "NeuralHD": 30
    ]

    var body: some View {
        Form {
            Section(header: Text("Azure Region")) {
                Text("The Azure Region for the Azure Speech Resource you setup. The voices available changes based on the region selected.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Link("See Setup Instructions", destination: URL(string: "https://github.com/rachit-shah/AetherVoiceSwift#setup-azure")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                Picker("Azure Region", selection: $azureApiRegion) {
                    ForEach(azureAvailableRegions, id: \.self) { region in
                        Text(region).tag(region)
                    }
                }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: azureApiRegion) {
                        Task {
                            await saveRegionToKeychain(azureApiRegion)
                        }
                    }
            }
            Section(header: Text("Azure Resource Key")) {
                Text("The Azure Resource Key acts like a password to access your Azure Speech Resource. Don't share it with anyone. The value will be securely stored in your keychain upon entering it.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Link("See Setup Instructions", destination: URL(string: "https://github.com/rachit-shah/AetherVoiceSwift#setup-azure")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                if isEditing {
                    TextField("Azure Resource Key", text: $azureApiKey)
                } else {
                    Text(maskedID)
                }
                
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task {
                            await saveToKeychain(azureApiKey)
                        }
                    }
                    isEditing.toggle()
                }

                Button("Delete", role: .destructive) {
                    deleteFromKeychain()
                    azureApiKey = ""
                }
            }
            Section(header: Text("Estimated Bill in your Azure account")) {
                Text("This estimate is based on the number of characters processed by each engine type and their respective costs as per Azure Text-to-Speech pricing. Note: This doesn't factor in any free-tier benefits you might have remaining.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                Link("Learn more about Azure Text-to-Speech Pricing", destination: URL(string: "https://azure.microsoft.com/en-us/pricing/details/cognitive-services/speech-services/")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                Text(printCharactersProcessed())
                Text("Estimated Cost: $\(calculateEstimatedCost())")
            }
        }
        .navigationTitle("Azure Cloud Text To Speech Settings")
        .padding()
        .onAppear {
            loadFromKeychain()
        }
    }
    
    private func printCharactersProcessed() -> String {
        var printStr = "Characters Processed By Voice Type (Estimated cost per million characters in braces as of Jan 2024):"
        let charactersProcessedDict = MicrosoftAzureSynthesizer.getCharactersProcessed()
        for (_, ele) in charactersProcessedDict.enumerated() {
            printStr += "\n - \(ele.key) - \(ele.value) ($\(costPerMillionCharacters[ele.key, default: 0]))"
        }
        return printStr
    }
    
    private func calculateEstimatedCost() -> String {
        var totalCost: Double = 0.0
        let charactersProcessedDict = MicrosoftAzureSynthesizer.getCharactersProcessed()
        for (_, ele) in charactersProcessedDict.enumerated() {
            let engine = ele.key
            totalCost += Double(ele.value) / 1_000_000 * costPerMillionCharacters[engine, default: 0]
        }
        return String(totalCost)
    }

    private var maskedID: String {
        !azureApiKey.isEmpty ? "●●●●●●" : "Not Set"
    }
    
    private var azureAvailableRegions: [String] {
        [
            "eastus",
            "eastus2",
            "southcentralus",
            "westus2",
            "westus3",
            "australiaeast",
            "southeastasia",
            "northeurope",
            "swedencentral",
            "uksouth",
            "westeurope",
            "centralus",
            "southafricanorth",
            "centralindia",
            "eastasia",
            "japaneast",
            "koreacentral",
            "canadacentral",
            "francecentral",
            "germanywestcentral",
            "norwayeast",
            "polandcentral",
            "switzerlandnorth",
            "uaenorth",
            "brazilsouth",
            "centraluseuap",
            "qatarcentral",
            "northcentralus",
            "westus",
            "westcentralus",
            "southafricawest",
            "australiacentral",
            "australiacentral2",
            "australiasoutheast",
            "japanwest",
            "koreasouth",
            "southindia",
            "westindia",
            "canadaeast",
            "francesouth",
            "germanynorth",
            "norwaywest",
            "switzerlandwest",
            "ukwest",
            "uaecentral",
            "brazilsoutheast"
        ]
    }

    private func saveToKeychain(_ id: String) async {
        let result = KeychainWrapper.save(key: "AZURE_API_KEY", data: Data(id.utf8))
        if result == false {
            print("Failed saving gcpApiKey in keychain.")
        } else {
            await listViewModel.initializeSynthesizer(ttsService: .microsoftAzure)
        }
    }
    
    private func saveRegionToKeychain(_ id: String) async {
        let result = KeychainWrapper.save(key: "AZURE_REGION", data: Data(id.utf8))
        if result == false {
            print("Failed saving azureApiRegion in keychain.")
        } else {
            await listViewModel.initializeSynthesizer(ttsService: .microsoftAzure)
        }
    }

    private func loadFromKeychain() {
        if let idData = KeychainWrapper.load(key: "AZURE_API_KEY"),
           let idString = String(data: idData, encoding: .utf8) {
            azureApiKey = idString
        }
        if let idRegionData = KeychainWrapper.load(key: "AZURE_REGION"),
           let idRegionString = String(data: idRegionData, encoding: .utf8) {
            azureApiRegion = idRegionString
        }
    }
    
    private func deleteFromKeychain() {
        let result = KeychainWrapper.delete(key: "AZURE_API_KEY")
        if result == false {
            print("Failed deleting azureApiKey from keychain.")
        } else {
            listViewModel.synthesizerDict[.microsoftAzure] = nil
        }
    }
}

