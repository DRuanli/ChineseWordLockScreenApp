//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Minimalist design focused on vocabulary learning
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var showingExample = false
    @State private var showingPersonalNote = false
    @State private var personalNote = ""
    @State private var cardOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var audioPlaying = false
    @State private var slowAudioMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Minimal header - just level indicator
                    HStack {
                        Text("HSK\(authManager.currentUser?.preferredHSKLevel ?? 5)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        
                        Spacer()
                        
                        // Quick progress indicator
                        if wordDataManager.todayWordsCount > 0 {
                            Text("\(wordDataManager.todayWordsCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Main word card - takes up most of the screen
                    MinimalistWordCard(
                        word: viewModel.currentWord,
                        showingExample: $showingExample,
                        showingPersonalNote: $showingPersonalNote,
                        personalNote: $personalNote,
                        cardOffset: $cardOffset,
                        isAnimating: $isAnimating,
                        audioPlaying: $audioPlaying,
                        slowAudioMode: $slowAudioMode,
                        viewModel: viewModel
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    
                    // Bottom minimal controls
                    HStack(spacing: 40) {
                        Button(action: previousWord) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        
                        Button(action: nextWord) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                wordDataManager.refreshData()
            }
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
    }
    
    private func nextWord() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = true
        }
        viewModel.getNextWord()
        resetStates()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }
    
    private func previousWord() {
        viewModel.getPreviousWord()
        resetStates()
    }
    
    private func resetStates() {
        showingExample = false
        showingPersonalNote = false
        personalNote = ""
    }
}

// MARK: - Minimalist Word Card
struct MinimalistWordCard: View {
    let word: HSKWord
    @Binding var showingExample: Bool
    @Binding var showingPersonalNote: Bool
    @Binding var personalNote: String
    @Binding var cardOffset: CGFloat
    @Binding var isAnimating: Bool
    @Binding var audioPlaying: Bool
    @Binding var slowAudioMode: Bool
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 25) {
                Spacer()
                
                // Chinese Character - dominant element
                Text(word.hanzi)
                    .font(.custom("Noto Sans SC", size: min(UIScreen.main.bounds.width * 0.4, 160)))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .opacity(isAnimating ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isAnimating)
                
                // Pinyin with tone colors
                HStack(spacing: 0) {
                    ForEach(Array(getPinyinWithTones(word.pinyin).enumerated()), id: \.offset) { index, syllable in
                        Text(syllable.text)
                            .font(.system(size: 28))
                            .foregroundColor(syllable.toneColor)
                    }
                }
                
                // Vietnamese meaning - primary
                Text(getVietnameseMeaning(word.meaning))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // English meaning - secondary
                Text(word.meaning)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Example sentence (expandable)
                if showingExample {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal, 60)
                        
                        if let example = word.example {
                            VStack(spacing: 6) {
                                Text(example)
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                
                                Text(getVietnameseTranslation(example))
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .italic()
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 20)
                }
                
                // Personal notes (expandable)
                if showingPersonalNote {
                    VStack(spacing: 8) {
                        Text("Ghi chú:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Thêm ghi chú...", text: $personalNote)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }
            
            // Action buttons - minimal and clean
            HStack(spacing: 30) {
                // Audio button
                Button(action: playAudio) {
                    VStack(spacing: 4) {
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
                
                // Example toggle
                Button(action: {
                    withAnimation(.spring()) {
                        showingExample.toggle()
                        if showingExample {
                            showingPersonalNote = false
                        }
                    }
                }) {
                    Image(systemName: showingExample ? "text.badge.minus" : "text.badge.plus")
                        .font(.title2)
                        .foregroundColor(showingExample ? .orange : .green)
                }
                
                // Save/heart button
                Button(action: {
                    viewModel.toggleSave()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(viewModel.isSaved ? .red : .gray)
                }
                
                // Notes toggle
                Button(action: {
                    withAnimation(.spring()) {
                        showingPersonalNote.toggle()
                        if showingPersonalNote {
                            showingExample = false
                        }
                    }
                }) {
                    Image(systemName: showingPersonalNote ? "note.text.badge.plus" : "note.text")
                        .font(.title2)
                        .foregroundColor(showingPersonalNote ? .orange : .gray)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
        .offset(x: cardOffset)
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
    
    private func getVietnameseMeaning(_ meaning: String) -> String {
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
        return meaning
    }
    
    private func getVietnameseTranslation(_ chinese: String) -> String {
        return "Căn phòng này rất rộng"
    }
}

// Keep the Color extension
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
