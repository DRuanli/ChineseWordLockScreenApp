//
//  LibraryView.swift
//  ChineseWordLockScreen
//
//  Enhanced version with complete features
//

import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var wordDataManager = WordDataManager.shared
    
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedHSKFilter: Int? = nil
    @State private var selectedWordType: WordType? = nil
    @State private var showingFlashcardMode = false
    @State private var showingExportSheet = false
    @State private var showingCreateFolder = false
    @State private var sortOption: SortOption = .recentlyAdded
    @State private var viewMode: ViewMode = .list
    @State private var selectedWords: Set<SavedWord> = []
    @State private var isMultiSelectMode = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedWord.savedDate, ascending: false)],
        animation: .default)
    private var allSavedWords: FetchedResults<SavedWord>
    
    enum WordType: String, CaseIterable {
        case noun = "名词"
        case verb = "动词"
        case adjective = "形容词"
        case all = "全部"
    }
    
    enum SortOption: String, CaseIterable {
        case recentlyAdded = "最新添加"
        case mostStudied = "最常学习"
        case leastStudied = "最少学习"
        case alphabetical = "字母顺序"
        case hskLevel = "HSK级别"
    }
    
    enum ViewMode: String, CaseIterable {
        case list = "列表"
        case grid = "网格"
    }
    
    var filteredWords: [SavedWord] {
        let baseFilter = { (word: SavedWord) -> Bool in
            // Tab filter
            switch selectedTab {
            case 1: // Favorites
                guard word.isFavorite else { return false }
            case 2: // Hard Words
                guard word.incorrectCount > word.correctCount else { return false }
            default:
                break
            }
            
            // Search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesSearch = (word.hanzi?.contains(searchText) ?? false) ||
                                   (word.pinyin?.lowercased().contains(searchLower) ?? false) ||
                                   (word.meaning?.lowercased().contains(searchLower) ?? false)
                guard matchesSearch else { return false }
            }
            
            // HSK filter
            if let hskFilter = selectedHSKFilter {
                guard word.hskLevel == hskFilter else { return false }
            }
            
            return true
        }
        
        var filtered = allSavedWords.filter(baseFilter)
        
        // Sort
        switch sortOption {
        case .recentlyAdded:
            filtered.sort { ($0.savedDate ?? Date()) > ($1.savedDate ?? Date()) }
        case .mostStudied:
            filtered.sort { $0.reviewCount > $1.reviewCount }
        case .leastStudied:
            filtered.sort { $0.reviewCount < $1.reviewCount }
        case .alphabetical:
            filtered.sort { ($0.pinyin ?? "") < ($1.pinyin ?? "") }
        case .hskLevel:
            filtered.sort { $0.hskLevel < $1.hskLevel }
        }
        
        return filtered
    }
    
    var reviewTodayCount: Int {
        wordDataManager.wordsForReview.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    LibraryTabBar(selectedTab: $selectedTab)
                    
                    // Search and Filter Bar
                    SearchFilterBar(
                        searchText: $searchText,
                        selectedHSKFilter: $selectedHSKFilter,
                        selectedWordType: $selectedWordType,
                        sortOption: $sortOption,
                        viewMode: $viewMode
                    )
                    
                    // Review Today Badge
                    if reviewTodayCount > 0 && selectedTab == 0 {
                        ReviewTodayBadge(count: reviewTodayCount) {
                            showingFlashcardMode = true
                        }
                    }
                    
                    // Words List/Grid
                    if filteredWords.isEmpty {
                        EmptyLibraryView(tab: selectedTab)
                    } else {
                        if viewMode == .list {
                            WordListView(
                                words: filteredWords,
                                selectedWords: $selectedWords,
                                isMultiSelectMode: $isMultiSelectMode
                            )
                        } else {
                            WordGridView(
                                words: filteredWords,
                                selectedWords: $selectedWords,
                                isMultiSelectMode: $isMultiSelectMode
                            )
                        }
                    }
                }
            }
            .navigationTitle("我的词库")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isMultiSelectMode {
                        Button("取消") {
                            isMultiSelectMode = false
                            selectedWords.removeAll()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isMultiSelectMode {
                        Button("全选") {
                            selectedWords = Set(filteredWords)
                        }
                    } else {
                        Menu {
                            Button {
                                showingFlashcardMode = true
                            } label: {
                                Label("Flashcard模式", systemImage: "rectangle.stack")
                            }
                            
                            Button {
                                showingExportSheet = true
                            } label: {
                                Label("导出CSV", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                isMultiSelectMode = true
                            } label: {
                                Label("多选", systemImage: "checkmark.circle")
                            }
                            
                            Button {
                                showingCreateFolder = true
                            } label: {
                                Label("新建文件夹", systemImage: "folder.badge.plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFlashcardMode) {
                FlashcardModeView(words: Array(filteredWords))
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(words: Array(selectedWords.isEmpty ? Set(filteredWords) : selectedWords))
            }
            .sheet(isPresented: $showingCreateFolder) {
                CreateFolderView()
            }
            .overlay(
                // Multi-select bottom bar
                isMultiSelectMode && !selectedWords.isEmpty ?
                MultiSelectBottomBar(
                    selectedCount: selectedWords.count,
                    onDelete: deleteSelectedWords,
                    onExport: exportSelectedWords,
                    onAddToFolder: addSelectedToFolder
                ) : nil,
                alignment: .bottom
            )
        }
    }
    
    private func deleteSelectedWords() {
        withAnimation {
            selectedWords.forEach { viewContext.delete($0) }
            try? viewContext.save()
            selectedWords.removeAll()
            isMultiSelectMode = false
            wordDataManager.fetchSavedWords()
        }
    }
    
    private func exportSelectedWords() {
        showingExportSheet = true
    }
    
    private func addSelectedToFolder() {
        // Implementation for folder management
    }
}

// MARK: - Tab Bar
struct LibraryTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "All Words", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Favorites ♥", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "Hard Words", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.blue : Color.gray.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 10)
                )
        }
    }
}

