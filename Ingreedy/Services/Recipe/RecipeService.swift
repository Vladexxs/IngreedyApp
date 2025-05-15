import Foundation

struct Recipe: Codable, Identifiable {
    let id: Int
    let name: String
    let ingredients: [String]?
    let instructions: [String]?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let servings: Int?
    let difficulty: String?
    let cuisine: String?
    let caloriesPerServing: Int?
    let tags: [String]?
    let image: String?
    let rating: Double?
}

class RecipeService {
    private let baseURL = "https://dummyjson.com/recipes"
    
    // Tekrarlayan network ve decode işlemleri için yardımcı fonksiyon
    private func performRequest(url: URL, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(RecipeResponse.self, from: data)
                completion(.success(response.recipes))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        // Tüm tarifleri çekmek için limit=50 parametresi ekleniyor
        guard let url = URL(string: baseURL + "?limit=50") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        performRequest(url: url, completion: completion)
    }
    
    func searchRecipes(query: String, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        performRequest(url: url, completion: completion)
    }
    
    func fetchPopularRecipes(limit: Int = 10, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)?sortBy=rating&order=desc&limit=\(limit)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        performRequest(url: url, completion: completion)
    }
    
    func fetchRecipesByMealType(_ mealType: String, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let lowercasedType = mealType.lowercased()
        guard let url = URL(string: "\(baseURL)/meal-type/\(lowercasedType)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        performRequest(url: url, completion: completion)
    }
}

struct RecipeResponse: Codable {
    let recipes: [Recipe]
    let total: Int?
    let skip: Int?
    let limit: Int?
} 