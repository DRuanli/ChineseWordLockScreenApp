//
//  LoginView.swift
//  ChineseWordLockScreen
//
//  Created by Lê Nguyễn on 9/9/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            ScrollView {
                VStack(spacing: 30) {
                    logoAndTitle
                    loginForm
                    Spacer(minLength: 100)
                }
            }
        }
        .onTapGesture { focusedField = nil }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
}

// MARK: - Subviews
private extension LoginView {
    var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.7, blue: 0.6),
                Color(red: 0.9, green: 0.8, blue: 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    var logoAndTitle: some View {
        VStack(spacing: 20) {
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .shadow(radius: 10)
            
            VStack(spacing: 8) {
                Text("中文词汇")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Chinese Word Lock Screen")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.top, 60)
    }
    
    var loginForm: some View {
        VStack(spacing: 20) {
            usernameField
            passwordField
            
            if let errorMessage = authManager.errorMessage {
                errorText(errorMessage)
            }
            
            loginButton
            signUpLink
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
    }
    
    var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("用户名 / 邮箱")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("", text: $username)
                    .placeholder(when: username.isEmpty) {
                        Text("输入用户名或邮箱")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
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
    
    var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("密码")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.7))
                
                if isPasswordVisible {
                    TextField("", text: $password)
                        .placeholder(when: password.isEmpty) {
                            Text("输入密码")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                } else {
                    SecureField("", text: $password)
                        .placeholder(when: password.isEmpty) {
                            Text("输入密码")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .password)
                }
                
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.white.opacity(0.7))
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
    
    func errorText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
    }
    
    var loginButton: some View {
        Button(action: {
            Task {
                await authManager.login(username: username, password: password)
            }
        }) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("登录")
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
        .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
        .opacity((authManager.isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1)
    }
    
    var signUpLink: some View {
        HStack {
            Text("还没有账号？")
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: { showingSignUp = true }) {
                Text("注册")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .underline()
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Custom Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
}
