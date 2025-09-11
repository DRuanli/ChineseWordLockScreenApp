//
//  MainTabView.swift
//  ChineseWordLockScreen
//
//  Updated for the redesigned home view
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            StudyDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(2)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(3)
            
            ProfileSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
        .onAppear {
            notificationManager.requestAuthorization()
            
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
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
        NavigationView {
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
        }
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
