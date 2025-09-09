//
//  LibraryView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedWord.savedDate, ascending: false)],
        animation: .default)
    private var savedWords: FetchedResults<SavedWord>
    
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    
    var filteredWords: [SavedWord] {
        savedWords.filter { word in
            let matchesSearch = searchText.isEmpty ||
                (word.hanzi?.contains(searchText) ?? false) ||
                (word.pinyin?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (word.meaning?.lowercased().contains(searchText.lowercased()) ?? false)
            
            let matchesFavorite = !showFavoritesOnly || word.isFavorite
            
            return matchesSearch && matchesFavorite
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredWords) { word in
                    WordRowView(word: word)
                }
                .onDelete(perform: deleteWords)
            }
            .searchable(text: $searchText, prompt: "搜索汉字、拼音或意思")
            .navigationTitle("我的词库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFavoritesOnly.toggle() }) {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(showFavoritesOnly ? .yellow : .gray)
                    }
                }
            }
            .overlay {
                if savedWords.isEmpty {
                    ContentUnavailableView(
                        "没有保存的词汇",
                        systemImage: "bookmark",
                        description: Text("点击主页的书签图标保存词汇")
                    )
                }
            }
        }
    }
    
    private func deleteWords(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredWords[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting words: \(error)")
            }
        }
    }
}

struct WordRowView: View {
    let word: SavedWord
    @StateObject private var wordDataManager = WordDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word.hanzi ?? "")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    wordDataManager.toggleFavorite(for: word)
                }) {
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
                .foregroundColor(.primary)
            
            if let example = word.example {
                Text(example)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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
            }
        }
        .padding(.vertical, 4)
    }
}
