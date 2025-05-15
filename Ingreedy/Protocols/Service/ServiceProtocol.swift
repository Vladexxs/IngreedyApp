import Foundation

protocol ServiceProtocol {
    associatedtype Model
    
    func fetch() async throws -> [Model]
    func fetch(id: String) async throws -> Model?
    func create(_ model: Model) async throws
    func update(_ model: Model) async throws
    func delete(id: String) async throws
} 