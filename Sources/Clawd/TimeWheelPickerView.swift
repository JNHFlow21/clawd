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
    addSubview(hourStepper)
    addSubview(minuteStepper)
    updateLabels()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    hourLabel.frame = NSRect(x: 8, y: 3, width: 32, height: 24)
    colonLabel.frame = NSRect(x: 41, y: 3, width: 10, height: 24)
    minuteLabel.frame = NSRect(x: 52, y: 3, width: 32, height: 24)
    hourStepper.frame = NSRect(x: 88, y: 1, width: 19, height: 27)
    minuteStepper.frame = NSRect(x: 112, y: 1, width: 19, height: 27)
  }

  override func scrollWheel(with event: NSEvent) {
    if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
      adjustHour(event.scrollingDeltaX < 0 ? 1 : -1)
    } else {
      adjustMinute(event.scrollingDeltaY < 0 ? 1 : -1)
    }
  }

  private func configureLabel(_ label: NSTextField) {
    label.alignment = .center
    label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .heavy)
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
    stepper.target = self
    stepper.action = #selector(stepperChanged(_:))
  }

  @objc private func stepperChanged(_ sender: NSStepper) {
    updateLabels()
  }

  private func adjustHour(_ delta: Int) {
    var value = hourStepper.integerValue + delta
    if value < 0 { value = 23 }
    if value > 23 { value = 0 }
    hourStepper.integerValue = value
    updateLabels()
  }

  private func adjustMinute(_ delta: Int) {
    var value = minuteStepper.integerValue + delta
    if value < 0 { value = 59 }
    if value > 59 { value = 0 }
    minuteStepper.integerValue = value
    updateLabels()
  }

  private func updateLabels() {
    hourLabel.stringValue = String(format: "%02d", hourStepper.integerValue)
    minuteLabel.stringValue = String(format: "%02d", minuteStepper.integerValue)
  }
}
