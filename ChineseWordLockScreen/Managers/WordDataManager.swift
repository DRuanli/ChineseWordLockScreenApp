//
//  WordDataManager.swift
//  ChineseWordLockScreen
//
//  Enhanced version with SRS algorithm and proper data synchronization
//

import Foundation
import CoreData
import WidgetKit

class WordDataManager: ObservableObject {
    static let shared = WordDataManager()
    let context = PersistenceController.shared.container.viewContext
    private let authManager = AuthenticationManager.shared
    
    @Published var savedWords: [SavedWord] = []
    @Published var currentWord: HSKWord?
    @Published var selectedHSKLevel: Int = 5
    @Published var todayWordsCount: Int = 0
    @Published var streak: Int = 0
    @Published var wordsForReview: [SavedWord] = []
    
    // IMPORTANT: Use App Group for sharing data with Widget
    private let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    // SRS intervals in days
    private let srsIntervals = [1, 3, 7, 14, 30, 60, 120]
    
    private init() {
        fetchSavedWords()
        loadWordOfDay()
        updateTodayProgress()
        checkWordsForReview()
    }
    
    // MARK: - Word Loading
    func loadWordOfDay() {
        guard let user = authManager.currentUser else {
            currentWord = HSKDatabaseSeeder.shared.getWordOfDay()
            saveToUserDefaults(word: currentWord!)
            return
        }
        
        selectedHSKLevel = Int(user.preferredHSKLevel)
        
        // First check if there are words due for review
        if let reviewWord = getNextReviewWord() {
            currentWord = HSKWord(
                hanzi: reviewWord.hanzi ?? "",
                pinyin: reviewWord.pinyin ?? "",
                meaning: reviewWord.meaning ?? "",
                example: reviewWord.example,
                hskLevel: Int(reviewWord.hskLevel)
            )
        } else {
            // Get new word for the level
            currentWord = HSKDatabaseSeeder.shared.getWordForLevel(selectedHSKLevel) ??
                        HSKDatabaseSeeder.shared.getWordOfDay()
        }
        
        saveToUserDefaults(word: currentWord!)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func saveToUserDefaults(word: HSKWord) {
        userDefaults?.set(word.hanzi, forKey: "current_hanzi")
        userDefaults?.set(word.pinyin, forKey: "current_pinyin")
        userDefaults?.set(word.meaning, forKey: "current_meaning")
        userDefaults?.set(word.example, forKey: "current_example")
        userDefaults?.set(Date(), forKey: "last_update")
        
        // Sync immediately
        userDefaults?.synchronize()
    }
    
    // MARK: - Core Data Operations
    func fetchSavedWords() {
        guard let user = authManager.currentUser else {
            savedWords = []
            return
        }
        
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedWord.savedDate, ascending: false)]
        
