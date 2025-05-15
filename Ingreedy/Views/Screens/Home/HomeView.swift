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

#Preview {
    HomeView()
        .environmentObject(Router())
} 
