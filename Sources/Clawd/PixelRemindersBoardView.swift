import AppKit

final class PixelRemindersBoardView: NSView {
  var onToggle: (() -> Void)?
  var isCollapsed = false {
    didSet {
      needsDisplay = true
    }
  }
  var language: AppLanguage = .english {
    didSet {
      needsDisplay = true
    }
  }

  private var displayTimer: Timer?
  private var startDate = Date()
  private var snapshot = ReminderBoardSnapshot(
    items: [],
    statusText: "Loading reminders...",
    isAuthorized: true
  )

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    stopAnimating()
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if window == nil {
      stopAnimating()
    } else {
      startAnimating()
    }
  }

  override var isHidden: Bool {
    didSet {
      isHidden ? stopAnimating() : startAnimating()
    }
  }

  func update(snapshot: ReminderBoardSnapshot) {
    self.snapshot = snapshot
    needsDisplay = true
    startAnimating()
  }

  private func startAnimating() {
    guard !isHidden, displayTimer == nil else { return }
    let timer = Timer(timeInterval: 0.35, repeats: true) { [weak self] _ in
      self?.needsDisplay = true
    }
    RunLoop.main.add(timer, forMode: .common)
    displayTimer = timer
  }

  private func stopAnimating() {
    displayTimer?.invalidate()
    displayTimer = nil
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.clear.setFill()
    dirtyRect.fill()

    let time = Date().timeIntervalSince(startDate)
    if isCollapsed {
      drawCollapsedIcon(in: bounds, time: time)
    } else {
      drawBoard(in: bounds, time: time)
    }
  }

  override func mouseDown(with event: NSEvent) {
    onToggle?()
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  private func drawBoard(in rect: NSRect, time: TimeInterval) {
    let board = rect.insetBy(dx: 3, dy: 3)
    let postColor = color(0x6b4429)
    let darkWood = color(0x4f301d)
    let wood = color(0xb8793d)
    let paper = color(0xffe3a4)
    let ink = color(0x3f271a)

    drawPixelRect(NSRect(x: board.minX + 17, y: board.minY, width: 12, height: board.height - 20), postColor)
    drawPixelRect(NSRect(x: board.maxX - 29, y: board.minY, width: 12, height: board.height - 20), postColor)
    drawPixelRect(NSRect(x: board.minX + 14, y: board.minY + 5, width: 18, height: 5), darkWood)
    drawPixelRect(NSRect(x: board.maxX - 32, y: board.minY + 5, width: 18, height: 5), darkWood)

    let sign = NSRect(x: board.minX, y: board.minY + 26, width: board.width, height: board.height - 30)
    drawPixelRect(sign, darkWood)
    drawPixelRect(sign.insetBy(dx: 4, dy: 4), wood)
    let paperRect = sign.insetBy(dx: 10, dy: 10)
    drawPixelRect(paperRect, paper)

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(rect: paperRect).addClip()

    let blink = Int(time * 2) % 2 == 0
    drawPixelRect(NSRect(x: paperRect.minX + 10, y: paperRect.maxY - 20, width: 8, height: 8), blink ? color(0xe95b4f) : color(0xd44940))
    drawPixelRect(NSRect(x: paperRect.maxX - 18, y: paperRect.maxY - 20, width: 8, height: 8), blink ? color(0xe95b4f) : color(0xd44940))

    drawText(text(.remindersTitle), in: NSRect(x: paperRect.minX + 16, y: paperRect.maxY - 40, width: paperRect.width - 32, height: 22), size: 13, color: ink, weight: .heavy, alignment: .center)
    drawText(snapshot.statusText, in: NSRect(x: paperRect.minX + 12, y: paperRect.maxY - 62, width: paperRect.width - 24, height: 18), size: 9, color: color(0x76553a), weight: .bold, alignment: .center)

    if !snapshot.isAuthorized {
      drawMultilineText(
        [text(.grantRemindersAccessLine1), text(.grantRemindersAccessLine2), text(.grantRemindersAccessLine3)],
        in: NSRect(x: paperRect.minX + 12, y: paperRect.midY - 36, width: paperRect.width - 24, height: 72),
        size: 12,
        color: ink,
        weight: .heavy,
        alignment: .center
      )
      NSGraphicsContext.restoreGraphicsState()
      return
    }

    if snapshot.items.isEmpty {
      drawText(text(.allClear), in: NSRect(x: paperRect.minX + 12, y: paperRect.midY - 12, width: paperRect.width - 24, height: 24), size: 13, color: ink, weight: .heavy, alignment: .center)
      NSGraphicsContext.restoreGraphicsState()
      return
    }

    let itemStartY = paperRect.maxY - 100
    let rowHeight: CGFloat = 43
    for (index, item) in snapshot.items.prefix(5).enumerated() {
      let y = itemStartY - CGFloat(index) * rowHeight
      let pinX = paperRect.minX + 9
      drawPixelRect(NSRect(x: pinX, y: y + 22, width: 8, height: 8), color(index % 2 == 0 ? 0xe95b4f : 0x62bde8))
      let labelRect = NSRect(x: paperRect.minX + 24, y: y + 6, width: paperRect.width - 36, height: 36)
      drawMultilineText(lines(for: item.title, maxLines: 2, width: labelRect.width, fontSize: 11), in: labelRect, size: 11, color: ink, weight: .heavy, alignment: .left)
    }

    NSGraphicsContext.restoreGraphicsState()
  }

  private func drawCollapsedIcon(in rect: NSRect, time: TimeInterval) {
    let size = min(rect.width, rect.height)
    let icon = NSRect(
      x: rect.midX - size / 2 + 3,
      y: rect.midY - size / 2 + 3,
      width: size - 6,
      height: size - 6
    )
    let darkWood = color(0x4f301d)
    let wood = color(0xb8793d)
    let paper = color(0xffe3a4)
    let ink = color(0x3f271a)
    let blink = Int(time * 2) % 2 == 0

    drawPixelRect(icon, darkWood)
    drawPixelRect(icon.insetBy(dx: 4, dy: 4), wood)
    drawPixelRect(icon.insetBy(dx: 9, dy: 9), paper)
    drawPixelRect(NSRect(x: icon.minX + 12, y: icon.maxY - 18, width: 7, height: 7), blink ? color(0xe95b4f) : color(0xd44940))
    drawPixelRect(NSRect(x: icon.maxX - 19, y: icon.maxY - 18, width: 7, height: 7), blink ? color(0x62bde8) : color(0x248cc8))
    drawText("!", in: NSRect(x: icon.minX + 12, y: icon.minY + 10, width: icon.width - 24, height: icon.height - 20), size: 22, color: ink, weight: .heavy, alignment: .center)
  }

  private func drawPixelRect(_ rect: NSRect, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(rect: rect.integral).fill()
  }

  private func drawText(_ text: String, in rect: NSRect, size: CGFloat, color: NSColor, weight: NSFont.Weight, alignment: NSTextAlignment) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.monospacedSystemFont(ofSize: size, weight: weight),
      .foregroundColor: color,
      .paragraphStyle: paragraph
    ]
    (text as NSString).draw(in: rect, withAttributes: attributes)
  }

  private func drawMultilineText(_ lines: [String], in rect: NSRect, size: CGFloat, color: NSColor, weight: NSFont.Weight, alignment: NSTextAlignment) {
    guard !lines.isEmpty else { return }
    let lineHeight = size + 3
    let totalHeight = CGFloat(lines.count) * lineHeight
    let startY = rect.midY + totalHeight / 2 - lineHeight
    for (index, line) in lines.enumerated() {
      let lineRect = NSRect(
        x: rect.minX,
        y: startY - CGFloat(index) * lineHeight,
        width: rect.width,
        height: lineHeight + 2
      )
      drawText(line, in: lineRect, size: size, color: color, weight: weight, alignment: alignment)
    }
  }

  private func lines(for title: String, maxLines: Int, width: CGFloat, fontSize: CGFloat) -> [String] {
    let cleaned = title.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return [] }

    var lines: [String] = []
    var current = ""
    for character in cleaned {
      let candidate = current + String(character)
      if textWidth(candidate, fontSize: fontSize) <= width || current.isEmpty {
        current = candidate
      } else {
        lines.append(current)
        current = String(character)
        if lines.count == maxLines {
          break
        }
      }
    }

    if lines.count < maxLines, !current.isEmpty {
      lines.append(current)
    }

    if lines.count > maxLines {
      lines = Array(lines.prefix(maxLines))
    }

    if lines.count == maxLines && textWidth(lines[maxLines - 1], fontSize: fontSize) > width {
      lines[maxLines - 1] = truncated(lines[maxLines - 1], width: width, fontSize: fontSize)
    } else if cleaned.count > lines.joined().count, !lines.isEmpty {
      lines[lines.count - 1] = truncated(lines[lines.count - 1], width: width, fontSize: fontSize)
    }

    return lines
  }

  private func truncated(_ text: String, width: CGFloat, fontSize: CGFloat) -> String {
    var value = text
    while value.count > 1 && textWidth(value + "...", fontSize: fontSize) > width {
      value.removeLast()
    }
    return value + "..."
  }

  private func textWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .heavy)
    ]
    return (text as NSString).size(withAttributes: attributes).width
  }

  private func color(_ hex: UInt32) -> NSColor {
    NSColor(
      calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
      green: CGFloat((hex >> 8) & 0xff) / 255,
      blue: CGFloat(hex & 0xff) / 255,
      alpha: 1
    )
  }

  private func text(_ key: L10nKey) -> String {
    L10n.text(key, language: language)
  }
}
