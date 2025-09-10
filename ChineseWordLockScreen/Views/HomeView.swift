//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Enhanced version with Vietnamese support and detailed requirements
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var showingMoreMeanings = false
    @State private var showingExample = false
    @State private var showingMoreExamples = false
    @State private var showingPersonalNote = false
    @State private var personalNote = ""
    @State private var autoPlayEnabled = false
    @State private var showingFullFlashcard = false
    
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
                        
                        // Enhanced Word Display Card
                        EnhancedWordCard(
                            word: viewModel.currentWord,
                            showingMoreMeanings: $showingMoreMeanings,
                            showingExample: $showingExample,
                            showingMoreExamples: $showingMoreExamples,
                            showingPersonalNote: $showingPersonalNote,
                            personalNote: $personalNote,
                            autoPlayEnabled: $autoPlayEnabled,
                            viewModel: viewModel
                        )
                        .padding(.horizontal)
                        
                        // Quick Actions
                        QuickActionsSection(
                            showingFullFlashcard: $showingFullFlashcard
                        )
                        
                        // Daily Progress
                        DailyProgressSection(
                            current: wordDataManager.todayWordsCount,
                            goal: Int(authManager.currentUser?.dailyGoal ?? 10)
                        )
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                wordDataManager.refreshData()
                if autoPlayEnabled {
                    viewModel.speakWord()
                }
            }
            .sheet(isPresented: $showingFullFlashcard) {
                FlashcardSessionView()
            }
        }
    }
}

// MARK: - Enhanced Word Card
struct EnhancedWordCard: View {
    let word: HSKWord
    @Binding var showingMoreMeanings: Bool
    @Binding var showingExample: Bool
    @Binding var showingMoreExamples: Bool
    @Binding var showingPersonalNote: Bool
    @Binding var personalNote: String
    @Binding var autoPlayEnabled: Bool
    let viewModel: HomeViewModel
    
