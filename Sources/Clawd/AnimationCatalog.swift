import Foundation

enum AnimationCatalog {
  static let workAnimations = [
    "clawd-coffee.html",
    "clawd-keyboard.html",
    "clawd-reading.html",
    "clawd-stretch.html",
    "clawd-meditation.html",
    "clawd-tidy-desk.html",
    "clawd-cheer-sign.html",
    "clawd-fitness.html",
    "clawd-sleep.html",
    "clawd-running.html",
    "clawd-swimming.html",
    "clawd-daydream.html"
  ]

  static let warningAnimation = "clawd-alarm-ready.html"
  static let throwAnimation = "clawd-alarm-throw.html"
  static let breakAnimation = "clawd-alarm-break.html"
  static let bedtimeAnimation = "clawd-bedtime.html"
}

enum ScreenEdge: CaseIterable {
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
}

func formatDuration(_ totalSeconds: Int) -> String {
  let safeSeconds = max(0, totalSeconds)
  let minutes = safeSeconds / 60
  let seconds = safeSeconds % 60
  return String(format: "%d:%02d", minutes, seconds)
}
