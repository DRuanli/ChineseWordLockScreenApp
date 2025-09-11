//
//  QuizView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 11/9/25.
//

import SwiftUI
import AVFoundation

struct QuizView: View {
    let wordData: (word: HSKWord, state: WordLearningState, quizType: QuizType?)
    let onComplete: (Bool) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedAnswer: String?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var options: [String] = []
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Progress indicator
                ProgressView(value: 0.5)
                    .tint(.blue)
                    .padding(.horizontal)
                
                // Quiz content based on type
                if let quizType = wordData.quizType {
                    quizContent(for: quizType)
                } else {
                    // Default recognition quiz
                    quizContent(for: .recognition)
                }
                
                Spacer()
                
                // Submit button
                Button(action: checkAnswer) {
                    Text(showResult ? "Tiếp tục" : "Kiểm tra")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            showResult ?
                            (isCorrect ? Color.green : Color.red) :
                            Color.blue
                        )
                        .cornerRadius(12)
                }
                .disabled(selectedAnswer == nil && !showResult)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bỏ qua") {
                        onComplete(false)
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupQuiz()
            }
        }
    }
    
    @ViewBuilder
    private func quizContent(for type: QuizType) -> some View {
        switch type {
        case .recognition:
            recognitionQuiz
        case .recall:
            recallQuiz
        case .audio:
            audioQuiz
        case .context:
            contextQuiz
        }
    }
    
    private var recognitionQuiz: some View {
        VStack(spacing: 20) {
            Text("Nghĩa của từ này là gì?")
                .font(.headline)
            
            Text(wordData.word.hanzi)
                .font(.system(size: 80, weight: .bold))
                .padding()
            
            Text(wordData.word.pinyin)
                .font(.title3)
                .foregroundColor(.secondary)
            
            // Options
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OptionButton(
                        text: option,
                        isSelected: selectedAnswer == option,
                        isCorrect: showResult && option == wordData.word.meaning,
                        isWrong: showResult && selectedAnswer == option && option != wordData.word.meaning
                    ) {
                        selectedAnswer = option
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var recallQuiz: some View {
        VStack(spacing: 20) {
            Text("Chữ Hán nào có nghĩa này?")
                .font(.headline)
            
            Text(wordData.word.meaning)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            // Options with hanzi
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OptionButton(
                        text: option,
                        isSelected: selectedAnswer == option,
                        isCorrect: showResult && option == wordData.word.hanzi,
                        isWrong: showResult && selectedAnswer == option && option != wordData.word.hanzi
                    ) {
                        selectedAnswer = option
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var audioQuiz: some View {
        VStack(spacing: 20) {
            Text("Nghe và chọn chữ đúng")
                .font(.headline)
            
            Button(action: playAudio) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Options with hanzi
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OptionButton(
                        text: option,
                        isSelected: selectedAnswer == option,
                        isCorrect: showResult && option == wordData.word.hanzi,
                        isWrong: showResult && selectedAnswer == option && option != wordData.word.hanzi
                    ) {
                        selectedAnswer = option
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var contextQuiz: some View {
        VStack(spacing: 20) {
            Text("Chọn từ phù hợp để điền vào câu")
                .font(.headline)
            
            if let example = wordData.word.example {
                Text(example.replacingOccurrences(of: wordData.word.hanzi, with: "___"))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            // Options with hanzi
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OptionButton(
                        text: option,
                        isSelected: selectedAnswer == option,
                        isCorrect: showResult && option == wordData.word.hanzi,
                        isWrong: showResult && selectedAnswer == option && option != wordData.word.hanzi
                    ) {
                        selectedAnswer = option
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func setupQuiz() {
        guard let quizType = wordData.quizType else {
            setupRecognitionQuiz()
            return
        }
        
        switch quizType {
        case .recognition:
            setupRecognitionQuiz()
        case .recall:
            setupRecallQuiz()
        case .audio:
            setupAudioQuiz()
        case .context:
            setupContextQuiz()
        }
    }
    
    private func setupRecognitionQuiz() {
        // Get random wrong meanings
        let allWords = HSKDatabaseSeeder.shared.getSampleWords()
        var wrongOptions = allWords
            .filter { $0.hanzi != wordData.word.hanzi }
            .map { $0.meaning }
            .shuffled()
            .prefix(3)
            .map { String($0) }
        
        wrongOptions.append(wordData.word.meaning)
        options = wrongOptions.shuffled()
    }
    
    private func setupRecallQuiz() {
        // Get random wrong hanzi
        let allWords = HSKDatabaseSeeder.shared.getSampleWords()
        var wrongOptions = allWords
            .filter { $0.hanzi != wordData.word.hanzi }
            .map { $0.hanzi }
            .shuffled()
            .prefix(3)
            .map { String($0) }
        
        wrongOptions.append(wordData.word.hanzi)
        options = wrongOptions.shuffled()
    }
    
    private func setupAudioQuiz() {
        setupRecallQuiz()
        // Auto-play audio on appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            playAudio()
        }
    }
    
    private func setupContextQuiz() {
        setupRecallQuiz()
    }
    
    private func playAudio() {
        // Use text-to-speech for Chinese
        let utterance = AVSpeechUtterance(string: wordData.word.hanzi)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.4
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    private func checkAnswer() {
        if showResult {
            onComplete(isCorrect)
            dismiss()
        } else {
            withAnimation {
                showResult = true
                
                switch wordData.quizType {
                case .recognition:
                    isCorrect = selectedAnswer == wordData.word.meaning
                case .recall, .audio, .context:
                    isCorrect = selectedAnswer == wordData.word.hanzi
                default:
                    isCorrect = selectedAnswer == wordData.word.meaning
                }
            }
        }
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let action: () -> Void
    
    var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.3)
        } else if isWrong {
            return Color.red.opacity(0.3)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    var borderColor: Color {
        if isCorrect {
            return Color.green
        } else if isWrong {
            return Color.red
        } else if isSelected {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .disabled(isCorrect || isWrong)
    }
}
