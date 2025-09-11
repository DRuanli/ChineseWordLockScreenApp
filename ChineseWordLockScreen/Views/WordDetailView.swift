//
//  WordDetailView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 11/9/25.
//

import SwiftUI
import AVFoundation



struct WordDetailView: View {
    let word: HSKWord
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var relatedWords: [HSKWord] = []
    @State private var synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Word Header Card
                    wordHeaderCard
                    
                    // Tab Selection
                    Picker("", selection: $selectedTab) {
                        Text("Tổng quan").tag(0)
                        Text("Ví dụ").tag(1)
                        Text("Liên quan").tag(2)
                        Text("Ghi nhớ").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Tab Content
                    tabContent
                }
            }
            .navigationTitle("Chi tiết từ vựng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
            .onAppear {
                loadRelatedWords()
            }
        }
    }
    
    private var wordHeaderCard: some View {
        VStack(spacing: 16) {
            // Hanzi with stroke order hint
            Text(word.hanzi)
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.primary)
            
            // Pinyin with tone marks
            HStack(spacing: 4) {
                Text(word.pinyin)
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Button(action: playPronunciation) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // Meaning
            Text(word.meaning)
                .font(.title3)
                .multilineTextAlignment(.center)
            
            // Vietnamese translation
            Text(getVietnameseTranslation())
                .font(.title3)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
            
            // HSK Level Badge
            Text("HSK \(word.hskLevel)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            overviewTab
        case 1:
            examplesTab
        case 2:
            relatedWordsTab
        case 3:
            mnemonicsTab
        default:
            EmptyView()
        }
    }
    
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Character components
            InfoSection(title: "Thành phần") {
                Text("Phân tích bộ thủ và cấu trúc chữ")
                    .foregroundColor(.secondary)
            }
            
            // Tone information
            InfoSection(title: "Thanh điệu") {
                ToneVisualizer(pinyin: word.pinyin)
            }
            
            // Part of speech
            InfoSection(title: "Từ loại") {
                Text(getPartOfSpeech())
                    .font(.body)
            }
            
            // Usage frequency
            InfoSection(title: "Tần suất sử dụng") {
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < 4 ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    Text("Thường dùng")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var examplesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let example = word.example {
                ExampleCard(
                    chinese: example,
                    pinyin: getPinyinForExample(example),
                    translation: getTranslationForExample(example)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var relatedWordsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !relatedWords.isEmpty {
                ForEach(relatedWords, id: \.hanzi) { relatedWord in
                    RelatedWordCard(word: relatedWord, mainWord: word)
                }
            } else {
                Text("Đang tải từ liên quan...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
    
    private var mnemonicsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Memory tips
            InfoSection(title: "Mẹo ghi nhớ") {
                VStack(alignment: .leading, spacing: 12) {
                    MnemonicTip(
                        icon: "lightbulb.fill",
                        tip: "Hãy tưởng tượng hình ảnh liên quan đến nghĩa của từ"
                    )
                    
                    MnemonicTip(
                        icon: "link",
                        tip: "Liên kết với từ có âm tương tự trong tiếng Việt"
                    )
                    
                    MnemonicTip(
                        icon: "pencil",
                        tip: "Viết từ này 10 lần để ghi nhớ nét chữ"
                    )
                }
            }
            
            // Story creation
            InfoSection(title: "Tạo câu chuyện") {
                Text("Hãy tạo một câu chuyện ngắn sử dụng từ '\(word.hanzi)' để ghi nhớ tốt hơn")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    private func playPronunciation() {
        let utterance = AVSpeechUtterance(string: word.hanzi)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
    
    private func getVietnameseTranslation() -> String {
        // Simple translation mapping
        let translations: [String: String] = [
            "wide": "rộng",
            "method": "phương pháp",
            "help": "giúp đỡ",
            "competition": "cuộc thi",
            "express": "biểu đạt",
            "change": "thay đổi",
            "participate": "tham gia",
            "be late": "muộn, trễ",
            "plan": "kế hoạch",
            "worry": "lo lắng"
        ]
        
        return translations[word.meaning.lowercased()] ?? word.meaning
    }
    
    private func getPartOfSpeech() -> String {
        if word.meaning.hasPrefix("to ") {
            return "Động từ"
        } else if word.meaning.contains("tion") || word.meaning.contains("ness") {
            return "Danh từ"
        } else {
            return "Tính từ/Danh từ"
        }
    }
    
    private func loadRelatedWords() {
        // Load words with similar components or meanings
        let allWords = HSKDatabaseSeeder.shared.getSampleWords()
        relatedWords = Array(allWords.filter { $0.hanzi != word.hanzi }.prefix(5))
    }
    
    private func getPinyinForExample(_ example: String) -> String {
        // Simplified - would need proper pinyin conversion
        return "Example pinyin"
    }
    
    private func getTranslationForExample(_ example: String) -> String {
        // Simplified translation
        return "Ví dụ dịch nghĩa"
    }
    
    private func getAdditionalExamples() -> [(chinese: String, pinyin: String, translation: String)] {
        // Return contextual examples
        return [
            (chinese: "这条路很宽", pinyin: "zhè tiáo lù hěn kuān", translation: "Con đường này rất rộng"),
            (chinese: "宽容的心", pinyin: "kuānróng de xīn", translation: "Tấm lòng khoan dung")
        ]
    }
}

// MARK: - Supporting Components
struct InfoSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ToneVisualizer: View {
    let pinyin: String
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...4, id: \.self) { tone in
                VStack(spacing: 4) {
                    ToneMark(tone: tone)
                    Text("Thanh \(tone)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .opacity(pinyin.contains(toneMarker(for: tone)) ? 1.0 : 0.3)
            }
        }
    }
    
    func toneMarker(for tone: Int) -> String {
        switch tone {
        case 1: return "ā"
        case 2: return "á"
        case 3: return "ǎ"
        case 4: return "à"
        default: return ""
        }
    }
}

struct ToneMark: View {
    let tone: Int
    
    var body: some View {
        ZStack {
            // Tone contour visualization
            Path { path in
                let width: CGFloat = 40
                let height: CGFloat = 30
                
                switch tone {
                case 1: // High level
                    path.move(to: CGPoint(x: 0, y: 5))
                    path.addLine(to: CGPoint(x: width, y: 5))
                case 2: // Rising
                    path.move(to: CGPoint(x: 0, y: height - 5))
                    path.addLine(to: CGPoint(x: width, y: 5))
                case 3: // Dipping
                    path.move(to: CGPoint(x: 0, y: 10))
                    path.addCurve(
                        to: CGPoint(x: width, y: 10),
                        control1: CGPoint(x: width/2, y: height - 5),
                        control2: CGPoint(x: width/2, y: height - 5)
                    )
                case 4: // Falling
                    path.move(to: CGPoint(x: 0, y: 5))
                    path.addLine(to: CGPoint(x: width, y: height - 5))
                default:
                    break
                }
            }
            .stroke(Color.blue, lineWidth: 3)
            .frame(width: 40, height: 30)
        }
    }
}

struct ExampleCard: View {
    let chinese: String
    let pinyin: String
    let translation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chinese)
                .font(.title3)
                .fontWeight(.medium)
            
            Text(pinyin)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(translation)
                .font(.body)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct RelatedWordCard: View {
    let word: HSKWord
    let mainWord: HSKWord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(word.hanzi)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(word.pinyin)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(word.meaning)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if hasCommonComponent() {
                Label("Cùng bộ", systemImage: "link")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    func hasCommonComponent() -> Bool {
        // Check if words share common radicals
        return word.hanzi.contains(where: { mainWord.hanzi.contains($0) })
    }
}

struct MnemonicTip: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(tip)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}
