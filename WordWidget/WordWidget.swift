//
//  WordWidget.swift
//  WordWidget
//
//  Created by Lê Nguyễn on 9/9/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), hanzi: "你", pinyin: "nǐ", meaning: "you")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Generate timeline entries for the next 24 hours, updating every hour
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = getEntry(for: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!))
        completion(timeline)
    }
    
    private func getEntry(for date: Date = Date()) -> SimpleEntry {
        let hanzi = userDefaults?.string(forKey: "current_hanzi") ?? "学"
        let pinyin = userDefaults?.string(forKey: "current_pinyin") ?? "xué"
        let meaning = userDefaults?.string(forKey: "current_meaning") ?? "to learn"
        
        return SimpleEntry(date: date, hanzi: hanzi, pinyin: pinyin, meaning: meaning)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let hanzi: String
    let pinyin: String
    let meaning: String
}

struct WordWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
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

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 8) {
            Text(entry.hanzi)
                .font(.system(size: 40, weight: .medium))
                .minimumScaleFactor(0.5)
            
            Text(entry.pinyin)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.teal.opacity(0.3), Color.yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.hanzi)
                    .font(.system(size: 50, weight: .medium))
                    .minimumScaleFactor(0.5)
                
                Text(entry.pinyin)
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(entry.meaning)
                    .font(.system(size: 18))
                    .multilineTextAlignment(.trailing)
                
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .font(.caption)
                    Text("HSK")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.teal.opacity(0.3), Color.yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 20) {
            Text(entry.hanzi)
                .font(.system(size: 80, weight: .medium))
                .minimumScaleFactor(0.5)
            
            Text(entry.pinyin)
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            
            Text(entry.meaning)
                .font(.system(size: 22))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            HStack {
                Image(systemName: "book.fill")
                Text("Chinese Word Lock Screen")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.teal.opacity(0.3), Color.yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct CircularWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack {
            Text(entry.hanzi)
                .font(.title2)
                .minimumScaleFactor(0.5)
        }
    }
}

struct RectangularWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.hanzi)
                .font(.title3)
                .fontWeight(.medium)
            Text(entry.pinyin)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InlineWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        Text("\(entry.hanzi) • \(entry.pinyin)")
    }
}



struct WordWidget: Widget {
    let kind: String = "WordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WordWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("中文词汇")
        .description("每日学习新的中文词汇")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    WordWidget()
} timeline: {
    SimpleEntry(date: .now, hanzi: "学", pinyin: "xué", meaning: "to learn")
    SimpleEntry(date: .now, hanzi: "好", pinyin: "hǎo", meaning: "good")
}
