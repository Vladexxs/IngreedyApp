import Foundation
import Combine

// MARK: - Ingredient Suggestion ViewModel Protocol
protocol IngredientSuggestionViewModelProtocol: ObservableObject {
    var userIngredients: [String] { get }
    var suggestedRecipes: [Recipe] { get }
    var partialMatchRecipes: [PartialMatchResult] { get }
    var searchText: String { get set }
    var ingredientSuggestions: [String] { get }
    var allIngredients: Set<String> { get }
    var dynamicCategories: [IngredientCategory] { get }
    var isLoading: Bool { get }
    var error: Error? { get }
    
    func addIngredient(_ ingredient: String)
    func removeIngredient(_ ingredient: String)
    func suggestRecipes()
    func clearIngredients()
    func fetchAllIngredients()
}

// MARK: - Ingredient Suggestion ViewModel Implementation
@MainActor
final class IngredientSuggestionViewModel: BaseViewModel, IngredientSuggestionViewModelProtocol {
    
    // MARK: - Published Properties
    @Published var userIngredients: [String] = []
    @Published var suggestedRecipes: [Recipe] = []
    @Published var partialMatchRecipes: [PartialMatchResult] = []
    @Published var searchText: String = "" {
        didSet { updateIngredientSuggestions() }
    }
    @Published var ingredientSuggestions: [String] = []
    @Published var allIngredients: Set<String> = []
    
    // MARK: - Computed Properties
    var dynamicCategories: [IngredientCategory] {
        IngredientCategory.createCategories(from: allIngredients)
    }
    
    // MARK: - Private Properties
    private let recipeService: RecipeServiceProtocol
    private var allRecipes: [Recipe] = []
    
    // MARK: - Initializer
    init(recipeService: RecipeServiceProtocol = RecipeService()) {
        self.recipeService = recipeService
        super.init()
        fetchAllIngredients()
    }
    
    // MARK: - Public Methods
    func fetchAllIngredients() {
        performNetwork(recipeService.fetchRecipes) { [weak self] recipes in
            self?.allRecipes = recipes
            self?.collectAllIngredients(from: recipes)
        }
    }
    
    func addIngredient(_ ingredient: String) {
        let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, 
              !userIngredients.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { 
            return 
        }
        
        userIngredients.append(trimmed)
        searchText = ""
        updateIngredientSuggestions()
    }
    
    func removeIngredient(_ ingredient: String) {
        userIngredients.removeAll { $0.caseInsensitiveCompare(ingredient) == .orderedSame }
    }
    
    func suggestRecipes() {
        guard !userIngredients.isEmpty else { return }
        
        if allRecipes.isEmpty {
            fetchAllIngredients()
            return
        }
        
        processRecipes(allRecipes)
    }
    
    func clearIngredients() {
        userIngredients.removeAll()
        suggestedRecipes.removeAll()
        partialMatchRecipes.removeAll()
        searchText = ""
        ingredientSuggestions = []
    }
    
    // MARK: - Private Methods
    private func collectAllIngredients(from recipes: [Recipe]) {
        var ingredientSet = Set<String>()
        
        for recipe in recipes {
            for ingredient in recipe.displayIngredients {
                ingredientSet.insert(ingredient)
            }
        }
        
        allIngredients = ingredientSet
        updateIngredientSuggestions()
    }
    
    private func updateIngredientSuggestions() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            ingredientSuggestions = []
            return
        }
        
        ingredientSuggestions = allIngredients
            .filter { ingredient in
                ingredient.lowercased().contains(query) &&
                !userIngredients.contains(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame })
            }
            .sorted()
    }
    
    private func processRecipes(_ recipes: [Recipe]) {
        let userIngredientsSet = Set(userIngredients.map { 
            $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) 
        })
        
        guard !userIngredientsSet.isEmpty else { return }
        
        var matches: [(recipe: Recipe, matchRatio: Double, matchingIngredients: [String], missingIngredients: [String])] = []
        
        for recipe in recipes {
            let recipeIngredientsSet = Set(recipe.displayIngredients.map { 
                $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) 
            })
            
            guard !recipeIngredientsSet.isEmpty else { continue }
            
            let matchingIngredients = Array(userIngredientsSet.intersection(recipeIngredientsSet))
            let missingIngredients = Array(recipeIngredientsSet.subtracting(userIngredientsSet))
            
            // Calculate match ratio
            let matchRatio = Double(matchingIngredients.count) / Double(recipeIngredientsSet.count)
            
            // Only include recipes where at least one ingredient matches
            if !matchingIngredients.isEmpty {
                matches.append((
                    recipe: recipe,
                    matchRatio: matchRatio,
                    matchingIngredients: matchingIngredients,
                    missingIngredients: missingIngredients
                ))
            }
        }
        
        // Sort matches by match ratio (highest first)
        matches.sort { $0.matchRatio > $1.matchRatio }
        
        // Separate exact matches and partial matches
        let exactMatches = matches
            .filter { $0.matchRatio == 1.0 }
            .map { $0.recipe }
        
        let partialMatches = matches
            .filter { $0.matchRatio < 1.0 }
            .map { PartialMatchResult(
                recipe: $0.recipe,
                matchingIngredients: $0.matchingIngredients,
                missingIngredients: $0.missingIngredients
            )}
        
        self.suggestedRecipes = exactMatches
        self.partialMatchRecipes = partialMatches
    }
} 