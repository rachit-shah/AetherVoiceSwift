import SwiftUI

struct DocumentListView: View {
    @ObservedObject var viewModel: DocumentListViewModel

    var body: some View {
        List(viewModel.documents) { document in
            NavigationLink(destination: IntermediateReaderView(document: document)) {
                Text(document.title)
            }
        }
        .navigationTitle("Documents")
        .onAppear {
            viewModel.fetchDocuments()
        }
    }
}

// Intermediate view to handle async initialization
struct IntermediateReaderView: View {
    var document: AppDocument
    @State private var viewModel: DocumentReaderViewModel?

    var body: some View {
        if let viewModel = viewModel {
            DocumentReaderView(viewModel: viewModel)
        } else {
            Text("Loading...")
                .task {
                    viewModel = try? await DocumentReaderViewModel(document: document)
                }
        }
    }
}
