import SwiftUI
import SwiftData

/// 背包：查看已购物品并支持消耗（原生列表）
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
            List {
                if items.isEmpty {
                    emptyView
                } else {
                    if !available.isEmpty {
                        Section("可用") {
                            ForEach(available, id: \.id) { item in
                                backpackRow(item)
                            }
                        }
                    }
                    if !consumed.isEmpty {
                        Section("已消耗") {
                            ForEach(consumed, id: \.id) { item in
                                backpackRow(item)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .tint(Selge.Palette.accent)
            .navigationTitle("背包")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
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
        Section {
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.secondary)
                Text("背包还是空的")
                    .font(.headline)
                Text("去商店用金币换取奖励吧")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private func backpackRow(_ item: PurchasedItem) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(Selge.Palette.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .opacity(item.isConsumed ? 0.45 : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(item.isConsumed ? .secondary : Selge.Palette.textPrimary)
                Text(Self.dateFormatter.string(from: item.purchasedAt))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if item.isConsumed {
                Text("已消耗")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Button("消耗") { consumable = item }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd 购入"
        return formatter
    }()
}
