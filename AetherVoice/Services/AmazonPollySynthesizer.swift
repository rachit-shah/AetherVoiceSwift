import Foundation
import AVFoundation
import AWSCognitoIdentity
import AWSClientRuntime
import AWSPolly

class AmazonPollySynthesizer: NSObject, SpeechSynthesizerProtocol, AVAudioPlayerDelegate {

    internal var selectedEngine: String?
    internal var selectedVoiceIdentifier: String?
    internal var selectedLanguageCode: String?
    weak var delegate: SpeechSynthesizerDelegate?
    private var cognitoCredentials: CognitoIdentityClientTypes.Credentials?
    
    private var voices: [PollyClientTypes.Voice]
    private var cognitoIdentityId: String
    private var AwsRegion: String
    private var pollyClient: PollyClient
    private var cognitoClient: CognitoIdentityClient
    private var audioPlayer: AVAudioPlayer
    
    init(cognitoIdentityId: String) async throws {
        self.cognitoIdentityId = cognitoIdentityId
        self.AwsRegion = self.cognitoIdentityId.components(separatedBy: ":")[0]
        self.cognitoClient = try CognitoIdentityClient(region: self.AwsRegion)
        self.pollyClient = try PollyClient(region: self.AwsRegion)
        self.audioPlayer = AVAudioPlayer()
        self.voices = []
        super.init()
        self.voices = try await self.listVoices()
    }
    
    static func getCognitoIdentityFromKeychain() -> String? {
        // Cognito pool ID. Pool needs to be unauthenticated pool with
        // Amazon Polly permissions.
        if let idData = KeychainWrapper.load(key: "COGNITO_IDENTITY_POOL_ID"),
           let idString = String(data: idData, encoding: .utf8) {
            return idString
        } else {
            return nil
        }
    }
    
    func refreshCredentials() async {
        if (self.cognitoCredentials == nil || self.cognitoCredentials!.expiration!.timeIntervalSinceNow <= 0) {
            do {
                print("Refreshing credentials")
                let identityId = try await self.cognitoClient.getId(input: GetIdInput(identityPoolId: self.cognitoIdentityId)).identityId
                let getCredentialsForIdentityInput = GetCredentialsForIdentityInput(identityId: identityId)
                self.cognitoCredentials = try await self.cognitoClient.getCredentialsForIdentity(input: getCredentialsForIdentityInput).credentials
                if (self.cognitoCredentials == nil || self.cognitoCredentials?.accessKeyId == nil || self.cognitoCredentials?.secretKey == nil) {
                    throw RuntimeError("Couldn't get credentials from AWS Cognito.")
                }
                let awsCreds = Credentials(accessKey: self.cognitoCredentials!.accessKeyId!, secret: self.cognitoCredentials!.secretKey!, expirationTimeout: self.cognitoCredentials!.expiration, sessionToken: self.cognitoCredentials!.sessionToken)
                let staticCreds = try StaticCredentialsProvider(awsCreds)
                let pollyClientConfiguration = try await PollyClient.PollyClientConfiguration(
                    credentialsProvider: staticCreds,
                    region: self.AwsRegion
                )
                self.pollyClient = PollyClient(config: pollyClientConfiguration)
            } catch {
                print("Failed to get Cognito Credentials: \(error)")
            }
        }
    }
    
    func generateAudioData(text: String) async throws -> Data {
        if selectedEngine == nil || selectedVoiceIdentifier == nil {
            throw SynthesizerError.userError("Need to select engine, language and/or voice in the reader settings.")
        }
        await refreshCredentials()
        let input = SynthesizeSpeechInput(
            engine: PollyClientTypes.Engine(rawValue: selectedEngine!),
            outputFormat: .mp3,
            text: text,
            textType: .text,
            voiceId: PollyClientTypes.VoiceId(rawValue: selectedVoiceIdentifier!)
        )
        print("Generating text Polly: \(text)")
        do {
            let synthesizedSpeechResult = try await self.pollyClient.synthesizeSpeech(input: input)
            guard let speech = try await synthesizedSpeechResult.audioStream?.readData()
            else {
                throw SynthesizerError.synthesizerError("Polly Error: Unable to parse audio data from response")
            }
            AmazonPollySynthesizer.saveCharactersProcessed(count: text.count, engine: selectedEngine!)
            return speech
        } catch {
            switch error {
                case is SynthesizerError:
                    throw error
                default:
                    throw SynthesizerError.synthesizerError("Polly Error: \(error)")
            }
        }
    }

