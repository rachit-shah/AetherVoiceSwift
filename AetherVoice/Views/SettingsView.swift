import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var listViewModel: DocumentListViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AWS Configuration")) {
                    NavigationLink("Setup Amazon Polly", destination: AWSSettingsView(listViewModel: listViewModel))
                }
                Section(header: Text("GCP Configuration")) {
                    NavigationLink("Setup Google Cloud Text To Speech", destination: GCPSettingsView(listViewModel: listViewModel))
                }
            }
            .navigationTitle("Settings")
        }
    }
}
