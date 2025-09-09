//
//  MainTabView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("主页", systemImage: "house.fill")
                }
            
            LibraryView()
                .tabItem {
                    Label("词库", systemImage: "books.vertical.fill")
                }
            
            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            notificationManager.requestAuthorization()
        }
    }
}

struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("selectedHSKLevel") private var selectedHSKLevel = 5
    @State private var notificationFrequency = 3
    
    var body: some View {
        NavigationView {
            Form {
                Section("学习设置") {
                    Picker("HSK级别", selection: $selectedHSKLevel) {
                        Text("HSK 3").tag(3)
                        Text("HSK 4").tag(4)
                        Text("HSK 5").tag(5)
                        Text("HSK 6").tag(6)
                    }
                }
                
                Section("通知设置") {
                    Toggle("启用通知", isOn: $notificationManager.isNotificationEnabled)
                        .onChange(of: notificationManager.isNotificationEnabled) { newValue in
                            if newValue {
                                notificationManager.requestAuthorization()
                            }
                        }
                    
                    if notificationManager.isNotificationEnabled {
                        Stepper("每日提醒: \(notificationManager.notificationFrequency)次",
                                value: $notificationManager.notificationFrequency,
                                in: 1...5)
                            .onChange(of: notificationManager.notificationFrequency) { newValue in
                                notificationManager.updateNotificationFrequency(newValue)
                            }
                    }
                }
                
                Section("Widget设置") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("添加Widget到锁屏")
                            .font(.headline)
                        Text("1. 长按锁屏")
                            .font(.caption)
                        Text("2. 点击自定义")
                            .font(.caption)
                        Text("3. 添加小组件")
                            .font(.caption)
                        Text("4. 选择 Chinese Word")
                            .font(.caption)
                    }
                    .padding(.vertical, 5)
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("开发者")
                        Spacer()
                        Text("Lê Nguyễn")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    MainTabView()
}
