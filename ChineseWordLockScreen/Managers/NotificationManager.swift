//
//  NotificationManager.swift
//  ChineseWordLockScreen
//
//  Enhanced with smart scheduling and content variety
//
import UserNotifications
import Foundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var notificationFrequency: Int = 3
    @Published var quietHoursStart: Int = 22
    @Published var quietHoursEnd: Int = 7
    @Published var adaptiveScheduling = true
    
    private let wordDataManager = WordDataManager.shared
    
    // Schedule notifications based on learning state priority
    func scheduleAdaptiveNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let optimalTimes = getOptimalNotificationTimes()
        
        for (index, time) in optimalTimes.enumerated() {
            let priority = getNotificationPriority(for: time)
            scheduleNotification(at: time, priority: priority, id: "adaptive_\(index)")
        }
    }
    
    private func getOptimalNotificationTimes() -> [NotificationTime] {
        var times: [NotificationTime] = []
        
        // Morning: New word introduction
        times.append(NotificationTime(hour: 8, minute: 0, type: .newWord))
        
        // Midday: Quick review
        times.append(NotificationTime(hour: 12, minute: 30, type: .review))
        
        // Evening: Context practice
        times.append(NotificationTime(hour: 18, minute: 0, type: .context))
        
        // Before bed: Audio review (optional)
        if notificationFrequency > 3 {
            times.append(NotificationTime(hour: 21, minute: 0, type: .audio))
        }
        
        return times.filter { time in
            time.hour < quietHoursStart || time.hour >= quietHoursEnd
        }
    }
    
    private func getNotificationPriority(for time: NotificationTime) -> NotificationPriority {
        let learningWords = wordDataManager.learningWordsQueue.count
        let reviewWords = wordDataManager.reviewWordsQueue.count
        
        if learningWords > 10 {
            return .high
        } else if reviewWords > 20 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func scheduleNotification(at time: NotificationTime, priority: NotificationPriority, id: String) {
        let content = UNMutableNotificationContent()
        
        switch time.type {
        case .newWord:
            let (word, _, _) = wordDataManager.getNextWord(isNewWordMode: true)
            content.title = "🆕 Từ mới hôm nay"
            content.body = "\(word.hanzi) (\(word.pinyin)) - \(word.meaning)"
            content.categoryIdentifier = "NEW_WORD"
            
        case .review:
            let overdueCount = wordDataManager.learningWordsQueue.filter {
                ($0.nextReviewDate ?? Date()) <= Date()
            }.count
            content.title = "📚 Thời gian ôn tập"
            content.body = "Bạn có \(overdueCount) từ cần ôn tập"
            content.categoryIdentifier = "REVIEW"
            
        case .context:
            let (word, _, _) = wordDataManager.getNextWord(isNewWordMode: false)
            content.title = "💡 Luyện tập ngữ cảnh"
            if let example = word.example {
                content.body = example
            } else {
                content.body = "Hãy tạo câu với từ: \(word.hanzi)"
            }
            content.categoryIdentifier = "CONTEXT"
            
        case .audio:
            content.title = "🎧 Luyện nghe"
            content.body = "Thời gian luyện phát âm và nghe hiểu"
            content.categoryIdentifier = "AUDIO"
        }
        
        // Set priority
        switch priority {
        case .high:
            content.interruptionLevel = .timeSensitive
        case .medium:
            content.interruptionLevel = .active
        case .low:
            content.interruptionLevel = .passive
        }
        
        content.sound = .default
        content.badge = NSNumber(value: wordDataManager.learningWordsQueue.count)
        
        // Create trigger
        var dateComponents = DateComponents()
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

// Supporting types
struct NotificationTime {
    let hour: Int
    let minute: Int
    let type: NotificationType
}

enum NotificationType {
    case newWord
    case review
    case context
    case audio
}

enum NotificationPriority {
    case high
    case medium
    case low
}
