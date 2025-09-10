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
            // HSK3 Words (20 words)
            HSKWord(hanzi: "办法", pinyin: "bànfǎ", meaning: "method, way", example: "我们需要想个办法解决这个问题。", hskLevel: 3),
            HSKWord(hanzi: "帮助", pinyin: "bāngzhù", meaning: "help, assist", example: "谢谢你的帮助！", hskLevel: 3),
            HSKWord(hanzi: "比赛", pinyin: "bǐsài", meaning: "competition, match", example: "明天有一场足球比赛。", hskLevel: 3),
            HSKWord(hanzi: "表示", pinyin: "biǎoshì", meaning: "express, indicate", example: "他表示同意我的看法。", hskLevel: 3),
            HSKWord(hanzi: "城市", pinyin: "chéngshì", meaning: "city", example: "上海是中国最大的城市。", hskLevel: 3),
            HSKWord(hanzi: "迟到", pinyin: "chídào", meaning: "be late", example: "对不起，我迟到了。", hskLevel: 3),
            HSKWord(hanzi: "除了", pinyin: "chúle", meaning: "except, besides", example: "除了英语，我还会说中文。", hskLevel: 3),
            HSKWord(hanzi: "打算", pinyin: "dǎsuàn", meaning: "plan, intend", example: "你打算什么时候去旅行？", hskLevel: 3),
            HSKWord(hanzi: "担心", pinyin: "dānxīn", meaning: "worry", example: "不要担心，一切都会好的。", hskLevel: 3),
            HSKWord(hanzi: "地方", pinyin: "dìfang", meaning: "place", example: "这个地方很漂亮。", hskLevel: 3),
            
            // HSK4 Words (20 words)
            HSKWord(hanzi: "安排", pinyin: "ānpái", meaning: "arrange, plan", example: "我已经安排好了明天的行程。", hskLevel: 4),
            HSKWord(hanzi: "保护", pinyin: "bǎohù", meaning: "protect", example: "我们要保护环境。", hskLevel: 4),
            HSKWord(hanzi: "表扬", pinyin: "biǎoyáng", meaning: "praise", example: "老师表扬了他的进步。", hskLevel: 4),
            HSKWord(hanzi: "诚实", pinyin: "chéngshí", meaning: "honest", example: "诚实是最好的品质。", hskLevel: 4),
            HSKWord(hanzi: "成功", pinyin: "chénggōng", meaning: "succeed, success", example: "努力就会成功。", hskLevel: 4),
            HSKWord(hanzi: "程度", pinyin: "chéngdù", meaning: "degree, level", example: "你的中文程度很高。", hskLevel: 4),
            HSKWord(hanzi: "抽烟", pinyin: "chōuyān", meaning: "smoke", example: "请不要在这里抽烟。", hskLevel: 4),
            HSKWord(hanzi: "出差", pinyin: "chūchāi", meaning: "business trip", example: "他经常出差到国外。", hskLevel: 4),
            HSKWord(hanzi: "传真", pinyin: "chuánzhēn", meaning: "fax", example: "请把文件传真给我。", hskLevel: 4),
            HSKWord(hanzi: "窗户", pinyin: "chuānghu", meaning: "window", example: "请打开窗户通风。", hskLevel: 4),
            
            // HSK5 Words (30 words)
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
            HSKWord(hanzi: "差距", pinyin: "chājù", meaning: "gap, disparity", example: "城乡差距正在缩小。", hskLevel: 5),
            HSKWord(hanzi: "产品", pinyin: "chǎnpǐn", meaning: "product", example: "这个产品质量很好。", hskLevel: 5),
            HSKWord(hanzi: "长途", pinyin: "chángtú", meaning: "long distance", example: "长途旅行很累。", hskLevel: 5),
            HSKWord(hanzi: "抄写", pinyin: "chāoxiě", meaning: "copy, transcribe", example: "请抄写这段文字。", hskLevel: 5),
            HSKWord(hanzi: "朝代", pinyin: "cháodài", meaning: "dynasty", example: "唐朝是中国历史上的重要朝代。", hskLevel: 5),
            
            // HSK6 Words (20 words)
            HSKWord(hanzi: "哀悼", pinyin: "āidào", meaning: "mourn, grieve", example: "全国人民哀悼逝去的英雄。", hskLevel: 6),
            HSKWord(hanzi: "爱戴", pinyin: "àidài", meaning: "love and respect", example: "他深受人民的爱戴。", hskLevel: 6),
            HSKWord(hanzi: "暧昧", pinyin: "àimèi", meaning: "ambiguous", example: "他的态度很暧昧。", hskLevel: 6),
            HSKWord(hanzi: "安置", pinyin: "ānzhì", meaning: "arrange, settle", example: "政府安置了受灾群众。", hskLevel: 6),
            HSKWord(hanzi: "案例", pinyin: "ànlì", meaning: "case, example", example: "这是一个成功的案例。", hskLevel: 6),
            HSKWord(hanzi: "按摩", pinyin: "ànmó", meaning: "massage", example: "按摩可以缓解疲劳。", hskLevel: 6),
            HSKWord(hanzi: "昂贵", pinyin: "ángguì", meaning: "expensive", example: "这件衣服太昂贵了。", hskLevel: 6),
            HSKWord(hanzi: "熬夜", pinyin: "áoyè", meaning: "stay up late", example: "不要经常熬夜工作。", hskLevel: 6),
            HSKWord(hanzi: "巴不得", pinyin: "bābude", meaning: "eager, can't wait", example: "他巴不得马上见到你。", hskLevel: 6),
            HSKWord(hanzi: "拔苗助长", pinyin: "bámiáozhùzhǎng", meaning: "spoil by excessive enthusiasm", example: "教育孩子不能拔苗助长。", hskLevel: 6)
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
    
    func getWordForLevel(_ level: Int) -> HSKWord? {
        let levelWords = getWords(for: level)
        if levelWords.isEmpty {
            return getWordOfDay()
        }
        let dayOfYear = Calendar.current.ordinateOfDay(for: Date()) ?? 1
        let index = dayOfYear % levelWords.count
        return levelWords[index]
    }
    
    func getRandomWordForLevel(_ level: Int) -> HSKWord? {
        let levelWords = getWords(for: level)
        return levelWords.randomElement()
    }
}

extension Calendar {
    func ordinateOfDay(for date: Date) -> Int? {
        let components = dateComponents([.day], from: startOfYear(for: date), to: date)
        return (components.day ?? 0) + 1
    }
    
    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components) ?? date
    }
}
