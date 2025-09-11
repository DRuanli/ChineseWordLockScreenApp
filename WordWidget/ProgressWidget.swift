//
//  ProgressWidget.swift
//  WordWidget
//
//  Fixed progress tracking widget with containerBackground API
//

import WidgetKit
import SwiftUI

// MARK: - Progress Entry
struct StudyProgressEntry: TimelineEntry {
    let date: Date
    let learned: Int
    let goal: Int
    let streak: Int
    let weeklyProgress: [Int]
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(learned) / Double(goal), 1.0)
    }
    
    var isGoalMet: Bool {
        learned >= goal
    }
}

// MARK: - Progress Provider
struct StudyProgressProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    func placeholder(in context: Context) -> StudyProgressEntry {
        StudyProgressEntry(
            date: Date(),
            learned: 8,
            goal: 10,
            streak: 5,
            weeklyProgress: [12, 8, 15, 10, 6, 8, 8]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StudyProgressEntry) -> ()) {
        completion(loadProgress())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyProgressEntry>) -> ()) {
        let entry = loadProgress()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadProgress() -> StudyProgressEntry {
        let learned = userDefaults?.integer(forKey: "today_count") ?? 0
        let goal = userDefaults?.integer(forKey: "daily_goal") ?? 10
        let streak = userDefaults?.integer(forKey: "streak_count") ?? 0
        let weeklyProgress = userDefaults?.array(forKey: "weekly_progress") as? [Int] ?? [0, 0, 0, 0, 0, 0, learned]
        
        return StudyProgressEntry(
            date: Date(),
            learned: learned,
            goal: goal,
            streak: streak,
            weeklyProgress: weeklyProgress
        )
    }
}

// MARK: - Progress Widget View
struct ProgressWidgetEntryView: View {
    var entry: StudyProgressEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallProgressView(entry: entry)
        case .systemMedium:
            MediumProgressView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularProgressView(entry: entry)
        default:
            SmallProgressView(entry: entry)
        }
    }
}

// MARK: - Progress Views
struct SmallProgressView: View {
    let entry: StudyProgressEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if entry.isGoalMet {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("学习")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(entry.isGoalMet ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(entry.learned)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("/\(entry.goal)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("\(entry.streak) ngày")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Hôm nay")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "chineseword://progress"))
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct MediumProgressView: View {
    let entry: StudyProgressEntry
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(entry.isGoalMet ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 1) {
                        Text("\(entry.learned)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("/\(entry.goal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(spacing: 4) {
                    if entry.isGoalMet {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Đạt mục tiêu")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Còn \(entry.goal - entry.learned) từ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(entry.streak) ngày")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tuần này")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<entry.weeklyProgress.count, id: \.self) { index in
                        let dayProgress = entry.weeklyProgress[index]
                        let height = max(8, CGFloat(dayProgress) / 20 * 40)
                        
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index == entry.weeklyProgress.count - 1 ? (entry.isGoalMet ? Color.green : Color.blue) : Color.gray.opacity(0.3))
                                .frame(width: 12, height: height)
                            
                            Text(dayAbbreviation(for: index))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text("Từ đã học")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "chineseword://progress"))
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func dayAbbreviation(for index: Int) -> String {
        let days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        let today = Calendar.current.component(.weekday, from: Date())
        let dayIndex = (today - 2 + index - entry.weeklyProgress.count + 1 + 7) % 7
        return days[dayIndex]
    }
}

struct AccessoryCircularProgressView: View {
    let entry: StudyProgressEntry
    
    var body: some View {
        ZStack {
            Circle()
                .fill(entry.isGoalMet ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
            
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(entry.isGoalMet ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 1) {
                Text("\(entry.learned)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                if entry.isGoalMet {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8))
                        .foregroundColor(.green)
                } else {
                    Text("/\(entry.goal)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .widgetURL(URL(string: "chineseword://progress"))
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Widget Configuration
struct ProgressWidget: Widget {
    let kind: String = "ProgressWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyProgressProvider()) { entry in
            ProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("学习进度 • Progress")
        .description("Theo dõi tiến độ học từ vựng hàng ngày")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    ProgressWidget()
} timeline: {
    StudyProgressEntry(
        date: Date(),
        learned: 8,
        goal: 10,
        streak: 5,
        weeklyProgress: [12, 8, 15, 10, 6, 8, 8]
    )
}

#Preview(as: .systemMedium) {
    ProgressWidget()
} timeline: {
    StudyProgressEntry(
        date: Date(),
        learned: 8,
        goal: 10,
        streak: 5,
        weeklyProgress: [12, 8, 15, 10, 6, 8, 8]
    )
}

#Preview(as: .accessoryCircular) {
    ProgressWidget()
} timeline: {
    StudyProgressEntry(
        date: Date(),
        learned: 8,
        goal: 10,
        streak: 5,
        weeklyProgress: [12, 8, 15, 10, 6, 8, 8]
    )
}