// MARK: - Search and Filter Bar
struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedHSKFilter: Int?
    @Binding var selectedWordType: LibraryView.WordType?
    @Binding var sortOption: LibraryView.SortOption
    @Binding var viewMode: LibraryView.ViewMode
    
    @State private var showingFilters = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索汉字、拼音或意思", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(hasActiveFilters ? .blue : .secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Filter chips
            if showingFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // HSK Level filters
                        ForEach(3...6, id: \.self) { level in
                            FilterChip(
                                title: "HSK\(level)",
                                isSelected: selectedHSKFilter == level
                            ) {
                                selectedHSKFilter = selectedHSKFilter == level ? nil : level
                            }
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        // Sort options
                        Menu {
                            ForEach(LibraryView.SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    Label(
                                        option.rawValue,
                                        systemImage: sortOption == option ? "checkmark" : ""
                                    )
                                }
                            }
                        } label: {
                            FilterChip(title: "排序: \(sortOption.rawValue)", isSelected: false) { }
                        }
                        
                        // View mode toggle
                        Button {
                            viewMode = viewMode == .list ? .grid : .list
                        } label: {
                            Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var hasActiveFilters: Bool {
        selectedHSKFilter != nil || selectedWordType != nil || sortOption != .recentlyAdded
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

// MARK: - Review Badge
struct ReviewTodayBadge: View {
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.orange)
                
                Text("Bạn có \(count) từ cần ôn hôm nay")
                    .font(.subheadline)
                
                Spacer()
                
                Text("Bắt đầu")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Word List View
struct WordListView: View {
    let words: [SavedWord]
    @Binding var selectedWords: Set<SavedWord>
    @Binding var isMultiSelectMode: Bool
    
    var body: some View {
        List {
            ForEach(words, id: \.self) { word in
                WordRowEnhanced(
                    word: word,
                    isSelected: selectedWords.contains(word),
                    isMultiSelectMode: isMultiSelectMode,
                    onSelect: {
                        if isMultiSelectMode {
                            if selectedWords.contains(word) {
                                selectedWords.remove(word)
                            } else {
                                selectedWords.insert(word)
                            }
                        }
                    }
                )
            }
            .onDelete(perform: deleteWords)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func deleteWords(at offsets: IndexSet) {
        withAnimation {
            offsets.map { words[$0] }.forEach { word in
                WordDataManager.shared.deleteWord(word)
            }
        }
    }
}

// MARK: - Word Grid View
struct WordGridView: View {
    let words: [SavedWord]
    @Binding var selectedWords: Set<SavedWord>
    @Binding var isMultiSelectMode: Bool
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(words, id: \.self) { word in
                    WordCardView(
                        word: word,
                        isSelected: selectedWords.contains(word),
                        isMultiSelectMode: isMultiSelectMode,
                        onSelect: {
                            if isMultiSelectMode {
                                if selectedWords.contains(word) {
                                    selectedWords.remove(word)
                                } else {
                                    selectedWords.insert(word)
                                }
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Enhanced Word Row
struct WordRowEnhanced: View {
    let word: SavedWord
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onSelect: () -> Void
    
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var showingDetail = false
    @State private var showingNote = false
    @State private var personalNote = ""
    
    var body: some View {
        HStack(spacing: 12) {
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .onTapGesture(perform: onSelect)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(word.hanzi ?? "")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Status icons
                        if word.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if word.reviewCount > 5 {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if word.incorrectCount > word.correctCount {
                            Text("🟨")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        wordDataManager.toggleFavorite(for: word)
                    } label: {
                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                            .foregroundColor(word.isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                Text(word.pinyin ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(word.meaning ?? "")
                    .font(.body)
                    .lineLimit(2)
                
                if let example = word.example {
                    Text(example)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Label("HSK \(word.hskLevel)", systemImage: "graduationcap.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if word.reviewCount > 0 {
                        Label("\(word.reviewCount)", systemImage: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let nextReview = word.nextReviewDate {
                        Text(nextReviewText(for: nextReview))
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isMultiSelectMode {
                showingDetail = true
            } else {
                onSelect()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                wordDataManager.deleteWord(word)
            } label: {
                Label("删除", systemImage: "trash")
            }
            
            Button {
                showingNote = true
            } label: {
                Label("笔记", systemImage: "note.text")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading) {
            Button {
                wordDataManager.markWordAsRemembered(word)
            } label: {
                Label("记得", systemImage: "checkmark")
            }
            .tint(.green)
            
            Button {
                wordDataManager.markWordAsForgotten(word)
            } label: {
                Label("忘记", systemImage: "xmark")
            }
            .tint(.orange)
        }
        .sheet(isPresented: $showingDetail) {
            WordDetailView(word: word)
        }
        .sheet(isPresented: $showingNote) {
            NoteEditView(word: word, note: $personalNote)
        }
    }
    
    private func nextReviewText(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 { return "今天复习" }
        if days == 1 { return "明天复习" }
        return "\(days)天后复习"
    }
}

// MARK: - Word Card View (Grid)
struct WordCardView: View {
    let word: SavedWord
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            if isMultiSelectMode {
                HStack {
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
            
            Text(word.hanzi ?? "")
                .font(.largeTitle)
                .fontWeight(.medium)
            
            Text(word.pinyin ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(word.meaning ?? "")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Spacer()
            
            HStack {
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("HSK\(word.hskLevel)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .overlay(
            isSelected ?
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.blue, lineWidth: 2)
            : nil
        )
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Empty State
struct EmptyLibraryView: View {
    let tab: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: tab == 1 ? "heart" : tab == 2 ? "exclamationmark.triangle" : "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(emptyTitle)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if tab == 0 {
                NavigationLink(destination: HomeView()) {
                    Text("浏览词汇")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyTitle: String {
        switch tab {
        case 1: return "没有收藏的词汇"
        case 2: return "没有困难词汇"
        default: return "词库为空"
        }
    }
    
    private var emptyMessage: String {
        switch tab {
        case 1: return "点击爱心图标来收藏你喜欢的词汇"
        case 2: return "练习中标记为困难的词汇会显示在这里"
        default: return "开始学习并保存词汇来建立你的个人词库"
        }
    }
}

// MARK: - Multi-select Bottom Bar
struct MultiSelectBottomBar: View {
    let selectedCount: Int
    let onDelete: () -> Void
    let onExport: () -> Void
    let onAddToFolder: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            Text("已选 \(selectedCount) 个")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button(action: onAddToFolder) {
                Image(systemName: "folder.badge.plus")
            }
            
            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
        )
    }
}

// MARK: - Supporting Views
struct FlashcardModeView: View {
    let words: [SavedWord]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Text("Flashcard Mode with \(words.count) words")
                .navigationTitle("Flashcards")
                .navigationBarItems(
                    trailing: Button("Done") { dismiss() }
                )
        }
    }
}

struct ExportView: View {
    let words: [SavedWord]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("导出 \(words.count) 个词汇")
                    .font(.title2)
                
                Button("导出为CSV") {
                    // Export logic
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("导出")
            .navigationBarItems(
                trailing: Button("取消") { dismiss() }
            )
        }
    }
}

struct CreateFolderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var folderName = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("文件夹名称", text: $folderName)
            }
            .navigationTitle("新建文件夹")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("创建") {
                    // Create folder logic
                    dismiss()
                }
                .disabled(folderName.isEmpty)
            )
        }
    }
}

struct WordDetailView: View {
    let word: SavedWord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text(word.hanzi ?? "")
                        .font(.system(size: 80))
                    
                    Text(word.pinyin ?? "")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(word.meaning ?? "")
                        .font(.title3)
                    
                    if let example = word.example {
                        Text(example)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("词汇详情")
            .navigationBarItems(
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

struct NoteEditView: View {
    let word: SavedWord
    @Binding var note: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("个人笔记") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("\(word.hanzi ?? "") - 笔记")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("保存") {
                    // Save note logic
                    dismiss()
                }
            )
        }
    }
}
