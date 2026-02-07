import Foundation

struct Medication: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var frequencyHours: Double
    var lastGivenDate: Date?
    var notes: String

    var nextDueDate: Date? {
        guard let lastGiven = lastGivenDate else { return nil }
        return lastGiven.addingTimeInterval(frequencyHours * 3600)
    }

    var isOverdue: Bool {
        guard let nextDue = nextDueDate else { return false }
        return Date() > nextDue
    }

    var isDueSoon: Bool {
        guard let nextDue = nextDueDate else { return false }
        let thirtyMinutesFromNow = Date().addingTimeInterval(30 * 60)
        return nextDue <= thirtyMinutesFromNow && !isOverdue
    }

    init(id: UUID = UUID(), name: String, frequencyHours: Double, lastGivenDate: Date? = nil, notes: String = "") {
        self.id = id
        self.name = name
        self.frequencyHours = frequencyHours
        self.lastGivenDate = lastGivenDate
        self.notes = notes
    }
}
