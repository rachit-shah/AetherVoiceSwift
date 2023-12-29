import Foundation
import AVFoundation
import NaturalLanguage

@MainActor
class DocumentReaderViewModel: ObservableObject, SpeechSynthesizerDelegate {
    enum TTSService {
        case local, amazonPolly, googleCloud, microsoftAzure
    }

    @Published var currentSentenceIndex = 0
    @Published var isSpeaking = false
    
    @Published var selectedLanguage: String = "en-US" {
        didSet {
            Task {
                stopReadingText()
                await updateVoicesForSelectedLanguage()
            }
        }
    }
    @Published var selectedVoice: String = "Joanna" {
        didSet {
            stopReadingText()
            updateSynthesizerVoice()
        }
    }
    @Published var availableLanguages: [String] = ["en-US"]
    @Published var availableVoices: [String] = ["Default"]
    @Published var availableEngines: [String] = ["standard"]
    
    @Published var selectedTTSService: TTSService = .amazonPolly {
        didSet {
            Task {
                stopReadingText()
                try await updateSelectedSynthesizer()
            }
        }
    }
    
    @Published var selectedEngine: String = "standard" {
        didSet {
            Task {
                stopReadingText()
                await updateVoicesForSelectedLanguage()
            }
        }
    }

    let document: AppDocument
    var sentences: [String]
    var speechSynthesizer: SpeechSynthesizerProtocol
    
    init(document: AppDocument) async throws {
        self.document = document
        self.sentences = DocumentReaderViewModel.splitIntoSentences(text: document.content)
        self.speechSynthesizer = LocalSpeechSynthesizer(sentences: self.sentences, delegate: nil)
        self.speechSynthesizer = LocalSpeechSynthesizer(sentences: self.sentences, delegate: self)
        try await updateSelectedSynthesizer()
    }

    func startReading() async {
        guard currentSentenceIndex < sentences.count else { return }
        let sentenceToRead = sentences[currentSentenceIndex]
        await speechSynthesizer.speak(text: sentenceToRead)
    }

    func stopReadingText() {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        speechSynthesizer.stopSpeaking()
    }

    func toggleSpeech() {
        if self.isSpeaking == true {
            DispatchQueue.main.async {
                self.isSpeaking = false
            }
        } else {
            DispatchQueue.main.async {
                self.isSpeaking = true
            }
        }
    }

    func moveToPreviousSentence() {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentSentenceIndex = max(self.currentSentenceIndex - 1, 0)
            self.isSpeaking = true
        }
    }

    func moveToNextSentence() {
        if currentSentenceIndex < sentences.count - 1 {
            DispatchQueue.main.async {
                self.isSpeaking = false
                self.currentSentenceIndex += 1
                self.isSpeaking = true
            }
        }
    }

    private func updateSelectedSynthesizer() async throws {
        switch selectedTTSService {
        case .local:
            speechSynthesizer = LocalSpeechSynthesizer(sentences: sentences, delegate: self)
        case .amazonPolly:
            // Initialize Amazon Polly Speech Synthesizer
            speechSynthesizer = try AmazonPollySynthesizer(sentences: sentences, delegate: self)
        case .googleCloud:
            // Initialize Google Cloud Speech Synthesizer
            speechSynthesizer = LocalSpeechSynthesizer(sentences: sentences, delegate: self)
        case .microsoftAzure:
            // Initialize Microsoft Azure Speech Synthesizer
            speechSynthesizer = LocalSpeechSynthesizer(sentences: sentences, delegate: self)
        }
        availableEngines = speechSynthesizer.supportedEngines()
        availableLanguages = await speechSynthesizer.supportedLanguages()
        availableVoices = await speechSynthesizer.supportedVoices()
        selectedLanguage = speechSynthesizer.selectedLanguageCode
        selectedVoice = speechSynthesizer.selectedVoiceIdentifier
        speechSynthesizer.setLanguage(language: selectedLanguage)
        speechSynthesizer.setVoice(voice: selectedVoice)
    }
    
    private func updateVoicesForSelectedLanguage() async {
        speechSynthesizer.setEngine(engine: selectedEngine)
        speechSynthesizer.setLanguage(language: selectedLanguage)
        availableVoices = await speechSynthesizer.supportedVoices()
        selectedVoice = availableVoices.first ?? "Default"
        speechSynthesizer.setVoice(voice: selectedVoice)
    }

    private func updateSynthesizerVoice() {
        speechSynthesizer.setVoice(voice: selectedVoice)
    }

    static func splitIntoSentences(text: String) -> [String] {
        var sentences = [String]()
        let cleanedText = text.replacingOccurrences(of: "\n", with: " ")
                             .replacingOccurrences(of: "\r", with: " ")

        var currentSentence = ""
        var insideQuotes = false

        for character in cleanedText {
            if character == "\"" || character == "「" {
                if !insideQuotes && !currentSentence.trimmingCharacters(in: .whitespaces).isEmpty {
                    sentences.append(currentSentence.trimmingCharacters(in: .whitespaces))
                    currentSentence = ""
                }
                insideQuotes.toggle()
            } else if character == "」" || (character == "\"" && insideQuotes) {
                insideQuotes = false
                currentSentence.append(character)
                sentences.append(currentSentence.trimmingCharacters(in: .whitespaces))
                currentSentence = ""
                continue
            }

            if (character == "." || character == "。"), !insideQuotes {
                currentSentence.append(character)
                sentences.append(currentSentence.trimmingCharacters(in: .whitespaces))
                currentSentence = ""
            } else {
                currentSentence.append(character)
            }
        }

        if !currentSentence.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(currentSentence.trimmingCharacters(in: .whitespaces))
        }

        return sentences.filter { !$0.isEmpty }
    }
    
    nonisolated func didFinishSpeaking() {
        DispatchQueue.main.async {
            print("Finished speaking \(self.currentSentenceIndex)")
            self.currentSentenceIndex += 1
        }
    }
}

