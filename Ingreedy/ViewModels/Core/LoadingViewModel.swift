import SwiftUI
import Combine

/// Loading ekranı için ViewModel
class LoadingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var progress: Double = 0.0
    @Published var isLoadingComplete: Bool = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private let loadingDuration: Double
    private let updateInterval: TimeInterval = 0.02 // 50 FPS için
    private var startTime: Date?
    
    // MARK: - Initialization
    init() {
        // Rastgele loading süresi: 5-8 saniye arası (daha uzun)
        self.loadingDuration = Double.random(in: 5.0...8.0)
    }
    
    // MARK: - Public Methods
    
    /// Loading animasyonunu başlatır
    func startLoading() {
        startTime = Date()
        progress = 0.0
        isLoadingComplete = false
        
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    /// Loading animasyonunu durdurur
    func stopLoading() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Methods
    
    /// Progress bar'ı günceller
    private func updateProgress() {
        guard let startTime = startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let newProgress = min(elapsedTime / loadingDuration, 1.0)
        
        // Smooth animation için progress'i güncelle
        DispatchQueue.main.async { [weak self] in
            self?.progress = newProgress
            
            if newProgress >= 1.0 {
                self?.completeLoading()
            }
        }
    }
    
    /// Loading tamamlandığında çağrılır
    private func completeLoading() {
        isLoadingComplete = true
        stopLoading()
    }
    
    // MARK: - Deinitializer
    deinit {
        stopLoading()
    }
} 