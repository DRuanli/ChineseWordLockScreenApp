//
//  QuickStudyView.swift
//  ChineseWordLockScreen
//
//  Quick study session for focused learning
//

import SwiftUI

struct QuickStudyView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var currentWords: [HSKWord] = []
    @State private var currentIndex = 0
    @State private var studyMode: StudyMode = .recognition
    @State private var showingResult = false
    @State private var sessionStats = SessionStats()
    @State private var timeRemaining = 300 // 5 minutes
    @State private var timer: Timer?
    
    enum StudyMode: String, CaseIterable {
        case recognition = "Nhận diện"
        case recall = "Ghi nhớ"
        case listening = "Nghe hiểu"
        
        var icon: String {
            switch self {
            case .recognition: return "eye.fill"
            case .recall: return "brain.head.profile"
            case .listening: return "ear.fill"
            }
        }
    }
    
    struct SessionStats {
        var correct = 0
        var incorrect = 0
        var total = 0
        
        var accuracy: Double {
            guard total > 0 else { return 0 }
            return Double(correct) / Double(total)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("F8F9FA")
                    .ignoresSafeArea()
                
                if currentWords.isEmpty {
                    setupView
                } else if showingResult {
                    resultView
                } else {
                    studyView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !currentWords.isEmpty && !showingResult {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(timeRemaining / 60):\(String(format: "%02d", timeRemaining % 60))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(timeRemaining < 60 ? .red : .primary)
                            
                            Text("\(currentIndex + 1)/\(currentWords.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            setupSession()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Setup View
    var setupView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Học nhanh 5 phút")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Chọn chế độ học tập")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 15) {
                ForEach(StudyMode.allCases, id: \.self) { mode in
                    Button(action: {
                        studyMode = mode
                        startSession()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: mode.icon)
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(modeDescription(mode))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Study View
    var studyView: some View {
        VStack(spacing: 20) {
            // Progress bar
            ProgressView(value: Double(currentIndex), total: Double(currentWords.count))
                .tint(.blue)
                .scaleEffect(x: 1, y: 2)
                .padding(.horizontal)
            
            // Word card
            if currentIndex < currentWords.count {
                StudyWordCard(
                    word: currentWords[currentIndex],
                    mode: studyMode,
                    onAnswer: handleAnswer
                )
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    // MARK: - Result View
    var resultView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: sessionStats.accuracy >= 0.8 ? "checkmark.circle.fill" : "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(sessionStats.accuracy >= 0.8 ? .green : .orange)
                
                Text("Hoàn thành!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Kết quả học tập của bạn")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 15) {
                ResultCard(
                    title: "Độ chính xác",
                    value: "\(Int(sessionStats.accuracy * 100))%",
                    color: sessionStats.accuracy >= 0.8 ? .green : .orange
                )
                
                HStack(spacing: 15) {
                    ResultCard(
                        title: "Đúng",
                        value: "\(sessionStats.correct)",
                        color: .green
                    )
                    
                    ResultCard(
                        title: "Sai",
                        value: "\(sessionStats.incorrect)",
                        color: .red
                    )
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: { startSession() }) {
                    Text("Học tiếp")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    Text("Hoàn thành")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    private func setupSession() {
        // Get random words for the session
        let allWords = HSKDatabaseSeeder.shared.getSampleWords()
        currentWords = Array(allWords.shuffled().prefix(20))
    }
    
    private func startSession() {
        currentIndex = 0
        sessionStats = SessionStats()
        showingResult = false
        timeRemaining = 300
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endSession()
            }
        }
    }
    
    private func handleAnswer(_ isCorrect: Bool) {
        sessionStats.total += 1
        if isCorrect {
            sessionStats.correct += 1
        } else {
            sessionStats.incorrect += 1
        }
        
        if currentIndex < currentWords.count - 1 {
            currentIndex += 1
        } else {
            endSession()
        }
    }
    
    private func endSession() {
        timer?.invalidate()
        timer = nil
        showingResult = true
    }
    
    private func modeDescription(_ mode: StudyMode) -> String {
        switch mode {
        case .recognition:
            return "Nhìn chữ Hán, chọn nghĩa đúng"
        case .recall:
            return "Nhìn nghĩa, nhớ lại chữ Hán"
        case .listening:
            return "Nghe phát âm, chọn chữ đúng"
        }
    }
}

// MARK: - Study Word Card
struct StudyWordCard: View {
    let word: HSKWord
    let mode: QuickStudyView.StudyMode
    let onAnswer: (Bool) -> Void
    
    @State private var selectedAnswer: String?
    @State private var showingResult = false
    @State private var options: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Question
            VStack(spacing: 15) {
                switch mode {
                case .recognition:
                    Text(word.hanzi)
                        .font(.system(size: 80))
                        .fontWeight(.medium)
                    
                    Text(word.pinyin)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                case .recall:
                    Text(word.meaning)
                        .font(.title)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                case .listening:
                    Button(action: playAudio) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Nhấn để nghe")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minHeight: 150)
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: { selectAnswer(option) }) {
                        HStack {
                            Text(option)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if showingResult {
                                Image(systemName: getAnswerIcon(option))
                                    .foregroundColor(getAnswerColor(option))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(getAnswerBackground(option))
                                .stroke(getAnswerBorder(option), lineWidth: 2)
                        )
                    }
                    .disabled(showingResult)
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
        .onAppear {
            generateOptions()
        }
    }
    
    private func generateOptions() {
        let correctAnswer: String
        
        switch mode {
        case .recognition:
            correctAnswer = word.meaning
        case .recall:
            correctAnswer = word.hanzi
        case .listening:
            correctAnswer = word.hanzi
        }
        
        // Generate wrong options
        let allWords = HSKDatabaseSeeder.shared.getSampleWords()
        var wrongOptions: [String] = []
        
        while wrongOptions.count < 3 {
            let randomWord = allWords.randomElement()!
            let option: String
            
            switch mode {
            case .recognition:
                option = randomWord.meaning
            case .recall, .listening:
                option = randomWord.hanzi
            }
            
            if option != correctAnswer && !wrongOptions.contains(option) {
                wrongOptions.append(option)
            }
        }
        
        options = ([correctAnswer] + wrongOptions).shuffled()
    }
    
    private func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        showingResult = true
        
        let isCorrect: Bool
        switch mode {
        case .recognition:
            isCorrect = answer == word.meaning
        case .recall, .listening:
            isCorrect = answer == word.hanzi
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onAnswer(isCorrect)
            resetCard()
        }
    }
    
    private func resetCard() {
        selectedAnswer = nil
        showingResult = false
        generateOptions()
    }
    
    private func playAudio() {
        // Audio playback implementation
    }
    
    private func getAnswerIcon(_ option: String) -> String {
        if isCorrectAnswer(option) {
            return "checkmark.circle.fill"
        } else if option == selectedAnswer {
            return "xmark.circle.fill"
        }
        return ""
    }
    
    private func getAnswerColor(_ option: String) -> Color {
        if isCorrectAnswer(option) {
            return .green
        } else if option == selectedAnswer {
            return .red
        }
        return .clear
    }
    
    private func getAnswerBackground(_ option: String) -> Color {
        if !showingResult {
            return Color.gray.opacity(0.05)
        }
        
        if isCorrectAnswer(option) {
            return Color.green.opacity(0.1)
        } else if option == selectedAnswer {
            return Color.red.opacity(0.1)
        }
        return Color.gray.opacity(0.05)
    }
    
    private func getAnswerBorder(_ option: String) -> Color {
        if !showingResult {
            return Color.gray.opacity(0.2)
        }
        
        if isCorrectAnswer(option) {
            return Color.green
        } else if option == selectedAnswer {
            return Color.red
        }
        return Color.gray.opacity(0.2)
    }
    
    private func isCorrectAnswer(_ option: String) -> Bool {
        switch mode {
        case .recognition:
            return option == word.meaning
        case .recall, .listening:
            return option == word.hanzi
        }
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    QuickStudyView()
}
