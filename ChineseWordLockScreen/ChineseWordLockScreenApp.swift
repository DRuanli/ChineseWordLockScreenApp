//
//  ChineseWordLockScreenApp.swift
//  ChineseWordLockScreen
//
//  Updated for redesigned interface
//

import SwiftUI

@main
struct ChineseWordLockScreenApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
                .preferredColorScheme(.light) // Force light mode for consistent appearance
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                LoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onAppear {
            checkFirstLaunch()
            setupAppearance()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore && !authManager.isAuthenticated {
            showOnboarding = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
