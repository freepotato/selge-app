import Foundation

/// 版本信息：与 GitHub Release 版本同步
///
/// 同步链路：release-please（GitHub Action）→ 更新 Config/Version.xcconfig
/// → MARKETING_VERSION 注入 CFBundleShortVersionString → 此处读取展示。
/// 因此 App 内显示的版本号始终与仓库最新 Release 一致。
enum VersionInfo {
    static var shortVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }

    static var buildNumber: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
    }

    static var display: String {
        "\(shortVersion) (\(buildNumber))"
    }
}
