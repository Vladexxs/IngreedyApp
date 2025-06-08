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
        
        // Kingfisher yapılandırması - Optimized for faster loading
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024 // 150 MB (artırıldı)
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024 // 500 MB (artırıldı)
        cache.memoryStorage.config.expiration = .seconds(3600) // 1 saat (artırıldı)
        cache.diskStorage.config.expiration = .seconds(7 * 24 * 3600) // 1 hafta (artırıldı)
        
        // Performance odaklı default options
        KingfisherManager.shared.defaultOptions = [
            .transition(.fade(0.2)),
            .cacheOriginalImage // Orijinal görüntüleri cache'le
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
