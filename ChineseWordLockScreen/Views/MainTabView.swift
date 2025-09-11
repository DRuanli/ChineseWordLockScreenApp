//
//  MainTabView.swift
//  ChineseWordLockScreen
//
//  Custom minimalist tab bar with 3 buttons
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab: TabItem = .practice
    @State private var showingCategories = false
    @State private var showingPractice = false
    @State private var showingProfile = false
    
    enum TabItem {
        case categories
        case practice
        case profile
    }
    
    var body: some View {
        ZStack {
            // Main content - Home View as base
            HomeView()
                .ignoresSafeArea(.keyboard)
            
            // Custom Tab Bar at bottom
            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: $selectedTab,
                    showingCategories: $showingCategories,
                    showingPractice: $showingPractice,
                    showingProfile: $showingProfile
                )
            }
        }
        .onAppear {
            notificationManager.requestAuthorization()
            setupTabBarAppearance()
        }
        .fullScreenCover(isPresented: $showingCategories) {
            CategoriesHubView()
        }
        .fullScreenCover(isPresented: $showingPractice) {
            PracticeHubView()
        }
        .fullScreenCover(isPresented: $showingProfile) {
            ProfileHubView()
        }
    }
    
    private func setupTabBarAppearance() {
        UITabBar.appearance().isHidden = true
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.TabItem
    @Binding var showingCategories: Bool
    @Binding var showingPractice: Bool
    @Binding var showingProfile: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Categories Button
            TabBarButton(
                icon: "square.grid.2x2",
                isSelected: selectedTab == .categories,
                isCenter: false
            ) {
                showingCategories = true
                HapticFeedback.light.trigger()
            }
            .frame(maxWidth: .infinity)
            
            // Practice Button (Center - Larger)
            TabBarButton(
                icon: "graduationcap.fill",
                isSelected: selectedTab == .practice,
                isCenter: true
            ) {
                showingPractice = true
                HapticFeedback.medium.trigger()
            }
            .frame(maxWidth: .infinity)
            
            // Profile Button
            TabBarButton(
                icon: "person",
                isSelected: selectedTab == .profile,
                isCenter: false
            ) {
                showingProfile = true
                HapticFeedback.light.trigger()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, y: -2)
        )
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    var text: String? = nil
    let isSelected: Bool
    let isCenter: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isCenter {
                // Center button with special design
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                    
                    if let text = text {
                        Text(text)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(red: 0.72, green: 0.90, blue: 0.89)) // B8E5E3
                )
            } else {
                // Regular button
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.black.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.gray.opacity(0.1) : Color.clear)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Categories Hub View
struct CategoriesHubView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showingLibrary = false
    @State private var showingProgress = false
    @State private var showingStats = false
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.91, blue: 0.91) // F5F1E8
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search topics", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Make your own mix button
                            Button(action: {
                                showingPaywall = true
                            }) {
                                Text("Make your own mix")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color(red: 0.72, green: 0.90, blue: 0.89))
                                    .cornerRadius(20)
                            }
                            .padding(.horizontal)
                            
                            // Main categories grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                CategoryCard(
                                    icon: "books.vertical",
                                    title: "Library",
                                    isSelected: false
                                ) {
                                    showingLibrary = true
                                }
                                
                                CategoryCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Progress",
                                    isSelected: false
                                ) {
                                    showingProgress = true
                                }
                                
                                CategoryCard(
                                    icon: "chart.bar.fill",
                                    title: "Statistics",
                                    isSelected: false
                                ) {
                                    showingStats = true
                                }
                                
                                CategoryCard(
                                    icon: "heart.fill",
                                    title: "Favorites",
                                    isSelected: false
                                ) {
                                    showingLibrary = true
                                }
                                
                                CategoryCard(
                                    icon: "folder.fill",
                                    title: "Collections",
                                    isSelected: false
                                ) {
                                    showingLibrary = true
                                }
                                
                                CategoryCard(
                                    icon: "square.and.pencil",
                                    title: "Your own words",
                                    hasLock: true
                                ) {
                                    showingPaywall = true
                                }
                            }
                            .padding(.horizontal)
                            
                            // About ourselves section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("About ourselves")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    TopicCard(
                                        image: "face.smiling",
                                        title: "Emotions",
                                        hasLock: true,
                                        action: {
                                            showingPaywall = true
                                        }
                                    )
                                    
                                    TopicCard(
                                        image: "figure.stand",
                                        title: "Human body",
                                        hasLock: true,
                                        action: {
                                            showingPaywall = true
                                        }
                                    )
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 20)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Unlock all") {
                        showingPaywall = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingLibrary) {
            NavigationView {
                LibraryView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showingLibrary = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showingProgress) {
            NavigationView {
                StudyDashboardView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showingProgress = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showingStats) {
            StatsView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let icon: String
    let title: String
    var isSelected: Bool = false
    var hasLock: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.blue))
                    }
                    
                    if hasLock {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Topic Card
struct TopicCard: View {
    let image: String
    let title: String
    var hasLock: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .frame(height: 140)
                    
                    VStack {
                        Image(systemName: image)
                            .font(.system(size: 40))
                            .foregroundColor(.black.opacity(0.7))
                        
                        Spacer()
                    }
                    .padding()
                    
                    if hasLock {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Practice Hub View
struct PracticeHubView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            PracticeView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Profile Hub View
struct ProfileHubView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ProfileSettingsView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

// Keep the ProfileSettingsView exactly as it was
struct ProfileSettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var showingLogoutAlert = false
    @State private var selectedHSKLevel = 5
    @State private var dailyGoal = 10
    @State private var showingPaywall = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header - Simplified
                VStack(spacing: 15) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(authManager.currentUser?.username?.first?.uppercased() ?? "U")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: 4) {
                        Text(authManager.currentUser?.username ?? "用户")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(authManager.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 10)
                )
                .padding(.horizontal)
                
                // Settings Sections
                VStack(spacing: 15) {
                    // Premium upgrade card
                    Button(action: { showingPaywall = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nâng cấp Premium")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Mở khóa toàn bộ tính năng")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "crown.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Learning Settings
                    SettingsCard(title: "Cài đặt học tập", icon: "book.circle.fill", color: .blue) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("HSK Level")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $selectedHSKLevel) {
                                    ForEach(3...6, id: \.self) { level in
                                        Text("HSK \(level)").tag(level)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 200)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Mục tiêu hàng ngày")
                                    .font(.subheadline)
                                Spacer()
                                Stepper("\(dailyGoal) từ", value: $dailyGoal, in: 5...50, step: 5)
                                    .frame(width: 120)
                            }
                        }
                    }
                    
                    // Notification Settings
                    SettingsCard(title: "Thông báo", icon: "bell.circle.fill", color: .orange) {
                        VStack(spacing: 15) {
                            Toggle("Bật thông báo", isOn: $notificationManager.isNotificationEnabled)
                                .font(.subheadline)
                            
                            if notificationManager.isNotificationEnabled {
                                Divider()
                                Stepper("Tần suất: \(notificationManager.notificationFrequency) lần/ngày",
                                        value: $notificationManager.notificationFrequency,
                                        in: 1...5)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // Widget Instructions
                    SettingsCard(title: "Widget", icon: "square.stack.3d.up.fill", color: .purple) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Thêm Widget vào màn hình khóa:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach([
                                "1. Nhấn giữ màn hình khóa",
                                "2. Chọn Tùy chỉnh",
                                "3. Thêm tiện ích",
                                "4. Chọn Chinese Word"
                            ], id: \.self) { step in
                                Text(step)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Logout
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Đăng xuất")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Cài đặt")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.05))
        .onAppear {
            if let user = authManager.currentUser {
                selectedHSKLevel = Int(user.preferredHSKLevel)
                dailyGoal = Int(user.dailyGoal)
            }
        }
        .onChange(of: selectedHSKLevel) { newValue in
            authManager.updateUserProfile(hskLevel: newValue)
            wordDataManager.selectedHSKLevel = newValue
        }
        .onChange(of: dailyGoal) { newValue in
            authManager.updateUserProfile(dailyGoal: newValue)
        }
        .onChange(of: notificationManager.isNotificationEnabled) { newValue in
            authManager.updateUserProfile(notificationEnabled: newValue)
            if newValue {
                notificationManager.requestAuthorization()
            }
        }
        .onChange(of: notificationManager.notificationFrequency) { newValue in
            authManager.updateUserProfile(notificationFrequency: newValue)
            notificationManager.updateNotificationFrequency(newValue)
        }
        .alert("Đăng xuất", isPresented: $showingLogoutAlert) {
            Button("Hủy", role: .cancel) { }
            Button("Đăng xuất", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Bạn có chắc muốn đăng xuất?")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
    }
}

#Preview {
    MainTabView()
}
