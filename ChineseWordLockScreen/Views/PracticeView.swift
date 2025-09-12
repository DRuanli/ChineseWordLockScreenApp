//
//  PracticeView.swift
//  ChineseWordLockScreen
//
//  Practice games and challenges screen
//

import SwiftUI

struct PracticeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("F5F1E8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Game Shuffle Banner
                        GameShuffleBanner()
                            .padding(.horizontal)
                        
                        // Challenges Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CHALLENGES")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ChallengeCard(
                                        title: "Sprint",
                                        icon: "timer",
                                        colors: [.green, .gray, .gray]
                                    )
                                    ChallengeCard(
                                        title: "Perfection",
                                        icon: "heart.fill",
                                        colors: [.red, .gray, .gray]
                                    )
                                    ChallengeCard(
                                        title: "Rush",
                                        icon: "bolt.fill",
                                        colors: [.green, .red, .gray]
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Practice Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PRACTICE")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                GameCard(
                                    title: "Guess the word",
                                    icon: "doc.text.magnifyingglass",
                                    isLocked: false
                                )
                                GameCard(
                                    title: "Fill in the gap",
                                    icon: "square.and.pencil",
                                    isLocked: false
                                )
                                GameCard(
                                    title: "Meaning match",
                                    icon: "doc.on.doc",
                                    isLocked: false
                                )
                                GameCard(
                                    title: "Match synonyms",
                                    icon: "arrow.triangle.2.circlepath",
                                    isLocked: false
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Coming Soon Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("COMING SOON (TAP TO VOTE!)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                GameCard(
                                    title: "Hangman",
                                    icon: "figure.stand",
                                    isComingSoon: true
                                )
                                GameCard(
                                    title: "Complete word",
                                    icon: "rectangle.and.pencil.and.ellipsis",
                                    isComingSoon: true
                                )
                                GameCard(
                                    title: "Listen and spell",
                                    icon: "ear",
                                    isComingSoon: true
                                )
                                GameCard(
                                    title: "Word wheel",
                                    icon: "circle.grid.3x3",
                                    isComingSoon: true
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Unlock Button
                        Button(action: { showingPaywall = true }) {
                            Text("Unlock all games")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color("B8E5E3"))
                                .cornerRadius(30)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Unlock all") { showingPaywall = true }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Game Shuffle Banner
struct GameShuffleBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try Game shuffle")
                        .font(.system(size: 20, weight: .bold))
                    Text("A mix of all games")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Button(action: {}) {
                        Text("Start")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color("B8E5E3"))
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                // Decorative shapes
                Image(systemName: "shuffle")
                    .font(.system(size: 60))
                    .foregroundColor(Color("B8E5E3"))
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(20)
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let title: String
    let icon: String
    let colors: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colors[index])
                        .frame(width: 60 - CGFloat(index * 5), height: 8)
                        .offset(y: CGFloat(index * 12))
                }
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .offset(y: -20)
            }
            .frame(height: 80)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 140, height: 140)
        .background(Color.white)
        .cornerRadius(20)
    }
}

// MARK: - Game Card
struct GameCard: View {
    let title: String
    let icon: String
    var isLocked: Bool = false
    var isComingSoon: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("E5F5F3").opacity(0.5))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isComingSoon ? .gray : Color("4A9B8E"))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            isComingSoon ?
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            : nil
        )
    }
}

#Preview {
    PracticeView()
}
