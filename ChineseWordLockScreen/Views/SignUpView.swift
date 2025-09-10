//
//  SignUpView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedHSKLevel = 5
    @State private var isPasswordVisible = false
    @State private var agreedToTerms = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.8, blue: 0.3),
                    Color(red: 0.1, green: 0.7, blue: 0.6)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Title
                        VStack(spacing: 8) {
                            Text("创建账号")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("开始你的中文学习之旅")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 20)
                        
                        // Form Container
                        VStack(spacing: 20) {
                            // Username Field
                            CustomTextField(
                                title: "用户名",
                                text: $username,
                                placeholder: "选择一个用户名",
                                icon: "person.fill",
                                focused: $focusedField,
                                field: .username
                            )
                            
                            // Email Field
                            CustomTextField(
                                title: "邮箱",
                                text: $email,
                                placeholder: "your@email.com",
                                icon: "envelope.fill",
                                keyboardType: .emailAddress,
                                focused: $focusedField,
                                field: .email
                            )
                            
                            // Password Field
                            CustomSecureField(
                                title: "密码",
                                text: $password,
                                placeholder: "至少6个字符",
                                icon: "lock.fill",
                                isVisible: $isPasswordVisible,
                                focused: $focusedField,
                                field: .password
                            )
                            
                            // Confirm Password Field
                            CustomSecureField(
                                title: "确认密码",
                                text: $confirmPassword,
                                placeholder: "再次输入密码",
                                icon: "lock.fill",
                                isVisible: $isPasswordVisible,
                                focused: $focusedField,
                                field: .confirmPassword,
                                showToggle: false
                            )
                            
                            // HSK Level Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("HSK 级别")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack(spacing: 10) {
                                    ForEach(3...6, id: \.self) { level in
                                        Button(action: { selectedHSKLevel = level }) {
                                            Text("HSK \(level)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedHSKLevel == level ?
                                                    Color.white.opacity(0.3) :
                                                    Color.white.opacity(0.1)
                                                )
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(
                                                            selectedHSKLevel == level ?
                                                            Color.white.opacity(0.5) :
                                                            Color.white.opacity(0.2),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                            
                            // Terms Agreement
                            HStack {
                                Button(action: { agreedToTerms.toggle() }) {
                                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.white)
                                }
                                
                                Text("我同意服务条款和隐私政策")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                            }
                            
                            // Error Message
                            if let errorMessage = authManager.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                            }
                            
                            // Sign Up Button
                            Button(action: signUp) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("注册")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .disabled(!canSignUp)
                            .opacity(canSignUp ? 1 : 0.6)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.2))
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private var canSignUp: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        agreedToTerms &&
        !authManager.isLoading
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            authManager.errorMessage = "密码不匹配"
            return
        }
        
        Task {
            let success = await authManager.signUp(username: username, email: email, password: password)
            if success {
                await MainActor.run {
                    authManager.updateUserProfile(hskLevel: selectedHSKLevel)
                    dismiss()
                }
            }
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var focused: FocusState<SignUpView.Field?>.Binding
    let field: SignUpView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboardType)
                    .focused(focused, equals: field)
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    @Binding var isVisible: Bool
    var focused: FocusState<SignUpView.Field?>.Binding
    let field: SignUpView.Field
    var showToggle: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.7))
                
                if isVisible {
                    TextField("", text: $text)
                        .placeholder(when: text.isEmpty) {
                            Text(placeholder)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused(focused, equals: field)
                } else {
                    SecureField("", text: $text)
                        .placeholder(when: text.isEmpty) {
                            Text(placeholder)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(.white)
                        .focused(focused, equals: field)
                }
                
                if showToggle {
                    Button(action: { isVisible.toggle() }) {
                        Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    SignUpView()
}
