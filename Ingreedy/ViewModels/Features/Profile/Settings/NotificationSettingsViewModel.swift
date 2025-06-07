import Foundation
import UserNotifications
import Combine

/// Notification Settings işlemlerini yöneten ViewModel
@MainActor
class NotificationSettingsViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var notificationsEnabled = false
    @Published var friendActivities = true
    @Published var appUpdates = true
    @Published var weeklyDigest = false
    @Published var shouldOpenSettings = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let friendActivities = "notif_friend_activities"
        static let appUpdates = "notif_app_updates"
        static let weeklyDigest = "notif_weekly_digest"
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSettingsObservers()
    }
    
    // MARK: - Public Methods
    
    /// Notification ayarlarını yükler
    func loadNotificationSettings() {
        // Check system notification permission first
        checkNotificationPermission()
        
        // Load settings from UserDefaults
        friendActivities = userDefaults.bool(forKey: Keys.friendActivities)
        appUpdates = userDefaults.bool(forKey: Keys.appUpdates)
        weeklyDigest = userDefaults.bool(forKey: Keys.weeklyDigest)
    }
    
    /// Bildirim izni ister
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.notificationsEnabled = true
                    self?.scheduleDefaultNotifications()
                } else {
                    self?.notificationsEnabled = false
                }
            }
        }
    }
    
    /// Tüm bildirimleri temizler
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("All notifications cleared")
    }
    
    /// Sistem ayarlarını açma signal'ı gönderir
    func openSystemSettings() {
        shouldOpenSettings = true
    }
    
    // MARK: - Private Methods
    
    /// Bildirim iznini kontrol eder
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Ayar değişikliklerini gözlemler
    private func setupSettingsObservers() {
        // Observe push notification settings changes
        Publishers.CombineLatest(
            $friendActivities,
            $appUpdates
        )
        .dropFirst()
        .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
        .sink { [weak self] (values: (Bool, Bool)) in
            self?.saveNotificationSettings()
        }
        .store(in: &cancellables)
        
        // Observe email notification settings changes
        $weeklyDigest
        .dropFirst()
        .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.saveNotificationSettings()
        }
        .store(in: &cancellables)
    }
    
    /// Bildirim ayarlarını kaydeder
    private func saveNotificationSettings() {
        userDefaults.set(friendActivities, forKey: Keys.friendActivities)
        userDefaults.set(appUpdates, forKey: Keys.appUpdates)
        userDefaults.set(weeklyDigest, forKey: Keys.weeklyDigest)
        userDefaults.synchronize()
    }
    
    /// Varsayılan bildirimleri zamanlar
    private func scheduleDefaultNotifications() {
        guard notificationsEnabled else { return }
        
        // Schedule weekly recipe digest if enabled
        if weeklyDigest {
            scheduleWeeklyDigest()
        }
    }
    
    /// Bildirimleri zamanlar
    private func scheduleNotifications() {
        guard notificationsEnabled else { return }
        
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule new notifications based on current settings
        scheduleDefaultNotifications()
    }
    
    /// Haftalık özet bildirimini zamanlar
    private func scheduleWeeklyDigest() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Recipe Digest"
        content.body = "Discover new trending recipes this week!"
        content.sound = .default
        
        // Schedule for every Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-digest", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekly digest: \(error)")
            }
        }
    }
} 