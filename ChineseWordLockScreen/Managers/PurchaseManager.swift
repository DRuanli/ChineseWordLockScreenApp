//
//  PurchaseManager.swift
//  ChineseWordLockScreen
//
//  Handles In-App Purchases with StoreKit 2
//

import Foundation
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    @Published var isPremium = false
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productIds = [
        "SE.ChineseWordLockScreen.premium.monthly",
        "SE.ChineseWordLockScreen.premium.yearly",
        "SE.ChineseWordLockScreen.premium.lifetime"
    ]
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    func purchase(productId: String) async throws {
        guard let product = products.first(where: { $0.id == productId }) else {
            throw PurchaseError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            
        case .userCancelled:
            throw PurchaseError.userCancelled
            
        case .pending:
            throw PurchaseError.pending
            
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateCustomerProductStatus()
    }
    
    // MARK: - Check Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Update Status
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .consumable:
                    // Handle consumable if needed
                    break
                    
                case .nonConsumable:
                    purchasedProducts.insert(transaction.productID)
                    
                case .autoRenewable:
                    if transaction.revocationDate == nil {
                        purchasedProducts.insert(transaction.productID)
                    }
                    
                default:
                    break
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
        self.isPremium = !purchasedProducts.isEmpty
        
        // Save to UserDefaults for quick access
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
        
        // Notify widgets
        if let userDefaults = UserDefaults(suiteName: "group.SE.ChineseWordLockScreen") {
            userDefaults.set(isPremium, forKey: "isPremium")
        }
    }
    
    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction listener error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Check Premium Features
    func hasAccess(to feature: PremiumFeature) -> Bool {
        guard isPremium else { return false }
        
        // Check specific product access
        switch feature {
        case .unlimitedWords:
            return true // All premium plans
        case .nativeAudio:
            return true // All premium plans
        case .advancedSRS:
            return purchasedProductIDs.contains("SE.ChineseWordLockScreen.premium.yearly") ||
                   purchasedProductIDs.contains("SE.ChineseWordLockScreen.premium.lifetime")
        case .exportImport:
            return true // All premium plans
        case .offlineMode:
            return purchasedProductIDs.contains("SE.ChineseWordLockScreen.premium.lifetime")
        case .cloudSync:
            return true // All premium plans
        case .advancedAnalytics:
            return purchasedProductIDs.contains("SE.ChineseWordLockScreen.premium.yearly") ||
                   purchasedProductIDs.contains("SE.ChineseWordLockScreen.premium.lifetime")
        }
    }
}

// MARK: - Premium Features
enum PremiumFeature {
    case unlimitedWords
    case nativeAudio
    case advancedSRS
    case exportImport
    case offlineMode
    case cloudSync
    case advancedAnalytics
}

// MARK: - Purchase Errors
enum PurchaseError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case failedVerification
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Không tìm thấy sản phẩm"
        case .userCancelled:
            return "Đã hủy giao dịch"
        case .pending:
            return "Giao dịch đang chờ xử lý"
        case .failedVerification:
            return "Xác thực giao dịch thất bại"
        case .unknown:
            return "Lỗi không xác định"
        }
    }
}

// MARK: - Helper Extension
extension PurchaseManager {
    var monthlyProduct: Product? {
        products.first { $0.id == "SE.ChineseWordLockScreen.premium.monthly" }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == "SE.ChineseWordLockScreen.premium.yearly" }
    }
    
    var lifetimeProduct: Product? {
        products.first { $0.id == "SE.ChineseWordLockScreen.premium.lifetime" }
    }
    
    func formattedPrice(for productId: String) -> String {
        guard let product = products.first(where: { $0.id == productId }) else {
            return ""
        }
        return product.displayPrice
    }
}
