import SwiftUI

struct DocumentUploadView: View {
    @ObservedObject var viewModel: DocumentUploadViewModel

    var body: some View {
        VStack {
            Button(action: {
                viewModel.showDocumentPicker = true
            }) {
                Text("Upload Document")
            }
            .sheet(isPresented: $viewModel.showDocumentPicker) {
                // Document picker view will be here
            }
        }
    }
}
