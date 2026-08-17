import SwiftUI
import FirebaseCore
import FirebaseCrashlytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

/// The expense tracker application entry point and shared-state ownership boundary.
@main
struct FrictionSalesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var manager = ExpenseManager()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(manager)
                    .environmentObject(authManager)
                    .preferredColorScheme(.light)
                    .task {
                        await manager.fetchFromFirebase()
                    }
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .preferredColorScheme(.light)
            }
        }
    }
}

#Preview("App Root") {
    ContentView()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}