        do {
            savedWords = try context.fetch(request)
        } catch {
            print("Error fetching saved words: \(error)")
        }
    }
    
    func saveWord(_ word: HSKWord) {
        guard let user = authManager.currentUser else { return }
        
        // Check if already saved
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(format: "hanzi == %@ AND user == %@", word.hanzi, user)
        
        do {
            let existing = try context.fetch(request)
            if existing.isEmpty {
                let savedWord = SavedWord(context: context)
                savedWord.hanzi = word.hanzi
                savedWord.pinyin = word.pinyin
                savedWord.meaning = word.meaning
                savedWord.example = word.example
                savedWord.hskLevel = Int16(word.hskLevel)
                savedWord.savedDate = Date()
                savedWord.isFavorite = false
                savedWord.reviewCount = 0
                savedWord.lastReviewDate = Date()
                savedWord.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                savedWord.srsLevel = 0
                savedWord.user = user
                
                try context.save()
                fetchSavedWords()
                updateTodayProgress()
                checkWordsForReview()
            }
        } catch {
            print("Error saving word: \(error)")
        }
    }
    
    // MARK: - SRS Algorithm
    func markWordAsRemembered(_ savedWord: SavedWord) {
        savedWord.reviewCount += 1
        savedWord.lastReviewDate = Date()
        
        // Move to next SRS level
        let currentLevel = Int(savedWord.srsLevel)
        if currentLevel < srsIntervals.count - 1 {
            savedWord.srsLevel = Int16(currentLevel + 1)
        }
        
        // Calculate next review date
        let daysUntilNextReview = srsIntervals[Int(savedWord.srsLevel)]
        savedWord.nextReviewDate = Calendar.current.date(byAdding: .day, value: daysUntilNextReview, to: Date())
        
        do {
            try context.save()
            checkWordsForReview()
        } catch {
            print("Error updating SRS data: \(error)")
        }
    }
    
    func markWordAsForgotten(_ savedWord: SavedWord) {
        savedWord.reviewCount += 1
        savedWord.lastReviewDate = Date()
        
        // Reset to first SRS level
        savedWord.srsLevel = 0
        
        // Review again tomorrow
        savedWord.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        
        do {
            try context.save()
            checkWordsForReview()
        } catch {
            print("Error updating SRS data: \(error)")
        }
    }
    
    func checkWordsForReview() {
        guard let user = authManager.currentUser else {
            wordsForReview = []
            return
        }
        
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(
            format: "user == %@ AND nextReviewDate <= %@",
            user,
            today as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedWord.nextReviewDate, ascending: true)]
        
        do {
            wordsForReview = try context.fetch(request)
        } catch {
            print("Error fetching words for review: \(error)")
        }
    }
    
    func getNextReviewWord() -> SavedWord? {
        checkWordsForReview()
        return wordsForReview.first
    }
    
    // MARK: - Other Operations
    func toggleFavorite(for savedWord: SavedWord) {
        savedWord.isFavorite.toggle()
        
        do {
            try context.save()
            fetchSavedWords()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    func deleteWord(_ savedWord: SavedWord) {
        context.delete(savedWord)
        
        do {
            try context.save()
            fetchSavedWords()
        } catch {
            print("Error deleting word: \(error)")
        }
    }
    
    func getNextWord() {
        guard let user = authManager.currentUser else {
            currentWord = HSKDatabaseSeeder.shared.getRandomWord()
            saveToUserDefaults(word: currentWord!)
            return
        }
        
        // Check if there are review words first
        if let reviewWord = getNextReviewWord() {
            currentWord = HSKWord(
                hanzi: reviewWord.hanzi ?? "",
                pinyin: reviewWord.pinyin ?? "",
                meaning: reviewWord.meaning ?? "",
                example: reviewWord.example,
                hskLevel: Int(reviewWord.hskLevel)
            )
        } else {
            let level = Int(user.preferredHSKLevel)
            currentWord = HSKDatabaseSeeder.shared.getRandomWordForLevel(level) ??
                        HSKDatabaseSeeder.shared.getRandomWord()
        }
        
        saveToUserDefaults(word: currentWord!)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateTodayProgress() {
        guard let user = authManager.currentUser else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get today's saved words count
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(
            format: "user == %@ AND savedDate >= %@",
            user,
            today as NSDate
        )
        
        do {
            todayWordsCount = try context.count(for: request)
            
            // Update daily goal progress in UserDefaults for Widget
            userDefaults?.set(todayWordsCount, forKey: "today_count")
            userDefaults?.set(user.dailyGoal, forKey: "daily_goal")
        } catch {
            print("Error counting today's words: \(error)")
        }
        
        // Calculate streak
        calculateStreak(for: user)
    }
    
    private func calculateStreak(for user: User) {
        let calendar = Calendar.current
        var currentStreak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            
            request.predicate = NSPredicate(
                format: "user == %@ AND savedDate >= %@ AND savedDate < %@",
                user,
                currentDate as NSDate,
                nextDate as NSDate
            )
            
            do {
                let count = try context.count(for: request)
                if count > 0 {
                    currentStreak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                } else {
                    break
                }
            } catch {
                break
            }
        }
        
        streak = currentStreak
        userDefaults?.set(streak, forKey: "streak_count")
    }
    
    func refreshData() {
        fetchSavedWords()
        updateTodayProgress()
        checkWordsForReview()
    }
}
