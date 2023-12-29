import AVFoundation

class LocalSpeechSynthesizer: NSObject, SpeechSynthesizerProtocol, AVSpeechSynthesizerDelegate {
    weak var delegate: SpeechSynthesizerDelegate?
    private let synthesizer = AVSpeechSynthesizer()
    private var sentences: [String]
    private var currentSpeakingRange: NSRange = NSRange()
    internal var selectedVoiceIdentifier: String = "com.apple.voice.compact.en-US.Samantha"
    internal var selectedLanguageCode: String = "en-US"
    internal var selectedEngine: String = "standard"
    
    init(sentences: [String], delegate: SpeechSynthesizerDelegate?) {
        self.sentences = sentences
        self.delegate = delegate
        super.init()
        synthesizer.delegate = self
    }

    func setEngine(engine: String) {
        selectedEngine = engine
    }
    
    func setLanguage(language: String) {
        selectedLanguageCode = language
    }

    func setVoice(voice: String) {
        selectedVoiceIdentifier = voice
    }

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)
        synthesizer.speak(utterance)
        print("Speaking text Local: \(text).")
        LocalSpeechSynthesizer.saveCharactersProcessed(count: text.count, engine: selectedEngine)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func supportedEngines() -> [String] {
        return ["standard"]
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
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        delegate?.didFinishSpeaking()
    }
    
    static func saveCharactersProcessed(count: Int, engine: String) {
        var charactersProcessed = getCharactersProcessed()
        let charactersProcessedForEngine = charactersProcessed[engine, default: 0]
        charactersProcessed[engine] = charactersProcessedForEngine + count
        UserDefaults.standard.set(charactersProcessed, forKey: "localCharactersProcessed")
    }

    static func getCharactersProcessed() -> [String:Int] {
        return UserDefaults.standard.dictionary(forKey: "localCharactersProcessed") as? [String: Int] ?? [String: Int]()
    }
}
