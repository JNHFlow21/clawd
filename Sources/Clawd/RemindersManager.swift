import EventKit
import Foundation

struct ReminderBoardItem {
  let title: String
  let dueDate: Date?
}

struct ReminderBoardSnapshot {
  let items: [ReminderBoardItem]
  let statusText: String
  let isAuthorized: Bool
}

final class RemindersManager {
  var onSnapshot: ((ReminderBoardSnapshot) -> Void)?

  private let settings: AppSettings
  private let eventStore = EKEventStore()
  private var refreshTimer: Timer?
  private let maxItems = 5

  init(settings: AppSettings) {
    self.settings = settings
  }

  func start() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(eventStoreChanged),
      name: .EKEventStoreChanged,
      object: eventStore
    )

    requestAccessAndRefresh()
    refreshTimer?.invalidate()
    let timer = Timer(timeInterval: 20, repeats: true) { [weak self] _ in
      self?.refresh()
    }
    RunLoop.main.add(timer, forMode: .common)
    refreshTimer = timer
  }

  func stop() {
    refreshTimer?.invalidate()
    refreshTimer = nil
    NotificationCenter.default.removeObserver(self)
  }

  func refreshNow() {
    refresh()
  }

  @objc private func eventStoreChanged() {
    refresh()
  }

  private func requestAccessAndRefresh() {
    requestRemindersAccess { [weak self] granted, error in
      DispatchQueue.main.async {
        guard let self else { return }
        if granted {
          self.refresh()
        } else {
          self.publish(
            items: [],
            statusText: error == nil ? self.text(.remindersAccessNeeded) : self.text(.remindersUnavailable),
            isAuthorized: false
          )
        }
      }
    }
  }

  private func requestRemindersAccess(completion: @escaping (Bool, Error?) -> Void) {
    if #available(macOS 14.0, *) {
      eventStore.requestFullAccessToReminders(completion: completion)
    } else {
      eventStore.requestAccess(to: .reminder, completion: completion)
    }
  }

  private func refresh() {
    let predicate = eventStore.predicateForIncompleteReminders(
      withDueDateStarting: nil,
      ending: nil,
      calendars: nil
    )

    eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
      guard let self else { return }
      let items = (reminders ?? [])
        .filter { !$0.isCompleted }
        .map { reminder in
          ReminderBoardItem(
            title: reminder.title.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: Self.date(from: reminder.dueDateComponents)
          )
        }
        .filter { !$0.title.isEmpty }
        .sorted { lhs, rhs in
          switch (lhs.dueDate, rhs.dueDate) {
          case let (left?, right?):
            return left < right
          case (.some, .none):
            return true
          case (.none, .some):
            return false
          case (.none, .none):
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
          }
        }

      let limitedItems = Array(items.prefix(self.maxItems))
      let status = items.isEmpty ? self.text(.noOpenReminders) : L10n.openReminders(items.count, language: self.settings.language)
      DispatchQueue.main.async {
        self.publish(items: limitedItems, statusText: status, isAuthorized: true)
      }
    }
  }

  private func publish(items: [ReminderBoardItem], statusText: String, isAuthorized: Bool) {
    onSnapshot?(
      ReminderBoardSnapshot(
        items: items,
        statusText: statusText,
        isAuthorized: isAuthorized
      )
    )
  }

  private func text(_ key: L10nKey) -> String {
    L10n.text(key, language: settings.language)
  }

  private static func date(from components: DateComponents?) -> Date? {
    guard var components else { return nil }
    if components.calendar == nil {
      components.calendar = Calendar.current
    }
    return components.date
  }
}
