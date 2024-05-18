import SwiftUI

struct DocumentListView: View {
    @ObservedObject var viewModel: DocumentListViewModel

    var body: some View {
        List {
            ForEach(viewModel.documents) { document in
                NavigationLink(destination: DocumentReaderView(viewModel: DocumentReaderViewModel(document: document, synthesizerDict: viewModel.synthesizerDict))) {
                    Text(document.title)
                }
                #if os(macOS)
                .contextMenu {
                    Button(action: {
                        viewModel.deleteDocument(document)
                    }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                }
                #endif
            }
            #if os(iOS)
            .onDelete(perform: deleteDocuments)
            #endif
        }
        .navigationTitle("Documents")
        .onAppear {
            viewModel.fetchDocuments()
        }
    }
    
    private func deleteDocuments(at offsets: IndexSet) {
        viewModel.deleteDocuments(at: offsets)
    }
}
