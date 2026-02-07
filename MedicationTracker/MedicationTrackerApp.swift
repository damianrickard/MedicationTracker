import SwiftUI

@main
struct MedicationTrackerApp: App {
    @State private var store = MedicationStore()

    #if os(macOS)
    init() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                #if os(iOS)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
                #endif
        }
    }
}
