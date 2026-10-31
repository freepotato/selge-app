import SwiftUI
import SwiftData

/// 成就页：分段控件分页（默认「全部」），圆形 3D 徽章支持摆动旋转
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

    private var shownDefs: [AchievementDef] {
        selectedGroup == "all"
            ? AchievementCatalog.all
            : AchievementCatalog.all.filter { $0.group == selectedGroup }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("分类", selection: $selectedGroup) {
                    ForEach(AchievementCatalog.groups, id: \.key) { group in
                        Text(group.label).tag(group.key)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                        ForEach(shownDefs) { def in
                            BadgeCard(
                                def: def,
                                unlockedAt: unlockedMap[def.id],
                                currentCount: counts[def.group] ?? 0
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 6)
            .background(Selge.Palette.bg)
            .selgeScreenHeader()
        }
    }
}

// MARK: - 3D 徽章卡片

/// 圆形 3D 徽章（质感参考 Apple 健身徽章）：
/// 手指左右摆动旋转，松手后带回弹惯性的钟摆动画；旋转角度受限，不可翻至背面。
struct BadgeCard: View {
    let def: AchievementDef
    let unlockedAt: Date?
    let currentCount: Int

    @State private var swingAngle: Double = 0
    private var isUnlocked: Bool { unlockedAt != nil }

    var body: some View {
        VStack(spacing: 10) {
            badge
                .rotation3DEffect(
                    .degrees(swingAngle),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.8
                )
                .gesture(swingGesture)

            VStack(spacing: 3) {
                Text(def.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isUnlocked ? Selge.Palette.textPrimary : Selge.Palette.textTertiary)
                Text(def.desc)
                    .font(.system(size: 11))
                    .foregroundStyle(Selge.Palette.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.system(size: 10, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isUnlocked ? Selge.Palette.accent : Selge.Palette.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .selgeCard()
        .opacity(isUnlocked ? 1 : 0.82)
    }

    private var subtitle: String {
        if let date = unlockedAt {
            return Self.dateFormatter.string(from: date) + " 解锁"
        }
        return "\(min(currentCount, def.requirement)) / \(def.requirement)"
    }

    // MARK: 徽章视觉

    private var badge: some View {
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
                .padding(9)
            // 高光
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .top, endPoint: .center
                    )
                )
                .padding(9)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            // 内容
            if isUnlocked {
                Text(def.icon)
                    .font(.system(size: 34))
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Selge.Palette.textTertiary)
            }
        }
        .frame(width: 92, height: 92)
        .shadow(color: .black.opacity(isUnlocked ? 0.18 : 0.08), radius: 6, x: 0, y: 3)
    }

    private var ringColors: [Color] {
        isUnlocked
            ? [Selge.g3, Selge.g5]
            : [Selge.Palette.border, Selge.Palette.borderStrong]
    }

    private var innerFill: AnyShapeStyle {
        isUnlocked
            ? AnyShapeStyle(LinearGradient(colors: [Selge.g1, Selge.g2], startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(LinearGradient(colors: [Selge.Palette.bg2, Selge.Palette.bg2], startPoint: .top, endPoint: .bottom))
    }

    // MARK: 摆动手势（角度受限 + 惯性回弹）

    private var swingGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                // 限制最大 ±72°，保证永不翻转至背面
                let target = Double(value.translation.width) * 0.55
                swingAngle = min(max(target, -72), 72)
            }
            .onEnded { _ in
                // 松手后钟摆式回弹（低阻尼弹簧带惯性摆动）
                withAnimation(.spring(response: 0.6, dampingFraction: 0.28, blendDuration: 0.2)) {
                    swingAngle = 0
                }
            }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}
