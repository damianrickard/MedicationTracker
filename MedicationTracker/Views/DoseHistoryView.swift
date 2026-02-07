import SwiftUI

struct DoseHistoryView: View {
    @Environment(MedicationStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let medication: Medication

    var body: some View {
        #if os(iOS)
        NavigationStack {
            historyContent
                .navigationTitle("\(medication.name) History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        #else
        VStack(spacing: 0) {
            historyContent

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    @ViewBuilder
    private var historyContent: some View {
        let currentMed = store.medications.first(where: { $0.id == medication.id })
        let sortedHistory = (currentMed?.doseHistory ?? [])
            .sorted { $0.date > $1.date }

        if sortedHistory.isEmpty {
            ContentUnavailableView(
                "No Doses Recorded",
                systemImage: "clock",
                description: Text("Dose history will appear here after giving medication.")
            )
        } else {
            List {
                Section("Total doses: \(sortedHistory.count)") {
                    ForEach(sortedHistory) { dose in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(TimeFormatting.formatDate(dose.date))
                                    .font(.body)
                                if !dose.note.isEmpty {
                                    Text(dose.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(dose.date, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { sortedHistory[$0].id }
                        for doseId in toDelete {
                            store.deleteDoseRecord(
                                medicationId: medication.id,
                                doseId: doseId
                            )
                        }
                    }
                }
            }
        }
    }
}
