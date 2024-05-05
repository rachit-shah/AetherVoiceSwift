import AVFoundation

class MicrosoftAzureSynthesizer: NSObject, SpeechSynthesizerProtocol, AVAudioPlayerDelegate {
    
    internal var selectedEngine: String?
    internal var selectedVoiceIdentifier: String?
    internal var selectedLanguageCode: String?
    weak var delegate: SpeechSynthesizerDelegate?
    
    private var voices: [AzureVoice]
    private var audioPlayer: AVAudioPlayer
    
    private var azureSubscriptionKey: String
    private var azureTTSEndpoint: String
    
    init(azureRegion: String, azureApiKey: String) throws {
        self.azureTTSEndpoint = "https://\(azureRegion).tts.speech.microsoft.com"
        self.azureSubscriptionKey = azureApiKey
        self.voices = []
        self.audioPlayer = AVAudioPlayer()
        super.init()
        print("Listing Azure Voices")
        listVoices()
    }
    
    static func getAzureSettingsFromKeychain() -> (azureRegion: String?, azureApiKey: String?) {
        if let apiKeyData = KeychainWrapper.load(key: "AZURE_API_KEY"),
           let apiKeyString = String(data: apiKeyData, encoding: .utf8) {
            if let apiRegionData = KeychainWrapper.load(key: "AZURE_REGION"),
               let apiRegionString = String(data: apiRegionData, encoding: .utf8) {
                return (azureRegion: apiRegionString, azureApiKey: apiKeyString)
            }
        }
        return (azureRegion: nil, azureApiKey: nil)
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
        if selectedEngine == nil || selectedVoiceIdentifier == nil || selectedLanguageCode == nil {
            throw SynthesizerError.userError("Need to select engine, language and/or voice in the reader settings.")
        }
        let url = URL(string: "\(azureTTSEndpoint)/cognitiveservices/v1")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("audio-24khz-160kbitrate-mono-mp3", forHTTPHeaderField: "X-Microsoft-OutputFormat")
        request.setValue("application/ssml+xml", forHTTPHeaderField: "Content-Type")
        request.setValue("AetherVoice", forHTTPHeaderField: "User-Agent")
        request.setValue(azureSubscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let ssmlBody = """
            <speak version='1.0' xml:lang='\(selectedLanguageCode ?? "en-US")'>
                <voice xml:lang='\(selectedLanguageCode ?? "en-US")' name='\(selectedVoiceIdentifier ?? "en-US-ChristopherNeural")'>
                \(text)
                </voice>
            </speak>
        """
        request.httpBody = ssmlBody.data(using: .utf8)
        var speakError: Error?
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                speakError = error
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server responded with an error")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                print("Speaking text Azure: \(text). \(data)")
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer.delegate = self
                self.audioPlayer.play()
                MicrosoftAzureSynthesizer.saveCharactersProcessed(count: text.count, engine: self.selectedEngine ?? "Neural")
            } catch {
                print("Failed to speak using Azure: \(error).")
                speakError = SynthesizerError.audioPlaybackError("Audio Playback Error: \(error.localizedDescription)")
            }
        }
        task.resume()
        if speakError != nil {
            throw SynthesizerError.synthesizerError("Azure Error: \(speakError.debugDescription)")
        }
    }

    func stopSpeaking() {
        // Stop any ongoing speech
        if self.audioPlayer.isPlaying == true {
            self.audioPlayer.stop()
        }
    }
    
    private func listVoices() {
        let voicesUrl = URL(string: "\(azureTTSEndpoint)/cognitiveservices/voices/list")!
        var request = URLRequest(url: voicesUrl)
        request.httpMethod = "GET"
        request.addValue(azureSubscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            print("Azure List Voices Query:")
            print(data ?? "No data")
            print(response ?? "No response")
            print(error ?? "No error")
            if let error = error {
                print("Error fetching voices: \(error.localizedDescription)")
            } else if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
                    print(type(of: json))
                    print(json)
                    var foundVoices: [AzureVoice] = []
                    json.forEach { ele in
                        let azureVoice = AzureVoice(
                            name: ele["ShortName"] as! String,
                            gender: ele["Gender"] as! String,
                            locale: ele["Locale"] as! String,
                            secondaryLocaleList: ele["SecondaryLocaleList", default: []] as! [String],
                            styleList: ele["StyleList", default: []] as! [String],
                            voiceType: ele["VoiceType"] as! String
                        )
                        foundVoices.append(azureVoice)
                    }
                    self.voices = foundVoices
                    print(self.voices)
                } catch {
                    print("Error parsing voice data: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    
    func supportedEngines() -> [String] {
        let allEngines = self.voices.map {
            $0.voiceType
        }
        let uniqueEngines = Array(Set(allEngines))
        print("Azure Supported Engines \(uniqueEngines)")
        return Array(uniqueEngines).sorted()
    }

    func supportedLanguages() -> [String] {
        if selectedEngine == nil {
            return []
        }
        let filteredVoices = self.voices.filter {
            selectedEngine == $0.voiceType
        }
        let allLanguages = filteredVoices.map {
            $0.secondaryLocaleList + [$0.locale]
        }.reduce([], +)
        let uniqueLanguages = Array(Set(allLanguages))
        print("Azure Supported Languages \(uniqueLanguages)")
        return Array(uniqueLanguages).sorted()
    }

    func supportedVoices() -> [String] {
        if selectedEngine == nil || selectedLanguageCode == nil {
            return []
        }
        let supportedVoices = self.voices.filter {
            let allVoices = $0.secondaryLocaleList + [$0.locale]
            let languageFlag = allVoices.contains(selectedLanguageCode!)
            let engineFlag = selectedEngine == $0.voiceType
            return languageFlag && engineFlag
        }.map { $0.name }
        print("Azure Supported Voices \(supportedVoices)")
        return supportedVoices
    }
    
    // AVAudioPlayerDelegate method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
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
