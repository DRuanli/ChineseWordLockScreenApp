//
//  StudyDashboardView.swift
//  ChineseWordLockScreen
//
//  Enhanced study dashboard with proper database integration and UI alignment
//

import SwiftUI
import CoreData
import Charts

struct StudyDashboardView: View {
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    // Study modes
    @State private var showingFlashcards = false
    @State private var showingQuiz = false
    @State private var showingReview = false
    @State private var showingWordDetail = false
    @State private var selectedWord: SavedWord?
    
    // UI states
    @State private var selectedTab = 0
    @State private var refreshing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // App-consistent background
                Color(red: 0.95, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Study Modes Section
                        StudyModesSection(
                            showingFlashcards: $showingFlashcards,
                            showingQuiz: $showingQuiz,
                            showingReview: $showingReview
                        )
                        .padding(.horizontal)
                        
                        // Review Schedule
                        if !wordDataManager.wordsForReview.isEmpty {
                            ReviewScheduleSection(
                                words: wordDataManager.wordsForReview,
                                onSelectWord: { word in
                                    selectedWord = word
                                    showingWordDetail = true
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        
                        // Recent Activity
                        RecentActivitySection(
                            words: Array(wordDataManager.savedWords.prefix(10)),
                            onSelectWord: { word in
                                selectedWord = word
                                showingWordDetail = true
                            }
                        )
                        .padding(.horizontal)
                        
                        // Study Tips
                        StudyTipsCard()
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationTitle("Bảng học tập")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: StatsView()) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFlashcards) {
            FlashcardSessionView()
        }
        .sheet(isPresented: $showingQuiz) {
            QuizSessionView()
        }
        .sheet(isPresented: $showingReview) {
            SRSReviewView()
        }
        .sheet(item: $selectedWord) { word in
            WordDetailView(word: word)
        }
        .onAppear {
            wordDataManager.refreshData()
        }
    }
    
    @MainActor
    private func refreshData() async {
        refreshing = true
        wordDataManager.refreshData()
        try? await Task.sleep(nanoseconds: 500_000_000)
        refreshing = false
    }
}



// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Study Modes Section
struct StudyModesSection: View {
    @Binding var showingFlashcards: Bool
    @Binding var showingQuiz: Bool
    @Binding var showingReview: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chế độ học")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    StudyModeCard(
                        icon: "rectangle.stack.fill",
                        title: "Flashcards",
                        subtitle: "Lật thẻ học từ",
                        color: .blue,
                        badge: nil
                    ) {
                        HapticFeedback.light.trigger()
                        showingFlashcards = true
                    }
                    
                    StudyModeCard(
                        icon: "questionmark.circle.fill",
                        title: "Quiz",
                        subtitle: "Kiểm tra nhanh",
                        color: .green,
                        badge: "Mới"
                    ) {
                        HapticFeedback.light.trigger()
                        showingQuiz = true
                    }
                    
                    StudyModeCard(
                        icon: "brain.head.profile",
                        title: "SRS Review",
                        subtitle: "Ôn tập thông minh",
                        color: .orange,
                        badge: WordDataManager.shared.wordsForReview.isEmpty ? nil : "\(WordDataManager.shared.wordsForReview.count)"
                    ) {
                        HapticFeedback.light.trigger()
                        showingReview = true
                    }
                    
                    StudyModeCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Thống kê",
                        subtitle: "Xem tiến độ",
                        color: .purple,
                        badge: nil
                    ) {
                        HapticFeedback.light.trigger()
                        // Navigate to stats
                    }
                }
            }
        }
    }
}

// MARK: - Study Mode Card
struct StudyModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.red)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Review Schedule Section
struct ReviewScheduleSection: View {
    let words: [SavedWord]
    let onSelectWord: (SavedWord) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lịch ôn tập hôm nay")
                    .font(.headline)
                
                Spacer()
                
                Text("\(words.count) từ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(words.prefix(5)) { word in
                    ReviewWordRow(word: word, onTap: {
                        onSelectWord(word)
                    })
                }
                
