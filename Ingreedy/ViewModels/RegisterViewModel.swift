import Foundation
import Combine

class RegisterViewModel: BaseViewModel {
    @Published var registerModel: RegisterModel = RegisterModel(
        email: "",
        password: "",
        confirmPassword: "",
        fullName: ""
    )
    
    func register() {
        // Firebase entegrasyonu sonrası eklenecek
    }
} 