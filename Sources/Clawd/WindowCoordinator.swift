import AppKit
import QuartzCore

final class WindowCoordinator {
  private final class ActionProxy: NSObject {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
      self.action = action
    }

    @objc func invoke(_ sender: Any?) {
      action()
    }
  }

  private final class BreakWindowContext {
    let window: NSWindow
    let webView: TransparentWebView
    let messageLabel: NSTextField
    let timerLabel: NSTextField

    init(window: NSWindow, webView: TransparentWebView, messageLabel: NSTextField, timerLabel: NSTextField) {
      self.window = window
      self.webView = webView
      self.messageLabel = messageLabel
      self.timerLabel = timerLabel
    }
  }

  private final class BedtimeWindowContext {
    let window: NSWindow
    let webView: TransparentWebView
    let lockLabel: NSTextField
    let emergencyButton: NSButton
    let actionProxy: ActionProxy

    init(
      window: NSWindow,
      webView: TransparentWebView,
      lockLabel: NSTextField,
      emergencyButton: NSButton,
      actionProxy: ActionProxy
    ) {
      self.window = window
      self.webView = webView
      self.lockLabel = lockLabel
      self.emergencyButton = emergencyButton
      self.actionProxy = actionProxy
    }
  }

  private let settings: AppSettings
  private let animationsDirectory: URL
  private let workAnimationBaseSize: CGFloat = 720
  private let workTimerWindowSize = NSSize(width: 110, height: 48)
  private let reminderBoardExpandedSize = NSSize(width: 190, height: 398)
  private let reminderBoardCollapsedSize = NSSize(width: 54, height: 54)
  private var workWindow: NSPanel?
  private var primaryWorkWebView: TransparentWebView?
  private var secondaryWorkWebView: TransparentWebView?
  private var visibleWorkWebView: TransparentWebView?
  private var workTimerWindow: NSPanel?
  private var workTimerLabel: NSTextField?
  private var reminderWindow: NSPanel?
  private var remindersBoardView: PixelRemindersBoardView?
  private var currentWorkEdge: ScreenEdge = .bottomRight
  private var currentWorkAnimationName = ""
  private var displayedWorkAnimationName = ""
  private var workLoadGeneration = 0
  private var workReadinessTimer: Timer?
  private var breakContexts: [BreakWindowContext] = []
  private var bedtimeContexts: [BedtimeWindowContext] = []
  private var bedtimeReminderWindows: [NSPanel] = []
  private var bedtimeReminderTimer: Timer?

  var onRemindersCollapsedChanged: ((Bool) -> Void)?

  init(settings: AppSettings) {
    self.settings = settings
    self.animationsDirectory = WindowCoordinator.resolveAnimationsDirectory()
  }

  func showWorkCompanion(animationName: String, edge: ScreenEdge) {
    let panel = ensureWorkWindow()
    currentWorkEdge = edge
    currentWorkAnimationName = animationName
    let size = NSSize(width: settings.companionSize, height: settings.companionSize)
    panel.setFrame(NSRect(origin: panel.frame.origin, size: size), display: true)
    layoutWorkWebViews()
    positionWorkWindow(panel, edge: edge, size: size, screen: activeWorkScreen())

    if displayedWorkAnimationName == animationName, visibleWorkWebView != nil {
      panel.orderFrontRegardless()
      return
    }

    loadWorkAnimationWhenReady(animationName)
  }

  func showWarningCompanion() {
    showWorkCompanion(animationName: AnimationCatalog.warningAnimation, edge: .bottomRight)
  }

  func updateWorkTimer(remainingSeconds: Int) {
    let timerPanel = ensureWorkTimerWindow()
    let reminderPanel = ensureReminderWindow()
    let screen = activeWorkScreen()
    workTimerLabel?.stringValue = formatDuration(remainingSeconds)
    positionWorkTimerWindow(timerPanel, screen: screen)
    positionReminderWindow(reminderPanel, screen: screen)
    repositionCurrentWorkWindow(on: screen)
    timerPanel.orderFrontRegardless()
    reminderPanel.orderFrontRegardless()
  }

  func hideWorkTimer() {
    workTimerWindow?.orderOut(nil)
  }

  func showReminderBoard() {
    let reminderPanel = ensureReminderWindow()
    let screen = activeWorkScreen()
    positionReminderWindow(reminderPanel, screen: screen)
    repositionCurrentWorkWindow(on: screen)
    reminderPanel.orderFrontRegardless()
  }

  func updateReminders(_ snapshot: ReminderBoardSnapshot) {
    _ = ensureReminderWindow()
    remindersBoardView?.update(snapshot: snapshot)
  }

  func toggleRemindersCollapsed() {
    setRemindersCollapsed(!settings.remindersCollapsed, animated: true)
  }

  func applySettings() {
    remindersBoardView?.language = settings.language
    setRemindersCollapsed(settings.remindersCollapsed, animated: false)
  }

  func hideWorkUI() {
    workLoadGeneration += 1
    stopWorkReadinessTimer()
    workWindow?.orderOut(nil)
    workTimerWindow?.orderOut(nil)
    reminderWindow?.orderOut(nil)
  }

  func showBreakOverlay(animationName: String, remainingSeconds: Int) {
    hideWorkUI()
    hideBreakOverlay()

    for screen in NSScreen.screens {
      let context = makeBreakWindow(for: screen)
      context.webView.loadAnimation(animationName, from: animationsDirectory)
      context.timerLabel.stringValue = formatDuration(remainingSeconds)
      breakContexts.append(context)
      context.window.makeKeyAndOrderFront(nil)
      context.window.orderFrontRegardless()
    }

    NSApp.activate(ignoringOtherApps: true)
  }

  func switchBreakAnimation(to animationName: String) {
    for context in breakContexts {
      context.webView.loadAnimation(animationName, from: animationsDirectory)
    }
  }

  func updateBreakTimer(remainingSeconds: Int) {
    for context in breakContexts {
      context.timerLabel.stringValue = formatDuration(remainingSeconds)
    }
  }

  func hideBreakOverlay() {
    for context in breakContexts {
      context.window.orderOut(nil)
    }
    breakContexts.removeAll()
  }

  func showBedtimeOverlay(
    lockRemainingSeconds: Int?,
    emergencyAvailable: Bool,
    onEmergencyExit: @escaping () -> Void
  ) {
    hideWorkUI()
    hideBreakOverlay()
    hideBedtimeReminder()

    if bedtimeContexts.isEmpty {
      for screen in NSScreen.screens {
        let context = makeBedtimeWindow(for: screen, onEmergencyExit: onEmergencyExit)
        context.webView.loadAnimation(AnimationCatalog.bedtimeAnimation, from: animationsDirectory)
        bedtimeContexts.append(context)
        context.window.makeKeyAndOrderFront(nil)
        context.window.orderFrontRegardless()
      }
    }

    updateBedtimeOverlay(lockRemainingSeconds: lockRemainingSeconds, emergencyAvailable: emergencyAvailable)
    NSApp.activate(ignoringOtherApps: true)
  }

  func updateBedtimeOverlay(lockRemainingSeconds: Int?, emergencyAvailable: Bool) {
    for context in bedtimeContexts {
      if let lockRemainingSeconds {
        context.lockLabel.stringValue = "\(text(.lockingIn)) \(formatDuration(lockRemainingSeconds))"
      } else {
        context.lockLabel.stringValue = text(.sleepModeUntilMorning)
      }
      context.emergencyButton.isEnabled = emergencyAvailable
      context.emergencyButton.title = emergencyAvailable ? text(.emergencyExit) : text(.emergencyUsedButton)
      context.window.orderFrontRegardless()
    }
  }

  func hideBedtimeOverlay() {
    for context in bedtimeContexts {
      context.window.orderOut(nil)
    }
    bedtimeContexts.removeAll()
  }

  func showBedtimeReminder(message: String, duration: TimeInterval = 30) {
    hideBedtimeReminder()

    for screen in NSScreen.screens {
      let visibleFrame = screen.visibleFrame
      let size = NSSize(
        width: min(820, max(360, visibleFrame.width - 96)),
        height: min(310, max(210, visibleFrame.height * 0.28))
      )
      let origin = NSPoint(
        x: visibleFrame.midX - size.width / 2,
        y: visibleFrame.maxY - size.height - 64
      )
      let panel = NSPanel(
        contentRect: NSRect(origin: origin, size: size),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
      )
      panel.backgroundColor = .clear
      panel.isOpaque = false
      panel.hasShadow = true
      panel.level = .statusBar
      panel.ignoresMouseEvents = true
      panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
      panel.hidesOnDeactivate = false

      let root = PixelNoticeBoardView(frame: NSRect(origin: .zero, size: size), message: message)
      root.autoresizingMask = [.width, .height]
      panel.contentView = root
      bedtimeReminderWindows.append(panel)
      panel.orderFrontRegardless()
    }

    bedtimeReminderTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
      self?.hideBedtimeReminder()
    }
  }

  func hideBedtimeReminder() {
    bedtimeReminderTimer?.invalidate()
    bedtimeReminderTimer = nil
    for window in bedtimeReminderWindows {
      window.orderOut(nil)
    }
    bedtimeReminderWindows.removeAll()
  }

  func hideAll() {
    hideWorkUI()
    hideBreakOverlay()
    hideBedtimeOverlay()
    hideBedtimeReminder()
  }

  private func ensureWorkWindow() -> NSPanel {
    if let workWindow {
      return workWindow
    }

    let size = NSSize(width: settings.companionSize, height: settings.companionSize)
    let panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.level = .statusBar
    panel.ignoresMouseEvents = true
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    panel.hidesOnDeactivate = false

    let contentView = NSView(frame: NSRect(origin: .zero, size: size))
    contentView.wantsLayer = true
    contentView.layer?.backgroundColor = NSColor.clear.cgColor

    let primaryWebView = makeWorkWebView()
    let secondaryWebView = makeWorkWebView()
    secondaryWebView.alphaValue = 0
    contentView.addSubview(primaryWebView)
    contentView.addSubview(secondaryWebView)

    panel.contentView = contentView
    workWindow = panel
    primaryWorkWebView = primaryWebView
    secondaryWorkWebView = secondaryWebView
    layoutWorkWebViews()
    return panel
  }

  private func makeWorkWebView() -> TransparentWebView {
    let webView = TransparentWebView(frame: NSRect(x: 0, y: 0, width: workAnimationBaseSize, height: workAnimationBaseSize))
    webView.autoresizingMask = []
    return webView
  }

  private func loadWorkAnimationWhenReady(_ animationName: String) {
    guard let loadingWebView = nextWorkWebViewForLoading() else { return }

    workLoadGeneration += 1
    stopWorkReadinessTimer()
    let generation = workLoadGeneration

    loadingWebView.alphaValue = 0
    loadingWebView.loadAnimation(animationName, from: animationsDirectory)
    waitUntilWorkWebViewHasPixels(loadingWebView, animationName: animationName, generation: generation)
  }

  private func nextWorkWebViewForLoading() -> TransparentWebView? {
    if visibleWorkWebView === primaryWorkWebView {
      return secondaryWorkWebView
    }
    return primaryWorkWebView ?? secondaryWorkWebView
  }

  private func waitUntilWorkWebViewHasPixels(_ webView: TransparentWebView, animationName: String, generation: Int) {
    var attempts = 0
    let timer = Timer(timeInterval: 0.08, repeats: true) { [weak self, weak webView] timer in
      guard let self, let webView, generation == self.workLoadGeneration else {
        timer.invalidate()
        return
      }

      attempts += 1
      webView.evaluateJavaScript(Self.forcePaintAndDetectPixelsScript) { result, _ in
        guard generation == self.workLoadGeneration else { return }
        if (result as? Bool) == true {
          self.stopWorkReadinessTimer()
          self.presentReadyWorkWebView(webView, animationName: animationName)
          return
        }

        if attempts >= 160 {
          self.stopWorkReadinessTimer()
          if self.visibleWorkWebView == nil {
            self.presentReadyWorkWebView(webView, animationName: animationName)
          }
        }
      }
    }

    RunLoop.main.add(timer, forMode: .common)
    workReadinessTimer = timer
  }

  private func presentReadyWorkWebView(_ webView: TransparentWebView, animationName: String) {
    guard animationName == currentWorkAnimationName, let panel = workWindow else { return }

    layoutWorkWebViews()
    if let contentView = panel.contentView {
      contentView.addSubview(webView, positioned: .above, relativeTo: nil)
    }

    primaryWorkWebView?.alphaValue = primaryWorkWebView === webView ? 1 : 0
    secondaryWorkWebView?.alphaValue = secondaryWorkWebView === webView ? 1 : 0
    visibleWorkWebView = webView
    displayedWorkAnimationName = animationName

    let size = NSSize(width: settings.companionSize, height: settings.companionSize)
    panel.setFrame(NSRect(origin: panel.frame.origin, size: size), display: true)
    positionWorkWindow(panel, edge: currentWorkEdge, size: size, screen: activeWorkScreen())
    panel.orderFrontRegardless()
  }

  private func stopWorkReadinessTimer() {
    workReadinessTimer?.invalidate()
    workReadinessTimer = nil
  }

  private static let forcePaintAndDetectPixelsScript = """
  (() => {
    const canvas = document.querySelector('canvas');
    if (!canvas || canvas.width < 2 || canvas.height < 2) return false;

    try {
      if (typeof resizeCanvas === 'function') resizeCanvas();
      if (typeof render === 'function') {
        if (render.length >= 2) render(0, 0);
        else if (render.length === 1) render(0);
        else render();
      }
    } catch (_) {}

    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    if (!ctx) return false;

    const w = canvas.width;
    const h = canvas.height;
    const points = [
      [0.15, 0.15], [0.5, 0.15], [0.85, 0.15],
      [0.15, 0.5], [0.5, 0.5], [0.85, 0.5],
      [0.15, 0.85], [0.5, 0.85], [0.85, 0.85]
    ];
    for (const [px, py] of points) {
      const x = Math.max(0, Math.min(w - 1, Math.floor(w * px)));
      const y = Math.max(0, Math.min(h - 1, Math.floor(h * py)));
      const data = ctx.getImageData(x, y, 1, 1).data;
      if (data[3] > 8) return true;
    }

    const stepX = Math.max(1, Math.floor(w / 28));
    const stepY = Math.max(1, Math.floor(h / 28));
    for (let y = 0; y < h; y += stepY) {
      for (let x = 0; x < w; x += stepX) {
        const data = ctx.getImageData(x, y, 1, 1).data;
        if (data[3] > 8) return true;
      }
    }
    return false;
  })();
  """

  private func layoutWorkWebViews() {
    let scale = CGFloat(settings.companionSize) / workAnimationBaseSize
    for webView in [primaryWorkWebView, secondaryWorkWebView].compactMap({ $0 }) {
      webView.frame = NSRect(x: 0, y: 0, width: workAnimationBaseSize, height: workAnimationBaseSize)
      webView.layer?.anchorPoint = CGPoint(x: 0, y: 0)
      webView.layer?.position = CGPoint(x: 0, y: 0)
      webView.layer?.transform = CATransform3DMakeScale(scale, scale, 1)
    }
  }

  private func ensureWorkTimerWindow() -> NSPanel {
    if let workTimerWindow {
      return workTimerWindow
    }

    let size = workTimerWindowSize
    let panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.level = .statusBar
    panel.ignoresMouseEvents = true
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    panel.hidesOnDeactivate = false

    let root = NSView(frame: NSRect(origin: .zero, size: size))
    root.wantsLayer = true
    root.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.26).cgColor
    root.layer?.cornerRadius = 8

    let label = NSTextField(labelWithString: "0:00")
    label.frame = root.bounds.insetBy(dx: 8, dy: 4)
    label.autoresizingMask = [.width, .height]
    label.alignment = .center
    label.textColor = .white
    label.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
    label.wantsLayer = true
    label.layer?.shadowColor = NSColor.black.withAlphaComponent(0.45).cgColor
    label.layer?.shadowRadius = 2
    label.layer?.shadowOpacity = 1
    label.layer?.shadowOffset = CGSize(width: 0, height: -1)
    root.addSubview(label)

    panel.contentView = root
    workTimerWindow = panel
    workTimerLabel = label
    return panel
  }

  private func ensureReminderWindow() -> NSPanel {
    if let reminderWindow {
      return reminderWindow
    }

    let size = currentReminderWindowSize()
    let panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.level = .statusBar
    panel.ignoresMouseEvents = false
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    panel.hidesOnDeactivate = false

    let board = PixelRemindersBoardView(frame: NSRect(origin: .zero, size: size))
    board.autoresizingMask = [.width, .height]
    board.isCollapsed = settings.remindersCollapsed
    board.language = settings.language
    board.onToggle = { [weak self] in
      self?.toggleRemindersCollapsed()
    }

    panel.contentView = board
    reminderWindow = panel
    remindersBoardView = board
    return panel
  }

  private func setRemindersCollapsed(_ collapsed: Bool, animated: Bool) {
    let changed = settings.remindersCollapsed != collapsed
    settings.remindersCollapsed = collapsed
    remindersBoardView?.isCollapsed = collapsed

    guard let panel = reminderWindow else { return }
    positionReminderWindow(panel, screen: activeWorkScreen(), animated: animated)
    repositionCurrentWorkWindow(on: activeWorkScreen())
    panel.orderFrontRegardless()

    if changed {
      onRemindersCollapsedChanged?(collapsed)
    }
  }

  private func makeBreakWindow(for screen: NSScreen) -> BreakWindowContext {
    let window = NSWindow(
      contentRect: screen.frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.setFrame(screen.frame, display: false)
    window.backgroundColor = .clear
    window.isOpaque = false
    window.hasShadow = false
    window.level = .screenSaver
    window.ignoresMouseEvents = false
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    window.hidesOnDeactivate = false

    let root = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
    root.wantsLayer = true
    root.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.82).cgColor

    let webView = TransparentWebView(frame: .zero)
    let messageLabel = NSTextField(labelWithString: text(.breakMessage))
    let timerLabel = NSTextField(labelWithString: "0:00")

    configureBreakMessageLabel(messageLabel)
    configureBreakTimerLabel(timerLabel)

    root.addSubview(webView)
    root.addSubview(messageLabel)
    root.addSubview(timerLabel)
    window.contentView = root

    let context = BreakWindowContext(window: window, webView: webView, messageLabel: messageLabel, timerLabel: timerLabel)
    layoutBreakContext(context, in: root.bounds)
    return context
  }

  private func makeBedtimeWindow(for screen: NSScreen, onEmergencyExit: @escaping () -> Void) -> BedtimeWindowContext {
    let window = NSWindow(
      contentRect: screen.frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.setFrame(screen.frame, display: false)
    window.backgroundColor = .clear
    window.isOpaque = false
    window.hasShadow = false
    window.level = .screenSaver
    window.ignoresMouseEvents = false
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    window.hidesOnDeactivate = false

    let root = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
    root.wantsLayer = true
    root.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.88).cgColor

    let webView = TransparentWebView(frame: root.bounds)
    webView.autoresizingMask = [.width, .height]

    let lockLabel = NSTextField(labelWithString: "\(text(.lockingIn)) 15:00")
    lockLabel.alignment = .center
    lockLabel.textColor = NSColor.white.withAlphaComponent(0.88)
    lockLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .bold)
    lockLabel.wantsLayer = true
    lockLabel.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.36).cgColor
    lockLabel.layer?.cornerRadius = 8

    let actionProxy = ActionProxy(action: onEmergencyExit)
    let emergencyButton = NSButton(title: text(.emergencyExit), target: actionProxy, action: #selector(ActionProxy.invoke(_:)))
    emergencyButton.bezelStyle = .rounded
    emergencyButton.font = .systemFont(ofSize: 14, weight: .semibold)

    root.addSubview(webView)
    root.addSubview(lockLabel)
    root.addSubview(emergencyButton)
    window.contentView = root

    let context = BedtimeWindowContext(
      window: window,
      webView: webView,
      lockLabel: lockLabel,
      emergencyButton: emergencyButton,
      actionProxy: actionProxy
    )
    layoutBedtimeContext(context, in: root.bounds)
    return context
  }

  private func configureBreakMessageLabel(_ label: NSTextField) {
    label.alignment = .center
    label.textColor = NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.72, alpha: 1.0)
    label.font = .monospacedSystemFont(ofSize: 46, weight: .heavy)
    label.wantsLayer = true
    label.layer?.shadowColor = NSColor(calibratedRed: 0.62, green: 0.18, blue: 0.16, alpha: 1).cgColor
    label.layer?.shadowRadius = 0
    label.layer?.shadowOpacity = 1
    label.layer?.shadowOffset = CGSize(width: 4, height: -4)
  }

  private func configureBreakTimerLabel(_ label: NSTextField) {
    label.alignment = .center
    label.textColor = .white
    label.font = .monospacedDigitSystemFont(ofSize: 82, weight: .heavy)
    label.wantsLayer = true
    label.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
    label.layer?.cornerRadius = 8
  }

  private func layoutBreakContext(_ context: BreakWindowContext, in bounds: NSRect) {
    let width = bounds.width
    let animationHeight = min(bounds.height * 0.58, 640)
    let messageHeight: CGFloat = 70
    let timerHeight: CGFloat = 112
    let gap: CGFloat = 16
    let totalHeight = animationHeight + messageHeight + timerHeight + gap * 2
    let startY = max(28, (bounds.height - totalHeight) / 2)

    context.timerLabel.frame = NSRect(
      x: max(24, (width - 360) / 2),
      y: startY,
      width: min(360, width - 48),
      height: timerHeight
    )
    context.messageLabel.frame = NSRect(
      x: 24,
      y: context.timerLabel.frame.maxY + gap,
      width: width - 48,
      height: messageHeight
    )
    context.webView.frame = NSRect(
      x: 0,
      y: context.messageLabel.frame.maxY + gap,
      width: width,
      height: animationHeight
    )
  }

  private func layoutBedtimeContext(_ context: BedtimeWindowContext, in bounds: NSRect) {
    context.webView.frame = bounds

    let lockSize = NSSize(width: min(300, bounds.width - 48), height: 48)
    context.lockLabel.frame = NSRect(
      x: max(24, (bounds.width - lockSize.width) / 2),
      y: bounds.height - lockSize.height - 34,
      width: lockSize.width,
      height: lockSize.height
    )

    let buttonSize = NSSize(width: 150, height: 36)
    context.emergencyButton.frame = NSRect(
      x: bounds.width - buttonSize.width - 28,
      y: 28,
      width: buttonSize.width,
      height: buttonSize.height
    )
  }

  private func repositionCurrentWorkWindow(on screen: NSScreen) {
    guard let panel = workWindow, panel.isVisible else { return }

    let size = NSSize(width: settings.companionSize, height: settings.companionSize)
    if panel.frame.size != size {
      panel.setFrame(NSRect(origin: panel.frame.origin, size: size), display: true)
      layoutWorkWebViews()
    }
    positionWorkWindow(panel, edge: currentWorkEdge, size: size, screen: screen)
  }

  private func positionWorkWindow(_ panel: NSPanel, edge: ScreenEdge, size: NSSize, screen: NSScreen) {
    let visibleFrame = screen.visibleFrame
    let margin: CGFloat = 20
    var origin: NSPoint

    switch edge {
    case .topLeft:
      origin = NSPoint(x: visibleFrame.minX + margin, y: visibleFrame.maxY - size.height - margin)
    case .topRight:
      origin = NSPoint(x: visibleFrame.maxX - size.width - margin, y: visibleFrame.maxY - size.height - margin)
    case .bottomLeft:
      origin = NSPoint(x: visibleFrame.minX + margin, y: visibleFrame.minY + margin)
    case .bottomRight:
      origin = NSPoint(x: visibleFrame.maxX - size.width - margin, y: visibleFrame.minY + margin)
    }

    panel.setFrameOrigin(workOriginAvoidingReservedAreas(origin: origin, size: size, screen: screen, margin: margin))
  }

  private func positionWorkTimerWindow(_ panel: NSPanel, screen: NSScreen) {
    let visibleFrame = screen.visibleFrame
    let margin: CGFloat = 20
    if panel.frame.size != workTimerWindowSize {
      panel.setFrame(NSRect(origin: panel.frame.origin, size: workTimerWindowSize), display: true)
    }
    let origin = NSPoint(
      x: visibleFrame.minX + margin,
      y: visibleFrame.maxY - panel.frame.height - margin
    )
    panel.setFrameOrigin(origin)
  }

  private func positionReminderWindow(_ panel: NSPanel, screen: NSScreen, animated: Bool = false) {
    let visibleFrame = screen.visibleFrame
    let margin: CGFloat = 20
    let size = currentReminderWindowSize()
    let origin = NSPoint(
      x: visibleFrame.minX + margin,
      y: visibleFrame.minY + margin
    )
    let frame = NSRect(origin: origin, size: size)
    if animated {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.18
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        panel.animator().setFrame(frame, display: true)
      }
    } else if panel.frame != frame {
      panel.setFrame(frame, display: true)
    }
  }

  private func predictedWorkTimerFrame(on screen: NSScreen) -> NSRect {
    let visibleFrame = screen.visibleFrame
    let margin: CGFloat = 20
    return NSRect(
      x: visibleFrame.minX + margin,
      y: visibleFrame.maxY - workTimerWindowSize.height - margin,
      width: workTimerWindowSize.width,
      height: workTimerWindowSize.height
    )
  }

  private func predictedReminderFrame(on screen: NSScreen) -> NSRect {
    let visibleFrame = screen.visibleFrame
    let margin: CGFloat = 20
    return NSRect(
      x: visibleFrame.minX + margin,
      y: visibleFrame.minY + margin,
      width: currentReminderWindowSize().width,
      height: currentReminderWindowSize().height
    )
  }

  private func currentReminderWindowSize() -> NSSize {
    settings.remindersCollapsed ? reminderBoardCollapsedSize : reminderBoardExpandedSize
  }

  private func reservedWorkFrames(on screen: NSScreen) -> [NSRect] {
    [
      predictedWorkTimerFrame(on: screen).insetBy(dx: -10, dy: -10),
      predictedReminderFrame(on: screen).insetBy(dx: -10, dy: -10)
    ]
  }

  private func workOriginAvoidingReservedAreas(origin: NSPoint, size: NSSize, screen: NSScreen, margin: CGFloat) -> NSPoint {
    let visibleFrame = screen.visibleFrame
    let originalOrigin = clampedOrigin(origin, size: size, visibleFrame: visibleFrame, margin: margin)
    var frame = NSRect(origin: originalOrigin, size: size)
    let reservedFrames = reservedWorkFrames(on: screen)

    for _ in 0..<3 {
      var changed = false
      for reservedFrame in reservedFrames where frame.intersects(reservedFrame) {
        frame.origin = bestWorkOrigin(
          for: frame,
          avoiding: reservedFrame,
          within: visibleFrame,
          margin: margin,
          preferredOrigin: originalOrigin
        )
        changed = true
      }
      if !changed {
        break
      }
    }

    return clampedOrigin(frame.origin, size: size, visibleFrame: visibleFrame, margin: margin)
  }

  private func bestWorkOrigin(
    for frame: NSRect,
    avoiding reservedFrame: NSRect,
    within visibleFrame: NSRect,
    margin: CGFloat,
    preferredOrigin: NSPoint
  ) -> NSPoint {
    let size = frame.size
    let candidates = [
      NSPoint(x: frame.minX, y: reservedFrame.maxY + margin),
      NSPoint(x: frame.minX, y: reservedFrame.minY - size.height - margin),
      NSPoint(x: reservedFrame.maxX + margin, y: frame.minY),
      NSPoint(x: reservedFrame.minX - size.width - margin, y: frame.minY)
    ]

    let validCandidates = candidates.filter { candidate in
      let candidateFrame = NSRect(origin: candidate, size: size)
      return candidateFrame.minX >= visibleFrame.minX + margin
        && candidateFrame.maxX <= visibleFrame.maxX - margin
        && candidateFrame.minY >= visibleFrame.minY + margin
        && candidateFrame.maxY <= visibleFrame.maxY - margin
    }

    return validCandidates.min { lhs, rhs in
      squaredDistance(lhs, preferredOrigin) < squaredDistance(rhs, preferredOrigin)
    } ?? clampedOrigin(frame.origin, size: size, visibleFrame: visibleFrame, margin: margin)
  }

  private func clampedOrigin(_ origin: NSPoint, size: NSSize, visibleFrame: NSRect, margin: CGFloat) -> NSPoint {
    let minX = visibleFrame.minX + margin
    let maxX = max(minX, visibleFrame.maxX - size.width - margin)
    let minY = visibleFrame.minY + margin
    let maxY = max(minY, visibleFrame.maxY - size.height - margin)

    return NSPoint(
      x: min(max(origin.x, minX), maxX),
      y: min(max(origin.y, minY), maxY)
    )
  }

  private func squaredDistance(_ lhs: NSPoint, _ rhs: NSPoint) -> CGFloat {
    let dx = lhs.x - rhs.x
    let dy = lhs.y - rhs.y
    return dx * dx + dy * dy
  }

  private func text(_ key: L10nKey) -> String {
    L10n.text(key, language: settings.language)
  }

  private func activeWorkScreen() -> NSScreen {
    let mouseLocation = NSEvent.mouseLocation
    if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
      return screen
    }
    return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
  }

  private static func resolveAnimationsDirectory() -> URL {
    if let resourceURL = Bundle.main.resourceURL {
      let bundled = resourceURL.appendingPathComponent("Animations", isDirectory: true)
      if FileManager.default.fileExists(atPath: bundled.path) {
        return bundled
      }
    }

    let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return current.appendingPathComponent("Resources/Animations", isDirectory: true)
  }
}
