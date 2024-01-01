import AVFoundation

class MicrosoftAzureSynthesizer: NSObject, SpeechSynthesizerProtocol, AVSpeechSynthesizerDelegate {
    
    internal var selectedEngine: String?
    internal var selectedVoiceIdentifier: String?
    internal var selectedLanguageCode: String?
    weak var delegate: SpeechSynthesizerDelegate?
    
    private let synthesizer = AVSpeechSynthesizer()
    private var voices: [AVSpeechSynthesisVoice]
    
    override init() {
        self.voices = []
        super.init()
        self.voices = self.listVoices()
        synthesizer.delegate = self
    }
    
    func setDelegate(delegate: SpeechSynthesizerDelegate) {
        self.delegate = delegate
    }

    func setEngine(engine: String?) {
        selectedEngine = engine
    }
    
    func setLanguage(language: String?) {
        selectedLanguageCode = language
    }

    func setVoice(voice: String?) {
        selectedVoiceIdentifier = voice
    }
    
    func speak(text: String) throws {
        if selectedEngine == nil || selectedVoiceIdentifier == nil {
            throw SynthesizerError.userError("Need to select engine, language and/or voice in the reader settings.")
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier!)
        synthesizer.speak(utterance)
        print("Speaking text Local: \(text).")
        LocalSpeechSynthesizer.saveCharactersProcessed(count: text.count, engine: selectedEngine!)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    private func listVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }
    
    func supportedEngines() -> [String] {
        return ["standard"]
    }

    func supportedLanguages() -> [String] {
        let allLanguages = self.voices.map { $0.language }
        let uniqueLanguages = Set(allLanguages)
        return Array(uniqueLanguages).sorted()  // Convert back to sorted array
    }

    func supportedVoices() -> [String] {
        if selectedLanguageCode == nil {
            return []
        }
        return self.voices
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
        UserDefaults.standard.set(charactersProcessed, forKey: "azureCharactersProcessed")
    }

    static func getCharactersProcessed() -> [String:Int] {
        return UserDefaults.standard.dictionary(forKey: "azureCharactersProcessed") as? [String: Int] ?? [String: Int]()
    }
}
