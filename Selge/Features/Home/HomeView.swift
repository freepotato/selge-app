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
    private var progress: (level: Int, current: Int, needed: Int, fraction: Double) {
        GameRules.progress(forXP: hero?.xp ?? 0)
    }

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerBar
            statCards
            heatmapCard
        }
        .padding(.top, 4)
    }

    // MARK: 历险热力图（填满剩余高度，无标题，仅图 + 图例）

    private var heatmapCard: some View {
        VStack(spacing: 10) {
            HeatmapView(records: records)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            heatmapLegend
        }
        .padding(12)
        .selgeCard()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heatmapLegend: some View {
        HStack(spacing: 4) {
            Text("近 \(HeatmapView.weekColumnCount) 周")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(Selge.Palette.textTertiary)
            Spacer()
            Text("少")
                .font(.system(size: 9))
                .foregroundStyle(Selge.Palette.textTertiary)
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(legendColor(index))
                    .frame(width: 8, height: 8)
            }
            Text("多")
                .font(.system(size: 9))
                .foregroundStyle(Selge.Palette.textTertiary)
        }
    }

    private func legendColor(_ index: Int) -> Color {
        switch index {
        case 1: return Selge.Palette.heat1
        case 2: return Selge.Palette.heat2
        case 3: return Selge.Palette.heat3
        case 4: return Selge.Palette.heat4
        default: return Selge.Palette.heat
        }
    }

    // MARK: 顶部信息条：等级 / 经验进度 / 金币

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Lv.\(progress.level)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.accent)
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
