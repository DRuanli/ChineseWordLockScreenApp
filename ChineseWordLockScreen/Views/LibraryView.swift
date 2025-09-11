//
//  LibraryView.swift
//  ChineseWordLockScreen
//
//  Enhanced library with comprehensive filtering and organization
//

import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    // View states
    @State private var selectedSection: LibrarySection = .myWords
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .grid
    @State private var sortOption: SortOption = .recentlyAdded
    @State private var selectedHSKLevels: Set<Int> = []
    @State private var showOnlyFavorites = false
    @State private var showOnlyDifficult = false
    @State private var selectedFolder: PersonalFolder?
    @State private var showingCreateFolder = false
    @State private var showingFilterSheet = false
    @State private var showingExportSheet = false
    @State private var selectedWords: Set<SavedWord> = []
    @State private var isMultiSelectMode = false
    
    // Enums
    enum LibrarySection: String, CaseIterable {
        case myWords = "Từ của tôi"
        case hskLevels = "HSK 1-6"
        case folders = "Thư mục"
        case topics = "Chủ đề"
        
        var icon: String {
            switch self {
            case .myWords: return "star.fill"
            case .hskLevels: return "graduationcap.fill"
            case .folders: return "folder.fill"
            case .topics: return "tag.fill"
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "Lưới"
        case list = "Danh sách"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case recentlyAdded = "Mới thêm"
        case alphabetical = "A-Z"
        case mostStudied = "Học nhiều"
        case difficulty = "Độ khó"
    }
    
    // Computed properties
    var filteredWords: [SavedWord] {
        let baseWords: [SavedWord]
        
        switch selectedSection {
        case .myWords:
            baseWords = wordDataManager.savedWords
        case .hskLevels:
            if selectedHSKLevels.isEmpty {
                baseWords = wordDataManager.savedWords
            } else {
                baseWords = wordDataManager.savedWords.filter { selectedHSKLevels.contains(Int($0.hskLevel)) }
            }
        case .folders:
            if let folder = selectedFolder {
                baseWords = folder.words as? [SavedWord] ?? []
            } else {
                baseWords = []
            }
        case .topics:
            baseWords = wordDataManager.savedWords // Filter by topic tags
        }
        
        var filtered = baseWords
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { word in
                (word.hanzi?.contains(searchText) ?? false) ||
                (word.pinyin?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (word.meaning?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
        
        // Apply filters
        if showOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        if showOnlyDifficult {
            filtered = filtered.filter { $0.incorrectCount > $0.correctCount }
        }
        
        // Apply sorting
        switch sortOption {
        case .recentlyAdded:
            filtered.sort { ($0.savedDate ?? Date()) > ($1.savedDate ?? Date()) }
        case .alphabetical:
            filtered.sort { ($0.pinyin ?? "") < ($1.pinyin ?? "") }
        case .mostStudied:
            filtered.sort { $0.reviewCount > $1.reviewCount }
        case .difficulty:
            filtered.sort {
                let diff1 = $0.incorrectCount > 0 ? Double($0.incorrectCount) / Double($0.correctCount + $0.incorrectCount) : 0
                let diff2 = $1.incorrectCount > 0 ? Double($1.incorrectCount) / Double($1.correctCount + $1.incorrectCount) : 0
                return diff1 > diff2
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Section Tabs
                    SectionTabBar(selectedSection: $selectedSection)
                    
                    // Search and Filter Bar
                    SearchAndFilterBar(
                        searchText: $searchText,
                        viewMode: $viewMode,
                        showingFilterSheet: $showingFilterSheet
                    )
                    
                    // Content based on section
                    Group {
                        switch selectedSection {
                        case .myWords:
                            MyWordsContent(
                                words: filteredWords,
                                viewMode: viewMode,
                                selectedWords: $selectedWords,
                                isMultiSelectMode: $isMultiSelectMode
                            )
                        case .hskLevels:
                            HSKLevelsContent(
                                words: filteredWords,
                                selectedLevels: $selectedHSKLevels,
                                viewMode: viewMode
                            )
                        case .folders:
                            FoldersContent(
                                selectedFolder: $selectedFolder,
                                words: filteredWords,
                                viewMode: viewMode,
                                showingCreateFolder: $showingCreateFolder
                            )
                        case .topics:
                            TopicsContent(
                                words: filteredWords,
                                viewMode: viewMode
                            )
                        }
                    }
                }
            }
            .navigationTitle("Thư viện từ vựng")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if isMultiSelectMode {
                            Button("Hủy chọn") {
                                isMultiSelectMode = false
                                selectedWords.removeAll()
                            }
                        } else {
                            Button {
                                isMultiSelectMode = true
                            } label: {
                                Label("Chọn nhiều", systemImage: "checkmark.circle")
                            }
                            
                            Button {
                                showingExportSheet = true
                            } label: {
                                Label("Xuất CSV", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(
                    sortOption: $sortOption,
                    showOnlyFavorites: $showOnlyFavorites,
                    showOnlyDifficult: $showOnlyDifficult
                )
            }
            .sheet(isPresented: $showingCreateFolder) {
                CreateFolderView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(words: Array(selectedWords.isEmpty ? Set(filteredWords) : selectedWords))
            }
        }
    }
}

// MARK: - Section Tab Bar
struct SectionTabBar: View {
    @Binding var selectedSection: LibraryView.LibrarySection
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(LibraryView.LibrarySection.allCases, id: \.self) { section in
                    SectionTab(
                        section: section,
                        isSelected: selectedSection == section
                    ) {
                        withAnimation(.spring()) {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct SectionTab: View {
    let section: LibraryView.LibrarySection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(section.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(height: 3)
                        .transition(.scale)
                } else {
                    Color.clear
                        .frame(height: 3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search and Filter Bar
struct SearchAndFilterBar: View {
    @Binding var searchText: String
    @Binding var viewMode: LibraryView.ViewMode
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Tìm kiếm từ vựng...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            // View mode toggle
            Button {
                withAnimation {
                    viewMode = viewMode == .grid ? .list : .grid
                }
            } label: {
                Image(systemName: viewMode.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            }
            
            // Filter button
            Button {
                showingFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - My Words Content
struct MyWordsContent: View {
    let words: [SavedWord]
    let viewMode: LibraryView.ViewMode
    @Binding var selectedWords: Set<SavedWord>
    @Binding var isMultiSelectMode: Bool
    
    var body: some View {
        if words.isEmpty {
            EmptyStateView(
                icon: "books.vertical",
                title: "Chưa có từ vựng",
                message: "Bắt đầu lưu các từ bạn học để xây dựng thư viện cá nhân"
            )
        } else {
            ScrollView {
                if viewMode == .grid {
                    WordGridView(
                        words: words,
                        selectedWords: $selectedWords,
                        isMultiSelectMode: $isMultiSelectMode
                    )
                } else {
                    WordListView(
                        words: words,
                        selectedWords: $selectedWords,
                        isMultiSelectMode: $isMultiSelectMode
                    )
                }
            }
        }
    }
}

// MARK: - HSK Levels Content
struct HSKLevelsContent: View {
    let words: [SavedWord]
    @Binding var selectedLevels: Set<Int>
    let viewMode: LibraryView.ViewMode
    
    var body: some View {
        VStack(spacing: 0) {
            // HSK Level Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...6, id: \.self) { level in
                        HSKLevelChip(
                            level: level,
                            isSelected: selectedLevels.contains(level),
                            wordCount: getWordCount(for: level)
                        ) {
                            if selectedLevels.contains(level) {
                                selectedLevels.remove(level)
                            } else {
                                selectedLevels.insert(level)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // Words display
            if words.isEmpty {
                EmptyStateView(
                    icon: "graduationcap",
                    title: "Chọn cấp độ HSK",
                    message: "Chọn một hoặc nhiều cấp độ để xem từ vựng"
                )
            } else {
                ScrollView {
                    if viewMode == .grid {
                        WordGridView(
                            words: words,
                            selectedWords: .constant(Set()),
                            isMultiSelectMode: .constant(false)
                        )
                    } else {
                        WordListView(
                            words: words,
                            selectedWords: .constant(Set()),
                            isMultiSelectMode: .constant(false)
                        )
                    }
                }
            }
        }
    }
    
    private func getWordCount(for level: Int) -> Int {
        WordDataManager.shared.savedWords.filter { $0.hskLevel == level }.count
    }
}

struct HSKLevelChip: View {
    let level: Int
    let isSelected: Bool
    let wordCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("HSK \(level)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(wordCount) từ")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Folders Content
struct FoldersContent: View {
    @Binding var selectedFolder: PersonalFolder?
    let words: [SavedWord]
    let viewMode: LibraryView.ViewMode
    @Binding var showingCreateFolder: Bool
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonalFolder.createdDate, ascending: false)],
        animation: .default)
    private var folders: FetchedResults<PersonalFolder>
    
    var body: some View {
        if selectedFolder == nil {
            // Show folders list
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    // Create new folder card
                    Button {
                        showingCreateFolder = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            
                            Text("Tạo thư mục")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundColor(.blue)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Existing folders
                    ForEach(folders, id: \.self) { folder in
                        FolderCard(folder: folder) {
                            selectedFolder = folder
                        }
                    }
                }
                .padding()
            }
        } else {
            // Show folder contents
            VStack(spacing: 0) {
                // Folder header
                HStack {
                    Button {
                        selectedFolder = nil
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Thư mục")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(selectedFolder?.name ?? "")
                        .font(.headline)
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            // Edit folder
                        } label: {
                            Label("Sửa", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            // Delete folder
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                // Folder words
                if words.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "Thư mục trống",
                        message: "Thêm từ vựng vào thư mục này để tổ chức học tập"
                    )
                } else {
                    ScrollView {
                        if viewMode == .grid {
                            WordGridView(
                                words: words,
                                selectedWords: .constant(Set()),
                                isMultiSelectMode: .constant(false)
                            )
                        } else {
                            WordListView(
                                words: words,
                                selectedWords: .constant(Set()),
                                isMultiSelectMode: .constant(false)
                            )
                        }
                    }
                }
            }
        }
    }
}

struct FolderCard: View {
    let folder: PersonalFolder
    let action: () -> Void
    
    var wordCount: Int {
        (folder.words as? Set<SavedWord>)?.count ?? 0
    }

    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title)
                        .foregroundColor(Color(folder.colorHex ?? "007AFF"))
                    
                    Spacer()
                    
                    if wordCount > 0 {
                        Text("\(wordCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.name ?? "Untitled")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let description = folder.folderDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding()
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Topics Content
struct TopicsContent: View {
    let words: [SavedWord]
    let viewMode: LibraryView.ViewMode
    
    let topics = [
        Topic(name: "Gia đình", icon: "person.3.fill", color: .blue, tags: ["family", "relatives"]),
        Topic(name: "Công việc", icon: "briefcase.fill", color: .purple, tags: ["work", "career"]),
        Topic(name: "Du lịch", icon: "airplane", color: .orange, tags: ["travel", "vacation"]),
        Topic(name: "Ẩm thực", icon: "fork.knife", color: .red, tags: ["food", "cooking"]),
        Topic(name: "Giáo dục", icon: "graduationcap.fill", color: .green, tags: ["education", "school"]),
        Topic(name: "Sức khỏe", icon: "heart.fill", color: .pink, tags: ["health", "medical"]),
        Topic(name: "Công nghệ", icon: "laptopcomputer", color: .indigo, tags: ["technology", "computer"]),
        Topic(name: "Thể thao", icon: "sportscourt.fill", color: .mint, tags: ["sports", "exercise"])
    ]
    
    struct Topic {
        let name: String
        let icon: String
        let color: Color
        let tags: [String]
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(topics, id: \.name) { topic in
                    TopicCard(topic: topic, wordCount: getWordCount(for: topic))
                }
            }
            .padding()
        }
    }
    
    private func getWordCount(for topic: Topic) -> Int {
        // Filter words by topic tags
        return words.filter { word in
            // Check if word has any of the topic tags
            // This would require adding a tags field to SavedWord
            return false // Placeholder
        }.count
    }
}

struct TopicCard: View {
    let topic: TopicsContent.Topic
    let wordCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: topic.icon)
                .font(.largeTitle)
                .foregroundColor(topic.color)
            
            Text(topic.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("\(wordCount) từ")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(topic.color.opacity(0.1))
        )
    }
}

// MARK: - Word Grid View
struct WordGridView: View {
    let words: [SavedWord]
    @Binding var selectedWords: Set<SavedWord>
    @Binding var isMultiSelectMode: Bool
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(words, id: \.self) { word in
                WordGridCard(
                    word: word,
                    isSelected: selectedWords.contains(word),
                    isMultiSelectMode: isMultiSelectMode
                ) {
                    if isMultiSelectMode {
                        if selectedWords.contains(word) {
                            selectedWords.remove(word)
                        } else {
                            selectedWords.insert(word)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct WordGridCard: View {
    let word: SavedWord
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onSelect: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            if isMultiSelectMode {
                onSelect()
            } else {
                showingDetail = true
            }
        }) {
            VStack(spacing: 12) {
                // Selection indicator
                if isMultiSelectMode {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .gray)
                            .font(.title3)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
                
                // Character
                Text(word.hanzi ?? "")
                    .font(.system(size: 48))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
                
                // Pinyin
                Text(word.pinyin ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Meaning
                Text(word.meaning ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                // Bottom indicators
                HStack {
                    if word.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("HSK\(word.hskLevel)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        isSelected ?
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue, lineWidth: 2)
                        : nil
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            WordDetailSheet(word: word)
        }
    }
}

// MARK: - Word List View
struct WordListView: View {
    let words: [SavedWord]
    @Binding var selectedWords: Set<SavedWord>
    @Binding var isMultiSelectMode: Bool
    
    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(words, id: \.self) { word in
                WordListRow(
                    word: word,
                    isSelected: selectedWords.contains(word),
                    isMultiSelectMode: isMultiSelectMode
                ) {
                    if isMultiSelectMode {
                        if selectedWords.contains(word) {
                            selectedWords.remove(word)
                        } else {
                            selectedWords.insert(word)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

//
//  LibraryView.swift
//  ChineseWordLockScreen
//
//  Enhanced library with comprehensive filtering and organization
//

import SwiftUI
import CoreData

// ... keep everything you already wrote above ...

// CONTINUED from WordListRow (closing out properly)
struct WordListRow: View {
    let word: SavedWord
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onSelect: () -> Void
    @State private var showingDetail = false
    @StateObject private var wordDataManager = WordDataManager.shared
    
    var body: some View {
        Button(action: {
            if isMultiSelectMode {
                onSelect()
            } else {
                showingDetail = true
            }
        }) {
            HStack(spacing: 15) {
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title3)
                }
                
                Text(word.hanzi ?? "")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.pinyin ?? "")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(word.meaning ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
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
                        
                        Text("HSK\(word.hskLevel)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            WordDetailSheet(word: word)
        }
    }
}

// MARK: - Word Detail Sheet
struct WordDetailSheet: View {
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
            .navigationTitle("Chi tiết từ")
            .navigationBarItems(trailing: Button("Đóng") { dismiss() })
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Binding var sortOption: LibraryView.SortOption
    @Binding var showOnlyFavorites: Bool
    @Binding var showOnlyDifficult: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sắp xếp")) {
                    Picker("Tiêu chí", selection: $sortOption) {
                        ForEach(LibraryView.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Bộ lọc")) {
                    Toggle("Chỉ từ yêu thích", isOn: $showOnlyFavorites)
                    Toggle("Chỉ từ khó", isOn: $showOnlyDifficult)
                }
            }
            .navigationTitle("Bộ lọc")
            .navigationBarItems(trailing: Button("Xong") { dismiss() })
        }
    }
}

// MARK: - Create Folder View
struct CreateFolderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var folderName = ""
    @State private var folderDescription = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tên thư mục") {
                    TextField("Nhập tên", text: $folderName)
                }
                
                Section("Mô tả") {
                    TextField("Nhập mô tả (tùy chọn)", text: $folderDescription)
                }
            }
            .navigationTitle("Tạo thư mục")
            .navigationBarItems(
                leading: Button("Hủy") { dismiss() },
                trailing: Button("Tạo") {
                    // TODO: Save folder to CoreData
                    dismiss()
                }
                .disabled(folderName.isEmpty)
            )
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    let words: [SavedWord]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Xuất \(words.count) từ vựng")
                    .font(.title2)
                
                Button("Xuất CSV") {
                    // TODO: Implement CSV export
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Xuất dữ liệu")
            .navigationBarItems(trailing: Button("Đóng") { dismiss() })
        }
    }
}


