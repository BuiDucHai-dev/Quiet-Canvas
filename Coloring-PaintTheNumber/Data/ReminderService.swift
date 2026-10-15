//
//  ReminderService.swift
//  Coloring-PaintTheNumber
//

import Foundation
import UserNotifications

/// Daily local notification for the challenge.
enum Reminder {
    static func schedule(minutes: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return false }
        center.removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "Today's picture is ready"
        content.body = "Take ten quiet minutes to color."
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: minutes / 60, minute: minutes % 60), repeats: true)
        try? await center.add(UNNotificationRequest(identifier: "daily", content: content, trigger: trigger))
        return true
    }

    static func cancel() { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
}
