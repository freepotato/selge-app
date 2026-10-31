import Foundation
import SwiftData

/// 一次历险结算的结果（用于结算页展示）
struct SettlementResult {
    let categoryName: String
    let emoji: String
    let minutes: Double
    let xp: Int
    let coin: Int
    let beforeLevel: Int
    let afterLevel: Int
    let streak: Int
    let newAchievements: [AchievementDef]
}

/// 商品购买结果
enum PurchaseOutcome {
    case success(PurchasedItem)
    case insufficientFunds
}

/// 游戏状态操作层：负责种子数据、结算、购买、消耗、成就检测等业务逻辑。
/// 视图通过 @Query 响应式读取数据，通过本对象执行写操作。
@Observable
@MainActor
final class GameStore {
    let context: ModelContext
    let config: AppConfig

    init(context: ModelContext, config: AppConfig = .shared) {
        self.context = context
        self.config = config
        seedIfNeeded()
    }

    // MARK: - 种子数据

    /// 首次启动：创建勇者、预置 4 类别、预置商品
    private func seedIfNeeded() {
        let heroFetch = FetchDescriptor<HeroProfile>()
        let heroCount = (try? context.fetchCount(heroFetch)) ?? 0
        if heroCount == 0 {
            context.insert(HeroProfile())
        }

        let categoryFetch = FetchDescriptor<AdventureCategory>()
        let categoryCount = (try? context.fetchCount(categoryFetch)) ?? 0
        if categoryCount == 0 {
            context.insert(Self.seedCategory(id: SeedCategory.walk, emoji: "🚶", name: "散步", kind: .time, xpPerMinute: 1, baseXP: 0, order: 0))
            context.insert(Self.seedCategory(id: SeedCategory.movie, emoji: "🎬", name: "电影", kind: .time, xpPerMinute: 0.32, baseXP: 0, order: 1))
            context.insert(Self.seedCategory(id: SeedCategory.read, emoji: "📚", name: "读书", kind: .time, xpPerMinute: 0.5, baseXP: 0, order: 2))
            context.insert(Self.seedCategory(id: SeedCategory.guitar, emoji: "🎸", name: "指弹", kind: .once, xpPerMinute: 0, baseXP: 500, order: 3))
        }

        let shopFetch = FetchDescriptor<ShopItem>()
        let shopCount = (try? context.fetchCount(shopFetch)) ?? 0
        if shopCount == 0 {
            for (index, seed) in ShopCatalog.defaults.enumerated() {
                let item = ShopItem()
                item.itemKey = seed.id
                item.emoji = seed.emoji
                item.name = seed.name
                item.itemDescription = seed.desc
                item.priceCoin = seed.price
                item.sortOrder = index
                context.insert(item)
            }
        }

        try? context.save()
    }

    private static func seedCategory(id: UUID, emoji: String, name: String, kind: AdventureKind, xpPerMinute: Double, baseXP: Int, order: Int) -> AdventureCategory {
        let category = AdventureCategory()
        category.id = id
        category.emoji = emoji
        category.name = name
        category.kind = kind
        category.xpPerMinute = xpPerMinute
        category.baseXP = baseXP
        category.sortOrder = order
        return category
    }

    // MARK: - 查询辅助

    func hero() -> HeroProfile? {
        var fetch = FetchDescriptor<HeroProfile>(sortBy: [SortDescriptor(\.createdAt)])
        fetch.fetchLimit = 1
        return try? context.fetch(fetch).first
    }

    func categories() -> [AdventureCategory] {
        let fetch = FetchDescriptor<AdventureCategory>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
        return (try? context.fetch(fetch)) ?? []
    }

    /// 各成就分组的完成计数（walk/movie/read/guitar 按类别名聚合，adventure 为总数）
    func groupCounts(records: [AdventureRecord], categories: [AdventureCategory]) -> [String: Int] {
        var counts: [String: Int] = [:]
        let nameToGroup: [String: String] = ["散步": "walk", "电影": "movie", "读书": "read", "指弹": "guitar"]
        for record in records {
            if let group = nameToGroup[record.categoryName] {
                counts[group, default: 0] += 1
            }
        }
        counts["adventure"] = records.count
        return counts
    }

    // MARK: - 历险结算

    /// 计时型结算
    func settle(category: AdventureCategory, startedAt: Date, endedAt: Date) -> SettlementResult {
        let minutes = max(0, endedAt.timeIntervalSince(startedAt) / 60)
        return settle(category: category, minutes: minutes, startedAt: startedAt, endedAt: endedAt)
    }

    /// 难度型（单次）结算
    func settleOnce(category: AdventureCategory) -> SettlementResult {
        settle(category: category, minutes: 0, startedAt: nil, endedAt: Date.now)
    }

