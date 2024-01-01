import SwiftUI

struct DocumentListView: View {
    @ObservedObject var viewModel: DocumentListViewModel

    var body: some View {
        List(viewModel.documents) { document in
            NavigationLink(destination: DocumentReaderView(viewModel: DocumentReaderViewModel(document: document, synthesizerDict: viewModel.synthesizerDict))) {
                Text(document.title)
            }
        }
        .navigationTitle("Documents")
        .onAppear {
            viewModel.fetchDocuments()
        }
    }
}
