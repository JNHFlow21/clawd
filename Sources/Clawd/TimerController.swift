import Foundation

enum TimerMode {
  case disabled
  case idle
  case work
  case warning
  case rest
}

struct TimerSnapshot {
  let mode: TimerMode
  let remainingSeconds: Int
}

final class TimerController {
  private let settings: AppSettings
  private let windows: WindowCoordinator
  private let onSnapshot: (TimerSnapshot) -> Void

  private var tickTimer: Timer?
  private var rotationTimer: Timer?
  private var introTimer: Timer?
  private var workStartedAt = Date()
  private var breakStartedAt = Date()
  private var breakEndsAt = Date()
  private var breakActive = false
  private var warningActive = false
  private var workModeActive = false
  private var bedtimeSuspended = false
  private var workAnimationStarted = false
  private var lastAnimationName = ""
  private var lastEdge: ScreenEdge?

  init(settings: AppSettings, windows: WindowCoordinator, onSnapshot: @escaping (TimerSnapshot) -> Void) {
    self.settings = settings
    self.windows = windows
    self.onSnapshot = onSnapshot
  }

  func start() {
    tickTimer?.invalidate()
    tickTimer = makeTimer(interval: 1, repeats: true) { [weak self] _ in
      self?.tick()
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if self.settings.enabled {
        self.enterRestMode()
      } else {
        self.disable()
      }
    }
  }

  func setEnabled(_ enabled: Bool) {
    settings.enabled = enabled
    if enabled {
      enterRestMode()
    } else {
      disable()
    }
  }

  func startWorkMode() {
    settings.enabled = true
    bedtimeSuspended = false
    workModeActive = true
    startWorkCycle(resetStart: true)
  }

  func resetWorkTimer() {
    startWorkMode()
  }

  func enterRestMode() {
    settings.enabled = true
    bedtimeSuspended = false
    workModeActive = false
    enterIdleMode(showPet: true)
  }

  func suspendForBedtime() {
    bedtimeSuspended = true
    workModeActive = false
    enterIdleMode(showPet: false)
  }

  func resumeFromBedtime() {
    bedtimeSuspended = false
    if settings.enabled {
      enterIdleMode(showPet: true)
    } else {
      disable()
    }
  }

  func startBreakNow() {
    settings.enabled = true
    bedtimeSuspended = false
    workModeActive = false
    startBreak()
  }

  func applySettingsAndRestart() {
    if !settings.enabled {
      disable()
    } else if bedtimeSuspended {
      enterIdleMode(showPet: false)
    } else if workModeActive {
      startWorkCycle(resetStart: true)
    } else {
      enterIdleMode(showPet: true)
    }
  }

  private func disable() {
    clearRotationTimer()
    introTimer?.invalidate()
    introTimer = nil
    breakActive = false
    warningActive = false
    workModeActive = false
    bedtimeSuspended = false
    workAnimationStarted = false
    windows.hideAll()
    onSnapshot(TimerSnapshot(mode: .disabled, remainingSeconds: 0))
  }

  private func tick() {
    if bedtimeSuspended {
      onSnapshot(TimerSnapshot(mode: .idle, remainingSeconds: 0))
      return
    }

    guard settings.enabled else {
      disable()
      return
    }

    guard workModeActive || breakActive else {
      ensureIdleAnimationRunning()
      onSnapshot(TimerSnapshot(mode: .idle, remainingSeconds: 0))
      return
    }

    if breakActive {
      tickBreak()
    } else {
      tickWork()
    }
  }

  private func tickWork() {
    let remaining = workRemainingSeconds()
    windows.updateWorkTimer(remainingSeconds: remaining)

    guard remaining > 0 else {
      startBreak()
      return
    }

    if remaining <= warningWindowSeconds() {
      showWarningIfNeeded()
      onSnapshot(TimerSnapshot(mode: .warning, remainingSeconds: remaining))
      return
    }

    if warningActive {
      warningActive = false
    }

    ensureWorkAnimationRunning()
    onSnapshot(TimerSnapshot(mode: .work, remainingSeconds: remaining))
  }

  private func tickBreak() {
    let remaining = max(0, Int(ceil(breakEndsAt.timeIntervalSinceNow)))
    guard remaining > 0 else {
      enterIdleMode(showPet: true)
      return
    }

    windows.updateBreakTimer(remainingSeconds: remaining)
    onSnapshot(TimerSnapshot(mode: .rest, remainingSeconds: remaining))
  }

  private func startWorkCycle(resetStart: Bool) {
    clearRotationTimer()
    introTimer?.invalidate()
    introTimer = nil
    workModeActive = true
    breakActive = false
    warningActive = false
    workAnimationStarted = false
    if resetStart {
      workStartedAt = Date()
    }
    windows.hideBreakOverlay()
    ensureWorkAnimationRunning()
    tickWork()
  }

