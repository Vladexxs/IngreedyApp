import Foundation
import Combine
import FirebaseFirestore

/// Privacy Settings işlemlerini yöneten ViewModel
@MainActor
class PrivacySettingsViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var allowRecipeSharing = true
    @Published var allowAnalytics = true
    
    // MARK: - Private Properties
    private let authService: AuthenticationServiceProtocol
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let allowRecipeSharing = "privacy_recipe_sharing"
        static let allowAnalytics = "privacy_analytics"
    }
    
    // MARK: - Initialization
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        setupSettingsObservers()
    }
    
    // MARK: - Public Methods
    
    /// Privacy ayarlarını yükler
    func loadPrivacySettings() {
        // Load from UserDefaults first (local cache)
        allowRecipeSharing = userDefaults.bool(forKey: Keys.allowRecipeSharing)
        allowAnalytics = userDefaults.bool(forKey: Keys.allowAnalytics)
        
        // Then fetch from Firestore to sync
        fetchPrivacySettingsFromFirestore()
    }
    
    /// Kişisel verileri indirir
    func downloadPersonalData() {
        guard let user = authService.currentUser else { return }
        
        performNetwork({ (completion: @escaping (Result<Void, Error>) -> Void) in
            let db = Firestore.firestore()
            
            // Collect all user data
            db.collection("users").document(user.id).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let userData = snapshot?.data() else {
                    completion(.failure(NSError(domain: "DataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                    return
                }
                
                // Create export data
                let exportData: [String: Any] = [
                    "user_profile": userData,
                    "privacy_settings": [
                        "allow_sharing": self.allowRecipeSharing,
                        "analytics": self.allowAnalytics
                    ],
                    "export_date": Date().ISO8601String()
                ]
                
                print("Personal data prepared for download: \(exportData)")
                completion(.success(()))
            }
        }, onSuccess: { (_: Void) in
            // In real implementation, save to Documents or share
        })
    }
    
    // MARK: - Private Methods
    
    /// Ayar değişikliklerini gözlemler ve Firestore'a senkronize eder
    private func setupSettingsObservers() {
        // Observe setting changes and sync to Firestore
        Publishers.CombineLatest(
            $allowRecipeSharing,
            $allowAnalytics
        )
        .dropFirst()
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.savePrivacySettingsToFirestore()
        }
        .store(in: &cancellables)
    }
    
    /// Privacy ayarlarını Firestore'dan getirir
    private func fetchPrivacySettingsFromFirestore() {
        guard let user = authService.currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.id).collection("settings").document("privacy").getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self.allowRecipeSharing = data["allow_sharing"] as? Bool ?? true
                self.allowAnalytics = data["analytics"] as? Bool ?? true
                
                // Update local cache
                self.saveSettingsToUserDefaults()
            }
        }
    }
    
    /// Privacy ayarlarını Firestore'a kaydeder
    private func savePrivacySettingsToFirestore() {
        guard let user = authService.currentUser else { return }
        
        let settings: [String: Any] = [
            "allow_sharing": allowRecipeSharing,
            "analytics": allowAnalytics,
            "updated_at": Timestamp(date: Date())
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.id).collection("settings").document("privacy").setData(settings, merge: true) { [weak self] error in
            if error == nil {
                // Update local cache
                self?.saveSettingsToUserDefaults()
            }
        }
    }
    
    /// Ayarları UserDefaults'a kaydeder
    private func saveSettingsToUserDefaults() {
        userDefaults.set(allowRecipeSharing, forKey: Keys.allowRecipeSharing)
        userDefaults.set(allowAnalytics, forKey: Keys.allowAnalytics)
    }
} 