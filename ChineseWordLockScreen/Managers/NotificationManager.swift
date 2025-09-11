//
//  NotificationManager.swift
//  ChineseWordLockScreen
//
//  Enhanced with smart scheduling and content variety
//

import Foundation
import UserNotifications
import WidgetKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationEnabled = false
    @Published var notificationFrequency = 3 // times per day
    @Published var quietHoursStart = 22 // 10 PM
    @Published var quietHoursEnd = 7 // 7 AM
    
    private let wordDataManager = WordDataManager.shared
    private let hskDatabase = HSKDatabaseSeeder.shared
    
    private init() {
        checkNotificationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .carPlay]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationEnabled = granted
                if granted {
                    self.scheduleNotifications()
                    self.setupNotificationCategories()
                }
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationEnabled = settings.authorizationStatus == .authorized
                if self.isNotificationEnabled {
                    self.setupNotificationCategories()
                }
            }
        }
    }
    
    // MARK: - Notification Categories
    private func setupNotificationCategories() {
        // Review actions
        let rememberAction = UNNotificationAction(
            identifier: "REMEMBER_ACTION",
            title: "记得了 ✓",
            options: [.foreground]
        )
        
        let forgetAction = UNNotificationAction(
            identifier: "FORGET_ACTION",
            title: "忘记了 ✗",
            options: [.foreground]
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "查看详情",
            options: [.foreground]
        )
        
        // Categories
        let reviewCategory = UNNotificationCategory(
            identifier: "REVIEW_CATEGORY",
            actions: [rememberAction, forgetAction],
            intentIdentifiers: [],
            options: []
        )
        
        let wordCategory = UNNotificationCategory(
            identifier: "WORD_CATEGORY",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([reviewCategory, wordCategory])
    }
    
    // MARK: - Schedule Notifications
    func scheduleNotifications() {
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule based on frequency
        let notificationTimes = getOptimalNotificationTimes()
        
        for (index, hour) in notificationTimes.enumerated() {
            scheduleWordNotification(at: hour, id: "word_\(index)")
            scheduleReviewNotification(at: hour + 1, id: "review_\(index)") // Review 1 hour after word
        }
        
        // Schedule streak reminder
        scheduleStreakReminder()
    }
    
    private func getOptimalNotificationTimes() -> [Int] {
        switch notificationFrequency {
        case 1:
            return [12] // Noon only
        case 2:
            return [9, 18] // Morning and evening
        case 3:
            return [9, 13, 19] // Morning, lunch, evening
        case 4:
            return [8, 12, 16, 20] // 4 times spread
        case 5:
            return [8, 11, 14, 17, 20] // 5 times spread
        default:
            return [9, 13, 19]
        }
    }
    
    private func scheduleWordNotification(at hour: Int, id: String) {
        // Skip if in quiet hours
        if hour >= quietHoursStart || hour < quietHoursEnd {
            return
        }
        
        let content = UNMutableNotificationContent()
        let word = hskDatabase.getRandomWord()
        
        // Vary content type
        let contentTypes = [
            "word", "quiz", "context", "collocation"
        ]
        let selectedType = contentTypes.randomElement() ?? "word"
        
        switch selectedType {
        case "quiz":
            content.title = "快速测验 Quiz"
            content.body = "'\(word.hanzi)' 的意思是什么？"
            content.categoryIdentifier = "REVIEW_CATEGORY"
            
        case "context":
            content.title = "例句 Example"
            if let example = word.example {
                content.body = example
            } else {
                content.body = "\(word.hanzi) (\(word.pinyin)) - \(word.meaning)"
            }
            content.categoryIdentifier = "WORD_CATEGORY"
            
        case "collocation":
            content.title = "词语搭配 Word Pairing"
            content.body = "学习: \(word.hanzi) + 其他词"
            content.categoryIdentifier = "WORD_CATEGORY"
            
        default: // "word"
            content.title = "今日新词 Word of the Day"
            content.body = "\(word.hanzi) (\(word.pinyin)) - \(word.meaning)"
            content.categoryIdentifier = "WORD_CATEGORY"
        }
        
        content.sound = .default
        content.badge = 1
        
        // Store word info for action handling
        content.userInfo = [
            "hanzi": word.hanzi,
            "pinyin": word.pinyin,
            "meaning": word.meaning,
            "type": selectedType
        ]
        
        // Schedule daily
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func scheduleReviewNotification(at hour: Int, id: String) {
        // Skip if in quiet hours or no words to review
        if hour >= quietHoursStart || hour < quietHoursEnd {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "复习时间 Review Time"
        
        let reviewCount = wordDataManager.wordsForReview.count
        if reviewCount > 0 {
            content.body = "你有 \(reviewCount) 个词需要复习"
        } else {
            content.body = "继续保持学习势头！"
        }
        
        content.categoryIdentifier = "REVIEW_CATEGORY"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleStreakReminder() {
        let content = UNMutableNotificationContent()
        content.title = "保持连续学习 Keep Your Streak!"
        
        let streak = wordDataManager.streak
        if streak > 0 {
            content.body = "你已经连续学习 \(streak) 天了，不要中断！🔥"
        } else {
            content.body = "开始新的学习连续记录吧！"
        }
        
        content.sound = .default
        content.categoryIdentifier = "WORD_CATEGORY"
        
        // Schedule at 8 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Update Settings
    func updateNotificationFrequency(_ frequency: Int) {
        notificationFrequency = frequency
        if isNotificationEnabled {
            scheduleNotifications()
        }
    }
    
    func updateQuietHours(start: Int, end: Int) {
        quietHoursStart = start
        quietHoursEnd = end
        if isNotificationEnabled {
            scheduleNotifications()
        }
    }
    
    // MARK: - Smart Notifications
    func sendImmediateReviewNotification(for word: HSKWord) {
        let content = UNMutableNotificationContent()
        content.title = "立即复习 Quick Review"
        content.body = "复习: \(word.hanzi) (\(word.pinyin)) - \(word.meaning)"
        content.sound = .default
        content.categoryIdentifier = "REVIEW_CATEGORY"
        
        content.userInfo = [
            "hanzi": word.hanzi,
            "pinyin": word.pinyin,
            "meaning": word.meaning
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "immediate_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendMilestoneNotification(milestone: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 成就达成 Achievement Unlocked!"
        content.body = milestone
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "milestone_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
