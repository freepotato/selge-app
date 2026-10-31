# Xcode 工程配置与发布指南

## 工程结构

```
selge-app/
├── project.yml                  # XcodeGen 工程定义（工程文件由它生成）
├── Selge.xcodeproj/             # xcodegen generate 产物
├── Config/Version.xcconfig      # MARKETING_VERSION（release-please 自动维护）
├── Selge/
│   ├── Entitlements/Selge.entitlements   # iCloud/CloudKit 能力
│   ├── Assets.xcassets          # AppIcon / AccentColor / LaunchBackground / LaunchLogo
│   ├── Info.plist               # xcodegen 生成（含 UILaunchScreen 等）
│   ├── Models/                  # SwiftData 模型（CloudKit 兼容）
│   ├── Services/                # 业务逻辑（GameStore / GameRules / Persistence / AppConfig…）
│   ├── Features/                # Home / Adventure / Shop / Achievements / Settings
│   └── Theme/                   # 橄榄绿色板与设计令牌
└── docs/                        # CHANGELOG.md（同时打包进 App）与本目录文档
```

日常开发只需修改 `project.yml` 后执行 `xcodegen generate`；`Selge.xcodeproj` 可提交或本地再生成均可。

## 版本号机制（重要）

`Config/Version.xcconfig` 挂接为 Debug/Release 的 xcconfig：

- `MARKETING_VERSION` 由 release-please 在 Release PR 中自动更新（generic extra-files），App 内显示版本 = `CFBundleShortVersionString` = 该值，与 GitHub Release 严格同步。
- **请勿在 target 设置或 Info.plist 中另行覆盖 `MARKETING_VERSION`**，否则会破坏同步链路。
- 上传 TestFlight 前手动递增 `CURRENT_PROJECT_VERSION`（构建号）。

## 签名与能力配置（首次）

1. **团队**：Xcode → Selge target → Signing & Capabilities → 勾选 Automatically manage signing，选择你的 Team（个人免费账号亦可真机调试）。
2. **Bundle ID**：`com.freepotato.selge`，如使用个人团队被占用可在 project.yml 中调整。
3. **iCloud 容器注册**：
   - Apple Developer → Certificates, Identifiers & Profiles → Identifiers → 新建/编辑 App ID `com.freepotato.selge`，勾选 iCloud → Include CloudKit support；
   - CloudKit Dashboard → 选择容器 `iCloud.com.freepotato.selge`（首次构建运行后自动创建，或在 Dashboard 手动创建）；
   - 真机需登录 iCloud 账户；无账户时 App 自动降级为本地存储。
4. **能力文件**：`Selge/Entitlements/Selge.entitlements` 已声明 `com.apple.developer.icloud-services = [CloudKit]` 与容器标识，Xcode 会在签名时合并。

> **个人免费团队（未加入付费开发者计划）**：不支持 iCloud 能力，签名包含 iCloud 声明会报
> "Personal development teams do not support the iCloud capability"。
> 工程已内置处理：**Debug 配置自动使用空声明 `SelgeDebug.entitlements`**（免费签名可直接
> 真机安装，App 纯本地运行），**Release 配置使用完整 iCloud 声明 `Selge.entitlements`**
> 并启用 `SELGE_CLOUDKIT` 编译条件，无需任何手动修改。
> 免费签名 7 天过期需重新 Run，且同一 Apple ID 最多同时安装 3 个免费签名的 App。
> 需要 iCloud 同步请加入 Apple Developer Program（99 美元/年），用 Release/Archive 构建。

## TestFlight / App Store Connect 发布流程

1. 递增 `CURRENT_PROJECT_VERSION`（`Config/Version.xcconfig`）。
2. Xcode → Product → Destination 选 Any iOS Device (arm64) → Product → Archive。
3. Organizer → Distribute App → App Store Connect → Upload。
4. App Store Connect → TestFlight：处理导出合规（Info.plist 已置 `ITSAppUsesNonExemptEncryption = false`，通常可自动豁免）→ 添加内部/外部测试员。
5. 首次外发 TestFlight 需提供隐私政策 URL（可指向 Selge 网站）并完成 App 隐私问卷（本应用不收集数据，仅用户 iCloud 私有库存储）。

## GitHub Release 流程（release-please）

1. 日常开发以 Conventional Commits 提交（`feat:`、`fix:`、`docs:`、`chore:`…）合入 `main`。
2. release-please Action 检测后自动开/更新 **Release PR**：内容为 `docs/CHANGELOG.md` 追加版本段落 + `Version.xcconfig` 版本号 bump + `.release-please-manifest.json` 更新。
3. 合并 Release PR → 自动打 `vX.Y.Z` tag 并创建 GitHub Release。
4. App 内「设置 → 更新日志」读取的 CHANGELOG.md 随下一次构建携带，因此 App 版本与 Release 版本永远一致。

## 本地验证

```bash
xcodegen generate
xcodebuild -project Selge.xcodeproj -scheme Selge \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
```
