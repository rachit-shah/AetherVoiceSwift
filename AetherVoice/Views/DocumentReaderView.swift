import SwiftUI
import MediaPlayer

struct DocumentReaderView: View {
    @StateObject var viewModel: DocumentReaderViewModel
    @State private var showingSettings = false
    @State private var startAtMiddle = false

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(0..<viewModel.sentences.count, id: \.self) { index in
                        Text(viewModel.sentences[index].text)
                            .foregroundColor(index == viewModel.currentSentenceIndex ? .blue : .gray)
                            .padding(.bottom, 3)
                            .onTapGesture {
                                print("Tapped sentence \(index)")
                                startAtMiddle = true
                                viewModel.currentSentenceIndex = index
                                viewModel.isSpeaking = true
                            }
                    }
                    .onChange(of: viewModel.currentSentenceIndex) { oldValue, newValue in
                        print("Finished reading \(oldValue), now reading \(newValue)")
                        if oldValue >= viewModel.sentences.count {
                            print("Reached last sentence. Stopping to read.")
                            viewModel.currentSentenceIndex = 0
                            viewModel.isSpeaking = false
                        }
                        if viewModel.isSpeaking {
                            print("Start reading due to tap or continue reading")
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
                            print("Start reading due to play button")
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
        #if os(iOS)
        .sheet(isPresented: $showingSettings) {
            TTSConfigView(viewModel: viewModel)
        }
        #elseif os(macOS)
        .popover(isPresented: $showingSettings) {
            TTSConfigView(viewModel: viewModel)
                .padding()
        }
        #endif
        .navigationTitle(viewModel.document.title)
        .onAppear {
            setupRemoteCommands()
        }
        .onDisappear {
            viewModel.stopReadingText()
        }
        .alert("Error", isPresented: Binding<Bool>.constant(viewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }

    @ViewBuilder
    private var ttsToolbarContent: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gear")
        }
    }
    
    private func setupRemoteCommands() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        remoteCommandCenter.playCommand.addTarget { [self] event in
            self.viewModel.toggleSpeech()
            return .success
        }

        remoteCommandCenter.pauseCommand.addTarget { [self] event in
            self.viewModel.toggleSpeech()
            return .success
        }

        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [15] // Skip backward by 15 seconds
        remoteCommandCenter.skipBackwardCommand.addTarget { [self] event in
            self.viewModel.moveToPreviousSentence()
            return .success
        }

        remoteCommandCenter.skipForwardCommand.preferredIntervals = [15] // Skip forward by 15 seconds
        remoteCommandCenter.skipForwardCommand.addTarget { [self] event in
            self.viewModel.moveToNextSentence()
            return .success
        }

        // Update now playing info
        updateNowPlayingInfo(title: viewModel.document.title)
    }

    private func updateNowPlayingInfo(title: String) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

struct TTSConfigView: View {
    @ObservedObject var viewModel: DocumentReaderViewModel

    var body: some View {
        Form {
            Picker("TTS", selection: $viewModel.selectedTTSService) {
                ForEach(viewModel.availableSynthesizers, id: \.self) { service in
                    Text(service.rawValue).tag(service)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Picker("Engine", selection: $viewModel.selectedEngine) {
                ForEach(viewModel.availableEngines, id: \.self) { engine in
                    Text(engine).tag(engine)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Picker("Lang", selection: $viewModel.selectedLanguage) {
                ForEach(viewModel.availableLanguages, id: \.self) { language in
                    Text(language).tag(language)
                }
            }
            .pickerStyle(MenuPickerStyle())

            Picker("Voice", selection: $viewModel.selectedVoice) {
                ForEach(viewModel.availableVoices, id: \.self) { voice in
                    Text(voice).tag(voice)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}
