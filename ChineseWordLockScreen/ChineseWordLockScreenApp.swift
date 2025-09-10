//
//  ChineseWordLockScreenApp.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
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
}
