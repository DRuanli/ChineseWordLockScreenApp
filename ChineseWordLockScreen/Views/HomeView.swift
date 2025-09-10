//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Enhanced version following detailed requirements
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var dragAmount = CGSize.zero
    @State private var cardRotation: Double = 0
    @State private var showingExample = false
    @State private var showingDefinition = true
    @State private var flippedCards: Set<String> = []
    @State private var showingFullFlashcard = false
    @State private var showingChallenge = false
    @State private var dailyGoalReached = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "F5F5F8"), Color(hex: "E9F5FF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HomeHeaderSection(
                            todayCount: wordDataManager.todayWordsCount,
                            streak: wordDataManager.streak,
                            level: authManager.currentUser?.preferredHSKLevel ?? 5
                        )
                        
                        // Word of the Day Card
                        WordOfDayCard(
                            word: viewModel.currentWord,
                            showingDefinition: $showingDefinition,
                            showingExample: $showingExample,
                            viewModel: viewModel,
                            dragAmount: $dragAmount,
                            cardRotation: $cardRotation
                        )
                        .padding(.horizontal)
                        
                        // Quick Review Section
                        QuickReviewSection(
                            flippedCards: $flippedCards,
                            showingFullFlashcard: $showingFullFlashcard
                        )
                        
                        // Daily Goal Progress
                        DailyGoalProgress(
                            current: wordDataManager.todayWordsCount,
                            goal: Int(authManager.currentUser?.dailyGoal ?? 10),
                            reached: $dailyGoalReached
                        )
                        
                        // Shortcuts
                        ShortcutsSection(
                            showingFullFlashcard: $showingFullFlashcard
                        )
                        
                        // Mini Stats
                        MiniStatsSection(
                            totalWords: wordDataManager.savedWords.count,
                            streak: wordDataManager.streak,
                            weeklyAccuracy: calculateWeeklyAccuracy()
                        )
                        
                        // Recommendation Strip
                        if !wordDataManager.wordsForReview.isEmpty {
                            RecommendationStrip(
                                reviewCount: wordDataManager.wordsForReview.count
                            )
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                wordDataManager.refreshData()
                checkDailyGoal()
            }
            .sheet(isPresented: $showingFullFlashcard) {
                FlashcardSessionView()
            }
        }
    }
    
    private func checkDailyGoal() {
        if let goal = authManager.currentUser?.dailyGoal {
            dailyGoalReached = wordDataManager.todayWordsCount >= Int(goal)
            if dailyGoalReached && !UserDefaults.standard.bool(forKey: "goal_celebrated_today") {
                celebrateGoal()
            }
        }
    }
    
    private func celebrateGoal() {
        withAnimation(.spring()) {
            dailyGoalReached = true
        }
        UserDefaults.standard.set(true, forKey: "goal_celebrated_today")
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func calculateWeeklyAccuracy() -> Double {
        // Calculate based on correct/incorrect counts
        let correct = wordDataManager.savedWords.reduce(0) { $0 + Int($1.correctCount) }
        let incorrect = wordDataManager.savedWords.reduce(0) { $0 + Int($1.incorrectCount) }
        let total = correct + incorrect
        return total > 0 ? Double(correct) / Double(total) * 100 : 0
    }
}

// MARK: - Header Section
struct HomeHeaderSection: View {
    let todayCount: Int
    let streak: Int
    let level: Int16
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日词汇")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    Label("\(todayCount) 词", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(streak) 天", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                // Level Badge
                Text("HSK\(level)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                
                // Profile Avatar
                NavigationLink(destination: ProfileSettingsView()) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(AuthenticationManager.shared.currentUser?.username?.first?.uppercased() ?? "U")
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Word of Day Card
struct WordOfDayCard: View {
    let word: HSKWord
    @Binding var showingDefinition: Bool
    @Binding var showingExample: Bool
    let viewModel: HomeViewModel
    @Binding var dragAmount: CGSize
    @Binding var cardRotation: Double
    
    @State private var audioPlaying = false
    @State private var seenCount = 1
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("今日词语")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Seen \(seenCount)/\(AuthenticationManager.shared.currentUser?.dailyGoal ?? 10)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("HSK \(word.hskLevel)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colorForLevel(word.hskLevel).opacity(0.2))
                    .foregroundColor(colorForLevel(word.hskLevel))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            
            // Main content
            VStack(spacing: 20) {
                // Chinese character
                Text(word.hanzi)
                    .font(.system(size: 100, weight: .medium))
                    .foregroundColor(.primary)
                    .scaleEffect(showingExample ? 0.8 : 1.0)
                    .onTapGesture(count: 2) {
                        playAudio()
                    }
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showingDefinition.toggle()
                        }
                    }
                
                // Pinyin with tone colors
                HStack(spacing: 4) {
                    ForEach(Array(word.pinyin.enumerated()), id: \.offset) { index, char in
                        Text(String(char))
                            .font(.system(size: 28))
                            .foregroundColor(getToneColor(for: word.pinyin, at: index))
                    }
                }
                
                // Meaning
                if showingDefinition {
                    Text(word.meaning)
                        .font(.title3)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    
                    Text("【\(getWordType(word))】")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Example
                if showingExample, let example = word.example {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    Text(example)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical, 30)
            
            // Bottom actions
            HStack(spacing: 30) {
                // Audio button
                Button(action: playAudio) {
                    Image(systemName: audioPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .scaleEffect(audioPlaying ? 1.2 : 1.0)
                }
                
                // Save button
                Button(action: {
                    viewModel.toggleSave()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(viewModel.isSaved ? .red : .gray)
                        .scaleEffect(viewModel.isSaved ? 1.1 : 1.0)
                }
                .animation(.spring(response: 0.3), value: viewModel.isSaved)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .rotation3DEffect(
            .degrees(cardRotation),
            axis: (x: 0, y: 1, z: 0)
        )
        .offset(dragAmount)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring()) {
                        dragAmount = value.translation
                        cardRotation = Double(value.translation.width / 10)
                    }
                }
                .onEnded { value in
                    if abs(value.translation.width) > 100 {
                        withAnimation(.spring()) {
                            viewModel.getNextWord()
                            showingExample = false
                            seenCount += 1
                        }
                    }
                    withAnimation(.spring()) {
                        dragAmount = .zero
                        cardRotation = 0
                    }
                }
        )
    }
    
    private func playAudio() {
        withAnimation(.easeInOut(duration: 0.2)) {
            audioPlaying = true
        }
        viewModel.speakWord()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                audioPlaying = false
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func getToneColor(for pinyin: String, at index: Int) -> Color {
        // Simplified tone detection
        let toneMarks = ["ā", "á", "ǎ", "à", "ē", "é", "ě", "è", "ī", "í", "ǐ", "ì", "ō", "ó", "ǒ", "ò", "ū", "ú", "ǔ", "ù", "ǖ", "ǘ", "ǚ", "ǜ"]
        let char = String(pinyin[pinyin.index(pinyin.startIndex, offsetBy: index)])
        
        if toneMarks[0..<4].contains(where: { char.contains($0) }) { return .green }
        if toneMarks[4..<8].contains(where: { char.contains($0) }) { return .yellow }
        if toneMarks[8..<12].contains(where: { char.contains($0) }) { return .blue }
        if toneMarks[12..<16].contains(where: { char.contains($0) }) { return .red }
        
        return .secondary
    }
    
    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 3: return .green
        case 4: return .blue
        case 5: return .orange
        case 6: return .red
        default: return .gray
        }
    }
    
    private func getWordType(_ word: HSKWord) -> String {
        // This would be determined by word analysis or database
        return "adj."
    }
}

// MARK: - Quick Review Section
struct QuickReviewSection: View {
    @Binding var flippedCards: Set<String>
    @Binding var showingFullFlashcard: Bool
    @StateObject private var wordDataManager = WordDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ôn nhanh")
                    .font(.headline)
                
