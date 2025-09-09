//
//  HomeViewModel.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import Foundation
import SwiftUI
import CoreData
import AVFoundation

class HomeViewModel: ObservableObject {
    @Published var currentWord: HSKWord
    @Published var isSaved: Bool = false
    @Published var showingDefinition: Bool = true
    
    private let wordDataManager = WordDataManager.shared
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        self.currentWord = HSKDatabaseSeeder.shared.getWordOfDay()
        checkIfSaved()
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
        let utterance = AVSpeechUtterance(string: currentWord.hanzi)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
    
    func getNextWord() {
        currentWord = HSKDatabaseSeeder.shared.getRandomWord()
        checkIfSaved()
        wordDataManager.saveToUserDefaults(word: currentWord)
    }
    
    func toggleDefinition() {
        withAnimation(.spring()) {
            showingDefinition.toggle()
        }
    }
}
