//
//  HSKDatabaseSeeder.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import Foundation

class HSKDatabaseSeeder {
    static let shared = HSKDatabaseSeeder()
    
    private init() {}
    
    func getSampleWords() -> [HSKWord] {
        return [
            // HSK3 Words
            HSKWord(hanzi: "办法", pinyin: "bànfǎ", meaning: "method, way", example: "我们需要想个办法解决这个问题。", hskLevel: 3),
            HSKWord(hanzi: "帮助", pinyin: "bāngzhù", meaning: "help, assist", example: "谢谢你的帮助！", hskLevel: 3),
            HSKWord(hanzi: "比赛", pinyin: "bǐsài", meaning: "competition, match", example: "明天有一场足球比赛。", hskLevel: 3),
            HSKWord(hanzi: "表示", pinyin: "biǎoshì", meaning: "express, indicate", example: "他表示同意我的看法。", hskLevel: 3),
            HSKWord(hanzi: "城市", pinyin: "chéngshì", meaning: "city", example: "上海是中国最大的城市。", hskLevel: 3),
            
            // HSK4 Words
            HSKWord(hanzi: "安排", pinyin: "ānpái", meaning: "arrange, plan", example: "我已经安排好了明天的行程。", hskLevel: 4),
            HSKWord(hanzi: "保护", pinyin: "bǎohù", meaning: "protect", example: "我们要保护环境。", hskLevel: 4),
            HSKWord(hanzi: "表扬", pinyin: "biǎoyáng", meaning: "praise", example: "老师表扬了他的进步。", hskLevel: 4),
            HSKWord(hanzi: "诚实", pinyin: "chéngshí", meaning: "honest", example: "诚实是最好的品质。", hskLevel: 4),
            HSKWord(hanzi: "成功", pinyin: "chénggōng", meaning: "succeed, success", example: "努力就会成功。", hskLevel: 4),
            
            // HSK5 Words
            HSKWord(hanzi: "爱惜", pinyin: "àixī", meaning: "cherish, treasure", example: "我们要爱惜粮食。", hskLevel: 5),
            HSKWord(hanzi: "安慰", pinyin: "ānwèi", meaning: "comfort, console", example: "朋友的安慰让我感觉好多了。", hskLevel: 5),
            HSKWord(hanzi: "把握", pinyin: "bǎwò", meaning: "grasp, seize", example: "要把握好每一个机会。", hskLevel: 5),
            HSKWord(hanzi: "宝贵", pinyin: "bǎoguì", meaning: "valuable, precious", example: "时间是最宝贵的。", hskLevel: 5),
            HSKWord(hanzi: "背景", pinyin: "bèijǐng", meaning: "background", example: "这张照片的背景很美。", hskLevel: 5),
            HSKWord(hanzi: "彼此", pinyin: "bǐcǐ", meaning: "each other", example: "我们要彼此帮助。", hskLevel: 5),
            HSKWord(hanzi: "避免", pinyin: "bìmiǎn", meaning: "avoid", example: "要避免犯同样的错误。", hskLevel: 5),
            HSKWord(hanzi: "采访", pinyin: "cǎifǎng", meaning: "interview", example: "记者正在采访这位作家。", hskLevel: 5),
            HSKWord(hanzi: "财产", pinyin: "cáichǎn", meaning: "property, assets", example: "这是他的个人财产。", hskLevel: 5),
            HSKWord(hanzi: "操心", pinyin: "cāoxīn", meaning: "worry about", example: "父母总是为孩子操心。", hskLevel: 5),
            
            // HSK6 Words
            HSKWord(hanzi: "哀悼", pinyin: "āidào", meaning: "mourn, grieve", example: "全国人民哀悼逝去的英雄。", hskLevel: 6),
            HSKWord(hanzi: "爱戴", pinyin: "àidài", meaning: "love and respect", example: "他深受人民的爱戴。", hskLevel: 6),
            HSKWord(hanzi: "暧昧", pinyin: "àimèi", meaning: "ambiguous", example: "他的态度很暧昧。", hskLevel: 6),
            HSKWord(hanzi: "安置", pinyin: "ānzhì", meaning: "arrange, settle", example: "政府安置了受灾群众。", hskLevel: 6),
            HSKWord(hanzi: "案例", pinyin: "ànlì", meaning: "case, example", example: "这是一个成功的案例。", hskLevel: 6)
        ]
    }
    
    func getWordOfDay() -> HSKWord {
        let words = getSampleWords()
        let dayOfYear = Calendar.current.ordinateOfDay(for: Date()) ?? 1
        let index = dayOfYear % words.count
        return words[index]
    }
    
    func getRandomWord() -> HSKWord {
        let words = getSampleWords()
        return words.randomElement() ?? words[0]
    }
    
    func getWords(for level: Int) -> [HSKWord] {
        return getSampleWords().filter { $0.hskLevel == level }
    }
}

extension Calendar {
    func ordinateOfDay(for date: Date) -> Int? {
        return dateComponents([.day], from: startOfYear(for: date), to: date).day
    }
    
    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components) ?? date
    }
}
