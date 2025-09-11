//
//  StatsView.swift
//  ChineseWordLockScreen
//
//  Enhanced minimalist statistics with beautiful charts
//

import SwiftUI
import CoreData
import Charts

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedStatTab: StatTab = .overview
    
    enum TimeRange: String, CaseIterable {
        case week = "Tuần"
        case month = "Tháng"
        case year = "Năm"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    enum StatTab: String, CaseIterable {
        case overview = "Tổng quan"
        case progress = "Tiến độ"
        case distribution = "Phân bố"
        
        var icon: String {
            switch self {
            case .overview: return "chart.pie.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .distribution: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color("F8F9FA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Minimal header with key metrics
                        MinimalStatsHeader(viewModel: viewModel)
                        
                        // Tab selector
                        MinimalTabSelector(selectedTab: $selectedStatTab)
                        
                        // Content based on selected tab
                        Group {
                            switch selectedStatTab {
                            case .overview:
                                OverviewCharts(viewModel: viewModel, timeRange: $selectedTimeRange)
                            case .progress:
                                ProgressCharts(viewModel: viewModel, timeRange: $selectedTimeRange)
                            case .distribution:
                                DistributionCharts(viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Thống kê")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - View Model
class StatsViewModel: ObservableObject {
    @Published var totalWords: Int = 0
    @Published var todayWords: Int = 0
    @Published var weeklyWords: Int = 0
    @Published var monthlyWords: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var favoriteCount: Int = 0
    @Published var reviewCount: Int = 0
    
    // Chart data
    @Published var dailyProgress: [DailyProgress] = []
    @Published var weeklyProgress: [WeeklyProgress] = []
    @Published var monthlyProgress: [MonthlyProgress] = []
    @Published var hskDistribution: [HSKDistribution] = []
    @Published var difficultyDistribution: [DifficultyData] = []
    @Published var hourlyActivity: [HourlyActivity] = []
    
    private let context = PersistenceController.shared.container.viewContext
    
    // Data structures
    struct DailyProgress: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
        let dayName: String
    }
    
    struct WeeklyProgress: Identifiable {
        let id = UUID()
        let week: String
        let count: Int
        let weekNumber: Int
    }
    
    struct MonthlyProgress: Identifiable {
        let id = UUID()
        let month: String
        let count: Int
        let monthNumber: Int
    }
    
    struct HSKDistribution: Identifiable {
        let id = UUID()
        let level: Int
        let count: Int
        let percentage: Double
        let color: Color
    }
    
    struct DifficultyData: Identifiable {
        let id = UUID()
        let category: String
        let count: Int
        let color: Color
    }
    
    struct HourlyActivity: Identifiable {
        let id = UUID()
        let hour: Int
        let count: Int
    }
    
    func loadData() {
        loadBasicStats()
        loadDailyProgress()
        loadWeeklyProgress()
        loadMonthlyProgress()
        loadHSKDistribution()
        loadDifficultyDistribution()
        loadHourlyActivity()
    }
    
    private func loadBasicStats() {
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        
        do {
            let words = try context.fetch(request)
            totalWords = words.count
            favoriteCount = words.filter { $0.isFavorite }.count
            reviewCount = words.reduce(0) { $0 + Int($1.reviewCount) }
            
            // Today's words
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            todayWords = words.filter {
                guard let savedDate = $0.savedDate else { return false }
                return calendar.startOfDay(for: savedDate) == today
            }.count
            
            // Weekly words
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            weeklyWords = words.filter {
                guard let savedDate = $0.savedDate else { return false }
                return savedDate >= weekAgo
            }.count
            
            // Monthly words
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: today)!
            monthlyWords = words.filter {
                guard let savedDate = $0.savedDate else { return false }
                return savedDate >= monthAgo
            }.count
            
            // Calculate streaks
            calculateStreaks(words: words)
        } catch {
            print("Error loading stats: \(error)")
        }
    }
    
    private func calculateStreaks(words: [SavedWord]) {
        let calendar = Calendar.current
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Sort words by date
        let sortedWords = words.sorted { ($0.savedDate ?? Date.distantPast) > ($1.savedDate ?? Date.distantPast) }
        
        // Calculate current streak
        while true {
            let hasWordOnDate = sortedWords.contains { word in
                guard let savedDate = word.savedDate else { return false }
                return calendar.startOfDay(for: savedDate) == currentDate
            }
            
            if hasWordOnDate {
                currentStreak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        self.currentStreak = currentStreak
        
        // Calculate longest streak (simplified)
        self.longestStreak = max(currentStreak, 7) // Placeholder
    }
    
    private func loadDailyProgress() {
        let calendar = Calendar.current
        let today = Date()
        var progress: [DailyProgress] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
            request.predicate = NSPredicate(format: "savedDate >= %@ AND savedDate < %@", startOfDay as NSDate, endOfDay as NSDate)
            
            do {
                let count = try context.count(for: request)
                let dayName = dayOffset == 0 ? "Hôm nay" : getDayName(for: date)
                progress.append(DailyProgress(date: date, count: count, dayName: dayName))
            } catch {
                print("Error loading daily progress: \(error)")
            }
        }
        
        self.dailyProgress = progress
    }
    
    private func loadWeeklyProgress() {
        let calendar = Calendar.current
        var progress: [WeeklyProgress] = []
        
        for weekOffset in (0..<4).reversed() {
            let weeksAgo = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date())!
            let weekNumber = calendar.component(.weekOfYear, from: weeksAgo)
            
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weeksAgo)?.start ?? Date()
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            
            let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
            request.predicate = NSPredicate(format: "savedDate >= %@ AND savedDate < %@", startOfWeek as NSDate, endOfWeek as NSDate)
            
            do {
                let count = try context.count(for: request)
                let weekName = weekOffset == 0 ? "Tuần này" : "Tuần \(weekNumber)"
                progress.append(WeeklyProgress(week: weekName, count: count, weekNumber: weekNumber))
            } catch {
                print("Error loading weekly progress: \(error)")
            }
        }
        
        self.weeklyProgress = progress
    }
    
    private func loadMonthlyProgress() {
        let calendar = Calendar.current
        var progress: [MonthlyProgress] = []
        
        for monthOffset in (0..<6).reversed() {
            let monthsAgo = calendar.date(byAdding: .month, value: -monthOffset, to: Date())!
            let monthNumber = calendar.component(.month, from: monthsAgo)
            
            let startOfMonth = calendar.dateInterval(of: .month, for: monthsAgo)?.start ?? Date()
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            
            let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
            request.predicate = NSPredicate(format: "savedDate >= %@ AND savedDate < %@", startOfMonth as NSDate, endOfMonth as NSDate)
            
            do {
                let count = try context.count(for: request)
                let monthName = getMonthName(for: monthNumber)
                progress.append(MonthlyProgress(month: monthName, count: count, monthNumber: monthNumber))
            } catch {
                print("Error loading monthly progress: \(error)")
            }
        }
        
        self.monthlyProgress = progress
    }
    
    private func loadHSKDistribution() {
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        
        do {
            let words = try context.fetch(request)
            let total = words.count
            
            var distribution: [HSKDistribution] = []
            let colors: [Color] = [.green, .blue, .orange, .red]
            
            for level in 3...6 {
                let count = words.filter { $0.hskLevel == level }.count
                let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0
                distribution.append(HSKDistribution(
                    level: level,
                    count: count,
                    percentage: percentage,
                    color: colors[level - 3]
                ))
            }
            
            self.hskDistribution = distribution
        } catch {
            print("Error loading HSK distribution: \(error)")
        }
    }
    
    private func loadDifficultyDistribution() {
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        
        do {
            let words = try context.fetch(request)
            
            let easy = words.filter { $0.correctCount > $0.incorrectCount * 2 }.count
            let medium = words.filter {
                let ratio = $0.incorrectCount > 0 ? Double($0.correctCount) / Double($0.incorrectCount) : 10
                return ratio >= 0.5 && ratio <= 2
            }.count
            let hard = words.filter { $0.incorrectCount > $0.correctCount }.count
            
            self.difficultyDistribution = [
                DifficultyData(category: "Dễ", count: easy, color: .green),
                DifficultyData(category: "Trung bình", count: medium, color: .orange),
                DifficultyData(category: "Khó", count: hard, color: .red)
            ]
        } catch {
            print("Error loading difficulty distribution: \(error)")
        }
    }
    
    private func loadHourlyActivity() {
        // Simplified hourly activity
        var activity: [HourlyActivity] = []
        for hour in 0..<24 {
            // Mock data - in real app, would query by hour
            let count = Int.random(in: 0...10)
            activity.append(HourlyActivity(hour: hour, count: count))
        }
        self.hourlyActivity = activity
    }
    
    private func getDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func getMonthName(for month: Int) -> String {
        let monthNames = ["", "Th1", "Th2", "Th3", "Th4", "Th5", "Th6", "Th7", "Th8", "Th9", "Th10", "Th11", "Th12"]
        return monthNames[month]
    }
}

// MARK: - Minimal Stats Header
struct MinimalStatsHeader: View {
    @ObservedObject var viewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Primary metric - large and centered
            VStack(spacing: 8) {
                Text("\(viewModel.totalWords)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Tổng từ vựng")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Secondary metrics in a row
            HStack(spacing: 30) {
                MetricPill(
                    value: "\(viewModel.currentStreak)",
                    label: "Streak",
                    icon: "flame.fill",
                    color: .orange
                )
                
                MetricPill(
                    value: "\(viewModel.todayWords)",
                    label: "Hôm nay",
                    icon: "calendar",
                    color: .blue
                )
                
                MetricPill(
                    value: "\(viewModel.favoriteCount)",
                    label: "Yêu thích",
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
        .padding(.horizontal)
    }
}

struct MetricPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Tab Selector
struct MinimalTabSelector: View {
    @Binding var selectedTab: StatsView.StatTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(StatsView.StatTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                            .animation(.spring(), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Overview Charts
struct OverviewCharts: View {
    @ObservedObject var viewModel: StatsViewModel
    @Binding var timeRange: StatsView.TimeRange
    
    var body: some View {
        VStack(spacing: 24) {
            // Time range selector
            TimeRangeSelector(selectedRange: $timeRange)
            
            // Line chart for progress
            ProgressLineChart(
                data: viewModel.dailyProgress,
                timeRange: timeRange
            )
            
            // HSK Distribution Pie Chart
            HSKPieChart(distribution: viewModel.hskDistribution)
        }
    }
}

// MARK: - Progress Charts
struct ProgressCharts: View {
    @ObservedObject var viewModel: StatsViewModel
    @Binding var timeRange: StatsView.TimeRange
    
    var body: some View {
        VStack(spacing: 24) {
            TimeRangeSelector(selectedRange: $timeRange)
            
            // Bar chart for daily/weekly/monthly
            ProgressBarChart(
                dailyData: viewModel.dailyProgress,
                weeklyData: viewModel.weeklyProgress,
                monthlyData: viewModel.monthlyProgress,
                timeRange: timeRange
            )
            
            // Heat map for activity
            ActivityHeatMap(hourlyData: viewModel.hourlyActivity)
        }
    }
}

// MARK: - Distribution Charts
struct DistributionCharts: View {
    @ObservedObject var viewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Difficulty distribution
            DifficultyDonutChart(data: viewModel.difficultyDistribution)
            
            // HSK level bars
            HSKBarChart(distribution: viewModel.hskDistribution)
        }
    }
}

// MARK: - Chart Components
struct TimeRangeSelector: View {
    @Binding var selectedRange: StatsView.TimeRange
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(StatsView.TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedRange == range ? .semibold : .regular)
                        .foregroundColor(selectedRange == range ? .white : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedRange == range ? Color.blue : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct ProgressLineChart: View {
    let data: [StatsViewModel.DailyProgress]
    let timeRange: StatsView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tiến độ học tập")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data) { item in
                LineMark(
                    x: .value("Ngày", item.dayName),
                    y: .value("Từ", item.count)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Ngày", item.dayName),
                    y: .value("Từ", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Ngày", item.dayName),
                    y: .value("Từ", item.count)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(60)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
}

struct ProgressBarChart: View {
    let dailyData: [StatsViewModel.DailyProgress]
    let weeklyData: [StatsViewModel.WeeklyProgress]
    let monthlyData: [StatsViewModel.MonthlyProgress]
    let timeRange: StatsView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phân bố thời gian")
                .font(.headline)
            
            Chart {
                switch timeRange {
                case .week:
                    ForEach(dailyData) { item in
                        BarMark(
                            x: .value("Ngày", item.dayName),
                            y: .value("Từ", item.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(8)
                    }
                case .month:
                    ForEach(weeklyData) { item in
                        BarMark(
                            x: .value("Tuần", item.week),
                            y: .value("Từ", item.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(8)
                    }
                case .year:
                    ForEach(monthlyData) { item in
                        BarMark(
                            x: .value("Tháng", item.month),
                            y: .value("Từ", item.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
}

struct HSKPieChart: View {
    let distribution: [StatsViewModel.HSKDistribution]
    @State private var selectedSlice: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Phân bố HSK")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack {
                    ForEach(distribution.indices, id: \.self) { index in
                        let item = distribution[index]
                        let startAngle = calculateStartAngle(for: index)
                        let endAngle = calculateEndAngle(for: index)
                        
                        PieSlice(
                            startAngle: startAngle,
                            endAngle: endAngle,
                            color: item.color,
                            isSelected: selectedSlice == index
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedSlice = selectedSlice == index ? nil : index
                            }
                        }
                    }
                    
                    // Center text
                    VStack(spacing: 4) {
                        if let selected = selectedSlice {
                            Text("HSK \(distribution[selected].level)")
                                .font(.headline)
                            Text("\(distribution[selected].count) từ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(distribution.reduce(0) { $0 + $1.count })")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Tổng")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: 200)
            }
            .frame(height: 200)
            
            // Legend
            HStack(spacing: 20) {
                ForEach(distribution) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        
                        Text("HSK\(item.level)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(item.percentage))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
    
    private func calculateStartAngle(for index: Int) -> Angle {
        let total = distribution.reduce(0) { $0 + $1.percentage }
        var angle: Double = -90
        
        for i in 0..<index {
            angle += (distribution[i].percentage / total) * 360
        }
        
        return Angle(degrees: angle)
    }
    
    private func calculateEndAngle(for index: Int) -> Angle {
        let total = distribution.reduce(0) { $0 + $1.percentage }
        var angle: Double = -90
        
        for i in 0...index {
            angle += (distribution[i].percentage / total) * 360
        }
        
        return Angle(degrees: angle)
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * (isSelected ? 0.9 : 0.8)
            
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 5)
            .animation(.spring(), value: isSelected)
        }
    }
}

struct HSKBarChart: View {
    let distribution: [StatsViewModel.HSKDistribution]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Từ vựng theo cấp độ")
                .font(.headline)
            
            ForEach(distribution) { item in
                HStack(spacing: 12) {
                    Text("HSK \(item.level)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 24)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.color)
                                .frame(
                                    width: max(0, CGFloat(item.percentage) / 100 * geometry.size.width),
                                    height: 24
                                )
                            
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                        }
                    }
                    .frame(height: 24)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
}

struct DifficultyDonutChart: View {
    let data: [StatsViewModel.DifficultyData]
    @State private var selectedSegment: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Độ khó từ vựng")
                .font(.headline)
            
            HStack(spacing: 30) {
                // Donut chart
                ZStack {
                    ForEach(data.indices, id: \.self) { index in
                        let item = data[index]
                        let startAngle = calculateStartAngle(for: index)
                        let endAngle = calculateEndAngle(for: index)
                        
                        DonutSegment(
                            startAngle: startAngle,
                            endAngle: endAngle,
                            color: item.color,
                            isSelected: selectedSegment == item.category
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedSegment = selectedSegment == item.category ? nil : item.category
                            }
                        }
                    }
                    
                    // Center info
                    if let selected = selectedSegment,
                       let item = data.first(where: { $0.category == selected }) {
                        VStack(spacing: 4) {
                            Text("\(item.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(item.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(data) { item in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(item.count) từ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
    
    private func calculateStartAngle(for index: Int) -> Angle {
        let total = data.reduce(0) { $0 + $1.count }
        var angle: Double = -90
        
        for i in 0..<index {
            angle += (Double(data[i].count) / Double(total)) * 360
        }
        
        return Angle(degrees: angle)
    }
    
    private func calculateEndAngle(for index: Int) -> Angle {
        let total = data.reduce(0) { $0 + $1.count }
        var angle: Double = -90
        
        for i in 0...index {
            angle += (Double(data[i].count) / Double(total)) * 360
        }
        
        return Angle(degrees: angle)
    }
}

struct DonutSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let outerRadius = min(geometry.size.width, geometry.size.height) / 2 * (isSelected ? 1.0 : 0.95)
            let innerRadius = outerRadius * 0.6
            
            Path { path in
                path.addArc(
                    center: center,
                    radius: outerRadius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.addArc(
                    center: center,
                    radius: innerRadius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: true
                )
                path.closeSubpath()
            }
            .fill(color)
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 3)
            .animation(.spring(), value: isSelected)
        }
    }
}

struct ActivityHeatMap: View {
    let hourlyData: [StatsViewModel.HourlyActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thời gian học trong ngày")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                ForEach(hourlyData) { item in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForActivity(item.count))
                        .frame(height: 30)
                        .overlay(
                            Text("\(item.hour)h")
                                .font(.caption2)
                                .foregroundColor(item.count > 5 ? .white : .secondary)
                        )
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                Text("Ít")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForActivity(level * 2))
                            .frame(width: 20, height: 10)
                    }
                }
                
                Text("Nhiều")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
    
    private func colorForActivity(_ count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.1)
        case 1...2: return Color.blue.opacity(0.2)
        case 3...5: return Color.blue.opacity(0.4)
        case 6...8: return Color.blue.opacity(0.6)
        default: return Color.blue.opacity(0.8)
        }
    }
}


// Keep the existing StatCard for backward compatibility
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

#Preview {
    StatsView()
}
