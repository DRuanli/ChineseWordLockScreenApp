//
//  WordLearningState.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 11/9/25.
//

import Foundation
import SwiftUI

enum WordLearningState: Int16, CaseIterable {
    case new = 0           // Never seen
    case introduced = 1    // First exposure
    case learning = 2      // Active learning phase (Days 1-3)
    case review = 3        // Short-term review (Days 4-14)
    case mastered = 4      // Long-term review (Days 15+)
    
    var displayName: String {
        switch self {
        case .new: return "Từ mới"
        case .introduced: return "Đã giới thiệu"
        case .learning: return "Đang học"
        case .review: return "Ôn tập"
        case .mastered: return "Thành thạo"
        }
    }
    
    var color: Color {
        switch self {
        case .new: return .blue
        case .introduced: return .orange
        case .learning: return .yellow
        case .review: return .green
        case .mastered: return .purple
        }
    }
}

enum QuizType: CaseIterable {
    case recognition    // See hanzi → choose meaning
    case recall        // See meaning → type pinyin/hanzi
    case audio         // Hear pronunciation → choose hanzi
    case context       // Complete sentence with word
    
    var weight: Double {
        switch self {
        case .recognition: return 0.4
        case .recall: return 0.3
        case .context: return 0.2
        case .audio: return 0.1
        }
    }
}
