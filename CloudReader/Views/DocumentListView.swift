import SwiftUI

struct DocumentListView: View {
    @ObservedObject var viewModel: DocumentListViewModel

    var body: some View {
        List(viewModel.documents) { document in
            NavigationLink(destination: DocumentReaderView(viewModel: DocumentReaderViewModel(document: document))) {
                Text(document.title)
            }
        }
        .navigationTitle("Documents")
        .onAppear {
            viewModel.fetchDocuments()
        }
        // Add additional modifiers or platform-specific code if needed
    }
}

struct DocumentRow: View {
    var document: AppDocument

    var body: some View {
        HStack {
            Text(document.title)
            Spacer()
            // Additional information or icons can be added here
        }
    }
}
