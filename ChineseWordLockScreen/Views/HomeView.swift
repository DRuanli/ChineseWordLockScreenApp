//
//  HomeView.swift
//  ChineseWordLockScreen
//
//  Redesigned minimalist vocabulary card with swipe navigation
//  Updated with fixed swipe logic and word source selection
//

import SwiftUI
import AVFoundation
import Photos
import CoreData

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var wordDataManager = WordDataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var dragOffset: CGSize = .zero
    @State private var showingShareView = false
    @State private var showingInfo = false
    @State private var capturedImage: UIImage?
    @State private var audioPlaying = false
    @State private var currentWordIndex = 0
    
    // Swipe threshold
    private let swipeThreshold: CGFloat = 100
    
    // Dynamic total words from viewModel
    var totalWords: Int {
        viewModel.wordHistory.count
    }
    
    var body: some View {
        ZStack {
            // Clean beige background
            Color(red: 0.95, green: 0.93, blue: 0.88)
                .ignoresSafeArea()
            
            if showingShareView {
                ShareView(
                    word: viewModel.currentWord,
                    capturedImage: $capturedImage,
                    isPresented: $showingShareView
                )
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Word source selector at the top
                    HStack {
                        WordSourceSelector(
                            sourceMode: $viewModel.wordSourceMode,
                            selectedFolderId: $viewModel.selectedFolderId
                        )
                        .onChange(of: viewModel.wordSourceMode) { _ in
                            // Reload words when source changes
                            viewModel.loadSessionWords(count: 10)
                            currentWordIndex = 0
                        }
                        .onChange(of: viewModel.selectedFolderId) { _ in
                            // Reload words when folder changes
                            if viewModel.wordSourceMode == .folder {
                                viewModel.loadSessionWords(count: 10)
                                currentWordIndex = 0
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Top bar with progress indicator
                    TopProgressBar(
                        currentIndex: currentWordIndex,
                        total: max(totalWords, 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Main vocabulary card
                    VocabularyCard(
                        word: viewModel.currentWord,
                        audioPlaying: $audioPlaying,
                        onPlayAudio: playAudio
                    )
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                    .opacity(1 - Double(abs(dragOffset.width) / 200))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.interactiveSpring()) {
                                    dragOffset = value.translation
                                }
                            }
                            .onEnded { value in
                                handleSwipe(value.translation)
                            }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                    
                    // Bottom action buttons
                    ActionButtonBar(
                        onInfo: {
                            showingInfo = true
                        },
                        onShare: shareWord,
                        onLike: toggleLike,
                        isLiked: viewModel.isSaved
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            wordDataManager.refreshData()
            setupScreenshotDetection()
            
            // Initialize with words based on selected mode
            viewModel.loadSessionWords(count: 10)
        }
        .sheet(isPresented: $showingInfo) {
            WordInfoSheet(word: viewModel.currentWord)
        }
    }
    
    // MARK: - Helper Methods
    private func handleSwipe(_ translation: CGSize) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Check if swipe exceeds threshold
            if abs(translation.width) > swipeThreshold || abs(translation.height) > swipeThreshold {
                // Determine swipe direction
                if abs(translation.width) > abs(translation.height) {
                    // Horizontal swipe
                    if translation.width > 0 {
                        // Swipe right - Add to favorites (if not already saved)
                        if !viewModel.isSaved {
                            viewModel.toggleSave()
                            // Use HapticFeedback that's already defined in the project
                            HapticFeedback.success.trigger()
                        }
                        // Then move to next word
                        currentWordIndex += 1
                        viewModel.getNextWord()
                    } else {
                        // Swipe left - Remove from favorites (if saved)
                        if viewModel.isSaved {
                            viewModel.toggleSave()
                            HapticFeedback.light.trigger()
                        }
                        // Then move to next word
                        currentWordIndex += 1
                        viewModel.getNextWord()
                    }
                } else {
                    // Vertical swipe
                    if translation.height > 0 {
                        // Swipe down - Go to previous word
                        if currentWordIndex > 0 {
                            currentWordIndex -= 1
                            viewModel.getPreviousWord()
                        }
                    } else {
                        // Swipe up - Go to next word
                        currentWordIndex += 1
                        viewModel.getNextWord()
                    }
                }
            }
            // Reset offset
            dragOffset = .zero
        }
    }
    
    private func playAudio() {
        withAnimation(.easeInOut(duration: 0.2)) {
            audioPlaying = true
        }
        viewModel.speakWord()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            audioPlaying = false
        }
    }
    
    private func shareWord() {
        // Capture the card as image first
        captureCard()
        showingShareView = true
    }
    
    private func toggleLike() {
        viewModel.toggleSave()
        HapticFeedback.light.trigger()
    }
    
    private func captureCard() {
        // Create a view to capture
        let cardView = ShareableCard(word: viewModel.currentWord)
        let controller = UIHostingController(rootView: cardView)
        
        // Set the size for the card
        let targetSize = CGSize(width: 350, height: 500)
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)
        controller.view.backgroundColor = .clear
        
        // Create the image
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        capturedImage = renderer.image { _ in
            controller.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        }
    }
    
    private func setupScreenshotDetection() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Increment screenshot count or handle as needed
            print("Screenshot taken")
        }
    }
    
    private func saveImage() {
        guard let image = capturedImage else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                HapticFeedback.success.trigger()
            }
        }
    }
    
    private func copyText() {
        let textToCopy = """
        \(viewModel.currentWord.hanzi)
        \(viewModel.currentWord.pinyin)
        \(viewModel.currentWord.meaning)
        """
        UIPasteboard.general.string = textToCopy
        HapticFeedback.success.trigger()
    }
    
    private func shareToApp() {
        guard let image = capturedImage else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [image, viewModel.shareWord()],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Word Source Selector
struct WordSourceSelector: View {
    @Binding var sourceMode: WordSourceMode
    @Binding var selectedFolderId: NSManagedObjectID?
    @State private var showingFolderPicker = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonalFolder.name, ascending: true)],
        animation: .default)
    private var folders: FetchedResults<PersonalFolder>
    
    var body: some View {
        VStack(spacing: 12) {
            // Mode selector
            Menu {
                ForEach(WordSourceMode.allCases, id: \.self) { mode in
                    Button {
                        sourceMode = mode
                        if mode == .folder && folders.first != nil {
                            selectedFolderId = folders.first?.objectID
                        }
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                            if sourceMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: iconForMode(sourceMode))
                        .font(.system(size: 16))
                    Text(sourceMode.rawValue)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
            
            // Show folder selector if folder mode is selected
            if sourceMode == .folder && !folders.isEmpty {
                Menu {
                    ForEach(folders, id: \.objectID) { folder in
                        Button {
                            selectedFolderId = folder.objectID
                        } label: {
                            HStack {
                                Text(folder.name ?? "Unnamed")
                                if selectedFolderId == folder.objectID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14))
                        Text(selectedFolderName)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private func iconForMode(_ mode: WordSourceMode) -> String {
        switch mode {
        case .random:
            return "shuffle"
        case .favorites:
            return "heart.fill"
        case .folder:
            return "folder.fill"
        case .mixed:
            return "square.stack.3d.up.fill"
        }
    }
    
    private var selectedFolderName: String {
        guard let folderId = selectedFolderId,
              let folder = folders.first(where: { $0.objectID == folderId }) else {
            return "Select Folder"
        }
        return folder.name ?? "Unnamed"
    }
}

// MARK: - Top Progress Bar
struct TopProgressBar: View {
    let currentIndex: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(total, 10), id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentIndex ? Color.black : Color.black.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Vocabulary Card
struct VocabularyCard: View {
    let word: HSKWord
    @Binding var audioPlaying: Bool
    let onPlayAudio: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Chinese character
            Text(word.hanzi)
                .font(.system(size: 80, weight: .regular))
                .foregroundColor(.black)
            
            // Pinyin with audio button
            HStack(spacing: 15) {
                Text(word.pinyin)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.black.opacity(0.8))
                
                Button(action: onPlayAudio) {
                    Image(systemName: audioPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.black.opacity(0.7))
                        .scaleEffect(audioPlaying ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: audioPlaying)
                }
            }
            
            // Part of speech and definition
            VStack(spacing: 12) {
                Text("(n.) \(word.meaning)")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.black.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 30)
            
            // Example sentence
            if let example = word.example {
                Text(example)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Action Button Bar
struct ActionButtonBar: View {
    let onInfo: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let isLiked: Bool
    
    var body: some View {
        HStack(spacing: 40) {
            // Info button
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.title)
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            
            // Share button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            
            // Like button
            Button(action: onLike) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.title)
                    .foregroundColor(isLiked ? .red : .black.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
        }
    }
}

// MARK: - Share View
struct ShareView: View {
    let word: HSKWord
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var showingActivityView = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 30) {
                // Close button
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Card preview
                ShareableCard(word: word)
                    .frame(maxWidth: 350)
                    .padding(.horizontal, 20)
                
                // Action buttons
                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        ShareActionButton(icon: "arrow.down.circle", label: "Save image") {
                            saveImage()
                        }
                        
                        ShareActionButton(icon: "doc.on.doc", label: "Copy text") {
                            copyText()
                        }
                        
                        ShareActionButton(icon: "paperplane", label: "Share") {
                            shareToApp()
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
    
    private func saveImage() {
        guard let image = capturedImage else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                HapticFeedback.success.trigger()
            }
        }
    }
    
    private func copyText() {
        let textToCopy = """
        \(word.hanzi)
        \(word.pinyin)
        \(word.meaning)
        """
        UIPasteboard.general.string = textToCopy
        HapticFeedback.success.trigger()
    }
    
    private func shareToApp() {
        guard let image = capturedImage else { return }
        
        let shareText = """
        Chinese Word of the Day
        
        \(word.hanzi)
        \(word.pinyin)
        
        Meaning: \(word.meaning)
        
        \(word.example ?? "")
        
        Learn Chinese with Chinese Word Lock Screen app!
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [image, shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Share Action Button
struct ShareActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 80)
        }
    }
}

// MARK: - Shareable Card
struct ShareableCard: View {
    let word: HSKWord
    
    var body: some View {
        VStack(spacing: 20) {
            Text(word.hanzi)
                .font(.system(size: 60, weight: .regular))
            
            Text(word.pinyin)
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text(word.meaning)
                .font(.system(size: 20))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let example = word.example {
                Text(example)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Word Info Sheet
struct WordInfoSheet: View {
    let word: HSKWord
    @Environment(\.dismiss) var dismiss
    @State private var currentTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Tabs
                Picker("Info", selection: $currentTab) {
                    Text("Details").tag(0)
                    Text("Tones").tag(1)
                    Text("Usage").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                ScrollView {
                    switch currentTab {
                    case 0:
                        DetailsTab(word: word)
                    case 1:
                        TonesTab(word: word)
                    case 2:
                        UsageTab(word: word)
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Word Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Details Tab
struct DetailsTab: View {
    let word: HSKWord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoRow(label: "Character", value: word.hanzi)
            InfoRow(label: "Pinyin", value: word.pinyin)
            InfoRow(label: "Meaning", value: word.meaning)
            InfoRow(label: "HSK Level", value: "HSK \(word.hskLevel)")
            
            if let example = word.example {
                InfoRow(label: "Example", value: example)
            }
        }
        .padding()
    }
}

// MARK: - Tones Tab
struct TonesTab: View {
    let word: HSKWord
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tone Analysis")
                .font(.headline)
            
            Text(analyzeTonePattern(word.pinyin))
                .font(.system(size: 18))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 12) {
                ToneInfo(tone: 1, description: "High level tone (ā)")
                ToneInfo(tone: 2, description: "Rising tone (á)")
                ToneInfo(tone: 3, description: "Dipping tone (ǎ)")
                ToneInfo(tone: 4, description: "Falling tone (à)")
                ToneInfo(tone: 0, description: "Neutral tone")
            }
            .padding()
        }
        .padding()
    }
    
    private func analyzeTonePattern(_ pinyin: String) -> String {
        let syllables = pinyin.split(separator: " ")
        var pattern = ""
        
        for (index, syllable) in syllables.enumerated() {
            if index > 0 {
                pattern += " + "
            }
            let tone = detectTone(String(syllable))
            pattern += "Tone \(tone == 0 ? "neutral" : String(tone))"
        }
        
        return pattern.trimmingCharacters(in: .whitespaces)
    }
    
    private func detectTone(_ syllable: String) -> Int {
        let tone1 = ["ā", "ē", "ī", "ō", "ū", "ǖ"]
        let tone2 = ["á", "é", "í", "ó", "ú", "ǘ"]
        let tone3 = ["ǎ", "ě", "ǐ", "ǒ", "ǔ", "ǚ"]
        let tone4 = ["à", "è", "ì", "ò", "ù", "ǜ"]
        
        for char in syllable {
            let charStr = String(char)
            if tone1.contains(where: { charStr.contains($0) }) { return 1 }
            if tone2.contains(where: { charStr.contains($0) }) { return 2 }
            if tone3.contains(where: { charStr.contains($0) }) { return 3 }
            if tone4.contains(where: { charStr.contains($0) }) { return 4 }
        }
        return 0
    }
}

// MARK: - Usage Tab
struct UsageTab: View {
    let word: HSKWord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Common Usage")
                .font(.headline)
            
            if let example = word.example {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example Sentence:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(example)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            
            Text("Study Tips")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 12) {
                StudyTip(icon: "lightbulb.fill", text: "Practice writing the character stroke by stroke")
                StudyTip(icon: "speaker.wave.2.fill", text: "Listen to the pronunciation multiple times")
                StudyTip(icon: "book.fill", text: "Create your own example sentences")
            }
        }
        .padding()
    }
}

// MARK: - Helper Views
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
        }
    }
}

struct ToneInfo: View {
    let tone: Int
    let description: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(toneColor)
                .frame(width: 12, height: 12)
            
            Text(description)
                .font(.subheadline)
        }
    }
    
    private var toneColor: Color {
        switch tone {
        case 1: return .red
        case 2: return .orange
        case 3: return .green
        case 4: return .blue
        default: return .gray
        }
    }
}

struct StudyTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
