import SwiftUI
import SwiftData

/// 背包：查看已购物品并支持消耗
struct BackpackView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\PurchasedItem.purchasedAt, order: .reverse)])
    private var items: [PurchasedItem]
    @State private var consumable: PurchasedItem?

    private var available: [PurchasedItem] { items.filter { !$0.isConsumed } }
    private var consumed: [PurchasedItem] { items.filter { $0.isConsumed } }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if available.isEmpty && consumed.isEmpty {
                        emptyView
                    } else {
                        if !available.isEmpty {
                            section(title: "可用", items: available)
                        }
                        if !consumed.isEmpty {
                            section(title: "已消耗", items: consumed)
                        }
                    }
                }
                .padding(16)
            }
            .background(Selge.Palette.bg)
            .navigationTitle("背包")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Selge.Palette.accent)
                }
            }
            .confirmationDialog(
                "消耗「\(consumable?.name ?? "")」？",
                isPresented: .init(
                    get: { consumable != nil },
                    set: { if !$0 { consumable = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("消耗") { if let item = consumable { store.consume(item: item) } }
                Button("取消", role: .cancel) {}
            } message: {
                Text("消耗后将从背包移除，该操作不可撤销")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 34))
                .foregroundStyle(Selge.Palette.textTertiary)
            Text("背包还是空的")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Selge.Palette.textSecondary)
            Text("去商店用金币换取奖励吧")
                .font(.system(size: 12))
                .foregroundStyle(Selge.Palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func section(title: String, items: [PurchasedItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Selge.Palette.textTertiary)
            ForEach(items, id: \.id) { item in
                backpackRow(item)
            }
        }
    }

    private func backpackRow(_ item: PurchasedItem) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(Selge.Palette.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .opacity(item.isConsumed ? 0.45 : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(item.isConsumed ? Selge.Palette.textTertiary : Selge.Palette.textPrimary)
                Text(Self.dateFormatter.string(from: item.purchasedAt))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Selge.Palette.textTertiary)
            }
            Spacer()
            if item.isConsumed {
                Text("已消耗")
                    .font(.system(size: 12))
                    .foregroundStyle(Selge.Palette.textTertiary)
            } else {
                Button("消耗") { consumable = item }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Selge.Palette.accent)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .selgeCard()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd 购入"
        return formatter
    }()
}
