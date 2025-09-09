//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var dragAmount = CGSize.zero
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.teal.opacity(0.1), Color.yellow.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Chinese Character
                    Text(viewModel.currentWord.hanzi)
                        .font(.system(size: 100, weight: .medium))
                        .foregroundColor(.primary)
                        .offset(dragAmount)
                        .gesture(
                            DragGesture()
                                .onChanged { dragAmount = $0.translation }
                                .onEnded { _ in
                                    if abs(dragAmount.width) > 100 {
                                        viewModel.getNextWord()
                                    }
                                    withAnimation(.spring()) {
                                        dragAmount = .zero
                                    }
                                }
                        )
                    
                    // Pinyin
                    Text(viewModel.currentWord.pinyin)
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    
                    // Meaning
                    if viewModel.showingDefinition {
                        Text(viewModel.currentWord.meaning)
                            .font(.title2)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    // Example Sentence
                    if let example = viewModel.currentWord.example {
                        Text(example)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }
                    
                    // HSK Level Badge
                    HStack {
                        Image(systemName: "graduationcap.fill")
                        Text("HSK \(viewModel.currentWord.hskLevel)")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(15)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 40) {
                        // Toggle Definition
                        Button(action: { viewModel.toggleDefinition() }) {
                            Image(systemName: viewModel.showingDefinition ? "eye.fill" : "eye.slash.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Speak
                        Button(action: { viewModel.speakWord() }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        // Save/Unsave
                        Button(action: { viewModel.toggleSave() }) {
                            Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                                .foregroundColor(viewModel.isSaved ? .yellow : .gray)
                        }
                        
                        // Next Word
                        Button(action: { viewModel.getNextWord() }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("今日词汇")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
