import AppKit

final class SettingsWindowController: NSWindowController {
  private let settings: AppSettings
  private let onSave: () -> Void
  private let onStartWork: () -> Void
  private let onRestMode: () -> Void

  private let titleLabel = NSTextField(labelWithString: "")
  private let subtitleLabel = NSTextField(labelWithString: "")
  private let enabledCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
  private let remindersCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
  private let bedtimeCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
  private let workLabel = NSTextField(labelWithString: "")
  private let breakLabel = NSTextField(labelWithString: "")
  private let sizeLabel = NSTextField(labelWithString: "")
  private let languageLabel = NSTextField(labelWithString: "")
  private let bedtimeTitleLabel = NSTextField(labelWithString: "")
  private let startTimeLabel = NSTextField(labelWithString: "")
  private let endTimeLabel = NSTextField(labelWithString: "")
  private let lockAfterLabel = NSTextField(labelWithString: "")
  private let workField = NSTextField()
  private let breakField = NSTextField()
  private let sizeField = NSTextField()
  private let bedtimeStartPicker = TimeWheelPickerView(frame: NSRect(x: 180, y: 0, width: 136, height: 30))
  private let bedtimeEndPicker = TimeWheelPickerView(frame: NSRect(x: 180, y: 0, width: 136, height: 30))
  private let bedtimeOverlayField = NSTextField()
  private let languagePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
  private let statusLabel = NSTextField(labelWithString: "")
  private let loginItemButton = NSButton(title: "", target: nil, action: nil)
  private let saveButton = NSButton(title: "", target: nil, action: nil)
  private let resetButton = NSButton(title: "", target: nil, action: nil)
  private let breakButton = NSButton(title: "", target: nil, action: nil)

