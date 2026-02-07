import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case byDueDate = "byDueDate"
    case byName = "byName"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .byDueDate: return "By Due Date"
        case .byName: return "By Name"
        }
    }
}
