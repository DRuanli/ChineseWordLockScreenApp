//
//  ProfileSettingsView.swift
//  ChineseWordLockScreen
//
//  Redesigned profile and settings view with modern card-based layout
//

import SwiftUI

struct ProfileSettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var wordDataManager = WordDataManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showingLogoutAlert = false
    @State private var showingPaywall = false
    @State private var showingFavorites = false
    @State private var showingOwnWords = false
    @State private var showingCollections = false
    @State private var showingHistory = false
    @State private var showingWidgets = false
    @State private var showingReminders = false
    @State private var showingThemes = false
    @State private var showingVoices = false
    @State private var showingAppIcon = false
    @State private var showingWatch = false
    @State private var showingAppBundle = false
    @State private var selectedHSKLevel = 5
    @State private var dailyGoal = 10
    
    var body: some View {
        ZStack {
            // Background color matching the design
            Color(red: 0.96, green: 0.91, blue: 0.87)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with navigation buttons
                    HStack {
                        Button("Done") {
                            dismiss()
                        }
                        .font(.system(size: 17))
                        .foregroundColor(.black)
                        
                        Spacer()
                        
                        Text("Profile")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        NavigationLink(destination: DetailedSettingsView(
                            selectedHSKLevel: $selectedHSKLevel,
                            dailyGoal: $dailyGoal
                        )) {
                            Text("Settings")
                                .font(.system(size: 17))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Go Premium Banner
                    PremiumBanner(showingPaywall: $showingPaywall)
                        .padding(.horizontal, 20)
                    
                    // Your Vocabulary Section
                    VocabularySection(
                        showingFavorites: $showingFavorites,
                        showingOwnWords: $showingOwnWords,
                        showingCollections: $showingCollections,
                        showingHistory: $showingHistory
                    )
                    .padding(.horizontal, 20)
                    
                    // Customize the app Section
                    CustomizeSection(
                        showingWidgets: $showingWidgets,
                        showingReminders: $showingReminders,
                        showingThemes: $showingThemes,
                        showingVoices: $showingVoices,
                        showingAppIcon: $showingAppIcon,
                        showingWatch: $showingWatch
                    )
                    .padding(.horizontal, 20)
                    
                    // Get the app bundle
                    AppBundleCard(showingAppBundle: $showingAppBundle)
                        .padding(.horizontal, 20)
                    
                    // Logout Button
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                            Text("Logout")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 10)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUserSettings()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesView()
        }
        .sheet(isPresented: $showingOwnWords) {
            PaywallView() // Or custom words view if available
        }
        .sheet(isPresented: $showingCollections) {
            CollectionsView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingWidgets) {
            WidgetInstructionsView()
        }
        .sheet(isPresented: $showingReminders) {
            ReminderSettingsView()
        }
        .sheet(isPresented: $showingThemes) {
            PaywallView() // Or themes view
        }
        .sheet(isPresented: $showingVoices) {
            PaywallView() // Or voices view
        }
        .sheet(isPresented: $showingAppIcon) {
            PaywallView() // Or app icon picker
        }
        .sheet(isPresented: $showingWatch) {
            PaywallView() // Or watch settings
        }
        .sheet(isPresented: $showingAppBundle) {
            PaywallView() // Or app bundle info
        }
        .alert("Đăng xuất", isPresented: $showingLogoutAlert) {
            Button("Hủy", role: .cancel) { }
            Button("Đăng xuất", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Bạn có chắc muốn đăng xuất?")
        }
    }
    
    private func loadUserSettings() {
        if let user = authManager.currentUser {
            selectedHSKLevel = Int(user.preferredHSKLevel)
            dailyGoal = Int(user.dailyGoal)
        }
    }
}

// MARK: - Premium Banner
struct PremiumBanner: View {
    @Binding var showingPaywall: Bool
    
    var body: some View {
        Button(action: {
            showingPaywall = true
            HapticFeedback.light.trigger()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Go Premium")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Access all categories, words, themes, and remove ads!")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Target icon illustration
                ZStack {
                    Circle()
                        .fill(Color(red: 0.98, green: 0.65, blue: 0.55).opacity(0.3))
                        .frame(width: 60, height: 60)
                        .offset(x: 5, y: 5)
                    
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(.black)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.7, green: 0.82, blue: 0.8))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vocabulary Section
struct VocabularySection: View {
    @StateObject private var wordDataManager = WordDataManager.shared
    @Binding var showingFavorites: Bool
    @Binding var showingOwnWords: Bool
    @Binding var showingCollections: Bool
    @Binding var showingHistory: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Vocabulary")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            // Streak Card
            StreakCard()
            
            // Vocabulary Options Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProfileVocabularyCard(
                    icon: "heart.fill",
                    title: "Favorites",
                    color: Color(red: 0.7, green: 0.82, blue: 0.8),
                    action: {
                        showingFavorites = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                ProfileVocabularyCard(
                    icon: "pencil",
                    title: "Your own words",
                    color: .white,
                    hasLock: true,
                    action: {
                        showingOwnWords = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                ProfileVocabularyCard(
                    icon: "bookmark.fill",
                    title: "Collections",
                    color: .white,
                    action: {
                        showingCollections = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                ProfileVocabularyCard(
                    icon: "book.fill",
                    title: "History",
                    color: Color(red: 0.7, green: 0.82, blue: 0.8),
                    action: {
                        showingHistory = true
                        HapticFeedback.light.trigger()
                    }
                )
            }
        }
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    @StateObject private var wordDataManager = WordDataManager.shared
    @State private var weekDays = ["Th", "Fr", "Sa", "Su", "Mo", "Tu", "We"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your streak")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    // Share functionality
                    HapticFeedback.light.trigger()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    // More options
                    HapticFeedback.light.trigger()
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                // Flame icon with number
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("\(wordDataManager.streak)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                
                // Week days
                HStack(spacing: 8) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 4) {
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Circle()
                                .fill(index == 0 ? Color(red: 0.7, green: 0.82, blue: 0.8) : Color.gray.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(index == 0 ? .black : .clear)
                                )
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Profile Vocabulary Card (Renamed to avoid conflict)
struct ProfileVocabularyCard: View {
    let icon: String
    let title: String
    let color: Color
    var hasLock: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color == .white ? .black : .black)
                    
                    Spacer()
                    
                    if hasLock {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background(color)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Customize Section
struct CustomizeSection: View {
    @Binding var showingWidgets: Bool
    @Binding var showingReminders: Bool
    @Binding var showingThemes: Bool
    @Binding var showingVoices: Bool
    @Binding var showingAppIcon: Bool
    @Binding var showingWatch: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customize the app")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                CustomizeCard(
                    icon: "rectangle.on.rectangle.angled",
                    title: "Widgets",
                    illustration: .widget,
                    action: {
                        showingWidgets = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                CustomizeCard(
                    icon: "bell.badge",
                    title: "Reminders",
                    illustration: .reminder,
                    action: {
                        showingReminders = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                CustomizeCard(
                    icon: "paintbrush",
                    title: "Themes",
                    illustration: .themes,
                    action: {
                        showingThemes = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                CustomizeCard(
                    icon: "speaker.wave.2",
                    title: "Voices",
                    illustration: .voices,
                    action: {
                        showingVoices = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                CustomizeCard(
                    icon: "app.badge",
                    title: "App icon",
                    illustration: .appIcon,
                    action: {
                        showingAppIcon = true
                        HapticFeedback.light.trigger()
                    }
                )
                
                CustomizeCard(
                    icon: "applewatch",
                    title: "Watch",
                    illustration: .watch,
                    action: {
                        showingWatch = true
                        HapticFeedback.light.trigger()
                    }
                )
            }
        }
    }
}

// MARK: - Customize Card
struct CustomizeCard: View {
    let icon: String
    let title: String
    let illustration: IllustrationType
    let action: () -> Void
    
    enum IllustrationType {
        case widget, reminder, themes, voices, appIcon, watch
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Illustration
                ZStack {
                    // Shadow dots
                    Circle()
                        .fill(Color(red: 0.98, green: 0.65, blue: 0.55).opacity(0.3))
                        .frame(width: 50, height: 50)
                        .offset(x: 10, y: 10)
                    
                    // Main icon
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.7, green: 0.82, blue: 0.8))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                        )
                }
                .frame(height: 80)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Bundle Card
struct AppBundleCard: View {
    @Binding var showingAppBundle: Bool
    
    var body: some View {
        Button(action: {
            showingAppBundle = true
            HapticFeedback.light.trigger()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Get the app bundle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("The complete mental well-being and growth toolkit")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // App icons illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.7, green: 0.82, blue: 0.8))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("I am")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                        )
                        .offset(x: -10, y: -10)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.98, green: 0.65, blue: 0.55).opacity(0.8))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        )
                        .offset(x: 10, y: 10)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detailed Settings View
struct DetailedSettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var wordDataManager = WordDataManager.shared
    @Environment(\.dismiss) var dismiss
    @Binding var selectedHSKLevel: Int
    @Binding var dailyGoal: Int
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.91, blue: 0.87)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Learning Settings
                    SettingsCard(
                        title: "Cài đặt học tập",
                        icon: "book.circle.fill",
                        color: .blue
                    ) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("HSK Level")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $selectedHSKLevel) {
                                    ForEach(3...6, id: \.self) { level in
                                        Text("HSK \(level)").tag(level)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 200)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Mục tiêu hàng ngày")
                                    .font(.subheadline)
                                Spacer()
                                Stepper("\(dailyGoal) từ", value: $dailyGoal, in: 5...50, step: 5)
                                    .frame(width: 120)
                            }
                        }
                    }
                    
                    // Notification Settings
                    SettingsCard(
                        title: "Thông báo",
                        icon: "bell.circle.fill",
                        color: .orange
                    ) {
                        VStack(spacing: 15) {
                            Toggle("Bật thông báo", isOn: $notificationManager.isNotificationEnabled)
                                .font(.subheadline)
                            
                            if notificationManager.isNotificationEnabled {
                                Divider()
                                Stepper("Tần suất: \(notificationManager.notificationFrequency) lần/ngày",
                                        value: $notificationManager.notificationFrequency,
                                        in: 1...5)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .onChange(of: selectedHSKLevel) { newValue in
            authManager.updateUserProfile(hskLevel: newValue)
            wordDataManager.selectedHSKLevel = newValue
        }
        .onChange(of: dailyGoal) { newValue in
            authManager.updateUserProfile(dailyGoal: newValue)
        }
        .onChange(of: notificationManager.isNotificationEnabled) { newValue in
            authManager.updateUserProfile(notificationEnabled: newValue)
            if newValue {
                notificationManager.requestAuthorization()
            }
        }
        .onChange(of: notificationManager.notificationFrequency) { newValue in
            authManager.updateUserProfile(notificationFrequency: newValue)
            notificationManager.updateNotificationFrequency(newValue)
        }
    }
}

// MARK: - Settings Card Component
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views (Placeholders)
struct FavoritesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Favorites")
                    .font(.largeTitle)
                // Add your favorites content here
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CollectionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Collections")
                    .font(.largeTitle)
                // Add your collections content here
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("History")
                    .font(.largeTitle)
                // Add your history content here
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct WidgetInstructionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Thêm Widget vào màn hình khóa:")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    ForEach([
                        "1. Nhấn giữ màn hình khóa",
                        "2. Chọn Tùy chỉnh",
                        "3. Thêm tiện ích",
                        "4. Chọn Chinese Word"
                    ], id: \.self) { step in
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(step)
                                .font(.body)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Widget Instructions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ReminderSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notification Settings")) {
                    Toggle("Enable Notifications", isOn: $notificationManager.isNotificationEnabled)
                    
                    if notificationManager.isNotificationEnabled {
                        Stepper("Frequency: \(notificationManager.notificationFrequency) times/day",
                                value: $notificationManager.notificationFrequency,
                                in: 1...10)
                    }
                }
                
                Section(header: Text("Quiet Hours")) {
                    HStack {
                        Text("Start")
                        Spacer()
                        Text("\(notificationManager.quietHoursStart):00")
                    }
                    
                    HStack {
                        Text("End")
                        Spacer()
                        Text("\(notificationManager.quietHoursEnd):00")
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileSettingsView()
    }
}
