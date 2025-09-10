//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var dragAmount = CGSize.zero
    @State private var showingExample = false
    @State private var cardRotation: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                AnimatedBackground()
                
                VStack(spacing: 0) {
                    // Header
                    HomeHeaderView(
                        todayCount: wordDataManager.todayWordsCount,
                        streak: wordDataManager.streak
                    )
                    
                    // Main Card
                    GeometryReader { geometry in
                        ZStack {
                            // Shadow Card
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.black.opacity(0.1))
                                .offset(y: 10)
                                .blur(radius: 10)
                            
                            // Main Word Card
                            WordCard(
                                word: viewModel.currentWord,
                                showingDefinition: viewModel.showingDefinition,
                                showingExample: showingExample,
                                cardRotation: cardRotation,
                                dragAmount: dragAmount
                            )
                            .rotation3DEffect(
                                .degrees(cardRotation),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .offset(dragAmount)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            dragAmount = value.translation
                                            cardRotation = Double(value.translation.width / 10)
                                        }
                                    }
                                    .onEnded { value in
                                        if abs(value.translation.width) > 100 {
                                            withAnimation(.spring()) {
                                                viewModel.getNextWord()
                                                showingExample = false
                                            }
                                        }
                                        withAnimation(.spring()) {
                                            dragAmount = .zero
                                            cardRotation = 0
                                        }
                                    }
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    
                    // Action Buttons
                    ActionButtonsView(
                        viewModel: viewModel,
                        showingExample: $showingExample
                    )
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            wordDataManager.refreshData()
        }
    }
}

struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.98),
                    Color(red: 0.9, green: 0.95, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Floating circles
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.teal.opacity(0.1),
                                Color.yellow.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 100...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 10)
                    .opacity(animate ? 0.6 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

struct HomeHeaderView: View {
    let todayCount: Int
    let streak: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日词汇")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 15) {
                    Label("\(todayCount) 词", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(streak) 天", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Profile Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.teal, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(AuthenticationManager.shared.currentUser?.username?.first?.uppercased() ?? "U")
                        .font(.headline)
                        .foregroundColor(.white)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
}

struct WordCard: View {
    let word: HSKWord
    let showingDefinition: Bool
    let showingExample: Bool
    let cardRotation: Double
    let dragAmount: CGSize
    
    var body: some View {
        VStack(spacing: 25) {
            // HSK Level Badge
            HStack {
                Spacer()
                Text("HSK \(word.hskLevel)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(colorForHSKLevel(word.hskLevel).opacity(0.2))
                    )
                    .foregroundColor(colorForHSKLevel(word.hskLevel))
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Chinese Character
            Text(word.hanzi)
                .font(.system(size: 100, weight: .medium))
                .foregroundColor(.primary)
                .scaleEffect(showingExample ? 0.8 : 1.0)
                .animation(.spring(), value: showingExample)
            
            // Pinyin
            Text(word.pinyin)
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            // Meaning
            if showingDefinition {
                Text(word.meaning)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            // Example
            if showingExample, let example = word.example {
                VStack(spacing: 10) {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    Text(example)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 20,
                    x: 0,
                    y: 5
                )
        )
    }
    
    private func colorForHSKLevel(_ level: Int) -> Color {
        switch level {
        case 3: return .green
        case 4: return .blue
        case 5: return .orange
        case 6: return .red
        default: return .gray
        }
    }
}

struct ActionButtonsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var showingExample: Bool
    
    var body: some View {
        HStack(spacing: 30) {
            // Toggle Definition
            ActionButton(
                icon: viewModel.showingDefinition ? "eye.fill" : "eye.slash.fill",
                color: .gray,
                action: { withAnimation { viewModel.toggleDefinition() } }
            )
            
            // Example
            ActionButton(
                icon: "text.quote",
                color: .purple,
                isActive: showingExample,
                action: { withAnimation { showingExample.toggle() } }
            )
            
            // Speak
            ActionButton(
                icon: "speaker.wave.2.fill",
                color: .blue,
                action: { viewModel.speakWord() }
            )
            
            // Save/Unsave
            ActionButton(
                icon: viewModel.isSaved ? "bookmark.fill" : "bookmark",
                color: viewModel.isSaved ? .yellow : .gray,
                action: { withAnimation { viewModel.toggleSave() } }
            )
            
            // Next Word
            ActionButton(
                icon: "arrow.right.circle.fill",
                color: .green,
                action: {
                    withAnimation(.spring()) {
                        viewModel.getNextWord()
                        showingExample = false
                    }
                }
            )
        }
        .padding(.horizontal, 30)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isActive ? .white : color)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isActive ? color : Color.gray.opacity(0.1))
                )
                .scaleEffect(isActive ? 1.1 : 1.0)
        }
    }
}

#Preview {
    HomeView()
}
