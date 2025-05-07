import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: Router
    @State private var selectedCategory = "Breakfast"
    @StateObject private var viewModel = HomeViewModel()
    let userName = "Alena Sabyan"
    let categories = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert"]
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Extra space at top to respect safe area and status bar
                    Color.clear.frame(height: 60)
                    
                    // Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Good Morning 👋")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.primary)
                            Text(userName)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.text)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    // Featured
                    Text("Featured")
                        .font(.headline)
                        .foregroundColor(AppColors.text)
                        .padding(.horizontal, 24)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(viewModel.featuredRecipes, id: \ .id) { recipe in
                                FeaturedRecipeCard(recipe: recipe)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                    
                    // Category
                    HStack {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(AppColors.text)
                        Spacer()
                        Button("See All") {}
                            .font(.subheadline)
                            .foregroundColor(AppColors.accent)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: { viewModel.selectedMealType = cat }) {
                                    Text(cat)
                                        .font(.subheadline.bold())
                                        .foregroundColor(viewModel.selectedMealType == cat ? .white : AppColors.text)
                                        .padding(.horizontal, 26)
                                        .padding(.vertical, 12)
                                        .background(viewModel.selectedMealType == cat ? AppColors.accent : AppColors.card)
                                        .cornerRadius(22)
                                        .shadow(color: viewModel.selectedMealType == cat ? AppColors.accent.opacity(0.25) : .clear, radius: 6, y: 2)
                                }
                                .animation(.easeInOut(duration: 0.18), value: viewModel.selectedMealType)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                    
                    // Popular Recipes
                    HStack {
                        Text("Popular Recipes")
                            .font(.headline)
                            .foregroundColor(AppColors.text)
                        Spacer()
                        Button("See All") {}
                            .font(.subheadline)
                            .foregroundColor(AppColors.accent)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(viewModel.popularRecipes, id: \ .id) { recipe in
                                PopularRecipeCard(recipe: recipe)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24) // Daha fazla boşluk azaltıldı
                    
                    // Show More Button
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            Text("Show More Recipes")
                                .font(.subheadline.bold())
                                .foregroundColor(AppColors.buttonText)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(AppColors.accent)
                                .cornerRadius(22)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 40) // Extra padding for tab bar azaltıldı
                    .background(Color.clear) // Butonun arkasını şeffaf yap
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct FeaturedRecipeCard: View {
    let recipe: Recipe
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 230, height: 130)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(AppColors.primary.opacity(0.15))
                        .frame(width: 230, height: 130)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.black.opacity(0.28))
                )
                .cornerRadius(22)
                .shadow(color: AppColors.primary.opacity(0.10), radius: 8, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 230, height: 130)
                    .shadow(color: AppColors.primary.opacity(0.10), radius: 8, y: 4)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Featured")
                        .font(.caption2.bold())
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(AppColors.accent.opacity(0.12))
                        .cornerRadius(8)
                    Spacer()
                }
                Text(recipe.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text(recipe.cuisine ?? "")
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) Min")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
        }
        .frame(width: 230, height: 130)
    }
}

struct PopularRecipeCard: View {
    @State private var isFavorite = false
    let recipe: Recipe
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 170, height: 120)
                            .clipped()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppColors.card)
                            .frame(width: 170, height: 120)
                    }
                    .cornerRadius(18)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppColors.card)
                        .frame(width: 170, height: 120)
                }
                Text(recipe.name)
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.text)
                    .lineLimit(2)
                    .frame(width: 160, alignment: .leading)
                HStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.caption)
                        .foregroundColor(AppColors.accent)
                    Text("\(recipe.caloriesPerServing ?? 0) Kcal")
                        .font(.caption)
                        .foregroundColor(AppColors.text)
                }
                Spacer(minLength: 4)
            }
            .frame(width: 170, height: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(AppColors.card)
            .cornerRadius(22)
            .shadow(color: AppColors.primary.opacity(0.10), radius: 6, y: 3)
            Button(action: { isFavorite.toggle() }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : AppColors.primary)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2, y: 1)
            }
            .offset(x: -10, y: 10)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Router())
} 
