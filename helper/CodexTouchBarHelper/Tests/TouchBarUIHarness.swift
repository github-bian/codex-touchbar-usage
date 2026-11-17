import AppKit
import CodexTouchBarCore

@main
struct TouchBarUIHarness {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let tokens: Set<String> = ["Codex", "ChatGPT", "com.openai.codex"]
        precondition(ForegroundTarget.resolve(bundleIdentifier: "dev.zcode.app", candidates: ["ChatGPT"], codexTokens: tokens) == .zcode)
        precondition(ForegroundTarget.resolve(bundleIdentifier: "com.openai.codex", candidates: ["ZCode"], codexTokens: tokens) == .codex)
        precondition(ForegroundTarget.resolve(bundleIdentifier: "com.apple.Terminal", candidates: ["Terminal"], codexTokens: tokens) == .none)
        precondition(ForegroundTarget.resolve(bundleIdentifier: nil, candidates: ["ChatGPT"], codexTokens: tokens) == .codex)
        let controller = TouchBarController(usesSystemTouchBar: false)
        var timings: [Double] = []
        for _ in 0..<100 {
            let start = CFAbsoluteTimeGetCurrent()
            controller.show(for: .codex)
            controller.show(for: .zcode)
            controller.hideAnimated()
            controller.show(for: .codex)
            timings.append((CFAbsoluteTimeGetCurrent() - start) * 1000)
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.7))
        precondition(controller.isPresented && controller.target == .codex, "late hide must not dismiss current panel")
        controller.hideAnimated()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        precondition(!controller.isPresented)
        timings.sort()
        print("100 rapid synthetic target cycles: PASS; p95 dispatch ms=\(timings[94]) (system presentation disabled)")

        let directory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "/tmp/codex-touchbar-preview")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let codex = UsageTouchBarView(frame: NSRect(x: 0, y: 0, width: 720, height: 30))
        codex.alphaValue = 1
        var original = UsageSnapshot.placeholder
        original.primary = LimitWindow(name: "codex", usedPercent: 39, windowMinutes: 10080, resetsAt: Int(Date().timeIntervalSince1970) + 9378)
        original.resetCreditsAvailable = 3
        original.resetCreditsExpiresAt = 1785109710
        original.yesterdayTokens = 791733914
        original.cumulativeTokens = 15439107907
        original.source = "app-server"
        codex.snapshot = original
        precondition(UsageTouchBarView.countdown(3_661, now: Date(timeIntervalSince1970: 0)) == "01:01:01")
        precondition(UsageTouchBarView.countdown(0, now: Date(timeIntervalSince1970: 10)) == "00:00:00")
        precondition(UsageTouchBarView.countdown(nil) == "--:--:--")
        let events = directory.appendingPathComponent("events.jsonl")
        try "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}\n".write(to: events, atomically: true, encoding: .utf8)
        precondition(ConversationStore.status(path: events.path) == .completed)
        try "{\"type\":\"event_msg\",\"payload\":{\"type\":\"turn_aborted\"}}\n".write(to: events, atomically: true, encoding: .utf8)
        precondition(ConversationStore.status(path: events.path) == .unknown)
        precondition(ConversationStore.status(path: events.path + ".missing") == .unknown)
        codex.conversations = [
            Conversation(id: UUID().uuidString, title: "优化首页", status: .active),
            Conversation(id: UUID().uuidString, title: "修复登录", status: .completed),
            Conversation(id: UUID().uuidString, title: "数据分析", status: .unknown)
        ]
        let scroll = codex.subviews.compactMap { $0 as? NSScrollView }.first!
        let shortStart = scroll.frame.minX
        original.primary?.resetsAt = Int(Date().timeIntervalSince1970) + 123 * 86400
        codex.snapshot = original
        precondition(scroll.frame.minX > shortStart, "longer countdown must reserve more space")
        original.primary?.resetsAt = Int(Date().timeIntervalSince1970) + 9378
        codex.snapshot = original
        precondition(scroll.frame.minX == shortStart, "shorter countdown must release space")
        original.primary?.usedPercent = 0.1
        codex.snapshot = original
        precondition(scroll.frame.minX > shortStart, "longer quota must reserve more space")
        original.primary?.usedPercent = 39
        codex.snapshot = original
        precondition(scroll.frame.minX == shortStart, "shorter quota must release space")
        codex.selectedID = codex.conversations.first?.id
        try render(codex, to: directory.appendingPathComponent("codex.png"))
        let zcode = ZCodeTouchBarView(frame: codex.frame)
        var z = ZCodeUsageSnapshot.placeholder
        z.provider = .go
        z.goRolling = ZCodeQuota(usedPercent: 23, resetsAt: 1788939447)
        z.goWeekly = ZCodeQuota(usedPercent: 81, resetsAt: 1789344000)
        z.goMonthly = ZCodeQuota(usedPercent: 94, resetsAt: 1789004067)
        z.glmPrimary = ZCodeQuota(usedPercent: 27, resetsAt: 1788929097)
        z.glmWeekly = ZCodeQuota(usedPercent: 72, resetsAt: 1789106366)
        z.todayTokens = 12345678
        z.cumulativeTokens = 1234567890
        z.statsReady = true
        zcode.snapshot = z
        try render(zcode, to: directory.appendingPathComponent("go.png"))
        z.provider = .glm
        zcode.snapshot = z
        try render(zcode, to: directory.appendingPathComponent("glm.png"))
        (zcode.subviews.first as? NSButton)?.performClick(nil)
        precondition(zcode.showsDetails)
        try render(zcode, to: directory.appendingPathComponent("details.png"))
        print("Native AppKit rendering: PASS")
    }

    @MainActor static func render(_ view: NSView, to url: URL) throws {
        let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = .black
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { fatalError("bitmap unavailable") }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("PNG unavailable") }
        try data.write(to: url)
    }
}