    func speak(text: String, data: Data) throws {
        if selectedEngine == nil || selectedVoiceIdentifier == nil {
            throw SynthesizerError.userError("Need to select engine, language and/or voice in the reader settings.")
        }
        do {
            self.audioPlayer = try AVAudioPlayer(data: data)
            self.audioPlayer.delegate = self
            self.audioPlayer.play()
        } catch {
            switch error {
                case is SynthesizerError:
                    throw error
                default:
                    throw SynthesizerError.synthesizerError("Polly Error: \(error)")
            }
        }
    }

    func stopSpeaking() {
        // Stop any ongoing speech
        if self.audioPlayer.isPlaying == true {
            self.audioPlayer.stop()
        }
    }
    
    private func listVoices() async throws -> [PollyClientTypes.Voice] {
        await refreshCredentials()
        do {
            var foundVoices: [PollyClientTypes.Voice] = []
            var nextToken: String?
            repeat {
                let response = try await self.pollyClient.describeVoices(input: DescribeVoicesInput())
                nextToken = response.nextToken
                foundVoices += response.voices ?? []
                print("Listing Polly Voices: \(String(describing: response.nextToken)) \(String(describing: response.voices?.debugDescription))")
            } while (nextToken != nil)
            return foundVoices
        } catch {
            throw SynthesizerError.synthesizerError("Error getting voices from Amazon Polly: \(error.localizedDescription)")
        }
    }
    
    func supportedEngines() -> [String] {
        return ["standard", "neural", "long-form"]
    }

    func supportedLanguages() -> [String] {
        if selectedEngine == nil {
            return []
        }
        let allLanguages = self.voices.filter {
            var engineFlag = false
            if $0.supportedEngines != nil && $0.supportedEngines!.count > 0 {
                var supportedEngines: [String] = []
                for engine in $0.supportedEngines! {
                    supportedEngines.append(engine.rawValue)
                }
                engineFlag = supportedEngines.contains(selectedEngine!)
            }
            return engineFlag
        }
        .map { $0.languageCode?.rawValue ?? "en-US" }
        let uniqueLanguages = Array(Set(allLanguages))
        return Array(uniqueLanguages).sorted()  // Convert back to sorted array
    }

    func supportedVoices() -> [String] {
        if selectedEngine == nil || selectedLanguageCode == nil {
            return []
        }
        return self.voices.filter { (voice) -> Bool in
            let languageFlag = voice.languageCode!.rawValue == selectedLanguageCode
            var additionalLanguageFlag = false
            if voice.additionalLanguageCodes != nil && voice.additionalLanguageCodes!.count > 0 {
                var additionalLanguages: [String] = []
                for languageCode in voice.additionalLanguageCodes! {
                    additionalLanguages.append(languageCode.rawValue)
                }
                additionalLanguageFlag = additionalLanguages.contains(selectedLanguageCode!)
            }
            var engineFlag = false
            if voice.supportedEngines != nil && voice.supportedEngines!.count > 0 {
                var supportedEngines: [String] = []
                for engine in voice.supportedEngines! {
                    supportedEngines.append(engine.rawValue)
                }
                engineFlag = supportedEngines.contains(selectedEngine!)
            }
            return (languageFlag || additionalLanguageFlag) && engineFlag
        }.map { $0.id?.rawValue ?? "" }
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
        UserDefaults.standard.set(charactersProcessed, forKey: "amazonPollyCharactersProcessed")
    }

    static func getCharactersProcessed() -> [String:Int] {
        return UserDefaults.standard.dictionary(forKey: "amazonPollyCharactersProcessed") as? [String: Int] ?? [String: Int]()
    }
}
