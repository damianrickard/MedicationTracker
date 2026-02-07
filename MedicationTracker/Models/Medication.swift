import Foundation

struct Medication: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var frequencyHours: Double
    var doseHistory: [DoseRecord]
    var notes: String

    /// Most recent dose date, computed from dose history
    var lastGivenDate: Date? {
        doseHistory.map(\.date).max()
    }

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

    init(id: UUID = UUID(), name: String, frequencyHours: Double, lastGivenDate: Date? = nil, doseHistory: [DoseRecord]? = nil, notes: String = "") {
        self.id = id
        self.name = name
        self.frequencyHours = frequencyHours
        self.notes = notes

        if let history = doseHistory {
            self.doseHistory = history
        } else if let date = lastGivenDate {
            self.doseHistory = [DoseRecord(date: date)]
        } else {
            self.doseHistory = []
        }
    }

    // MARK: - Custom Codable for migration from lastGivenDate to doseHistory

    enum CodingKeys: String, CodingKey {
        case id, name, frequencyHours, doseHistory, notes
        case lastGivenDate // Legacy key for migration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        frequencyHours = try container.decode(Double.self, forKey: .frequencyHours)
        notes = try container.decode(String.self, forKey: .notes)

        // Try new format first
        if let history = try container.decodeIfPresent([DoseRecord].self, forKey: .doseHistory) {
            doseHistory = history
        }
        // Fall back to legacy single-date format
        else if let legacyDate = try container.decodeIfPresent(Date.self, forKey: .lastGivenDate) {
            doseHistory = [DoseRecord(date: legacyDate)]
        } else {
            doseHistory = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(frequencyHours, forKey: .frequencyHours)
        try container.encode(notes, forKey: .notes)
        try container.encode(doseHistory, forKey: .doseHistory)
        // Do NOT encode lastGivenDate — it is now computed
    }
}
