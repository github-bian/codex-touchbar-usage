import AppKit
import CodexTouchBarCore

final class UsageTouchBarView: NSView {
    var snapshot: UsageSnapshot? = .placeholder { didSet { errorMessage = nil; needsDisplay = true } }
    var errorMessage: String? { didSet { needsDisplay = true } }
    var conversations: [Conversation] = [] { didSet { if oldValue != conversations { updateButtons() } } }
    override var isFlipped: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 720, height: 30) }
    private let scroll = NSScrollView(frame: NSRect(x: 256, y: 0, width: 464, height: 30))
    private let content = NSView(frame: NSRect(x: 0, y: 0, width: 464, height: 30))
    private var selectedID: String?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        alphaValue = 0
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.autohidesScrollers = true
        scroll.documentView = content
        addSubview(scroll)
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let s = snapshot ?? .placeholder
        let white = NSColor(white: 0.95, alpha: 1)
        let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        let mono = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let badge = NSBezierPath(roundedRect: NSRect(x: 3, y: 4, width: 49, height: 22), xRadius: 11, yRadius: 11)
        NSColor.systemTeal.setStroke()
        badge.lineWidth = 1.2
        badge.stroke()
        let ticket = NSBezierPath()
        ticket.move(to: NSPoint(x: 11, y: 9))
        ticket.line(to: NSPoint(x: 24, y: 9))
        ticket.line(to: NSPoint(x: 24, y: 12))
        ticket.curve(to: NSPoint(x: 24, y: 18), controlPoint1: NSPoint(x: 21, y: 12), controlPoint2: NSPoint(x: 21, y: 18))
        ticket.line(to: NSPoint(x: 24, y: 21))
        ticket.line(to: NSPoint(x: 11, y: 21))
        ticket.line(to: NSPoint(x: 11, y: 18))
        ticket.curve(to: NSPoint(x: 11, y: 12), controlPoint1: NSPoint(x: 14, y: 18), controlPoint2: NSPoint(x: 14, y: 12))
        ticket.close()
        ticket.lineWidth = 1.2
        ticket.lineJoinStyle = .round
        ticket.stroke()
        text(s.resetCreditsAvailable.map(String.init) ?? "—", x: 29, width: 21, font: font, color: white)
        let center = NSPoint(x: 70, y: 15)
        let radius: CGFloat = 8
        let track = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        track.lineWidth = 3
        NSColor(white: 0.24, alpha: 1).setStroke()
        track.stroke()
        if let remaining = UsageFormatting.remainingPercent(usedPercent: s.primary?.usedPercent) {
            let fraction = max(0, min(100, remaining)) / 100
            let progress = NSBezierPath()
            progress.lineWidth = 3
            progress.lineCapStyle = .round
            if fraction >= 1 {
                progress.appendOval(in: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            } else if fraction > 0 {
                progress.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - CGFloat(fraction) * 360, clockwise: true)
            }
            (remaining <= 10 ? NSColor.systemRed : remaining <= 30 ? NSColor.systemOrange : NSColor.systemTeal).setStroke()
            progress.stroke()
        }
        text(UsageFormatting.balanceLabel(usedPercent: s.primary?.usedPercent), x: 84, width: 43, font: font, color: white)
        text("◷ " + Self.countdown(s.primary?.resetsAt), x: 133, width: 114, font: mono, color: white)
        NSColor(white: 0.3, alpha: 1).setFill()
        NSRect(x: 250, y: 6, width: 1, height: 18).fill()
    }

    static func countdown(_ timestamp: Int?, now: Date = Date()) -> String {
        guard let timestamp else { return "--:--:--" }
        let seconds = max(0, timestamp - Int(now.timeIntervalSince1970))
        if seconds >= 86400 { return "\(seconds / 86400)天 \(String(format: "%02d:%02d", (seconds % 86400) / 3600, (seconds % 3600) / 60))" }
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    private func text(_ value: String, x: CGFloat, width: CGFloat, font: NSFont, color: NSColor) {
        (value as NSString).draw(in: NSRect(x: x, y: 7, width: width, height: 18), withAttributes: [.font: font, .foregroundColor: color])
    }

    private func updateButtons() {
        content.subviews.forEach { $0.removeFromSuperview() }
        var x: CGFloat = 0
        for conversation in conversations {
            let button = NSButton(frame: NSRect(x: x, y: 3, width: 126, height: 24))
            button.isBordered = false
            button.wantsLayer = true
            button.layer?.backgroundColor = NSColor(white: 0.15, alpha: 1).cgColor
            button.layer?.cornerRadius = 12
            button.layer?.borderWidth = conversation.id == selectedID ? 1 : 0
            button.layer?.borderColor = NSColor.systemBlue.cgColor
            let dot = conversation.status == .active ? "● " : conversation.status == .completed ? "✓ " : "• "
            let color: NSColor = conversation.status == .active ? .systemBlue : conversation.status == .completed ? .systemGreen : .secondaryLabelColor
            let title = NSMutableAttributedString(string: dot, attributes: [.foregroundColor: color, .font: NSFont.systemFont(ofSize: 11, weight: .bold)])
            title.append(NSAttributedString(string: conversation.title, attributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 11, weight: .medium)]))
            button.attributedTitle = title
            button.lineBreakMode = .byTruncatingTail
            button.identifier = NSUserInterfaceItemIdentifier(conversation.id)
            button.target = self
            button.action = #selector(openConversation(_:))
            content.addSubview(button)
            x += 132
        }
        content.frame.size.width = max(scroll.contentSize.width, x)
    }

    @objc private func openConversation(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue, UUID(uuidString: id) != nil, let url = URL(string: "codex://threads/\(id)") else { return }
        if NSWorkspace.shared.open(url) { selectedID = id; updateButtons() }
    }
}
