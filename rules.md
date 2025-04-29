
# Ingreedy - Geliştirme Kuralları ve Uygulama Mantığı

## 🚀 Uygulamanın Amacı
Ingreedy, kullanıcıların ellerindeki malzemelere göre yemek tarifleri bulmasını, tarifleri değerlendirmesini ve arkadaşlarıyla paylaşmasını sağlayan bir yemek tarifleri uygulamasıdır.

## 🧠 Uygulama Mantığı
- Kullanıcılar uygulamaya kayıt olup giriş yapabilir.
- Ellerindeki malzemeleri girerek tarif önerileri alabilir.
- Tarifler API üzerinden alınır ve her tarifin detaylarında malzemeler, açıklamalar ve görseller yer alır.
- Kullanıcılar tarifleri beğenebilir ve "favorilere" ekleyebilir.
- Tarifler arkadaşlarla paylaşılabilir. Paylaşılan tarifler değerlendirilerek tarifin genel puanı (rating) etkilenir.
- Kullanıcılar bir tarif hakkında değerlendirme yapabilir ve puan verebilir.
- Her kullanıcının bir profil ekranı vardır.
- Firebase Firestore üzerinden kullanıcıların paylaşımları ve değerlendirmeleri senkronize edilir.
- “Şifremi unuttum” özelliği Firebase Authentication ile sağlanacaktır.

👨‍🍳 Malzeme ve Tarif Öneri Sistemi

-Kullanıcının girdiği tüm malzemeler, önerilen tarifin malzeme listesinde birebir bulunmalıdır.
-Eksik malzemeler, kullanıcıda olmayan ama tarifte geçen malzemelerdir; ayrı bir alanda gösterilmelidir.
-Tarif önerileri, eşleşme oranına göre sıralanmalıdır:
    Önce tam eşleşen tarifler (3/3),
    Ardından kısmi eşleşenler (3/4, 2/4).

🌟 Kullanıcı Etkileşim Özellikleri

Tarifler kullanıcı tarafından favorilere eklenebilmelidir.

Tarifler uygulama içinden diğer kullanıcılarla paylaşılabilmelidir.

Paylaşılan tarifler, diğer kullanıcılar tarafından 0–10 arası puanlanabilir.

Puanlar, 5 yıldızlı derecelendirme sistemine dönüştürülerek gösterilmelidir.

Kullanıcı giriş/kayıt sistemi tamamlanmıştır; yalnızca tasarımsal iyileştirmeler yapılacaktır.

🤪 Test Edilebilirlik ve Mimari Kurallar

Her yeni özellik, minimum bir örnek veri ile test edilebilir olmalıdır.

ViewModel katmanı, diğer katmanlardan bağımsız şekilde test edilebilir yapıda olmalıdır.
## 🧱 Mimarî Yapı
- **MVVM** mimarisi uygulanmaktadır.
- Dosya yapısı aşağıdaki gibidir:
  - `Models`: Veri modelleri
  - `Protocols`: Servis ve ViewModel protokolleri
  - `Services`: Firebase & API servisleri
  - `Utils`: Stil, renk, sabitler ve yönlendirme
  - `ViewModels`: Her view’a ait mantık katmanı
  - `Views`: Kullanıcıya gösterilen ekranlar

## 🔐 Firebase Kullanımı
- Kullanıcı kimlik doğrulama: `FirebaseAuthenticationService.swift`
- Tarif paylaşımı, favoriler ve değerlendirme işlemleri Firestore üzerinde gerçekleşir.
- Her paylaşım, paylaşımı yapan kullanıcıya bağlıdır ve değerlendirme puanları burada tutulur.

## 📜 Ek Kurallar
- Her yeni özelliğin MVVM prensiplerine uygun geliştirilmesi gerekmektedir.
- UI bileşenleri View’lar altında yer almalı, iş mantığı ViewModel’e taşınmalıdır.
- Kod tekrarından kaçınılmalı, ortak yapı `Utils` içinde tanımlanmalıdır.
- Router yapısı tek bir merkezde yönetilmeli (`Router.swift`).
- Uygulama sade, kullanıcı dostu ve sürdürülebilir olmalıdır.

## 🔮 Gelecek Özellikler
- Şifremi unuttum ekranı
- Kullanıcı istatistikleri ve tarif geçmişi

