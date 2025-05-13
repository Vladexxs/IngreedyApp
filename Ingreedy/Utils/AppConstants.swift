import SwiftUI

/// Uygulama genelinde kullanılan sabit değerler
enum AppConstants {
    /// Boşluk değerleri
    enum Spacing {
        /// Küçük boşluk - 8pt
        static let small: CGFloat = 8
        /// Orta boşluk - 16pt
        static let medium: CGFloat = 16
        /// Büyük boşluk - 24pt
        static let large: CGFloat = 24
        /// Ekstra büyük boşluk - 32pt
        static let extraLarge: CGFloat = 32
    }
    
    /// Köşe yuvarlaklık değerleri
    enum CornerRadius {
        /// Küçük yuvarlaklık - 8pt
        static let small: CGFloat = 8
        /// Orta yuvarlaklık - 12pt
        static let medium: CGFloat = 12
        /// Büyük yuvarlaklık - 15pt
        static let large: CGFloat = 15
    }
    
    /// Gölge değerleri
    enum Shadow {
        /// Gölge rengi - %10 opak siyah
        static let small = Color.black.opacity(0.1)
        /// Gölge yarıçapı - 5pt
        static let radius: CGFloat = 5
        /// Gölge Y offset - 2pt
        static let y: CGFloat = 2
    }
    
    /// Görsel boyutları
    enum ImageSize {
        /// Logo boyutu - 120pt
        static let logo: CGFloat = 120
        /// Hata ikonu boyutu - 50pt
        static let errorIcon: CGFloat = 50
    }
    
    /// Yazı tipi boyutları
    enum FontSize {
        /// Başlık boyutu - 40pt
        static let title: CGFloat = 40
        /// Alt başlık boyutu - 17pt
        static let headline: CGFloat = 17
        /// Gövde metin boyutu - 15pt
        static let body: CGFloat = 15
    }
    
    /// Opaklık değerleri
    enum Opacity {
        /// Arka plan opaklığı - %30
        static let background: Double = 0.3
        /// Ön plan opaklığı - %90
        static let foreground: Double = 0.9
    }
} 