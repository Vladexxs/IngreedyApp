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
    open func handleError(_ error: Error) {
        self.error = error
    }
    
    /// Hata bilgisini temizler
    func clearError() {
        self.error = nil
    }
    
    /// Ortak network işlemleri için generic yardımcı fonksiyon
    func performNetwork<T>(
        _ block: @escaping (@escaping (Result<T, Error>) -> Void) -> Void,
        onSuccess: @escaping (T) -> Void
    ) {
        isLoading = true
        error = nil
        block { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let value):
                    onSuccess(value)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
} 