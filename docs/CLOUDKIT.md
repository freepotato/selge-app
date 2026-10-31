# Selge CloudKit 数据架构

## 容器与数据库划分

| 项 | 值 |
| --- | --- |
| 容器 ID | `iCloud.com.freepotato.selge` |
| 数据库 | 私有库（private database），zone 由 SwiftData 自动管理 |
| 公共库 | 当前版本不使用；预留用于后续付费版云端配置分发 |

- iOS 端通过 SwiftData `ModelConfiguration(cloudKitDatabase: .private("iCloud.com.freepotato.selge"))` 读写（见 `Selge/Services/Persistence.swift`）。
- 设备无 iCloud 账户或签名未包含 iCloud 能力时，同步失败会降级为纯本地存储，App 功能不受影响。
- Web 端（Cloudflare Pages）后续通过 CloudKit JS（CloudKit Web Services）访问同一容器、同一私有库，实现双向同步。

## Record Type 映射

SwiftData 导出 CloudKit 时自动使用 `CD_` 前缀 + 类名。字段名同理加 `CD_` 前缀，类型映射为 CloudKit 基础类型。

| SwiftData 模型 | CloudKit Record Type | 关键字段（CD_ 前缀） | 用途 |
| --- | --- | --- | --- |
| `HeroProfile` | `CD_HeroProfile` | id(UUID)、name、xp(Int64)、coin(Int64)、streak、lastAdventureDay、createdAt、updatedAt | 用户基础信息、等级/经验/金币/连续打卡 |
| `AdventureCategory` | `CD_AdventureCategory` | id、emoji、name、kindRaw、xpPerMinute(Double)、baseXP、sortOrder、createdAt | 历险类别（Web 端需识别 kindRaw：time/once） |
| `AdventureRecord` | `CD_AdventureRecord` | id、categoryId、categoryName、emoji、kindRaw、xp、coin、minutes、note、startedAt、endedAt、dayKey | 历险记录；类别信息冗余存储，删除类别后历史仍完整 |
| `ShopItem` | `CD_ShopItem` | id、itemKey、emoji、name、itemDescription、priceCoin、sortOrder、isActive | 商品元数据（itemKey 与 Web 端约定一致，如 `m_ticket`） |
| `PurchasedItem` | `CD_PurchasedItem` | id、itemKey、name、emoji、priceCoin、purchasedAt、consumedAt、isConsumed | 背包：已购物品与消耗状态 |
| `AccountTransaction` | `CD_AccountTransaction` | id、at、xpDelta、coinDelta、reason、dayKey | 账户收支流水 |
| `AchievementUnlock` | `CD_AchievementUnlock` | id、achievementId、group、unlockedAt | 成就解锁事实（成就定义内置于客户端 `AchievementCatalog`，云端只存解锁记录，避免定义变更产生迁移） |

## 字段与索引约定（CloudKit Dashboard 侧）

SwiftData 首次同步会在 Dashboard 自动创建 Record Type；如需手工调整，遵循：

1. **可查询字段（Queryable Index）**：各表的 `CD_id`；`CD_AdventureRecord.CD_dayKey`、`CD_categoryId`（热力图与分类统计）；`CD_AccountTransaction.CD_dayKey`、`CD_at`（流水排序）；`CD_PurchasedItem.CD_isConsumed`（背包过滤）。
2. **排序索引（Sortable）**：`CD_sortOrder`、`CD_createdAt`、`CD_purchasedAt`、`CD_at`。
3. **不使用唯一约束**：SwiftData + CloudKit 不支持 UNIQUE；去重逻辑由客户端按 `id` 字段处理。
4. **全部字段可选或带默认值**：CloudKit 要求字段可空或含默认值，模型已遵守（见 `Selge/Models/Models.swift`）。

## 权限划分

| 数据库 | 权限 | 说明 |
| --- | --- | --- |
| 私有库 | 仅用户本人读写（默认） | 全部用户数据；iOS 与 Web 端均以用户 Apple ID 身份访问 |
| 公共库 | 后续只读（世界可读、仅管理员写） | 预留：付费配置、商品目录下发 |

## Web 端 CloudKit JS 兼容要点

1. 在 CloudKit Dashboard 为容器启用 **CloudKit Web Services**，创建 Token 并配置 Web 端域名（Cloudflare Pages 域名）为允许来源。
2. Web 端使用 `CloudKit.default.setUp()` 后 `fetchRecord`/`saveRecords` 操作同样的 Record Type；字段读写注意 `CD_` 前缀与类型包装（如 `{ value: 123 }`）。
3. 用户通过 Apple ID 登录后，Web 端与 iOS 端读写同一私有库数据集；冲突以记录级 last-writer-wins 处理，关键计数字段（xp/coin）建议 Web 端先读后算再写，减少丢失更新。
4. `dayKey`（本地时区 `yyyy-MM-dd`）由写入端生成，两端共用同一规则（见 `GameRules.dayKey`），热力图与流水分组不做时区换算。
