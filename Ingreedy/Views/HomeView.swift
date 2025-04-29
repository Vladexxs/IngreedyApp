import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Home")
                    .font(.title)
                    .padding()
                
                Button(action: {
                    router.navigate(to: .recipes)
                }) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                        Text("View Recipes")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    router.navigate(to: .ingredientSuggestion)
                }) {
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("Malzemeyle Tarif Bul")
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button("Logout") {
                    router.navigate(to: .login)
                }
                .padding()
            }
            .navigationTitle("Ingreedy")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Router())
} 