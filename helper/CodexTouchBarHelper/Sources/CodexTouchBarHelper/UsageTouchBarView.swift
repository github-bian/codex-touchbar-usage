import AppKit
import CodexTouchBarCore

private final class ConversationButton: NSButton {
    var conversation: Conversation!
    var selected = false
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let outline = NSBezierPath()
        if selected {
            outline.move(to: NSPoint(x: 11, y: 7))
            outline.curve(to: NSPoint(x: 18, y: 7), controlPoint1: NSPoint(x: 10, y: -1), controlPoint2: NSPoint(x: 14, y: 1))
            outline.line(to: NSPoint(x: bounds.width - 18, y: 7))
            outline.curve(to: NSPoint(x: bounds.width - 11, y: 7), controlPoint1: NSPoint(x: bounds.width - 14, y: 1), controlPoint2: NSPoint(x: bounds.width - 10, y: -1))
            outline.curve(to: NSPoint(x: bounds.width - 2, y: 15), controlPoint1: NSPoint(x: bounds.width - 5, y: 7), controlPoint2: NSPoint(x: bounds.width - 2, y: 10))
            outline.line(to: NSPoint(x: bounds.width - 2, y: 21))
            outline.curve(to: NSPoint(x: bounds.width - 10, y: 28), controlPoint1: NSPoint(x: bounds.width - 2, y: 26), controlPoint2: NSPoint(x: bounds.width - 5, y: 28))
            outline.line(to: NSPoint(x: 10, y: 28))
            outline.curve(to: NSPoint(x: 2, y: 21), controlPoint1: NSPoint(x: 5, y: 28), controlPoint2: NSPoint(x: 2, y: 26))
            outline.line(to: NSPoint(x: 2, y: 15))
            outline.curve(to: NSPoint(x: 11, y: 7), controlPoint1: NSPoint(x: 2, y: 10), controlPoint2: NSPoint(x: 5, y: 7))
            outline.close()
        } else {
            outline.appendRoundedRect(NSRect(x: 2, y: 5, width: bounds.width - 4, height: 23), xRadius: 8, yRadius: 8)
        }
        (selected ? NSColor(white: 0.78, alpha: 1) : NSColor(white: 0.38, alpha: 1)).setStroke()
        outline.lineWidth = 1
        outline.stroke()
        if selected {
            NSColor.systemTeal.setFill()
            NSBezierPath(roundedRect: NSRect(x: 28, y: 6, width: bounds.width - 56, height: 1.5), xRadius: 0.75, yRadius: 0.75).fill()
        }
        let statusColor: NSColor = conversation.status == .active ? .systemBlue : conversation.status == .completed ? .systemGreen : .secondaryLabelColor
        statusColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 9, y: 14, width: 5, height: 5)).fill()
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        (conversation.title as NSString).draw(in: NSRect(x: 19, y: 9, width: bounds.width - (selected ? 42 : 27), height: 17), withAttributes: [.font: NSFont.systemFont(ofSize: 11, weight: .medium), .foregroundColor: NSColor.white, .paragraphStyle: style])
        if selected {
            NSColor.systemTeal.setFill()
            let x = bounds.width - 17
            NSBezierPath(ovalIn: NSRect(x: x, y: 15, width: 7, height: 5)).fill()
            for dx: CGFloat in [0, 3, 6] { NSBezierPath(ovalIn: NSRect(x: x - 0.5 + dx, y: 11.5, width: 2.5, height: 3)).fill() }
        }
    }
}

final class UsageTouchBarView: NSView {
    var snapshot: UsageSnapshot? = .placeholder { didSet { errorMessage = nil; needsDisplay = true } }
    var errorMessage: String? { didSet { needsDisplay = true } }
    var conversations: [Conversation] = [] { didSet { if oldValue != conversations { updateButtons() } } }
    override var isFlipped: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 720, height: 30) }
    private let scroll = NSScrollView(frame: NSRect(x: 256, y: 0, width: 464, height: 30))
    private let content = NSView(frame: NSRect(x: 0, y: 0, width: 464, height: 30))
    var selectedID: String? { didSet { if oldValue != selectedID { updateButtons() } } }

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
            let button = ConversationButton(frame: NSRect(x: x, y: 0, width: 104, height: 30))
            button.isBordered = false
            button.conversation = conversation
            button.selected = conversation.id == selectedID
            button.setAccessibilityLabel(conversation.title)
            button.identifier = NSUserInterfaceItemIdentifier(conversation.id)
            button.target = self
            button.action = #selector(openConversation(_:))
            content.addSubview(button)
            x += 110
        }
        content.frame.size.width = max(scroll.contentSize.width, x)
    }

    @objc private func openConversation(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue, UUID(uuidString: id) != nil, let url = URL(string: "codex://threads/\(id)") else { return }
        if NSWorkspace.shared.open(url) { selectedID = id }
    }
}
