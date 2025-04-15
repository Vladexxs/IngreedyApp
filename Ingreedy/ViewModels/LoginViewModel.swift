import Foundation
import Combine

class LoginViewModel: BaseViewModel {
    @Published var loginModel: LoginModel = LoginModel(email: "", password: "")
    
    func login() {
        // Firebase entegrasyonu sonrası eklenecek
    }
} 