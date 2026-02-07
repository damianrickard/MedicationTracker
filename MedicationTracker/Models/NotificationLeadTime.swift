import Foundation

enum NotificationLeadTime: String, CaseIterable, Identifiable {
    case atDueTime = "0"
    case fiveMinutes = "5"
    case tenMinutes = "10"
    case fifteenMinutes = "15"
    case thirtyMinutes = "30"
    case sixtyMinutes = "60"

    var id: String { rawValue }

    var minutes: Int {
        Int(rawValue) ?? 0
    }

    var timeInterval: TimeInterval {
        TimeInterval(minutes * 60)
    }

    var displayName: String {
        switch self {
        case .atDueTime: return "At due time"
        case .fiveMinutes: return "5 minutes before"
        case .tenMinutes: return "10 minutes before"
        case .fifteenMinutes: return "15 minutes before"
        case .thirtyMinutes: return "30 minutes before"
        case .sixtyMinutes: return "1 hour before"
        }
    }
}
