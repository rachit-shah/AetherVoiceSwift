protocol SpeechSynthesizerProtocol {
    var selectedVoiceIdentifier: String { get }
    var selectedLanguageCode: String { get }
    func speak(text: String)
    func stopSpeaking()
    func supportedLanguages() -> [String]
    func supportedVoices() -> [String]
    func setLanguage(language: String)
    func setVoice(voice: String)
    // Add other common methods as needed
}

protocol SpeechSynthesizerDelegate: AnyObject {
    func didStartSpeaking(sentenceIndex: Int)
}
