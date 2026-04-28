import Foundation

enum AppLanguage: String, CaseIterable {
  case english = "en"
  case chinese = "zh"

  var displayName: String {
    switch self {
    case .english:
      return "English"
    case .chinese:
      return "中文"
    }
  }
}

enum L10nKey: String {
  case enableClawd
  case disableClawd
  case showReminders
  case hideReminders
  case startWork
  case restMode
  case startBreakNow
  case resetWorkTimer
  case emergencyExitBedtime
  case settings
  case quitClawd
  case sleepMode
  case clawdOff
  case rest
  case settingsTitle
  case settingsSubtitle
  case showRemindersBoard
  case enableBedtimeGuard
  case workMinutes
  case breakMinutes
  case companionSize
  case language
  case bedtime
  case startTime
  case endTime
  case lockAfterMinutes
  case save
  case resetWork
  case startBreak
  case saved
  case reset
  case started
  case updated
  case failed
  case launchAtLoginOn
  case launchAtLoginNeedsApproval
  case launchAtLoginOff
  case launchAtLoginNotAvailable
  case launchAtLoginUnknown
  case launchAtLoginUnsupported
  case bedtimeInactive
  case emergencyAlreadyUsed
  case emergencyUsed
  case bedtimeWarning60
  case bedtimeWarning30
  case bedtimeWarning5
  case lockCommandMissing
  case lockFailed
  case sleepSetupFailed
  case displaySleepFailed
  case lockingIn
  case sleepModeUntilMorning
  case emergencyExit
  case emergencyUsedButton
  case breakMessage
  case remindersAccessNeeded
  case remindersUnavailable
  case noOpenReminders
  case openReminders
  case remindersTitle
  case grantRemindersAccessLine1
  case grantRemindersAccessLine2
  case grantRemindersAccessLine3
  case allClear
}

enum L10n {
  static func text(_ key: L10nKey, language: AppLanguage) -> String {
    switch language {
    case .english:
      return english[key] ?? key.rawValue
    case .chinese:
      return chinese[key] ?? english[key] ?? key.rawValue
    }
  }

  static func openReminders(_ count: Int, language: AppLanguage) -> String {
    switch language {
    case .english:
      return "\(count) open reminders"
    case .chinese:
      return "\(count) 条未完成提醒"
    }
  }

  private static let english: [L10nKey: String] = [
    .enableClawd: "Enable Clawd",
    .disableClawd: "Disable Clawd",
    .showReminders: "Show Reminders",
    .hideReminders: "Hide Reminders",
    .startWork: "Start Work",
    .restMode: "Rest Mode",
    .startBreakNow: "Start Break Now",
    .resetWorkTimer: "Reset Work Timer",
    .emergencyExitBedtime: "Emergency Exit Bedtime",
    .settings: "Settings...",
    .quitClawd: "Quit Clawd",
    .sleepMode: "Sleep Mode",
    .clawdOff: "Clawd Off",
    .rest: "Rest",
    .settingsTitle: "Clawd Gatekeeper",
    .settingsSubtitle: "A tiny work companion with reminders, breaks, and bedtime guard.",
    .showRemindersBoard: "Show reminders board",
    .enableBedtimeGuard: "Enable bedtime guard",
    .workMinutes: "Work minutes",
    .breakMinutes: "Break minutes",
    .companionSize: "Companion size",
    .language: "Language",
    .bedtime: "Bedtime",
    .startTime: "Start time",
    .endTime: "End time",
    .lockAfterMinutes: "Lock after minutes",
    .save: "Save",
    .resetWork: "Reset Work",
    .startBreak: "Start Break",
    .saved: "Saved",
    .reset: "Reset",
    .started: "Started",
    .updated: "Updated",
    .failed: "Failed",
    .launchAtLoginOn: "Launch at Login: On",
    .launchAtLoginNeedsApproval: "Launch at Login: Needs Approval",
    .launchAtLoginOff: "Launch at Login: Off",
    .launchAtLoginNotAvailable: "Launch at Login: Not Available",
    .launchAtLoginUnknown: "Launch at Login: Unknown",
    .launchAtLoginUnsupported: "Launch at Login: macOS 13+",
    .bedtimeInactive: "Bedtime guard is not active right now.",
    .emergencyAlreadyUsed: "Emergency exit has already been used for this bedtime window.",
    .emergencyUsed: "Emergency exit used. Bedtime guard will return tomorrow.",
    .bedtimeWarning60: "Bedtime starts in 1 hour. Wrap up work and prepare to wash up.",
    .bedtimeWarning30: "Bedtime starts in 30 minutes. Start closing your work.",
    .bedtimeWarning5: "Bedtime starts in 5 minutes. Clawd is preparing the bed.",
    .lockCommandMissing: "Could not find the macOS lock screen command.",
    .lockFailed: "Could not lock screen automatically.",
    .sleepSetupFailed: "Could not finish sleep setup. Check macOS lock screen settings.",
    .displaySleepFailed: "Could not put the display to sleep automatically.",
    .lockingIn: "Locking in",
    .sleepModeUntilMorning: "Sleep mode active until morning",
    .emergencyExit: "Emergency Exit",
    .emergencyUsedButton: "Emergency Used",
    .breakMessage: "Stand up, take a rest!!!",
    .remindersAccessNeeded: "Reminders access needed",
    .remindersUnavailable: "Reminders unavailable",
    .noOpenReminders: "No open reminders",
    .openReminders: "open reminders",
    .remindersTitle: "REMINDERS",
    .grantRemindersAccessLine1: "Grant",
    .grantRemindersAccessLine2: "Reminders",
    .grantRemindersAccessLine3: "access",
    .allClear: "All clear"
  ]