  init(
    settings: AppSettings,
    onSave: @escaping () -> Void,
    onStartWork: @escaping () -> Void,
    onRestMode: @escaping () -> Void
  ) {
    self.settings = settings
    self.onSave = onSave
    self.onStartWork = onStartWork
    self.onRestMode = onRestMode

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 520, height: 600),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.isReleasedWhenClosed = false
    window.backgroundColor = NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.09, alpha: 1)
    let contentView = PixelSettingsBackgroundView(frame: NSRect(x: 0, y: 0, width: 520, height: 600))
    contentView.autoresizingMask = [.width, .height]
    window.contentView = contentView
    super.init(window: window)
    buildUI()
    loadValues()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func showWindow(_ sender: Any?) {
    loadValues()
    window?.center()
    super.showWindow(sender)
  }

  private func buildUI() {
    guard let contentView = window?.contentView else { return }

    titleLabel.frame = NSRect(x: 28, y: 546, width: 280, height: 28)
    titleLabel.font = .monospacedSystemFont(ofSize: 22, weight: .heavy)
    titleLabel.textColor = chromeInk
    contentView.addSubview(titleLabel)

    subtitleLabel.frame = NSRect(x: 28, y: 522, width: 460, height: 20)
    subtitleLabel.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
    subtitleLabel.textColor = chromeMuted
    contentView.addSubview(subtitleLabel)

    enabledCheckbox.frame = NSRect(x: 28, y: 486, width: 210, height: 24)
    styleCheckbox(enabledCheckbox)
    contentView.addSubview(enabledCheckbox)

    remindersCheckbox.frame = NSRect(x: 28, y: 456, width: 240, height: 24)
    styleCheckbox(remindersCheckbox)
    contentView.addSubview(remindersCheckbox)

    loginItemButton.target = self
    loginItemButton.action = #selector(loginItemClicked)
    loginItemButton.isEnabled = LoginItemController.isSupported
    loginItemButton.frame = NSRect(x: 292, y: 480, width: 200, height: 32)
    styleButton(loginItemButton)
    contentView.addSubview(loginItemButton)

    addNumericRow(label: workLabel, field: workField, y: 410, contentView: contentView)
    addNumericRow(label: breakLabel, field: breakField, y: 370, contentView: contentView)
    addNumericRow(label: sizeLabel, field: sizeField, y: 330, contentView: contentView)

    languageLabel.frame = NSRect(x: 28, y: 296, width: 142, height: 20)
    styleFormLabel(languageLabel)
    contentView.addSubview(languageLabel)
    languagePopUp.frame = NSRect(x: 180, y: 288, width: 136, height: 30)
    languagePopUp.target = self
    languagePopUp.action = #selector(languageChanged)
    languagePopUp.font = .monospacedSystemFont(ofSize: 13, weight: .bold)
    contentView.addSubview(languagePopUp)

    bedtimeTitleLabel.frame = NSRect(x: 28, y: 250, width: 180, height: 22)
    bedtimeTitleLabel.font = .monospacedSystemFont(ofSize: 16, weight: .heavy)
    bedtimeTitleLabel.textColor = chromeInk
    contentView.addSubview(bedtimeTitleLabel)

    bedtimeCheckbox.frame = NSRect(x: 28, y: 220, width: 230, height: 24)
    styleCheckbox(bedtimeCheckbox)
    contentView.addSubview(bedtimeCheckbox)

    addTimeRow(label: startTimeLabel, picker: bedtimeStartPicker, y: 180, contentView: contentView)
    addTimeRow(label: endTimeLabel, picker: bedtimeEndPicker, y: 140, contentView: contentView)
    addNumericRow(label: lockAfterLabel, field: bedtimeOverlayField, y: 100, contentView: contentView)

    saveButton.target = self
    saveButton.action = #selector(saveClicked)
    saveButton.frame = NSRect(x: 312, y: 32, width: 86, height: 32)
    saveButton.keyEquivalent = "\r"
    styleButton(saveButton)
    contentView.addSubview(saveButton)

    resetButton.target = self
    resetButton.action = #selector(resetClicked)
    resetButton.frame = NSRect(x: 28, y: 32, width: 112, height: 32)
    styleButton(resetButton)
    contentView.addSubview(resetButton)

    breakButton.target = self
    breakButton.action = #selector(startBreakClicked)
    breakButton.frame = NSRect(x: 152, y: 32, width: 112, height: 32)
    styleButton(breakButton)
    contentView.addSubview(breakButton)

    statusLabel.frame = NSRect(x: 410, y: 38, width: 82, height: 20)
    statusLabel.alignment = .right
    statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .heavy)
    statusLabel.textColor = NSColor(calibratedRed: 1.0, green: 0.89, blue: 0.48, alpha: 1)
    contentView.addSubview(statusLabel)
  }

  private func addNumericRow(label: NSTextField, field: NSTextField, y: CGFloat, contentView: NSView) {
    label.frame = NSRect(x: 28, y: y + 6, width: 142, height: 20)
    styleFormLabel(label)
    contentView.addSubview(label)

    field.frame = NSRect(x: 180, y: y, width: 90, height: 28)
    field.alignment = .right
    styleTextField(field)
    contentView.addSubview(field)
  }

  private func addTimeRow(label: NSTextField, picker: TimeWheelPickerView, y: CGFloat, contentView: NSView) {
    label.frame = NSRect(x: 28, y: y + 6, width: 142, height: 20)
    styleFormLabel(label)
    contentView.addSubview(label)

    picker.frame.origin = NSPoint(x: 180, y: y - 1)
    contentView.addSubview(picker)
  }

  private func loadValues() {
    rebuildLanguagePopUp(selected: settings.language)
    applyLanguage(settings.language)

    enabledCheckbox.state = settings.enabled ? .on : .off
    remindersCheckbox.state = settings.remindersCollapsed ? .off : .on
    bedtimeCheckbox.state = settings.bedtimeEnabled ? .on : .off
    workField.stringValue = String(settings.workMinutes)
    breakField.stringValue = String(settings.breakMinutes)
    sizeField.stringValue = String(Int(settings.companionSize))
    bedtimeStartPicker.minutesAfterMidnight = settings.bedtimeStartMinutes
    bedtimeEndPicker.minutesAfterMidnight = settings.bedtimeEndMinutes
    bedtimeOverlayField.stringValue = String(settings.bedtimeOverlayMinutes)
    loginItemButton.title = LoginItemController.statusText(language: settings.language)
  }

  private func rebuildLanguagePopUp(selected language: AppLanguage) {
    languagePopUp.removeAllItems()
    for item in AppLanguage.allCases {
      languagePopUp.addItem(withTitle: item.displayName)
    }
    if let index = AppLanguage.allCases.firstIndex(of: language) {
      languagePopUp.selectItem(at: index)
    }
  }

  private func applyLanguage(_ language: AppLanguage) {
    window?.title = L10n.text(.settings, language: language)
    titleLabel.stringValue = L10n.text(.settingsTitle, language: language)
    subtitleLabel.stringValue = L10n.text(.settingsSubtitle, language: language)
    enabledCheckbox.title = L10n.text(.enableClawd, language: language)
    remindersCheckbox.title = L10n.text(.showRemindersBoard, language: language)
    bedtimeCheckbox.title = L10n.text(.enableBedtimeGuard, language: language)
    workLabel.stringValue = L10n.text(.workMinutes, language: language)
    breakLabel.stringValue = L10n.text(.breakMinutes, language: language)
    sizeLabel.stringValue = L10n.text(.companionSize, language: language)
    languageLabel.stringValue = L10n.text(.language, language: language)
    bedtimeTitleLabel.stringValue = L10n.text(.bedtime, language: language)
    startTimeLabel.stringValue = L10n.text(.startTime, language: language)
    endTimeLabel.stringValue = L10n.text(.endTime, language: language)
    lockAfterLabel.stringValue = L10n.text(.lockAfterMinutes, language: language)
    saveButton.title = L10n.text(.save, language: language)
    resetButton.title = L10n.text(.startWork, language: language)
    breakButton.title = L10n.text(.restMode, language: language)
    loginItemButton.title = LoginItemController.statusText(language: language)
    styleCheckbox(enabledCheckbox)
    styleCheckbox(remindersCheckbox)
    styleCheckbox(bedtimeCheckbox)
    styleButton(saveButton)
    styleButton(resetButton)
    styleButton(breakButton)
    styleButton(loginItemButton)
  }

  @objc private func languageChanged() {
    applyLanguage(selectedLanguage)
  }

  @objc private func saveClicked() {
    settings.language = selectedLanguage
    settings.enabled = enabledCheckbox.state == .on
    settings.remindersCollapsed = remindersCheckbox.state != .on
    settings.bedtimeEnabled = bedtimeCheckbox.state == .on
    settings.workMinutes = intValue(from: workField, fallback: settings.workMinutes)
    settings.breakMinutes = intValue(from: breakField, fallback: settings.breakMinutes)
    settings.companionSize = Double(intValue(from: sizeField, fallback: Int(settings.companionSize)))
    settings.bedtimeStartMinutes = bedtimeStartPicker.minutesAfterMidnight
    settings.bedtimeEndMinutes = bedtimeEndPicker.minutesAfterMidnight
    settings.bedtimeOverlayMinutes = intValue(from: bedtimeOverlayField, fallback: settings.bedtimeOverlayMinutes)
    onSave()
    showStatus(.saved)
  }

  @objc private func resetClicked() {
    onStartWork()
    showStatus(.started)
  }

  @objc private func startBreakClicked() {
    onRestMode()
    showStatus(.started)
  }

  @objc private func loginItemClicked() {
    do {
      try LoginItemController.toggle()
      loginItemButton.title = LoginItemController.statusText(language: selectedLanguage)
      showStatus(.updated)
    } catch {
      showStatus(.failed)
    }
  }

  private var selectedLanguage: AppLanguage {
    let index = languagePopUp.indexOfSelectedItem
    guard AppLanguage.allCases.indices.contains(index) else {
      return settings.language
    }
    return AppLanguage.allCases[index]
  }

  private func intValue(from field: NSTextField, fallback: Int) -> Int {
    Int(field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? fallback
  }

  private func showStatus(_ key: L10nKey) {
    statusLabel.stringValue = L10n.text(key, language: selectedLanguage)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      self?.statusLabel.stringValue = ""
    }
  }

  private var chromeInk: NSColor {
    NSColor(calibratedRed: 0.15, green: 0.19, blue: 0.23, alpha: 1)
  }

  private var chromeMuted: NSColor {
    NSColor(calibratedRed: 0.36, green: 0.29, blue: 0.24, alpha: 1)
  }

  private var chromeButtonFill: NSColor {
    NSColor(calibratedRed: 0.12, green: 0.19, blue: 0.25, alpha: 1)
  }

  private var chromeAccent: NSColor {
    NSColor(calibratedRed: 1.0, green: 0.79, blue: 0.33, alpha: 1)
  }

  private func styleFormLabel(_ label: NSTextField) {
    label.font = .monospacedSystemFont(ofSize: 13, weight: .heavy)
    label.textColor = chromeInk
  }

  private func styleTextField(_ field: NSTextField) {
    field.font = .monospacedDigitSystemFont(ofSize: 14, weight: .heavy)
    field.textColor = .white
    field.backgroundColor = chromeButtonFill
    field.isBordered = false
    field.wantsLayer = true
    field.layer?.backgroundColor = chromeButtonFill.cgColor
    field.layer?.borderColor = NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.09, alpha: 1).cgColor
    field.layer?.borderWidth = 3
    field.layer?.cornerRadius = 0
  }

  private func styleCheckbox(_ checkbox: NSButton) {
    checkbox.font = .monospacedSystemFont(ofSize: 13, weight: .heavy)
    checkbox.contentTintColor = chromeInk
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .heavy),
      .foregroundColor: chromeInk
    ]
    checkbox.attributedTitle = NSAttributedString(string: checkbox.title, attributes: attributes)
  }

  private func styleButton(_ button: NSButton) {
    button.isBordered = false
    button.wantsLayer = true
    button.layer?.backgroundColor = chromeButtonFill.cgColor
    button.layer?.borderColor = NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.09, alpha: 1).cgColor
    button.layer?.borderWidth = 3
    button.layer?.cornerRadius = 0
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .heavy),
      .foregroundColor: button.isEnabled ? NSColor.white : NSColor.white.withAlphaComponent(0.45)
    ]
    button.attributedTitle = NSAttributedString(string: button.title, attributes: attributes)
  }
}
