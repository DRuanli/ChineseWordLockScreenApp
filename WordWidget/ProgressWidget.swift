//
//  ProgressWidget.swift
//  WordWidget
//
//  Created by Lê Nguyễn on 9/9/25.
//

import WidgetKit
import SwiftUI

// MARK: - Entry
struct ProgressEntry: TimelineEntry {
    let date: Date
    let learned: Int
    let goal: Int
}

// MARK: - Provider
struct ProgressProvider: TimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(date: Date(), learned: 12, goal: 20)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> ()) {
        let entry = loadProgress()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> ()) {
        let entry = loadProgress()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadProgress() -> ProgressEntry {
        let learned = userDefaults?.integer(forKey: "words_learned_today") ?? 0
        let goal = userDefaults?.integer(forKey: "daily_goal") ?? 20
        return ProgressEntry(date: Date(), learned: learned, goal: goal)
    }
}

// MARK: - Widget View
struct ProgressWidgetEntryView: View {
    var entry: ProgressEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            VStack(spacing: 8) {
                Text("Tiến độ hôm nay")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: Double(entry.learned), total: Double(entry.goal))
                    .progressViewStyle(.linear)
                
                Text("\(entry.learned)/\(entry.goal) từ")
                    .font(.footnote)
                    .foregroundColor(.primary)
            }
            .padding()
            
        case .systemMedium:
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tiến độ học 📈")
                        .font(.headline)
                    
                    ProgressView(value: Double(entry.learned), total: Double(entry.goal))
                        .progressViewStyle(.linear)
                        .tint(.blue)
                    
                    Text("Hôm nay: \(entry.learned)/\(entry.goal) từ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            
        default:
            VStack {
                Text("Tiến độ học")
                Text("\(entry.learned)/\(entry.goal)")
            }
        }
    }
}

// MARK: - Widget
struct ProgressWidget: Widget {
    let kind: String = "ProgressWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tiến độ học tập")
        .description("Xem tiến độ học từ vựng hàng ngày.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
