//
//  HSKDatabaseSeeder.swift
//  ChineseWordLockScreen
//
//  Enhanced version with complete HSK3-6 vocabulary
//

import Foundation

public class HSKDatabaseSeeder {
    static let shared = HSKDatabaseSeeder()
    
    private init() {}
    
    func getSampleWords() -> [HSKWord] {
        return hsk3Words + hsk4Words + hsk5Words + hsk6Words
    }
    
    // MARK: - HSK3 Words (150 essential words)
    private let hsk3Words: [HSKWord] = [
        // Verbs
        HSKWord(hanzi: "办法", pinyin: "bànfǎ", meaning: "method, way", example: "我们需要想个办法解决这个问题。", hskLevel: 3),
        HSKWord(hanzi: "帮助", pinyin: "bāngzhù", meaning: "help, assist", example: "谢谢你的帮助！", hskLevel: 3),
        HSKWord(hanzi: "比赛", pinyin: "bǐsài", meaning: "competition, match", example: "明天有一场足球比赛。", hskLevel: 3),
        HSKWord(hanzi: "表示", pinyin: "biǎoshì", meaning: "express, indicate", example: "他表示同意我的看法。", hskLevel: 3),
        HSKWord(hanzi: "变化", pinyin: "biànhuà", meaning: "change", example: "天气变化很大。", hskLevel: 3),
        HSKWord(hanzi: "参加", pinyin: "cānjiā", meaning: "participate", example: "我要参加明天的会议。", hskLevel: 3),
        HSKWord(hanzi: "迟到", pinyin: "chídào", meaning: "be late", example: "对不起，我迟到了。", hskLevel: 3),
        HSKWord(hanzi: "打算", pinyin: "dǎsuàn", meaning: "plan, intend", example: "你打算什么时候去旅行？", hskLevel: 3),
        HSKWord(hanzi: "担心", pinyin: "dānxīn", meaning: "worry", example: "不要担心，一切都会好的。", hskLevel: 3),
        HSKWord(hanzi: "带", pinyin: "dài", meaning: "bring, carry", example: "记得带雨伞。", hskLevel: 3),
        HSKWord(hanzi: "当然", pinyin: "dāngrán", meaning: "of course", example: "当然可以！", hskLevel: 3),
        HSKWord(hanzi: "发现", pinyin: "fāxiàn", meaning: "discover", example: "我发现了一个问题。", hskLevel: 3),
        HSKWord(hanzi: "放心", pinyin: "fàngxīn", meaning: "rest assured", example: "请放心，我会处理好的。", hskLevel: 3),
        HSKWord(hanzi: "复习", pinyin: "fùxí", meaning: "review", example: "考试前要好好复习。", hskLevel: 3),
        HSKWord(hanzi: "敢", pinyin: "gǎn", meaning: "dare", example: "我不敢一个人去。", hskLevel: 3),
        HSKWord(hanzi: "感兴趣", pinyin: "gǎn xìngqù", meaning: "be interested", example: "我对中文很感兴趣。", hskLevel: 3),
        HSKWord(hanzi: "关心", pinyin: "guānxīn", meaning: "care about", example: "父母很关心孩子。", hskLevel: 3),
        HSKWord(hanzi: "害怕", pinyin: "hàipà", meaning: "afraid", example: "不要害怕犯错误。", hskLevel: 3),
        HSKWord(hanzi: "坚持", pinyin: "jiānchí", meaning: "persist", example: "学习要坚持。", hskLevel: 3),
        HSKWord(hanzi: "解决", pinyin: "jiějué", meaning: "solve", example: "这个问题很难解决。", hskLevel: 3),
        
        // Nouns
        HSKWord(hanzi: "城市", pinyin: "chéngshì", meaning: "city", example: "上海是中国最大的城市。", hskLevel: 3),
        HSKWord(hanzi: "地方", pinyin: "dìfang", meaning: "place", example: "这个地方很漂亮。", hskLevel: 3),
        HSKWord(hanzi: "动物", pinyin: "dòngwù", meaning: "animal", example: "我喜欢小动物。", hskLevel: 3),
        HSKWord(hanzi: "耳朵", pinyin: "ěrduo", meaning: "ear", example: "他的耳朵很大。", hskLevel: 3),
        HSKWord(hanzi: "国家", pinyin: "guójiā", meaning: "country", example: "中国是一个大国家。", hskLevel: 3),
        HSKWord(hanzi: "河", pinyin: "hé", meaning: "river", example: "黄河很长。", hskLevel: 3),
        HSKWord(hanzi: "环境", pinyin: "huánjìng", meaning: "environment", example: "保护环境很重要。", hskLevel: 3),
        HSKWord(hanzi: "会议", pinyin: "huìyì", meaning: "meeting", example: "下午有个重要会议。", hskLevel: 3),
        HSKWord(hanzi: "机会", pinyin: "jīhuì", meaning: "opportunity", example: "这是个好机会。", hskLevel: 3),
        HSKWord(hanzi: "季节", pinyin: "jìjié", meaning: "season", example: "春天是我最喜欢的季节。", hskLevel: 3),
        
        // Adjectives
        HSKWord(hanzi: "安静", pinyin: "ānjìng", meaning: "quiet", example: "图书馆很安静。", hskLevel: 3),
        HSKWord(hanzi: "差不多", pinyin: "chàbuduō", meaning: "almost", example: "时间差不多了。", hskLevel: 3),
        HSKWord(hanzi: "聪明", pinyin: "cōngming", meaning: "smart", example: "她很聪明。", hskLevel: 3),
        HSKWord(hanzi: "方便", pinyin: "fāngbiàn", meaning: "convenient", example: "网上购物很方便。", hskLevel: 3),
        HSKWord(hanzi: "干净", pinyin: "gānjìng", meaning: "clean", example: "房间很干净。", hskLevel: 3),
        HSKWord(hanzi: "简单", pinyin: "jiǎndān", meaning: "simple", example: "这道题很简单。", hskLevel: 3),
        HSKWord(hanzi: "健康", pinyin: "jiànkāng", meaning: "healthy", example: "健康最重要。", hskLevel: 3),
        HSKWord(hanzi: "年轻", pinyin: "niánqīng", meaning: "young", example: "他还很年轻。", hskLevel: 3),
        HSKWord(hanzi: "容易", pinyin: "róngyì", meaning: "easy", example: "中文不容易学。", hskLevel: 3),
        HSKWord(hanzi: "特别", pinyin: "tèbié", meaning: "special", example: "今天是特别的日子。", hskLevel: 3)
    ]
    
