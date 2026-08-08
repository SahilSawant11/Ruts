import AppKit

let outputDir = "/Users/sahil/RutsXoxo/Ruts/macos/Runner/Assets.xcassets/AppIcon.appiconset"
let masterPath = "/Users/sahil/RutsXoxo/Ruts/assets/branding/caskly_app_icon_master.png"
let fontPath = "/Users/sahil/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"

let iconCodePoint: UniChar = 0xE38C // Icons.local_bar
let backgroundColor = NSColor.white
let glyphColor = NSColor(
  calibratedRed: 0x16 / 255.0,
  green: 0x16 / 255.0,
  blue: 0x1F / 255.0,
  alpha: 1.0
)
let shadowColor = NSColor(
  calibratedWhite: 0.0,
  alpha: 0.08
)

let sizes = [16, 32, 64, 128, 256, 512, 1024]

func makeRoundedRectPath(in rect: CGRect, radius: CGFloat) -> NSBezierPath {
  return NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func cgImage(from image: NSImage) -> CGImage? {
  var proposedRect = CGRect(origin: .zero, size: image.size)
  return image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
}

func writePNG(rep: NSBitmapImageRep, to path: String) throws {
  guard let data = rep.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "IconGen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"])
  }
  try data.write(to: URL(fileURLWithPath: path))
}

guard let fontData = NSData(contentsOfFile: fontPath) as Data?,
      let provider = CGDataProvider(data: fontData as CFData),
      let cgFont = CGFont(provider),
      CTFontManagerRegisterGraphicsFont(cgFont, nil) || true else {
  fatalError("Unable to load MaterialIcons font from \(fontPath)")
}

let materialFont = NSFont(name: "Material Icons", size: 580) ?? NSFont(name: "MaterialIcons-Regular", size: 580)
guard let iconFont = materialFont else {
  fatalError("Unable to instantiate Material Icons font")
}

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

for size in sizes {
  let rect = CGRect(x: 0, y: 0, width: size, height: size)
  guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ) else {
    fatalError("Unable to create bitmap rep for \(size)x\(size)")
  }

  rep.size = NSSize(width: size, height: size)
  NSGraphicsContext.saveGraphicsState()
  guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("Unable to create graphics context for \(size)x\(size)")
  }
  NSGraphicsContext.current = context
  context.imageInterpolation = .high

  shadowColor.setFill()
  let shadowRect = rect.insetBy(dx: CGFloat(size) * 0.035, dy: CGFloat(size) * 0.04)
    .offsetBy(dx: 0, dy: -CGFloat(size) * 0.012)
  makeRoundedRectPath(in: shadowRect, radius: CGFloat(size) * 0.22).fill()

  backgroundColor.setFill()
  makeRoundedRectPath(in: rect.insetBy(dx: CGFloat(size) * 0.02, dy: CGFloat(size) * 0.02), radius: CGFloat(size) * 0.22).fill()

  let iconString = NSString(characters: [iconCodePoint], length: 1)
  let fontSize = CGFloat(size) * 0.46
  let attrs: [NSAttributedString.Key: Any] = [
    .font: iconFont.withSize(fontSize),
    .foregroundColor: glyphColor,
    .paragraphStyle: paragraph,
  ]
  let attrString = NSAttributedString(string: iconString as String, attributes: attrs)
  let bounds = attrString.boundingRect(
    with: NSSize(width: CGFloat(size), height: CGFloat(size)),
    options: [.usesLineFragmentOrigin, .usesFontLeading]
  )

  let drawRect = CGRect(
    x: 0,
    y: (CGFloat(size) - bounds.height) / 2.0 - CGFloat(size) * 0.02,
    width: CGFloat(size),
    height: bounds.height
  )
  attrString.draw(in: drawRect)
  NSGraphicsContext.restoreGraphicsState()

  let outputName = "app_icon_\(size).png"
  try writePNG(rep: rep, to: "\(outputDir)/\(outputName)")

  if size == 1024 {
    try writePNG(rep: rep, to: masterPath)
  }
}

print("Generated icon set and master icon.")
