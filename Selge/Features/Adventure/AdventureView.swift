import SwiftUI
import SwiftData

/// 历险页：预置 4 类别，进入单类别会话（开始计时 → 实时状态 → 结束结算）
struct AdventureView: View {
    @Environment(GameStore.self) private var store
    @Query private var categories: [AdventureCategory]
    @State private var activeCategory: AdventureCategory?

    private var sorted: [AdventureCategory] {
        categories.sorted {
            $0.sortOrder == $1.sortOrder
                ? $0.createdAt < $1.createdAt
                : $0.sortOrder < $1.sortOrder
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sorted, id: \.id) { category in
                        CategoryCard(category: category) {
                            activeCategory = category
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .background(Selge.Palette.bg)
            .selgeScreenHeader()
            .sheet(item: $activeCategory) { category in
                AdventureSessionView(category: category)
                    .presentationDetents([.large])
            }
        }
    }
}

// MARK: - 类别卡片

private struct CategoryCard: View {
    let category: AdventureCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(category.emoji)
                    .font(.system(size: 30))
                    .frame(width: 52, height: 52)
                    .background(Selge.Palette.accentSoftBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Selge.Palette.textPrimary)
                    Text(category.ruleDescription)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Selge.Palette.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Selge.Palette.textTertiary)
            }
            .padding(14)
            .selgeCard()
        }
        .buttonStyle(.plain)
    }
}