  private func startBreak() {
    clearRotationTimer()
    introTimer?.invalidate()
    workModeActive = false
    breakActive = true
    warningActive = false
    workAnimationStarted = false
    breakStartedAt = Date()
    breakEndsAt = breakStartedAt.addingTimeInterval(TimeInterval(settings.breakMinutes * 60))

    let remaining = max(1, Int(ceil(breakEndsAt.timeIntervalSinceNow)))
    windows.showBreakOverlay(animationName: AnimationCatalog.throwAnimation, remainingSeconds: remaining)
    onSnapshot(TimerSnapshot(mode: .rest, remainingSeconds: remaining))

    introTimer = makeTimer(interval: settings.breakIntroSeconds, repeats: false) { [weak self] _ in
      self?.windows.switchBreakAnimation(to: AnimationCatalog.breakAnimation)
    }
  }

  private func enterIdleMode(showPet: Bool) {
    clearRotationTimer()
    introTimer?.invalidate()
    introTimer = nil
    breakActive = false
    warningActive = false
    workAnimationStarted = false
    windows.hideBreakOverlay()
    windows.hideWorkTimer()

    if showPet {
      ensureIdleAnimationRunning()
      windows.showReminderBoard()
    } else {
      windows.hideWorkUI()
    }

    onSnapshot(TimerSnapshot(mode: .idle, remainingSeconds: 0))
  }

  private func ensureIdleAnimationRunning() {
    if !workAnimationStarted {
      showInitialWorkAnimation()
      scheduleNextIdleRotation()
      return
    }

    windows.showReminderBoard()

    if rotationTimer == nil {
      scheduleNextIdleRotation()
    }
  }

  private func ensureWorkAnimationRunning() {
    if !workAnimationStarted {
      showInitialWorkAnimation()
      scheduleNextWorkRotation()
      return
    }

    if rotationTimer == nil {
      scheduleNextWorkRotation()
    }
  }

  private func showWarningIfNeeded() {
    guard !warningActive else { return }
    clearRotationTimer()
    warningActive = true
    windows.showWarningCompanion()
  }

  private func rotateWorkAnimation() {
    let animationName = randomWorkAnimation()
    let edge = randomEdge()
    workAnimationStarted = true
    windows.showWorkCompanion(animationName: animationName, edge: edge)
  }

  private func showInitialWorkAnimation() {
    let animationName = AnimationCatalog.workAnimations.first ?? randomWorkAnimation()
    lastAnimationName = animationName
    lastEdge = .bottomRight
    workAnimationStarted = true
    windows.showWorkCompanion(animationName: animationName, edge: .bottomRight)
  }

  private func scheduleNextWorkRotation() {
    clearRotationTimer()

    let secondsUntilWarning = workRemainingSeconds() - warningWindowSeconds()
    guard secondsUntilWarning > 1 else { return }

    let randomDelay = Int.random(in: settings.minWorkAnimationSeconds...settings.maxWorkAnimationSeconds)
    let delay = min(randomDelay, max(1, secondsUntilWarning - 1))

    rotationTimer = makeTimer(interval: TimeInterval(delay), repeats: false) { [weak self] _ in
      guard let self else { return }
      self.rotationTimer = nil
      guard self.settings.enabled, self.workModeActive, !self.bedtimeSuspended, !self.breakActive, !self.warningActive else { return }
      if self.workRemainingSeconds() <= self.warningWindowSeconds() {
        self.showWarningIfNeeded()
        return
      }
      self.rotateWorkAnimation()
      self.scheduleNextWorkRotation()
    }
  }

  private func scheduleNextIdleRotation() {
    clearRotationTimer()
    let delay = Int.random(in: settings.minWorkAnimationSeconds...settings.maxWorkAnimationSeconds)
    rotationTimer = makeTimer(interval: TimeInterval(delay), repeats: false) { [weak self] _ in
      guard let self else { return }
      self.rotationTimer = nil
      guard self.settings.enabled, !self.workModeActive, !self.bedtimeSuspended, !self.breakActive else { return }
      self.rotateWorkAnimation()
      self.scheduleNextIdleRotation()
    }
  }

  private func clearRotationTimer() {
    rotationTimer?.invalidate()
    rotationTimer = nil
  }

  private func makeTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
    let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
    RunLoop.main.add(timer, forMode: .common)
    return timer
  }

  private func workRemainingSeconds() -> Int {
    let duration = TimeInterval(settings.workMinutes * 60)
    let endAt = workStartedAt.addingTimeInterval(duration)
    return max(0, Int(ceil(endAt.timeIntervalSinceNow)))
  }

  private func warningWindowSeconds() -> Int {
    min(max(1, settings.warningSeconds), max(1, settings.workMinutes * 60))
  }

  private func randomWorkAnimation() -> String {
    lastAnimationName = randomDifferentItem(from: AnimationCatalog.workAnimations, previous: lastAnimationName)
    return lastAnimationName
  }

  private func randomEdge() -> ScreenEdge {
    let next = randomDifferentItem(from: ScreenEdge.allCases, previous: lastEdge)
    lastEdge = next
    return next
  }

  private func randomDifferentItem<T: Equatable>(from items: [T], previous: T?) -> T {
    precondition(!items.isEmpty)
    guard items.count > 1 else { return items[0] }

    var candidate = previous ?? items.randomElement()!
    for _ in 0..<6 where candidate == previous {
      candidate = items.randomElement()!
    }
    if candidate == previous {
      return items.first { $0 != previous } ?? items[0]
    }
    return candidate
  }
}