    private func settle(category: AdventureCategory, minutes: Double, startedAt: Date?, endedAt: Date) -> SettlementResult {
        let hero = hero()
        let xp: Int
        switch category.kind {
        case .time:
            xp = GameRules.xp(minutes: minutes, perMinute: category.xpPerMinute)
        case .once:
            xp = category.baseXP
        }
        let coin = GameRules.coin(forXP: xp, multiplier: config.coinMultiplier)
        let beforeLevel = GameRules.level(forXP: hero?.xp ?? 0)

        // 1. 写入历险记录
        let record = AdventureRecord()
        record.categoryId = category.id
        record.categoryName = category.name
        record.emoji = category.emoji
        record.kindRaw = category.kindRaw
        record.xp = xp
        record.coin = coin
        record.minutes = category.kind == .time ? minutes : 0
        record.startedAt = startedAt
        record.endedAt = endedAt
        record.dayKey = GameRules.dayKey(for: endedAt)
        context.insert(record)

        // 2. 更新勇者经验/金币/连续打卡
        if let hero {
            hero.xp += xp
            hero.coin += coin
            let day = endedAt
            hero.streak = GameRules.nextStreak(lastDay: hero.lastAdventureDay, newDay: day, current: hero.streak)
            hero.lastAdventureDay = day
            hero.updatedAt = Date.now
        }

        // 3. 写入收支流水
        let transaction = AccountTransaction()
        transaction.at = endedAt
        transaction.xpDelta = xp
        transaction.coinDelta = coin
        transaction.reason = category.kind == .time
            ? "\(category.name) · \(Int(minutes.rounded())) 分钟"
            : "\(category.name) · 单次"
        transaction.dayKey = record.dayKey
        context.insert(transaction)

        // 4. 成就检测
        let newAchievements = checkAchievements(at: endedAt)

        try? context.save()

        return SettlementResult(
            categoryName: category.name,
            emoji: category.emoji,
            minutes: minutes,
            xp: xp,
            coin: coin,
            beforeLevel: beforeLevel,
            afterLevel: GameRules.level(forXP: hero?.xp ?? 0),
            streak: hero?.streak ?? 0,
            newAchievements: newAchievements
        )
    }

    // MARK: - 成就

    /// 检测并写入新解锁的成就，返回本次新解锁列表
    @discardableResult
    func checkAchievements(at date: Date = Date.now) -> [AchievementDef] {
        let records = (try? context.fetch(FetchDescriptor<AdventureRecord>())) ?? []
        let categories = categories()
        let counts = groupCounts(records: records, categories: categories)
        let unlockedIds = Set(unlockedAchievementIds())
        var newly: [AchievementDef] = []

        for def in AchievementCatalog.all {
            guard !unlockedIds.contains(def.id) else { continue }
            let count = counts[def.group] ?? 0
            if count >= def.requirement {
                let unlock = AchievementUnlock()
                unlock.achievementId = def.id
                unlock.group = def.group
                unlock.unlockedAt = date
                context.insert(unlock)
                newly.append(def)
            }
        }
        return newly
    }

    func unlockedAchievementIds() -> [String] {
        let fetch = FetchDescriptor<AchievementUnlock>()
        return ((try? context.fetch(fetch)) ?? []).map(\.achievementId)
    }

    func unlockedMap() -> [String: Date] {
        let fetch = FetchDescriptor<AchievementUnlock>()
        var map: [String: Date] = [:]
        for unlock in (try? context.fetch(fetch)) ?? [] {
            map[unlock.achievementId] = unlock.unlockedAt
        }
        return map
    }

    // MARK: - 商店

    func shopItems() -> [ShopItem] {
        let fetch = FetchDescriptor<ShopItem>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? context.fetch(fetch)) ?? []
    }

    func purchase(item: ShopItem) -> PurchaseOutcome {
        guard let hero = hero() else { return .insufficientFunds }
        guard hero.coin >= item.priceCoin else { return .insufficientFunds }

        hero.coin -= item.priceCoin
        hero.updatedAt = Date.now

        let purchased = PurchasedItem()
        purchased.itemKey = item.itemKey
        purchased.name = item.name
        purchased.emoji = item.emoji
        purchased.priceCoin = item.priceCoin
        context.insert(purchased)

        let transaction = AccountTransaction()
        transaction.at = Date.now
        transaction.xpDelta = 0
        transaction.coinDelta = -item.priceCoin
        transaction.reason = "购买 \(item.name)"
        transaction.dayKey = GameRules.dayKey(for: Date.now)
        context.insert(transaction)

        try? context.save()
        return .success(purchased)
    }

    // MARK: - 背包

    func backpackItems() -> [PurchasedItem] {
        let fetch = FetchDescriptor<PurchasedItem>(sortBy: [SortDescriptor(\.purchasedAt, order: .reverse)])
        return (try? context.fetch(fetch)) ?? []
    }

    /// 消耗背包物品
    func consume(item: PurchasedItem) {
        guard !item.isConsumed else { return }
        item.isConsumed = true
        item.consumedAt = Date.now

        let transaction = AccountTransaction()
        transaction.at = Date.now
        transaction.xpDelta = 0
        transaction.coinDelta = 0
        transaction.reason = "消耗 \(item.name)"
        transaction.dayKey = GameRules.dayKey(for: Date.now)
        context.insert(transaction)

        try? context.save()
    }

    // MARK: - 账户明细

    func recentTransactions(limit: Int = 30) -> [AccountTransaction] {
        var fetch = FetchDescriptor<AccountTransaction>(sortBy: [SortDescriptor(\.at, order: .reverse)])
        fetch.fetchLimit = limit
        return (try? context.fetch(fetch)) ?? []
    }

    // MARK: - 设置：类别管理

    func addCategory(emoji: String, name: String, kind: AdventureKind, xpPerMinute: Double, baseXP: Int) {
        let order = (categories().map(\.sortOrder).max() ?? -1) + 1
        let category = AdventureCategory()
        category.emoji = emoji.isEmpty ? "✨" : emoji
        category.name = name
        category.kind = kind
        category.xpPerMinute = xpPerMinute
        category.baseXP = baseXP
        category.sortOrder = order
        context.insert(category)
        try? context.save()
    }

    func deleteCategory(_ category: AdventureCategory) {
        context.delete(category)
        try? context.save()
    }
}
