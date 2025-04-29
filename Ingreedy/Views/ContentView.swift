import SwiftUI
import FirebaseCore

struct ContentView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        Group {
            switch router.currentRoute {
            case .login:
                LoginView()
            case .register:
                RegisterView()
            case .home:
                HomeView()
            case .recipes:
                RecipeListView()
            case .ingredientSuggestion:
                IngredientSuggestionView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Router())
} 
