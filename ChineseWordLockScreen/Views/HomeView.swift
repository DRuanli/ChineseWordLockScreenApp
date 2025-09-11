//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Redesigned minimalist vocabulary card with swipe navigation
//

import SwiftUI

struct HomeView: View {
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var learningMode: LearningMode = .newWord
    @State private var currentWordData: (word: HSKWord, state: WordLearningState, quizType: QuizType?)?
    @State private var showingQuiz = false
    @State private var showingWordDetail = false
    @State private var quizStartTime = Date()
    @State private var showingSettings = false
    @State private var dailyProgress: Float = 0.0
    
    enum LearningMode: String, CaseIterable {
        case newWord = "Học từ mới"
        case review = "Ôn tập"
        
        var icon: String {
            switch self {
            case .newWord: return "plus.circle.fill"
            case .review: return "arrow.clockwise.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .newWord: return .blue
            case .review: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with user info
                        headerSection
                        
                        // Daily Progress
                        dailyProgressSection
                        
                        // Mode Selector
                        modeSelectorSection
                        
                        // Current Word Card
                        if let wordData = currentWordData {
                            WordStudyCard(
                                wordData: wordData,
                                onStartQuiz: { showingQuiz = true },
                                onToggleFavorite: toggleFavorite,
                                onShowDetail: { showingWordDetail = true },
                                onNext: loadNextWord
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        
                        // Queue Status
                        queueStatusSection
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadNextWord()
                updateDailyProgress()
            }
            .sheet(isPresented: $showingQuiz) {
                if let wordData = currentWordData {
                    QuizView(
                        wordData: wordData,
                        onComplete: handleQuizCompletion
                    )
                }
            }
            .sheet(isPresented: $showingWordDetail) {
                if let wordData = currentWordData {
                    WordDetailView(word: wordData.word)
                }
            }
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Xin chào, \(authManager.currentUser?.username ?? "Học viên")!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Đã học \(wordDataManager.wordsLearnedToday)/\(wordDataManager.dailyNewWordLimit) từ hôm nay")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var dailyProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tiến độ hôm nay")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(dailyProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: dailyProgress)
                .tint(.blue)
                .scaleEffect(y: 2)
            
            HStack(spacing: 20) {
                StatLabel(
                    icon: "star.fill",
                    value: "\(wordDataManager.introducedWordsQueue.count)",
                    label: "Đã giới thiệu",
                    color: .orange
                )
                
                StatLabel(
                    icon: "brain",
                    value: "\(wordDataManager.learningWordsQueue.count)",
                    label: "Đang học",
                    color: .yellow
                )
                
                StatLabel(
                    icon: "checkmark.circle.fill",
                    value: "\(wordDataManager.reviewWordsQueue.count)",
                    label: "Cần ôn tập",
                    color: .green
                )
            }
            .font(.caption)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var modeSelectorSection: some View {
        HStack(spacing: 12) {
            ForEach(LearningMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring()) {
                        learningMode = mode
                        loadNextWord()
                    }
                }) {
                    HStack {
                        Image(systemName: mode.icon)
                        Text(mode.rawValue)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(learningMode == mode ? .white : mode.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        learningMode == mode ?
                        mode.color : mode.color.opacity(0.1)
                    )
                    .cornerRadius(20)
                }
            }
        }
    }
    
    private var queueStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trạng thái hàng đợi")
                .font(.headline)
            
            VStack(spacing: 8) {
                QueueStatusRow(
                    state: .new,
                    count: wordDataManager.newWordsQueue.count,
                    label: "Từ mới chưa học"
                )
                
                QueueStatusRow(
                    state: .learning,
                    count: wordDataManager.learningWordsQueue.filter {
                        ($0.nextReviewDate ?? Date()) <= Date()
                    }.count,
                    label: "Cần ôn tập ngay"
                )
                
                QueueStatusRow(
                    state: .review,
                    count: wordDataManager.reviewWordsQueue.filter {
                        ($0.nextReviewDate ?? Date()) <= Date()
                    }.count,
                    label: "Đến hạn ôn tập"
                )
                
                QueueStatusRow(
                    state: .mastered,
                    count: wordDataManager.masteredWordsQueue.count,
                    label: "Đã thành thạo"
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: LibraryView()) {
                QuickActionButton(
                    icon: "books.vertical.fill",
                    title: "Thư viện",
                    color: .purple
                )
            }
            
            NavigationLink(destination: StudyDashboardView()) {
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Thống kê",
                    color: .green
                )
            }
            
