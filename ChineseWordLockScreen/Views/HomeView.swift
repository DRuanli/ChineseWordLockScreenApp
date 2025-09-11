//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Redesigned minimalist vocabulary card with swipe navigation
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var dragOffset: CGSize = .zero
    @State private var showingShareView = false
    @State private var showingInfo = false
    @State private var capturedImage: UIImage?
    @State private var audioPlaying = false
    @State private var currentWordIndex = 0
    @State private var totalWords = 5
    
    // Swipe threshold
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Clean beige background
            Color(red: 0.95, green: 0.93, blue: 0.88)
                .ignoresSafeArea()
            
            if showingShareView {
                ShareView(
                    word: viewModel.currentWord,
                    capturedImage: $capturedImage,
                    isPresented: $showingShareView
                )
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Top bar with progress indicator
                    TopProgressBar(currentIndex: currentWordIndex, total: totalWords)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Main vocabulary card
                    VocabularyCard(
                        word: viewModel.currentWord,
                        audioPlaying: $audioPlaying,
                        onPlayAudio: playAudio
                    )
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                    .opacity(1 - Double(abs(dragOffset.width) / 200))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.interactiveSpring()) {
                                    dragOffset = value.translation
                                }
                            }
                            .onEnded { value in
                                handleSwipe(value.translation)
                            }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                    
                    // Bottom action buttons
                    ActionButtonBar(
                        onInfo: { showingInfo = true },
                        onShare: shareWord,
                        onLike: toggleLike,
                        onBookmark: toggleBookmark,
                        isLiked: viewModel.isSaved,
                        isBookmarked: viewModel.isSaved
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            wordDataManager.refreshData()
            setupScreenshotDetection()
        }
        .sheet(isPresented: $showingInfo) {
            WordInfoSheet(word: viewModel.currentWord)
        }
    }
    
    // MARK: - Helper Methods
    private func handleSwipe(_ translation: CGSize) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Check if swipe exceeds threshold
            if abs(translation.width) > swipeThreshold || abs(translation.height) > swipeThreshold {
                // Determine swipe direction and load next word
                if abs(translation.width) > abs(translation.height) {
                    // Horizontal swipe
                    if translation.width > 0 {
                        // Swipe right - previous word
                        if currentWordIndex > 0 {
                            currentWordIndex -= 1
                            viewModel.getPreviousWord()
                        }
                    } else {
                        // Swipe left - next word
                        if currentWordIndex < totalWords - 1 {
                            currentWordIndex += 1
                            viewModel.getNextWord()
                        }
                    }
                } else {
                    // Vertical swipe
                    if translation.height > 0 {
                        // Swipe down - could be used for special action
                        if currentWordIndex < totalWords - 1 {
                            currentWordIndex += 1
                            viewModel.getNextWord()
                        }
                    } else {
                        // Swipe up - could be used for special action
                        if currentWordIndex < totalWords - 1 {
                            currentWordIndex += 1
                            viewModel.getNextWord()
                        }
                    }
                }
            }
            // Reset offset
            dragOffset = .zero
        }
    }
    
    private func playAudio() {
        withAnimation(.easeInOut(duration: 0.2)) {
            audioPlaying = true
        }
        viewModel.speakWord()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            audioPlaying = false
        }
    }
    
    private func shareWord() {
        // Capture the card as image first
        captureCard()
        showingShareView = true
    }
    
    private func toggleLike() {
        viewModel.toggleSave()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func toggleBookmark() {
        viewModel.toggleSave()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func captureCard() {
        // Implementation for capturing the card as image
        // This would use a view snapshot extension
    }
    
    private func setupScreenshotDetection() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            showingShareView = true
        }
    }
}

// MARK: - Top Progress Bar
struct TopProgressBar: View {
    @StateObject private var wordDataManager = WordDataManager.shared
    let currentIndex: Int
    let total: Int
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(total)
    }
    
    var body: some View {
        HStack {
            Image(systemName: "bookmark")
                .font(.title2)
                .foregroundColor(.black.opacity(0.7))
            
            Text("\(currentIndex + 1)/\(total)")
                .font(.headline)
                .foregroundColor(.black.opacity(0.7))
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.7))
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
            
            Spacer()
            
            Image(systemName: "crown")
                .font(.title2)
                .foregroundColor(.black.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.9))
                )
        }
    }
}

// MARK: - Vocabulary Card
struct VocabularyCard: View {
    let word: HSKWord
    @Binding var audioPlaying: Bool
    let onPlayAudio: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Main word
            Text(word.hanzi)
                .font(.system(size: 80, weight: .bold, design: .serif))
                .foregroundColor(.black)
            
