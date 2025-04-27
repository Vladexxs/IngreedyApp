import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
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
            
            Button("Logout") {
                router.navigate(to: .login)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Router())
} 