                Text("• 2 phút")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Full mode") {
                    showingFullFlashcard = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(wordDataManager.savedWords.prefix(5)), id: \.hanzi) { word in
                        MiniFlashcard(
                            word: word,
                            isFlipped: flippedCards.contains(word.hanzi ?? "")
                        ) {
                            withAnimation(.spring()) {
                                if flippedCards.contains(word.hanzi ?? "") {
                                    flippedCards.remove(word.hanzi ?? "")
                                } else {
                                    flippedCards.insert(word.hanzi ?? "")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MiniFlashcard: View {
    let word: SavedWord
    let isFlipped: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5)
                .frame(width: 100, height: 120)
            
            VStack(spacing: 8) {
                if !isFlipped {
                    Text(word.hanzi ?? "")
                        .font(.title2)
                        .fontWeight(.medium)
                } else {
                    Text(word.pinyin ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(word.meaning ?? "")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(10)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Daily Goal Progress
struct DailyGoalProgress: View {
    let current: Int
    let goal: Int
    @Binding var reached: Bool
    
    var progress: Double {
        min(Double(current) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Hôm nay: \(current)/\(goal) exposures")
                    .font(.subheadline)
                
                Spacer()
                
                if reached {
                    Label("Đạt mục tiêu!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            ProgressView(value: progress)
                .tint(reached ? .green : .blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
        .overlay(
            reached ? ConfettiView() : nil
        )
    }
}

// MARK: - Shortcuts Section
struct ShortcutsSection: View {
    @Binding var showingFullFlashcard: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            ShortcutButton(
                icon: "rectangle.stack.fill",
                label: "Flashcards",
                color: .blue
            ) {
                showingFullFlashcard = true
            }
            
            NavigationLink(destination: LibraryView()) {
                ShortcutButton(
                    icon: "books.vertical.fill",
                    label: "Library",
                    color: .green
                ) { }
            }
            
            NavigationLink(destination: ReviewSRSView()) {
                ShortcutButton(
                    icon: "arrow.clockwise",
                    label: "Review",
                    color: .orange
                ) { }
            }
            
            NavigationLink(destination: StatsView()) {
                ShortcutButton(
                    icon: "chart.bar.fill",
                    label: "Stats",
                    color: .purple
                ) { }
            }
        }
        .padding(.horizontal)
    }
}

struct ShortcutButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
    }
}

// MARK: - Mini Stats
struct MiniStatsSection: View {
    let totalWords: Int
    let streak: Int
    let weeklyAccuracy: Double
    
    var body: some View {
        HStack(spacing: 30) {
            StatItem(value: "\(totalWords)", label: "Tổng từ")
            StatItem(value: "\(streak)", label: "Streak")
            StatItem(value: "\(Int(weeklyAccuracy))%", label: "Accuracy")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recommendation Strip
struct RecommendationStrip: View {
    let reviewCount: Int
    
    var body: some View {
        NavigationLink(destination: ReviewSRSView()) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Gợi ý: ôn \(reviewCount) từ khó")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Bắt đầu")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.yellow.opacity(0.1))
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views
struct ConfettiView: View {
    var body: some View {
        // Simplified confetti animation
        EmptyView()
    }
}

struct FlashcardSessionView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Text("Full Flashcard Session")
                .navigationTitle("Flashcards")
                .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct ReviewSRSView: View {
    var body: some View {
        Text("SRS Review")
            .navigationTitle("Review")
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = scanner.string.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: Double(r) / 0xff,
            green: Double(g) / 0xff,
            blue: Double(b) / 0xff
        )
    }
}
