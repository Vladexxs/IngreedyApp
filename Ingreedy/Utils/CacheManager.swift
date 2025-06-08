import Foundation
import Kingfisher
import SwiftUI

/// Kingfisher cache yönetimi için utility sınıfı
/// SwiftUI pattern'e uygun olarak tasarlanmıştır
/// CacheCallbackCoordinator hatası için optimize edilmiştir
final class CacheManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CacheManager()
    private let serialQueue = DispatchQueue(label: "com.ingreedy.cache", qos: .utility)
    
    // MARK: - Published Properties
    @Published var isPerformingMaintenance = false
    
    private init() {
        setupCacheConfiguration()
        startMaintenanceTimer()
    }
    
    deinit {
        maintenanceTimer?.invalidate()
    }
    
    // MARK: - Timer-based Maintenance
    private var maintenanceTimer: Timer?
    
    private func startMaintenanceTimer() {
        // Her 10 dakikada bir maintenance (daha az sık)
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.performMaintenanceIfNeeded()
        }
    }
    
    private func setupCacheConfiguration() {
        let cache = ImageCache.default
        
        // Memory pressure handling - daha akıllı
        cache.memoryStorage.config.cleanInterval = 60 // 1 dakikada bir
        
        // Auto cleanup - daha optimize
        cache.cleanExpiredMemoryCache()
    }
    
    // MARK: - Public Methods
    
    /// Gerektiğinde cache maintenance gerçekleştir
    func performMaintenanceIfNeeded() {
        guard !isPerformingMaintenance else { return }
        
        serialQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.isPerformingMaintenance = true
            }
            
            // Sadece expired cache'leri temizle
            ImageCache.default.cleanExpiredMemoryCache()
            ImageCache.default.cleanExpiredDiskCache()
            
            DispatchQueue.main.async {
                self?.isPerformingMaintenance = false
            }
        }
    }
    
    /// Acil durum cache reset (sadece gerektiğinde)
    func emergencyReset() {
        serialQueue.async {
            ImageCache.default.clearMemoryCache()
            print("🚨 Emergency cache reset performed")
        }
    }
    
    /// Profile image cache'ini temizle (logout için)
    func clearProfileImageCache(forURL url: String) {
        guard let imageURL = URL(string: url) else { return }
        
        serialQueue.async {
            ImageCache.default.removeImage(forKey: imageURL.absoluteString)
        }
    }
    
    /// Tüm cache'leri güvenli şekilde temizle
    func clearAllCaches() {
        serialQueue.async {
            ImageCache.default.clearMemoryCache()
            ImageCache.default.clearDiskCache()
        }
    }
    
    /// Memory warning durumunda çağrılan fonksiyon
    func handleMemoryWarning() {
        serialQueue.async {
            // Sadece memory cache'i temizle
            ImageCache.default.clearMemoryCache()
        }
    }
    
    /// Cache statistics (Basitleştirilmiş versiyon)
    func getCacheStatistics() -> (memoryUsage: String, diskUsage: String) {
        do {
            let diskSize = try ImageCache.default.diskStorage.totalSize()
            return (memoryUsage: "Active", diskUsage: ByteCountFormatter.string(fromByteCount: Int64(diskSize), countStyle: .file))
        } catch {
            return (memoryUsage: "Active", diskUsage: "Unknown")
        }
    }
    
    /// Proactive cache warming - önemli resimleri önceden yükle
    func warmupCache(imageURLs: [String], priority: Float = 0.5) {
        serialQueue.async {
            let group = DispatchGroup()
            
            for urlString in imageURLs.prefix(10) { // En fazla 10 resim
                guard let url = URL(string: urlString) else { continue }
                
                group.enter()
                KingfisherManager.shared.retrieveImage(
                    with: url,
                    options: [
                        .cacheOriginalImage,
                        .backgroundDecode
                    ]
                ) { _ in
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                print("✅ Cache warmup completed for \(imageURLs.count) images")
            }
        }
    }
    
    /// Memory pressure'a göre dinamik temizlik
    func handleMemoryPressure(level: MemoryPressureLevel) {
        serialQueue.async {
            switch level {
            case .low:
                // Sadece expired olanları temizle
                ImageCache.default.cleanExpiredMemoryCache()
            case .medium:
                // Memory cache'in yarısını temizle
                let cache = ImageCache.default
                cache.memoryStorage.config.totalCostLimit = cache.memoryStorage.config.totalCostLimit / 2
                cache.clearMemoryCache()
                // Sonra eski limite geri döndür
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    cache.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024
                }
            case .high:
                // Tüm memory cache'i temizle
                ImageCache.default.clearMemoryCache()
            }
        }
    }
}

enum MemoryPressureLevel {
    case low, medium, high
}

// MARK: - KFImage Extensions

extension KFImage {
    
    /// Minimum güvenli konfigürasyon
    func configureMinimal() -> KFImage {
        return self
            .cacheOriginalImage() // Disk cache kullan
            .backgroundDecode()
            .placeholder {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .shimmering()
            }
            .fade(duration: 0.3)
    }
    
    /// Profile image için optimize konfigürasyon
    func configureForProfileImage(size: CGSize = CGSize(width: 100, height: 100)) -> KFImage {
        return self
            .setProcessor(DownsamplingImageProcessor(size: size))
            .cacheOriginalImage() // Disk cache kullan
            .backgroundDecode()
            .placeholder {
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: size.width * 0.6))
                    )
            }
            .fade(duration: 0.25)
    }
    
    /// Recipe image için optimize konfigürasyon
    func configureForRecipeImage(size: CGSize = CGSize(width: 300, height: 200)) -> KFImage {
        return self
            .setProcessor(DownsamplingImageProcessor(size: size))
            .cacheOriginalImage()
            .backgroundDecode()
            .placeholder {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.system(size: 40))
                    )
                    .shimmering()
            }
            .fade(duration: 0.3)
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(45))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
} 