//
//  WordDataManager.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
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
    
    private let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    private init() {
        fetchSavedWords()
        loadWordOfDay()
        updateTodayProgress()
    }
    
    func loadWordOfDay() {
        guard let user = authManager.currentUser else {
            currentWord = HSKDatabaseSeeder.shared.getWordOfDay()
            return
        }
        
        selectedHSKLevel = Int(user.preferredHSKLevel)
        currentWord = HSKDatabaseSeeder.shared.getWordForLevel(selectedHSKLevel) ?? HSKDatabaseSeeder.shared.getWordOfDay()
        saveToUserDefaults(word: currentWord!)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func saveToUserDefaults(word: HSKWord) {
        userDefaults?.set(word.hanzi, forKey: "current_hanzi")
        userDefaults?.set(word.pinyin, forKey: "current_pinyin")
        userDefaults?.set(word.meaning, forKey: "current_meaning")
        userDefaults?.set(word.example, forKey: "current_example")
    }
    
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
                savedWord.user = user
                
                try context.save()
                fetchSavedWords()
                updateTodayProgress()
            }
        } catch {
            print("Error saving word: \(error)")
        }
    }
    
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
    
    func incrementReviewCount(for savedWord: SavedWord) {
        savedWord.reviewCount += 1
        
        do {
            try context.save()
        } catch {
            print("Error updating review count: \(error)")
        }
    }
    
    func getNextWord() {
        guard let user = authManager.currentUser else {
            currentWord = HSKDatabaseSeeder.shared.getRandomWord()
            return
        }
        
        let level = Int(user.preferredHSKLevel)
        currentWord = HSKDatabaseSeeder.shared.getRandomWordForLevel(level) ?? HSKDatabaseSeeder.shared.getRandomWord()
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
    }
    
    func refreshData() {
        fetchSavedWords()
        updateTodayProgress()
    }
}
