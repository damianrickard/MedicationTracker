import Foundation

enum TimeFormatting {
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func formatRelativeTime(until date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval < 0 {
            return "Overdue by \(formatDuration(abs(interval)))"
        } else {
            return "Due in \(formatDuration(interval))"
        }
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    static func formatFrequency(_ hours: Double) -> String {
        if hours == 24.0 {
            return "Once daily"
        } else if hours == 12.0 {
            return "Every 12 hours"
        } else if hours == 8.0 {
            return "Every 8 hours"
        } else if hours.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "Every \(Int(hours)) hours"
        } else {
            return "Every \(hours) hours"
        }
    }
}