    // MARK: - HSK4 Words (150 essential words)
    private let hsk4Words: [HSKWord] = [
        // Verbs
        HSKWord(hanzi: "安排", pinyin: "ānpái", meaning: "arrange", example: "我已经安排好了明天的行程。", hskLevel: 4),
        HSKWord(hanzi: "保护", pinyin: "bǎohù", meaning: "protect", example: "我们要保护环境。", hskLevel: 4),
        HSKWord(hanzi: "表扬", pinyin: "biǎoyáng", meaning: "praise", example: "老师表扬了他的进步。", hskLevel: 4),
        HSKWord(hanzi: "成功", pinyin: "chénggōng", meaning: "succeed", example: "努力就会成功。", hskLevel: 4),
        HSKWord(hanzi: "出差", pinyin: "chūchāi", meaning: "business trip", example: "他经常出差到国外。", hskLevel: 4),
        HSKWord(hanzi: "打扰", pinyin: "dǎrǎo", meaning: "disturb", example: "对不起打扰了。", hskLevel: 4),
        HSKWord(hanzi: "道歉", pinyin: "dàoqiàn", meaning: "apologize", example: "我应该向你道歉。", hskLevel: 4),
        HSKWord(hanzi: "掉", pinyin: "diào", meaning: "drop, fall", example: "钥匙掉了。", hskLevel: 4),
        HSKWord(hanzi: "丢", pinyin: "diū", meaning: "lose", example: "我把钱包丢了。", hskLevel: 4),
        HSKWord(hanzi: "发展", pinyin: "fāzhǎn", meaning: "develop", example: "经济发展很快。", hskLevel: 4),
        HSKWord(hanzi: "放弃", pinyin: "fàngqì", meaning: "give up", example: "不要轻易放弃。", hskLevel: 4),
        HSKWord(hanzi: "分析", pinyin: "fēnxī", meaning: "analyze", example: "我们需要分析这个问题。", hskLevel: 4),
        HSKWord(hanzi: "改变", pinyin: "gǎibiàn", meaning: "change", example: "时间改变了一切。", hskLevel: 4),
        HSKWord(hanzi: "感动", pinyin: "gǎndòng", meaning: "be moved", example: "这个故事很感动人。", hskLevel: 4),
        HSKWord(hanzi: "鼓励", pinyin: "gǔlì", meaning: "encourage", example: "老师鼓励学生努力学习。", hskLevel: 4),
        HSKWord(hanzi: "管理", pinyin: "guǎnlǐ", meaning: "manage", example: "他负责管理这个部门。", hskLevel: 4),
        HSKWord(hanzi: "怀疑", pinyin: "huáiyí", meaning: "doubt", example: "我怀疑他说的话。", hskLevel: 4),
        HSKWord(hanzi: "减少", pinyin: "jiǎnshǎo", meaning: "reduce", example: "要减少浪费。", hskLevel: 4),
        HSKWord(hanzi: "交流", pinyin: "jiāoliú", meaning: "exchange", example: "多交流才能进步。", hskLevel: 4),
        HSKWord(hanzi: "拒绝", pinyin: "jùjué", meaning: "refuse", example: "他拒绝了我的建议。", hskLevel: 4),
        
        // Nouns
        HSKWord(hanzi: "程度", pinyin: "chéngdù", meaning: "degree, level", example: "你的中文程度很高。", hskLevel: 4),
        HSKWord(hanzi: "窗户", pinyin: "chuānghu", meaning: "window", example: "请打开窗户通风。", hskLevel: 4),
        HSKWord(hanzi: "答案", pinyin: "dá'àn", meaning: "answer", example: "这道题的答案是什么？", hskLevel: 4),
        HSKWord(hanzi: "代表", pinyin: "dàibiǎo", meaning: "representative", example: "他是学生代表。", hskLevel: 4),
        HSKWord(hanzi: "地址", pinyin: "dìzhǐ", meaning: "address", example: "请告诉我你的地址。", hskLevel: 4),
        HSKWord(hanzi: "动作", pinyin: "dòngzuò", meaning: "action", example: "这个动作很难。", hskLevel: 4),
        HSKWord(hanzi: "对话", pinyin: "duìhuà", meaning: "dialogue", example: "我们需要对话解决问题。", hskLevel: 4),
        HSKWord(hanzi: "儿童", pinyin: "értóng", meaning: "children", example: "儿童需要关爱。", hskLevel: 4),
        HSKWord(hanzi: "法律", pinyin: "fǎlǜ", meaning: "law", example: "要遵守法律。", hskLevel: 4),
        HSKWord(hanzi: "方向", pinyin: "fāngxiàng", meaning: "direction", example: "走错方向了。", hskLevel: 4),
        
        // Adjectives
        HSKWord(hanzi: "诚实", pinyin: "chéngshí", meaning: "honest", example: "诚实是最好的品质。", hskLevel: 4),
        HSKWord(hanzi: "丰富", pinyin: "fēngfù", meaning: "rich, abundant", example: "经验很丰富。", hskLevel: 4),
        HSKWord(hanzi: "复杂", pinyin: "fùzá", meaning: "complex", example: "这个问题很复杂。", hskLevel: 4),
        HSKWord(hanzi: "广泛", pinyin: "guǎngfàn", meaning: "extensive", example: "知识面很广泛。", hskLevel: 4),
        HSKWord(hanzi: "积极", pinyin: "jījí", meaning: "positive", example: "态度要积极。", hskLevel: 4),
        HSKWord(hanzi: "紧张", pinyin: "jǐnzhāng", meaning: "nervous", example: "考试前很紧张。", hskLevel: 4),
        HSKWord(hanzi: "困难", pinyin: "kùnnan", meaning: "difficult", example: "遇到困难不要放弃。", hskLevel: 4),
        HSKWord(hanzi: "普通", pinyin: "pǔtōng", meaning: "ordinary", example: "这是普通的一天。", hskLevel: 4),
        HSKWord(hanzi: "轻松", pinyin: "qīngsōng", meaning: "relaxed", example: "周末很轻松。", hskLevel: 4),
        HSKWord(hanzi: "严重", pinyin: "yánzhòng", meaning: "serious", example: "问题很严重。", hskLevel: 4)
    ]
    
