//
//  HomeViewModel.swift
//  ChineseWordLockScreen
//
//  Enhanced for redesigned vocabulary card interface
//

import Foundation
import SwiftUI
import CoreData
import AVFoundation

class HomeViewModel: ObservableObject {
    @Published var currentWord: HSKWord
    @Published var isSaved: Bool = false
    @Published var showingDefinition: Bool = true
    @Published var wordHistory: [HSKWord] = []
    @Published var currentIndex: Int = 0
    
    private let wordDataManager = WordDataManager.shared
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        self.currentWord = HSKDatabaseSeeder.shared.getWordOfDay()
        self.wordHistory.append(currentWord)
        checkIfSaved()
        
        // Configure speech synthesizer
        synthesizer.usesApplicationAudioSession = false
    }
    
    func checkIfSaved() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<SavedWord> = SavedWord.fetchRequest()
        request.predicate = NSPredicate(format: "hanzi == %@", currentWord.hanzi)
        
        do {
            let results = try context.fetch(request)
            isSaved = !results.isEmpty
        } catch {
            print("Error checking saved status: \(error)")
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
    
    func speakWord() {
        synthesizer.stopSpeaking(at: .immediate)
        
        // Create utterance with Chinese voice
        let utterance = AVSpeechUtterance(string: currentWord.hanzi)
        
        // Try to get Chinese voice
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
    
    func getNextWord() {
        // Save current word to history if needed
        if currentIndex == wordHistory.count - 1 {
            let newWord = HSKDatabaseSeeder.shared.getRandomWord()
            wordHistory.append(newWord)
        }
        
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
    
    func toggleDefinition() {
        withAnimation(.spring()) {
            showingDefinition.toggle()
        }
    }
    
    // Helper method to get random words for session
    func loadSessionWords(count: Int = 5) -> [HSKWord] {
        var words: [HSKWord] = []
        let allWords = HSKDatabaseSeeder.shared.getSampleWords()
        
        for _ in 0..<count {
            if let randomWord = allWords.randomElement() {
                words.append(randomWord)
            }
        }
        
        return words
    }
    
    // Share functionality
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
    
    // Get word details for info sheet
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
}
