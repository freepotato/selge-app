import Foundation

/// 游戏数值规则（与 Web 端 Selge 保持一致）
enum GameRules {
    /// 最高等级
    static let maxLevel = 9

    /// 升级所需经验：从 n 级升到 n+1 级需要 500 * n²
    /// XP_TABLE[i] = 到达 i 级的累计经验门槛
    static let xpTable: [Int: Int] = {
        var table: [Int: Int] = [1: 0]
        var total = 0
        for i in 2...maxLevel {
            total += 500 * (i - 1) * (i - 1)
            table[i] = total
        }
        return table
    }()

    /// 金币倍率：金币 = 经验 × 1.5（免费版锁死，付费版预留可配置）
    static let defaultCoinMultiplier: Double = 1.5

    /// 等级称谓
    static func levelTitle(_ level: Int) -> String {
        switch level {
        case 9: return "致皇"
        case 8: return "致王"
        case 7: return "致尊"
        case 6: return "致宗"
        case 5: return "致灵"
        case 4: return "大致师"
        case 3: return "致师"
        case 2: return "致者"
        default: return "致徒"
        }
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        for i in (1...maxLevel).reversed() {
            if xp >= (xpTable[i] ?? 0) {
                level = i
                break
            }
        }
        return level
    }

    /// 当前等级内的进度信息
    static func progress(forXP xp: Int) -> (level: Int, title: String, current: Int, needed: Int, fraction: Double) {
        let level = Self.level(forXP: xp)
        if level >= maxLevel {
            return (maxLevel, levelTitle(maxLevel), 1, 1, 1)
        }
        let lower = xpTable[level] ?? 0
        let upper = xpTable[level + 1] ?? lower + 500
        let current = xp - lower
        let needed = upper - lower
        let fraction = needed > 0 ? Double(current) / Double(needed) : 0
        return (level, levelTitle(level), current, needed, min(max(fraction, 0), 1))
    }

    /// 计时型结算经验（分钟 × 每分钟经验，四舍五入）
    static func xp(minutes: Double, perMinute: Double) -> Int {
        Int((minutes * perMinute).rounded())
    }

    /// 金币结算（经验 × 倍率，四舍五入）
    static func coin(forXP xp: Int, multiplier: Double = defaultCoinMultiplier) -> Int {
        Int((Double(xp) * multiplier).rounded())
    }

    /// 连续打卡：今天有记录且昨天也有 → +1；中断 → 重置为 1
    static func nextStreak(lastDay: Date?, newDay: Date, current: Int) -> Int {
        let cal = Calendar.current
        guard let last = lastDay else { return 1 }
        if cal.isDate(last, inSameDayAs: newDay) { return max(current, 1) }
        if cal.isDate(cal.date(byAdding: .day, value: -1, to: newDay)!, inSameDayAs: last) {
            return current + 1
        }
        return 1
    }

    /// 本地日期键 "yyyy-MM-dd"
    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// 热力图颜色档位（GitHub 贡献图风格：0-4 档）
    static func heatLevel(forCount count: Int) -> Int {
        switch count {
        case 0: return 0
        case 1...2: return 1
        case 3...4: return 2
        case 5...6: return 3
        default: return 4
        }
    }
}
