import Foundation
import Combine

/// Tüm ViewModel sınıfları için temel sınıf
@MainActor
class BaseViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Yükleniyor durumu
    @Published var isLoading: Bool = false
    
    /// Hata durumu
    @Published var error: Error?
    
    // MARK: - Properties
    
    /// Combine aboneliklerini takip etmek için kullanılır
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Error Handling
    
    /// Hata yönetimi için kullanılır
    /// - Parameter error: İşlenecek hata
    func handleError(_ error: Error) {
        self.error = error
    }
} 