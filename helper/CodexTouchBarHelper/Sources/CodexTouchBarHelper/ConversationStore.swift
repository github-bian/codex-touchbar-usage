import AppKit
import SQLite3

struct Conversation: Equatable {
    enum Status { case active, completed, unknown }
    let id: String
    let title: String
    let status: Status
}

enum ConversationStore {
    static func recent() -> [Conversation] {
        let path = NSHomeDirectory() + "/.codex/state_5.sqlite"
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return []
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 100)
        let query = "SELECT id, COALESCE(NULLIF(name,''),title), rollout_path FROM threads WHERE archived=0 AND source='vscode' AND (thread_source='user' OR thread_source IS NULL) AND attached_thread_parent_id IS NULL AND preview<>'' ORDER BY recency_at_ms DESC LIMIT 50"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }
        var result: [Conversation] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = sqlite3_column_text(statement, 0), let title = sqlite3_column_text(statement, 1), let path = sqlite3_column_text(statement, 2) else { continue }
            let identifier = String(cString: id)
            guard UUID(uuidString: identifier) != nil else { continue }
            let name = String(cString: title).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            result.append(Conversation(id: identifier, title: name, status: status(path: String(cString: path))))
        }
        return result
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    static func status(path: String) -> Conversation.Status {
        guard let file = FileHandle(forReadingAtPath: path) else { return .unknown }
        defer { try? file.close() }
        let size = (try? file.seekToEnd()) ?? 0
        try? file.seek(toOffset: size > 262_144 ? size - 262_144 : 0)
        guard let data = try? file.readToEnd() else { return .unknown }
        let text = String(decoding: data, as: UTF8.self)
        for line in text.split(separator: "\n").reversed() {
            guard let data = line.data(using: .utf8), let event = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], event["type"] as? String == "event_msg", let payload = event["payload"] as? [String: Any], let type = payload["type"] as? String else { continue }
            if type == "task_complete" { return .completed }
            if type == "turn_aborted" || type == "task_failed" { return .unknown }
            if type == "task_started" {
                // shortcut: old starts may belong to a crashed process; show unknown until live status is available.
                guard let timestamp = event["timestamp"] as? String, let date = parseDate(timestamp), Date().timeIntervalSince(date) < 120 else { return .unknown }
                return .active
            }
        }
        return .unknown
    }
}
