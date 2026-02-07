import Foundation
import Observation
import Combine

@Observable
class MedicationStore {
    var medications: [Medication] = []

    private let persistence = PersistenceManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        medications = persistence.load()

        // Listen for remote iCloud changes
        NotificationCenter.default.publisher(for: PersistenceManager.remoteDataDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.medications = self.persistence.load()
                NotificationManager.shared.rescheduleAll(medications: self.medications)
            }
            .store(in: &cancellables)
    }

    func addMedication(_ medication: Medication) {
        medications.append(medication)
        save()
        NotificationManager.shared.scheduleMedicationReminder(for: medication)
    }

    func deleteMedication(id: UUID) {
        medications.removeAll { $0.id == id }
        save()
        NotificationManager.shared.cancelReminder(for: id)
    }

    func updateMedication(_ medication: Medication) {
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[index] = medication
        save()
        NotificationManager.shared.scheduleMedicationReminder(for: medication)
    }

    func giveMedication(id: UUID, at date: Date = Date()) {
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        let record = DoseRecord(date: date)
        medications[index].doseHistory.append(record)
        save()
        NotificationManager.shared.scheduleMedicationReminder(for: medications[index])
    }

    func deleteDoseRecord(medicationId: UUID, doseId: UUID) {
        guard let index = medications.firstIndex(where: { $0.id == medicationId }) else { return }
        medications[index].doseHistory.removeAll { $0.id == doseId }
        save()
        NotificationManager.shared.scheduleMedicationReminder(for: medications[index])
    }

    private func save() {
        persistence.save(medications)
    }
}
