import AVFoundation

class LocalSpeechSynthesizer: NSObject, SpeechSynthesizerProtocol, AVSpeechSynthesizerDelegate {
    weak var delegate: SpeechSynthesizerDelegate?
    private let synthesizer = AVSpeechSynthesizer()
    private var sentences: [String]
    private var currentSpeakingRange: NSRange = NSRange()
    internal var selectedVoiceIdentifier: String = "com.apple.voice.compact.en-US.Samantha"
    internal var selectedLanguageCode: String = "en-US"
    
    init(sentences: [String], delegate: SpeechSynthesizerDelegate?) {
        self.sentences = sentences
        self.delegate = delegate
        super.init()
        synthesizer.delegate = self
    }

    func setLanguage(language: String) {
        selectedLanguageCode = language
        // Update the selected voice based on the new language if needed
    }

    func setVoice(voice: String) {
        selectedVoiceIdentifier = voice
    }

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func supportedLanguages() -> [String] {
        let allLanguages = AVSpeechSynthesisVoice.speechVoices().map { $0.language }
        let uniqueLanguages = Set(allLanguages)
        return Array(uniqueLanguages).sorted()  // Convert back to sorted array
    }

    func supportedVoices() -> [String] {
        // Filter the voices to only those that match the selected language
        return AVSpeechSynthesisVoice.speechVoices()
               .filter { $0.language == selectedLanguageCode }
               .map { $0.identifier }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        guard let range = Range(characterRange, in: utterance.speechString) else { return }
        updateCurrentSentenceIndex(speechString: utterance.speechString, upTo: range.lowerBound)
    }

    private func updateCurrentSentenceIndex(speechString: String, upTo index: String.Index) {
        let substring = String(speechString[..<index])
        let sentences = DocumentReaderViewModel.splitIntoSentences(text: substring)
        delegate?.didStartSpeaking(sentenceIndex: sentences.count - 1)
    }
}
