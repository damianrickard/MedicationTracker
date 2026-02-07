import Foundation

struct DoseRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var note: String

    init(id: UUID = UUID(), date: Date, note: String = "") {
        self.id = id
        self.date = date
        self.note = note
    }
}