    @State private var audioPlaying = false
    @State private var slowAudioMode = false
    @State private var cardOffset: CGFloat = 0
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top controls
            HStack {
                Text("Từ vựng hôm nay")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Toggle("", isOn: $autoPlayEnabled)
                    .labelsHidden()
                    .scaleEffect(0.7)
                
                Text("Auto")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            
            VStack(spacing: 15) {
                // 1. Chinese Character - 40-50% of card
                Text(word.hanzi)
                    .font(.custom("Noto Sans SC", size: 120))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(minHeight: 150)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .opacity(isAnimating ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isAnimating)
                
                // 2. Pinyin with tone colors
                HStack(spacing: 0) {
                    ForEach(Array(getPinyinWithTones(word.pinyin).enumerated()), id: \.offset) { index, syllable in
                        Text(syllable.text)
                            .font(.system(size: 24))
                            .foregroundColor(syllable.toneColor)
                    }
                }
                .padding(.top, -10)
                
                // 3. Vietnamese Meaning
                VStack(spacing: 8) {
                    HStack {
                        Text(getVietnameseMeaning(word.meaning))
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                        
                        // 4. Word Type
                        Text(getWordType(word))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(getWordTypeColor(word).opacity(0.2))
                            .foregroundColor(getWordTypeColor(word))
                            .cornerRadius(8)
                    }
                    
                    if !showingMoreMeanings {
                        Button(action: { withAnimation { showingMoreMeanings.toggle() } }) {
                            Text("Xem thêm nghĩa →")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(getFullMeanings(word))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                
                // 5. Example Sentence (optional, expandable)
                if showingExample {
                    VStack(spacing: 8) {
                        Divider().padding(.horizontal, 40)
                        
                        if let example = word.example {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(example)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                
                                Text(getPinyinForExample(example))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(getVietnameseTranslation(example))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .italic()
                            }
                            .padding(.horizontal)
                            
                            if !showingMoreExamples {
                                Button("Thêm ví dụ") {
                                    withAnimation { showingMoreExamples.toggle() }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 6. Audio Button (always visible)
                HStack(spacing: 25) {
                    Button(action: playAudio) {
                        VStack(spacing: 2) {
                            Image(systemName: audioPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .scaleEffect(audioPlaying ? 1.2 : 1.0)
                            
                            if slowAudioMode {
                                Text("Chậm")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onLongPressGesture {
                        slowAudioMode = true
                        playAudio()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            slowAudioMode = false
                        }
                    }
                    
                    Button(action: { showingExample.toggle() }) {
                        Image(systemName: showingExample ? "text.badge.minus" : "text.badge.plus")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        viewModel.toggleSave()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(viewModel.isSaved ? .red : .gray)
                    }
                    
                    Button(action: { showingPersonalNote.toggle() }) {
                        Image(systemName: "note.text")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 10)
                
                // 7. Tags/Classification
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        TagButton(text: "HSK\(word.hskLevel)", color: .purple)
                        TagButton(text: getWordType(word), color: getWordTypeColor(word))
                        TagButton(text: getTopicTag(word), color: .teal)
                    }
                }
                .padding(.horizontal)
                
                // 8. Word Frequency
                HStack {
                    Text("Phổ biến:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < getFrequencyRating(word) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                // 9. Personal Notes
                if showingPersonalNote {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ghi chú cá nhân:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("VD: nhớ bằng 'quần rộng'...", text: $personalNote)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 20)
            
            // Navigation controls
            HStack(spacing: 30) {
                Button(action: previousWord) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Text("Vuốt để chuyển từ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: nextWord) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
        .offset(x: cardOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    cardOffset = value.translation.width / 3
                }
                .onEnded { value in
                    if abs(value.translation.width) > 100 {
                        if value.translation.width > 0 {
                            previousWord()
                        } else {
                            nextWord()
                        }
                    }
                    withAnimation(.spring()) {
                        cardOffset = 0
                    }
                }
        )
    }
    
    // Helper functions
    private func playAudio() {
        withAnimation(.easeInOut(duration: 0.2)) {
            audioPlaying = true
        }
        
        if slowAudioMode {
            viewModel.speakWordSlow()
        } else {
            viewModel.speakWord()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            audioPlaying = false
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func nextWord() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = true
        }
        viewModel.getNextWord()
        resetStates()
        if autoPlayEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.speakWord()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }
    
    private func previousWord() {
        // Implementation for previous word
        nextWord() // Simplified for now
    }
    
    private func resetStates() {
        showingMoreMeanings = false
        showingExample = false
        showingMoreExamples = false
        showingPersonalNote = false
        personalNote = ""
    }
    
    // Tone color mapping
    private func getPinyinWithTones(_ pinyin: String) -> [(text: String, toneColor: Color)] {
        var result: [(String, Color)] = []
        let syllables = pinyin.split(separator: " ")
        
        for syllable in syllables {
            let tone = detectTone(String(syllable))
            result.append((String(syllable), getToneColor(tone)))
        }
        
        return result
    }
    
    private func detectTone(_ syllable: String) -> Int {
        let tone1 = ["ā", "ē", "ī", "ō", "ū", "ǖ"]
        let tone2 = ["á", "é", "í", "ó", "ú", "ǘ"]
        let tone3 = ["ǎ", "ě", "ǐ", "ǒ", "ǔ", "ǚ"]
        let tone4 = ["à", "è", "ì", "ò", "ù", "ǜ"]
        
        for char in syllable {
            if tone1.contains(where: { String(char).contains($0) }) { return 1 }
            if tone2.contains(where: { String(char).contains($0) }) { return 2 }
            if tone3.contains(where: { String(char).contains($0) }) { return 3 }
            if tone4.contains(where: { String(char).contains($0) }) { return 4 }
        }
        return 0
    }
    
    private func getToneColor(_ tone: Int) -> Color {
        switch tone {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .primary
        }
    }
    
    private func getWordType(_ word: HSKWord) -> String {
        // Simplified word type detection
        if word.meaning.contains("to ") { return "【v.】" }
        if word.meaning.contains("tion") || word.meaning.contains("ness") { return "【n.】" }
        return "【adj.】"
    }
    
    private func getWordTypeColor(_ word: HSKWord) -> Color {
        let type = getWordType(word)
        switch type {
        case "【v.】": return .green
        case "【n.】": return .blue
        case "【adj.】": return .orange
        default: return .gray
        }
    }
    
    private func getVietnameseMeaning(_ meaning: String) -> String {
        // Vietnamese translations mapping (simplified)
        let translations: [String: String] = [
            "wide": "rộng",
            "method": "phương pháp",
            "help": "giúp đỡ",
            "competition": "cuộc thi",
            "express": "biểu đạt",
            "change": "thay đổi",
            "participate": "tham gia",
            "be late": "trễ",
            "plan": "kế hoạch",
            "worry": "lo lắng"
        ]
        
        for (eng, viet) in translations {
            if meaning.lowercased().contains(eng) {
                return viet
            }
        }
        return meaning // Fallback to English
    }
    
    private func getFullMeanings(_ word: HSKWord) -> String {
        // Extended meanings
        return "\(getWordType(word)) \(getVietnameseMeaning(word.meaning)) / khoan dung / thoáng"
    }
    
    private func getPinyinForExample(_ chinese: String) -> String {
        // Simplified - would need proper pinyin conversion
        return "Zhège fángjiān hěn kuān"
    }
    
    private func getVietnameseTranslation(_ chinese: String) -> String {
        // Simplified translation
        return "Căn phòng này rất rộng"
    }
    
    private func getTopicTag(_ word: HSKWord) -> String {
        // Topic categorization
        return "Chủ đề: Tính cách"
    }
    
    private func getFrequencyRating(_ word: HSKWord) -> Int {
        // Frequency based on HSK level
        switch word.hskLevel {
        case 3: return 5
        case 4: return 4
        case 5: return 3
        case 6: return 2
        default: return 3
        }
    }
}

// MARK: - Tag Button
struct TagButton: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
    }
}

// MARK: - Quick Actions
struct QuickActionsSection: View {
    @Binding var showingFullFlashcard: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            ActionButton(icon: "rectangle.stack", label: "Flashcards", color: .blue) {
                showingFullFlashcard = true
            }
            
            NavigationLink(destination: LibraryView()) {
                ActionButton(icon: "books.vertical", label: "Thư viện", color: .green) { }
            }
            
            NavigationLink(destination: StatsView()) {
                ActionButton(icon: "chart.bar", label: "Thống kê", color: .purple) { }
            }
        }
        .padding(.horizontal)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
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
}

// MARK: - Daily Progress
struct DailyProgressSection: View {
    let current: Int
    let goal: Int
    
    var progress: Double {
        min(Double(current) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Hôm nay: \(current)/\(goal) từ")
                    .font(.subheadline)
                
                Spacer()
                
                if progress >= 1.0 {
                    Label("Hoàn thành!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : .blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)
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

// MARK: - Flashcard Session View
struct FlashcardSessionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !wordDataManager.savedWords.isEmpty {
                    VStack(spacing: 30) {
                        Text("\(currentIndex + 1) / \(wordDataManager.savedWords.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
                        .onTapGesture {
                            withAnimation {
                                showingAnswer.toggle()
                            }
                        }
                        
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
                                    .foregroundColor(.blue)
                            }
                            .disabled(currentIndex >= wordDataManager.savedWords.count - 1)
                        }
                    }
                    .padding()
                } else {
                    Text("Chưa có từ vựng nào được lưu")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
    
    private func nextCard() {
        if currentIndex < wordDataManager.savedWords.count - 1 {
            withAnimation {
                currentIndex += 1
                showingAnswer = false
            }
        }
    }
    
    private func previousCard() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
                showingAnswer = false
            }
        }
    }
}

// Keep existing helper components
struct HomeHeaderSection: View {
    let todayCount: Int
    let streak: Int
    let level: Int16
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Học từ vựng")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    Label("\(todayCount) từ", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(streak) ngày", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Text("HSK\(level)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                
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
