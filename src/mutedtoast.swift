// mutedtoast: shows a silent, click-through "Muted" HUD (like the macOS brightness/volume overlay) for ~3 s, then exits.
// usage: mutedtoast [left top right bottom]
//   With the Meet window's bounds (global, top-left origin, as Chrome's AppleScript reports them) the HUD sits
//   centred on that window just above Meet's control bar; every other screen gets it at a fixed spot near the bottom.
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // no Dock icon, never steals focus

let hudSize = NSSize(width: 150, height: 150)
let aboveBottom: CGFloat = 100  // clears Meet's ~80 px control bar

func makeHUD(at origin: NSPoint) -> NSPanel {
  let panel = NSPanel(contentRect: NSRect(origin: origin, size: hudSize), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
  panel.level = .statusBar
  panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
  panel.ignoresMouseEvents = true
  panel.isOpaque = false
  panel.backgroundColor = .clear
  panel.hasShadow = true

  let hud = NSVisualEffectView(frame: NSRect(origin: .zero, size: hudSize))
  hud.material = .hudWindow
  hud.state = .active
  // Round with a mask image, not layer.cornerRadius: the blur and the window shadow follow the mask, so the corners stay clean.
  let radius: CGFloat = 18
  let mask = NSImage(size: NSSize(width: radius * 2 + 1, height: radius * 2 + 1), flipped: false) { rect in
    NSColor.black.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    return true
  }
  mask.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
  mask.resizingMode = .stretch
  hud.maskImage = mask

  let cfg = NSImage.SymbolConfiguration(pointSize: 48, weight: .semibold).applying(.init(paletteColors: [.systemRed]))
  let icon = NSImageView(image: NSImage(systemSymbolName: "mic.slash.fill", accessibilityDescription: "Muted")!.withSymbolConfiguration(cfg)!)
  let label = NSTextField(labelWithString: "Muted")
  label.font = .systemFont(ofSize: 15, weight: .semibold)
  label.textColor = .labelColor
  let stack = NSStackView(views: [icon, label])
  stack.orientation = .vertical
  stack.spacing = 10
  stack.translatesAutoresizingMaskIntoConstraints = false
  hud.addSubview(stack)
  NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo: hud.centerXAnchor), stack.centerYAnchor.constraint(equalTo: hud.centerYAnchor)])

  panel.contentView = hud
  panel.invalidateShadow()
  panel.alphaValue = 0
  panel.orderFrontRegardless()
  return panel
}

var origins: [NSPoint] = []
var meetScreen: NSScreen? = nil
let args = CommandLine.arguments.dropFirst().compactMap { Double($0) }
if args.count == 4 {
  // Chrome bounds are top-left origin relative to the primary screen; Cocoa is bottom-left.
  let primaryHeight = NSScreen.screens[0].frame.height
  let (left, right, bottom) = (CGFloat(args[0]), CGFloat(args[2]), CGFloat(args[3]))
  let centre = NSPoint(x: (left + right) / 2, y: primaryHeight - bottom + aboveBottom + hudSize.height / 2)
  origins.append(NSPoint(x: centre.x - hudSize.width / 2, y: centre.y - hudSize.height / 2))
  meetScreen = NSScreen.screens.first { $0.frame.contains(centre) }
}
for screen in NSScreen.screens where screen != meetScreen {
  origins.append(NSPoint(x: screen.visibleFrame.midX - hudSize.width / 2, y: screen.visibleFrame.minY + aboveBottom))
}

let panels = origins.map(makeHUD)
NSAnimationContext.runAnimationGroup { $0.duration = 0.2; panels.forEach { $0.animator().alphaValue = 1 } }
DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
  NSAnimationContext.runAnimationGroup({ $0.duration = 0.4; panels.forEach { $0.animator().alphaValue = 0 } }, completionHandler: { exit(0) })
}
app.run()