            NavigationLink(destination: QuickStudyView()) {
                QuickActionButton(
                    icon: "timer",
                    title: "Luyện tập",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Methods
    private func loadNextWord() {
        currentWordData = wordDataManager.getNextWord(isNewWordMode: learningMode == .newWord)
        quizStartTime = Date()
    }
    
    private func toggleFavorite() {
        guard let wordData = currentWordData else { return }
        
        // Find saved word
        if let savedWord = wordDataManager.savedWords.first(where: {
            $0.hanzi == wordData.word.hanzi
        }) {
            wordDataManager.toggleFavorite(for: savedWord)
        }
    }
    
    private func handleQuizCompletion(isCorrect: Bool) {
        guard let wordData = currentWordData else { return }
        
        let responseTime = Date().timeIntervalSince(quizStartTime)
        
        // If it's a new word, introduce it first
        if wordData.state == .new {
            wordDataManager.introduceWord(wordData.word)
        } else {
            // Update existing word
            if let savedWord = wordDataManager.savedWords.first(where: {
                $0.hanzi == wordData.word.hanzi
            }) {
                wordDataManager.updateWordAfterQuiz(savedWord, isCorrect: isCorrect, responseTime: responseTime)
            }
        }
        
        // Load next word
        loadNextWord()
        updateDailyProgress()
    }
    
    private func updateDailyProgress() {
        let total = wordDataManager.dailyNewWordLimit
        let completed = wordDataManager.wordsLearnedToday
        dailyProgress = min(Float(completed) / Float(total), 1.0)
    }
}

// MARK: - Supporting Views
struct WordStudyCard: View {
    let wordData: (word: HSKWord, state: WordLearningState, quizType: QuizType?)
    let onStartQuiz: () -> Void
    let onToggleFavorite: () -> Void
    let onShowDetail: () -> Void
    let onNext: () -> Void
    
    @State private var isFlipped = false
    @State private var showPinyin = false
    
    var body: some View {
        VStack(spacing: 16) {
            // State indicator
            HStack {
                Label(wordData.state.displayName, systemImage: stateIcon)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(wordData.state.color)
                    .cornerRadius(15)
                
                Spacer()
                
                Text("HSK \(wordData.word.hskLevel)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            
            // Main card
            VStack(spacing: 20) {
                // Hanzi
                Text(wordData.word.hanzi)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.primary)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showPinyin.toggle()
                        }
                    }
                
                // Pinyin (toggle visibility)
                if showPinyin {
                    Text(wordData.word.pinyin)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Meaning
                if isFlipped || wordData.state == .new {
                    VStack(spacing: 8) {
                        Text(wordData.word.meaning)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                        
                        if let example = wordData.word.example {
                            Text(example)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Quiz type indicator
                if let quizType = wordData.quizType {
                    Label(quizTypeDescription(quizType), systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 5)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .onTapGesture {
                if wordData.state != .new {
                    withAnimation(.spring()) {
                        isFlipped.toggle()
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: onToggleFavorite) {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(.pink)
                        .frame(width: 50, height: 50)
                        .background(Color.pink.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: onShowDetail) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                
                if wordData.state == .new {
                    Button(action: {
                        // Introduce word
                        WordDataManager.shared.introduceWord(wordData.word)
                        onNext()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Thêm vào học")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                } else {
                    Button(action: onStartQuiz) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Bắt đầu Quiz")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                }
                
                Button(action: onNext) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 50, height: 50)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var stateIcon: String {
        switch wordData.state {
        case .new: return "sparkles"
        case .introduced: return "eye"
        case .learning: return "brain"
        case .review: return "arrow.clockwise"
        case .mastered: return "crown"
        }
    }
    
    private func quizTypeDescription(_ type: QuizType) -> String {
        switch type {
        case .recognition: return "Nhận diện nghĩa"
        case .recall: return "Nhớ lại chữ Hán"
        case .audio: return "Nghe và chọn"
        case .context: return "Điền vào câu"
        }
    }
}

struct StatLabel: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .fontWeight(.bold)
                Text(label)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct QueueStatusRow: View {
    let state: WordLearningState
    let count: Int
    let label: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(count > 0 ? state.color : .secondary)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
