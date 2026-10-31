import SwiftUI
import SwiftData

/// 成就页：顶部分类分段控件，同时支持左右滑动切换类别；下方逐行展示徽章（静态展示，无动画）
struct AchievementsView: View {
    @Environment(GameStore.self) private var store
    @Query private var records: [AdventureRecord]
    @Query private var unlocks: [AchievementUnlock]
    @Query private var categories: [AdventureCategory]
    @State private var selectedGroup = "all"

    private var unlockedMap: [String: Date] {
        Dictionary(uniqueKeysWithValues: unlocks.map { ($0.achievementId, $0.unlockedAt) })
    }

    private var counts: [String: Int] {
        store.groupCounts(records: records, categories: categories)
    }

    /// 排序规则：已解锁在前，解锁时间越新越靠前；未解锁按达成门槛由易到难
    private func defs(for group: String) -> [AchievementDef] {
        let defs = group == "all"
            ? AchievementCatalog.all
            : AchievementCatalog.all.filter { $0.group == group }
        return defs.sorted { lhs, rhs in
            switch (unlockedMap[lhs.id], unlockedMap[rhs.id]) {
            case let (left?, right?):
                if left != right { return left > right }
                return lhs.requirement < rhs.requirement
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                if lhs.requirement != rhs.requirement { return lhs.requirement < rhs.requirement }
                return lhs.id < rhs.id
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Picker("分类", selection: $selectedGroup) {
                    ForEach(AchievementCatalog.groups, id: \.key) { group in
                        Text(group.label).tag(group.key)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                TabView(selection: $selectedGroup) {
                    ForEach(AchievementCatalog.groups, id: \.key) { group in
                        page(for: group.key)
                            .tag(group.key)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.top, 6)
            .background(Selge.Palette.bg)
            .selgeScreenHeader()
        }
    }

    private func page(for group: String) -> some View {
        List {
            Section {
                ForEach(defs(for: group)) { def in
                    AchievementRow(
                        def: def,
                        unlockedAt: unlockedMap[def.id],
                        currentCount: counts[def.group] ?? 0
                    )
                }
            } header: {
                Text("徽章")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Selge.Palette.bg)
    }
}

// MARK: - 单个成就行

/// 圆形 3D 徽章（静态展示，参考 Apple 健身徽章质感）
private struct AchievementRow: View {
    let def: AchievementDef
    let unlockedAt: Date?
    let currentCount: Int

    private var isUnlocked: Bool { unlockedAt != nil }

    var body: some View {
        HStack(spacing: 12) {
            BadgeArt(icon: def.icon, unlocked: isUnlocked, size: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(def.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isUnlocked ? Selge.Palette.textPrimary : .secondary)
                Text(def.desc)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(isUnlocked ? "已解锁" : "\(min(currentCount, def.requirement)) / \(def.requirement)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(isUnlocked ? Selge.Palette.accent : .secondary)
                if let unlockedAt {
                    Text(Self.dateFormatter.string(from: unlockedAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .opacity(isUnlocked ? 1 : 0.85)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

// MARK: - 3D 徽章图形

private struct BadgeArt: View {
    let icon: String
    let unlocked: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            // 底层外圈（立体渐变环）
            Circle()
                .fill(
                    LinearGradient(
                        colors: ringColors,
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            // 内圈
            Circle()
                .fill(innerFill)
                .padding(size * 0.1)
            // 高光
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .top, endPoint: .center
                    )
                )
                .padding(size * 0.1)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            // 内容
            if unlocked {
                Text(icon)
                    .font(.system(size: size * 0.42))
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.26, weight: .medium))
                    .foregroundStyle(Selge.Palette.textTertiary)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(unlocked ? 0.16 : 0.06), radius: 3, x: 0, y: 2)
    }

    private var ringColors: [Color] {
        unlocked
            ? [Selge.g3, Selge.g5]
            : [Selge.Palette.border, Selge.Palette.borderStrong]
    }

    private var innerFill: AnyShapeStyle {
        unlocked
            ? AnyShapeStyle(LinearGradient(colors: [Selge.g1, Selge.g2], startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(LinearGradient(colors: [Selge.Palette.bg2, Selge.Palette.bg2], startPoint: .top, endPoint: .bottom))
    }
}
