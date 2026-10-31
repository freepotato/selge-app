import Foundation
import SwiftData

/// 用户基础信息与等级/经验/金币
/// SwiftData + CloudKit 兼容约束：全部属性可选或带默认值，不使用唯一约束
@Model
final class HeroProfile {
    var id: UUID = UUID()
    var name: String = "勇者"
    var xp: Int = 0
    var coin: Int = 0
    var streak: Int = 0
    var lastAdventureDay: Date?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init() {}
}

/// 历险类别（散步 / 电影 / 读书 / 指弹，可由用户在设置中管理）
@Model
final class AdventureCategory {
    var id: UUID = UUID()
    var emoji: String = "✨"
    var name: String = ""
    /// AdventureKind rawValue: time | once
    var kindRaw: String = AdventureKind.time.rawValue
    /// 计时型：每分钟经验
    var xpPerMinute: Double = 0
    /// 难度型：单次经验
    var baseXP: Int = 0
    var sortOrder: Int = 0
    var createdAt: Date = Date.now

    var kind: AdventureKind {
        get { AdventureKind(rawValue: kindRaw) ?? .time }
        set { kindRaw = newValue.rawValue }
    }

    /// 规则描述（列表展示用）
    var ruleDescription: String {
        kind == .time
            ? String(format: "%.2f xp/分钟", xpPerMinute)
            : "\(baseXP) xp/次"
    }

    init() {}
}

/// 历险记录（完成一次历险即生成一条）
@Model
final class AdventureRecord {
    var id: UUID = UUID()
    /// 冗余存储类别信息，类别被删除后记录仍可读，并兼容 CloudKit Web 端直接查询
    var categoryId: UUID?
    var categoryName: String = ""
    var emoji: String = "✨"
    var kindRaw: String = AdventureKind.time.rawValue
    /// 结算经验
    var xp: Int = 0
    /// 结算金币
    var coin: Int = 0
    /// 计时型时长（分钟）
    var minutes: Double = 0
    var note: String?
    var startedAt: Date?
    var endedAt: Date = Date.now
    /// 本地日期键 "yyyy-MM-dd"，热力图与流水分组使用
    var dayKey: String = ""

    var kind: AdventureKind { AdventureKind(rawValue: kindRaw) ?? .time }

    init() {}
}

/// 商店商品元数据（当前预置 5 件，付费版可扩展自定义商品）
@Model
final class ShopItem {
    var id: UUID = UUID()
    /// 商品键，如 "m_ticket"；与 Web 端保持一致
    var itemKey: String = ""
    var emoji: String = "🎁"
    var name: String = ""
    var itemDescription: String = ""
    var priceCoin: Int = 0
    var sortOrder: Int = 0
    var isActive: Bool = true

    init() {}
}

/// 已购物品（背包）
@Model
final class PurchasedItem {
    var id: UUID = UUID()
    var itemKey: String = ""
    var name: String = ""
    var emoji: String = "🎁"
    var priceCoin: Int = 0
    var purchasedAt: Date = Date.now
    var consumedAt: Date?
    var isConsumed: Bool = false

    init() {}
}

/// 账户收支流水（经验 / 金币）
@Model
final class AccountTransaction {
    var id: UUID = UUID()
    var at: Date = Date.now
    /// 经验变动（正为收入，负为支出）
    var xpDelta: Int = 0
    /// 金币变动
    var coinDelta: Int = 0
    /// 说明，如 "散步 · 25 分钟"、"购买 电影票"
    var reason: String = ""
    var dayKey: String = ""
    /// 关联的历险记录 ID（编辑/删除记录时同步调整对应流水）
    var relatedRecordId: UUID?

    init() {}
}

/// 成就解锁状态（成就定义见 AchievementCatalog，云端仅存解锁事实）
@Model
final class AchievementUnlock {
    var id: UUID = UUID()
    /// 成就定义 ID，如 "w1"、"g5"
    var achievementId: String = ""
    /// 成就分组：walk / movie / read / guitar / adventure
    var group: String = ""
    var unlockedAt: Date = Date.now

    init() {}
}
