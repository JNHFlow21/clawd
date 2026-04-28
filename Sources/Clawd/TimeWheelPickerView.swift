import AppKit

final class TimeWheelPickerView: NSView {
  private let hourLabel = NSTextField(labelWithString: "00")
  private let minuteLabel = NSTextField(labelWithString: "00")
  private let colonLabel = NSTextField(labelWithString: ":")
  private let hourStepper = NSStepper()
  private let minuteStepper = NSStepper()

  var minutesAfterMidnight: Int {
    get {
      Int(hourStepper.integerValue) * 60 + Int(minuteStepper.integerValue)
    }
    set {
      let safeValue = min(max(newValue, 0), 23 * 60 + 59)
      hourStepper.integerValue = safeValue / 60
      minuteStepper.integerValue = safeValue % 60
      updateLabels()
    }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor(calibratedRed: 0.12, green: 0.19, blue: 0.25, alpha: 1).cgColor
    layer?.cornerRadius = 0
    layer?.borderColor = NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.09, alpha: 1).cgColor
    layer?.borderWidth = 3

    configureLabel(hourLabel)
    configureLabel(minuteLabel)
    colonLabel.alignment = .center
    colonLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .heavy)
    colonLabel.textColor = .white

    configureStepper(hourStepper, max: 23)
    configureStepper(minuteStepper, max: 59)

    addSubview(hourLabel)
    addSubview(colonLabel)
    addSubview(minuteLabel)
    updateLabels()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    hourLabel.frame = NSRect(x: 8, y: 3, width: 48, height: 24)
    colonLabel.frame = NSRect(x: 58, y: 3, width: 18, height: 24)
    minuteLabel.frame = NSRect(x: 78, y: 3, width: 48, height: 24)
  }

  override func scrollWheel(with event: NSEvent) {
    let localPoint = convert(event.locationInWindow, from: nil)
    let rawDelta = abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX)
      ? event.scrollingDeltaY
      : -event.scrollingDeltaX
    let direction = rawDelta < 0 ? 1 : -1
    let ticks = min(6, max(1, Int(round(abs(rawDelta) / 6))))

    if localPoint.x < bounds.midX {
      adjustHour(direction * ticks)
    } else {
      let minuteStep = event.modifierFlags.contains(.shift) ? 15 : 5
      adjustMinute(direction * ticks * minuteStep)
    }
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  private func configureLabel(_ label: NSTextField) {
    label.alignment = .center
    label.font = .monospacedDigitSystemFont(ofSize: 20, weight: .heavy)
    label.textColor = .white
    label.wantsLayer = true
    label.layer?.backgroundColor = NSColor.clear.cgColor
    label.layer?.cornerRadius = 0
  }

  private func configureStepper(_ stepper: NSStepper, max: Double) {
    stepper.minValue = 0
    stepper.maxValue = max
    stepper.increment = 1
    stepper.valueWraps = true
    stepper.isHidden = true
    stepper.target = self
    stepper.action = #selector(stepperChanged(_:))
  }

  @objc private func stepperChanged(_ sender: NSStepper) {
    updateLabels()
  }

  private func adjustHour(_ delta: Int) {
    var value = (hourStepper.integerValue + delta) % 24
    if value < 0 { value += 24 }
    hourStepper.integerValue = value
    updateLabels()
  }

  private func adjustMinute(_ delta: Int) {
    var value = (minuteStepper.integerValue + delta) % 60
    if value < 0 { value += 60 }
    minuteStepper.integerValue = value
    updateLabels()
  }

  private func updateLabels() {
    hourLabel.stringValue = String(format: "%02d", hourStepper.integerValue)
    minuteLabel.stringValue = String(format: "%02d", minuteStepper.integerValue)
  }
}
