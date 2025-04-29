import Foundation

class IngredientSuggestionViewModel: ObservableObject {
    @Published var userIngredients: [String] = []
    @Published var suggestedRecipes: [Recipe] = []
    @Published var partialMatchRecipes: [(recipe: Recipe, missingIngredients: [String])] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText: String = "" {
        didSet { updateIngredientSuggestions() }
    }
    @Published var ingredientSuggestions: [String] = []

    private let recipeService = RecipeService()
    private var allIngredients: Set<String> = []
    private var allRecipes: [Recipe] = []

    init() {
        fetchAllIngredients()
    }

    func fetchAllIngredients() {
        isLoading = true
        recipeService.fetchRecipes { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let recipes):
                    self?.allRecipes = recipes
                    self?.collectAllIngredients(from: recipes)
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }

    func addIngredient(_ ingredient: String) {
        let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !userIngredients.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        userIngredients.append(trimmed)
        searchText = ""
        updateIngredientSuggestions()
    }

    func removeIngredient(_ ingredient: String) {
        userIngredients.removeAll { $0.caseInsensitiveCompare(ingredient) == .orderedSame }
    }

    func suggestRecipes() {
        if allRecipes.isEmpty {
            isLoading = true
            fetchAllIngredients()
            return
        }
        processRecipes(allRecipes)
    }

    private func collectAllIngredients(from recipes: [Recipe]) {
        var set = Set<String>()
        for recipe in recipes {
            for ingredient in recipe.ingredients ?? [] {
                set.insert(ingredient)
            }
        }
        allIngredients = set
        updateIngredientSuggestions()
    }

    private func updateIngredientSuggestions() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            ingredientSuggestions = []
            return
        }
        ingredientSuggestions = allIngredients.filter { ingredient in
            ingredient.lowercased().contains(query)
                && !userIngredients.contains(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame })
        }.sorted()
    }

    private func processRecipes(_ recipes: [Recipe]) {
        let userSet = Set(userIngredients.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
        var matches: [(recipe: Recipe, matchRatio: Double, missingIngredients: [String])] = []

        guard !userSet.isEmpty else { return }

        for recipe in recipes {
            let recipeIngredients = Set((recipe.ingredients ?? []).map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
            guard !recipeIngredients.isEmpty else { continue }

            let matchingIngredients = userSet.intersection(recipeIngredients)
            let missingIngredients = Array(recipeIngredients.subtracting(userSet))
            
            // Calculate match ratio
            let matchRatio = Double(matchingIngredients.count) / Double(recipeIngredients.count)
            
            // Only include recipes where at least one ingredient matches
            if matchingIngredients.count > 0 {
                matches.append((recipe: recipe, matchRatio: matchRatio, missingIngredients: missingIngredients))
            }
        }

        // Sort matches by match ratio (highest first)
        matches.sort { $0.matchRatio > $1.matchRatio }

        // Separate exact matches and partial matches
        let exactMatches = matches.filter { $0.matchRatio == 1.0 }.map { $0.recipe }
        let partial = matches.filter { $0.matchRatio < 1.0 }.map { (recipe: $0.recipe, missingIngredients: $0.missingIngredients) }

        self.suggestedRecipes = exactMatches
        self.partialMatchRecipes = partial
    }

    func clearIngredients() {
        userIngredients.removeAll()
        suggestedRecipes.removeAll()
        partialMatchRecipes.removeAll()
        searchText = ""
        ingredientSuggestions = []
    }
} 