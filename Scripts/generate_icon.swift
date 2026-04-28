import AppKit
import Foundation

let pngPath = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.png"
let icnsPath = CommandLine.arguments.dropFirst().dropFirst().first ?? "Resources/AppIcon.icns"
let pngURL = URL(fileURLWithPath: pngPath)
let icnsURL = URL(fileURLWithPath: icnsPath)
let size: CGFloat = 1024
let grid: CGFloat = 64
let cell = size / grid

func color(_ hex: UInt32) -> NSColor {
  let r = CGFloat((hex >> 16) & 0xff) / 255
  let g = CGFloat((hex >> 8) & 0xff) / 255
  let b = CGFloat(hex & 0xff) / 255
  return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
}

func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ fill: NSColor) {
  fill.setFill()
  let drawRect = NSRect(
    x: CGFloat(x) * cell,
    y: size - CGFloat(y + h) * cell,
    width: CGFloat(w) * cell,
    height: CGFloat(h) * cell
  )
  drawRect.fill()
}

func pixel(_ x: Int, _ y: Int, _ fill: NSColor) {
  rect(x, y, 1, 1, fill)
}

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let background = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size), xRadius: 180, yRadius: 180)
background.addClip()
NSGradient(colors: [
  color(0xfff1a8),
  color(0x8fe9d2),
  color(0x4bb7f0)
])?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 90)

rect(5, 6, 6, 3, color(0xffffff).withAlphaComponent(0.55))
rect(10, 9, 4, 2, color(0xffffff).withAlphaComponent(0.35))
rect(49, 45, 8, 3, color(0xffffff).withAlphaComponent(0.4))
rect(52, 42, 5, 2, color(0xffffff).withAlphaComponent(0.28))

let outline = color(0x5b2a22)
let crab = color(0xcf6f59)
let crabDark = color(0xb95745)
let claw = color(0xdc7b62)
let blush = color(0xf45aa5)
let cream = color(0xffefb7)
let black = color(0x0b0b0b)
let red = color(0xe33e39)
let redDark = color(0x9f2424)
let gold = color(0xffc857)
let white = color(0xfffbef)

// Raised arm and alarm clock support.
rect(42, 20, 5, 4, outline)
rect(43, 18, 5, 5, claw)
rect(46, 15, 4, 4, claw)
rect(48, 14, 3, 2, outline)

// Alarm clock.
rect(38, 10, 18, 18, outline)
rect(39, 11, 16, 16, red)
rect(42, 14, 10, 10, white)
rect(44, 16, 6, 6, cream)
rect(45, 6, 5, 4, outline)
rect(46, 5, 3, 3, red)
rect(36, 8, 6, 4, outline)
rect(37, 7, 4, 3, red)
rect(52, 8, 6, 4, outline)
rect(53, 7, 4, 3, red)
rect(41, 28, 4, 3, redDark)
rect(50, 28, 4, 3, redDark)
rect(47, 16, 1, 5, black)
rect(47, 20, 4, 1, black)
pixel(40, 12, gold)
pixel(53, 12, gold)

// Motion sparks.
rect(30, 8, 2, 2, gold)
rect(33, 13, 1, 3, white)
rect(58, 17, 2, 2, white)
rect(56, 23, 3, 1, gold)

// Clawd body outline and body.
rect(10, 29, 36, 23, outline)
rect(12, 27, 32, 24, crab)
rect(13, 51, 5, 7, crabDark)
rect(22, 51, 5, 7, crabDark)
rect(36, 51, 5, 7, crabDark)
rect(45, 51, 5, 7, crabDark)

// Left claw.
rect(5, 34, 8, 8, outline)
rect(4, 35, 8, 6, claw)
rect(1, 34, 5, 3, claw)
rect(1, 39, 5, 3, claw)

// Right raised shoulder.
rect(44, 30, 8, 6, outline)
rect(44, 29, 7, 6, claw)

// Face.
rect(18, 35, 3, 3, black)
rect(34, 35, 3, 3, black)
rect(16, 43, 5, 4, blush)
rect(34, 43, 5, 4, blush)
pixel(19, 35, color(0xffffff))
pixel(35, 35, color(0xffffff))

// Pixel highlights and shadow.
rect(14, 29, 12, 2, color(0xe28a72))
rect(43, 32, 2, 13, crabDark)
rect(16, 58, 36, 3, color(0x247b96).withAlphaComponent(0.24))

image.unlockFocus()

guard
  let tiffData = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiffData),
  let pngData = bitmap.representation(using: .png, properties: [:])
else {
  fatalError("Unable to render icon")
}

try FileManager.default.createDirectory(at: pngURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try pngData.write(to: pngURL)

func makePNGData(for targetSize: CGFloat) -> Data {
  let resized = NSImage(size: NSSize(width: targetSize, height: targetSize))
  resized.lockFocus()
  NSGraphicsContext.current?.imageInterpolation = .none
  image.draw(
    in: NSRect(x: 0, y: 0, width: targetSize, height: targetSize),
    from: NSRect(x: 0, y: 0, width: size, height: size),
    operation: .copy,
    fraction: 1
  )
  resized.unlockFocus()

  guard
    let data = resized.tiffRepresentation,
    let rep = NSBitmapImageRep(data: data),
    let png = rep.representation(using: .png, properties: [:])
  else {
    fatalError("Unable to render \(targetSize)px icon")
  }
  return png
}

func appendASCII(_ string: String, to data: inout Data) {
  data.append(string.data(using: .ascii)!)
}

func appendUInt32BE(_ value: UInt32, to data: inout Data) {
  data.append(UInt8((value >> 24) & 0xff))
  data.append(UInt8((value >> 16) & 0xff))
  data.append(UInt8((value >> 8) & 0xff))
  data.append(UInt8(value & 0xff))
}

let iconBlocks: [(type: String, data: Data)] = [
  ("icp4", makePNGData(for: 16)),
  ("icp5", makePNGData(for: 32)),
  ("icp6", makePNGData(for: 64)),
  ("ic07", makePNGData(for: 128)),
  ("ic08", makePNGData(for: 256)),
  ("ic09", makePNGData(for: 512)),
  ("ic10", pngData)
]

var icnsData = Data()
let totalLength = UInt32(8 + iconBlocks.reduce(0) { $0 + 8 + $1.data.count })
appendASCII("icns", to: &icnsData)
appendUInt32BE(totalLength, to: &icnsData)
for block in iconBlocks {
  appendASCII(block.type, to: &icnsData)
  appendUInt32BE(UInt32(8 + block.data.count), to: &icnsData)
  icnsData.append(block.data)
}
try icnsData.write(to: icnsURL)

print("Generated \(pngURL.path)")
print("Generated \(icnsURL.path)")
