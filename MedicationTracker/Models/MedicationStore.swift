import Foundation
import Observation

@Observable
class MedicationStore {
    var medications: [Medication] = []

    private let persistence = PersistenceManager()

    init() {
        medications = persistence.load()
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
        medications[index].lastGivenDate = date
        save()
        NotificationManager.shared.scheduleMedicationReminder(for: medications[index])
    }

    private func save() {
        persistence.save(medications)
    }
}
