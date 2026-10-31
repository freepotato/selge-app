# Selge for iOS

Selge —— Life RPG 人生冒险 / 习惯养成应用的原生 iOS 客户端。

每一次认真的生活都值得被记录：散步、观影、读书、练琴……完成它们即可获得经验与金币，升级勇者、解锁成就、在商店犒赏自己。

## 功能总览（免费版 · v0.1.0）

| 模块 | 说明 |
| --- | --- |
| 主页 | 等级 / 经验进度 / 金币信息条，固定 3 张类别统计卡片，GitHub 风格历险热力图（单屏无滚动） |
| 历险 | 预置散步（1 xp/分钟）、电影（0.32 xp/分钟）、读书（0.5 xp/分钟）、指弹（500 xp/次）；完整计时 → 结算流程 |
| 商店 | 预置电影票 / 新裤子 / 100 元红包 / 新外套 / 新鞋子；金币 = 经验 × 1.5；下拉刷新查看账户明细，内置背包 |
| 成就 | 分段控件分类浏览，Apple 健身风格圆形 3D 徽章，支持摆动旋转交互 |
| 设置 | 历险类型管理、深浅色模式、锁定参数展示、版本与更新日志 |

## 免费版 / 付费版功能边界

| 能力 | 免费版 | 付费版（规划中） |
| --- | --- | --- |
| 历险类别 | 预置 4 类，可增删 | 无限制 + 多行统计卡片 |
| 金币倍率 | 锁定 1.5× | 可配置 |
| 自定义成就 | 关闭 | 开放 |
| 自定义商店商品 | 关闭 | 开放 |
| iCloud 同步 | 私有库双向同步 | 同左 |

付费开关接口已在 `Selge/Services/AppConfig.swift` 统一封装（`paidFeaturesUnlocked`），当前版本恒为关闭。

## 数据与隐私

- 本地存储基于 SwiftData，CloudKit 私有容器（`iCloud.com.freepotato.selge`）实现 iOS 与后续 Web 端的双向同步；无 iCloud 账户时自动降级为纯本地存储。
- 所有数据仅存于用户个人 iCloud 私有库，开发者无法读取；详见 [docs/CLOUDKIT.md](docs/CLOUDKIT.md)。
- 应用不收集任何追踪信息，不含第三方分析 SDK。

## 版本与更新日志

- App 内「设置 → 关于」展示版本号与更新日志（数据源为打包进 App 的 `docs/CHANGELOG.md`）。
- 版本号由 [release-please](https://github.com/googleapis/release-please) 依据 Conventional Commits 自动维护：合并 Release PR 后打 tag、发布 GitHub Release，并同步更新 `Config/Version.xcconfig` 的 `MARKETING_VERSION`，保证 App 显示版本与 GitHub Release 完全一致。
- 日常提交请遵循 Conventional Commits（`feat:` / `fix:` / `docs:` …）。

## 构建指南

```bash
brew install xcodegen      # 若未安装
xcodegen generate          # 由 project.yml 生成 Selge.xcodeproj
open Selge.xcodeproj       # 选择团队签名后 Cmd+R 运行
```

要求：Xcode 16+（iOS 17.0+ 部署目标）、XcodeGen 2.40+。签名与 iCloud 能力配置、TestFlight 发布流程见 [docs/xcode-setup.md](docs/xcode-setup.md)。

## 闭源声明

本项目为专有软件：未经书面授权，禁止复制、修改、分发、二次打包、上架或任何形式的商用。完整条款见 [LICENSE](LICENSE)。

商业授权与合作请联系：licensing@selge.app
