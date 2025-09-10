//
//  WordWidget.swift
//  WordWidget
//
//  Enhanced version with Vietnamese support and interactive features
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Intent for Interaction
struct ChangeWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Change Word"
    
    func perform() async throws -> some IntentResult {
        // Update word in UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
        let words = HSKDatabaseSeeder.shared.getSampleWords()
        let randomWord = words.randomElement()!
        
        userDefaults?.set(randomWord.hanzi, forKey: "current_hanzi")
        userDefaults?.set(randomWord.pinyin, forKey: "current_pinyin")
        userDefaults?.set(randomWord.meaning, forKey: "current_meaning")
        userDefaults?.set(randomWord.example, forKey: "current_example")
        userDefaults?.set(Date(), forKey: "last_update")
        
        // Reload widget
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            hanzi: "宽",
            pinyin: "kuān",
            meaning: "wide",
            vietnameseMeaning: "rộng",
            example: "房间很宽",
            toneColors: [.green]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Update based on user preference (every unlock or timed)
        let updateFrequency = userDefaults?.integer(forKey: "widget_update_frequency") ?? 10
        
        // Generate entries for next updates
        for minuteOffset in stride(from: 0, to: 60, by: updateFrequency) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = getEntry(for: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!))
        completion(timeline)
    }
    
    private func getEntry(for date: Date = Date()) -> SimpleEntry {
        let hanzi = userDefaults?.string(forKey: "current_hanzi") ?? "学"
        let pinyin = userDefaults?.string(forKey: "current_pinyin") ?? "xué"
        let meaning = userDefaults?.string(forKey: "current_meaning") ?? "to learn"
        let example = userDefaults?.string(forKey: "current_example") ?? "学习中文"
        
        // Vietnamese translation
        let vietnameseMeaning = getVietnameseMeaning(meaning)
        
        // Get tone colors for pinyin
        let toneColors = getToneColors(pinyin)
        
        return SimpleEntry(
            date: date,
            hanzi: hanzi,
            pinyin: pinyin,
            meaning: meaning,
            vietnameseMeaning: vietnameseMeaning,
            example: example,
            toneColors: toneColors
        )
    }
    
    private func getVietnameseMeaning(_ english: String) -> String {
        let translations: [String: String] = [
            "wide": "rộng",
            "to learn": "học",
            "good": "tốt",
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
        case 3: return .blue
        case 4: return .red
        default: return .primary
        }
    }
}

// MARK: - Entry Model
struct SimpleEntry: TimelineEntry {
    let date: Date
    let hanzi: String
    let pinyin: String
    let meaning: String
    let vietnameseMeaning: String
    let example: String?
    let toneColors: [Color]
}

