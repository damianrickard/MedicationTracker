import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MedicationStore.self) private var store

    @AppStorage("sortOption") private var sortOptionRaw: String = SortOption.byDueDate.rawValue
    @AppStorage("notificationLeadTime") private var leadTimeRaw: String = NotificationLeadTime.atDueTime.rawValue

    var body: some View {
        #if os(iOS)
        NavigationStack {
            settingsForm
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        #else
        VStack(spacing: 0) {
            settingsForm

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 350, minHeight: 200)
        #endif
    }

    private var settingsForm: some View {
        Form {
            Section("Sort Order") {
                Picker("Sort medications", selection: $sortOptionRaw) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Notifications") {
                Picker("Reminder timing", selection: $leadTimeRaw) {
                    ForEach(NotificationLeadTime.allCases) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: leadTimeRaw) { _, _ in
                    NotificationManager.shared.rescheduleAll(medications: store.medications)
                }
            }
        }
        .formStyle(.grouped)
        #if os(macOS)
        .padding()
        #endif
    }
}
