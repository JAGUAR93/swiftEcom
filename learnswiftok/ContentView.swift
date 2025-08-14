//
//  ContentView.swift
//  learnswiftok
//
//  Created by RISHABH KUMAR on 13/08/25

import SwiftUI

// MARK: - Models
struct Product: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let image: String
    let rating: Rating
}

struct Rating: Codable, Hashable {
    let rate: Double
    let count: Int
}

// MARK: - ViewModel
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var cartItems: [Product: Int] = [:] // Product with quantity
    @Published var errorMessage: String? = nil
    
    func fetchProducts() {
        guard let url = URL(string: "https://fakestoreapi.com/products") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print(" Error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data"
                    print(" API Error: No data received")
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([Product].self, from: data)
                    self.products = decoded
                    print(" Parsed Products Count: \(decoded.count)")
                } catch {
                    self.errorMessage = "Decoding error"
                    print(" Decoding Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func toggleCart(product: Product) {
        if let qty = cartItems[product] {
            cartItems[product] = nil
            print("🗑 Removed from cart: \(product.title)")
        } else {
            cartItems[product] = 1
            print("🛒 Added to cart: \(product.title)")
        }
    }
    
    func updateQuantity(product: Product, increment: Bool) {
        guard let qty = cartItems[product] else { return }
        if increment {
            cartItems[product] = qty + 1
        } else {
            cartItems[product] = max(1, qty - 1)
        }
        print("🔄 Updated quantity for \(product.title): \(cartItems[product]!)")
    }
    
    func isInCart(product: Product) -> Bool {
        cartItems.keys.contains(product)
    }
    
    var totalCartItems: Int {
        cartItems.values.reduce(0, +)
    }
    
    var totalPrice: Double {
        cartItems.reduce(0) { total, item in
            total + (item.key.price * Double(item.value))
        }
    }
}
//Main App
struct ContentView: View {
    @StateObject var viewModel = ProductViewModel()
    @State private var selectedTab = 0
    @State private var selectedProduct: Product?
    @State private var showThankYou = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel, selectedProduct: $selectedProduct, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }.tag(0)
            
            Text("Catalog")
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "square.grid.2x2.fill" : "square.grid.2x2")
                    Text("Catalog")
                }.tag(1)
            
            CartView(viewModel: viewModel, showThankYou: $showThankYou)
                .tabItem {
                    ZStack {
                        Image(systemName: selectedTab == 2 ? "cart.fill" : "cart")
                        if viewModel.totalCartItems > 0 {
                            Text("\(viewModel.totalCartItems)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                    Text("Cart")
                }.tag(2)
            
            Text("Favorites")
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                    Text("Favorites")
                }.tag(3)
            
            Text("Profile")
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }.tag(4)
        }
        .accentColor(Color(red: 0.7, green: 0.9, blue: 0.3))
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(product: product, viewModel: viewModel)
        }
        .alert("Thank You!", isPresented: $showThankYou) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your order has been placed successfully!")
        }
        .onAppear {
            viewModel.fetchProducts()
        }
    }
}

// MARK: - Home Screen
struct HomeView: View {
    @ObservedObject var viewModel: ProductViewModel
    @Binding var selectedProduct: Product?
    @Binding var selectedTab: Int // Added this binding
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header with delivery address
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color(red: 0.7, green: 0.9, blue: 0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                )
                            
