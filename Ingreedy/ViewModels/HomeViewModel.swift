import Foundation
import Combine

class HomeViewModel: BaseViewModel {
    @Published var homeModel: HomeModel?
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        setupUser()
    }
    
    private func setupUser() {
        guard let user = authService.currentUser else {
            return
        }
        self.homeModel = HomeModel(user: user)
    }
    
    func logout() {
        do {
            try authService.logout()
        } catch {
            handleError(error)
        }
    }
} 