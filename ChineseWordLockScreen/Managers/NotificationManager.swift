//
//  NotificationManager.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationEnabled = false
    @Published var notificationFrequency = 3 // times per day
    
    private init() {
        checkNotificationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationEnabled = granted
                if granted {
                    self.scheduleNotifications()
                }
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleNotifications() {
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule new notifications
        let hours = [9, 13, 19] // 9 AM, 1 PM, 7 PM
        
        for hour in hours.prefix(notificationFrequency) {
            let content = UNMutableNotificationContent()
            let word = HSKDatabaseSeeder.shared.getRandomWord()
            
            content.title = "今日新词 Word of the Day"
            content.body = "\(word.hanzi) (\(word.pinyin)) - \(word.meaning)"
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "word_reminder_\(hour)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func updateNotificationFrequency(_ frequency: Int) {
        notificationFrequency = frequency
        if isNotificationEnabled {
            scheduleNotifications()
        }
    }
}
