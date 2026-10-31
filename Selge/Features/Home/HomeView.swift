import SwiftUI
import SwiftData

/// 主页：原生分组列表 —— 账户（等级/经验/金币）、类别统计、历险热力图
struct HomeView: View {
    @Environment(GameStore.self) private var store
    @Query private var heroes: [HeroProfile]
    @Query private var records: [AdventureRecord]
    @Query private var categories: [AdventureCategory]

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                List {
                    accountSection
                    statsSection
                    heatmapSection(width: max(0, proxy.size.width - 68))
                }
                .listStyle(.insetGrouped)
                .tint(Selge.Palette.accent)
                .scrollContentBackground(.hidden)
                .background(Selge.Palette.bg)
                .selgeScreenHeader()
            }
        }
    }

    private var hero: HeroProfile? { heroes.first }

    private var progress: (level: Int, current: Int, needed: Int, fraction: Double) {
        GameRules.progress(forXP: hero?.xp ?? 0)
    }

    // MARK: - 账户：等级 / 经验进度 / 金币

    private var accountSection: some View {
        Section {
            LabeledContent("等级") {
                Text("Lv.\(progress.level)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                XPProgressBar(fraction: progress.fraction)
                Text(progress.level >= GameRules.maxLevel
                     ? "已至巅峰"
                     : "\(progress.current) / \(progress.needed) xp")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

            LabeledContent("金币") {
                CoinText(value: hero?.coin ?? 0, font: .system(size: 17, weight: .semibold, design: .rounded))
            }
        } header: {
            Text("账户")
        }
    }

    // MARK: - 类别统计

    private var statsSection: some View {
        let limit = max(1, AppConfig.shared.homeCardLimit)
        let shown = categories
            .sorted {
                $0.sortOrder == $1.sortOrder
                    ? $0.createdAt < $1.createdAt
                    : $0.sortOrder < $1.sortOrder
            }
            .prefix(limit)
        let counts = Dictionary(grouping: records, by: \.categoryId).mapValues(\.count)

        return Section {
            ForEach(shown, id: \.id) { category in
                HStack(spacing: 10) {
                    Text(category.emoji)
                        .font(.system(size: 18))
                        .frame(width: 26, alignment: .leading)
                    Text(category.name)
                        .font(.system(size: 16))
                    Spacer(minLength: 8)
                    Text("\(counts[category.id] ?? 0) 次")
                        .font(.system(size: 15, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("类别统计")
        }
    }

    // MARK: - 历险热力图（按内容自然高度展示）

    private func heatmapSection(width: CGFloat) -> some View {
        Section {
            VStack(spacing: 10) {
                HeatmapView(records: records)
                    .frame(height: HeatmapView.intrinsicHeight(containerWidth: width))
                heatmapLegend
            }
        } header: {
            Text("历险热力图")
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 4) {
            Text("近 \(HeatmapView.weekColumnCount) 周")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
            Text("少")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(legendColor(index))
                    .frame(width: 9, height: 9)
            }
            Text("多")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
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
}
