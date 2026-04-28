import Foundation

final class AppSettings {
  static let shared = AppSettings()

  private enum Key: String {
    case enabled
    case workMinutes
    case breakMinutes
    case companionSize
    case remindersCollapsed
    case bedtimeEnabled
    case bedtimeStartMinutes
    case bedtimeEndMinutes
    case bedtimeOverlayMinutes
    case bedtimeEmergencyIntervalToken
    case language
  }

  private let defaults: UserDefaults

  private init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    defaults.register(defaults: [
      Key.enabled.rawValue: true,
      Key.workMinutes.rawValue: 30,
      Key.breakMinutes.rawValue: 3,
      Key.companionSize.rawValue: 150.0,
      Key.remindersCollapsed.rawValue: false,
      Key.bedtimeEnabled.rawValue: true,
      Key.bedtimeStartMinutes.rawValue: 22 * 60 + 30,
      Key.bedtimeEndMinutes.rawValue: 5 * 60,
      Key.bedtimeOverlayMinutes.rawValue: 15,
      Key.bedtimeEmergencyIntervalToken.rawValue: "",
      Key.language.rawValue: AppLanguage.english.rawValue
    ])
  }

  var enabled: Bool {
    get { defaults.object(forKey: Key.enabled.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.enabled.rawValue) }
  }

  var workMinutes: Int {
    get { clamp(defaults.integer(forKey: Key.workMinutes.rawValue), min: 1, max: 240, fallback: 30) }
    set { defaults.set(clamp(newValue, min: 1, max: 240, fallback: 30), forKey: Key.workMinutes.rawValue) }
  }

  var breakMinutes: Int {
    get { clamp(defaults.integer(forKey: Key.breakMinutes.rawValue), min: 1, max: 60, fallback: 3) }
    set { defaults.set(clamp(newValue, min: 1, max: 60, fallback: 3), forKey: Key.breakMinutes.rawValue) }
  }

  var companionSize: Double {
    get {
      let value = defaults.double(forKey: Key.companionSize.rawValue)
      return value > 0 ? min(max(value, 96), 260) : 150
    }
    set {
      defaults.set(min(max(newValue, 96), 260), forKey: Key.companionSize.rawValue)
    }
  }

  var remindersCollapsed: Bool {
    get { defaults.object(forKey: Key.remindersCollapsed.rawValue) as? Bool ?? false }
    set { defaults.set(newValue, forKey: Key.remindersCollapsed.rawValue) }
  }

  var bedtimeEnabled: Bool {
    get { defaults.object(forKey: Key.bedtimeEnabled.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.bedtimeEnabled.rawValue) }
  }

  var bedtimeStartMinutes: Int {
    get { clampMinuteOfDay(defaults.integer(forKey: Key.bedtimeStartMinutes.rawValue), fallback: 22 * 60 + 30) }
    set { defaults.set(clampMinuteOfDay(newValue, fallback: 22 * 60 + 30), forKey: Key.bedtimeStartMinutes.rawValue) }
  }

  var bedtimeEndMinutes: Int {
    get { clampMinuteOfDay(defaults.integer(forKey: Key.bedtimeEndMinutes.rawValue), fallback: 5 * 60) }
    set { defaults.set(clampMinuteOfDay(newValue, fallback: 5 * 60), forKey: Key.bedtimeEndMinutes.rawValue) }
  }

  var bedtimeOverlayMinutes: Int {
    get { clamp(defaults.integer(forKey: Key.bedtimeOverlayMinutes.rawValue), min: 1, max: 120, fallback: 15) }
    set { defaults.set(clamp(newValue, min: 1, max: 120, fallback: 15), forKey: Key.bedtimeOverlayMinutes.rawValue) }
  }

  func hasUsedBedtimeEmergency(intervalToken: String) -> Bool {
    defaults.string(forKey: Key.bedtimeEmergencyIntervalToken.rawValue) == intervalToken
  }

  func markBedtimeEmergencyUsed(intervalToken: String) {
    defaults.set(intervalToken, forKey: Key.bedtimeEmergencyIntervalToken.rawValue)
  }

  var language: AppLanguage {
    get {
      let rawValue = defaults.string(forKey: Key.language.rawValue) ?? AppLanguage.english.rawValue
      return AppLanguage(rawValue: rawValue) ?? .english
    }
    set {
      defaults.set(newValue.rawValue, forKey: Key.language.rawValue)
    }
  }

  var warningSeconds: Int { 10 }
  var minWorkAnimationSeconds: Int { 12 }
  var maxWorkAnimationSeconds: Int { 20 }
  var breakIntroSeconds: TimeInterval { 2.8 }

  private func clamp(_ value: Int, min: Int, max: Int, fallback: Int) -> Int {
    guard value > 0 else { return fallback }
    return Swift.min(Swift.max(value, min), max)
  }

  private func clampMinuteOfDay(_ value: Int, fallback: Int) -> Int {
    guard value >= 0 else { return fallback }
    return Swift.min(Swift.max(value, 0), 23 * 60 + 59)
  }
}
