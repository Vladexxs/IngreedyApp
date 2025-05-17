import SwiftUI

/// Uygulama genelinde kullanılan renkler
struct AppColors {
    // MARK: - Ana Renkler
    
    /// Arka plan rengi - Beyaz
    static let background = Color.white
    
    /// Birincil renk - Koyu kahverengi (#4E2E15)
    static let primary = Color(red: 78/255, green: 46/255, blue: 21/255)
    
    /// Vurgu rengi - Turuncu (#FF8800)
    static let accent = Color(red: 1.0, green: 0.53, blue: 0.0)
    
    /// Metin rengi - Daha koyu kahverengi
    static let text = Color(red: 60/255, green: 32/255, blue: 10/255)
    
    /// İkincil metin rengi - Açık kahverengi/gri
    static let secondary = Color(red: 160/255, green: 120/255, blue: 80/255)
    
    // MARK: - Yardımcı Renkler
    
    /// Kart arka plan rengi - Açık kahverengi (#F7E9DD)
    static let card = Color(red: 247/255, green: 233/255, blue: 221/255)
    
    /// Tab bar arka plan rengi - Açık turuncu/krem (#FFECD9)
    static let tabBar = Color(red: 255/255, green: 236/255, blue: 217/255)
    
    /// Buton metin rengi - Beyaz
    static let buttonText = Color.white
    
    /// Buton arka plan rengi - Turuncu
    static let buttonBackground = Color(red: 1.0, green: 0.53, blue: 0.0)
    
    /// Kart ve avatar gölgesi için siyahın düşük opaklığı
    static let shadow = Color.black.opacity(0.08)
} 