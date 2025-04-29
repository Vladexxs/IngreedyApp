import SwiftUI

enum Route {
    case login
    case register
    case home
    case recipes
    case ingredientSuggestion
}

class Router: ObservableObject {
    @Published var currentRoute: Route = .login
    
    func navigate(to route: Route) {
        currentRoute = route
    }
    
    func checkAuthAndNavigate() {
        if FirebaseAuthenticationService.shared.currentUser != nil {
            currentRoute = .home
        } else {
            currentRoute = .login
        }
    }
} 