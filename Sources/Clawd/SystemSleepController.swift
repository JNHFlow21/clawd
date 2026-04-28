import Foundation

enum SystemSleepController {
  private static let defaultsPath = "/usr/bin/defaults"
  private static let pmsetPath = "/usr/bin/pmset"
  private static let cgSessionPath = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"

  static func prepareForBedtime(settings: AppSettings, windows: WindowCoordinator) {
    DispatchQueue.global(qos: .utility).async {
      let canSleepDisplay = FileManager.default.isExecutableFile(atPath: pmsetPath)
      let passwordEnabled = runProcess(
        path: defaultsPath,
        arguments: ["write", "com.apple.screensaver", "askForPassword", "-int", "1"],
        timeout: 3
      )
      let delayEnabled = runProcess(
        path: defaultsPath,
        arguments: ["write", "com.apple.screensaver", "askForPasswordDelay", "-int", "0"],
        timeout: 3
      )

      DispatchQueue.main.async {
        if !canSleepDisplay || !passwordEnabled || !delayEnabled {
          windows.showBedtimeReminder(
            message: L10n.text(.sleepSetupFailed, language: settings.language),
            duration: 10
          )
        }
      }
    }
  }

  static func lockAndSleepDisplay(settings: AppSettings, windows: WindowCoordinator) {
    DispatchQueue.global(qos: .utility).async {
      if FileManager.default.isExecutableFile(atPath: cgSessionPath) {
        _ = runProcess(path: cgSessionPath, arguments: ["-suspend"], timeout: 3)
      }

      let slept = runProcess(path: pmsetPath, arguments: ["displaysleepnow"], timeout: 3)
      if !slept {
        DispatchQueue.main.async {
          windows.showBedtimeReminder(
            message: L10n.text(.displaySleepFailed, language: settings.language),
            duration: 10
          )
        }
      }
    }
  }

  private static func runProcess(path: String, arguments: [String], timeout: TimeInterval) -> Bool {
    guard FileManager.default.isExecutableFile(atPath: path) else {
      return false
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments

    let semaphore = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in
      semaphore.signal()
    }

    do {
      try process.run()
    } catch {
      return false
    }

    if semaphore.wait(timeout: .now() + timeout) == .timedOut {
      process.terminate()
      return false
    }

    return process.terminationStatus == 0
  }
}
