import SwiftUI
import Kingfisher

struct IngredientSuggestionView: View {
    @StateObject private var viewModel = IngredientSuggestionViewModel()
    @State private var showingClearAlert = false
    @State private var showingAIChat = false

    @FocusState private var isTextFieldFocused: Bool // KEYBOARD FIX: Focus state
    
    var body: some View {
        NavigationView {
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Hero Section
                            heroSection
                            
                            // Search Section
                            searchSection
                            
                            // Category Pills
                            if viewModel.userIngredients.isEmpty && !viewModel.dynamicCategories.isEmpty {
                                categorySection
                            }
                            
                            // Selected Ingredients
                            if !viewModel.userIngredients.isEmpty {
                                selectedIngredientsSection
                                
                                // Stats Section
                                statsSection
                                
                                // Action Button
                                actionButton
                            }
                            

                            
                            // Results Section
                            if viewModel.isLoading {
                                loadingSection
                            } else if let error = viewModel.error {
                                errorSection(error)
                            } else {
                                resultsSection
                            }
                            
                            // AI Assistant Card (Bottom Section)
                            aiAssistantSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                    .onTapGesture {
                        // KEYBOARD FIX: ScrollView'a tıklandığında keyboard'u kapat
                        isTextFieldFocused = false
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .alert("Clear Ingredients", isPresented: $showingClearAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Clear", role: .destructive) {
                        viewModel.clearIngredients()
                    }
                } message: {
                    Text("All selected ingredients and results will be cleared.")
                }
                .sheet(isPresented: $showingAIChat) {
                    AIChatView(userIngredients: viewModel.userIngredients)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(
                        colors: [AppColors.accent.opacity(0.8), AppColors.primary.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 160)
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 12, y: 6)
                
                VStack(spacing: 12) {
                    Image(systemName: "kitchen.scale.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("Discover Recipes with Ingredients")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Find out what you can cook with your ingredients!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isTextFieldFocused ? AppColors.accent : AppColors.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                
                ZStack(alignment: .leading) {
                    // PLACEHOLDER FIX: Custom placeholder with proper color
                    if viewModel.searchText.isEmpty {
                        Text("Search ingredients (e.g. tomato, chicken)...")
                            .foregroundColor(AppColors.secondary.opacity(0.7))
                            .font(.system(size: 16))
                    }
                    
                    TextField("", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                        .foregroundColor(AppColors.primary) // TEXT COLOR FIX: Kahverengi ton
                        .accentColor(AppColors.accent) // CURSOR COLOR: Accent renk
                        .focused($isTextFieldFocused) // KEYBOARD FIX: Focus binding
                        .submitLabel(.search) // KEYBOARD FIX: Search button
                        .onSubmit {
                            // Enter'a basıldığında ilk suggestion'ı ekle
                            if let firstSuggestion = viewModel.ingredientSuggestions.first {
                                viewModel.addIngredient(firstSuggestion)
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.card)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isTextFieldFocused ? AppColors.accent.opacity(0.6) : 
                           (viewModel.searchText.isEmpty ? Color.clear : AppColors.accent.opacity(0.3)), lineWidth: 1.5)
            ) // ACTIVE STATE: Focus durumunda daha belirgin border
            .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused) // SMOOTH ANIMATION
            
            // Suggestion Dropdown
            if !viewModel.ingredientSuggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.ingredientSuggestions.prefix(5).enumerated()), id: \.offset) { index, suggestion in
                        Button(action: {
                            viewModel.addIngredient(suggestion)
                            isTextFieldFocused = false // KEYBOARD FIX: Suggestion seçildiğinde keyboard'u kapat
                        }) {
                            HStack {
                                Image(systemName: "scope")
                                    .font(.caption)
                                    .foregroundColor(AppColors.accent)
                                
                                Text(suggestion)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .font(.caption)
                                    .foregroundColor(AppColors.accent)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.card)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < min(4, viewModel.ingredientSuggestions.count - 1) {
                            Divider()
                                .background(AppColors.secondary.opacity(0.3))
                        }
                    }
                }
                .background(AppColors.card)
                .cornerRadius(12)
                .shadow(color: AppColors.shadow, radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Categories")
                    .font(.headline.bold())
                    .foregroundColor(AppColors.primary)
                Spacer()
            }
            
            categoryGrid
        }
    }
    
    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(viewModel.dynamicCategories, id: \.name) { category in
                IngredientCategoryButton(category: category) {
                    if let randomIngredient = category.ingredients.randomElement() {
                        viewModel.addIngredient(randomIngredient)
                    }
                }
            }
        }
    }
    
    // MARK: - Selected Ingredients Section
    private var selectedIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Selected Ingredients (\(viewModel.userIngredients.count))")
                    .font(.headline.bold())
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Button(action: {
                    showingClearAlert = true
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red.opacity(0.8))
                }
                .disabled(viewModel.userIngredients.isEmpty)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(viewModel.userIngredients, id: \.self) { ingredient in
                    HStack(spacing: 8) {
                        Text(IngredientEmojiHelper.getEmoji(for: ingredient))
                            .font(.title3)
                        
                        Text(ingredient.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.removeIngredient(ingredient)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.1), AppColors.primary.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "list.bullet.rectangle",
                title: "Perfect Match",
                value: "\(viewModel.suggestedRecipes.count)",
                color: AppColors.accent
            )
            
            StatCard(
                icon: "chart.pie",
                title: "Partial Match",
                value: "\(viewModel.partialMatchRecipes.count)",
                color: AppColors.primary
            )
            
            StatCard(
                icon: "star.fill",
                title: "Total Recipes",
                value: "\(viewModel.suggestedRecipes.count + viewModel.partialMatchRecipes.count)",
                color: .green
            )
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.suggestRecipes()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3.bold())
                
                Text("Get Recipe Suggestions")
                    .font(.headline.bold())
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: AppColors.accent.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(viewModel.userIngredients.isEmpty)
        .opacity(viewModel.userIngredients.isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppColors.accent)
            
            Text("Preparing recipe suggestions...")
                .font(.subheadline)
                .foregroundColor(AppColors.secondary)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Error Section
    private func errorSection(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("An error occurred")
                .font(.headline.bold())
                .foregroundColor(AppColors.primary)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(AppColors.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.suggestRecipes()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppColors.accent)
            .cornerRadius(12)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(spacing: 24) {
            // Perfect Matches
            if !viewModel.suggestedRecipes.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                        
                        Text("Perfect Matches")
                            .font(.headline.bold())
                            .foregroundColor(AppColors.primary)
                        
                        Spacer()
                        
                        Text("\(viewModel.suggestedRecipes.count)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green)
                            .cornerRadius(8)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(viewModel.suggestedRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                EnhancedRecipeCard(recipe: recipe, matchType: .perfect)
                            }
                        }
                    }
                }
            }
            
            // Partial Matches
            if !viewModel.partialMatchRecipes.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                        
                        Text("Partial Matches")
                            .font(.headline.bold())
                            .foregroundColor(AppColors.primary)
                        
                        Spacer()
                        
                        Text("\(viewModel.partialMatchRecipes.count)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.accent)
                            .cornerRadius(8)
                    }
                    
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.partialMatchRecipes, id: \.recipe.id) { result in
                            NavigationLink(destination: RecipeDetailView(recipe: result.recipe)) {
                                PartialMatchCard(partialMatch: result)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - AI Assistant Section
    private var aiAssistantSection: some View {
        AIAssistantCard(userIngredients: viewModel.userIngredients) {
            showingAIChat = true
        }
    }

}

#Preview {
    IngredientSuggestionView()
} 