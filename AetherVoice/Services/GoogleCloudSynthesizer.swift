import Foundation
import AVFoundation
import GoogleAPIClientForREST_Texttospeech

class GoogleCloudSynthesizer: NSObject, SpeechSynthesizerProtocol, AVAudioPlayerDelegate {
    
    internal var selectedEngine: String?
    internal var selectedVoiceIdentifier: String?
    internal var selectedLanguageCode: String?
    weak var delegate: SpeechSynthesizerDelegate?
    
    private var voices: [GTLRTexttospeech_Voice]
    private var gcpTtsClient: GTLRTexttospeechService
    private var audioPlayer: AVAudioPlayer

    init(gcpApiKey: String) throws {
        self.gcpTtsClient = GTLRTexttospeechService()
        self.gcpTtsClient.isRetryEnabled = true
        self.gcpTtsClient.apiKey = gcpApiKey
        self.gcpTtsClient.apiKeyRestrictionBundleID = Bundle.main.bundleIdentifier
        self.voices = []
        self.audioPlayer = AVAudioPlayer()
        super.init()
        try listVoices()
    }
    
    static func getGcpApiKeyFromKeychain() -> String? {
        if let idData = KeychainWrapper.load(key: "GCP_API_KEY"),
           let idString = String(data: idData, encoding: .utf8) {
            return idString
        } else {
            return nil
        }
    }

    func speak(text: String) async throws {
        if selectedEngine == nil || selectedVoiceIdentifier == nil || selectedLanguageCode == nil {
            throw SynthesizerError.userError("Need to select engine, language and/or voice in the reader settings.")
        }
        let input = GTLRTexttospeech_SynthesisInput()
        input.text = text

        let voice = GTLRTexttospeech_VoiceSelectionParams()
        voice.languageCode = selectedLanguageCode
        voice.name = selectedVoiceIdentifier

        let audioConfig = GTLRTexttospeech_AudioConfig()
        audioConfig.audioEncoding = "MP3"

        let request = GTLRTexttospeech_SynthesizeSpeechRequest()
        request.input = input
        request.voice = voice
        request.audioConfig = audioConfig
        print(request)
        let query = GTLRTexttospeechQuery_TextSynthesize.query(withObject: request)
        var speakError: Error?
        self.gcpTtsClient.executeQuery(query) { (ticket, response, err) in
            do {
                if let err = err {
                    print("Failed to speak using GCP: \(err). \(ticket)")
                    speakError = err
                }
                
                if let response = response as? GTLRTexttospeech_SynthesizeSpeechResponse,
                   let audioContent = response.audioContent,
                   let speech = Data(base64Encoded: audioContent) {
                    print("Speaking text GCP: \(text). \(speech)")
                    self.audioPlayer = try AVAudioPlayer(data: speech)
                    self.audioPlayer.delegate = self
                    self.audioPlayer.play()
                    GoogleCloudSynthesizer.saveCharactersProcessed(count: text.count, engine: self.selectedEngine!)
                }
            } catch {
                print("Failed to speak using GCP: \(error).")
                speakError = SynthesizerError.audioPlaybackError("Audio Playback Error: \(error.localizedDescription)")
            }
        }
        if speakError != nil {
            throw SynthesizerError.synthesizerError("GCP Error: \(speakError.debugDescription)")
        }
    }

    func stopSpeaking() {
        // Stop any ongoing speech
        if self.audioPlayer.isPlaying == true {
            self.audioPlayer.stop()
        }
    }
    
    private func listVoices() throws {
        let query = GTLRTexttospeechQuery_VoicesList.query()
        self.gcpTtsClient.executeQuery(query) { [self] (ticket, response, err) in
            print("GCP Query:")
            print(ticket)
            print(response ?? "No response")
            print(err ?? "No error")
            if let err = err {
                print("Failed to get voices from GCP: \(err). \(ticket)")
            }
            print("Listing GCP Voices")
            print(response.debugDescription)
            let response = response as? GTLRTexttospeech_ListVoicesResponse
            self.voices = response?.voices ?? []
            print(self.voices)
        }
    }
    
    func supportedEngines() -> [String] {
        let allEngines = self.voices.map {
            let nameComponents = $0.name!.components(separatedBy: "-")
            return nameComponents[2]
        }
        let uniqueEngines = Array(Set(allEngines))
        print("GCP Supported Engines \(uniqueEngines)")
        return Array(uniqueEngines).sorted()
    }

    func supportedLanguages() -> [String] {
        if selectedEngine == nil {
            return []
        }
        let filteredVoices = self.voices.filter {
            selectedEngine == $0.name!.components(separatedBy: "-")[2]
        }
        let allLanguages = filteredVoices.map { $0.languageCodes ?? [] }.reduce([], +)
        let uniqueLanguages = Array(Set(allLanguages))
        print("GCP Supported Languages \(uniqueLanguages)")
        return Array(uniqueLanguages).sorted()
    }

    func supportedVoices() -> [String] {
        if selectedEngine == nil || selectedLanguageCode == nil {
            return []
        }
        let supportedVoices = self.voices.filter {
            let languageFlag = $0.languageCodes!.contains(selectedLanguageCode!)
            let engineFlag = selectedEngine == $0.name!.components(separatedBy: "-")[2]
            return languageFlag && engineFlag
        }.map { $0.name! }
        print("GCP Supported Voices \(supportedVoices)")
        return supportedVoices
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
    
    // AVAudioPlayerDelegate method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.didFinishSpeaking()
    }
    
    static func saveCharactersProcessed(count: Int, engine: String) {
        var charactersProcessed = getCharactersProcessed()
        let charactersProcessedForEngine = charactersProcessed[engine, default: 0]
        charactersProcessed[engine] = charactersProcessedForEngine + count
        UserDefaults.standard.set(charactersProcessed, forKey: "gcpCharactersProcessed")
    }

    static func getCharactersProcessed() -> [String:Int] {
        return UserDefaults.standard.dictionary(forKey: "gcpCharactersProcessed") as? [String: Int] ?? [String: Int]()
    }
}
