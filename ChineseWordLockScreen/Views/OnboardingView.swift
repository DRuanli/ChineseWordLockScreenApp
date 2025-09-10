//
//  OnboardingView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.7, blue: 0.6),
                    Color(red: 0.9, green: 0.8, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Skip Button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("跳过")
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                    }
                }
                .padding()
                
                // Pages
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        image: "character.book.closed.fill",
                        title: "每日学习新词汇",
                        description: "通过锁屏小组件，每次解锁手机都能学习新的中文词汇",
                        color: .teal
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        image: "bell.badge.fill",
                        title: "智能提醒",
                        description: "设置个性化学习提醒，培养每日学习习惯",
                        color: .orange
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        image: "chart.line.uptrend.xyaxis",
                        title: "追踪进度",
                        description: "记录学习统计，见证你的中文进步之旅",
                        color: .purple
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Get Started Button
                Button(action: { dismiss() }) {
                    Text(currentPage == 2 ? "开始学习" : "下一步")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .onTapGesture {
                    if currentPage < 2 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let image: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: image)
                .font(.system(size: 100))
                .foregroundColor(.white)
                .shadow(radius: 10)
            
            VStack(spacing: 15) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
