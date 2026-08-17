import SwiftUI

/// The expense tracker application entry point and shared-state ownership boundary.
@main
struct FrictionSalesApp: App {
    @StateObject private var manager = ExpenseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .preferredColorScheme(.light)
        }
    }
}

#Preview("App Root") {
    ContentView()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}
