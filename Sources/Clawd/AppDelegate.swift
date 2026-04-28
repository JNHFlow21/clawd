import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let settings = AppSettings.shared
  private lazy var windows = WindowCoordinator(settings: settings)
  private lazy var remindersManager = RemindersManager(settings: settings)
  private lazy var timerController = TimerController(settings: settings, windows: windows) { [weak self] snapshot in
    self?.render(snapshot: snapshot)
  }
  private lazy var bedtimeController = BedtimeController(settings: settings, windows: windows) { [weak self] isBlocking in
    guard let self else { return }
    if isBlocking {
      self.timerController.suspendForBedtime()
    } else {
      self.timerController.resumeFromBedtime()
    }
    self.render(snapshot: self.latestSnapshot)
    self.rebuildMenu()
  }

  private var statusItem: NSStatusItem?
  private var settingsWindowController: SettingsWindowController?
  private var latestSnapshot = TimerSnapshot(mode: .disabled, remainingSeconds: 0)

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    installStatusItem()
    windows.onRemindersCollapsedChanged = { [weak self] _ in
      self?.rebuildMenu()
    }
    SystemSleepController.prepareForBedtime(settings: settings, windows: windows)
    remindersManager.onSnapshot = { [weak self] snapshot in
      self?.windows.updateReminders(snapshot)
    }
    remindersManager.start()
    DispatchQueue.main.async { [weak self] in
      self?.timerController.start()
      self?.bedtimeController.start()
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    remindersManager.stop()
    bedtimeController.stop()
    windows.hideAll()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.title = "Clawd"
    statusItem = item
    rebuildMenu()
  }

  private func rebuildMenu() {
    let menu = NSMenu()
    let language = settings.language

    let enabledTitle = settings.enabled ? L10n.text(.disableClawd, language: language) : L10n.text(.enableClawd, language: language)
    menu.addItem(NSMenuItem(title: enabledTitle, action: #selector(toggleEnabled), keyEquivalent: ""))
    let remindersTitle = settings.remindersCollapsed ? L10n.text(.showReminders, language: language) : L10n.text(.hideReminders, language: language)
    menu.addItem(NSMenuItem(title: remindersTitle, action: #selector(toggleReminders), keyEquivalent: ""))
    let startWorkItem = NSMenuItem(title: L10n.text(.startWork, language: language), action: #selector(startWorkMode), keyEquivalent: "w")
    startWorkItem.isEnabled = settings.enabled && !bedtimeController.isBlocking
    menu.addItem(startWorkItem)
    let restModeItem = NSMenuItem(title: L10n.text(.restMode, language: language), action: #selector(restMode), keyEquivalent: "")
    restModeItem.isEnabled = settings.enabled && !bedtimeController.isBlocking
    menu.addItem(restModeItem)
    let startBreakItem = NSMenuItem(title: L10n.text(.startBreakNow, language: language), action: #selector(startBreakNow), keyEquivalent: "b")
    startBreakItem.isEnabled = settings.enabled && !bedtimeController.isBlocking
    menu.addItem(startBreakItem)
    let emergencyItem = NSMenuItem(title: L10n.text(.emergencyExitBedtime, language: language), action: #selector(emergencyExitBedtime), keyEquivalent: "")
    emergencyItem.isEnabled = bedtimeController.isBlocking && bedtimeController.canUseEmergencyExit
    menu.addItem(emergencyItem)
    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: L10n.text(.settings, language: language), action: #selector(openSettings), keyEquivalent: ","))
    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: L10n.text(.quitClawd, language: language), action: #selector(quit), keyEquivalent: "q"))

    for item in menu.items {
      item.target = self
    }

    statusItem?.menu = menu
  }

  private func render(snapshot: TimerSnapshot) {
    latestSnapshot = snapshot
    statusItem?.button?.title = title(for: snapshot)
  }

  private func title(for snapshot: TimerSnapshot) -> String {
    let language = settings.language
    if bedtimeController.isBlocking {
      return L10n.text(.sleepMode, language: language)
    }

    switch snapshot.mode {
    case .disabled:
      return L10n.text(.clawdOff, language: language)
    case .idle:
      return L10n.text(.restMode, language: language)
    case .work:
      return "Clawd \(formatDuration(snapshot.remainingSeconds))"
    case .warning:
      return "Clawd ! \(formatDuration(snapshot.remainingSeconds))"
    case .rest:
      return "\(L10n.text(.rest, language: language)) \(formatDuration(snapshot.remainingSeconds))"
    }
  }

  @objc private func toggleEnabled() {
    timerController.setEnabled(!settings.enabled)
    rebuildMenu()
  }

  @objc private func toggleReminders() {
    windows.toggleRemindersCollapsed()
    rebuildMenu()
  }

  @objc private func startBreakNow() {
    if !settings.enabled {
      settings.enabled = true
      rebuildMenu()
    }
    timerController.startBreakNow()
  }

  @objc private func startWorkMode() {
    if !settings.enabled {
      settings.enabled = true
      rebuildMenu()
    }
    timerController.startWorkMode()
  }

  @objc private func restMode() {
    if !settings.enabled {
      settings.enabled = true
      rebuildMenu()
    }
    timerController.enterRestMode()
  }

  @objc private func resetWorkTimer() {
    if !settings.enabled {
      settings.enabled = true
      rebuildMenu()
    }
    timerController.resetWorkTimer()
  }

  @objc private func openSettings() {
    if settingsWindowController == nil {
      settingsWindowController = SettingsWindowController(
          settings: settings,
          onSave: { [weak self] in
            self?.timerController.applySettingsAndRestart()
            self?.windows.applySettings()
            self?.bedtimeController.applySettings()
            self?.remindersManager.refreshNow()
            self?.rebuildMenu()
          },
        onStartWork: { [weak self] in
          self?.startWorkMode()
        },
        onRestMode: { [weak self] in
          self?.restMode()
        }
      )
    }
    settingsWindowController?.showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  @objc private func emergencyExitBedtime() {
    bedtimeController.emergencyExitFromMenu()
    rebuildMenu()
  }
}
