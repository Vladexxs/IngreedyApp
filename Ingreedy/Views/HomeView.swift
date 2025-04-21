import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        VStack {
            Text("Welcome to Home")
                .font(.title)
                .padding()
            
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