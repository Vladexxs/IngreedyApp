//
//  IngreedyApp.swift
//  Ingreedy
//
//  Created by Mert Yılmazer on 15.04.2025.
//


import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct Ingreedy: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var router = Router()
    
    init() {
        FirebaseApp.configure()
        // Check auth status and navigate to appropriate screen
        router.checkAuthAndNavigate()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
