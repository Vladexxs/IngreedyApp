import Foundation

struct HomeModel {
    var user: User
    var recipes: [Recipe] = []
}

struct Recipe {
    let id: String
    let title: String
    let imageURL: String
    let cookingTime: String
    let difficulty: String
} 