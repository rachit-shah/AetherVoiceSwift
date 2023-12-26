import Foundation
import AVFoundation
import NaturalLanguage

class DocumentReaderViewModel: ObservableObject, SpeechSynthesizerDelegate {
    enum TTSService {
        case local, amazonPolly, googleCloud, microsoftAzure
    }

    @Published var currentSentenceIndex = 0
    @Published var startSentenceIndex = 0
    @Published var isSpeaking = false
    
    @Published var selectedLanguage: String = "en-US" {
        didSet {
            stopReadingText()
            updateVoicesForSelectedLanguage()
        }
    }
    @Published var selectedVoice: String = "com.apple.voice.compact.en-US.Samantha" {
        didSet {
            stopReadingText()
            updateSynthesizerVoice()
        }
    }
    @Published var availableLanguages: [String] = ["en-US"]
    @Published var availableVoices: [String] = ["Default"]
    
    @Published var selectedTTSService: TTSService = .local {
        didSet {
            stopReadingText()
            updateSelectedSynthesizer()
        }
    }

    let document: AppDocument
    var sentences: [String]
    var speechSynthesizer: SpeechSynthesizerProtocol
    
    init(document: AppDocument) {
        self.document = document
        self.sentences = DocumentReaderViewModel.splitIntoSentences(text: document.content)
        self.speechSynthesizer = LocalSpeechSynthesizer(sentences: self.sentences, delegate: nil)
        self.speechSynthesizer = LocalSpeechSynthesizer(sentences: self.sentences, delegate: self)
        updateSelectedSynthesizer()
    }

    func startReading(from sentenceIndex: Int) {
        guard sentenceIndex < sentences.count else { return }

        stopReadingText()
        startSentenceIndex = sentenceIndex
        isSpeaking = true
        let textToRead = sentences[sentenceIndex...].joined(separator: " ")
        speechSynthesizer.speak(text: textToRead)
        currentSentenceIndex = sentenceIndex
    }

    func stopReadingText() {
        speechSynthesizer.stopSpeaking()
        isSpeaking = false
    }

    func toggleSpeech() {
        if isSpeaking {
            stopReadingText()
        } else {
            startReading(from: currentSentenceIndex)
        }
    }

    func moveToPreviousSentence() {
        let newIndex = max(currentSentenceIndex - 1, 0)
        startReading(from: newIndex)
    }

    func moveToNextSentence() {
        let newIndex = min(currentSentenceIndex + 1, sentences.count - 1)
        startReading(from: newIndex)
    }

    private func updateSelectedSynthesizer() {
        switch selectedTTSService {
        case .local:
            speechSynthesizer = LocalSpeechSynthesizer(sentences: sentences, delegate: self)
        case .amazonPolly:
            // Initialize Amazon Polly Speech Synthesizer
            speechSynthesizer = AmazonPollySynthesizer()
        case .googleCloud:
            // Initialize Google Cloud Speech Synthesizer
            speechSynthesizer = GoogleCloudSynthesizer()
        case .microsoftAzure:
            // Initialize Microsoft Azure Speech Synthesizer
            speechSynthesizer = MicrosoftAzureSynthesizer()
        }
        availableLanguages = speechSynthesizer.supportedLanguages()
        availableVoices = speechSynthesizer.supportedVoices()
        selectedLanguage = speechSynthesizer.selectedLanguageCode
        selectedVoice = speechSynthesizer.selectedVoiceIdentifier
        speechSynthesizer.setLanguage(language: selectedLanguage)
        speechSynthesizer.setVoice(voice: selectedVoice)
    }
    
    private func updateVoicesForSelectedLanguage() {
        availableVoices = speechSynthesizer.supportedVoices()
        selectedVoice = availableVoices.first ?? "Default"
        speechSynthesizer.setLanguage(language: selectedLanguage)
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
            if character == "\"" {
                insideQuotes.toggle() // Toggle the insideQuotes flag
            }

            if character == ".", !insideQuotes {
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
    
    func didStartSpeaking(sentenceIndex: Int) {
        DispatchQueue.main.async {
            self.currentSentenceIndex = self.startSentenceIndex + sentenceIndex
        }
    }
}

