protocol SpeechSynthesizerProtocol {
    var selectedVoiceIdentifier: String? { get set }
    var selectedLanguageCode: String? { get set }
    var selectedEngine: String? { get set }
    var delegate: SpeechSynthesizerDelegate? { get set }
    func speak(text: String) async throws
    func stopSpeaking()
    func supportedEngines() -> [String]
    func supportedLanguages() -> [String]
    func supportedVoices() -> [String]
    func setDelegate(delegate: SpeechSynthesizerDelegate)
    func setEngine(engine: String?)
    func setLanguage(language: String?)
    func setVoice(voice: String?)
    static func saveCharactersProcessed(count: Int, engine: String)
    static func getCharactersProcessed() -> [String:Int]
    // Add other common methods as needed
}

protocol SpeechSynthesizerDelegate: AnyObject {
    func didFinishSpeaking()
    func didEncounterError(_ error: Error)
}

enum SynthesizerError: Error {
    case audioPlaybackError(String)
    case synthesizerError(String)
    case userError(String)
    
    var errorDescription: String? {
        switch self {
        case .audioPlaybackError(let message):
            return "Audio playback failed: \(message)"
        case .synthesizerError(let message):
            return "Failed to synthesize speech: \(message)"
        case .userError(let message):
            return "User error: \(message)"
        }
    }
}

enum TTSService: String, CaseIterable {
    case local, amazonPolly, googleCloud, microsoftAzure
}
