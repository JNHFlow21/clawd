import Foundation

final class BedtimeController {
  private let settings: AppSettings
  private let windows: WindowCoordinator
  private let onStateChanged: (Bool) -> Void
  private let calendar = Calendar.current
  private let tickInterval: TimeInterval = 5

  private var timer: Timer?
  private var activeIntervalToken: String?
  private var lockDeadline: Date?
  private var lockTriggered = false
  private var blocking = false
  private var firedWarningKeys = Set<String>()

  var isBlocking: Bool {
    blocking
  }

  var canUseEmergencyExit: Bool {
    guard let token = activeIntervalToken ?? bedtimeInterval(containing: Date())?.token else {
      return false
    }
    return !settings.hasUsedBedtimeEmergency(intervalToken: token)
  }

  init(settings: AppSettings, windows: WindowCoordinator, onStateChanged: @escaping (Bool) -> Void) {
    self.settings = settings
    self.windows = windows
    self.onStateChanged = onStateChanged
  }

  func start() {
    timer?.invalidate()
    timer = makeTimer(interval: tickInterval, repeats: true) { [weak self] _ in
      self?.tick()
    }
    tick()
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    endBlocking()
    windows.hideBedtimeReminder()
  }

  func applySettings() {
    activeIntervalToken = nil
    lockDeadline = nil
    lockTriggered = false
    if !settings.bedtimeEnabled {
      endBlocking()
      windows.hideBedtimeReminder()
    }
    tick()
  }

  func emergencyExitFromMenu() {
    emergencyExit()
  }

  private func tick() {
    guard settings.bedtimeEnabled else {
      if blocking {
        endBlocking()
      }
      return
    }

    let now = Date()
    if let interval = bedtimeInterval(containing: now) {
      handleBedtimeWindow(now: now, interval: interval)
    } else {
      if blocking {
        endBlocking()
      }
      handleWarnings(now: now)
    }
  }

  private func handleBedtimeWindow(now: Date, interval: BedtimeInterval) {
    if settings.hasUsedBedtimeEmergency(intervalToken: interval.token) {
      if blocking {
        endBlocking()
      }
      return
    }

    if activeIntervalToken != interval.token || !blocking {
      beginBlocking(now: now, intervalToken: interval.token)
    }

    let remaining: Int?
    if lockTriggered {
      remaining = nil
    } else if let lockDeadline {
      remaining = max(0, Int(ceil(lockDeadline.timeIntervalSince(now))))
    } else {
      remaining = settings.bedtimeOverlayMinutes * 60
    }

    windows.showBedtimeOverlay(
      lockRemainingSeconds: remaining,
      emergencyAvailable: canUseEmergencyExit,
      onEmergencyExit: { [weak self] in
        self?.emergencyExit()
      }
    )

    if !lockTriggered, let lockDeadline, now >= lockDeadline {
      lockTriggered = true
      windows.updateBedtimeOverlay(lockRemainingSeconds: nil, emergencyAvailable: canUseEmergencyExit)
      lockScreenAndSleepDisplay()
    }
  }

  private func beginBlocking(now: Date, intervalToken: String) {
    activeIntervalToken = intervalToken
    lockDeadline = now.addingTimeInterval(TimeInterval(settings.bedtimeOverlayMinutes * 60))
    lockTriggered = false
    blocking = true
    onStateChanged(true)
  }

  private func endBlocking() {
    activeIntervalToken = nil
    lockDeadline = nil
    lockTriggered = false
    if blocking {
      blocking = false
      onStateChanged(false)
    }
    windows.hideBedtimeOverlay()
  }

  private func emergencyExit() {
    guard let token = activeIntervalToken ?? bedtimeInterval(containing: Date())?.token else {
      windows.showBedtimeReminder(message: text(.bedtimeInactive), duration: 6)
      return
    }

    guard !settings.hasUsedBedtimeEmergency(intervalToken: token) else {
      windows.showBedtimeReminder(message: text(.emergencyAlreadyUsed), duration: 6)
      return
    }

    settings.markBedtimeEmergencyUsed(intervalToken: token)
    endBlocking()
    windows.showBedtimeReminder(message: text(.emergencyUsed), duration: 8)
  }

  private func handleWarnings(now: Date) {
    let nextStart = nextBedtimeStart(after: now)
    let token = token(for: nextStart)
    let warnings: [(minutes: Int, key: L10nKey)] = [
      (60, .bedtimeWarning60),
      (30, .bedtimeWarning30),
      (5, .bedtimeWarning5)
    ]

    for warning in warnings {
      let fireAt = nextStart.addingTimeInterval(TimeInterval(-warning.minutes * 60))
      let delta = now.timeIntervalSince(fireAt)
      let key = "\(token)-\(warning.minutes)"
      if delta >= 0, delta < tickInterval + 1, !firedWarningKeys.contains(key) {
        firedWarningKeys.insert(key)
        windows.showBedtimeReminder(message: text(warning.key), duration: 30)
      }
    }
  }

  private func lockScreenAndSleepDisplay() {
    SystemSleepController.lockAndSleepDisplay(settings: settings, windows: windows)
  }

  private func text(_ key: L10nKey) -> String {
    L10n.text(key, language: settings.language)
  }

  private func makeTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
    let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
    RunLoop.main.add(timer, forMode: .common)
    return timer
  }

  private struct BedtimeInterval {
    let start: Date
    let end: Date
    let token: String
  }

  private func bedtimeInterval(containing date: Date) -> BedtimeInterval? {
    let startMinutes = settings.bedtimeStartMinutes
    let endMinutes = settings.bedtimeEndMinutes

    if startMinutes == endMinutes {
      return nil
    }

    if startMinutes < endMinutes {
      let start = dateOnSameDay(as: date, minutesAfterMidnight: startMinutes)
      let end = dateOnSameDay(as: date, minutesAfterMidnight: endMinutes)
      guard date >= start, date < end else { return nil }
      return BedtimeInterval(start: start, end: end, token: token(for: start))
    }

    let todayStart = dateOnSameDay(as: date, minutesAfterMidnight: startMinutes)
    let todayEnd = dateOnSameDay(as: date, minutesAfterMidnight: endMinutes)

    if date >= todayStart {
      let end = calendar.date(byAdding: .day, value: 1, to: todayEnd) ?? todayEnd.addingTimeInterval(24 * 60 * 60)
      return BedtimeInterval(start: todayStart, end: end, token: token(for: todayStart))
    }

    if date < todayEnd {
      let start = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart.addingTimeInterval(-24 * 60 * 60)
      return BedtimeInterval(start: start, end: todayEnd, token: token(for: start))
    }

    return nil
  }

  private func nextBedtimeStart(after date: Date) -> Date {
    let todayStart = dateOnSameDay(as: date, minutesAfterMidnight: settings.bedtimeStartMinutes)
    if todayStart > date {
      return todayStart
    }
    return calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart.addingTimeInterval(24 * 60 * 60)
  }

  private func dateOnSameDay(as date: Date, minutesAfterMidnight: Int) -> Date {
    var components = calendar.dateComponents([.year, .month, .day], from: date)
    components.hour = minutesAfterMidnight / 60
    components.minute = minutesAfterMidnight % 60
    components.second = 0
    return calendar.date(from: components) ?? date
  }

  private func token(for start: Date) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: start)
    return String(
      format: "%04d-%02d-%02d-%04d-%04d",
      components.year ?? 0,
      components.month ?? 0,
      components.day ?? 0,
      settings.bedtimeStartMinutes,
      settings.bedtimeEndMinutes
    )
  }
}
