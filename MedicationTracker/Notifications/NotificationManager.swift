import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    func scheduleMedicationReminder(for medication: Medication) {
        guard let nextDue = medication.nextDueDate else { return }

        // Read lead time from UserDefaults
        let leadTimeRaw = UserDefaults.standard.string(forKey: "notificationLeadTime") ?? NotificationLeadTime.atDueTime.rawValue
        let leadTime = NotificationLeadTime(rawValue: leadTimeRaw) ?? .atDueTime
        let notificationDate = nextDue.addingTimeInterval(-leadTime.timeInterval)

        // Don't schedule notifications for past dates
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        if leadTime == .atDueTime {
            content.body = "\(medication.name) is due now"
        } else {
            content.body = "\(medication.name) is due in \(leadTime.minutes) minutes"
        }
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate, repeats: false
        )

        let request = UNNotificationRequest(
            identifier: medication.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for medicationId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [medicationId.uuidString]
            )
    }

    func rescheduleAll(medications: [Medication]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for medication in medications {
            scheduleMedicationReminder(for: medication)
        }
    }
}