  private static let chinese: [L10nKey: String] = [
    .enableClawd: "启用 Clawd",
    .disableClawd: "禁用 Clawd",
    .showReminders: "显示提醒事项",
    .hideReminders: "收起提醒事项",
    .startWork: "开始工作",
    .restMode: "休息模式",
    .startBreakNow: "立即休息",
    .resetWorkTimer: "重置工作计时",
    .emergencyExitBedtime: "紧急退出睡眠模式",
    .settings: "设置...",
    .quitClawd: "退出 Clawd",
    .sleepMode: "睡眠模式",
    .clawdOff: "Clawd 已关闭",
    .rest: "休息",
    .settingsTitle: "Clawd 守门员",
    .settingsSubtitle: "一个带提醒、休息和睡眠守护的小工作伙伴。",
    .showRemindersBoard: "显示提醒事项告示牌",
    .enableBedtimeGuard: "启用睡眠守护",
    .workMinutes: "工作分钟数",
    .breakMinutes: "休息分钟数",
    .companionSize: "伙伴大小",
    .language: "语言",
    .bedtime: "睡眠时间",
    .startTime: "开始时间",
    .endTime: "结束时间",
    .lockAfterMinutes: "多少分钟后锁屏",
    .save: "保存",
    .resetWork: "重置工作",
    .startBreak: "开始休息",
    .saved: "已保存",
    .reset: "已重置",
    .started: "已开始",
    .updated: "已更新",
    .failed: "失败",
    .launchAtLoginOn: "开机启动：开",
    .launchAtLoginNeedsApproval: "开机启动：需要批准",
    .launchAtLoginOff: "开机启动：关",
    .launchAtLoginNotAvailable: "开机启动：不可用",
    .launchAtLoginUnknown: "开机启动：未知",
    .launchAtLoginUnsupported: "开机启动：需要 macOS 13+",
    .bedtimeInactive: "睡眠守护当前没有启动。",
    .emergencyAlreadyUsed: "这个睡眠时间段已经使用过紧急退出。",
    .emergencyUsed: "已使用紧急退出。睡眠守护明天恢复。",
    .bedtimeWarning60: "距离睡眠时间还有 1 小时。开始收尾，准备洗漱。",
    .bedtimeWarning30: "距离睡眠时间还有 30 分钟。请开始关闭工作。",
    .bedtimeWarning5: "距离睡眠时间还有 5 分钟。Clawd 正在准备床。",
    .lockCommandMissing: "找不到 macOS 锁屏命令。",
    .lockFailed: "无法自动锁屏。",
    .sleepSetupFailed: "无法完成睡眠配置，请检查 macOS 锁屏设置。",
    .displaySleepFailed: "无法自动息屏。",
    .lockingIn: "即将锁屏",
    .sleepModeUntilMorning: "睡眠模式将持续到早上",
    .emergencyExit: "紧急退出",
    .emergencyUsedButton: "紧急退出已使用",
    .breakMessage: "站起来休息一下！！！",
    .remindersAccessNeeded: "需要提醒事项权限",
    .remindersUnavailable: "提醒事项不可用",
    .noOpenReminders: "没有未完成提醒",
    .openReminders: "条未完成提醒",
    .remindersTitle: "提醒事项",
    .grantRemindersAccessLine1: "授权",
    .grantRemindersAccessLine2: "提醒事项",
    .grantRemindersAccessLine3: "权限",
    .allClear: "全部完成"
  ]
}
