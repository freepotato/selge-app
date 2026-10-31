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

    /// 设备是否具备启用 CloudKit 的前提：App 签名包含 iCloud 能力且已登录 iCloud 账户。
    /// 免费个人开发团队签名的包不含 iCloud 能力（此时 ubiquityIdentityToken 为 nil），
    /// 直接跳过 CloudKit 初始化，避免异步崩溃并自动使用本地存储。
    static var cloudKitAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

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
        // 仅在 SELGE_CLOUDKIT 编译条件的构建中尝试（Release 配置）。
        // 运行时无法可靠探测签名是否包含 iCloud 能力：已登录 iCloud 的设备上
        // ubiquityIdentityToken 可能为非 nil，而缺少能力时 CloudKit 会在
        // 初始化时直接崩溃（CKContainer.m 断言），因此用编译期开关兜底，
        // 免费个人团队签名（Debug 真机）绝不触碰 CloudKit。
        #if SELGE_CLOUDKIT
        if cloudKitAvailable {
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
        }
        #endif

        // 降级：纯本地存储（无 iCloud 能力时仍可完整使用）
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("无法创建数据存储: \(error)")
        }
    }
}
