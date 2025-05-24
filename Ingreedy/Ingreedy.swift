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
        
        // Kingfisher yapılandırması
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024 // 500 MB
        
        // Firebase Storage URL'leri için özel yapılandırma
        let modifier = AnyModifier { request in
            var request = request
            request.timeoutInterval = 30
            return request
        }
        
        KingfisherManager.shared.defaultOptions = [
            .requestModifier(modifier),
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
