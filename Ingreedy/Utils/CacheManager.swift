import Foundation
import Kingfisher

/// Kingfisher cache yönetimi için utility sınıfı
/// MVVM pattern'e uygun olarak tasarlanmıştır
final class CacheManager {
    
    // MARK: - Singleton
    static let shared = CacheManager()
    private init() {}
    
    // MARK: - Profile Image Cache Management
    
    /// Profile image cache'ini temizler (userId ile)
    /// - Parameter userId: Kullanıcı ID'si
    func clearProfileImageCache(forUserId userId: String) {
        let imagePath = "profile_images/\(userId).jpg"
        ImageCache.default.removeImage(forKey: imagePath)
        logCacheOperation("Profile image cache cleared for user: \(userId)")
    }
    
    /// Belirli profile image URL'ini cache'den temizler
    /// - Parameter url: Temizlenecek image URL'i
    func clearProfileImageCache(forURL url: String) {
        ImageCache.default.removeImage(forKey: url)
        logCacheOperation("Profile image cache cleared for URL: \(url)")
    }
    
    /// Tüm profile image cache'lerini temizler
    func clearAllProfileImageCaches() {
        ImageCache.default.clearMemoryCache()
        logCacheOperation("All profile image caches cleared")
    }
    
    // MARK: - Recipe Image Cache Management
    
    /// Recipe image cache'ini optimize eder
    func optimizeRecipeImageCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        cache.diskStorage.config.sizeLimit = 300 * 1024 * 1024 // 300 MB
        logCacheOperation("Recipe image cache optimized")
    }
    
    // MARK: - General Cache Operations
    
    /// URL cache'ini temizler (API calls için)
    func clearURLCache() {
        URLCache.shared.removeAllCachedResponses()
        logCacheOperation("URL cache cleared")
    }
    
    /// Memory pressure durumunda cache'i optimize eder
    func handleMemoryPressure() {
        ImageCache.default.clearMemoryCache()
        logCacheOperation("Memory cache cleared due to pressure")
    }
    
    /// Tüm cache'leri temizler (logout için)
    func clearAllCaches() {
        clearAllProfileImageCaches()
        clearURLCache()
        logCacheOperation("All caches cleared")
    }
    
    // MARK: - Private Helpers
    
    private func logCacheOperation(_ message: String) {
        // Cache operations logged silently
    }
}

// MARK: - KFImage Extensions
extension KFImage {
    
    /// Profile image'lar için optimize edilmiş konfigürasyon
    /// Cache'i kullanır ve performans odaklıdır
    func configureForProfileImage(size: CGSize = CGSize(width: 100, height: 100)) -> KFImage {
        return self
            .setProcessor(DownsamplingImageProcessor(size: size))
            .fade(duration: 0.3)
            .retry(maxCount: 3, interval: .seconds(0.5))
            .cacheOriginalImage() // Orijinal görüntüyü cache'le
    }
    
    /// Recipe image'lar için standart konfigürasyon
    /// Normal cache kullanır ve performans odaklıdır
    func configureForRecipeImage(size: CGSize = CGSize(width: 400, height: 300)) -> KFImage {
        return self
            .setProcessor(DownsamplingImageProcessor(size: size))
            .fade(duration: 0.3)
            .retry(maxCount: 2, interval: .seconds(0.5))
    }
} 