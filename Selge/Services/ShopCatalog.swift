import Foundation

/// 预置商品（与 Web 端价格一致）
struct ShopSeed: Identifiable, Hashable {
    let id: String
    let emoji: String
    let name: String
    let desc: String
    let price: Int
}

enum ShopCatalog {
    static let defaults: [ShopSeed] = [
        .init(id: "m_ticket", emoji: "🎟️", name: "电影票", desc: "看一场电影", price: 100),
        .init(id: "pants", emoji: "👖", name: "新裤子", desc: "踏出每一步", price: 250),
        .init(id: "redpack", emoji: "🧧", name: "100元红包", desc: "放心地花吧", price: 300),
        .init(id: "jacket", emoji: "🧥", name: "新外套", desc: "风里更从容", price: 500),
        .init(id: "s_shoes", emoji: "👟", name: "新鞋子", desc: "走更远的路", price: 750),
    ]
}
