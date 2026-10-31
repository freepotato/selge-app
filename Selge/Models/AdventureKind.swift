import Foundation

/// 历险类别结算方式
enum AdventureKind: String, Codable, CaseIterable {
    /// 计时型：按单位时间累积经验（如散步 1 xp/min）
    case time
    /// 难度型：一次性结算（如指弹 500 xp/次）
    case once

    var label: String { self == .time ? "计时" : "单次" }
}

/// 预置类别固定 ID（保证种子数据幂等，且与后续云端同步兼容）
enum SeedCategory {
    static let walk = UUID(uuidString: "5A1E3B10-0001-4A6B-9E01-A2C4E6F80101")!
    static let movie = UUID(uuidString: "5A1E3B10-0002-4A6B-9E01-A2C4E6F80202")!
    static let read = UUID(uuidString: "5A1E3B10-0003-4A6B-9E01-A2C4E6F80303")!
    static let guitar = UUID(uuidString: "5A1E3B10-0004-4A6B-9E01-A2C4E6F80404")!
}
