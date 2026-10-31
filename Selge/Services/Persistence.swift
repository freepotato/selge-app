import Foundation
import SwiftData

/// 数据层入口：SwiftData + CloudKit 私有容器
///
/// 容器划分方案（详见 docs/CLOUDKIT.md）：
/// - 容器：iCloud.com.freepotato.selge（私有库 private database）
/// - 运行时优先启用 CloudKit 同步；当设备无 iCloud 账户、无授权或签名
///   未包含 iCloud 能力时，自动降级为纯本地存储，保证 App 始终可用。
enum Persistence {
    static let cloudContainerID = "iCloud.com.freepotato.selge"

    /// 是否成功启用了 CloudKit 同步
    static var cloudKitEnabled = false

    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            HeroProfile.self,
            AdventureCategory.self,
            AdventureRecord.self,
            ShopItem.self,
            PurchasedItem.self,
            AccountTransaction.self,
            AchievementUnlock.self,
        ])

        // 优先：CloudKit 私有容器（iOS 与后续 Web 端 CloudKit JS 共用同一数据集）
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(cloudContainerID)
            )
            let container = try ModelContainer(for: schema, configurations: [cloudConfig])
            cloudKitEnabled = true
            return container
        } catch {
            #if DEBUG
            print("[Selge] CloudKit 不可用，降级为本地存储: \(error.localizedDescription)")
            #endif
        }

        // 降级：纯本地存储（无 iCloud 能力时仍可完整使用）
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("无法创建数据存储: \(error)")
        }
    }
}
