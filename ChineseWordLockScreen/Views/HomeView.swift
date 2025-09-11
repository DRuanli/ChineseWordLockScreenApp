//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Tinder-style swipe interface with floating menus
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    // Card stack management
    @State private var cardStack: [HSKWord] = []
    @State private var currentIndex = 0
    
    // Menu states
    @State private var showLeftMenu = false
    @State private var showRightMenu = false
    @State private var showCenterMenu = false
    
    // Navigation states
    @State private var showingStats = false
    @State private var showingLibrary = false
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingStudyMode = false
    @State private var showingGameMode = false
    @State private var showingPractice = false
    @State private var showingTest = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                TopBar(
                    current: wordDataManager.todayWordsCount,
                    goal: Int(authManager.currentUser?.dailyGoal ?? 10),
                    streak: wordDataManager.streak
                )
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Swipeable Card Stack
                ZStack {
                    ForEach(cardStack.indices.reversed(), id: \.self) { index in
                        WordCard(
                            word: cardStack[index],
                            onRemove: { swipeDirection in
                                removeCard(at: index, direction: swipeDirection)
                            }
                        )
                        .opacity(index == currentIndex ? 1 : 0.5)
                        .scaleEffect(index == currentIndex ? 1 : 0.95)
                        .offset(y: CGFloat(index - currentIndex) * 10)
                        .allowsHitTesting(index == currentIndex)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
                
                Spacer()
            }
            
            // Floating Menu Buttons
            FloatingMenuButtons(
                showLeftMenu: $showLeftMenu,
                showRightMenu: $showRightMenu,
                showCenterMenu: $showCenterMenu,
                onStatsTap: { showingStats = true },
                onLibraryTap: { showingLibrary = true },
                onProfileTap: { showingProfile = true },
                onSettingsTap: { showingSettings = true },
                onStudyTap: { showingStudyMode = true },
                onGameTap: { showingGameMode = true },
                onPracticeTap: { showingPractice = true },
                onTestTap: { showingTest = true }
            )
        }
        .onAppear {
            loadCardStack()
        }
        .fullScreenCover(isPresented: $showingStats) {
            NavigationView { StatsView() }
        }
        .fullScreenCover(isPresented: $showingLibrary) {
            NavigationView { LibraryView() }
        }
        .fullScreenCover(isPresented: $showingProfile) {
            NavigationView { ProfileSettingsView() }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            NavigationView { ProfileSettingsView() }
        }
        .fullScreenCover(isPresented: $showingStudyMode) {
            StudyDashboardView()
        }
        .fullScreenCover(isPresented: $showingGameMode) {
            QuickStudyView()
        }
        .fullScreenCover(isPresented: $showingPractice) {
            FlashcardSessionView()
        }
        .fullScreenCover(isPresented: $showingTest) {
            QuickStudyView()
        }
    }
    
    private func loadCardStack() {
        let words = HSKDatabaseSeeder.shared.getSampleWords()
        cardStack = Array(words.shuffled().prefix(10))
    }
    
    private func removeCard(at index: Int, direction: SwipeDirection) {
        guard index == currentIndex else { return }
        
        withAnimation(.spring()) {
            if direction == .right {
                // Save word
                wordDataManager.saveWord(cardStack[index])
            }
            
            currentIndex += 1
            
            // Load more cards if running low
            if currentIndex >= cardStack.count - 3 {
                loadMoreCards()
            }
        }
    }
    
    private func loadMoreCards() {
        let words = HSKDatabaseSeeder.shared.getSampleWords()
        let newWords = Array(words.shuffled().prefix(5))
        cardStack.append(contentsOf: newWords)
    }
}

