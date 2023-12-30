import Foundation
import AVFoundation
import AWSCognitoIdentity
import AWSClientRuntime
import AWSPolly

class AmazonPollySynthesizer: NSObject, SpeechSynthesizerProtocol, AVAudioPlayerDelegate {
    
    internal var selectedEngine: String = "standard"
    internal var selectedVoiceIdentifier: String = "Joanna"
    internal var selectedLanguageCode: String = "en-US"
    weak var delegate: SpeechSynthesizerDelegate?
    private var sentences: [String]
    private var cognitoIdentityId: String
    private var AwsRegion: String
    private var cognitoCredentials: CognitoIdentityClientTypes.Credentials?
    private var pollyClient: PollyClient
    private var cognitoClient: CognitoIdentityClient
    private var audioPlayer: AVAudioPlayer


    init(sentences: [String], delegate: SpeechSynthesizerDelegate?) throws {
        self.sentences = sentences
        self.delegate = delegate
        // Cognito pool ID. Pool needs to be unauthenticated pool with
        // Amazon Polly permissions.
        if let idData = KeychainWrapper.load(key: "COGNITO_IDENTITY_POOL_ID"),
           let idString = String(data: idData, encoding: .utf8) {
            self.cognitoIdentityId = idString
            self.AwsRegion = cognitoIdentityId.components(separatedBy: ":")[0]
        } else {
            self.cognitoIdentityId = "Not Set"
            self.AwsRegion = "Not Set"
            delegate?.didEncounterError(.userError("Need to set Identity pool id in the AWS configuration to use Polly synthesizer. Change to a different synthesizer in reader settings or set the appropriate config in the Settings menu."))
        }
        self.cognitoClient = try CognitoIdentityClient(region: self.AwsRegion)
        self.pollyClient = try PollyClient(region: AwsRegion)
        // Create an audio player
        self.audioPlayer = AVAudioPlayer()
        super.init()
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

    func speak(text: String) async {
        await refreshCredentials()
        let input = SynthesizeSpeechInput(
            engine: PollyClientTypes.Engine(rawValue: selectedEngine),
            outputFormat: .mp3,
            text: text,
            textType: .text,
            voiceId: PollyClientTypes.VoiceId(rawValue: selectedVoiceIdentifier)
        )
        print(input)
        do {
            let synthesizedSpeechResult = try await self.pollyClient.synthesizeSpeech(input: input)
            guard let speech = try await synthesizedSpeechResult.audioStream?.readData()
            else {
                throw RuntimeError("No result was found. Please make sure a text string was sent over to synthesize.")
            }
            print("Speaking text Polly: \(text). \(speech)")
            self.audioPlayer = try AVAudioPlayer(data: speech)
            self.audioPlayer.delegate = self
            self.audioPlayer.play()
            AmazonPollySynthesizer.saveCharactersProcessed(count: text.count, engine: selectedEngine)
        } catch {
            print("Failed to speak using Amazon Polly: \(error)")
        }
    }

    func stopSpeaking() {
        // Stop any ongoing speech
        if self.audioPlayer.isPlaying == true {
            self.audioPlayer.stop()
        }
    }
    
    func supportedEngines() -> [String] {
        return ["standard", "neural", "long-form"]
    }

    func supportedLanguages() async -> [String] {
        await refreshCredentials()
        do {
            let allVoices = try await self.pollyClient.describeVoices(input: DescribeVoicesInput(engine: PollyClientTypes.Engine(rawValue: selectedEngine))).voices ?? []
            let allLanguages = allVoices.map { $0.languageCode?.rawValue ?? "en-US" }
            let uniqueLanguages = Array(Set(allLanguages))
            return Array(uniqueLanguages).sorted()  // Convert back to sorted array
        } catch {
            print("Error getting voices from Amazon Polly: \(error)")
            return []
        }
    }

    func supportedVoices() async -> [String] {
        await refreshCredentials()
        do {
            let allVoices = try await self.pollyClient.describeVoices(input: DescribeVoicesInput(engine: PollyClientTypes.Engine(rawValue: selectedEngine), languageCode: PollyClientTypes.LanguageCode(rawValue: selectedLanguageCode))).voices ?? []
            return allVoices.map { $0.id?.rawValue ?? "" }
        } catch {
            print("Error getting voices from Amazon Polly: \(error)")
            return []
        }
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
