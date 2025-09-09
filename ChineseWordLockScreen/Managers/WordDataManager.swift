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
    
    @Published var savedWords: [SavedWord] = []
    @Published var currentWord: HSKWord?
    @Published var selectedHSKLevel: Int = 5
    
    private let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    private init() {
        fetchSavedWords()
        loadWordOfDay()
    }
    
    func loadWordOfDay() {
        currentWord = HSKDatabaseSeeder.shared.getWordOfDay()
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
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedWord.savedDate, ascending: false)]
        
        do {
            savedWords = try context.fetch(request)
        } catch {
            print("Error fetching saved words: \(error)")
        }
    }
    
    func saveWord(_ word: HSKWord) {
        // Check if already saved
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(format: "hanzi == %@", word.hanzi)
        
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
                
                try context.save()
                fetchSavedWords()
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
        currentWord = HSKDatabaseSeeder.shared.getRandomWord()
        saveToUserDefaults(word: currentWord!)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
