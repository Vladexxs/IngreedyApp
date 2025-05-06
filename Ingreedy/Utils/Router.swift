import SwiftUI

enum Route {
    case login
    case register
    case home
    case recipes
    case ingredientSuggestion
    
    func description() -> String {
        switch self {
        case .login: return "Login"
        case .register: return "Register" 
        case .home: return "Home"
        case .recipes: return "Recipes"
        case .ingredientSuggestion: return "Ingredient Suggestion"
        }
    }
}

class Router: ObservableObject {
    @Published var currentRoute: Route = .login
    
    func navigate(to route: Route) {
        print("Navigating from \(currentRoute.description()) to \(route.description())")
        self.currentRoute = route
    }
    
    func checkAuthAndNavigate() {
        if FirebaseAuthenticationService.shared.currentUser != nil {
            print("User is logged in, navigating to Home")
            self.currentRoute = .home
        } else {
            print("User is not logged in, navigating to Login")
            self.currentRoute = .login
        }
    }
} 