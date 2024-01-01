import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: DocumentListViewModel
    @State private var showingSettings = false
    #if os(iOS)
    @State private var showingActionSheet = false
    @State private var showingDocumentPicker = false
    #endif

    var body: some View {
        NavigationView {
            DocumentListView(viewModel: viewModel)
                .frame(minWidth: 200)
                .navigationTitle("Documents")
                // Platform-specific UI
                #if os(iOS)
                .navigationBarItems(trailing: HStack {
                    settingsButton
                    addButtoniOS
                })
                .sheet(isPresented: $showingSettings) {
                    SettingsView(listViewModel: viewModel)
                }
                #elseif os(macOS)
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        Button(action: {
                            self.showingSettings.toggle()
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                        .popover(isPresented: $showingSettings) {
                            SettingsView(listViewModel: viewModel)
                                .frame(width: 300)
                                .padding()
                        }
                        addButtonmacOS
                    }
                }
                #endif
        }
    }
    
    private var settingsButton: some View {
        Button("Settings") {
            showingSettings = true
        }
    }

    #if os(iOS)
    private var addButtoniOS: some View {
        Button(action: {
            showingActionSheet = true
        }) {
            Image(systemName: "plus")
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Add Document"), message: Text("Choose an option"), buttons: [
                .default(Text("Upload a Document")) {
                    showingDocumentPicker = true
                },
                .default(Text("Link a Webpage")) {
                    // Implement webpage linking functionality
                },
                .cancel()
            ])
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(allowedContentTypes: [.plainText, .pdf, .epub]) { url in
                // Handle the picked document URL
                viewModel.processDocument(at: url)
            }
        }
    }
    #endif

    #if os(macOS)
    private var addButtonmacOS: some View {
        MenuButton(label: Image(systemName: "plus")) {
            Button("Upload a Document") {
                viewModel.uploadDocument()
            }
            Button("Link a Webpage") {
                // Implement webpage linking functionality
            }
        }
    }
    #endif
    
    #if os(iOS)
    func uploadDocument() {
        showingDocumentPicker = true
    }
    #endif
}

// Intermediate view to handle async initialization
struct IntermediateListView: View {
    @State var viewModel: DocumentListViewModel?

    var body: some View {
        if let viewModel = viewModel {
            ContentView(viewModel: viewModel)
        } else {
            Text("Loading...")
                .task {
                    viewModel = await DocumentListViewModel()
                }
        }
    }
}
