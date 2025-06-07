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
import Kingfisher

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
        
        // Kingfisher yapılandırması - Safe configuration
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        cache.diskStorage.config.sizeLimit = 300 * 1024 * 1024 // 300 MB
        cache.memoryStorage.config.expiration = .seconds(600) // 10 dakika
        cache.diskStorage.config.expiration = .seconds(3600) // 1 saat
        
        // Basit ve güvenli default options
        KingfisherManager.shared.defaultOptions = [
            .transition(.fade(0.2))
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
