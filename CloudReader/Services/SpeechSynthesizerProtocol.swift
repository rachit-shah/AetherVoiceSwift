protocol SpeechSynthesizerProtocol {
    var selectedVoiceIdentifier: String { get }
    var selectedLanguageCode: String { get }
    var selectedEngine: String { get }
    var delegate: SpeechSynthesizerDelegate? { get set }
    func speak(text: String) async
    func stopSpeaking()
    func supportedEngines() -> [String]
    func supportedLanguages() async -> [String]
    func supportedVoices() async -> [String]
    func setEngine(engine: String)
    func setLanguage(language: String)
    func setVoice(voice: String)
    // Add other common methods as needed
}

protocol SpeechSynthesizerDelegate: AnyObject {
    func didFinishSpeaking()
}
