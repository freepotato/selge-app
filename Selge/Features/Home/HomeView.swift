import SwiftUI
import SwiftData

/// 主页仪表盘：严格单屏，从上到下 —— 顶部信息条（等级/经验/金币）、
/// 固定一行 3 张类别统计卡片、GitHub 风格历险热力图（无标题）。
struct HomeView: View {
    @Environment(GameStore.self) private var store
    @Query private var heroes: [HeroProfile]
    @Query private var records: [AdventureRecord]
    @Query private var categories: [AdventureCategory]

    var body: some View {
        NavigationStack {
            homeContent
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .selgeScreenHeader()
                .background(Selge.Palette.bg)
        }
    }

    private var hero: HeroProfile? { heroes.first }
    private var progress: (level: Int, title: String, current: Int, needed: Int, fraction: Double) {
        GameRules.progress(forXP: hero?.xp ?? 0)
    }

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerBar
            statCards
            HeatmapView(records: records)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.top, 4)
    }

    // MARK: 顶部信息条：等级 / 经验进度 / 金币

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Text("Lv.\(progress.level)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Selge.Palette.accent)
                    Text(progress.title)
                        .font(Selge.logoFontRegular(15))
                        .foregroundStyle(Selge.Palette.textSecondary)
                }
                Spacer()
                CoinText(value: hero?.coin ?? 0)
            }

            XPProgressBar(fraction: progress.fraction)

            Text(progress.level >= GameRules.maxLevel
                 ? "已至巅峰"
                 : "\(progress.current) / \(progress.needed) xp")
                .font(.system(size: 11, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.textTertiary)
        }
        .padding(14)
        .selgeCard()
    }

    // MARK: 固定类别卡片行（一行 3 张；付费版预留多行多卡片）

    private var statCards: some View {
        let limit = max(1, AppConfig.shared.homeCardLimit)
        let shown = categories
            .sorted {
                $0.sortOrder == $1.sortOrder
                    ? $0.createdAt < $1.createdAt
                    : $0.sortOrder < $1.sortOrder
            }
            .prefix(limit)
        let counts = Dictionary(grouping: records, by: \.categoryId).mapValues(\.count)

        return HStack(spacing: 10) {
            ForEach(shown, id: \.id) { category in
                StatCardView(emoji: category.emoji, name: category.name, count: counts[category.id] ?? 0)
            }
        }
    }
}
