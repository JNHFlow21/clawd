import AppKit

final class PixelNoticeBoardView: NSView {
  var message: String {
    didSet {
      needsDisplay = true
    }
  }

  init(frame frameRect: NSRect, message: String) {
    self.message = message
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.clear.setFill()
    dirtyRect.fill()

    let darkWood = color(0x5b351f)
    let wood = color(0xb8793d)
    let paper = color(0xffe9ad)
    let ink = color(0x4a3022)

    let shadow = bounds.insetBy(dx: 18, dy: 16).offsetBy(dx: 18, dy: -18)
    drawPixelRect(shadow, color(0x02070b).withAlphaComponent(0.46))

    let sign = bounds.insetBy(dx: 18, dy: 18)
    drawPixelRect(sign, darkWood)
    drawPixelRect(sign.insetBy(dx: 8, dy: 8), wood)
    let paperRect = sign.insetBy(dx: 18, dy: 18)
    drawPixelRect(paperRect, paper)

    drawPixelRect(NSRect(x: paperRect.minX + 18, y: paperRect.maxY - 34, width: 13, height: 13), color(0xe95b4f))
    drawPixelRect(NSRect(x: paperRect.maxX - 31, y: paperRect.maxY - 34, width: 13, height: 13), color(0xe95b4f))

    let textRect = paperRect.insetBy(dx: 48, dy: 52)
    drawFittingText(message, in: textRect, color: ink)
  }

  private func drawFittingText(_ text: String, in rect: NSRect, color: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineSpacing = 3

    let cleaned = text
      .replacingOccurrences(of: ". ", with: ".\n")
      .replacingOccurrences(of: "。", with: "。\n")
      .replacingOccurrences(of: "，", with: "，")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    var size: CGFloat = rect.width > 520 ? 28 : 24
    var attributes: [NSAttributedString.Key: Any] = [:]
    var measured = NSRect.zero

    while size >= 16 {
      attributes = [
        .font: NSFont.monospacedSystemFont(ofSize: size, weight: .heavy),
        .foregroundColor: color,
        .paragraphStyle: paragraph
      ]
      measured = (cleaned as NSString).boundingRect(
        with: rect.size,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes
      )
      if measured.height <= rect.height && measured.width <= rect.width {
        break
      }
      size -= 2
    }

    let drawRect = NSRect(
      x: rect.minX,
      y: rect.midY - measured.height / 2,
      width: rect.width,
      height: measured.height + 6
    )
    (cleaned as NSString).draw(
      with: drawRect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attributes
    )
  }

  private func drawPixelRect(_ rect: NSRect, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(rect: rect.integral).fill()
  }

  private func color(_ rgb: Int) -> NSColor {
    NSColor(
      calibratedRed: CGFloat((rgb >> 16) & 0xff) / 255,
      green: CGFloat((rgb >> 8) & 0xff) / 255,
      blue: CGFloat(rgb & 0xff) / 255,
      alpha: 1
    )
  }
}

final class PixelSettingsBackgroundView: NSView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    color(0x0b1117).setFill()
    dirtyRect.fill()

    let card = NSRect(x: 16, y: 78, width: bounds.width - 32, height: bounds.height - 96)
    drawPixelRect(card.offsetBy(dx: 14, dy: -14), color(0x02070b).withAlphaComponent(0.42))
    drawPixelRect(card, color(0x6b4429))
    drawPixelRect(card.insetBy(dx: 6, dy: 6), color(0xb8793d))
    drawPixelRect(card.insetBy(dx: 10, dy: 10), color(0xffe7a8))
  }

  private func drawPixelRect(_ rect: NSRect, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(rect: rect.integral).fill()
  }

  private func color(_ rgb: Int) -> NSColor {
    NSColor(
      calibratedRed: CGFloat((rgb >> 16) & 0xff) / 255,
      green: CGFloat((rgb >> 8) & 0xff) / 255,
      blue: CGFloat(rgb & 0xff) / 255,
      alpha: 1
    )
  }
}
