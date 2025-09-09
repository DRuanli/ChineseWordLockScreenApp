//
//  HSKWord.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import Foundation

struct HSKWord: Codable, Identifiable {
    let id = UUID()
    let hanzi: String
    let pinyin: String
    let meaning: String
    let example: String?
    let hskLevel: Int
    
    enum CodingKeys: String, CodingKey {
        case hanzi, pinyin, meaning, example, hskLevel
    }
}
