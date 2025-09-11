//
//  PracticeView.swift
//  ChineseWordLockScreen
//
//  Enhanced practice games and challenges with full database integration
//

import SwiftUI
import CoreData

struct PracticeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var showingPaywall = false
    @State private var selectedGame: GameType?
    @State private var selectedChallenge: ChallengeType?
    @State private var showingGameShuffle = false
    
    enum GameType: String, CaseIterable {
        case guessWord = "Guess the word"
        case fillGap = "Fill in the gap"
        case meaningMatch = "Meaning match"
        case matchSynonyms = "Match synonyms"
        
        var icon: String {
            switch self {
            case .guessWord: return "doc.text.magnifyingglass"
            case .fillGap: return "square.and.pencil"
            case .meaningMatch: return "doc.on.doc"
            case .matchSynonyms: return "arrow.triangle.2.circlepath"
            }
        }
        
        var isLocked: Bool {
            return false // Can be configured based on user's premium status
        }
    }
    
    enum ChallengeType: String, CaseIterable {
        case sprint = "Sprint"
        case perfection = "Perfection"
        case rush = "Rush"
        
        var icon: String {
            switch self {
            case .sprint: return "timer"
            case .perfection: return "heart.fill"
            case .rush: return "bolt.fill"
            }
        }
        
        var colors: [Color] {
            switch self {
            case .sprint: return [.green, .gray, .gray]
            case .perfection: return [.red, .gray, .gray]
            case .rush: return [.green, .red, .gray]
            }
        }
        
        var description: String {
            switch self {
            case .sprint: return "Answer 30 words in 60 seconds"
            case .perfection: return "Get 10 correct in a row"
            case .rush: return "Speed increases with each answer"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // App-consistent background color
                Color(red: 0.96, green: 0.945, blue: 0.91)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Game Shuffle Banner
                        GameShuffleBanner(onStart: {
                            showingGameShuffle = true
                        })
                        .padding(.horizontal)
                        
                        // Challenges Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("THÁCH THỨC")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ChallengeType.allCases, id: \.self) { challenge in
                                        ChallengeCard(
                                            challenge: challenge,
                                            wordsAvailable: !wordDataManager.savedWords.isEmpty
                                        ) {
                                            if wordDataManager.savedWords.isEmpty {
                                                // Show alert to add words first
                                            } else {
                                                selectedChallenge = challenge
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Practice Games Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LUYỆN TẬP")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(GameType.allCases, id: \.self) { game in
                                    GameCard(
                                        game: game,
                                        wordsAvailable: !wordDataManager.savedWords.isEmpty
                                    ) {
                                        if game.isLocked && !authManager.isPremium {
                                            showingPaywall = true
                                        } else if wordDataManager.savedWords.isEmpty {
                                            // Show alert to add words first
                                        } else {
                                            selectedGame = game
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Coming Soon Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SẮP RA MẮT")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ComingSoonCard(title: "Hangman", icon: "figure.stand")
                                ComingSoonCard(title: "Complete word", icon: "rectangle.and.pencil.and.ellipsis")
                                ComingSoonCard(title: "Listen & spell", icon: "ear")
                                ComingSoonCard(title: "Word wheel", icon: "circle.grid.3x3")
                            }
                            .padding(.horizontal)
                        }
                        
                        // Statistics Section
                        if !wordDataManager.savedWords.isEmpty {
                            PracticeStatsCard()
                                .padding(.horizontal)
                        }
                        
                        // Unlock Premium Button
                        if !authManager.isPremium {
                            Button(action: { showingPaywall = true }) {
                                Text("Mở khóa tất cả trò chơi")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.72, green: 0.9, blue: 0.89),
                                                    Color(red: 0.8, green: 0.93, blue: 0.92)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(30)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Luyện tập")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                if !authManager.isPremium {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mở khóa") { showingPaywall = true }
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .fullScreenCover(item: $selectedGame) { game in
            GamePlayView(gameType: game)
        }
        .fullScreenCover(item: $selectedChallenge) { challenge in
            ChallengePlayView(challengeType: challenge)
        }
        .fullScreenCover(isPresented: $showingGameShuffle) {
            GameShuffleView()
        }
    }
}

// MARK: - Game Shuffle Banner
struct GameShuffleBanner: View {
    let onStart: () -> Void
    @StateObject private var wordDataManager = WordDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Thử Game Shuffle")
                        .font(.system(size: 20, weight: .bold))
                    Text("Kết hợp tất cả các trò chơi")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Button(action: onStart) {
                        Text("Bắt đầu")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.72, green: 0.9, blue: 0.89))
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                    .disabled(wordDataManager.savedWords.isEmpty)
                }
                
                Spacer()
                
                Image(systemName: "shuffle")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.72, green: 0.9, blue: 0.89))
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: PracticeView.ChallengeType
    let wordsAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(challenge.colors[index])
                            .frame(width: 60 - CGFloat(index * 5), height: 8)
                            .offset(y: CGFloat(index * 12))
                    }
                    
                    Image(systemName: challenge.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                        .offset(y: -20)
                }
                .frame(height: 80)
                
                VStack(spacing: 4) {
                    Text(challenge.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(challenge.description)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(width: 140, height: 160)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .opacity(wordsAvailable ? 1 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game Card
struct GameCard: View {
    let game: PracticeView.GameType
    let wordsAvailable: Bool
    let onTap: () -> Void
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.96, blue: 0.95).opacity(0.5))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: game.icon)
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.29, green: 0.61, blue: 0.56))
                }
                
                Text(game.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                if game.isLocked && !authManager.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .opacity(wordsAvailable ? 1 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Coming Soon Card
struct ComingSoonCard: View {
    let title: String
    let icon: String
    @State private var voteCount = 0
    
    var body: some View {
        Button(action: {
            voteCount += 1
            HapticFeedback.light.trigger()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                if voteCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 10))
                        Text("\(voteCount)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Practice Stats Card
struct PracticeStatsCard: View {
    @StateObject private var wordDataManager = WordDataManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Thống kê luyện tập")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Từ đã lưu",
                    value: "\(wordDataManager.savedWords.count)",
                    icon: "bookmark.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "Cần ôn tập",
                    value: "\(wordDataManager.wordsForReview.count)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatItem(
                    title: "Streak",
                    value: "\(wordDataManager.streak)",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Game Play Views (Placeholder implementations)
struct GamePlayView: View {
    let gameType: PracticeView.GameType
    @Environment(\.dismiss) var dismiss
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var currentWordIndex = 0
    @State private var score = 0
    @State private var showingResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.945, blue: 0.91)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Progress bar
                    ProgressView(value: Double(currentWordIndex), total: Double(min(10, wordDataManager.savedWords.count)))
                        .padding(.horizontal)
                    
                    // Score
                    HStack {
                        Label("\(score) điểm", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(currentWordIndex + 1)/\(min(10, wordDataManager.savedWords.count))")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Game content based on type
                    Group {
                        switch gameType {
                        case .guessWord:
                            GuessWordGameView(
                                word: wordDataManager.savedWords[safe: currentWordIndex],
                                onAnswer: handleAnswer
                            )
                        case .fillGap:
                            FillGapGameView(
                                word: wordDataManager.savedWords[safe: currentWordIndex],
                                onAnswer: handleAnswer
                            )
                        case .meaningMatch:
                            MeaningMatchGameView(
                                word: wordDataManager.savedWords[safe: currentWordIndex],
                                onAnswer: handleAnswer
                            )
                        case .matchSynonyms:
                            MatchSynonymsGameView(
                                word: wordDataManager.savedWords[safe: currentWordIndex],
                                onAnswer: handleAnswer
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle(gameType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Thoát") { dismiss() }
                }
            }
        }
        .interactiveDismissDisabled()
        .alert("Kết quả", isPresented: $showingResult) {
            Button("Tiếp tục") {
                if currentWordIndex < min(9, wordDataManager.savedWords.count - 1) {
                    currentWordIndex += 1
                } else {
                    dismiss()
                }
            }
        } message: {
            Text("Bạn đạt \(score) điểm!")
        }
    }
    
    private func handleAnswer(_ isCorrect: Bool) {
        if isCorrect {
            score += 10
            HapticFeedback.success.trigger()
        } else {
            HapticFeedback.error.trigger()
        }
        
        if currentWordIndex >= min(9, wordDataManager.savedWords.count - 1) {
            showingResult = true
        } else {
            currentWordIndex += 1
        }
    }
}

struct ChallengePlayView: View {
    let challengeType: PracticeView.ChallengeType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.945, blue: 0.91)
                    .ignoresSafeArea()
                
                VStack {
                    Text("\(challengeType.rawValue) Challenge")
                        .font(.largeTitle.bold())
                    
                    Text(challengeType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Coming Soon!")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(challengeType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

struct GameShuffleView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.945, blue: 0.91)
                    .ignoresSafeArea()
                
                VStack {
                    Text("Game Shuffle")
                        .font(.largeTitle.bold())
                    
                    Text("Mix of all games")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Coming Soon!")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Game Shuffle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Mini Game Views
struct GuessWordGameView: View {
    let word: SavedWord?
    let onAnswer: (Bool) -> Void
    @State private var options: [String] = []
    @State private var selectedAnswer: String?
    
    var body: some View {
        if let word = word {
            VStack(spacing: 30) {
                Text(word.hanzi ?? "")
                    .font(.system(size: 60, weight: .bold))
                
                Text("Chọn nghĩa đúng:")
                    .font(.headline)
                
                VStack(spacing: 15) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selectedAnswer = option
                            onAnswer(option == word.meaning)
                        }) {
                            Text(option)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    selectedAnswer == option ?
                                    (option == word.meaning ? Color.green : Color.red) :
                                    Color.white
                                )
                                .cornerRadius(12)
                        }
                        .disabled(selectedAnswer != nil)
                    }
                }
            }
            .padding()
            .onAppear {
                generateOptions()
            }
        }
    }
    
    private func generateOptions() {
        guard let word = word else { return }
        var opts = [word.meaning ?? ""]
        // Add random wrong options
        opts.append("Wrong answer 1")
        opts.append("Wrong answer 2")
        opts.append("Wrong answer 3")
        options = opts.shuffled()
    }
}

struct FillGapGameView: View {
    let word: SavedWord?
    let onAnswer: (Bool) -> Void
    @State private var userInput = ""
    
    var body: some View {
        if let word = word {
            VStack(spacing: 30) {
                Text("Điền từ còn thiếu:")
                    .font(.headline)
                
                Text("___ (\(word.pinyin ?? ""))")
                    .font(.title)
                
                Text("Nghĩa: \(word.meaning ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Nhập chữ Hán", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    onAnswer(userInput == word.hanzi)
                }) {
                    Text("Kiểm tra")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

struct MeaningMatchGameView: View {
    let word: SavedWord?
    let onAnswer: (Bool) -> Void
    
    var body: some View {
        if let word = word {
            GuessWordGameView(word: word, onAnswer: onAnswer)
        }
    }
}

struct MatchSynonymsGameView: View {
    let word: SavedWord?
    let onAnswer: (Bool) -> Void
    
    var body: some View {
        if let word = word {
            GuessWordGameView(word: word, onAnswer: onAnswer)
        }
    }
}

// MARK: - Extensions
extension PracticeView.GameType: Identifiable {
    var id: String { self.rawValue }
}

extension PracticeView.ChallengeType: Identifiable {
    var id: String { self.rawValue }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Haptic Feedback Helper
enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    
    func trigger() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    PracticeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
