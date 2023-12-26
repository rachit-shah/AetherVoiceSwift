import AVFoundation

class GoogleCloudSynthesizer: SpeechSynthesizerProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    internal var selectedVoiceIdentifier: String = "com.apple.voice.compact.en-US.Samantha"
    internal var selectedLanguageCode: String = "en-US"

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
        // Return a list of supported languages
        return AVSpeechSynthesisVoice.speechVoices().map { $0.language }
    }

    func supportedVoices() -> [String] {
        // Filter the voices to only those that match the selected language
        return AVSpeechSynthesisVoice.speechVoices()
               .filter { $0.language == selectedLanguageCode }
               .map { $0.identifier }
    }

    // ... other methods ...
}