                if words.count > 5 {
                    Button(action: {
                        // Show all review words
                    }) {
                        Text("Xem tất cả (\(words.count - 5) từ khác)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Review Word Row
struct ReviewWordRow: View {
    let word: SavedWord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.hanzi ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(word.pinyin ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if word.srsLevel > 0 {
                        Label("\(word.srsLevel)", systemImage: "brain")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    let words: [SavedWord]
    let onSelectWord: (SavedWord) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hoạt động gần đây")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: LibraryView()) {
                    Text("Xem tất cả")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(words) { word in
                        RecentWordCard(word: word) {
                            onSelectWord(word)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recent Word Card
struct RecentWordCard: View {
    let word: SavedWord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(word.hanzi ?? "")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(word.pinyin ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .frame(width: 80, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Study Tips Card
struct StudyTipsCard: View {
    let tips = [
        "Ôn tập từ vựng vào buổi sáng để ghi nhớ tốt hơn",
        "Sử dụng flashcard 5-10 phút mỗi ngày",
        "Viết câu ví dụ với từ mới học",
        "Nghe phát âm nhiều lần để nhớ lâu hơn",
        "Ôn lại từ đã học sau 1, 3, 7 ngày"
    ]
    
    @State private var currentTip = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Text("Mẹo học tập")
                    .font(.headline)
            }
            
            Text(tips[currentTip])
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                currentTip = (currentTip + 1) % tips.count
                HapticFeedback.light.trigger()
            }) {
                Text("Mẹo khác →")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

// MARK: - Supporting Views

struct FlashcardSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                if !wordDataManager.savedWords.isEmpty {
                    VStack(spacing: 20) {
                        // Progress indicator
                        ProgressView(value: Double(currentIndex + 1), total: Double(wordDataManager.savedWords.count))
                            .padding(.horizontal)
                        
                        // Flashcard
                        FlashcardView(
                            word: wordDataManager.savedWords[currentIndex],
                            showingAnswer: $showingAnswer
                        )
                        .padding()
                        
                        // Controls
                        HStack(spacing: 30) {
                            Button(action: previousCard) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                            }
                            .disabled(currentIndex == 0)
                            
                            Button(action: { showingAnswer.toggle() }) {
                                Text(showingAnswer ? "Ẩn" : "Hiện đáp án")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                            
                            Button(action: nextCard) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                            }
                            .disabled(currentIndex >= wordDataManager.savedWords.count - 1)
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "rectangle.stack",
                        title: "Chưa có từ vựng",
                        message: "Hãy lưu một số từ vựng để bắt đầu flashcard"
                    )
                }
            }
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
    
    private func nextCard() {
        if currentIndex < wordDataManager.savedWords.count - 1 {
            currentIndex += 1
            showingAnswer = false
        }
    }
    
    private func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            showingAnswer = false
        }
    }
}

struct FlashcardView: View {
    let word: SavedWord
    @Binding var showingAnswer: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(word.hanzi ?? "")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.primary)
            
            if showingAnswer {
                VStack(spacing: 12) {
                    Text(word.pinyin ?? "")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(word.meaning ?? "")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if let example = word.example {
                        Text(example)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.top, 8)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
}

struct QuizSessionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                Text("Quiz feature coming soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

struct SRSReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var wordDataManager = WordDataManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                if !wordDataManager.wordsForReview.isEmpty {
                    VStack {
                        Text("Review \(wordDataManager.wordsForReview.count) words")
                            .font(.title2)
                        // Add SRS review logic here
                    }
                } else {
                    EmptyStateView(
                        icon: "brain.head.profile",
                        title: "Không có từ cần ôn",
                        message: "Tất cả từ vựng đã được ôn tập"
                    )
                }
            }
            .navigationTitle("SRS Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

struct WordDetailView: View {
    let word: SavedWord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text(word.hanzi ?? "")
                        .font(.system(size: 60, weight: .bold))
                    
                    Text(word.pinyin ?? "")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(word.meaning ?? "")
                        .font(.title3)
                    
                    if let example = word.example {
                        Text(example)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Chi tiết từ vựng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    StudyDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
