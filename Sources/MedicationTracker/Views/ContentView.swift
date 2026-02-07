import SwiftUI

struct ContentView: View {
    @Environment(MedicationStore.self) private var store
    @State private var showingAddSheet = false
    @State private var refreshTick = false

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if store.medications.isEmpty {
                    ContentUnavailableView(
                        "No Medications",
                        systemImage: "pills",
                        description: Text("Add your dog's medications to start tracking doses.")
                    )
                } else {
                    List {
                        ForEach(sortedMedications) { medication in
                            MedicationRowView(medication: medication)
                        }
                        .onDelete { offsets in
                            let idsToDelete = offsets.map { sortedMedications[$0].id }
                            for id in idsToDelete {
                                store.deleteMedication(id: id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Medication Tracker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Medication", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMedicationView()
            }
            .onReceive(timer) { _ in
                refreshTick.toggle()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    private var sortedMedications: [Medication] {
        _ = refreshTick
        return store.medications.sorted { med1, med2 in
            if med1.isOverdue != med2.isOverdue {
                return med1.isOverdue
            }
            if let d1 = med1.nextDueDate, let d2 = med2.nextDueDate {
                return d1 < d2
            }
            if med1.nextDueDate != nil { return true }
            if med2.nextDueDate != nil { return false }
            return med1.name < med2.name
        }
    }
}
