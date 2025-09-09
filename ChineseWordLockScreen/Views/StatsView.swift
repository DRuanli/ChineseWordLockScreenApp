//
//  StatsView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedWord.savedDate, ascending: false)],
        animation: .default)
    private var savedWords: FetchedResults<SavedWord>
    
    @State private var selectedHSKLevel = 0
    
    var filteredWordCount: Int {
        if selectedHSKLevel == 0 {
            return savedWords.count
        }
        return savedWords.filter { $0.hskLevel == selectedHSKLevel }.count
    }
    
    var favoriteCount: Int {
        savedWords.filter { $0.isFavorite }.count
    }
    
    var totalReviews: Int {
        savedWords.reduce(0) { $0 + Int($1.reviewCount) }
    }
    
    var hskDistribution: [(level: Int, count: Int)] {
        var distribution: [Int: Int] = [:]
        for word in savedWords {
            distribution[Int(word.hskLevel), default: 0] += 1
        }
        return distribution.sorted { $0.key < $1.key }.map { (level: $0.key, count: $0.value) }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview Cards
                    HStack(spacing: 15) {
                        StatCard(
                            title: "总词汇",
                            value: "\(savedWords.count)",
                            icon: "book.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "收藏",
                            value: "\(favoriteCount)",
                            icon: "star.fill",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        StatCard(
                            title: "复习次数",
                            value: "\(totalReviews)",
                            icon: "arrow.clockwise",
                            color: .green
                        )
                        
                        StatCard(
                            title: "今日学习",
                            value: "\(getTodayCount())",
                            icon: "calendar",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // HSK Level Distribution
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HSK级别分布")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(hskDistribution, id: \.level) { item in
                                HStack {
                                    Text("HSK \(item.level)")
                                        .frame(width: 60, alignment: .leading)
                                        .font(.caption)
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(height: 25)
                                                .cornerRadius(5)
                                            
                                            Rectangle()
                                                .fill(colorForHSKLevel(item.level))
                                                .frame(
                                                    width: max(0, CGFloat(item.count) / CGFloat(max(savedWords.count, 1)) * geometry.size.width),
                                                    height: 25
                                                )
                                                .cornerRadius(5)
                                            
                                            Text("\(item.count)")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                        }
                                    }
                                    .frame(height: 25)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // Study Streak
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("学习连续天数")
                                .font(.headline)
                        }
                        
                        Text("\(calculateStreak())")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("继续努力！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("学习统计")
        }
    }
    
    private func getTodayCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return savedWords.filter {
            guard let savedDate = $0.savedDate else { return false }
            return calendar.startOfDay(for: savedDate) == today
        }.count
    }
    
    private func calculateStreak() -> Int {
        // Simple streak calculation - counts consecutive days with saved words
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let hasWordOnDate = savedWords.contains { word in
                guard let savedDate = word.savedDate else { return false }
                return calendar.startOfDay(for: savedDate) == currentDate
            }
            
            if hasWordOnDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func colorForHSKLevel(_ level: Int) -> Color {
        switch level {
        case 3: return .green
        case 4: return .blue
        case 5: return .orange
        case 6: return .red
        default: return .gray
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}
