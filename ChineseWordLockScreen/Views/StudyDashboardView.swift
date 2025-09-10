//
//  StudyDashboardView.swift
//  ChineseWordLockScreen
//
//  Comprehensive study progress and tools dashboard
//

import SwiftUI

struct StudyDashboardView: View {
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingFullFlashcard = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Study Stats Header
                    StudyStatsHeader(
                        todayCount: wordDataManager.todayWordsCount,
                        streak: wordDataManager.streak,
                        totalWords: wordDataManager.savedWords.count,
                        goal: Int(authManager.currentUser?.dailyGoal ?? 10)
                    )
                    
                    // Quick Actions Grid
                    QuickActionsGrid(showingFullFlashcard: $showingFullFlashcard)
                    
                    // Review Today Section
                    if !wordDataManager.wordsForReview.isEmpty {
                        ReviewTodaySection(words: wordDataManager.wordsForReview)
                    }
                    
                    // Recent Activity
                    RecentActivitySection(recentWords: Array(wordDataManager.savedWords.prefix(5)))
                }
                .padding()
            }
            .navigationTitle("Học tập")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground))
        }
        .sheet(isPresented: $showingFullFlashcard) {
            FlashcardSessionView()
        }
        .onAppear {
            wordDataManager.refreshData()
        }
    }
}

: - Study Stats Header
struct StudyStatsHeader: View {
    let todayCount: Int
    let streak: Int
    let totalWords: Int
    let goal: Int
    
    var progress: Double {
        min(Double(todayCount) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Main progress card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hôm nay")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(todayCount) / \(goal)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("từ đã học")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(progress: progress)
                        .frame(width: 80, height: 80)
                }
                
                ProgressView(value: progress)
                    .tint(progress >= 1.0 ? .green : .blue)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                if progress >= 1.0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Hoàn thành mục tiêu hôm nay!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
            
            // Stats row
            HStack(spacing: 15) {
                StatCard(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\(streak)",
                    color: .orange
                )
                
                StatCard(
                    icon: "books.vertical.fill",
                    title: "Tổng từ",
                    value: "\(totalWords)",
                    color: .blue
                )
                
                StatCard(
                    icon: "calendar",
                    title: "Tuần này",
                    value: "45", // Calculate weekly count
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress >= 1.0 ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    @Binding var showingFullFlashcard: Bool
    @Binding var showingQuickStudy: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Công cụ học tập")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ActionCard(
                    icon: "timer",
                    title: "Học nhanh",
                    subtitle: "5 phút tập trung",
                    color: .blue
                ) {
                    showingQuickStudy = true
                }
                
                ActionCard(
                    icon: "rectangle.stack",
                    title: "Flashcards",
                    subtitle: "Ôn tập từ đã lưu",
                    color: .green
                ) {
                    showingFullFlashcard = true
                }
                
                NavigationLink(destination: LibraryView()) {
                    ActionCard(
                        icon: "books.vertical",
                        title: "Thư viện",
                        subtitle: "Quản lý từ vựng",
                        color: .purple
                    ) { }
                }
                
                ActionCard(
                    icon: "brain.head.profile",
                    title: "SRS Quiz",
                    subtitle: "Kiểm tra trí nhớ",
                    color: .orange
                ) {
                    // SRS quiz action - could open another study mode
                }
            }
        }
    }
}

// MARK: - Action Card
struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Review Today Section
struct ReviewTodaySection: View {
    let words: [SavedWord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cần ôn hôm nay")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(words.count) từ")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(words.prefix(5), id: \.self) { word in
                        ReviewWordCard(word: word)
                    }
                    
                    if words.count > 5 {
                        NavigationLink(destination: LibraryView()) {
                            VStack {
                                Text("+\(words.count - 5)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text("xem thêm")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

// MARK: - Review Word Card
struct ReviewWordCard: View {
    let word: SavedWord
    
    var body: some View {
        VStack(spacing: 4) {
            Text(word.hanzi ?? "")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(word.pinyin ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 3)
        )
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    let recentWords: [SavedWord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hoạt động gần đây")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(recentWords, id: \.self) { word in
                    RecentActivityRow(word: word)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
        }
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    let word: SavedWord
    
    var body: some View {
        HStack {
            Text(word.hanzi ?? "")
                .font(.title3)
                .fontWeight(.medium)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(word.pinyin ?? "")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(word.meaning ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let date = word.savedDate {
                Text(timeAgoString(from: date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.timeStyle = .numeric
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Flashcard Session View (Simplified)
struct FlashcardSessionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if !wordDataManager.savedWords.isEmpty {
                    VStack(spacing: 40) {
                        // Progress
                        Text("\(currentIndex + 1) / \(wordDataManager.savedWords.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Card
                        VStack(spacing: 20) {
                            Text(wordDataManager.savedWords[currentIndex].hanzi ?? "")
                                .font(.system(size: 80))
                                .fontWeight(.medium)
                            
                            if showingAnswer {
                                VStack(spacing: 10) {
                                    Text(wordDataManager.savedWords[currentIndex].pinyin ?? "")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(wordDataManager.savedWords[currentIndex].meaning ?? "")
                                        .font(.title3)
                                        .multilineTextAlignment(.center)
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                showingAnswer.toggle()
                            }
                        }
                        
                        // Controls
                        HStack(spacing: 30) {
                            Button(action: previousCard) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                            .disabled(currentIndex == 0)
                            
                            Button(action: {
                                withAnimation {
                                    showingAnswer.toggle()
                                }
                            }) {
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
                                
