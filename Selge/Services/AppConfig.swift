import Foundation
import SwiftUI

/// 全局可配置参数（统一封装；免费版锁定，付费开关完整保留）
/// 说明：此处为应用内轻量配置，存储于 UserDefaults；
/// 后续接入 CloudKit 公共库/订阅体系时可平滑迁移为云端配置。
struct AppConfig {
    static let shared = AppConfig()

    @AppStorage("cfg.coinMultiplier") var coinMultiplier: Double = GameRules.defaultCoinMultiplier
    @AppStorage("cfg.homeCardLimit") var homeCardLimit: Int = 3
    @AppStorage("cfg.customAchievementsEnabled") var customAchievementsEnabled: Bool = false

    /// 付费功能总开关（当前版本恒为 false，预留接口）
    @AppStorage("cfg.paidFeaturesUnlocked") var paidFeaturesUnlocked: Bool = false

    // MARK: 外观
    // 外观偏好存于 UserDefaults("app.appearance")，由视图层以 @AppStorage 直接读写，
    // 以便设置变更即时生效（struct 值类型不便作为可变共享状态）

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var label: String {
            switch self {
            case .system: return "跟随系统"
            case .light: return "浅色"
            case .dark: return "深色"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    private init() {}
}
