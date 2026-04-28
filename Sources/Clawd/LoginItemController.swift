import Foundation
import ServiceManagement

enum LoginItemController {
  static var isSupported: Bool {
    if #available(macOS 13.0, *) {
      return true
    }
    return false
  }

  static var statusText: String {
    statusText(language: .english)
  }

  static func statusText(language: AppLanguage) -> String {
    if #available(macOS 13.0, *) {
      switch SMAppService.mainApp.status {
      case .enabled:
        return L10n.text(.launchAtLoginOn, language: language)
      case .requiresApproval:
        return L10n.text(.launchAtLoginNeedsApproval, language: language)
      case .notRegistered:
        return L10n.text(.launchAtLoginOff, language: language)
      case .notFound:
        return L10n.text(.launchAtLoginNotAvailable, language: language)
      @unknown default:
        return L10n.text(.launchAtLoginUnknown, language: language)
      }
    }
    return L10n.text(.launchAtLoginUnsupported, language: language)
  }

  static func toggle() throws {
    guard #available(macOS 13.0, *) else { return }
    switch SMAppService.mainApp.status {
    case .enabled, .requiresApproval:
      try SMAppService.mainApp.unregister()
    default:
      try SMAppService.mainApp.register()
    }
  }
}
