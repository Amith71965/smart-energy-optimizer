//
//  ios_appApp.swift
//  ios-app
//
//  Created by Amith Kumar Yadav K on 28/06/25.
//

import SwiftUI
import Combine

@main
struct SmartEnergyOptimizerApp: App {
    @StateObject private var apiManager = APIManager()
    @StateObject private var webSocketService = WebSocketService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiManager)
                .environmentObject(webSocketService)
                .preferredColorScheme(.dark)
                .onAppear {
                    webSocketService.connect()
                    apiManager.startPeriodicUpdates()
                }
        }
    }
}
