//
//  IngreedyApp.swift
//  Ingreedy
//
//  Created by Mert Yılmazer on 15.04.2025.
//

import SwiftUI
import FirebaseCore

@main
struct IngreedyApp: App {
    @StateObject private var router = Router()
    
    init() {
        FirebaseApp.configure()
        router.checkAuthAndNavigate()
    }
    
    var body: some Scene {
        WindowGroup {
            switch router.currentRoute {
            case .login:
                LoginView()
                    .environmentObject(router)
            case .register:
                RegisterView()
                    .environmentObject(router)
            case .home:
                HomeView()
                    .environmentObject(router)
            }
        }
    }
}
