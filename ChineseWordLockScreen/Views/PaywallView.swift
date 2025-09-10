//
//  PaywallView.swift
//  ChineseWordLockScreen
//
//  Premium subscription interface with Vietnamese pricing
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var selectedPlan: ProductPlan = .monthly
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum ProductPlan: String, CaseIterable {
        case monthly = "SE.ChineseWordLockScreen.premium.monthly"
        case yearly = "SE.ChineseWordLockScreen.premium.yearly"
        case lifetime = "SE.ChineseWordLockScreen.premium.lifetime"
        
        var title: String {
            switch self {
            case .monthly: return "Hàng tháng"
            case .yearly: return "Hàng năm"
            case .lifetime: return "Trọn đời"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "59.000đ/tháng"
            case .yearly: return "590.000đ/năm"
            case .lifetime: return "990.000đ"
            }
        }
        
        var savings: String? {
            switch self {
            case .yearly: return "Tiết kiệm 118.000đ"
            case .lifetime: return "Mua một lần, dùng mãi mãi"
            default: return nil
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.7, blue: 0.6).opacity(0.3),
                        Color(red: 0.9, green: 0.8, blue: 0.3).opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .shadow(radius: 10)
                            
                            Text("Nâng cấp Premium")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Mở khóa toàn bộ tính năng học tập")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 30)
                        
                        // Features list
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureRow(
                                icon: "book.fill",
                                title: "Toàn bộ HSK3-6",
                                description: "2500+ từ vựng đầy đủ"
                            )
                            
                            FeatureRow(
                                icon: "speaker.wave.3.fill",
                                title: "Audio bản xứ",
                                description: "Phát âm chuẩn, nghe chậm"
                            )
                            
                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "SRS thông minh",
                                description: "Thuật toán ôn tập tối ưu"
                            )
                            
                            FeatureRow(
                                icon: "infinity",
                                title: "Lưu không giới hạn",
                                description: "Thư viện từ vựng cá nhân"
                            )
                            
                            FeatureRow(
                                icon: "icloud.and.arrow.up",
                                title: "Đồng bộ đám mây",
                                description: "Truy cập mọi thiết bị"
                            )
                            
                            FeatureRow(
                                icon: "chart.xyaxis.line",
                                title: "Phân tích chi tiết",
                                description: "Theo dõi tiến độ học"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.9))
                        )
                        .padding(.horizontal)
                        
                        // Pricing plans
                        VStack(spacing: 15) {
                            ForEach(ProductPlan.allCases, id: \.self) { plan in
                                PlanCard(
                                    plan: plan,
                                    isSelected: selectedPlan == plan,
                                    onSelect: { selectedPlan = plan }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // CTA Button
                        Button(action: startPurchase) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Bắt đầu dùng thử 7 ngày miễn phí")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal)
                        
                        // Terms
                        VStack(spacing: 8) {
                            Text("• Dùng thử miễn phí 7 ngày, sau đó \(selectedPlan.price)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Hủy bất cứ lúc nào trong Cài đặt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Khôi phục giao dịch") {
                                restorePurchases()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
            .alert("Lỗi", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startPurchase() {
        isProcessing = true
        Task {
            do {
                try await purchaseManager.purchase(productId: selectedPlan.rawValue)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        isProcessing = true
        Task {
            do {
                try await purchaseManager.restorePurchases()
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Không tìm thấy giao dịch nào"
                    showError = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PlanCard: View {
    let plan: PaywallView.ProductPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(plan.price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .green)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                          ) :
                          LinearGradient(
                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView()
}
