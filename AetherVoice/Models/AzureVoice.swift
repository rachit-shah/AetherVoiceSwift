import Foundation


/*
 Example:
    {
         "Name": "Microsoft Server Speech Text to Speech Voice (af-ZA, AdriNeural)",
         "DisplayName": "Adri",
         "LocalName": "Adri",
         "ShortName": "af-ZA-AdriNeural",
         "Gender": "Female",
         "Locale": "af-ZA",
         "LocaleName": "Afrikaans (South Africa)",
         "SampleRateHertz": "48000",
         "VoiceType": "Neural",
         "Status": "GA",
         "WordsPerMinute": "147"
     },
 */
struct AzureVoice {
    var name : String
    var gender : String
    var locale : String
    var secondaryLocaleList : [String]
    var styleList : [String]
    var voiceType : String
    
    init(name : String,
         gender : String,
         locale : String,
         secondaryLocaleList : [String],
         styleList : [String],
         voiceType : String) {
        self.name = name
        self.gender = gender
        self.locale = locale
        self.secondaryLocaleList = secondaryLocaleList
        self.styleList = styleList
        self.voiceType = voiceType
    }
}

