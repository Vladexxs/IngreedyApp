import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: Router
    
    // Example data
    @State private var selectedCategory = "Breakfast"
    let userName = "Alena Sabyan"
    let featuredRecipes = [
        (title: "Asian white noodle with extra seafood", author: "James Spader", time: "20 Min", image: "featured1"),
        (title: "Healthy noodle with fresh veggie", author: "Olivia Wilde", time: "15 Min", image: "featured2")
    ]
    let categories = ["Breakfast", "Lunch", "Dinner"]
    let popularRecipes = [
        (title: "Healthy Taco Salad with fresh vegetable", kcal: 120, image: "popular1"),
        (title: "Japanese-style Pancakes Recipe", kcal: 64, image: "popular2")
    ]
    
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
                            ForEach(featuredRecipes, id: \ .title) { recipe in
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
                    HStack(spacing: 18) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat)
                                    .font(.subheadline.bold())
                                    .foregroundColor(selectedCategory == cat ? .white : AppColors.text)
                                    .padding(.horizontal, 26)
                                    .padding(.vertical, 12)
                                    .background(selectedCategory == cat ? AppColors.accent : AppColors.card)
                                    .cornerRadius(22)
                                    .shadow(color: selectedCategory == cat ? AppColors.accent.opacity(0.25) : .clear, radius: 6, y: 2)
                            }
                            .animation(.easeInOut(duration: 0.18), value: selectedCategory)
                        }
                    }
                    .padding(.horizontal, 20)
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
                            ForEach(popularRecipes, id: \ .title) { recipe in
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
    let recipe: (title: String, author: String, time: String, image: String)
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(AppColors.primary.opacity(0.15))
                .frame(width: 230, height: 130)
                .shadow(color: AppColors.primary.opacity(0.10), radius: 8, y: 4)
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
                Text(recipe.title)
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.text)
                    .lineLimit(2)
                Spacer()
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                    Text(recipe.author)
                        .font(.caption)
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                    Text(recipe.time)
                        .font(.caption)
                        .foregroundColor(AppColors.text)
                }
            }
            .padding(16)
        }
        .frame(width: 230, height: 130)
    }
}

struct PopularRecipeCard: View {
    @State private var isFavorite = false
    let recipe: (title: String, kcal: Int, image: String)
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppColors.card)
                    .frame(width: 160, height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .opacity(0.3)
                    )
                Text(recipe.title)
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.text)
                    .lineLimit(2)
                    .frame(width: 160, alignment: .leading)
                HStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.caption)
                        .foregroundColor(AppColors.accent)
                    Text("\(recipe.kcal) Kcal")
                        .font(.caption)
                        .foregroundColor(AppColors.text)
                }
                Spacer(minLength: 4) // Alt boşluk ekle
            }
            .frame(width: 170, height: 200) // Kartı biraz daha yüksek ve geniş yap
            .padding(.vertical, 8) // Üst-alt padding
            .padding(.horizontal, 4)
            .background(AppColors.card)
            .cornerRadius(22) // Daha belirgin köşe
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
