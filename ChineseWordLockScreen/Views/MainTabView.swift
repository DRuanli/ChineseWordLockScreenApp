//
//  MainTabView.swift
//  ChineseWordLockScreen
//
//  Main navigation controller with bottom tab bar
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedTab = 0
    @State private var showingPractice = false
    @State private var showingProfile = false
    
    var body: some View {
        ZStack {
            // Main content based on selected tab
            switch selectedTab {
            case 0:
                LibraryView()
            case 1:
                HomeView()
            default:
                HomeView()
            }
            
            // Custom Tab Bar
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    // Library Tab
                    TabButton(
                        icon: "square.grid.2x2",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                        showingPractice = false
                        showingProfile = false
                    }
                    
                    Spacer()
                    
                    // Practice Tab (Center)
                    TabButton(
                        icon: "graduationcap.fill",
                        title: "Practice",
                        isSelected: showingPractice,
                        isPrimary: true
                    ) {
                        showingPractice = true
                    }
                    
                    Spacer()
                    
                    // Profile Tab
                    TabButton(
                        icon: "person",
                        isSelected: showingProfile
                    ) {
                        showingProfile = true
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            }
        }
        .onAppear {
            notificationManager.requestAuthorization()
        }
        .fullScreenCover(isPresented: $showingPractice) {
            PracticeView()
        }
        .fullScreenCover(isPresented: $showingProfile) {
            ProfileView()
        }
    }
}

struct TabButton: View {
    let icon: String
    var title: String? = nil
    let isSelected: Bool
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isPrimary {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                    if let title = title {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color("B8E5E3"))
                .cornerRadius(25)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : .gray)
            }
        }
    }
}

#Preview {
    MainTabView()
}
