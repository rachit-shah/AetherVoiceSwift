//
//  AetherVoiceApp.swift
//  AetherVoice
//
//  Created by Rachit Shah on 12/24/23.
//

import SwiftUI
import AVKit

@main
struct AetherVoiceApp: App {
    let persistenceController = PersistenceController.shared
    
    #if os(iOS)
    // Application delegate adaptor to set up the custom AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

#if os(iOS)
// Custom AppDelegate to handle application lifecycle events
class AppDelegate: NSObject, UIApplicationDelegate {
    
    // This method is called when the application finishes launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Configure the audio session for background audio and video services
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Set the audio session category to playback
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            
            // Activate the audio session
            try audioSession.setActive(true, options: [])
        } catch {
            // Handle errors related to audio session setup
            print(error.localizedDescription)
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        return true
    }
}
#endif
