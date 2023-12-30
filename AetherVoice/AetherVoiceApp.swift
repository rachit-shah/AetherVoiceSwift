//
//  AetherVoiceApp.swift
//  AetherVoice
//
//  Created by Rachit Shah on 12/24/23.
//

import SwiftUI

@main
struct AetherVoiceApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
