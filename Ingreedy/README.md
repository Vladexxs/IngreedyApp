# Ingreedy

> Your AI-powered cooking companion for discovering, sharing, and preparing recipes based on your available ingredients.

---

## Table of Contents
- [Introduction](#introduction)
- [Architecture](#architecture)
- [External Integrations](#external-integrations)
- [Features](#features)
- [Folder Structure](#folder-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction
Ingreedy is an iOS application built with SwiftUI and MVVM architecture that helps users discover recipes by entering their available ingredients. It leverages AI-powered chat to provide cooking tips, ingredient substitutions, and personalized recipe suggestions.

---

## Architecture
- **Pattern**: MVVM (Model–View–ViewModel) to separate UI, business logic, and data.
- **Service Abstraction**: Protocol-oriented services for Authentication, Social/Friend, Recipe Sharing, and AI interactions.
- **Async/Await & Combine**: Modern concurrency and reactive patterns.
- **Routing**: Custom `Router` manages in-app navigation based on authentication state.
- **Caching**: Kingfisher (image cache) and `CacheManager` (memory/disk cache, memory pressure handling).

---

## External Integrations
- **Firebase**: Authentication (email/password, Google Sign-In), Firestore database, Cloud Storage.
- **Google Sign-In**: Seamless OAuth login.
- **Google Gemini AI**: Chat-based AI responses for cooking guidance (configured in `Configuration/GeminiConfiguration.swift`).
- **Kingfisher**: Efficient image loading & caching.
- **Lottie**: Rich JSON-based animations for splash and UI components.

---

## Features
- **Ingredient-Based Recipe Search**: Enter ingredients to find matching recipes and view match percentages.
- **AI Chat**: Interact with an AI assistant (ChefMate) for cooking tips, nutritional info, and substitutions.
- **User Authentication & Profile**: Sign up/login, profile setup, manage favorites.
- **Social Sharing**: Send and receive recipes with friends, react to shared recipes, view notifications.
- **Favorites & History**: Save favorite recipes and track history.
- **Modern UI**: Custom buttons, forms, shapes, animations, and tab-based navigation.
- **Performance Optimizations**: Memory pressure handling, aggressive caching policies.

---

## Folder Structure
```
Ingreedy/                      # Project root
├── Configuration/             # API keys, base URLs, model settings (GeminiConfiguration.swift)
├── Protocols/                 # Service interfaces (Auth, Friend, RecipeSharing, Notifications)
├── Models/                    # Data models for Entities, Requests, Responses, AI, Social
│   ├── Entities/              # User, Friend, Recipe structs
│   ├── Requests/              # Form validations (LoginModel, RegisterModel, ForgotPasswordModel)
│   ├── Responses/             # API response wrappers
│   ├── Social/                # FriendRequest, SharedRecipe models
│   └── AI/                    # ChatMessage, GeminiRequest/Response, AIError
├── Services/                  # Implementations for network, database (Firestore), AI, push notifications
│   ├── Network/               # Recipe API calls
│   ├── Database/              # Firebase services (Auth, Friends, Shared Recipes)
│   ├── AI/                    # GeminiAIService
│   └── Push/                  # NotificationService
├── ViewModels/                # Business logic for Views (Core, Features, AI)
├── Views/                     # SwiftUI Views (Core, Components, Features, AI Chat)
├── Utils/                     # Shared utilities (Router, CacheManager, Extensions, Constants, Styles)
├── Resources/                 # Assets, Lottie JSON animations, xcassets
├── Ingreedy.swift             # @main App entrypoint
├── Info.plist                 # App configuration (Google Sign-In client ID)
├── GoogleService-Info.plist   # Firebase configuration
├── Ingreedy.entitlements      # App entitlements
└── README.md                  # Project overview (this file)
```

---

## Installation
1. **Clone** the repository:
   ```bash
   git clone https://github.com/your-username/IngreedyApp.git
   cd Ingreedy/Ingreedy
   ```
2. **Dependencies**:
   - This project uses Swift Package Manager for Kingfisher, Lottie, and Firebase SDKs. Xcode will resolve and download packages automatically when you open the project.
3. **Configure API Keys**:
   - Open `Configuration/GeminiConfiguration.swift` and replace `apiKey` with your Google Gemini AI key.
   - Ensure `GoogleService-Info.plist` is present with correct Firebase credentials.
4. **Open in Xcode**:
   ```bash
   open Ingreedy.xcodeproj
   ```
5. **Run** on simulator or device (iOS 16+).

---

## Usage
- Launch the app, register or login.
- Add your ingredients and tap the chef hat button to discover recipe suggestions.
- Chat with ChefMate AI for cooking tips and substitutions.
- Send recipes to friends and view incoming shared recipes.
- Manage your profile, favorites, and app settings.

---

## Future Enhancements
- **Barcode/QR Scanner** for automatic ingredient entry.
- **Offline Support**: Local cache of recipes when network is unavailable.
- **Dark Mode** refinements and theming.
- **Advanced AI Responses**: Integrate recipe card generation within chat.
- **iPad & macOS Compatibility** via Catalyst.

---

## Contributing
Contributions are welcome! Please:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Commit your changes (`git commit -m 'Add my feature'`).
4. Push to the branch (`git push origin feature/my-feature`).
5. Open a Pull Request.

Please ensure code formatting consistency and add tests where applicable.

---

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. 