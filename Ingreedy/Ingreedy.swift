//
//  IngreedyApp.swift
//  Ingreedy
//
//  Created by Mert Yılmazer on 15.04.2025.
//


import SwiftUI
import FirebaseCore

@main
struct Ingreedy: App {
    @StateObject private var router = Router()
    
    init() {
        FirebaseApp.configure()
        // Doğrudan home ekranına yönlendir, giriş kontrolü yapma
        router.navigate(to: .home)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
