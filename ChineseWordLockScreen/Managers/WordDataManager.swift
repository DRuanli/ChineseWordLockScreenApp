//
//  WordDataManager.swift
//  ChineseWordLockScreen
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
    @Published var dailyNewWordLimit: Int = 5
    @Published var wordsLearnedToday: Int = 0
    
    // Priority queues for different word states
    @Published var newWordsQueue: [HSKWord] = []
    @Published var introducedWordsQueue: [SavedWord] = []
    @Published var learningWordsQueue: [SavedWord] = []
    @Published var reviewWordsQueue: [SavedWord] = []
    @Published var masteredWordsQueue: [SavedWord] = []
    
    private let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen")
    
    // SRS intervals based on state
    private let stateIntervals: [WordLearningState: [Int]] = [
        .introduced: [0],           // Same day reviews
        .learning: [1, 3, 7],       // Days 1-7
        .review: [14, 30, 60],      // Days 14-60
        .mastered: [90, 180, 365]   // Quarterly reviews
    ]
    
    private init() {
        loadAllQueues()
        updateTodayProgress()
    }
    
    // MARK: - Queue Management
    func loadAllQueues() {
        guard let user = authManager.currentUser else { return }
        
        // Load new words (not yet saved)
        loadNewWordsQueue()
        
        // Load saved words by state
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        
        do {
            let allWords = try context.fetch(request)
            
            // Sort into queues by state
            introducedWordsQueue = allWords.filter { $0.learningState == WordLearningState.introduced.rawValue }
            learningWordsQueue = allWords.filter { $0.learningState == WordLearningState.learning.rawValue }
                .sorted { ($0.nextReviewDate ?? Date()) < ($1.nextReviewDate ?? Date()) }
            reviewWordsQueue = allWords.filter { $0.learningState == WordLearningState.review.rawValue }
                .sorted { ($0.nextReviewDate ?? Date()) < ($1.nextReviewDate ?? Date()) }
            masteredWordsQueue = allWords.filter { $0.learningState == WordLearningState.mastered.rawValue }
            
            savedWords = allWords
        } catch {
            print("Error loading queues: \(error)")
        }
    }
    
    private func loadNewWordsQueue() {
        // Load words that haven't been introduced yet
        let allHSKWords = HSKDatabaseSeeder.shared.getAllWordsForLevel(selectedHSKLevel)
        let savedHanzi = savedWords.compactMap { $0.hanzi }
        newWordsQueue = allHSKWords.filter { !savedHanzi.contains($0.hanzi) }
            .shuffled()
            .prefix(50)
            .map { $0 }
    }
    
    // MARK: - Get Next Word Based on Priority
    func getNextWord(isNewWordMode: Bool) -> (word: HSKWord, state: WordLearningState, quizType: QuizType?) {
        if isNewWordMode {
            return getNextNewWord()
        } else {
            return getNextReviewWord()
        }
    }
    
    private func getNextNewWord() -> (word: HSKWord, state: WordLearningState, quizType: QuizType?) {
        // Check daily limit
        if wordsLearnedToday >= dailyNewWordLimit {
            // If limit reached, switch to review mode
            return getNextReviewWord()
        }
        
        // Get new word from queue
        if let newWord = newWordsQueue.first {
            return (newWord, .new, nil)
        }
        
        // Fallback to review if no new words
        return getNextReviewWord()
    }
    
    private func getNextReviewWord() -> (word: HSKWord, state: WordLearningState, quizType: QuizType?) {
        let now = Date()
        
        // Priority 1: Overdue learning words
        if let urgentWord = learningWordsQueue.first(where: { ($0.nextReviewDate ?? now) <= now }) {
            let hskWord = savedWordToHSKWord(urgentWord)
            return (hskWord, .learning, selectQuizType(for: urgentWord))
        }
        
        // Priority 2: Introduced words (same day review)
        if !introducedWordsQueue.isEmpty {
            let word = introducedWordsQueue.first!
            let hskWord = savedWordToHSKWord(word)
            return (hskWord, .introduced, .recognition)
        }
        
        // Priority 3: Due review words
        if let reviewWord = reviewWordsQueue.first(where: { ($0.nextReviewDate ?? now) <= now }) {
            let hskWord = savedWordToHSKWord(reviewWord)
            return (hskWord, .review, selectQuizType(for: reviewWord))
        }
        
        // Priority 4: Random mastered word for maintenance
        if let masteredWord = masteredWordsQueue.randomElement() {
            let hskWord = savedWordToHSKWord(masteredWord)
            return (hskWord, .mastered, selectQuizType(for: masteredWord))
        }
        
        // Fallback: Get any new word
        return getNextNewWord()
    }
    
    private func selectQuizType(for word: SavedWord) -> QuizType {
        // Based on accuracy, select appropriate quiz type
        let accuracy = calculateAccuracy(for: word)
        
        if accuracy < 0.6 {
            return .recognition // Easier
        } else if accuracy < 0.8 {
            return QuizType.allCases.randomElement()!
        } else {
            // Higher difficulty for well-known words
            return [QuizType.recall, QuizType.context].randomElement()!
        }
    }
    
    private func calculateAccuracy(for word: SavedWord) -> Double {
        let total = word.correctCount + word.incorrectCount
        guard total > 0 else { return 0.5 }
        return Double(word.correctCount) / Double(total)
    }
    
    // MARK: - Word State Transitions
    func introduceWord(_ word: HSKWord) {
        guard let user = authManager.currentUser else { return }
        
        let savedWord = SavedWord(context: context)
        savedWord.hanzi = word.hanzi
        savedWord.pinyin = word.pinyin
        savedWord.meaning = word.meaning
        savedWord.example = word.example
        savedWord.hskLevel = Int16(word.hskLevel)
        savedWord.savedDate = Date()
        savedWord.learningState = WordLearningState.introduced.rawValue
        savedWord.lastReviewDate = Date()
        savedWord.nextReviewDate = Date() // Review same day
        savedWord.user = user
        
        do {
            try context.save()
            wordsLearnedToday += 1
            loadAllQueues()
            updateWidgetData()
        } catch {
            print("Error introducing word: \(error)")
        }
    }
    
    func updateWordAfterQuiz(_ word: SavedWord, isCorrect: Bool, responseTime: TimeInterval) {
        // Update statistics
        if isCorrect {
            word.correctCount += 1
        } else {
            word.incorrectCount += 1
        }
        
        word.lastReviewDate = Date()
        word.reviewCount += 1
        
        // Calculate new state and review date
        let accuracy = calculateAccuracy(for: word)
        let currentState = WordLearningState(rawValue: word.learningState) ?? .introduced
        
        // State transition logic
        switch currentState {
        case .introduced:
            if word.reviewCount >= 3 && accuracy >= 0.8 {
                word.learningState = WordLearningState.learning.rawValue
                word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            } else {
                // Review again in 2 hours
                word.nextReviewDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())
            }
            
        case .learning:
            if accuracy >= 0.8 && responseTime < 3.0 {
                // Progress to review
                word.learningState = WordLearningState.review.rawValue
                word.srsLevel = 0
                word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
            } else if accuracy < 0.5 {
                // Reset to introduced
                word.learningState = WordLearningState.introduced.rawValue
                word.nextReviewDate = Date()
            } else {
                // Continue learning
                let interval = isCorrect ? 1 : 0
                word.nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: Date())
            }
            
        case .review:
            if accuracy >= 0.9 && word.reviewCount > 10 {
                // Progress to mastered
                word.learningState = WordLearningState.mastered.rawValue
                word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
            } else if accuracy < 0.7 {
                // Back to learning
                word.learningState = WordLearningState.learning.rawValue
                word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            } else {
                // Continue review with spaced repetition
                let intervals = stateIntervals[.review]!
                let level = min(Int(word.srsLevel), intervals.count - 1)
                let days = isCorrect ? intervals[level] : intervals[max(0, level - 1)]
                word.srsLevel = Int16(isCorrect ? level + 1 : max(0, level - 1))
                word.nextReviewDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
            }
            
        case .mastered:
            if !isCorrect && accuracy < 0.8 {
                // Demote to review
                word.learningState = WordLearningState.review.rawValue
                word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
            } else {
                // Long interval for mastered words
                word.nextReviewDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
            }
            
        default:
            break
        }
        
        do {
            try context.save()
            loadAllQueues()
        } catch {
            print("Error updating word: \(error)")
        }
    }
    
    // MARK: - Save/Delete Word
    func saveWord(_ word: HSKWord) {
        guard let user = authManager.currentUser else { return }
        
        let savedWord = SavedWord(context: context)
        savedWord.hanzi = word.hanzi
        savedWord.pinyin = word.pinyin
        savedWord.meaning = word.meaning
        savedWord.example = word.example
        savedWord.hskLevel = Int16(word.hskLevel)
        savedWord.savedDate = Date()
        savedWord.learningState = WordLearningState.introduced.rawValue
        savedWord.lastReviewDate = Date()
        savedWord.nextReviewDate = Date()
        savedWord.user = user
        savedWord.correctCount = 0
        savedWord.incorrectCount = 0
        savedWord.reviewCount = 0
        savedWord.srsLevel = 0
        savedWord.isFavorite = false
        
        do {
            try context.save()
            loadAllQueues()
            updateTodayProgress()
            updateWidgetData()
        } catch {
            print("Error saving word: \(error)")
        }
    }
    
    func deleteWord(_ word: SavedWord) {
        context.delete(word)
        do {
            try context.save()
            loadAllQueues()
            updateTodayProgress()
            updateWidgetData()
        } catch {
            print("Error deleting word: \(error)")
        }
    }
    
    // MARK: - User Defaults
    func saveToUserDefaults(word: HSKWord) {
        guard let user = authManager.currentUser else { return }
        
        userDefaults?.set(word.hanzi, forKey: "current_hanzi")
        userDefaults?.set(word.pinyin, forKey: "current_pinyin")
        userDefaults?.set(word.meaning, forKey: "current_meaning")
        userDefaults?.set(user.id, forKey: "current_user_id")
        userDefaults?.synchronize()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func saveUserDefaults() {
        guard let user = authManager.currentUser else { return }
        
        userDefaults?.set(selectedHSKLevel, forKey: "selected_hsk_level")
        userDefaults?.set(dailyNewWordLimit, forKey: "daily_new_word_limit")
        userDefaults?.set(user.id, forKey: "current_user_id")
        userDefaults?.synchronize()
    }
    
    // MARK: - Helper Methods
    private func savedWordToHSKWord(_ savedWord: SavedWord) -> HSKWord {
        return HSKWord(
            hanzi: savedWord.hanzi ?? "",
            pinyin: savedWord.pinyin ?? "",
            meaning: savedWord.meaning ?? "",
            example: savedWord.example,
            hskLevel: Int(savedWord.hskLevel)
        )
    }
    
    func toggleFavorite(for word: SavedWord) {
        word.isFavorite.toggle()
        do {
            try context.save()
            loadAllQueues()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    private func updateWidgetData() {
        if let currentWord = currentWord {
            saveToUserDefaults(word: currentWord)
        }
    }
    
    func updateTodayProgress() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let user = authManager.currentUser else { return }
        
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(
            format: "user == %@ AND savedDate >= %@",
            user,
            today as NSDate
        )
        
        do {
            let todayWords = try context.fetch(request)
            wordsLearnedToday = todayWords.count
            todayWordsCount = todayWords.count
        } catch {
            print("Error fetching today's progress: \(error)")
        }
    }
}
