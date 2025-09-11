//
//  View+Extensions.swift
//  ChineseWordLockScreen
//
//  Helper extensions for the redesigned interface
//

import SwiftUI
import UIKit

// MARK: - View Extensions
extension View {
    // Capture view as UIImage
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.all))
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    // Share sheet presenter
    func shareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
    
    // Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Color Extensions
extension Color {
    // App theme colors
    static let appBeige = Color(red: 0.95, green: 0.93, blue: 0.88)
    static let appDarkText = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let appLightText = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    // Tone colors for pinyin
    static let tone1 = Color(red: 0.2, green: 0.7, blue: 0.2) // Green
    static let tone2 = Color(red: 0.9, green: 0.6, blue: 0.0) // Orange
    static let tone3 = Color(red: 0.1, green: 0.5, blue: 0.8) // Blue
    static let tone4 = Color(red: 0.8, green: 0.2, blue: 0.2) // Red
    static let toneNeutral = Color.gray
}

// MARK: - Share Activity Helper
struct ShareActivity: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareActivity>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            presentationMode.wrappedValue.dismiss()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareActivity>) {}
}

// MARK: - Screenshot Detection
class ScreenshotDetector: ObservableObject {
    @Published var screenshotTaken = false
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotDetected),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    @objc private func screenshotDetected() {
        screenshotTaken = true
        
        // Reset after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.screenshotTaken = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Device Info
struct DeviceInfo {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var hasNotch: Bool {
        guard let window = UIApplication.shared.windows.first else { return false }
        return window.safeAreaInsets.top > 20
    }
}

// MARK: - Haptic Feedback
enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    
    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
