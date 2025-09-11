//
//  ProfileView.swift
//  ChineseWordLockScreen
//
//  Profile and vocabulary management screen
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("F5F1E8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Banner
                        PremiumBanner()
                            .padding(.horizontal)
                        
                        // Your Vocabulary Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Vocabulary")
                                .font(.system(size: 24, weight: .bold))
                                .padding(.horizontal)
                            
                            // Streak Card
                            StreakCard(streak: wordDataManager.streak)
                                .padding(.horizontal)
                            
                            // Vocabulary Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                VocabularyCard(
                                    icon: "heart.fill",
                                    title: "Favorites",
                                    color: Color("B8E5E3")
                                )
                                VocabularyCard(
                                    icon: "pencil",
                                    title: "Your own words",
                                    isLocked: true
                                )
                                VocabularyCard(
                                    icon: "bookmark.fill",
                                    title: "Collections",
                                    color: Color("FFE5CC")
                                )
                                VocabularyCard(
                                    icon: "clock.arrow.circlepath",
                                    title: "History",
                                    color: Color("E5E5FF")
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Customize Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Customize the app")
                                .font(.system(size: 24, weight: .bold))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                CustomizeCard(
                                    icon: "square.grid.2x2",
                                    title: "Widgets",
                                    illustration: "widget"
                                )
                                CustomizeCard(
                                    icon: "bell",
                                    title: "Reminders",
                                    illustration: "notification"
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") { showingSettings = true }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Premium Banner
struct PremiumBanner: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Go Premium")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Access all categories, words, themes, and remove ads!")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(.red)
        }
        .padding(20)
        .background(Color("B8E5E3"))
        .cornerRadius(20)
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your streak")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            HStack(spacing: 20) {
                // Flame icon with number
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("\(streak)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.orange))
                        .offset(x: 10, y: 5)
                }
                
                // Week days
                HStack(spacing: 8) {
                    ForEach(["Th", "Fr", "Sa", "Su", "Mo", "Tu", "We"], id: \.self) { day in
                        VStack(spacing: 4) {
                            Text(day)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Circle()
                                .fill(day == "Th" ? Color.green : Color.gray.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    day == "Th" ?
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                    : nil
                                )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
    }
}

// MARK: - Vocabulary Card
struct VocabularyCard: View {
    let icon: String
    let title: String
    var color: Color = .white
    var isLocked: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.black)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(20)
    }
}

// MARK: - Customize Card
struct CustomizeCard: View {
    let icon: String
    let title: String
    let illustration: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color("4A9B8E"))
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
    }
}

#Preview {
    ProfileView()
}
