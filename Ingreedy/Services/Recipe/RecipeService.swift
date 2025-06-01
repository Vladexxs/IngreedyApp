import Foundation

// MARK: - Recipe Service Protocol
protocol RecipeServiceProtocol {
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void)
    func searchRecipes(query: String, completion: @escaping (Result<[Recipe], Error>) -> Void)
    func fetchPopularRecipes(limit: Int, completion: @escaping (Result<[Recipe], Error>) -> Void)
    func fetchRecipesByMealType(_ mealType: String, completion: @escaping (Result<[Recipe], Error>) -> Void)
}

// MARK: - Recipe Service Implementation
final class RecipeService: RecipeServiceProtocol {
    
    // MARK: - Properties
    private let baseURL = "https://dummyjson.com/recipes"
    private let session: URLSession
    
    // MARK: - Initializer
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let urlString = "\(baseURL)?limit=50"
        performRequest(urlString: urlString, completion: completion)
    }
    
    func searchRecipes(query: String, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(RecipeServiceError.invalidURL))
            return
        }
        let urlString = "\(baseURL)/search?q=\(encodedQuery)"
        performRequest(urlString: urlString, completion: completion)
    }
    
    func fetchPopularRecipes(limit: Int = 10, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let urlString = "\(baseURL)?sortBy=rating&order=desc&limit=\(limit)"
        performRequest(urlString: urlString, completion: completion)
    }
    
    func fetchRecipesByMealType(_ mealType: String, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let lowercasedType = mealType.lowercased()
        let urlString = "\(baseURL)/meal-type/\(lowercasedType)"
        performRequest(urlString: urlString, completion: completion)
    }
    
    // MARK: - Private Methods
    private func performRequest(urlString: String, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(RecipeServiceError.invalidURL))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    private func performRequest(url: URL, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            // Handle network error
            if let error = error {
                completion(.failure(RecipeServiceError.networkError(error)))
                return
            }
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(RecipeServiceError.invalidResponse))
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                completion(.failure(RecipeServiceError.serverError(httpResponse.statusCode)))
                return
            }
            
            // Validate data
            guard let data = data else {
                completion(.failure(RecipeServiceError.noData))
                return
            }
            
            // Decode data
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(RecipeResponse.self, from: data)
                completion(.success(response.recipes))
            } catch {
                completion(.failure(RecipeServiceError.decodingError(error)))
            }
        }
        
        task.resume()
    }
}

// MARK: - Recipe Service Errors
enum RecipeServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case noData
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
} 