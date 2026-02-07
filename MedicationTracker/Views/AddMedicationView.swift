import SwiftUI

struct AddMedicationView: View {
    @Environment(MedicationStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var medicationToEdit: Medication?

    @State private var name: String = ""
    @State private var frequencySelection: String = "3x"
    @State private var customHours: Int = 8
    @State private var notes: String = ""
    @State private var hasLastDose: Bool = false
    @State private var lastDoseDate: Date = Date()

    private var isEditing: Bool { medicationToEdit != nil }

    private let frequencyOptions: [(label: String, key: String, hours: Double)] = [
        ("4x daily (every 6h)", "4x", 6),
        ("3x daily (every 8h)", "3x", 8),
        ("2x daily (every 12h)", "2x", 12),
        ("Once daily (every 24h)", "1x", 24),
        ("Every other day (48h)", "48h", 48),
        ("Custom", "custom", 0),
    ]

    private var frequencyHours: Double {
        if frequencySelection == "custom" {
            return max(Double(customHours), 1)
        }
        return frequencyOptions.first { $0.key == frequencySelection }?.hours ?? 8
    }

    var body: some View {
        #if os(iOS)
        NavigationStack {
            formContent
                .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isEditing ? "Save" : "Add") {
                            saveMedication()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
        #else
        VStack(spacing: 0) {
            formContent

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save Changes" : "Add Medication") {
                    saveMedication()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        .fixedSize(horizontal: true, vertical: false)
        #endif
    }

    private var formContent: some View {
        Form {
            TextField("Medication Name", text: $name)
                #if os(macOS)
                .textFieldStyle(.roundedBorder)
                #endif

            Picker("Frequency", selection: $frequencySelection) {
                ForEach(frequencyOptions, id: \.key) { option in
                    Text(option.label).tag(option.key)
                }
            }

            if frequencySelection == "custom" {
                Stepper("Every \(customHours) hours", value: $customHours, in: 1...168)
            }

            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(2...4)

            Toggle("Set last dose time", isOn: $hasLastDose)

            if hasLastDose {
                DatePicker(
                    "Last dose",
                    selection: $lastDoseDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
        .formStyle(.grouped)
        #if os(macOS)
        .padding()
        #endif
        .onAppear {
            if let med = medicationToEdit {
                name = med.name
                if let match = frequencyOptions.first(where: { $0.hours == med.frequencyHours && $0.key != "custom" }) {
                    frequencySelection = match.key
                } else {
                    frequencySelection = "custom"
                    customHours = max(Int(med.frequencyHours), 1)
                }
                notes = med.notes
                if let lastGiven = med.lastGivenDate {
                    hasLastDose = true
                    lastDoseDate = lastGiven
                }
            }
        }
    }

    private func saveMedication() {
        if isEditing {
            var updated = medicationToEdit!
            updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.frequencyHours = frequencyHours
            updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.lastGivenDate = hasLastDose ? lastDoseDate : nil
            store.updateMedication(updated)
        } else {
            let medication = Medication(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                frequencyHours: frequencyHours,
                lastGivenDate: hasLastDose ? lastDoseDate : nil,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            store.addMedication(medication)
        }
        dismiss()
    }
}