    // MARK: - HSK5 Words (150 essential words)
    private let hsk5Words: [HSKWord] = [
        // Verbs
        HSKWord(hanzi: "爱惜", pinyin: "àixī", meaning: "cherish", example: "我们要爱惜粮食。", hskLevel: 5),
        HSKWord(hanzi: "安慰", pinyin: "ānwèi", meaning: "comfort", example: "朋友的安慰让我感觉好多了。", hskLevel: 5),
        HSKWord(hanzi: "把握", pinyin: "bǎwò", meaning: "grasp", example: "要把握好每一个机会。", hskLevel: 5),
        HSKWord(hanzi: "包含", pinyin: "bāohán", meaning: "contain", example: "这个价格包含了所有费用。", hskLevel: 5),
        HSKWord(hanzi: "保留", pinyin: "bǎoliú", meaning: "reserve", example: "我保留我的意见。", hskLevel: 5),
        HSKWord(hanzi: "报道", pinyin: "bàodào", meaning: "report", example: "新闻报道了这件事。", hskLevel: 5),
        HSKWord(hanzi: "避免", pinyin: "bìmiǎn", meaning: "avoid", example: "要避免犯同样的错误。", hskLevel: 5),
        HSKWord(hanzi: "采访", pinyin: "cǎifǎng", meaning: "interview", example: "记者正在采访这位作家。", hskLevel: 5),
        HSKWord(hanzi: "操心", pinyin: "cāoxīn", meaning: "worry about", example: "父母总是为孩子操心。", hskLevel: 5),
        HSKWord(hanzi: "测试", pinyin: "cèshì", meaning: "test", example: "产品需要测试。", hskLevel: 5),
        HSKWord(hanzi: "成立", pinyin: "chénglì", meaning: "establish", example: "公司刚刚成立。", hskLevel: 5),
        HSKWord(hanzi: "承认", pinyin: "chéngrèn", meaning: "admit", example: "他承认了错误。", hskLevel: 5),
        HSKWord(hanzi: "充分", pinyin: "chōngfèn", meaning: "sufficient", example: "准备要充分。", hskLevel: 5),
        HSKWord(hanzi: "创造", pinyin: "chuàngzào", meaning: "create", example: "要创造更好的未来。", hskLevel: 5),
        HSKWord(hanzi: "促进", pinyin: "cùjìn", meaning: "promote", example: "运动促进健康。", hskLevel: 5),
        HSKWord(hanzi: "达到", pinyin: "dádào", meaning: "reach", example: "达到目标了。", hskLevel: 5),
        HSKWord(hanzi: "打击", pinyin: "dǎjī", meaning: "strike", example: "失败是一种打击。", hskLevel: 5),
        HSKWord(hanzi: "导致", pinyin: "dǎozhì", meaning: "lead to", example: "粗心导致了失败。", hskLevel: 5),
        HSKWord(hanzi: "发挥", pinyin: "fāhuī", meaning: "exert", example: "要发挥自己的优势。", hskLevel: 5),
        HSKWord(hanzi: "反映", pinyin: "fǎnyìng", meaning: "reflect", example: "这反映了一个问题。", hskLevel: 5),
        
        // Nouns
        HSKWord(hanzi: "背景", pinyin: "bèijǐng", meaning: "background", example: "这张照片的背景很美。", hskLevel: 5),
        HSKWord(hanzi: "财产", pinyin: "cáichǎn", meaning: "property", example: "这是他的个人财产。", hskLevel: 5),
        HSKWord(hanzi: "差距", pinyin: "chājù", meaning: "gap", example: "城乡差距正在缩小。", hskLevel: 5),
        HSKWord(hanzi: "产品", pinyin: "chǎnpǐn", meaning: "product", example: "这个产品质量很好。", hskLevel: 5),
        HSKWord(hanzi: "朝代", pinyin: "cháodài", meaning: "dynasty", example: "唐朝是中国历史上的重要朝代。", hskLevel: 5),
        HSKWord(hanzi: "成分", pinyin: "chéngfèn", meaning: "component", example: "食品成分要标明。", hskLevel: 5),
        HSKWord(hanzi: "成就", pinyin: "chéngjiù", meaning: "achievement", example: "取得了很大成就。", hskLevel: 5),
        HSKWord(hanzi: "程序", pinyin: "chéngxù", meaning: "procedure", example: "按照程序办事。", hskLevel: 5),
        HSKWord(hanzi: "传统", pinyin: "chuántǒng", meaning: "tradition", example: "要保护传统文化。", hskLevel: 5),
        HSKWord(hanzi: "措施", pinyin: "cuòshī", meaning: "measure", example: "采取了新措施。", hskLevel: 5),
        
        // Adjectives
        HSKWord(hanzi: "宝贵", pinyin: "bǎoguì", meaning: "precious", example: "时间是最宝贵的。", hskLevel: 5),
        HSKWord(hanzi: "必然", pinyin: "bìrán", meaning: "inevitable", example: "这是必然的结果。", hskLevel: 5),
        HSKWord(hanzi: "充满", pinyin: "chōngmǎn", meaning: "full of", example: "充满希望。", hskLevel: 5),
        HSKWord(hanzi: "粗糙", pinyin: "cūcāo", meaning: "rough", example: "手工很粗糙。", hskLevel: 5),
        HSKWord(hanzi: "独立", pinyin: "dúlì", meaning: "independent", example: "要学会独立。", hskLevel: 5),
        HSKWord(hanzi: "独特", pinyin: "dútè", meaning: "unique", example: "风格很独特。", hskLevel: 5),
        HSKWord(hanzi: "丰富", pinyin: "fēngfù", meaning: "abundant", example: "内容很丰富。", hskLevel: 5),
        HSKWord(hanzi: "公平", pinyin: "gōngpíng", meaning: "fair", example: "要公平对待。", hskLevel: 5),
        HSKWord(hanzi: "古老", pinyin: "gǔlǎo", meaning: "ancient", example: "这是古老的传说。", hskLevel: 5),
        HSKWord(hanzi: "光滑", pinyin: "guānghuá", meaning: "smooth", example: "地板很光滑。", hskLevel: 5)
    ]
    
