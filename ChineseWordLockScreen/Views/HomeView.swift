//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Clean minimalist design inspired by language learning apps
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var showingExample = false
    @State private var showingInfo = false
    @State private var showingShare = false
    @State private var audioPlaying = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Status Bar
                    CustomStatusBar()
                        .padding(.top, 8)
                    
                    // Progress Section
                    ProgressSection(
                        current: wordDataManager.todayWordsCount,
                        total: Int(authManager.currentUser?.dailyGoal ?? 10)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Main Content Area
                    VStack(spacing: 32) {
                        Spacer()
                        
                        // Chinese Character - Main Focus
                        Text(viewModel.currentWord.hanzi)
                            .font(.system(size: 64, weight: .bold, design: .default))
                            .foregroundColor(.black)
                        
                        // Pinyin with Audio Button
                        HStack(spacing: 12) {
                            Text("[\(viewModel.currentWord.pinyin)]")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Button(action: playAudio) {
                                Image(systemName: audioPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                    .scaleEffect(audioPlaying ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: audioPlaying)
                            }
                        }
                        
                        // Definition
                        VStack(spacing: 16) {
                            Text("(n.) \(getVietnameseMeaning(viewModel.currentWord.meaning))")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Example sentence - expandable
                            if showingExample {
                                if let example = viewModel.currentWord.example {
                                    Text(example)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                        
                        // Action Buttons Row
                        ActionButtonsRow(
                            showingExample: $showingExample,
                            showingInfo: $showingInfo,
                            showingShare: $showingShare,
                            isSaved: viewModel.isSaved,
                            onToggleSave: viewModel.toggleSave,
                            onInfo: { showingInfo = true },
                            onShare: { showingShare = true }
                        )
                        .padding(.horizontal, 60)
                        
                        Spacer()
                    }
                    
                    // Bottom Navigation
                    BottomNavigationBar(onNext: {
                        viewModel.getNextWord()
                        resetStates()
                    })
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34) // Safe area bottom
                }
            }
        }
        .onAppear {
            wordDataManager.refreshData()
        }
        .sheet(isPresented: $showingInfo) {
            WordInfoSheet(word: viewModel.currentWord)
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(word: viewModel.currentWord)
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func resetStates() {
        showingExample = false
    }
    
    private func getVietnameseMeaning(_ english: String) -> String {
        let translations: [String: String] = [
            "wide": "rộng", "method": "phương pháp", "help": "giúp đỡ",
            "competition": "cuộc thi", "express": "biểu đạt", "change": "thay đổi",
            "participate": "tham gia", "be late": "trễ", "plan": "kế hoạch",
            "worry": "lo lắng", "learn": "học", "study": "học tập",
            "good": "tốt", "beautiful": "đẹp", "big": "lớn", "small": "nhỏ"
        ]
        
        for (eng, viet) in translations {
            if english.lowercased().contains(eng) {
                return viet
            }
        }
        return english
    }
}

// MARK: - Custom Status Bar
struct CustomStatusBar: View {
    var body: some View {
        HStack {
            // Time
            Text("08:15")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            // Signal and Battery Icons
            HStack(spacing: 6) {
                // Signal dots
                HStack(spacing: 2) {
                    Circle().fill(Color.black).frame(width: 4, height: 4)
                    Circle().fill(Color.black).frame(width: 4, height: 4)
                    Circle().fill(Color.black).frame(width: 4, height: 4)
                }
                
                // WiFi icon
                Image(systemName: "wifi")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                
                // Battery
                Text("34")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Progress Section
struct ProgressSection: View {
    let current: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(current) / Double(total), 1.0)
    }
    
    var body: some View {
        HStack {
            // Bookmark icon
            Image(systemName: "bookmark")
                .font(.system(size: 16))
                .foregroundColor(.black)
            
            // Progress indicator
            Text("\(current)/\(total)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .black))
                .scaleEffect(x: 1, y: 0.8)
                .frame(height: 4)
            
            Spacer()
            
            // Chart icon
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 18))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Action Buttons Row
struct ActionButtonsRow: View {
    @Binding var showingExample: Bool
    @Binding var showingInfo: Bool
    @Binding var showingShare: Bool
    let isSaved: Bool
    let onToggleSave: () -> Void
    let onInfo: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            // Info button
            Button(action: onInfo) {
                Circle()
                    .stroke(Color.black, lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("i")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    )
            }
            
            // Share button
            Button(action: onShare) {
                Circle()
                    .stroke(Color.black, lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    )
            }
            
            // Favorite button
            Button(action: onToggleSave) {
                Circle()
                    .stroke(Color.black, lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(isSaved ? .red : .black)
                    )
            }
            
            // Example/Bookmark button
            Button(action: {
                withAnimation(.spring()) {
                    showingExample.toggle()
                }
            }) {
                Circle()
                    .stroke(Color.black, lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: showingExample ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    )
            }
        }
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            // Grid button
            Button(action: {}) {
                Image(systemName: "grid.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Practice button (Üben equivalent)
            Button(action: onNext) {
                Text("学习")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            
            Spacer()
            
            // Profile button
            NavigationLink(destination: ProfileSettingsView()) {
                Image(systemName: "person.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Word Info Sheet
struct WordInfoSheet: View {
    let word: HSKWord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(word.hanzi)
                    .font(.system(size: 48, weight: .bold))
                
                Text("[\(word.pinyin)]")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                
                Text(word.meaning)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                
                if let example = word.example {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("例句 Example:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(example)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Text("HSK Level:")
                        .fontWeight(.semibold)
                    Text("\(word.hskLevel)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("词汇详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: View {
    let word: HSKWord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("分享词汇")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text(word.hanzi)
                    .font(.system(size: 32, weight: .bold))
                
                Text("[\(word.pinyin)]")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(word.meaning)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button("分享到微信") {
                // Share implementation
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            
            Button("取消") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

#Preview {
    HomeView()
}