// MARK: - Widget Views
struct WordWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Chữ Hán lớn)
struct SmallWidgetView: View {
    let entry: SimpleEntry
    @State private var showPinyin = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                // Label
                HStack {
                    Text("今日词语")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                    Text("📚")
                        .font(.system(size: 10))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Spacer()
                
                // Main character (60-70% of space)
                Text(entry.hanzi)
                    .font(.custom("Noto Sans SC", size: 65))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .shadow(radius: 2)
                    .transition(.scale.combined(with: .opacity))
                
                // Pinyin (optional, tap to show)
                if showPinyin {
                    Text(entry.pinyin)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Navigation hint
                Image(systemName: "chevron.left.chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 8)
            }
        }
        .widgetURL(URL(string: "chineseword://widget/word/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            Color.clear
        }
        .onTapGesture {
            withAnimation {
                showPinyin.toggle()
            }
        }
    }
    
    var backgroundColors: [Color] {
        [Color(red: 0.1, green: 0.7, blue: 0.6),
         Color(red: 0.9, green: 0.8, blue: 0.3)]
    }
}

// MARK: - Medium Widget (Chữ + Pinyin + Nghĩa)
struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.teal.opacity(0.3), Color.yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 20) {
                // Left: Character section
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.hanzi)
                        .font(.custom("Noto Sans SC", size: 50))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                    
                    // Pinyin with tone colors
                    HStack(spacing: 2) {
                        ForEach(Array(entry.pinyin.split(separator: " ").enumerated()), id: \.offset) { index, syllable in
                            Text(String(syllable))
                                .font(.system(size: 18))
                                .foregroundColor(index < entry.toneColors.count ? entry.toneColors[index] : .primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Right: Meaning section
                VStack(alignment: .trailing, spacing: 8) {
                    Text(entry.vietnameseMeaning)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(entry.meaning)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .italic()
                    
                    // Audio button
                    Button(intent: ChangeWordIntent()) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "chineseword://widget/word/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

// MARK: - Large Widget (Full learning experience)
struct LargeWidgetView: View {
    let entry: SimpleEntry
    @State private var savedWords: Set<String> = []
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.teal.opacity(0.2), Color.yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("今日词语 📚")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("HSK 5")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button(intent: ChangeWordIntent()) {
                        Image(systemName: savedWords.contains(entry.hanzi) ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(savedWords.contains(entry.hanzi) ? .red : .gray)
                    }
                    .buttonStyle(.plain)
                }
                
                // Main content
                VStack(spacing: 12) {
                    // Character
                    Text(entry.hanzi)
                        .font(.custom("Noto Sans SC", size: 80))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // Pinyin with tones
                    HStack(spacing: 4) {
                        ForEach(Array(entry.pinyin.split(separator: " ").enumerated()), id: \.offset) { index, syllable in
                            Text(String(syllable))
                                .font(.system(size: 24))
                                .foregroundColor(index < entry.toneColors.count ? entry.toneColors[index] : .primary)
                        }
                    }
                    
                    // Meanings
                    VStack(spacing: 4) {
                        Text(entry.vietnameseMeaning)
                            .font(.system(size: 22, weight: .medium))
                        Text(entry.meaning)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    // Example sentence
                    if let example = entry.example {
                        VStack(spacing: 4) {
                            Divider()
                                .padding(.horizontal, 40)
                            
                            Text(example)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                            
                            Text("Căn phòng rất rộng")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .italic()
                        }
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Audio button
                    Button(intent: ChangeWordIntent()) {
                        Label("Phát âm", systemImage: "speaker.wave.2.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Spacer()
                    
                    // Next word button
                    Button(intent: ChangeWordIntent()) {
                        Label("Từ tiếp", systemImage: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "chineseword://widget/word/\(entry.hanzi)"))
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

// MARK: - Lock Screen Widgets
struct CircularWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
            
            VStack(spacing: 2) {
                Text(entry.hanzi)
                    .font(.system(size: 28, weight: .bold))
                    .minimumScaleFactor(0.5)
                
                Text("HSK")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RectangularWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.hanzi)
                    .font(.system(size: 22, weight: .medium))
                
                Spacer()
                
                Text("📚")
                    .font(.caption)
            }
            
            Text(entry.pinyin)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(entry.vietnameseMeaning)
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
}

struct InlineWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        Text("\(entry.hanzi) • \(entry.vietnameseMeaning)")
    }
}

// MARK: - Widget Configuration
struct WordWidget: Widget {
    let kind: String = "WordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WordWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("中文词汇")
        .description("锁屏学习中文词汇 - Học từ vựng tiếng Trung")
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

// MARK: - Preview
#Preview(as: .systemSmall) {
    WordWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        hanzi: "宽",
        pinyin: "kuān",
        meaning: "wide",
        vietnameseMeaning: "rộng",
        example: "房间很宽",
        toneColors: [.green]
    )
}

#Preview(as: .systemMedium) {
    WordWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        hanzi: "学习",
        pinyin: "xué xí",
        meaning: "to study",
        vietnameseMeaning: "học tập",
        example: "学习中文",
        toneColors: [.yellow, .yellow]
    )
}

#Preview(as: .systemLarge) {
    WordWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        hanzi: "帮助",
        pinyin: "bāng zhù",
        meaning: "to help",
        vietnameseMeaning: "giúp đỡ",
        example: "谢谢你的帮助",
        toneColors: [.green, .red]
    )
}
