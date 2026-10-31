import Foundation

/// 解析打包进 App 的 docs/CHANGELOG.md（release-please 生成格式）
enum ChangelogParser {
    struct Entry: Identifiable, Hashable {
        let version: String
        let date: String
        let bullets: [String]
        var id: String { version + date }
    }

    /// 解析 Markdown，返回按版本倒序的条目
    /// - Parameters:
    ///   - maxEntries: 最多展示的版本数
    ///   - maxBulletsPerEntry: 每个版本最多展示的条目数（保持日志精炼）
    static func parse(_ markdown: String, maxEntries: Int = 10, maxBulletsPerEntry: Int = 6) -> [Entry] {
        var entries: [Entry] = []
        var currentVersion: String?
        var currentDate = ""
        var currentBullets: [String] = []

        func flush() {
            if let version = currentVersion, !currentBullets.isEmpty {
                entries.append(Entry(version: version, date: currentDate, bullets: Array(currentBullets.prefix(maxBulletsPerEntry))))
            }
            currentBullets = []
        }

        for rawLine in markdown.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            // release-please 输出: "## 0.1.0 (2026-10-31)" 或 "## [0.1.0](url) (2026-10-31)"
            if line.hasPrefix("## ") {
                flush()
                let header = String(line.dropFirst(3))
                let cleaned = header
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .split(separator: "(")
                    .first.map { $0.trimmingCharacters(in: .whitespaces) } ?? header
                let parts = cleaned.split(separator: " ", maxSplits: 1)
                currentVersion = parts.count > 0 ? String(parts[0]) : cleaned
                currentDate = parts.count > 1 ? String(parts[1]) : ""
                continue
            }
            guard currentVersion != nil, line.hasPrefix("- ") else { continue }
            let bullet = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            if !bullet.isEmpty { currentBullets.append(bullet) }
        }
        flush()

        return Array(entries.prefix(maxEntries))
    }

    static func bundledEntries() -> [Entry] {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parse(markdown)
    }
}
