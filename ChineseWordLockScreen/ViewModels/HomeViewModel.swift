//
//  HomeViewModel.swift
//  ChineseWordLockScreen
//
//  Enhanced for redesigned vocabulary card interface
//  Updated with word source selection and improved logic
//

import Foundation
import SwiftUI
import CoreData
import AVFoundation

// MARK: - Word Source Mode (Moved outside class)
enum WordSourceMode: String, CaseIterable {
    case random = "Random Words"
    case favorites = "Favorite Words"
    case folder = "Folder Words"
    case mixed = "Mixed (Random + Favorites)"
}

class HomeViewModel: ObservableObject {
    @Published var currentWord: HSKWord
    @Published var isSaved: Bool = false
    @Published var showingDefinition: Bool = true
    @Published var wordHistory: [HSKWord] = []
    @Published var currentIndex: Int = 0
    @Published var wordSourceMode: WordSourceMode = .random
    @Published var selectedFolderId: NSManagedObjectID?
    
    private let wordDataManager = WordDataManager.shared
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        self.currentWord = HSKDatabaseSeeder.shared.getWordOfDay()
        self.wordHistory.append(currentWord)
        checkIfSaved()
        
        // Configure speech synthesizer
        synthesizer.usesApplicationAudioSession = false
        
        // Load initial session words
        loadSessionWords(count: 10)
    }
    
    // MARK: - Word Source Management
    func loadSessionWords(count: Int = 10) {
        wordHistory.removeAll()
        
        switch wordSourceMode {
        case .random:
            loadRandomWords(count: count)
        case .favorites:
            loadFavoriteWords(count: count)
        case .folder:
            if let folderId = selectedFolderId {
                loadFolderWords(folderId: folderId, count: count)
            } else {
                loadRandomWords(count: count) // Fallback
            }
        case .mixed:
            loadMixedWords(count: count)
        }
        
        if !wordHistory.isEmpty {
            currentIndex = 0
            currentWord = wordHistory[0]
            checkIfSaved()
            wordDataManager.saveToUserDefaults(word: currentWord)
        }
    }
    
    private func loadRandomWords(count: Int) {
        let allWords = HSKDatabaseSeeder.shared.getSampleWords()
        var addedWords = Set<String>() // Track added words to avoid duplicates
        
        while wordHistory.count < count && wordHistory.count < allWords.count {
            if let randomWord = allWords.randomElement() {
                if !addedWords.contains(randomWord.hanzi) {
                    wordHistory.append(randomWord)
                    addedWords.insert(randomWord.hanzi)
                }
            }
        }
    }
    
    private func loadFavoriteWords(count: Int) {
        let favoriteWords = wordDataManager.savedWords.filter { $0.isFavorite }
        
        if favoriteWords.isEmpty {
            // Fallback to all saved words if no favorites
            let allSaved = wordDataManager.savedWords
            if allSaved.isEmpty {
                // Final fallback to random if no saved words
                loadRandomWords(count: count)
                return
            }
            // Use all saved words
            for savedWord in allSaved.prefix(count) {
                let hskWord = convertToHSKWord(savedWord)
                wordHistory.append(hskWord)
            }
        } else {
            // Use favorite words
            for savedWord in favoriteWords.prefix(count) {
                let hskWord = convertToHSKWord(savedWord)
                wordHistory.append(hskWord)
            }
        }
        
        // Fill remaining with random if not enough
        if wordHistory.count < count {
            let remainingCount = count - wordHistory.count
            let tempHistory = wordHistory
            loadRandomWords(count: remainingCount)
            // Combine existing favorites with new random words
            wordHistory = tempHistory + wordHistory
        }
    }
    
    private func loadFolderWords(folderId: NSManagedObjectID, count: Int) {
        let context = PersistenceController.shared.container.viewContext
        
        do {
            guard let folder = try context.existingObject(with: folderId) as? PersonalFolder,
                  let folderWords = folder.words as? Set<SavedWord>,
                  !folderWords.isEmpty else {
                loadRandomWords(count: count)
                return
            }
            
            let sortedWords = folderWords.sorted { (a: SavedWord, b: SavedWord) in
                (a.savedDate ?? Date()) > (b.savedDate ?? Date())
            }

            
            for savedWord in sortedWords.prefix(count) {
                let hskWord = convertToHSKWord(savedWord)
                wordHistory.append(hskWord)
            }
            
            // Fill remaining with random if not enough
            if wordHistory.count < count {
                let remainingCount = count - wordHistory.count
                let tempHistory = wordHistory
                loadRandomWords(count: remainingCount)
                wordHistory = tempHistory + wordHistory
            }
        } catch {
            print("Error loading folder words: \(error)")
            loadRandomWords(count: count)
        }
    }
    
    private func loadMixedWords(count: Int) {
        // Load 50% favorites and 50% random
        let halfCount = count / 2
        
        // Load favorites first
        let favoriteWords = wordDataManager.savedWords.filter { $0.isFavorite }
        let favoritesToAdd = min(halfCount, favoriteWords.count)
        
        for savedWord in favoriteWords.prefix(favoritesToAdd) {
            let hskWord = convertToHSKWord(savedWord)
            wordHistory.append(hskWord)
        }
        
        // Fill rest with random
        let remainingCount = count - wordHistory.count
        loadRandomWords(count: remainingCount)
        
        // Shuffle to mix them up
        wordHistory.shuffle()
    }
    
    private func convertToHSKWord(_ savedWord: SavedWord) -> HSKWord {
        return HSKWord(
            hanzi: savedWord.hanzi ?? "",
            pinyin: savedWord.pinyin ?? "",
            meaning: savedWord.meaning ?? "",
            example: savedWord.example,
            hskLevel: Int(savedWord.hskLevel)
        )
    }
    
    // MARK: - Word Navigation
    func getNextWord() {
        // If we're at the end of history, load more words
        if currentIndex == wordHistory.count - 1 {
            switch wordSourceMode {
            case .random:
                // Add a new random word
                let newWord = HSKDatabaseSeeder.shared.getRandomWord()
                if !wordHistory.contains(where: { $0.hanzi == newWord.hanzi }) {
                    wordHistory.append(newWord)
                } else {
                    // Try to find another random word
                    let allWords = HSKDatabaseSeeder.shared.getSampleWords()
                    if let uniqueWord = allWords.first(where: { word in
                        !wordHistory.contains(where: { $0.hanzi == word.hanzi })
                    }) {
                        wordHistory.append(uniqueWord)
                    }
                }
                
            case .favorites:
                // Cycle through favorites
                if wordHistory.count > 0 {
                    let cycleIndex = (currentIndex + 1) % wordHistory.count
                    if cycleIndex < wordHistory.count {
                        currentWord = wordHistory[cycleIndex]
                        checkIfSaved()
                        wordDataManager.saveToUserDefaults(word: currentWord)
                        return
                    }
                }
                
            case .folder:
                // Cycle through folder words
                if wordHistory.count > 0 {
                    let cycleIndex = (currentIndex + 1) % wordHistory.count
                    if cycleIndex < wordHistory.count {
                        currentWord = wordHistory[cycleIndex]
                        checkIfSaved()
                        wordDataManager.saveToUserDefaults(word: currentWord)
                        return
                    }
                }
                
            case .mixed:
                // Add either random or favorite
                if Bool.random() && !wordDataManager.savedWords.isEmpty {
                    let randomSaved = wordDataManager.savedWords.randomElement()!
                    let hskWord = convertToHSKWord(randomSaved)
                    if !wordHistory.contains(where: { $0.hanzi == hskWord.hanzi }) {
                        wordHistory.append(hskWord)
                    }
                } else {
                    let newWord = HSKDatabaseSeeder.shared.getRandomWord()
                    if !wordHistory.contains(where: { $0.hanzi == newWord.hanzi }) {
                        wordHistory.append(newWord)
                    }
                }
            }
        }
        
        // Move to next word
        if currentIndex < wordHistory.count - 1 {
            currentIndex += 1
            currentWord = wordHistory[currentIndex]
            checkIfSaved()
            wordDataManager.saveToUserDefaults(word: currentWord)
        }
    }
    
    func getPreviousWord() {
        if currentIndex > 0 {
            currentIndex -= 1
            currentWord = wordHistory[currentIndex]
            checkIfSaved()
            wordDataManager.saveToUserDefaults(word: currentWord)
        }
    }
    
    // MARK: - Save Management
    func checkIfSaved() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(format: "hanzi == %@", currentWord.hanzi)
        
        do {
            let results = try context.fetch(request)
            isSaved = !results.isEmpty
        } catch {
            print("Error checking saved status: \(error)")
            isSaved = false
        }
    }
    
    func toggleSave() {
        if isSaved {
            // Remove from saved
            let context = PersistenceController.shared.container.viewContext
            let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
            request.predicate = NSPredicate(format: "hanzi == %@", currentWord.hanzi)
            
            do {
                let results = try context.fetch(request)
                if let wordToDelete = results.first {
                    wordDataManager.deleteWord(wordToDelete)
                    isSaved = false
                }
            } catch {
                print("Error removing saved word: \(error)")
            }
        } else {
            // Save the word
            wordDataManager.saveWord(currentWord)
            isSaved = true
        }
    }
    
    // MARK: - Audio
    func speakWord() {
        synthesizer.stopSpeaking(at: .immediate)
        
        // Create utterance with Chinese voice
        let utterance = AVSpeechUtterance(string: currentWord.hanzi)
        
        // Try to get Chinese voice (prefer Mainland, then HK, then Taiwan)
        if let voice = AVSpeechSynthesisVoice(language: "zh-CN") {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: "zh-HK") {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: "zh-TW") {
            utterance.voice = voice
        }
        
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func speakWordSlow() {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: currentWord.hanzi)
        
        if let voice = AVSpeechSynthesisVoice(language: "zh-CN") {
            utterance.voice = voice
        }
        
        utterance.rate = 0.2 // Even slower for learning
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - UI Support
    func toggleDefinition() {
        withAnimation(.spring()) {
            showingDefinition.toggle()
        }
    }
    
    // MARK: - Share & Export
    func shareWord() -> String {
        """
        Chinese Word of the Day
        
        \(currentWord.hanzi)
        \(currentWord.pinyin)
        
        Meaning: \(currentWord.meaning)
        
        \(currentWord.example ?? "")
        
        Learn Chinese with Chinese Word Lock Screen app!
        """
    }
    
    // MARK: - Word Details
    func getWordDetails() -> [(label: String, value: String)] {
        var details: [(String, String)] = []
        
        details.append(("Character", currentWord.hanzi))
        details.append(("Pinyin", currentWord.pinyin))
        details.append(("Meaning", currentWord.meaning))
        details.append(("HSK Level", "HSK \(currentWord.hskLevel)"))
        
        if let example = currentWord.example {
            details.append(("Example", example))
        }
        
        // Add tone information
        let tones = analyzeTones(currentWord.pinyin)
        details.append(("Tones", tones))
        
        return details
    }
    
    private func analyzeTones(_ pinyin: String) -> String {
        var tonePattern = ""
        let syllables = pinyin.split(separator: " ")
        
        for syllable in syllables {
            let tone = detectTone(String(syllable))
            if !tonePattern.isEmpty {
                tonePattern += " + "
            }
            tonePattern += "Tone \(tone)"
        }
        
        return tonePattern
    }
    
    private func detectTone(_ syllable: String) -> String {
        let tone1 = ["ā", "ē", "ī", "ō", "ū", "ǖ"]
        let tone2 = ["á", "é", "í", "ó", "ú", "ǘ"]
        let tone3 = ["ǎ", "ě", "ǐ", "ǒ", "ǔ", "ǚ"]
        let tone4 = ["à", "è", "ì", "ò", "ù", "ǜ"]
        
        for char in syllable {
            let charStr = String(char)
            if tone1.contains(where: { charStr.contains($0) }) { return "1 (High)" }
            if tone2.contains(where: { charStr.contains($0) }) { return "2 (Rising)" }
            if tone3.contains(where: { charStr.contains($0) }) { return "3 (Dipping)" }
            if tone4.contains(where: { charStr.contains($0) }) { return "4 (Falling)" }
        }
        return "Neutral"
    }
    
    // MARK: - Session Management
    func refreshWord() {
        currentWord = HSKDatabaseSeeder.shared.getRandomWord()
        checkIfSaved()
        wordDataManager.saveToUserDefaults(word: currentWord)
    }
    
    func loadWordForLevel(_ level: Int) {
        if let word = HSKDatabaseSeeder.shared.getWordForLevel(level) {
            currentWord = word
            if !wordHistory.contains(where: { $0.hanzi == word.hanzi }) {
                wordHistory.append(word)
                currentIndex = wordHistory.count - 1
            }
            checkIfSaved()
            wordDataManager.saveToUserDefaults(word: currentWord)
        }
    }
    
    // MARK: - Statistics
    func getTodayWordCount() -> Int {
        // In a real app, you'd track when words were viewed
        // For now, return current session count
        return wordHistory.count
    }
    
    func getSessionProgress() -> Double {
        guard !wordHistory.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(wordHistory.count)
    }
    
    func getWordSourceInfo() -> String {
        switch wordSourceMode {
        case .random:
            return "Learning from all HSK levels"
        case .favorites:
            let count = wordDataManager.savedWords.filter { $0.isFavorite }.count
            return "Learning from \(count) favorite words"
        case .folder:
            if let folderId = selectedFolderId {
                let context = PersistenceController.shared.container.viewContext
                if let folder = try? context.existingObject(with: folderId) as? PersonalFolder {
                    let wordCount = (folder.words as? Set<SavedWord>)?.count ?? 0
                    return "Learning from \(folder.name ?? "folder") (\(wordCount) words)"
                }
            }
            return "No folder selected"
        case .mixed:
            let favoriteCount = wordDataManager.savedWords.filter { $0.isFavorite }.count
            return "Mixed mode: Random + \(favoriteCount) favorites"
        }
    }
}
