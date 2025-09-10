//
//  AuthenticationManager.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import Foundation
import SwiftUI
import CoreData
import CryptoKit

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    private let context = PersistenceController.shared.container.viewContext
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let userIdKey = "currentUserId"
    
    private init() {
        checkForExistingSession()
    }
    
    // MARK: - Session Management
    
    func checkForExistingSession() {
        guard let userIdString = userDefaults.string(forKey: userIdKey),
              let userId = UUID(uuidString: userIdString) else {
            isAuthenticated = false
            return
        }
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        
        do {
            let users = try context.fetch(request)
            if let user = users.first {
                self.currentUser = user
                self.isAuthenticated = true
                updateLastLogin(for: user)
            } else {
                clearSession()
            }
        } catch {
            print("Error fetching user: \(error)")
            clearSession()
        }
    }
    
    private func updateLastLogin(for user: User) {
        user.lastLoginAt = Date()
        try? context.save()
    }
    
    private func clearSession() {
        userDefaults.removeObject(forKey: userIdKey)
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Authentication Methods
    
    func signUp(username: String, email: String, password: String) async -> Bool {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        // Validate input
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            await MainActor.run {
                errorMessage = "请填写所有字段"
                isLoading = false
            }
            return false
        }
        
        guard isValidEmail(email) else {
            await MainActor.run {
                errorMessage = "请输入有效的电子邮箱"
                isLoading = false
            }
            return false
        }
        
        guard password.count >= 6 else {
            await MainActor.run {
                errorMessage = "密码至少需要6个字符"
                isLoading = false
            }
            return false
        }
        
        // Check if username or email already exists
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@ OR email == %@", username, email)
        
        do {
            let existingUsers = try context.fetch(request)
            if !existingUsers.isEmpty {
                await MainActor.run {
                    errorMessage = "用户名或邮箱已存在"
                    isLoading = false
                }
                return false
            }
            
            // Create new user
            let newUser = User(context: context)
            newUser.userId = UUID()
            newUser.username = username
            newUser.email = email
            newUser.passwordHash = hashPassword(password)
            newUser.createdAt = Date()
            newUser.lastLoginAt = Date()
            newUser.preferredHSKLevel = 5
            newUser.dailyGoal = 10
            newUser.notificationEnabled = true
            newUser.notificationFrequency = 3
            
            try context.save()
            
            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
                self.isLoading = false
                self.saveSession(userId: newUser.userId!)
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "注册失败: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
    }
    
    func login(username: String, password: String) async -> Bool {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        guard !username.isEmpty, !password.isEmpty else {
            await MainActor.run {
                errorMessage = "请输入用户名和密码"
                isLoading = false
            }
            return false
        }
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@ OR email == %@", username, username)
        
        do {
            let users = try context.fetch(request)
            guard let user = users.first else {
                await MainActor.run {
                    errorMessage = "用户名或密码错误"
                    isLoading = false
                }
                return false
            }
            
            // Verify password
            guard verifyPassword(password, hash: user.passwordHash ?? "") else {
                await MainActor.run {
                    errorMessage = "用户名或密码错误"
                    isLoading = false
                }
                return false
            }
            
            // Update last login
            user.lastLoginAt = Date()
            try context.save()
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
                self.saveSession(userId: user.userId!)
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "登录失败: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
    }
    
    func logout() {
        clearSession()
    }
    
    // MARK: - Helper Methods
    
    private func saveSession(userId: UUID) {
        userDefaults.set(userId.uuidString, forKey: userIdKey)
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPassword(_ password: String, hash: String) -> Bool {
        return hashPassword(password) == hash
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - User Profile Management
    
    func updateUserProfile(hskLevel: Int? = nil, dailyGoal: Int? = nil, notificationEnabled: Bool? = nil, notificationFrequency: Int? = nil) {
        guard let user = currentUser else { return }
        
        if let hskLevel = hskLevel {
            user.preferredHSKLevel = Int16(hskLevel)
        }
        if let dailyGoal = dailyGoal {
            user.dailyGoal = Int16(dailyGoal)
        }
        if let notificationEnabled = notificationEnabled {
            user.notificationEnabled = notificationEnabled
        }
        if let notificationFrequency = notificationFrequency {
            user.notificationFrequency = Int16(notificationFrequency)
        }
        
        do {
            try context.save()
        } catch {
            print("Error updating user profile: \(error)")
        }
    }
}