                            VStack(alignment: .leading) {
                                Text("Delivery address")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("92 High Street, London")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            // Cart icon in top bar - Test requirement
                            Button(action: { selectedTab = 2 }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "cart")
                                        .foregroundColor(.black)
                                        .font(.title3)
                                    
                                    if viewModel.totalCartItems > 0 {
                                        Text("\(viewModel.totalCartItems)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 8, y: -8)
                                    }
                                }
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "bell")
                                    .foregroundColor(.black)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search the entire shop", text: .constant(""))
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Delivery Banner
                    HStack {
                        Text("Delivery is")
                            .foregroundColor(.black)
                        Text("50%")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("cheaper")
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                            .font(.title2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.9, green: 0.95, blue: 0.85))
                    )
                    .padding(.horizontal, 20)
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {}) {
                                Text("See all")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 24) {
                                CategoryItem(icon: "iphone", title: "Phones")
                                CategoryItem(icon: "gamecontroller.fill", title: "Consoles")
                                CategoryItem(icon: "laptopcomputer", title: "Laptops")
                                CategoryItem(icon: "camera.fill", title: "Cameras")
                                CategoryItem(icon: "headphones", title: "Audio")
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Products Grid - Main requirement
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("All Products")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("See all")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Grid View - As per test requirements
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(viewModel.products, id: \.id) { product in
                                ProductGridCard(product: product, viewModel: viewModel)
                                    .onTapGesture {
                                        selectedProduct = product
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if viewModel.products.isEmpty && viewModel.errorMessage == nil {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading products...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                Text("Error: \(errorMessage)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    viewModel.fetchProducts()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Category Item
struct CategoryItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.black)
                        .font(.title3)
                )
            Text(title)
                .font(.caption)
                .foregroundColor(.black)
        }
    }
}
struct ProductGridCard: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Heart icon for cart - As per test requirements
                Button(action: {
                    viewModel.toggleCart(product: product)
                }) {
                    Image(systemName: viewModel.isInCart(product: product) ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isInCart(product: product) ? .red : .gray)
                        .font(.system(size: 18))
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                        )
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Title - Test requirement
                Text(product.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Description - Test requirement
                Text(product.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Rating - Test requirement
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("\(product.rating.rate, specifier: "%.1f")")
                        .font(.system(size: 12, weight: .medium))
                    Text("(\(product.rating.count))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                // Price - Test requirement
                HStack {
                    Text("£\(product.price, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    if viewModel.isInCart(product: product) {
                        Text("In Cart")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}


struct ProductCard: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(width: 150, height: 150)
                }
                .frame(width: 150, height: 150)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button(action: { viewModel.toggleCart(product: product) }) {
                    Image(systemName: viewModel.isInCart(product: product) ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isInCart(product: product) ? .red : .gray)
                        .font(.system(size: 16))
                }
                .padding(8)
            }
            
            Text(product.title)
                .font(.system(size: 14))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 150, alignment: .leading)
            
            HStack {
                Text("£\(product.price, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                if product.price > 50 {
                    Text("£\(product.price * 1.3, specifier: "%.2f")")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .strikethrough()
                }
            }
        }
        .frame(width: 150)
    }
}


struct ProductDetailView: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    AsyncImage(url: URL(string: product.image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Product Title and Heart
                        HStack(alignment: .top) {
                            Text(product.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            Button(action: { viewModel.toggleCart(product: product) }) {
                                Image(systemName: viewModel.isInCart(product: product) ? "heart.fill" : "heart")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            }
                        }
                        
                        // Rating and Reviews
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                                    .font(.caption)
                                Text("\(product.rating.rate, specifier: "%.1f")")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            Text("\(product.rating.count) reviews")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("94%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                                .cornerRadius(6)
                            
                            HStack(spacing: 2) {
                                Image(systemName: "message")
                                    .font(.caption)
                                Text("8")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                        }
                        
                        // Price
                        HStack(spacing: 8) {
                            Text("£\(product.price, specifier: "%.2f")")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if product.price > 50 {
                                Text("from £\(product.price / 12, specifier: "%.0f") per month")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Description
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                        
                        // Add to Cart Button
                        Button(action: {
                            viewModel.toggleCart(product: product)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(viewModel.isInCart(product: product) ? "Remove from cart" : "Add to cart")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                            .cornerRadius(12)
                        }
                        
                        Text("Delivery on 26 October")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                        }
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
    }
}


struct CartView: View {
    @ObservedObject var viewModel: ProductViewModel
    @Binding var showThankYou: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.cartItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Your cart is empty")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Header
                    HStack {
                        Text("Cart")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Delivery Address
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.gray)
                        Text("92 High Street, London")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Select All
                    HStack {
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                                Text("Select all")
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.black)
                            }
                            Button(action: {}) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    // Cart Items
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(viewModel.cartItems.keys), id: \.id) { product in
                                CartItemView(product: product, quantity: viewModel.cartItems[product] ?? 1, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Checkout Button
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: {
                            viewModel.cartItems.removeAll()
                            showThankYou = true
                        }) {
                            Text("Checkout")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
        }
    }
}


struct CartItemView: View {
    let product: Product
    let quantity: Int
    @ObservedObject var viewModel: ProductViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // Checkbox
            Button(action: {}) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .font(.title3)
            }
            .padding(.trailing, 12)
            
            // Product Image
            AsyncImage(url: URL(string: product.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.trailing, 12)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("£\(product.price, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // Quantity Controls
            HStack(spacing: 12) {
                Button(action: { viewModel.updateQuantity(product: product, increment: false) }) {
                    Image(systemName: "minus")
                        .foregroundColor(.black)
                        .font(.system(size: 12, weight: .bold))
                }
                
                Text("\(quantity)")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20)
                
                Button(action: { viewModel.updateQuantity(product: product, increment: true) }) {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                        .font(.system(size: 12, weight: .bold))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