            // Pronunciation with audio button
            HStack(spacing: 12) {
                Text(word.pinyin)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.9))
                    )
                
                Button(action: onPlayAudio) {
                    Image(systemName: audioPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.black.opacity(0.7))
                        .scaleEffect(audioPlaying ? 1.2 : 1.0)
                }
            }
            
            // Part of speech and definition
            VStack(spacing: 12) {
                Text("(n.) \(word.meaning)")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.black.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 30)
            
            // Example sentence
            if let example = word.example {
                Text(example)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Action Button Bar
struct ActionButtonBar: View {
    let onInfo: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onBookmark: () -> Void
    let isLiked: Bool
    let isBookmarked: Bool
    
    var body: some View {
        HStack(spacing: 40) {
            // Info button
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.title)
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            
            // Share button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            
            // Like button
            Button(action: onLike) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.title)
                    .foregroundColor(isLiked ? .red : .black.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            
            // Bookmark button
            Button(action: onBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.title)
                    .foregroundColor(isBookmarked ? .blue : .black.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
        }
    }
}

// MARK: - Share View
struct ShareView: View {
    let word: HSKWord
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var showingActivityView = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 30) {
                // Close button
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Card preview
                ShareableCard(word: word)
                    .frame(maxWidth: 350)
                    .padding(.horizontal, 20)
                
                // Action buttons
                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        ShareActionButton(icon: "arrow.down.circle", label: "Save image") {
                            saveImage()
                        }
                        
                        ShareActionButton(icon: "doc.on.doc", label: "Copy text") {
                            copyText()
                        }
                        
                        ShareActionButton(icon: "bookmark", label: "Add to collection") {
                            addToCollection()
                        }
                    }
                    
                    // Share options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ShareAppButton(appIcon: "message.fill", appName: "Messages", color: .green) {
                                shareToApp("messages")
                            }
                            
                            ShareAppButton(appIcon: "f.circle.fill", appName: "Facebook", color: .blue) {
                                shareToApp("facebook")
                            }
                            
                            ShareAppButton(appIcon: "camera.circle.fill", appName: "Facebook\nStories", color: .blue) {
                                shareToApp("fb_stories")
                            }
                            
                            ShareAppButton(appIcon: "play.rectangle.fill", appName: "Facebook\nReels", color: .blue) {
                                shareToApp("fb_reels")
                            }
                            
                            ShareAppButton(appIcon: "message.circle.fill", appName: "Facebook\nMessenger", color: .blue) {
                                shareToApp("messenger")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    private func saveImage() {
        // Save to photo library
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func copyText() {
        let text = "\(word.hanzi)\n\(word.pinyin)\n\(word.meaning)"
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func addToCollection() {
        // Add to saved words
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func shareToApp(_ app: String) {
        showingActivityView = true
    }
}

// MARK: - Shareable Card
struct ShareableCard: View {
    let word: HSKWord
    
    var body: some View {
        VStack(spacing: 20) {
            // Word
            Text(word.hanzi)
                .font(.system(size: 60, weight: .bold, design: .serif))
                .foregroundColor(.black)
                .padding(.top, 40)
            
            // Pronunciation
            Text("'\(word.pinyin)")
                .font(.system(size: 20))
                .foregroundColor(.black.opacity(0.8))
            
            // Definition
            Text("(n.) \(word.meaning)")
                .font(.system(size: 18))
                .foregroundColor(.black.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Example
            if let example = word.example {
                Text(example)
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
            }
            
            // Watermark
            Text("vocabulary")
                .font(.caption)
                .foregroundColor(.black.opacity(0.4))
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Share Action Button
struct ShareActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 100)
        }
    }
}

// MARK: - Share App Button
struct ShareAppButton: View {
    let appIcon: String
    let appName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: appIcon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .clipShape(Circle())
                
                Text(appName)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
        }
    }
}

// MARK: - Word Info Sheet
struct WordInfoSheet: View {
    let word: HSKWord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Word header
                    VStack(spacing: 12) {
                        Text(word.hanzi)
                            .font(.system(size: 60, weight: .bold))
                            .frame(maxWidth: .infinity)
                        
                        Text(word.pinyin)
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text(word.meaning)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                        
                        // Vietnamese meaning
                        Text(getVietnameseMeaning(word.meaning))
                            .font(.title3)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    
                    Divider()
                    
                    // Additional information
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(label: "HSK Level", value: "HSK \(word.hskLevel)")
                        
                        if let example = word.example {
                            InfoRow(label: "Example", value: example)
                        }
                        
                        InfoRow(label: "Part of Speech", value: getPartOfSpeech(word.meaning))
                        
                        // Tone information
                        InfoRow(label: "Tones", value: getTonePattern(word.pinyin))
                        
                        // Usage frequency (mock data for now)
                        InfoRow(label: "Frequency", value: "Common")
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Word Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func getVietnameseMeaning(_ english: String) -> String {
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
            "worry": "lo lắng",
            "learn": "học",
            "study": "học tập"
        ]
        
        for (eng, viet) in translations {
            if english.lowercased().contains(eng) {
                return viet
            }
        }
        return english
    }
    
    private func getPartOfSpeech(_ meaning: String) -> String {
        // Simple detection based on meaning patterns
        if meaning.contains("to ") {
            return "Verb"
        } else if meaning.contains("ing") {
            return "Gerund/Noun"
        } else {
            return "Noun"
        }
    }
    
    private func getTonePattern(_ pinyin: String) -> String {
        var pattern = ""
        let syllables = pinyin.split(separator: " ")
        
        for syllable in syllables {
            let tone = detectTone(String(syllable))
            pattern += "Tone \(tone == 0 ? "neutral" : String(tone)) "
        }
        
        return pattern.trimmingCharacters(in: .whitespaces)
    }
    
    private func detectTone(_ syllable: String) -> Int {
        let tone1 = ["ā", "ē", "ī", "ō", "ū", "ǖ"]
        let tone2 = ["á", "é", "í", "ó", "ú", "ǘ"]
        let tone3 = ["ǎ", "ě", "ǐ", "ǒ", "ǔ", "ǚ"]
        let tone4 = ["à", "è", "ì", "ò", "ù", "ǜ"]
        
        for char in syllable {
            let charStr = String(char)
            if tone1.contains(where: { charStr.contains($0) }) { return 1 }
            if tone2.contains(where: { charStr.contains($0) }) { return 2 }
            if tone3.contains(where: { charStr.contains($0) }) { return 3 }
            if tone4.contains(where: { charStr.contains($0) }) { return 4 }
        }
        return 0
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
