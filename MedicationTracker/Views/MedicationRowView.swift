import SwiftUI

struct MedicationRowView: View {
    @Environment(MedicationStore.self) private var store
    let medication: Medication
    @State private var showingLogPastDose = false
    @State private var showingEdit = false
    @State private var showingHistory = false
    @State private var pastDoseDate = Date()

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)

                Text(TimeFormatting.formatFrequency(medication.frequencyHours))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !medication.notes.isEmpty {
                    Text(medication.notes)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .italic()
                }

                if let lastGiven = medication.lastGivenDate {
                    Text("Last given: \(TimeFormatting.formatDate(lastGiven)) (\(medication.doseHistory.count) \(medication.doseHistory.count == 1 ? "dose" : "doses"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let nextDue = medication.nextDueDate {
                    Text(TimeFormatting.formatRelativeTime(until: nextDue))
                        .font(.caption)
                        .foregroundStyle(medication.isOverdue ? .red : .secondary)
                        .fontWeight(medication.isOverdue ? .bold : .regular)
                } else {
                    Text("Not yet given")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            VStack(spacing: 6) {
                Button(action: {
                    withAnimation {
                        store.giveMedication(id: medication.id)
                    }
                }) {
                    Label("Give Now", systemImage: "clock.badge.checkmark")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                #if os(iOS)
                .controlSize(.small)
                #endif
                .tint(medication.isOverdue ? .red : .accentColor)

                Button(action: {
                    pastDoseDate = Date()
                    showingLogPastDose = true
                }) {
                    Label("Log Past Dose", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingLogPastDose) {
                    VStack(spacing: 12) {
                        Text("Log Past Dose")
                            .font(.headline)

                        DatePicker(
                            "Date & Time",
                            selection: $pastDoseDate,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        HStack {
                            Button("Cancel") {
                                showingLogPastDose = false
                            }
                            Spacer()
                            Button("Log Dose") {
                                withAnimation {
                                    store.giveMedication(id: medication.id, at: pastDoseDate)
                                }
                                showingLogPastDose = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    #if os(macOS)
                    .frame(width: 280)
                    #endif
                }

                Button(action: {
                    showingEdit = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .sheet(isPresented: $showingEdit) {
                    AddMedicationView(medicationToEdit: medication)
                }

                Button(action: {
                    showingHistory = true
                }) {
                    Label("History", systemImage: "list.bullet.clipboard")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .sheet(isPresented: $showingHistory) {
                    DoseHistoryView(medication: medication)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(
            medication.isOverdue ? Color.red.opacity(0.08) : nil
        )
    }

    private var statusColor: Color {
        if medication.isOverdue {
            return .red
        } else if medication.isDueSoon {
            return .orange
        } else if medication.lastGivenDate != nil {
            return .green
        } else {
            return .gray
        }
    }
}
