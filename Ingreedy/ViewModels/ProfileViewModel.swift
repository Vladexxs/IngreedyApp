import Foundation
import Combine

/// ProfileViewModel, kullanıcı profil bilgilerini ve çıkış işlemlerini yöneten ViewModel sınıfı
@MainActor
class ProfileViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoggedOut: Bool = false
    
    // MARK: - Private Properties
    private let authService: AuthenticationServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        fetchCurrentUser()
    }
    
    // MARK: - Public Methods
    
    /// Mevcut kullanıcı bilgilerini servis üzerinden alır
    func fetchCurrentUser() {
        user = authService.currentUser
    }
    
    /// Kullanıcıyı sistemden çıkışını gerçekleştirir
    func logout() {
        do {
            isLoading = true
            error = nil
            
            try authService.logout()
            
            isLoading = false
            isLoggedOut = true
        } catch {
            isLoading = false
            handleError(error)
        }
    }
} 