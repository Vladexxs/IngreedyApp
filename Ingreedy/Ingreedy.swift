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
        
        // OPTIMIZED Kingfisher yapılandırması - Performance ve stability dengesi
        setupKingfisher()
        
        // Memory pressure monitoring
        setupMemoryPressureMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .onAppear {
                    // AUTH FIX: App göründükten sonra auth check yap
                    router.checkAuthAndNavigate()
                }
        }
    }
    
    private func setupKingfisher() {
        let cache = ImageCache.default
        
        // Memory cache - optimize edilmiş limitler
        cache.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024 // 150MB
        cache.memoryStorage.config.countLimit = 200 // Daha fazla resim
        cache.memoryStorage.config.expiration = .seconds(1800) // 30 dakika (daha uzun)
        
        // Disk cache - daha büyük ve uzun süreli
        cache.diskStorage.config.sizeLimit = 300 * 1024 * 1024 // 300MB
        cache.diskStorage.config.expiration = .days(14) // 2 hafta
        
        // Network optimizasyonu - aggressive caching
        let modifier = AnyModifier { request in
            var r = request
            r.timeoutInterval = 20.0 // Daha uzun timeout
            r.cachePolicy = .returnCacheDataElseLoad // Önce cache'e bak
            return r
        }
        
        // Manager konfigürasyonu - performance odaklı
        KingfisherManager.shared.defaultOptions = [
            .requestModifier(modifier),
            .cacheOriginalImage, // Her zaman disk cache kullan
            .backgroundDecode, // Background thread'de decode et
            .callbackQueue(.mainAsync),
            .processor(DefaultImageProcessor.default),
            .scaleFactor(UIScreen.main.scale),
            .cacheSerializer(DefaultCacheSerializer.default),
            .onlyLoadFirstFrame // GIF'ler için sadece ilk frame
        ]
        
        // Connection limits - performance için optimize
        KingfisherManager.shared.downloader.sessionConfiguration.httpMaximumConnectionsPerHost = 8
        KingfisherManager.shared.downloader.sessionConfiguration.timeoutIntervalForRequest = 20.0
        KingfisherManager.shared.downloader.sessionConfiguration.timeoutIntervalForResource = 45.0
        
        // URLCache'i de artır
        let urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50MB
            diskCapacity: 200 * 1024 * 1024, // 200MB
            diskPath: nil
        )
        KingfisherManager.shared.downloader.sessionConfiguration.urlCache = urlCache
        KingfisherManager.shared.downloader.sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
    }
    
    private func setupMemoryPressureMonitoring() {
        // Memory warning notification monitoring
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("⚠️ Memory warning received - clearing cache")
            CacheManager.shared.handleMemoryPressure(level: .high)
        }
        
        // Background/foreground optimizations
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            CacheManager.shared.performMaintenanceIfNeeded()
        }
    }
}
