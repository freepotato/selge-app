import Foundation

/// 成就定义（与 Web 端一致；付费版预留自定义成就扩展点）
struct AchievementDef: Identifiable, Hashable {
    let id: String
    let group: String
    let icon: String
    let name: String
    let desc: String
    let requirement: Int
}

enum AchievementCatalog {
    /// 分组元信息（分段控件顺序）
    static let groups: [(key: String, label: String)] = [
        ("all", "全部"),
        ("adventure", "历险"),
        ("walk", "散步"),
        ("movie", "电影"),
        ("read", "读书"),
        ("guitar", "指弹"),
    ]

    static let all: [AchievementDef] = walk + movie + read + guitar + adventure

    static let walk: [AchievementDef] = [
        .init(id: "w1", group: "walk", icon: "🚶", name: "踏出一步", desc: "第一次散步", requirement: 1),
        .init(id: "w2", group: "walk", icon: "🌿", name: "闲庭信步", desc: "散步 10 次", requirement: 10),
        .init(id: "w3", group: "walk", icon: "🌳", name: "行者", desc: "散步 30 次", requirement: 30),
        .init(id: "w4", group: "walk", icon: "🏞️", name: "自然漫步者", desc: "散步 90 次", requirement: 90),
        .init(id: "w5", group: "walk", icon: "🌍", name: "四季行者", desc: "散步 365 次", requirement: 365),
    ]

    static let movie: [AchievementDef] = [
        .init(id: "m1", group: "movie", icon: "🎬", name: "影迷入门", desc: "看第一部电影", requirement: 1),
        .init(id: "m2", group: "movie", icon: "🎞️", name: "影迷", desc: "看 20 部电影", requirement: 20),
        .init(id: "m3", group: "movie", icon: "🏆", name: "影评达人", desc: "看 50 部电影", requirement: 50),
        .init(id: "m4", group: "movie", icon: "🎥", name: "电影大师", desc: "看 100 部电影", requirement: 100),
        .init(id: "m5", group: "movie", icon: "🌟", name: "银幕传奇", desc: "看 200 部电影", requirement: 200),
    ]

    static let read: [AchievementDef] = [
        .init(id: "r1", group: "read", icon: "📖", name: "开卷有益", desc: "读完第一本书", requirement: 1),
        .init(id: "r2", group: "read", icon: "📚", name: "书虫", desc: "读完 10 本书", requirement: 10),
        .init(id: "r3", group: "read", icon: "🏛️", name: "学者", desc: "读完 30 本书", requirement: 30),
        .init(id: "r4", group: "read", icon: "📜", name: "藏书阁", desc: "读完 50 本书", requirement: 50),
        .init(id: "r5", group: "read", icon: "🎓", name: "知识渊博", desc: "读完 100 本书", requirement: 100),
    ]

    static let guitar: [AchievementDef] = [
        .init(id: "g1", group: "guitar", icon: "🎸", name: "拨弦初试", desc: "完成第一次指弹", requirement: 1),
        .init(id: "g2", group: "guitar", icon: "🎵", name: "琴韵悠扬", desc: "完成 3 次指弹", requirement: 3),
        .init(id: "g3", group: "guitar", icon: "🎶", name: "指尖如歌", desc: "完成 7 次指弹", requirement: 7),
        .init(id: "g4", group: "guitar", icon: "🎼", name: "琴艺高手", desc: "完成 15 次指弹", requirement: 15),
        .init(id: "g5", group: "guitar", icon: "🎹", name: "指弹大师", desc: "完成 30 次指弹", requirement: 30),
    ]

    static let adventure: [AchievementDef] = [
        .init(id: "a1", group: "adventure", icon: "🗺️", name: "初出茅庐", desc: "完成第一次历险", requirement: 1),
        .init(id: "a2", group: "adventure", icon: "🧭", name: "渐入佳境", desc: "完成 30 次历险", requirement: 30),
        .init(id: "a3", group: "adventure", icon: "🏔️", name: "身经百战", desc: "完成 90 次历险", requirement: 90),
        .init(id: "a4", group: "adventure", icon: "👑", name: "传奇", desc: "完成 365 次历险", requirement: 365),
        .init(id: "a5", group: "adventure", icon: "🌟", name: "不朽传说", desc: "完成 720 次历险", requirement: 720),
    ]

    static func def(id: String) -> AchievementDef? {
        all.first { $0.id == id }
    }
}
