//
//  WordWidget.swift
//  WordWidget
//
//  Fixed minimalist widget implementation with containerBackground API
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - App Intents
struct NextWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Word"
    
    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
        let words = HSKDatabaseSeeder.shared.getSampleWords()
        let randomWord = words.randomElement()!
        
        userDefaults?.set(randomWord.hanzi, forKey: "current_hanzi")
        userDefaults?.set(randomWord.pinyin, forKey: "current_pinyin")
        userDefaults?.set(randomWord.meaning, forKey: "current_meaning")
        userDefaults?.set(randomWord.example, forKey: "current_example")
        userDefaults?.set(randomWord.hskLevel, forKey: "current_hsk_level")
        userDefaults?.set(Date(), forKey: "last_update")
        userDefaults?.synchronize()
        
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct SaveWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Save Word"
    
    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
        let currentHanzi = userDefaults?.string(forKey: "current_hanzi") ?? ""
        var savedWords = userDefaults?.stringArray(forKey: "widget_saved_words") ?? []
        
        if !savedWords.contains(currentHanzi) {
            savedWords.append(currentHanzi)
            userDefaults?.set(savedWords, forKey: "widget_saved_words")
            userDefaults?.synchronize()
        }
        
        return .result()
    }
}

// MARK: - Widget Entry
struct WordEntry: TimelineEntry {
    let date: Date
    let hanzi: String
    let pinyin: String
    let englishMeaning: String
    let vietnameseMeaning: String
    let example: String?
    let hskLevel: Int
    let isSaved: Bool
    let toneColors: [Color]
    
    static func placeholder() -> WordEntry {
        WordEntry(
            date: Date(),
            hanzi: "学习",
            pinyin: "xuéxí",
            englishMeaning: "to study, to learn",
            vietnameseMeaning: "học tập",
            example: "我喜欢学习中文",
            hskLevel: 4,
            isSaved: false,
            toneColors: [.yellow, .yellow]
        )
    }
}