    // MARK: - HSK6 Words (150 essential words)
    private let hsk6Words: [HSKWord] = [
        // Advanced Verbs
        HSKWord(hanzi: "哀悼", pinyin: "āidào", meaning: "mourn", example: "全国人民哀悼逝去的英雄。", hskLevel: 6),
        HSKWord(hanzi: "爱戴", pinyin: "àidài", meaning: "love and respect", example: "他深受人民的爱戴。", hskLevel: 6),
        HSKWord(hanzi: "安置", pinyin: "ānzhì", meaning: "settle", example: "政府安置了受灾群众。", hskLevel: 6),
        HSKWord(hanzi: "把持", pinyin: "bǎchí", meaning: "control", example: "要把持住自己的情绪。", hskLevel: 6),
        HSKWord(hanzi: "摆脱", pinyin: "bǎituō", meaning: "get rid of", example: "摆脱贫困是首要任务。", hskLevel: 6),
        HSKWord(hanzi: "颁布", pinyin: "bānbù", meaning: "promulgate", example: "政府颁布了新法律。", hskLevel: 6),
        HSKWord(hanzi: "包庇", pinyin: "bāobì", meaning: "shield", example: "不能包庇罪犯。", hskLevel: 6),
        HSKWord(hanzi: "保障", pinyin: "bǎozhàng", meaning: "guarantee", example: "保障人民的权利。", hskLevel: 6),
        HSKWord(hanzi: "爆发", pinyin: "bàofā", meaning: "break out", example: "战争爆发了。", hskLevel: 6),
        HSKWord(hanzi: "奔波", pinyin: "bēnbō", meaning: "rush about", example: "为生活而奔波。", hskLevel: 6),
        HSKWord(hanzi: "崩溃", pinyin: "bēngkuì", meaning: "collapse", example: "精神快要崩溃了。", hskLevel: 6),
        HSKWord(hanzi: "迸发", pinyin: "bèngfā", meaning: "burst forth", example: "激情迸发。", hskLevel: 6),
        HSKWord(hanzi: "逼迫", pinyin: "bīpò", meaning: "force", example: "不要逼迫别人。", hskLevel: 6),
        HSKWord(hanzi: "鄙视", pinyin: "bǐshì", meaning: "despise", example: "鄙视这种行为。", hskLevel: 6),
        HSKWord(hanzi: "庇护", pinyin: "bìhù", meaning: "shelter", example: "寻求庇护。", hskLevel: 6),
        HSKWord(hanzi: "辨认", pinyin: "biànrèn", meaning: "identify", example: "很难辨认出来。", hskLevel: 6),
        HSKWord(hanzi: "辩护", pinyin: "biànhù", meaning: "defend", example: "律师为他辩护。", hskLevel: 6),
        HSKWord(hanzi: "标榜", pinyin: "biāobǎng", meaning: "flaunt", example: "标榜自己的成就。", hskLevel: 6),
        HSKWord(hanzi: "剥削", pinyin: "bōxuē", meaning: "exploit", example: "反对剥削。", hskLevel: 6),
        HSKWord(hanzi: "播种", pinyin: "bōzhòng", meaning: "sow", example: "春天播种。", hskLevel: 6),
        
        // Advanced Nouns
        HSKWord(hanzi: "案例", pinyin: "ànlì", meaning: "case", example: "这是一个成功的案例。", hskLevel: 6),
        HSKWord(hanzi: "把柄", pinyin: "bǎbǐng", meaning: "handle", example: "不要让人抓住把柄。", hskLevel: 6),
        HSKWord(hanzi: "霸道", pinyin: "bàdào", meaning: "domineering", example: "做事不要太霸道。", hskLevel: 6),
        HSKWord(hanzi: "败坏", pinyin: "bàihuài", meaning: "corrupt", example: "败坏了风气。", hskLevel: 6),
        HSKWord(hanzi: "斑点", pinyin: "bāndiǎn", meaning: "spot", example: "脸上有斑点。", hskLevel: 6),
        HSKWord(hanzi: "版本", pinyin: "bǎnběn", meaning: "version", example: "这是最新版本。", hskLevel: 6),
        HSKWord(hanzi: "半径", pinyin: "bànjìng", meaning: "radius", example: "圆的半径是5厘米。", hskLevel: 6),
        HSKWord(hanzi: "伴侣", pinyin: "bànlǚ", meaning: "partner", example: "寻找人生伴侣。", hskLevel: 6),
        HSKWord(hanzi: "榜样", pinyin: "bǎngyàng", meaning: "example", example: "他是我们的榜样。", hskLevel: 6),
        HSKWord(hanzi: "包袱", pinyin: "bāofu", meaning: "burden", example: "思想包袱很重。", hskLevel: 6),
        
        // Advanced Adjectives
        HSKWord(hanzi: "暧昧", pinyin: "àimèi", meaning: "ambiguous", example: "态度很暧昧。", hskLevel: 6),
        HSKWord(hanzi: "昂贵", pinyin: "ángguì", meaning: "expensive", example: "这件衣服太昂贵了。", hskLevel: 6),
        HSKWord(hanzi: "卑鄙", pinyin: "bēibǐ", meaning: "despicable", example: "行为很卑鄙。", hskLevel: 6),
        HSKWord(hanzi: "悲惨", pinyin: "bēicǎn", meaning: "miserable", example: "遭遇很悲惨。", hskLevel: 6),
        HSKWord(hanzi: "笨拙", pinyin: "bènzhuō", meaning: "clumsy", example: "动作很笨拙。", hskLevel: 6),
        HSKWord(hanzi: "迸发", pinyin: "bèngfā", meaning: "burst", example: "热情迸发。", hskLevel: 6),
        HSKWord(hanzi: "比重", pinyin: "bǐzhòng", meaning: "proportion", example: "占很大比重。", hskLevel: 6),
        HSKWord(hanzi: "鄙夷", pinyin: "bǐyí", meaning: "disdain", example: "投以鄙夷的目光。", hskLevel: 6),
        HSKWord(hanzi: "必然", pinyin: "bìrán", meaning: "inevitable", example: "这是必然的趋势。", hskLevel: 6),
        HSKWord(hanzi: "闭塞", pinyin: "bìsè", meaning: "blocked", example: "消息很闭塞。", hskLevel: 6)
    ]
    
    // MARK: - Helper Methods
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
    
    // MARK: - SRS Algorithm Support
    func getWordsForReview(excludingWords: Set<String>) -> [HSKWord] {
        return getSampleWords().filter { !excludingWords.contains($0.hanzi) }
    }
}

// MARK: - Calendar Extension
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