// MARK: - Top Bar
struct TopBar: View {
    let current: Int
    let goal: Int
    let streak: Int
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        let currentDouble = Double(current)
        let goalDouble = Double(goal)
        return min(currentDouble / goalDouble, 1.0)
    }
    
    var body: some View {
        HStack {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text("\(streak)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Progress
            VStack(spacing: 4) {
                Text("\(current)/\(goal)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 100, height: 4)
            }
            
            Spacer()
            
            // HSK Level
            Text("HSK 5")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

// MARK: - Word Card
enum SwipeDirection {
    case left, right
}

struct WordCard: View {
    let word: HSKWord
    let onRemove: (SwipeDirection) -> Void
    
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var showingBack = false
    @State private var audioPlaying = false
    
    private let synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(getBorderColor(), lineWidth: 3)
                        .opacity(abs(offset.width) / 100.0)
                )
            
            // Card Content
            VStack(spacing: 20) {
                // Flip indicator
                HStack {
                    Spacer()
                    Button(action: { withAnimation { showingBack.toggle() } }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                if !showingBack {
                    // Front side
                    VStack(spacing: 25) {
                        Text(word.hanzi)
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.black)
                        
                        HStack(spacing: 12) {
                            Text(word.pinyin)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Button(action: playAudio) {
                                Image(systemName: audioPlaying ? "speaker.wave.3.fill" : "speaker.wave.2")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                    .scaleEffect(audioPlaying ? 1.2 : 1.0)
                            }
                        }
                        
                        Text(getVietnameseMeaning(word.meaning))
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                } else {
                    // Back side
                    VStack(spacing: 20) {
                        Text("例句 Example")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let example = word.example {
                            Text(example)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("HSK")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(word.hskLevel)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 60)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
                
                // Swipe hints
                HStack(spacing: 40) {
                    SwipeHint(icon: "xmark", color: .red, text: "跳过")
                        .opacity(offset.width < -50 ? 1 : 0.3)
                    
                    SwipeHint(icon: "heart.fill", color: .green, text: "保存")
                        .opacity(offset.width > 50 ? 1 : 0.3)
                }
                .padding(.bottom, 30)
            }
            .rotation3DEffect(
                .degrees(showingBack ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .frame(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.height * 0.6)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    if abs(gesture.translation.width) > 100 {
                        let direction: SwipeDirection = gesture.translation.width > 0 ? .right : .left
                        withAnimation(.spring()) {
                            offset = CGSize(
                                width: gesture.translation.width > 0 ? 500 : -500,
                                height: gesture.translation.height
                            )
                        }
                        onRemove(direction)
                    } else {
                        withAnimation(.spring()) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
    }
    
    private func getBorderColor() -> Color {
        if offset.width > 0 {
            return .green
        } else if offset.width < 0 {
            return .red
        }
        return .clear
    }
    
    private func playAudio() {
        withAnimation(.easeInOut(duration: 0.2)) {
            audioPlaying = true
        }
        
        let utterance = AVSpeechUtterance(string: word.hanzi)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            audioPlaying = false
        }
    }
    
    private func getVietnameseMeaning(_ english: String) -> String {
        let translations: [String: String] = [
            "wide": "rộng", "method": "phương pháp", "help": "giúp đỡ",
            "competition": "cuộc thi", "express": "biểu đạt", "change": "thay đổi",
            "participate": "tham gia", "be late": "trễ", "plan": "kế hoạch",
            "worry": "lo lắng", "learn": "học", "study": "học tập"
        ]
        
        for (eng, viet) in translations {
            if english.lowercased().contains(eng) {
                return viet
            }
        }
        return english
    }
}

struct SwipeHint: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Floating Menu Buttons
struct FloatingMenuButtons: View {
    @Binding var showLeftMenu: Bool
    @Binding var showRightMenu: Bool
    @Binding var showCenterMenu: Bool
    
    let onStatsTap: () -> Void
    let onLibraryTap: () -> Void
    let onProfileTap: () -> Void
    let onSettingsTap: () -> Void
    let onStudyTap: () -> Void
    let onGameTap: () -> Void
    let onPracticeTap: () -> Void
    let onTestTap: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(alignment: .bottom) {
                // Left Menu - Stats & Library
                VStack(spacing: 12) {
                    if showLeftMenu {
                        MenuButton(icon: "chart.bar.fill", color: .purple, action: {
                            showLeftMenu = false
                            onStatsTap()
                        })
                        .transition(.scale.combined(with: .opacity))
                        
                        MenuButton(icon: "books.vertical.fill", color: .orange, action: {
                            showLeftMenu = false
                            onLibraryTap()
                        })
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    FloatingButton(
                        icon: "chart.pie.fill",
                        color: .blue,
                        isOpen: showLeftMenu
                    ) {
                        withAnimation(.spring()) {
                            showLeftMenu.toggle()
                            showRightMenu = false
                            showCenterMenu = false
                        }
                    }
                }
                
                Spacer()
                
                // Center Menu - Study Modes
                VStack(spacing: 12) {
                    if showCenterMenu {
                        HStack(spacing: 12) {
                            MenuButton(icon: "book.fill", color: .green, action: {
                                showCenterMenu = false
                                onStudyTap()
                            })
                            .transition(.scale.combined(with: .opacity))
                            
                            MenuButton(icon: "gamecontroller.fill", color: .orange, action: {
                                showCenterMenu = false
                                onGameTap()
                            })
                            .transition(.scale.combined(with: .opacity))
                            
                            MenuButton(icon: "rectangle.stack.fill", color: .purple, action: {
                                showCenterMenu = false
                                onPracticeTap()
                            })
                            .transition(.scale.combined(with: .opacity))
                            
                            MenuButton(icon: "checkmark.circle.fill", color: .red, action: {
                                showCenterMenu = false
                                onTestTap()
                            })
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    FloatingButton(
                        icon: "play.fill",
                        color: .green,
                        isOpen: showCenterMenu,
                        size: 64
                    ) {
                        withAnimation(.spring()) {
                            showCenterMenu.toggle()
                            showLeftMenu = false
                            showRightMenu = false
                        }
                    }
                }
                
                Spacer()
                
                // Right Menu - Profile & Settings
                VStack(spacing: 12) {
                    if showRightMenu {
                        MenuButton(icon: "person.fill", color: .indigo, action: {
                            showRightMenu = false
                            onProfileTap()
                        })
                        .transition(.scale.combined(with: .opacity))
                        
                        MenuButton(icon: "gearshape.fill", color: .gray, action: {
                            showRightMenu = false
                            onSettingsTap()
                        })
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    FloatingButton(
                        icon: "person.circle.fill",
                        color: .indigo,
                        isOpen: showRightMenu
                    ) {
                        withAnimation(.spring()) {
                            showRightMenu.toggle()
                            showLeftMenu = false
                            showCenterMenu = false
                        }
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

struct FloatingButton: View {
    let icon: String
    let color: Color
    let isOpen: Bool
    var size: CGFloat = 56
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isOpen ? 45 : 0))
            }
        }
        .scaleEffect(isOpen ? 1.1 : 1)
    }
}

struct MenuButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 48, height: 48)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    HomeView()
}
