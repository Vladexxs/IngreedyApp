import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = HomeViewModel()
    let categories = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack(alignment: .center) {
                            Image(systemName: viewModel.timeBasedIcon)
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.primary)
                                .offset(y: -12)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(viewModel.greetingText)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.primary)
                                Text(viewModel.homeModel?.user.fullName ?? "")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppColors.text)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 18)
                        // Featured
                        Text("Featured")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.text)
                            .padding(.horizontal, 24)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.featuredRecipes, id: \ .id) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        FeaturedRecipeCard(recipe: recipe)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                        // Category
                        HStack {
                            Text("Category")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppColors.text)
                            Spacer()
                            Button("See All") {}
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(categories, id: \.self) { cat in
                                    Button(action: { viewModel.selectedMealType = cat }) {
                                        Text(cat)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(viewModel.selectedMealType == cat ? .white : AppColors.text)
                                            .padding(.horizontal, 22)
                                            .padding(.vertical, 10)
                                            .background(viewModel.selectedMealType == cat ? AppColors.accent : AppColors.card)
                                            .cornerRadius(18)
                                            .shadow(color: viewModel.selectedMealType == cat ? AppColors.accent.opacity(0.18) : .clear, radius: 4, y: 1)
                                    }
                                    .animation(.easeInOut(duration: 0.18), value: viewModel.selectedMealType)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 32)
                        // Popular Recipes
                        HStack {
                            Text("Popular Recipes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppColors.text)
                            Spacer()
                            Button("See All") {}
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
                            ForEach(viewModel.popularRecipes, id: \ .id) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    PopularRecipeCard(recipe: recipe)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    .padding(.bottom, 8)
                }
            }
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
