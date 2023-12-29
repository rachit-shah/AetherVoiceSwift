import SwiftUI



struct DocumentReaderView: View {
    @ObservedObject var viewModel: DocumentReaderViewModel
    @State private var showingSettings = false
    @State private var startAtMiddle = false

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(0..<viewModel.sentences.count, id: \.self) { index in
                        Text(viewModel.sentences[index])
                            .foregroundColor(index == viewModel.currentSentenceIndex ? .blue : .gray)
                            .padding(.bottom, 3)
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    startAtMiddle = true
                                    viewModel.currentSentenceIndex = index
                                    viewModel.isSpeaking = true
                                }
                            }
                    }
                    .onChange(of: viewModel.currentSentenceIndex) { oldValue, newValue in
                        print("Finished reading \(oldValue), now reading \(newValue)")
                        if newValue >= viewModel.sentences.count {
                            DispatchQueue.main.async {
                                viewModel.currentSentenceIndex = 0
                                viewModel.isSpeaking = false
                            }
                        }
                        if viewModel.isSpeaking {
                            Task {
                                await viewModel.startReading()
                            }
                            if startAtMiddle == true {
                                startAtMiddle = false
                            }
                        }
                    }
                    .onChange(of: viewModel.isSpeaking) { oldValue, newValue in
                        print("Value was \(oldValue), now \(newValue)")
                        if newValue == true && oldValue == false && startAtMiddle == false {
                            Task {
                                await viewModel.startReading()
                            }
                        } else if newValue == false && oldValue == true {
                            viewModel.stopReadingText()
                        }
                    }
                }
                .padding()
            }
            // TTS Controls Toolbar at the Bottom
            HStack {
                Spacer()

                Button(action: {viewModel.moveToPreviousSentence()}) {
                    Image(systemName: "arrow.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)  // Adjust size as needed
                }
                .buttonStyle(PlainButtonStyle())
                .padding()

                Button(action: {viewModel.toggleSpeech()}) {
                    Image(systemName: viewModel.isSpeaking ? "pause.fill" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)  // Adjust size as needed
                }
                .buttonStyle(PlainButtonStyle())
                .padding()

                Button(action: {viewModel.moveToNextSentence()}) {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)  // Adjust size as needed
                }
                .buttonStyle(PlainButtonStyle())
                .padding()

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ttsToolbarContent
            }
            #elseif os(macOS)
            ToolbarItemGroup {
                ttsToolbarContent
            }
            #endif
        }
        .sheet(isPresented: $showingSettings) {
            TTSConfigView(viewModel: viewModel)
        }
        .navigationTitle(viewModel.document.title)
        .onDisappear {
            viewModel.stopReadingText()
        }
    }

    @ViewBuilder
    private var ttsToolbarContent: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gear")
        }
    }
}

struct TTSConfigView: View {
    @ObservedObject var viewModel: DocumentReaderViewModel

    var body: some View {
        Form {
            Picker("TTS", selection: $viewModel.selectedTTSService) {
                Text("Local").tag(DocumentReaderViewModel.TTSService.local)
                Text("Polly").tag(DocumentReaderViewModel.TTSService.amazonPolly)
                Text("GCloud").tag(DocumentReaderViewModel.TTSService.googleCloud)
                Text("Azure").tag(DocumentReaderViewModel.TTSService.microsoftAzure)
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: viewModel.selectedTTSService) { _, _ in
                viewModel.selectedEngine = "standard"
                viewModel.selectedLanguage = "en-US"
                viewModel.selectedVoice = ""
            }
            
            Picker("Engine", selection: $viewModel.selectedEngine) {
                ForEach(viewModel.availableEngines, id: \.self) { language in
                    Text(language).tag(language)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: viewModel.selectedEngine) { _, _ in
                viewModel.selectedLanguage = "en-US"
                viewModel.selectedVoice = ""
            }
            
            Picker("Lang", selection: $viewModel.selectedLanguage) {
                ForEach(viewModel.availableLanguages, id: \.self) { language in
                    Text(language).tag(language)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: viewModel.selectedEngine) { _, _ in
                viewModel.selectedVoice = ""
            }

            Picker("Voice", selection: $viewModel.selectedVoice) {
                ForEach(viewModel.availableVoices, id: \.self) { voice in
                    Text(voice).tag(voice)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}