// MARK: - Timeline Provider
struct WordTimelineProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    func placeholder(in context: Context) -> WordEntry {
        return WordEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> ()) {
        completion(getCurrentEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> ()) {
        let entries = [getCurrentEntry()]
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getCurrentEntry() -> WordEntry {
        let hanzi = userDefaults?.string(forKey: "current_hanzi") ?? "学"
        let pinyin = userDefaults?.string(forKey: "current_pinyin") ?? "xué"
        let meaning = userDefaults?.string(forKey: "current_meaning") ?? "to learn"
        let example = userDefaults?.string(forKey: "current_example")
        let hskLevel = userDefaults?.integer(forKey: "current_hsk_level") ?? 4
        
        let vietnameseMeaning = getVietnameseMeaning(meaning)
        let toneColors = getToneColors(pinyin)
        let savedWords = userDefaults?.stringArray(forKey: "widget_saved_words") ?? []
        let isSaved = savedWords.contains(hanzi)
        
        return WordEntry(
            date: Date(),
            hanzi: hanzi,
            pinyin: pinyin,
            englishMeaning: meaning,
            vietnameseMeaning: vietnameseMeaning,
            example: example,
            hskLevel: hskLevel,
            isSaved: isSaved,
            toneColors: toneColors
        )
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
    
    private func getToneColors(_ pinyin: String) -> [Color] {
        let syllables = pinyin.split(separator: " ")
        return syllables.map { syllable in
            let tone = detectTone(String(syllable))
            return getToneColor(tone)
        }
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
    
    private func getToneColor(_ tone: Int) -> Color {
        switch tone {
        case 1: return Color(red: 0.2, green: 0.7, blue: 0.2) // Green
        case 2: return Color(red: 0.9, green: 0.6, blue: 0.0) // Orange
        case 3: return Color(red: 0.1, green: 0.5, blue: 0.8) // Blue
        case 4: return Color(red: 0.8, green: 0.2, blue: 0.2) // Red
        default: return Color.primary
        }
    }
}

// MARK: - Widget Views
struct WordWidgetEntryView: View {
    var entry: WordEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallHomeWidget(entry: entry)
        case .systemMedium:
            MediumHomeWidget(entry: entry)
        case .systemLarge:
            LargeHomeWidget(entry: entry)
        case .accessoryCircular:
            CircularLockScreenWidget(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenWidget(entry: entry)
        case .accessoryInline:
            InlineLockScreenWidget(entry: entry)
        default:
            SmallHomeWidget(entry: entry)
        }
    }
}

// MARK: - Home Screen Widgets
struct SmallHomeWidget: View {
    let entry: WordEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text("HSK\(entry.hskLevel)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            Spacer()
            
            Text(entry.hanzi)
                .font(.system(size: 50, weight: .medium))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.6)
            
            HStack(spacing: 1) {
                ForEach(Array(entry.pinyin.split(separator: " ").enumerated()), id: \.offset) { index, syllable in
                    Text(String(syllable))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(index < entry.toneColors.count ? entry.toneColors[index] : .secondary)
                }
            }
            
            Spacer()
            
            Text(entry.vietnameseMeaning)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue.opacity(index == 2 ? 1.0 : 0.3))
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.bottom, 12)
        }
        .widgetURL(URL(string: "chineseword://widget/word/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.99, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct MediumHomeWidget: View {
    let entry: WordEntry
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("HSK \(entry.hskLevel)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Text(entry.hanzi)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 2) {
                    ForEach(Array(entry.pinyin.split(separator: " ").enumerated()), id: \.offset) { index, syllable in
                        Text(String(syllable))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(index < entry.toneColors.count ? entry.toneColors[index] : .secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.vietnameseMeaning)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                    
                    Text(entry.englishMeaning)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(intent: SaveWordIntent()) {
                        Image(systemName: entry.isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(entry.isSaved ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(intent: NextWordIntent()) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "chineseword://widget/word/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.95, green: 0.98, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LargeHomeWidget: View {
    let entry: WordEntry
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日词汇 📚")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if entry.isSaved {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Text("HSK \(entry.hskLevel)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            Text(entry.hanzi)
                .font(.system(size: 64, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                ForEach(Array(entry.pinyin.split(separator: " ").enumerated()), id: \.offset) { index, syllable in
                    Text(String(syllable))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(index < entry.toneColors.count ? entry.toneColors[index] : .secondary)
                }
            }
            
            VStack(spacing: 6) {
                Text(entry.vietnameseMeaning)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(entry.englishMeaning)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            if let example = entry.example {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 30)
                    
                    VStack(spacing: 4) {
                        Text(example)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Ví dụ • Example")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(intent: SaveWordIntent()) {
                    Label(entry.isSaved ? "Đã lưu" : "Lưu từ", systemImage: entry.isSaved ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundColor(entry.isSaved ? .red : .blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(intent: NextWordIntent()) {
                    Label("Từ tiếp theo", systemImage: "arrow.right.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .widgetURL(URL(string: "chineseword://widget/word/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.95, green: 0.98, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Lock Screen Widgets
struct CircularLockScreenWidget: View {
    let entry: WordEntry
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
            
            Text(entry.hanzi)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.5)
        }
        .widgetURL(URL(string: "chineseword://lockscreen/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct RectangularLockScreenWidget: View {
    let entry: WordEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Text(entry.hanzi)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.pinyin)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(entry.vietnameseMeaning)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("HSK\(entry.hskLevel)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .widgetURL(URL(string: "chineseword://lockscreen/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct InlineLockScreenWidget: View {
    let entry: WordEntry
    
    var body: some View {
        Text("\(entry.hanzi) • \(entry.vietnameseMeaning)")
            .font(.caption)
            .widgetURL(URL(string: "chineseword://lockscreen/\(entry.hanzi)"))
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

// MARK: - Widget Configuration
struct WordWidget: Widget {
    let kind: String = "WordWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordTimelineProvider()) { entry in
            WordWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Chinese Word • 中文词汇")
        .description("Học từ vựng tiếng Trung mọi lúc mọi nơi")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    WordWidget()
} timeline: {
    WordEntry.placeholder()
}

#Preview(as: .systemMedium) {
    WordWidget()
} timeline: {
    WordEntry.placeholder()
}

#Preview(as: .systemLarge) {
    WordWidget()
} timeline: {
    WordEntry.placeholder()
}

#Preview(as: .accessoryCircular) {
    WordWidget()
} timeline: {
    WordEntry.placeholder()
}

#Preview(as: .accessoryRectangular) {
    WordWidget()
} timeline: {
    WordEntry.placeholder()
}
