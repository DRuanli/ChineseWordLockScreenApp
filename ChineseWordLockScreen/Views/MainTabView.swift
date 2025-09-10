//
//  MainTabView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                LibraryView()
                    .tag(1)
                
                StatsView()
                    .tag(2)
                
                ProfileSettingsView()
                    .tag(3)
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear {
            notificationManager.requestAuthorization()
            UITabBar.appearance().isHidden = true
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: "主页",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabBarButton(
                icon: "books.vertical.fill",
                title: "词库",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabBarButton(
                icon: "chart.bar.fill",
                title: "统计",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            TabBarButton(
                icon: "person.circle.fill",
                title: "我的",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .teal : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .teal : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ProfileSettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var showingLogoutAlert = false
    @State private var selectedHSKLevel = 5
    @State private var dailyGoal = 10
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderCard()
                    
                    // Settings Sections
                    VStack(spacing: 15) {
                        // Learning Settings
                        SettingsCard(title: "学习设置", icon: "book.circle.fill", color: .blue) {
                            VStack(spacing: 15) {
                                // HSK Level
                                HStack {
                                    Text("HSK 级别")
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
                                
                                // Daily Goal
                                HStack {
                                    Text("每日目标")
                                        .font(.subheadline)
                                    Spacer()
                                    Stepper("\(dailyGoal) 词", value: $dailyGoal, in: 5...50, step: 5)
                                        .frame(width: 120)
                                }
                            }
                        }
                        
                        // Notification Settings
                        SettingsCard(title: "通知设置", icon: "bell.circle.fill", color: .orange) {
                            VStack(spacing: 15) {
                                Toggle("启用通知", isOn: $notificationManager.isNotificationEnabled)
                                    .font(.subheadline)
                                
                                if notificationManager.isNotificationEnabled {
                                    Divider()
                                    Stepper("每日提醒: \(notificationManager.notificationFrequency)次",
                                            value: $notificationManager.notificationFrequency,
                                            in: 1...5)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        // Widget Instructions
                        SettingsCard(title: "Widget 设置", icon: "square.stack.3d.up.fill", color: .purple) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("添加Widget到锁屏:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                ForEach([
                                    "1. 长按锁屏",
                                    "2. 点击自定义",
                                    "3. 添加小组件",
                                    "4. 选择 Chinese Word"
                                ], id: \.self) { step in
                                    Text(step)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Account Actions
                        VStack(spacing: 10) {
                            Button(action: { showingLogoutAlert = true }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("退出登录")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("我的")
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
        .alert("退出登录", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }
}

struct ProfileHeaderCard: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var wordDataManager = WordDataManager.shared
    
    var body: some View {
        VStack(spacing: 15) {
            // Avatar
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
            
            // Username
            Text(authManager.currentUser?.username ?? "用户")
                .font(.title3)
                .fontWeight(.semibold)
            
            // Email
            Text(authManager.currentUser?.email ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Stats
            HStack(spacing: 30) {
                VStack {
                    Text("\(wordDataManager.savedWords.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.teal)
                    Text("已学词汇")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(wordDataManager.streak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("连续天数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("HSK\(authManager.currentUser?.preferredHSKLevel ?? 5)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("当前级别")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
        .padding(.horizontal)
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
    }
}

#Preview {
    MainTabView()
}
