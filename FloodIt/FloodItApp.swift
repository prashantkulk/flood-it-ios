import SwiftUI

@main
struct FloodItApp: App {
    // MARK: P12-T5 Ensure StoreManager initializes on launch to check entitlements
    @StateObject private var storeManager = StoreManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
